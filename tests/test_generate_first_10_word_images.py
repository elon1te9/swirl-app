import base64
import importlib.util
import json
import os
import tempfile
import unittest
from pathlib import Path
from unittest.mock import Mock, patch


SCRIPT_PATH = Path(__file__).resolve().parents[1] / "generate_first_10_word_images.py"


def load_script():
    spec = importlib.util.spec_from_file_location("generate_first_10_word_images", SCRIPT_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class GenerateFirstTenWordImagesTests(unittest.TestCase):
    def test_default_paths_point_to_backend_wwwroot_words_directory(self):
        script = load_script()

        expected_words_dir = SCRIPT_PATH.parents[0] / "backend" / "Swirl.Api" / "wwwroot" / "media" / "images" / "words"

        self.assertEqual(script.WORDS_FILE, expected_words_dir / "words.json")
        self.assertEqual(script.OUTPUT_DIR, expected_words_dir)

    def test_load_words_reads_only_first_ten_english_values(self):
        script = load_script()

        with tempfile.TemporaryDirectory() as temp_dir:
            words_file = Path(temp_dir) / "words.json"
            words_file.write_text(
                json.dumps(
                    [{"english": f"word{i}", "russian": f"ru{i}"} for i in range(12)],
                    ensure_ascii=False,
                ),
                encoding="utf-8",
            )

            self.assertEqual(script.load_words(words_file), [f"word{i}" for i in range(10)])

    def test_generate_prompt_includes_word_and_image_rules(self):
        script = load_script()

        prompt = script.generate_prompt("apple")

        self.assertIn('"apple"', prompt)
        self.assertIn("no text", prompt)
        self.assertIn("consistent image set", prompt)

    def test_request_polza_image_uses_media_api_payload(self):
        script = load_script()

        response = Mock()
        response.json.return_value = {"data": [{"url": "https://example.com/apple.png"}]}
        response.raise_for_status.return_value = None

        with patch.object(script.requests, "post", return_value=response) as post:
            payload = script.request_polza_image("api-key", "prompt text")

        self.assertEqual(payload, {"data": [{"url": "https://example.com/apple.png"}]})
        _, kwargs = post.call_args
        self.assertEqual(kwargs["json"]["model"], script.MODEL_ID)
        self.assertEqual(kwargs["json"]["input"]["prompt"], "prompt text")
        self.assertEqual(kwargs["json"]["input"]["aspect_ratio"], "1:1")
        self.assertEqual(kwargs["json"]["input"]["max_images"], 1)

    def test_save_image_decodes_base64_payload_to_png_file(self):
        script = load_script()

        with tempfile.TemporaryDirectory() as temp_dir:
            output_path = Path(temp_dir) / "apple.png"
            encoded = base64.b64encode(b"png-bytes").decode("ascii")

            script.save_image(f"data:image/png;base64,{encoded}", output_path)

            self.assertEqual(output_path.read_bytes(), b"png-bytes")


if __name__ == "__main__":
    unittest.main()
