"""Serves the web export the way itch.io does, to try it before uploading.

    python tools/web/serve.py                  # builds/web, then open http://localhost:8060/
    python tools/web/serve.py --upload 2       # as a later upload of the game, at another path
    python tools/web/serve.py --build path/to/web/export

itch.io shows a browser game in an iframe on its own page, the game's files coming from another site
(its CDN), so the game's storage is a third party's to the browser: partitioned under itch.io, and
blocked or wiped by some browsers and settings. This does the same with two local sites: the page on
localhost and the game on 127.0.0.1, in an iframe. Like itch's CDN it gzips html, js, css, svg, wasm,
wav, glb and pck files, serves each upload under a path of its own, and sends no cross origin isolation
headers, so a build that needs threads (SharedArrayBuffer) will not start here, as it would not there
unless that option is ticked. Standard library only.
"""

import argparse
import gzip
import http.server
import pathlib
import threading

ROOT = pathlib.Path(__file__).resolve().parents[2]
PAGE_PORT = 8060
GAME_PORT = 8061
# The file types itch.io's CDN gzips when they are uploaded uncompressed, by its HTML5 docs.
GZIPPED = {".html", ".js", ".css", ".svg", ".wasm", ".wav", ".glb", ".pck"}
TYPES = {".html": "text/html", ".js": "application/javascript", ".wasm": "application/wasm", ".pck": "application/octet-stream",
         ".png": "image/png", ".css": "text/css", ".svg": "image/svg+xml", ".json": "application/json"}

PAGE = """<!doctype html>
<html lang="en"><head><meta charset="utf-8"><title>Your Call, served as on itch.io</title>
<style>
body {{ margin: 0; background: #1b1a17; color: #c0bbb0; font: 15px Georgia, serif; }}
p {{ margin: 10px 16px; }}
iframe {{ display: block; margin: 0 auto; border: 0; width: min(100vw, 1280px); aspect-ratio: 16 / 9; }}
</style></head><body>
<p>The game below is served from {game_origin}, a site of its own, in an iframe, as itch.io serves it. Upload {upload}.</p>
<iframe src="{game_origin}/html/{upload}/index.html" allow="autoplay; fullscreen *; gamepad"
  allowfullscreen></iframe>
</body></html>
"""


class GameFiles(http.server.SimpleHTTPRequestHandler):
    """The game's files, under /html/<upload>/, gzipped as itch's CDN does."""

    build: pathlib.Path
    # Each file gzipped once, by path and when it last changed: a pck is slow to squeeze.
    squeezed: dict = {}
    lock = threading.Lock()

    def do_GET(self) -> None:
        parts = self.path.split("?")[0].strip("/").split("/")
        if len(parts) < 3 or parts[0] != "html":
            self.send_error(404)
            return
        file = (self.build / "/".join(parts[2:])).resolve()
        if not file.is_file() or self.build not in file.parents:
            # itch.io answers a missing file with 403, not 404.
            self.send_error(403)
            return
        data = file.read_bytes()
        self.send_response(200)
        self.send_header("Content-Type", TYPES.get(file.suffix, "application/octet-stream"))
        if file.suffix in GZIPPED and "gzip" in self.headers.get("Accept-Encoding", ""):
            key = (str(file), file.stat().st_mtime)
            with self.lock:
                if key not in self.squeezed:
                    self.squeezed[key] = gzip.compress(data, compresslevel=6)
                data = self.squeezed[key]
            self.send_header("Content-Encoding", "gzip")
        self.send_header("Content-Length", str(len(data)))
        self.send_header("Cache-Control", "no-cache")
        self.end_headers()
        self.wfile.write(data)

    def log_message(self, format: str, *args: object) -> None:
        pass


class Page(http.server.BaseHTTPRequestHandler):
    """The page the game is embedded in, as itch.io's game page."""

    upload: int

    def do_GET(self) -> None:
        body = PAGE.format(game_origin=f"http://127.0.0.1:{GAME_PORT}", upload=self.upload).encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "text/html")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, format: str, *args: object) -> None:
        pass


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--build", type=pathlib.Path, default=ROOT / "builds" / "web", help="the web export's folder")
    parser.add_argument("--upload", type=int, default=1, help="which upload of the game to serve it as")
    args = parser.parse_args()
    GameFiles.build = args.build.resolve()
    Page.upload = args.upload
    game = http.server.ThreadingHTTPServer(("127.0.0.1", GAME_PORT), GameFiles)
    page = http.server.ThreadingHTTPServer(("localhost", PAGE_PORT), Page)
    threading.Thread(target=game.serve_forever, daemon=True).start()
    print(f"Serving {GameFiles.build} as upload {args.upload}: open http://localhost:{PAGE_PORT}/ (Ctrl+C stops)", flush=True)
    try:
        page.serve_forever()
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    main()
