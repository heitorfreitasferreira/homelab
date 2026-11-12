#!/usr/bin/env python3
"""Receives one POST on 127.0.0.1 and writes the body to a 0600 file, then exits.

Used to move credentials from the browser to disk without echoing them.
Usage: receber-segredo.py <port> <output-file>
"""
import os
import sys
from http.server import BaseHTTPRequestHandler, HTTPServer

PORT = int(sys.argv[1])
OUT = sys.argv[2]


class Handler(BaseHTTPRequestHandler):
    def _cors(self):
        self.send_header("Access-Control-Allow-Origin", "https://dash.cloudflare.com")
        self.send_header("Access-Control-Allow-Methods", "POST")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.send_header("Access-Control-Allow-Private-Network", "true")

    def do_OPTIONS(self):
        self.send_response(204)
        self._cors()
        self.end_headers()

    def do_POST(self):
        body = self.rfile.read(min(int(self.headers.get("Content-Length", 0)), 8192))
        fd = os.open(OUT, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
        with os.fdopen(fd, "wb") as f:
            f.write(body)
        self.send_response(200)
        self._cors()
        self.end_headers()
        self.wfile.write(b"ok")
        self.server.done = True

    def log_message(self, *args):
        pass


srv = HTTPServer(("127.0.0.1", PORT), Handler)
srv.done = False
srv.timeout = 120
while not srv.done:
    srv.handle_request()
