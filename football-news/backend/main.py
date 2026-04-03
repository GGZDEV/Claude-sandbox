"""
Football News Aggregator - Backend API
"""
import asyncio
import json
import logging
import os
from datetime import datetime
from pathlib import Path
from typing import Optional

from apscheduler.schedulers.asyncio import AsyncIOScheduler
from fastapi import FastAPI, Query, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
from sqlalchemy import select, delete, or_
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import sessionmaker

from clickbait import compute_final_score, detect_clickbait
from feed_fetcher import fetch_feed, fetch_twitter_feed
from models import Article, Base, Source

# ---------------------------------------------------------------------------
# Setup
# ---------------------------------------------------------------------------
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

BASE_DIR = Path(__file__).parent
FRONTEND_DIR = BASE_DIR.parent / "frontend"
DB_PATH = BASE_DIR / "football_news.db"
SOURCES_FILE = BASE_DIR / "data" / "sources.json"

engine = create_async_engine(f"sqlite+aiosqlite:///{DB_PATH}", echo=False)
AsyncSessionLocal = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

app = FastAPI(title="Football News Aggregator", version="1.0.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

scheduler = AsyncIOScheduler()


# ---------------------------------------------------------------------------
# DB helpers
# ---------------------------------------------------------------------------
async def get_db():
    async with AsyncSessionLocal() as session:
        yield session


async def init_db():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    # Seed sources from JSON if table is empty
    async with AsyncSessionLocal() as db:
        result = await db.execute(select(Source))
        existing = result.scalars().all()
        if not existing:
            with open(SOURCES_FILE) as f:
                sources_data = json.load(f)
            for s in sources_data:
                db.add(Source(**s))
            await db.commit()
            logger.info(f"Seeded {len(sources_data)} sources")


# ---------------------------------------------------------------------------
# Feed refresh logic
# ---------------------------------------------------------------------------
async def refresh_source(source: Source):
    """Fetch articles for one source, score them, upsert into DB."""
    try:
        if source.twitter_handle:
            raw_articles = await fetch_twitter_feed(source.twitter_handle)
        else:
            raw_articles = await fetch_feed(source.url)
    except Exception as exc:
        logger.error(f"Error fetching {source.id}: {exc}")
        raw_articles = []

    async with AsyncSessionLocal() as db:
        # Update last_fetched / error_count
        src = await db.get(Source, source.id)
        if not src:
            return
        if raw_articles:
            src.last_fetched = datetime.utcnow()
            src.error_count = 0
        else:
            src.error_count = (src.error_count or 0) + 1

        new_count = 0
        for raw in raw_articles:
            existing = await db.get(Article, raw["id"])
            if existing:
                continue

            clickbait_score, flags = detect_clickbait(raw["title"])
            final_score = compute_final_score(source.reliability, clickbait_score)

            article = Article(
                id=raw["id"],
                source_id=source.id,
                title=raw["title"],
                url=raw["url"],
                summary=raw.get("summary"),
                published_at=raw["published_at"],
                author=raw.get("author"),
                image_url=raw.get("image_url"),
                source_reliability=source.reliability,
                clickbait_score=clickbait_score,
                final_score=final_score,
                clickbait_flags=flags,
            )
            db.add(article)
            new_count += 1

        await db.commit()
        if new_count:
            logger.info(f"[{source.id}] +{new_count} new articles")


async def refresh_all_sources():
    async with AsyncSessionLocal() as db:
        result = await db.execute(select(Source).where(Source.enabled == True))
        sources = result.scalars().all()

    # Fetch in parallel with a concurrency limit
    semaphore = asyncio.Semaphore(5)

    async def bounded(src):
        async with semaphore:
            await refresh_source(src)

    await asyncio.gather(*[bounded(s) for s in sources])
    logger.info("Feed refresh complete")


# ---------------------------------------------------------------------------
# API routes
# ---------------------------------------------------------------------------
@app.get("/api/sources")
async def list_sources():
    async with AsyncSessionLocal() as db:
        result = await db.execute(select(Source))
        sources = result.scalars().all()
    return [
        {
            "id": s.id,
            "name": s.name,
            "type": s.type,
            "country": s.country,
            "language": s.language,
            "city": s.city,
            "reliability": s.reliability,
            "tags": s.tags or [],
            "affiliation": s.affiliation,
            "twitter_handle": s.twitter_handle,
            "enabled": s.enabled,
            "last_fetched": s.last_fetched.isoformat() if s.last_fetched else None,
            "error_count": s.error_count,
        }
        for s in sources
    ]


@app.patch("/api/sources/{source_id}")
async def update_source(source_id: str, payload: dict):
    async with AsyncSessionLocal() as db:
        src = await db.get(Source, source_id)
        if not src:
            raise HTTPException(404, "Source not found")
        allowed = {"enabled", "reliability", "tags", "affiliation"}
        for key, val in payload.items():
            if key in allowed:
                setattr(src, key, val)
        await db.commit()
    return {"ok": True}


@app.get("/api/articles")
async def list_articles(
    page: int = Query(1, ge=1),
    per_page: int = Query(30, ge=1, le=100),
    source_id: Optional[str] = None,
    country: Optional[str] = None,
    tag: Optional[str] = None,
    min_score: Optional[float] = None,
    max_clickbait: Optional[float] = None,
    search: Optional[str] = None,
    sort: str = Query("date", pattern="^(date|score)$"),
):
    async with AsyncSessionLocal() as db:
        # Build base query joining source info
        stmt = select(Article, Source).join(Source, Article.source_id == Source.id).where(Source.enabled == True)

        if source_id:
            stmt = stmt.where(Article.source_id == source_id)
        if country:
            stmt = stmt.where(Source.country == country)
        if tag:
            # JSON array contains tag
            stmt = stmt.where(Source.tags.like(f'%"{tag}"%'))
        if min_score is not None:
            stmt = stmt.where(Article.final_score >= min_score)
        if max_clickbait is not None:
            stmt = stmt.where(Article.clickbait_score <= max_clickbait)
        if search:
            stmt = stmt.where(
                or_(
                    Article.title.ilike(f"%{search}%"),
                    Article.summary.ilike(f"%{search}%"),
                )
            )

        if sort == "score":
            stmt = stmt.order_by(Article.final_score.desc(), Article.published_at.desc())
        else:
            stmt = stmt.order_by(Article.published_at.desc())

        # Count total
        from sqlalchemy import func
        count_stmt = select(func.count()).select_from(stmt.subquery())
        total = (await db.execute(count_stmt)).scalar()

        # Paginate
        stmt = stmt.offset((page - 1) * per_page).limit(per_page)
        rows = (await db.execute(stmt)).all()

    articles = []
    for article, source in rows:
        articles.append({
            "id": article.id,
            "title": article.title,
            "url": article.url,
            "summary": article.summary,
            "published_at": article.published_at.isoformat(),
            "author": article.author,
            "image_url": article.image_url,
            "source": {
                "id": source.id,
                "name": source.name,
                "type": source.type,
                "country": source.country,
                "city": source.city,
                "reliability": source.reliability,
                "tags": source.tags or [],
                "affiliation": source.affiliation,
            },
            "scores": {
                "source_reliability": article.source_reliability,
                "clickbait_score": article.clickbait_score,
                "final_score": article.final_score,
                "clickbait_flags": article.clickbait_flags or [],
            },
        })

    return {"total": total, "page": page, "per_page": per_page, "articles": articles}


@app.post("/api/refresh")
async def manual_refresh():
    asyncio.create_task(refresh_all_sources())
    return {"ok": True, "message": "Refresh started"}


@app.post("/api/refresh/{source_id}")
async def refresh_one(source_id: str):
    async with AsyncSessionLocal() as db:
        src = await db.get(Source, source_id)
        if not src:
            raise HTTPException(404, "Source not found")
    asyncio.create_task(refresh_source(src))
    return {"ok": True, "message": f"Refresh started for {source_id}"}


@app.get("/api/stats")
async def stats():
    async with AsyncSessionLocal() as db:
        from sqlalchemy import func
        total_articles = (await db.execute(select(func.count(Article.id)))).scalar()
        total_sources = (await db.execute(select(func.count(Source.id)).where(Source.enabled == True))).scalar()
        avg_score = (await db.execute(select(func.avg(Article.final_score)))).scalar()
        avg_clickbait = (await db.execute(select(func.avg(Article.clickbait_score)))).scalar()
    return {
        "total_articles": total_articles,
        "total_sources": total_sources,
        "avg_final_score": round(avg_score or 0, 2),
        "avg_clickbait_score": round(avg_clickbait or 0, 3),
    }


# ---------------------------------------------------------------------------
# Serve frontend
# ---------------------------------------------------------------------------
if FRONTEND_DIR.exists():
    app.mount("/static", StaticFiles(directory=str(FRONTEND_DIR)), name="static")

    @app.get("/")
    async def serve_index():
        return FileResponse(str(FRONTEND_DIR / "index.html"))


# ---------------------------------------------------------------------------
# Startup / Shutdown
# ---------------------------------------------------------------------------
@app.on_event("startup")
async def on_startup():
    await init_db()
    # Initial fetch
    asyncio.create_task(refresh_all_sources())
    # Schedule every 15 minutes
    scheduler.add_job(refresh_all_sources, "interval", minutes=15, id="refresh_feeds")
    scheduler.start()
    logger.info("Scheduler started (refresh every 15 min)")


@app.on_event("shutdown")
async def on_shutdown():
    scheduler.shutdown(wait=False)


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
