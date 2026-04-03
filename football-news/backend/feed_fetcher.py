"""
RSS/Atom feed fetcher using Python's built-in xml.etree.ElementTree.
No external parser dependency needed.
"""
import asyncio
import hashlib
import logging
import re
from datetime import datetime
from typing import Optional
from xml.etree import ElementTree as ET

import httpx
from dateutil import parser as dateparser

logger = logging.getLogger(__name__)

NITTER_INSTANCES = [
    "https://nitter.net",
    "https://nitter.privacydev.net",
    "https://nitter.poast.org",
]

HEADERS = {
    "User-Agent": "Mozilla/5.0 (compatible; FootballNewsAggregator/1.0)"
}

# XML namespaces used in RSS/Atom feeds
NS = {
    "atom":  "http://www.w3.org/2005/Atom",
    "media": "http://search.yahoo.com/mrss/",
    "dc":    "http://purl.org/dc/elements/1.1/",
    "content": "http://purl.org/rss/1.0/modules/content/",
}


def make_article_id(url: str) -> str:
    return hashlib.sha256(url.encode()).hexdigest()[:16]


def _strip_html(text: str) -> str:
    return re.sub(r"<[^>]+>", "", text or "").strip()


def _parse_date(raw: str) -> datetime:
    if not raw:
        return datetime.utcnow()
    try:
        return dateparser.parse(raw, ignoretz=True)
    except Exception:
        return datetime.utcnow()


def _find_text(el, *paths) -> Optional[str]:
    """Try multiple XPath-style paths, return first match."""
    for path in paths:
        node = el.find(path, NS)
        if node is not None and node.text:
            return node.text.strip()
    return None


def _find_attr(el, attr, *paths) -> Optional[str]:
    for path in paths:
        node = el.find(path, NS)
        if node is not None and node.get(attr):
            return node.get(attr)
    return None


def _extract_image_from_text(text: str) -> Optional[str]:
    m = re.search(r'<img[^>]+src=["\']([^"\']+)["\']', text or "")
    return m.group(1) if m else None


def _parse_rss_entries(root: ET.Element) -> list[dict]:
    """Parse RSS 2.0 <item> elements."""
    items = []
    channel = root.find("channel")
    if channel is None:
        return items

    for item in channel.findall("item"):
        link = _find_text(item, "link") or _find_text(item, "guid")
        title = _find_text(item, "title")
        if not link or not title:
            continue

        summary_raw = _find_text(item, "description") or _find_text(item, "content:encoded", "content")
        summary = _strip_html(summary_raw)[:500] if summary_raw else None

        pub_date = _find_text(item, "pubDate") or _find_text(item, "dc:date")
        author = _find_text(item, "author") or _find_text(item, "dc:creator")

        # Image: media:content, enclosure
        image_url = None
        media = item.find("media:content", NS)
        if media is not None:
            image_url = media.get("url")
        if not image_url:
            enc = item.find("enclosure")
            if enc is not None and (enc.get("type", "").startswith("image") or not enc.get("type")):
                image_url = enc.get("url")
        if not image_url and summary_raw:
            image_url = _extract_image_from_text(summary_raw)

        items.append({
            "id": make_article_id(link),
            "title": title,
            "url": link,
            "summary": summary,
            "published_at": _parse_date(pub_date),
            "author": author,
            "image_url": image_url,
        })
    return items


def _parse_atom_entries(root: ET.Element) -> list[dict]:
    """Parse Atom 1.0 <entry> elements."""
    items = []
    for entry in root.findall("atom:entry", NS):
        link_el = entry.find("atom:link[@rel='alternate']", NS) or entry.find("atom:link", NS)
        link = link_el.get("href") if link_el is not None else None
        if not link:
            id_el = entry.find("atom:id", NS)
            link = id_el.text if id_el is not None else None
        title_el = entry.find("atom:title", NS)
        title = title_el.text.strip() if title_el is not None and title_el.text else None
        if not link or not title:
            continue

        summary_el = entry.find("atom:summary", NS) or entry.find("atom:content", NS)
        summary_raw = summary_el.text if summary_el is not None else None
        summary = _strip_html(summary_raw)[:500] if summary_raw else None

        pub_el = entry.find("atom:published", NS) or entry.find("atom:updated", NS)
        pub_date = pub_el.text if pub_el is not None else None

        author_el = entry.find("atom:author/atom:name", NS)
        author = author_el.text.strip() if author_el is not None and author_el.text else None

        image_url = None
        media = entry.find("media:content", NS)
        if media is not None:
            image_url = media.get("url")
        if not image_url and summary_raw:
            image_url = _extract_image_from_text(summary_raw)

        items.append({
            "id": make_article_id(link),
            "title": title,
            "url": link,
            "summary": summary,
            "published_at": _parse_date(pub_date),
            "author": author,
            "image_url": image_url,
        })
    return items


def _parse_feed_xml(content: str) -> list[dict]:
    try:
        root = ET.fromstring(content)
    except ET.ParseError as e:
        logger.warning(f"XML parse error: {e}")
        return []

    tag = root.tag.lower()
    if "rss" in tag or root.find("channel") is not None:
        return _parse_rss_entries(root)
    if "feed" in tag or "atom" in tag.lower():
        return _parse_atom_entries(root)
    # Try both
    items = _parse_rss_entries(root)
    if not items:
        items = _parse_atom_entries(root)
    return items


async def fetch_feed(url: str, timeout: int = 15) -> list[dict]:
    try:
        async with httpx.AsyncClient(headers=HEADERS, follow_redirects=True, timeout=timeout) as client:
            resp = await client.get(url)
            resp.raise_for_status()
            content = resp.text
    except Exception as exc:
        logger.warning(f"HTTP fetch failed for {url}: {exc}")
        return []

    return _parse_feed_xml(content)[:50]


async def fetch_twitter_feed(handle: str, timeout: int = 15) -> list[dict]:
    for instance in NITTER_INSTANCES:
        url = f"{instance}/{handle}/rss"
        articles = await fetch_feed(url, timeout=timeout)
        if articles:
            return articles
        await asyncio.sleep(0.5)
    logger.warning(f"All Nitter instances failed for @{handle}")
    return []
