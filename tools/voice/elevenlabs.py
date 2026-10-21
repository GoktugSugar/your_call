"""A small ElevenLabs HTTP client for the voice tools, using only the standard library.

The key comes from the ELEVENLABS_API_KEY environment variable, or from .env at the project root.
It is never printed or written anywhere else.
"""

import json
import os
import pathlib
import sys
import urllib.error
import urllib.request

API = "https://api.elevenlabs.io/v1"
ROOT = pathlib.Path(__file__).resolve().parents[2]
TIMEOUT_SECONDS = 300


class ApiError(Exception):
    def __init__(self, status: int, body: str):
        super().__init__(f"HTTP {status}: {body[:600]}")
        self.status = status
        self.body = body


def api_key() -> str:
    key = os.environ.get("ELEVENLABS_API_KEY", "").strip()
    env_file = ROOT / ".env"
    if not key and env_file.exists():
        for line in env_file.read_text(encoding="utf-8").splitlines():
            name, _, value = line.partition("=")
            if name.strip() == "ELEVENLABS_API_KEY":
                key = value.strip().strip('"').strip("'")
    if not key:
        sys.exit("No ELEVENLABS_API_KEY in the environment or in .env at the project root.")
    return key


def request(method: str, path: str, key: str, body: dict | None = None) -> dict:
    data = json.dumps(body).encode("utf-8") if body is not None else None
    req = urllib.request.Request(API + path, data=data, method=method, headers={
        "xi-api-key": key,
        "Content-Type": "application/json",
        "Accept": "application/json",
    })
    try:
        with urllib.request.urlopen(req, timeout=TIMEOUT_SECONDS) as response:
            return json.loads(response.read().decode("utf-8"))
    except urllib.error.HTTPError as error:
        raise ApiError(error.code, error.read().decode("utf-8", "replace")) from None
