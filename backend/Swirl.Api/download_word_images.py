#!/usr/bin/env python3
"""Download educational PNG images for English words using ddgs."""

import json
import os
import time

import requests
from ddgs import DDGS
from PIL import Image

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
DEFAULT_WORDS_FILE = os.path.join(SCRIPT_DIR, "words.json")
OUTPUT_DIR = os.path.join(SCRIPT_DIR, "wwwroot", "media", "images", "words")
FALLBACK_WORDS_FILE = os.path.join(OUTPUT_DIR, "words.json")
MIN_IMAGE_SIZE = 512
SEARCH_PAUSE_SECONDS = 1.0
REQUEST_TIMEOUT_SECONDS = 20
USER_AGENT = "Swirl educational word image downloader/1.0"


def resolve_words_file():
    if os.path.exists(DEFAULT_WORDS_FILE):
        return DEFAULT_WORDS_FILE
    if os.path.exists(FALLBACK_WORDS_FILE):
        return FALLBACK_WORDS_FILE
    return DEFAULT_WORDS_FILE


def load_words(words_file):
    with open(words_file, "r", encoding="utf-8") as handle:
        payload = json.load(handle)

    words = []
    for item in payload:
        english = str(item.get("english", "")).strip()
        if english:
            words.append(english)

    return words


def build_query(english):
    return f"{english} object isolated png 2D cartoon educational"


def to_file_stem(english):
    cleaned = []
    previous_was_separator = False

    for char in english.strip().lower():
        if char.isalnum():
            cleaned.append(char)
            previous_was_separator = False
        elif not previous_was_separator:
            cleaned.append("_")
            previous_was_separator = True

    return "".join(cleaned).strip("_")


def output_path_for_word(english, output_dir=OUTPUT_DIR):
    file_stem = to_file_stem(english)
    return os.path.join(output_dir, f"{file_stem}.png")


def result_is_large_enough(result):
    width = result.get("width")
    height = result.get("height")

    if width is None or height is None:
        return True

    try:
        return int(width) >= MIN_IMAGE_SIZE and int(height) >= MIN_IMAGE_SIZE
    except (TypeError, ValueError):
        return True


def search_image_url(english):
    query = build_query(english)
    try:
        with DDGS() as ddgs:
            results = ddgs.images(
                query,
                safesearch="strict",
                max_results=20,
            )

            for result in results:
                image_url = result.get("image")
                if image_url and result_is_large_enough(result):
                    return image_url
    except Exception as e:
        print(f"Search failed for {english}: {e}")
    return None


def download_image(image_url):
    response = requests.get(
        image_url,
        headers={"User-Agent": USER_AGENT},
        timeout=REQUEST_TIMEOUT_SECONDS,
    )
    response.raise_for_status()

    content_type = response.headers.get("Content-Type", "")
    if content_type and not content_type.lower().startswith("image/"):
        raise ValueError("Downloaded content is not an image")

    return response.content


def save_png(image_bytes, output_path):
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    temporary_path = output_path + ".download"

    with open(temporary_path, "wb") as handle:
        handle.write(image_bytes)

    try:
        with Image.open(temporary_path) as image:
            width, height = getattr(image, "size", (MIN_IMAGE_SIZE, MIN_IMAGE_SIZE))
            if width < MIN_IMAGE_SIZE or height < MIN_IMAGE_SIZE:
                raise ValueError("Image is smaller than 512x512")

            if image.mode not in ("RGB", "RGBA"):
                image = image.convert("RGBA")
            elif image.mode == "RGB":
                image = image.convert("RGBA")

            image.save(output_path, format="PNG")
    finally:
        if os.path.exists(temporary_path):
            os.remove(temporary_path)


def sleep_between_requests():
    delay = SEARCH_PAUSE_SECONDS + (time.time() % 1.0)
    time.sleep(delay)


def download_word_images(words_file=None, output_dir=OUTPUT_DIR):
    words = load_words(words_file or resolve_words_file())
    downloaded = 0
    skipped = 0
    errors = 0

    os.makedirs(output_dir, exist_ok=True)

    for index, english in enumerate(words, start=1):
        output_path = output_path_for_word(english, output_dir)

        if os.path.exists(output_path):
            skipped += 1
            print(f"[{index}/{len(words)}] {english}: already exists, skipped")
            continue

        try:
            image_url = search_image_url(english)
            if not image_url:
                errors += 1
                print(f"[{index}/{len(words)}] {english}: image not found")
                continue

            image_bytes = download_image(image_url)
            save_png(image_bytes, output_path)
            downloaded += 1
            print(f"[{index}/{len(words)}] {english}: saved to {output_path}")
        except Exception as exc:
            errors += 1
            print(f"[{index}/{len(words)}] {english}: skipped after error: {exc}")

        sleep_between_requests()

    print("")
    print("Done.")
    print(f"Downloaded: {downloaded}")
    print(f"Skipped existing: {skipped}")
    print(f"Errors: {errors}")

    return {
        "downloaded": downloaded,
        "skipped": skipped,
        "errors": errors,
    }


if __name__ == "__main__":
    download_word_images()