from http.server import BaseHTTPRequestHandler
import json
import sys
import os

sys.path.insert(0, os.path.dirname(__file__))
from _data import ARTICLES, SOURCES


class handler(BaseHTTPRequestHandler):
    def do_GET(self):
        scores = [a["scores"]["final_score"] for a in ARTICLES]
        cb = [a["scores"]["clickbait_score"] for a in ARTICLES]
        data = {
            "total_articles": len(ARTICLES),
            "total_sources": sum(1 for s in SOURCES if s["enabled"]),
            "avg_final_score": round(sum(scores) / len(scores), 2) if scores else 0,
            "avg_clickbait_score": round(sum(cb) / len(cb), 3) if cb else 0,
        }
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
