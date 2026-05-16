#!/usr/bin/env python3
"""Find affordable Polza.ai image generation models for a fixed image budget."""

from __future__ import annotations

import argparse
import json
import math
import os
import re
import sys
from dataclasses import dataclass
from typing import Any
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen


ENDPOINT = "https://polza.ai/api/v1/models?type=image&include_providers=true"
DEFAULT_IMAGE_COUNT = 200
DEFAULT_BUDGET_RUB = 100.0
PRIORITY_MODEL_IDS = (
    "qwen/image",
    "black-forest-labs/flux.2-flex",
    "black-forest-labs/flux.2-pro",
    "yandex/yandex-art",
    "google/gemini-3.1-flash-image-preview",
)


@dataclass(frozen=True)
class PriceMatch:
    price_rub: float
    source: str


@dataclass(frozen=True)
class ModelPrice:
    model_id: str
    model_name: str
    provider: str
    price_rub: float
    cost_for_images: float
    supported_parameters: str
    price_source: str
    raw_pricing: str


@dataclass(frozen=True)
class UnknownPrice:
    model_id: str
    model_name: str
    provider: str
    supported_parameters: str
    raw_pricing: str


@dataclass(frozen=True)
class PriceBuckets:
    under_100: list[ModelPrice]
    from_100_to_300: list[ModelPrice]
    over_300: list[ModelPrice]
    unknown: list[UnknownPrice]


def fetch_models(api_key: str, timeout: int = 30) -> Any:
    request = Request(
        ENDPOINT,
        headers={
            "Accept": "application/json",
            "Authorization": f"Bearer {api_key}",
            "User-Agent": "check-polza-image-prices/1.0",
        },
        method="GET",
    )

    try:
        with urlopen(request, timeout=timeout) as response:
            charset = response.headers.get_content_charset() or "utf-8"
            raw_body = response.read().decode(charset)
    except HTTPError as exc:
        body = exc.read().decode("utf-8", errors="replace")
        detail = f": {body.strip()}" if body.strip() else ""
        raise RuntimeError(f"Polza.ai returned HTTP {exc.code}{detail}") from exc
    except URLError as exc:
        raise RuntimeError(f"Could not connect to Polza.ai: {exc.reason}") from exc
    except TimeoutError as exc:
        raise RuntimeError("Request to Polza.ai timed out") from exc

    try:
        return json.loads(raw_body)
    except json.JSONDecodeError as exc:
        raise RuntimeError(f"Polza.ai returned invalid JSON: {exc}") from exc


def analyze_models(
    payload: Any,
    image_count: int = DEFAULT_IMAGE_COUNT,
    budget_rub: float = DEFAULT_BUDGET_RUB,
) -> PriceBuckets:
    under_100: list[ModelPrice] = []
    from_100_to_300: list[ModelPrice] = []
    over_300: list[ModelPrice] = []
    unknown: list[UnknownPrice] = []

    for model in iter_models(payload):
        model_id = stringify(first_present(model, "id", "model_id", "slug", "code"), "unknown-model")
        model_name = stringify(first_present(model, "name", "title", "display_name"), model_id)
        model_parameters = supported_parameters(model)
        model_level_price = find_rub_image_price(model_without_provider_details(model))

        for provider in iter_providers(model):
            provider_name = get_provider_name(provider)
            provider_parameters = supported_parameters(provider)
            combined_parameters = join_nonempty(model_parameters, provider_parameters) or "-"
            raw_pricing = raw_pricing_fields(model, provider)
            price = find_rub_image_price(provider)
            if price is None:
                price = model_level_price

            if price is None:
                unknown.append(
                    UnknownPrice(
                        model_id=model_id,
                        model_name=model_name,
                        provider=provider_name,
                        supported_parameters=combined_parameters,
                        raw_pricing=raw_pricing,
                    )
                )
                continue

            cost_for_images = price.price_rub * image_count
            item = ModelPrice(
                model_id=model_id,
                model_name=model_name,
                provider=provider_name,
                price_rub=price.price_rub,
                cost_for_images=cost_for_images,
                supported_parameters=combined_parameters,
                price_source=price.source,
                raw_pricing=raw_pricing,
            )
            if cost_for_images <= 100:
                under_100.append(item)
            elif cost_for_images <= 300:
                from_100_to_300.append(item)
            else:
                over_300.append(item)

    for bucket in (under_100, from_100_to_300, over_300):
        bucket.sort(key=model_price_sort_key)
    unknown.sort(key=unknown_price_sort_key)
    return PriceBuckets(
        under_100=under_100,
        from_100_to_300=from_100_to_300,
        over_300=over_300,
        unknown=unknown,
    )


def model_price_sort_key(item: ModelPrice) -> tuple[int, float, float, str, str]:
    return (priority_rank(item.model_id), item.cost_for_images, item.price_rub, item.model_id, item.provider)


def unknown_price_sort_key(item: UnknownPrice) -> tuple[int, str, str]:
    return (priority_rank(item.model_id), item.model_id, item.provider)


def priority_rank(model_id: str) -> int:
    try:
        return PRIORITY_MODEL_IDS.index(model_id)
    except ValueError:
        return len(PRIORITY_MODEL_IDS)


def raw_pricing_fields(model: dict[str, Any], provider: dict[str, Any]) -> str:
    fields: list[dict[str, Any]] = []
    for source, data in (
        ("model", model_without_provider_details(model)),
        ("provider", provider),
    ):
        for path, value in collect_raw_pricing_fields(data):
            fields.append({"source": source, "path": path, "value": value})

    if not fields:
        return "[]"
    return json.dumps(fields, ensure_ascii=False, indent=2, sort_keys=True)


def collect_raw_pricing_fields(obj: Any, path: tuple[str, ...] = ()) -> list[tuple[str, Any]]:
    fields: list[tuple[str, Any]] = []

    if isinstance(obj, dict):
        for key, value in obj.items():
            current_path = (*path, str(key))
            if is_raw_pricing_key(str(key)):
                fields.append((".".join(current_path), value))
            fields.extend(collect_raw_pricing_fields(value, current_path))
    elif isinstance(obj, list):
        for index, value in enumerate(obj):
            fields.extend(collect_raw_pricing_fields(value, (*path, str(index))))

    return fields


def is_raw_pricing_key(key: str) -> bool:
    normalized = key.lower().replace("-", "_")
    return any(token in normalized for token in ("pricing", "price", "cost", "rate", "tariff"))


def iter_models(payload: Any) -> list[dict[str, Any]]:
    if isinstance(payload, list):
        return [item for item in payload if isinstance(item, dict)]

    if not isinstance(payload, dict):
        return []

    for key in ("data", "models", "items", "results"):
        value = payload.get(key)
        if isinstance(value, list):
            return [item for item in value if isinstance(item, dict)]
        if isinstance(value, dict):
            nested = iter_models(value)
            if nested:
                return nested

    if looks_like_model(payload):
        return [payload]

    return []


def iter_providers(model: dict[str, Any]) -> list[dict[str, Any]]:
    for key in ("providers", "model_providers", "available_providers", "provider_prices"):
        value = model.get(key)
        if isinstance(value, list):
            providers = [item for item in value if isinstance(item, dict)]
            if providers:
                return providers
        if isinstance(value, dict):
            return [value]

    return [model]


def model_without_provider_details(model: dict[str, Any]) -> dict[str, Any]:
    provider_keys = {"providers", "model_providers", "available_providers", "provider_prices"}
    return {key: value for key, value in model.items() if key not in provider_keys}


def find_rub_image_price(obj: Any) -> PriceMatch | None:
    candidates: list[PriceMatch] = []
    collect_price_candidates(obj, (), candidates)
    if not candidates:
        return None
    return min(candidates, key=lambda item: item.price_rub)


def collect_price_candidates(obj: Any, path: tuple[str, ...], candidates: list[PriceMatch]) -> None:
    if isinstance(obj, dict):
        path_text = " ".join(path).lower()
        has_rub_currency = dict_mentions_rub(obj) or "rub" in path_text or "руб" in path_text
        has_image_unit = dict_mentions_image_or_request(obj) or path_mentions_image_or_request(path)

        if has_rub_currency:
            for key, value in obj.items():
                key_text = str(key).lower()
                number = parse_price(value)
                if number is None:
                    continue
                if is_excluded_price_key(key_text):
                    continue
                if has_image_unit or key_mentions_image_price(key_text):
                    candidates.append(PriceMatch(number, ".".join((*path, str(key)))))

        for key, value in obj.items():
            key_text = str(key).lower()
            number = parse_price(value)
            if (
                number is not None
                and key_mentions_image_price(key_text)
                and not is_excluded_price_key(key_text)
            ):
                candidates.append(PriceMatch(number, ".".join((*path, str(key)))))

            collect_price_candidates(value, (*path, str(key)), candidates)
        return

    if isinstance(obj, list):
        for index, value in enumerate(obj):
            collect_price_candidates(value, (*path, str(index)), candidates)


def dict_mentions_rub(data: dict[str, Any]) -> bool:
    for key, value in data.items():
        key_text = str(key).lower()
        if "currency" in key_text and value is not None:
            value_text = str(value).lower()
            if value_text in {"rub", "ruble", "rubles", "rur"} or "₽" in value_text or "руб" in value_text:
                return True
        if key_text.endswith("_rub") or key_text == "rub":
            return True
    return False


def dict_mentions_image_or_request(data: dict[str, Any]) -> bool:
    for key, value in data.items():
        key_text = str(key).lower()
        value_text = str(value).lower()
        if key_mentions_image_price(key_text):
            return True
        if key_text in {"unit", "type", "metric", "billing_unit", "billing_type"}:
            if mentions_image_or_request(value_text):
                return True
    return False


def path_mentions_image_or_request(path: tuple[str, ...]) -> bool:
    return mentions_image_or_request(" ".join(path).lower())


def key_mentions_image_price(key: str) -> bool:
    normalized = key.replace("-", "_")
    if any(token in normalized for token in ("per_image", "image_price", "price_per_image")):
        return True
    if any(token in normalized for token in ("per_request", "request_price", "price_per_request")):
        return True
    if normalized in {"image", "request", "amount", "price", "cost", "value"}:
        return True
    return ("rub" in normalized or "руб" in normalized) and mentions_image_or_request(normalized)


def mentions_image_or_request(text: str) -> bool:
    normalized = text.replace("-", "_")
    return any(token in normalized for token in ("image", "images", "picture", "per_request", "request"))


def is_excluded_price_key(key: str) -> bool:
    return any(
        token in key
        for token in (
            "token",
            "input",
            "output",
            "prompt",
            "completion",
            "second",
            "minute",
            "hour",
            "day",
            "month",
            "count",
            "limit",
        )
    )


def parse_price(value: Any) -> float | None:
    if isinstance(value, bool):
        return None
    if isinstance(value, (int, float)):
        number = float(value)
        if math.isfinite(number) and number >= 0:
            return number
        return None
    if not isinstance(value, str):
        return None

    cleaned = (
        value.strip()
        .replace("\u00a0", " ")
        .replace("₽", "")
        .replace("RUB", "")
        .replace("rub", "")
        .replace("руб.", "")
        .replace("руб", "")
        .replace(",", ".")
    )
    match = re.search(r"-?\d+(?:\.\d+)?", cleaned)
    if not match:
        return None
    number = float(match.group(0))
    if math.isfinite(number) and number >= 0:
        return number
    return None


def supported_parameters(obj: Any) -> str:
    if not isinstance(obj, dict):
        return ""

    pieces: list[str] = []
    for key, value in obj.items():
        key_text = str(key).lower()
        if key_text in {
            "supported_sizes",
            "sizes",
            "image_sizes",
            "resolutions",
            "supported_resolutions",
            "aspect_ratios",
            "supported_aspect_ratios",
            "parameters",
            "params",
            "options",
            "capabilities",
        }:
            text = format_value(value)
            if text:
                pieces.append(f"{key}: {text}")

    return "; ".join(pieces)


def format_value(value: Any) -> str:
    if value is None:
        return ""
    if isinstance(value, (str, int, float, bool)):
        return str(value)
    if isinstance(value, list):
        return ", ".join(format_value(item) for item in value if format_value(item))
    if isinstance(value, dict):
        parts = []
        for key, item in value.items():
            text = format_value(item)
            if text:
                parts.append(f"{key}={text}")
        return ", ".join(parts)
    return str(value)


def first_present(data: dict[str, Any], *keys: str) -> Any:
    for key in keys:
        value = data.get(key)
        if value not in (None, ""):
            return value
    return None


def stringify(value: Any, fallback: str) -> str:
    if value in (None, ""):
        return fallback
    return str(value)


def get_provider_name(provider: dict[str, Any]) -> str:
    return stringify(first_present(provider, "name", "provider", "provider_name", "id", "slug"), "unknown-provider")


def looks_like_model(data: dict[str, Any]) -> bool:
    return any(key in data for key in ("id", "model_id", "name", "title"))


def join_nonempty(*parts: str) -> str:
    return "; ".join(part for part in parts if part)


def print_report(
    buckets: PriceBuckets,
    image_count: int = DEFAULT_IMAGE_COUNT,
) -> None:
    print(f"Polza.ai image models for {image_count} images")
    print("Priority models checked first:")
    for model_id in PRIORITY_MODEL_IDS:
        print(f"- {model_id}")
    print()

    print_model_price_group(f"Up to 100 RUB for {image_count} images", buckets.under_100, image_count)
    print_model_price_group(f"From 100 to 300 RUB for {image_count} images", buckets.from_100_to_300, image_count)
    print_model_price_group(f"Over 300 RUB for {image_count} images", buckets.over_300, image_count)
    print_unknown_price_group("Unknown price", buckets.unknown, image_count)


def print_model_price_group(title: str, items: list[ModelPrice], image_count: int) -> None:
    print(title + ":")
    if not items:
        print("- none")
        print()
        return

    for item in items:
        print(f"- model id: {item.model_id}")
        print(f"  model name: {item.model_name}")
        print(f"  provider: {item.provider}")
        print(f"  price per image/request: {item.price_rub:.6g} RUB ({item.price_source})")
        print(f"  estimated cost for {image_count} images: {item.cost_for_images:.2f} RUB")
        print(f"  supported sizes/parameters: {item.supported_parameters}")
        print("  raw pricing fields:")
        print(indent_block(item.raw_pricing, "    "))
    print()


def print_unknown_price_group(title: str, items: list[UnknownPrice], image_count: int) -> None:
    print(title + ":")
    if not items:
        print("- none")
        print()
        return

    for item in items:
        print(f"- model id: {item.model_id}")
        print(f"  model name: {item.model_name}")
        print(f"  provider: {item.provider}")
        print("  price per image/request: not found")
        print(f"  estimated cost for {image_count} images: unknown")
        print(f"  supported sizes/parameters: {item.supported_parameters}")
        print("  raw pricing fields:")
        print(indent_block(item.raw_pricing, "    "))
    print()


def indent_block(text: str, prefix: str) -> str:
    return "\n".join(prefix + line for line in text.splitlines())


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Find the cheapest Polza.ai image generation models within a RUB budget."
    )
    parser.add_argument("--images", type=int, default=DEFAULT_IMAGE_COUNT, help="Number of images to estimate.")
    parser.add_argument("--budget", type=float, default=DEFAULT_BUDGET_RUB, help="Budget in RUB.")
    parser.add_argument("--timeout", type=int, default=30, help="HTTP timeout in seconds.")
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(sys.argv[1:] if argv is None else argv)
    if args.images <= 0:
        print("Error: --images must be greater than 0.", file=sys.stderr)
        return 2
    if args.budget < 0:
        print("Error: --budget must be 0 or greater.", file=sys.stderr)
        return 2

    api_key = os.environ.get("POLZA_API_KEY")
    if not api_key:
        print("Error: POLZA_API_KEY environment variable is not set.", file=sys.stderr)
        return 2

    try:
        payload = fetch_models(api_key, timeout=args.timeout)
        buckets = analyze_models(payload, image_count=args.images, budget_rub=args.budget)
        print_report(buckets, image_count=args.images)
        return 0
    except RuntimeError as exc:
        print(f"Error: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
