#!/usr/bin/env python3
"""Generate PNG images for the first 10 words in words.json using Polza.ai."""

from __future__ import annotations

import base64
import json
import os
import time
from pathlib import Path
from typing import Any

import requests

try:
    from dotenv import load_dotenv
except ImportError:
    def load_dotenv(*_args: Any, **_kwargs: Any) -> bool:
        return False


PROJECT_ROOT = Path(__file__).resolve().parent
WORDS_DIR = PROJECT_ROOT / "backend" / "Swirl.Api" / "wwwroot" / "media" / "images" / "words"
WORDS_FILE = WORDS_DIR / "words.json"
OUTPUT_DIR = WORDS_DIR

POLZA_MEDIA_API_URL = "https://polza.ai/api/v1/media"

# Grok Image / Grok Imagine image model in Polza.ai.
# If Polza.ai changes the exact model id, update only this constant.
MODEL_ID = "x-ai/grok-imagine-image"

REQUEST_TIMEOUT_SECONDS = 90
DOWNLOAD_TIMEOUT_SECONDS = 60
DELAY_BETWEEN_REQUESTS_SECONDS = 2.0
MAX_WORDS = 10


def load_words(words_file: Path = WORDS_FILE) -> list[str]:
    """Read words.json and return english values from the first 10 items."""
    with words_file.open("r", encoding="utf-8") as handle:
        payload = json.load(handle)

    if not isinstance(payload, list):
        raise ValueError("words.json must contain a JSON array.")

    words: list[str] = []
    for index, item in enumerate(payload[:MAX_WORDS], start=1):
        if not isinstance(item, dict):
            print(f"Warning: item #{index} is not an object, skipped.")
            continue

        english = str(item.get("english", "")).strip()
        if not english:
            print(f"Warning: item #{index} has no english value, skipped.")
            continue

        words.append(english)

    return words


def generate_prompt(word: str) -> str:
    """Build a consistent image prompt for one vocabulary word."""
    return (
        f'Create a clean 2D slightly cartoon illustration of the English word "{word}" '
        "for a mobile app vocabulary card. Friendly educational style, soft rounded "
        "shapes, centered main object, simple light background, soft colors, minimal "
        "details, clear recognizable object, no text, no letters, no watermark, no "
        "logo, square composition. All images must look like one consistent image set "
        "for the same app."
    )


def request_polza_image(api_key: str, prompt: str) -> dict[str, Any]:
    """Send one image generation request to Polza.ai Media API."""
    response = requests.post(
        POLZA_MEDIA_API_URL,
        headers={
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
            "Accept": "application/json",
        },
        json={
            "model": MODEL_ID,
            "input": {
                "prompt": prompt,
                "aspect_ratio": "1:1",
                "max_images": 1,
            },
        },
        timeout=REQUEST_TIMEOUT_SECONDS,
    )
    response.raise_for_status()

    try:
        return response.json()
    except json.JSONDecodeError as exc:
        raise RuntimeError("Polza.ai returned a non-JSON response.") from exc


def extract_image_source(payload: Any) -> str:
    """Find the first image URL or base64 image string in a Polza.ai response."""
    source = find_image_source_by_key(payload)
    if source:
        return source

    source = find_image_source_anywhere(payload)
    if source:
        return source

    raise ValueError(f"Could not find an image URL or base64 data in response: {payload}")


def find_image_source_by_key(payload: Any) -> str | None:
    """Prefer values stored under common image-related response keys."""
    preferred_keys = {
        "url",
        "image_url",
        "uri",
        "b64_json",
        "base64",
        "image_base64",
        "data",
        "image",
        "content",
    }

    if isinstance(payload, dict):
        for key, value in payload.items():
            if str(key).lower() in preferred_keys and isinstance(value, str) and is_image_source(value):
                return value

        for value in payload.values():
            source = find_image_source_by_key(value)
            if source:
                return source

    if isinstance(payload, list):
        for item in payload:
            source = find_image_source_by_key(item)
            if source:
                return source

    return None


def find_image_source_anywhere(payload: Any) -> str | None:
    """Fallback scan for response formats that use unexpected field names."""
    if isinstance(payload, str) and is_image_source(payload):
        return payload

    if isinstance(payload, dict):
        for value in payload.values():
            source = find_image_source_anywhere(value)
            if source:
                return source

    if isinstance(payload, list):
        for item in payload:
            source = find_image_source_anywhere(item)
            if source:
                return source

    return None


def is_image_source(value: str) -> bool:
    """Return True when a string looks like an image URL, data URL, or base64."""
    stripped = value.strip()
    if stripped.startswith(("http://", "https://")):
        return True
    if stripped.startswith("data:image/") and ";base64," in stripped:
        return True
    return looks_like_base64(stripped)


def looks_like_base64(value: str) -> bool:
    """Lightweight base64 check used only after URL/data URL checks."""
    if len(value) < 64:
        return False

    compact = "".join(value.split())
    if len(compact) % 4 != 0:
        return False

    try:
        base64.b64decode(compact, validate=True)
        return True
    except Exception:
        return False


def save_image(image_source: str, output_path: Path) -> None:
    """Save an image source returned by Polza.ai to a PNG file path."""
    output_path.parent.mkdir(parents=True, exist_ok=True)

    if image_source.startswith(("http://", "https://")):
        image_bytes = download_image(image_source)
    else:
        image_bytes = decode_base64_image(image_source)

    temporary_path = output_path.with_suffix(output_path.suffix + ".tmp")
    temporary_path.write_bytes(image_bytes)
    temporary_path.replace(output_path)


def download_image(image_url: str) -> bytes:
    """Download an image from a URL returned by Polza.ai."""
    response = requests.get(image_url, timeout=DOWNLOAD_TIMEOUT_SECONDS)
    response.raise_for_status()

    content_type = response.headers.get("Content-Type", "")
    if content_type and not content_type.lower().startswith("image/"):
        raise ValueError(f"URL did not return an image. Content-Type: {content_type}")

    return response.content


def decode_base64_image(image_source: str) -> bytes:
    """Decode raw base64 or data:image/...;base64 payloads."""
    encoded = image_source.strip()
    if encoded.startswith("data:image/"):
        encoded = encoded.split(",", 1)[1]

    try:
        return base64.b64decode("".join(encoded.split()), validate=True)
    except Exception as exc:
        raise ValueError("Image payload is not valid base64.") from exc


def output_path_for_word(word: str, output_dir: Path = OUTPUT_DIR) -> Path:
    """Build the requested PNG file path for an English word."""
    file_name = f"{word.strip().lower()}.png"
    file_name = file_name.replace("/", "_").replace("\\", "_")
    return output_dir / file_name


def main() -> int:
    load_dotenv()

    api_key = os.environ.get("POLZA_API_KEY")
    if not api_key:
        print("Error: POLZA_API_KEY environment variable is not set.")
        return 1

    try:
        words = load_words()
    except Exception as exc:
        print(f"Error: failed to read {WORDS_FILE}: {exc}")
        return 1

    created = 0
    skipped = 0
    errors = 0

    for index, word in enumerate(words, start=1):
        output_path = output_path_for_word(word)

        if output_path.exists():
            skipped += 1
            print(f"[{index}/{len(words)}] {word}: already exists, skipped")
            continue

        try:
            prompt = generate_prompt(word)
            payload = request_polza_image(api_key, prompt)
            image_source = extract_image_source(payload)
            save_image(image_source, output_path)
            created += 1
            print(f"[{index}/{len(words)}] {word}: saved to {output_path}")
        except Exception as exc:
            errors += 1
            print(f"[{index}/{len(words)}] {word}: error: {exc}")

        time.sleep(DELAY_BETWEEN_REQUESTS_SECONDS)

    print("")
    print("Done.")
    print(f"Created: {created}")
    print(f"Skipped: {skipped}")
    print(f"Errors: {errors}")

    return 0 if errors == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
