import importlib.util
import os
import sys
import tempfile
import types
import unittest


SCRIPT_PATH = os.path.join(
    os.path.dirname(os.path.dirname(__file__)),
    "backend",
    "Swirl.Api",
    "download_word_images.py",
)


def load_script():
    duckduckgo_module = types.ModuleType("duckduckgo_search")
    duckduckgo_module.DDGS = object
    sys.modules["duckduckgo_search"] = duckduckgo_module

    pil_module = types.ModuleType("PIL")
    image_module = types.ModuleType("PIL.Image")
    image_module.open = lambda path: None
    pil_module.Image = image_module
    sys.modules["PIL"] = pil_module
    sys.modules["PIL.Image"] = image_module

    spec = importlib.util.spec_from_file_location("download_word_images", SCRIPT_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class DownloadWordImagesTests(unittest.TestCase):
    def test_load_words_reads_english_entries_only(self):
        script = load_script()

        with tempfile.TemporaryDirectory() as temp_dir:
            words_file = os.path.join(temp_dir, "words.json")
            with open(words_file, "w", encoding="utf-8") as handle:
                handle.write(
                    '[{"english": "apple", "russian": "apple-ru"}, '
                    '{"russian": "missing-english"}, '
                    '{"english": "  bread  ", "russian": "bread-ru"}]'
                )

            self.assertEqual(script.load_words(words_file), ["apple", "bread"])

    def test_resolve_words_file_uses_script_directory_when_called_from_other_cwd(self):
        script = load_script()

        old_cwd = os.getcwd()
        with tempfile.TemporaryDirectory() as temp_dir:
            os.chdir(temp_dir)
            try:
                expected_path = os.path.join(
                    os.path.dirname(SCRIPT_PATH),
                    "wwwroot",
                    "media",
                    "images",
                    "words",
                    "words.json",
                )

                self.assertEqual(script.resolve_words_file(), expected_path)
            finally:
                os.chdir(old_cwd)

    def test_save_png_converts_downloaded_image_to_png(self):
        script = load_script()

        with tempfile.TemporaryDirectory() as temp_dir:
            output_file = os.path.join(temp_dir, "apple.png")
            saved = {}

            class FakeImage:
                mode = "RGB"

                def __enter__(self):
                    return self

                def __exit__(self, exc_type, exc, traceback):
                    return False

                def convert(self, mode):
                    saved["converted_to"] = mode
                    return self

                def save(self, path, format):
                    saved["path"] = path
                    saved["format"] = format

            script.Image.open = lambda path: FakeImage()
            script.save_png(b"fake-image-bytes", output_file)

            self.assertEqual(saved["converted_to"], "RGBA")
            self.assertEqual(saved["path"], output_file)
            self.assertEqual(saved["format"], "PNG")
            self.assertFalse(os.path.exists(output_file + ".download"))

    def test_save_png_rejects_too_small_images(self):
        script = load_script()

        with tempfile.TemporaryDirectory() as temp_dir:
            output_file = os.path.join(temp_dir, "apple.png")

            class SmallImage:
                mode = "RGB"
                size = (128, 128)

                def __enter__(self):
                    return self

                def __exit__(self, exc_type, exc, traceback):
                    return False

                def convert(self, mode):
                    return self

                def save(self, path, format):
                    with open(path, "wb") as handle:
                        handle.write(b"saved")

            script.Image.open = lambda path: SmallImage()

            with self.assertRaises(ValueError):
                script.save_png(b"fake-image-bytes", output_file)

            self.assertFalse(os.path.exists(output_file))
            self.assertFalse(os.path.exists(output_file + ".download"))


if __name__ == "__main__":
    unittest.main()
