import json
import os
import socket
from http.server import BaseHTTPRequestHandler, HTTPServer

DATA_FILE = "/data/fact.txt"


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        try:
            with open(DATA_FILE, encoding="utf-8") as f:
                fact = f.read().strip()
        except FileNotFoundError:
            print("file not found:", DATA_FILE, flush=True)
            self.answer(500, {"error": "file not found " + DATA_FILE})
            return

        if self.path == "/health":
            self.answer(200, {"status": "ok"})
        else:
            self.answer(200, {
                "name": os.getenv("STUDENT_NAME"),
                "variant": os.getenv("VARIANT"),
                "id": os.getenv("PERSONAL_ID"),
                "hostname": socket.gethostname(),
                "fact": fact,
            })

    def answer(self, code, data):
        self.send_response(code)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.end_headers()
        self.wfile.write(json.dumps(data, ensure_ascii=False).encode())


print("backend started on 5000", flush=True)
HTTPServer(("", 5000), Handler).serve_forever()
