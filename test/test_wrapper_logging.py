import importlib.util
import os
from pathlib import Path
from unittest import TestCase, main
from unittest.mock import patch


MODULE_PATH = Path(__file__).resolve().parents[1] / "backend" / "wrapper_api.py"


def load_wrapper():
    spec = importlib.util.spec_from_file_location("wrapper_api", MODULE_PATH)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


class CentralLoggingTests(TestCase):
    def test_sanitizes_sensitive_metadata(self):
        wrapper = load_wrapper()

        sanitized = wrapper._sanitize_metadata(
            {
                "safe": "ok",
                "password": "secret",
                "nested": {"authorization": "bearer secret", "value": 7},
            }
        )

        self.assertEqual(sanitized["safe"], "ok")
        self.assertEqual(sanitized["password"], "[REDACTED]")
        self.assertEqual(sanitized["nested"]["authorization"], "[REDACTED]")
        self.assertEqual(sanitized["nested"]["value"], 7)

    def test_central_log_is_fail_open(self):
        os.environ["LOGGING_SERVICE_URL"] = "http://logging-microservice:3367"
        wrapper = load_wrapper()
        wrapper.LOGGING_SERVICE_URL = "http://logging-microservice:3367"

        with patch("urllib.request.urlopen", side_effect=OSError("network down")):
            wrapper._central_log("info", "synthetic smoke", duration_ms=1, correlation_id="corr-1")


if __name__ == "__main__":
    main()
