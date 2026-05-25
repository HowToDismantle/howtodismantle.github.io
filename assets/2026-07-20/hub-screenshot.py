#!/usr/bin/env python3
"""Download a screenshot of a Peakboard Box via the Hub Public API.

Usage:
    PEAKBOARD_API_KEY=<your-key> python hub-screenshot.py <box-id> [output.png]

The API key is read from PEAKBOARD_API_KEY so it never ends up in source
control. The box id is the Hub-side identifier of the Box; copy it from the
Box detail page in the Hub UI.
"""
import base64
import os
import sys
import requests

BASE = "https://api.peakboard.com/public-api"


def get_token(api_key: str) -> str:
    r = requests.get(f"{BASE}/v2/auth/token", headers={"apiKey": api_key}, timeout=30)
    r.raise_for_status()
    return r.json()["accessToken"]


def fetch_screenshot(token: str, box_id: str) -> bytes:
    # The endpoint returns the PNG as a base64-encoded string with
    # Content-Type text/plain, so we decode r.text before returning.
    r = requests.get(
        f"{BASE}/v1/box/screenshot",
        params={"boxId": box_id},
        headers={"Authorization": f"Bearer {token}"},
        timeout=60,
    )
    r.raise_for_status()
    return base64.b64decode(r.text)


def main() -> None:
    api_key = os.environ.get("PEAKBOARD_API_KEY")
    if not api_key:
        sys.exit("Set PEAKBOARD_API_KEY in the environment.")
    if len(sys.argv) < 2:
        sys.exit("Usage: hub-screenshot.py <box-id> [output.png]")

    box_id = sys.argv[1]
    out_path = sys.argv[2] if len(sys.argv) > 2 else "screenshot.png"

    token = get_token(api_key)
    image = fetch_screenshot(token, box_id)
    with open(out_path, "wb") as f:
        f.write(image)
    print(f"Wrote {len(image)} bytes to {out_path}")


if __name__ == "__main__":
    main()
