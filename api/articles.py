from http.server import BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs
import json
import sys
import os

sys.path.insert(0, os.path.dirname(__file__))
from _data import ARTICLES, SOURCE_MAP


class handler(BaseHTTPRequestHandler):
    def do_GET(self):
        qs = parse_qs(urlparse(self.path).query)

        def qget(k, default=None):
            v = qs.get(k)
            return v[0] if v else default

        page      = int(qget("page", 1))
        per_page  = int(qget("per_page", 40))
        sort      = qget("sort", "date")
        search    = (qget("search") or "").lower()
        country   = qget("country", "")
        min_score = float(qget("min_score", 1))
        max_cb    = float(qget("max_clickbait", 1))
        tag       = qget("tag", "")
        source_id = qget("source_id", "")

        # Filter
        filtered = []
        for a in ARTICLES:
            src = SOURCE_MAP.get(a["source"]["id"], {})
            if not src.get("enabled", True):
                continue
            if search and search not in a["title"].lower() and search not in (a["summary"] or "").lower():
                continue
            if country and src.get("country") != country:
                continue
            if min_score > 1 and a["scores"]["final_score"] < min_score:
                continue
            if max_cb < 1 and a["scores"]["clickbait_score"] > max_cb:
                continue
            if tag and tag not in src.get("tags", []):
                continue
            if source_id and a["source"]["id"] != source_id:
                continue
            filtered.append(a)

        # Sort
        if sort == "score":
            filtered.sort(key=lambda a: (-a["scores"]["final_score"], a["published_at"]))
        else:
            filtered.sort(key=lambda a: a["published_at"], reverse=True)

        total = len(filtered)
        start = (page - 1) * per_page
        page_items = filtered[start:start + per_page]

        data = {"total": total, "page": page, "per_page": per_page, "articles": page_items}
        body = json.dumps(data).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self._cors()
        self.end_headers()
        self.wfile.write(body)

    def do_OPTIONS(self):
        self.send_response(204)
        self._cors()
        self.end_headers()

    def _cors(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")

    def log_message(self, *args):
        pass
