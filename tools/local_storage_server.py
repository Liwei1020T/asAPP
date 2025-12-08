#!/usr/bin/env python3
"""
Simple HTTP server for ASP-MS local storage.

Features:
- Serves files under ../local_storage via GET.
- Accepts file uploads via:
    POST /upload?folder=<folder>&filename=<name>
  and writes them under ../local_storage/<folder>/<name>.
- Returns JSON: {"path": "<relative/path>"} which is used by StorageRepository
  together with StorageConfig.publicBaseUrl.
"""

import http.server
import json
import os
import socketserver
from urllib.parse import urlparse, parse_qs


PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BASE_DIR = os.path.join(PROJECT_ROOT, "local_storage")
PORT = int(os.environ.get("LOCAL_STORAGE_PORT", "9000"))


class UploadHandler(http.server.SimpleHTTPRequestHandler):
  """Serve files from BASE_DIR and handle /upload for file writes."""

  def __init__(self, *args, **kwargs):
    super().__init__(*args, directory=BASE_DIR, **kwargs)

  # Basic CORS support so Cloudflare Pages / browsers can call this API.
  def end_headers(self):
    self.send_header("Access-Control-Allow-Origin", "*")
    self.send_header("Access-Control-Allow-Methods", "GET,POST,OPTIONS")
    self.send_header("Access-Control-Allow-Headers", "Content-Type")
    super().end_headers()

  def do_OPTIONS(self):
    self.send_response(204)
    self.end_headers()

  def do_POST(self):
    parsed = urlparse(self.path)
    if parsed.path != "/upload":
      self.send_error(404, "Unsupported POST path")
      return

    params = parse_qs(parsed.query)
    folder = params.get("folder", [""])[0].strip().strip("/\\")
    filename = params.get("filename", [""])[0].strip()

    if not filename:
      self.send_error(400, "Missing filename query parameter")
      return

    try:
      length = int(self.headers.get("Content-Length", "0"))
    except ValueError:
      self.send_error(400, "Invalid Content-Length header")
      return

    data = self.rfile.read(length)

    # Resolve target path under BASE_DIR
    safe_folder = folder.replace("\\", "/").strip("/")
    rel_path = f"{safe_folder}/{filename}" if safe_folder else filename
    target_dir = os.path.join(BASE_DIR, *safe_folder.split("/")) if safe_folder else BASE_DIR
    os.makedirs(target_dir, exist_ok=True)
    target_path = os.path.join(target_dir, filename)

    try:
      with open(target_path, "wb") as f:
        f.write(data)
    except OSError as exc:
      self.send_error(500, f"Failed to write file: {exc}")
      return

    # Respond with JSON containing the relative path (POSIX style)
    response = {"path": rel_path.replace("\\", "/")}

    self.send_response(200)
    self.send_header("Content-Type", "application/json; charset=utf-8")
    self.end_headers()
    self.wfile.write(json.dumps(response).encode("utf-8"))


def main():
  os.makedirs(BASE_DIR, exist_ok=True)
  with socketserver.TCPServer(("", PORT), UploadHandler) as httpd:
    print(f"[local_storage_server] Serving {BASE_DIR} at http://127.0.0.1:{PORT}")
    try:
      httpd.serve_forever()
    except KeyboardInterrupt:
      print("\n[local_storage_server] Shutting down...")


if __name__ == "__main__":
  main()

