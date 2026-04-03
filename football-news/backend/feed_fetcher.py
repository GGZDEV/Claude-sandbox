"""
RSS feed fetcher. Uses feedparser for standard RSS/Atom feeds.
Twitter handles are fetched via Nitter RSS mirrors.
"""
import hashlib
import logging
from datetime import datetime
from typing import Optional
import asyncio

import feedparser
import httpx
from dateutil import parser as dateparser

logger = logging.getLogger(__name__)

# Nitter instances to try in order
NITTER_INSTANCES = [
    "https://nitter.net",
    "https://nitter.privacydev.net",
    "https://nitter.poast.org",
]

HEADERS = {
    "User-Agent": "Mozilla/5.0 (compatible; FootballNewsAggregator/1.0; +https://github.com/ggzdev/claude-sandbox)"
}


def make_article_id(url: str) -> str:
    return hashlib.sha256(url.encode()).hexdigest()[:16]


def parse_date(entry) -> datetime:
    for field in ("published_parsed", "updated_parsed"):
        val = getattr(entry, field, None)
        if val:
            import time
            try:
                return datetime.fromtimestamp(time.mktime(val))
            except Exception:
                pass
    for field in ("published", "updated"):
        val = getattr(entry, field, None)
        if val:
            try:
                return dateparser.parse(val, ignoretz=True)
            except Exception:
                pass
    return datetime.utcnow()


def extract_image(entry) -> Optional[str]:
    # Try media:content or enclosures
    media = getattr(entry, "media_content", None)
    if media and isinstance(media, list) and media[0].get("url"):
        return media[0]["url"]
    enclosures = getattr(entry, "enclosures", None)
    if enclosures:
        for enc in enclosures:
            if enc.get("type", "").startswith("image"):
                return enc.get("href") or enc.get("url")
    # Try og:image in summary html
    summary = getattr(entry, "summary", "") or ""
    import re
    m = re.search(r'<img[^>]+src=["\']([^"\']+)["\']', summary)
    if m:
        return m.group(1)
    return None


async def fetch_feed(url: str, timeout: int = 15) -> list[dict]:
    """
    Fetch and parse an RSS/Atom feed. Returns a list of raw article dicts.
    """
    try:
        async with httpx.AsyncClient(headers=HEADERS, follow_redirects=True, timeout=timeout) as client:
            resp = await client.get(url)
            resp.raise_for_status()
            content = resp.text
    except Exception as exc:
        logger.warning(f"HTTP fetch failed for {url}: {exc}")
        return []

    try:
        feed = feedparser.parse(content)
    except Exception as exc:
        logger.warning(f"feedparser failed for {url}: {exc}")
        return []

    articles = []
    for entry in feed.entries[:50]:  # cap at 50 per fetch
        link = getattr(entry, "link", None) or getattr(entry, "id", None)
        if not link:
            continue
        title = getattr(entry, "title", "").strip()
        if not title:
            continue
        summary = getattr(entry, "summary", None) or getattr(entry, "description", None) or ""
        # Strip html tags from summary
        import re
        summary = re.sub(r"<[^>]+>", "", summary).strip()

        articles.append({
            "id": make_article_id(link),
            "title": title,
            "url": link,
            "summary": summary[:500] if summary else None,
            "published_at": parse_date(entry),
            "author": getattr(entry, "author", None),
            "image_url": extract_image(entry),
        })

    return articles


async def fetch_twitter_feed(handle: str, timeout: int = 15) -> list[dict]:
    """
    Try each Nitter instance to get the RSS feed for a Twitter handle.
    """
    for instance in NITTER_INSTANCES:
        url = f"{instance}/{handle}/rss"
        articles = await fetch_feed(url, timeout=timeout)
        if articles:
            return articles
        await asyncio.sleep(0.5)
    logger.warning(f"All Nitter instances failed for @{handle}")
    return []
