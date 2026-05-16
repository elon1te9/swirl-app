import io
import unittest
from contextlib import redirect_stdout

from check_polza_image_prices import analyze_models, print_report


class PolzaImagePriceTests(unittest.TestCase):
    def test_analyzes_affordable_models_and_unknown_prices(self):
        payload = {
            "data": [
                {
                    "id": "cheap-model",
                    "name": "Cheap Model",
                    "supported_sizes": ["1024x1024", "512x512"],
                    "providers": [
                        {
                            "name": "fast-provider",
                            "pricing": {
                                "currency": "RUB",
                                "per_request": 0.25,
                            },
                        }
                    ],
                },
                {
                    "id": "too-expensive",
                    "name": "Too Expensive",
                    "providers": [
                        {
                            "name": "premium-provider",
                            "price": {
                                "currency_code": "RUB",
                                "unit": "image",
                                "amount": "0.75",
                            },
                        }
                    ],
                },
                {
                    "id": "unknown-model",
                    "name": "Unknown Model",
                    "parameters": {"size": ["768x768"]},
                    "providers": [{"id": "mystery-provider"}],
                },
            ]
        }

        buckets = analyze_models(payload, image_count=200)

        self.assertEqual([item.model_id for item in buckets.under_100], ["cheap-model"])
        self.assertEqual(buckets.under_100[0].provider, "fast-provider")
        self.assertEqual(buckets.under_100[0].price_rub, 0.25)
        self.assertEqual(buckets.under_100[0].cost_for_images, 50.0)
        self.assertIn("1024x1024", buckets.under_100[0].supported_parameters)
        self.assertEqual([item.model_id for item in buckets.from_100_to_300], ["too-expensive"])
        self.assertEqual([item.model_id for item in buckets.unknown], ["unknown-model"])

    def test_print_report_keeps_unknown_prices_separate(self):
        payload = {
            "models": [
                {
                    "id": "known",
                    "name": "Known",
                    "providers": [{"name": "provider-a", "price_per_image_rub": "0.10"}],
                },
                {
                    "id": "unknown",
                    "name": "Unknown",
                    "providers": [{"name": "provider-b"}],
                },
            ]
        }

        buckets = analyze_models(payload, image_count=200)
        output = io.StringIO()
        with redirect_stdout(output):
            print_report(buckets, image_count=200)

        text = output.getvalue()
        self.assertIn("Up to 100 RUB", text)
        self.assertIn("known", text)
        self.assertIn("20.00 RUB", text)
        self.assertIn("raw pricing fields", text)
        self.assertIn("Unknown price", text)
        self.assertIn("unknown", text)

    def test_provider_without_price_does_not_reuse_another_provider_price(self):
        payload = {
            "data": [
                {
                    "id": "mixed",
                    "name": "Mixed Providers",
                    "providers": [
                        {"name": "priced-provider", "price_per_image_rub": 0.1},
                        {"name": "unknown-provider"},
                    ],
                }
            ]
        }

        buckets = analyze_models(payload, image_count=200)

        self.assertEqual([(item.model_id, item.provider) for item in buckets.under_100], [("mixed", "priced-provider")])
        self.assertEqual([(item.model_id, item.provider) for item in buckets.unknown], [("mixed", "unknown-provider")])

    def test_buckets_models_by_cost_and_keeps_raw_pricing_for_unknowns(self):
        payload = {
            "data": [
                {
                    "id": "google/gemini-3.1-flash-image-preview",
                    "name": "Gemini Preview",
                    "pricing": {"note": "model-level raw pricing"},
                    "providers": [
                        {
                            "name": "provider-c",
                            "pricing": {"currency": "RUB", "per_request": 2.0},
                        }
                    ],
                },
                {
                    "id": "black-forest-labs/flux.2-pro",
                    "name": "Flux Pro",
                    "providers": [{"name": "provider-b", "price_per_image_rub": 0.75}],
                },
                {
                    "id": "black-forest-labs/flux.2-flex",
                    "name": "Flux Flex",
                    "providers": [{"name": "provider-a", "price_per_image_rub": 0.25}],
                },
                {
                    "id": "qwen/image",
                    "name": "Qwen Image",
                    "providers": [{"name": "provider-z", "pricing": {"currency": "RUB", "per_request": "unknown"}}],
                },
            ]
        }

        buckets = analyze_models(payload, image_count=200)

        self.assertEqual([item.model_id for item in buckets.under_100], ["black-forest-labs/flux.2-flex"])
        self.assertEqual([item.model_id for item in buckets.from_100_to_300], ["black-forest-labs/flux.2-pro"])
        self.assertEqual([item.model_id for item in buckets.over_300], ["google/gemini-3.1-flash-image-preview"])
        self.assertEqual([item.model_id for item in buckets.unknown], ["qwen/image"])
        self.assertIn("per_request", buckets.unknown[0].raw_pricing)


if __name__ == "__main__":
    unittest.main()
