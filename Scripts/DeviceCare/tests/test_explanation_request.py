"""Offline contract checks using fictional evidence, without an API call."""

import hashlib
import importlib.util
import io
import json
from pathlib import Path
import tempfile
import unittest
from contextlib import redirect_stderr, redirect_stdout


ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("devicecare_request", ROOT / "ai/prepare_request.py")
REQUEST = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(REQUEST)


def evidence():
    return {
        "schema_version": 1,
        "product": "DeviceCare",
        "rules_version": "dto-0.2",
        "observed_at_utc": "2026-11-21T12:34:56.1234567Z",
        "maintenance_authorized": False,
        "findings": [
            {"id": "memory", "state": "Observed", "observed": 85,
             "units": "percent", "threshold": 85},
            {"id": "system-disk", "state": "Review", "observed": 15,
             "units": "GiB", "threshold": 15},
        ],
    }


def envelope(value=None, text=None):
    if text is None:
        text = json.dumps(evidence() if value is None else value, separators=(",", ":"))
    return {
        "SchemaVersion": 1,
        "InputJson": text,
        "InputSha256": hashlib.sha256(text.encode("utf-8")).hexdigest(),
    }


class ExplanationRequestTests(unittest.TestCase):
    def refuses(self, item):
        with self.assertRaises(REQUEST.InvalidExplanationRequest):
            REQUEST.prepare_request(item)

    def test_prepares_exact_evidence_with_strict_output_and_no_tools(self):
        item = envelope()
        prepared = REQUEST.prepare_request(item)
        self.assertEqual(prepared["model"], "gpt-6.2-sol")
        self.assertIs(prepared["store"], False)
        self.assertEqual(prepared["max_output_tokens"], 1500)
        self.assertEqual(prepared["input"][0]["content"][0]["text"], item["InputJson"])
        self.assertNotIn("tools", prepared)
        self.assertNotIn("api_key", prepared)
        fmt = prepared["text"]["format"]
        self.assertEqual(fmt["type"], "json_schema")
        self.assertIs(fmt["strict"], True)
        self.assertEqual(fmt["schema"]["required"], ["summary", "findings"])
        self.assertIs(fmt["schema"]["additionalProperties"], False)
        finding = fmt["schema"]["properties"]["findings"]
        self.assertEqual((finding["minItems"], finding["maxItems"]), (2, 2))
        self.assertIs(finding["items"]["additionalProperties"], False)

    def test_rounded_boundary_states_are_retained(self):
        prepared = REQUEST.prepare_request(envelope())
        data = json.loads(prepared["input"][0]["content"][0]["text"])
        self.assertEqual(data["findings"][0]["state"], "Observed")
        self.assertEqual(data["findings"][1]["state"], "Review")
        self.assertEqual(data["findings"][0]["observed"], data["findings"][0]["threshold"])
        self.assertEqual(data["findings"][1]["observed"], data["findings"][1]["threshold"])

    def test_unknown_and_missing_threshold_are_explicit(self):
        data = evidence()
        data["observed_at_utc"] = None
        for finding in data["findings"]:
            finding.update(state="Unknown", observed=None, threshold=None)
        self.assertEqual(REQUEST.validate_envelope(envelope(data)), data)
        data["findings"][0]["observed"] = 50
        self.refuses(envelope(data))

    def test_configured_thresholds_and_finding_order_are_preserved(self):
        data = evidence()
        data["findings"][0]["threshold"] = 72.5
        data["findings"][1]["threshold"] = 20.25
        data["findings"].reverse()
        self.assertEqual(REQUEST.validate_envelope(envelope(data)), data)

    def test_refuses_private_or_unknown_fields(self):
        for level in ("envelope", "input", "finding"):
            with self.subTest(level=level):
                data = evidence()
                if level == "input":
                    data["machine_name"] = "PRIVATE-CANARY"
                elif level == "finding":
                    data["findings"][0]["explanation"] = "PRIVATE-CANARY"
                item = envelope(data)
                if level == "envelope":
                    item["provider_error"] = "PRIVATE-CANARY"
                self.refuses(item)

    def test_refuses_missing_fields(self):
        for field in evidence():
            with self.subTest(field=field):
                data = evidence()
                del data[field]
                self.refuses(envelope(data))
        for field in evidence()["findings"][0]:
            with self.subTest(finding_field=field):
                data = evidence()
                del data["findings"][0][field]
                self.refuses(envelope(data))

    def test_refuses_unknown_duplicate_or_missing_findings(self):
        for replacement in ("memory", "other", [], None):
            with self.subTest(identity=replacement):
                data = evidence()
                data["findings"][1]["id"] = replacement
                self.refuses(envelope(data))
        data = evidence()
        data["findings"].pop()
        self.refuses(envelope(data))

    def test_refuses_state_or_unit_substitution(self):
        for name, value in (("state", "Healthy"), ("state", []), ("units", "MB")):
            with self.subTest(field=name, value=value):
                data = evidence()
                data["findings"][0][name] = value
                self.refuses(envelope(data))

    def test_refuses_type_coercion_and_out_of_range_numbers(self):
        mutations = (
            ("observed", True), ("observed", "85"), ("observed", None),
            ("observed", -1), ("observed", 101), ("observed", 10 ** 400),
            ("threshold", False), ("threshold", "85"),
            ("threshold", 0), ("threshold", 100),
        )
        for field, value in mutations:
            with self.subTest(field=field, value=repr(value)[:24]):
                data = evidence()
                data["findings"][0][field] = value
                self.refuses(envelope(data))
        for value in (-1, 0, 1025, True):
            data = evidence()
            data["findings"][1]["threshold"] = value
            self.refuses(envelope(data))

    def test_refuses_maintenance_or_schema_coercion(self):
        for value in (True, 0, "false", None):
            data = evidence()
            data["maintenance_authorized"] = value
            self.refuses(envelope(data))
        for value in (True, 1.0, "1", 2):
            data = evidence()
            data["schema_version"] = value
            self.refuses(envelope(data))
            item = envelope()
            item["SchemaVersion"] = value
            self.refuses(item)

    def test_refuses_product_and_rules_substitution(self):
        for field, value in (("product", "Other"), ("rules_version", "dto-0.3")):
            data = evidence()
            data[field] = value
            self.refuses(envelope(data))

    def test_refuses_invalid_time_and_accepts_null_or_utc(self):
        for value in ("2026-11", "2026-02-30T00:00:00Z", "2026-11-21T00:00:00+00:00", "2026-11-21T00:00:00", 0):
            with self.subTest(time=value):
                data = evidence()
                data["observed_at_utc"] = value
                self.refuses(envelope(data))
        for value in (None, "2026-11-21T00:00:00Z", "2026-11-21T00:00:00.1Z"):
            data = evidence()
            data["observed_at_utc"] = value
            REQUEST.prepare_request(envelope(data))

    def test_refuses_nonfinite_numbers(self):
        for token in ("NaN", "Infinity", "-Infinity", "1e9999"):
            text = envelope()["InputJson"].replace('"observed":85', '"observed":' + token)
            self.refuses(envelope(text=text))

    def test_refuses_duplicate_json_properties_at_both_boundaries(self):
        text = envelope()["InputJson"].replace('"product":"DeviceCare"', '"product":"DeviceCare","product":"Other"')
        self.refuses(envelope(text=text))
        raw = json.dumps(envelope())[:-1] + ',"SchemaVersion":1}'
        with self.assertRaises(REQUEST.InvalidExplanationRequest):
            REQUEST.parse_envelope(raw)

    def test_exact_bytes_are_bound_without_reserialization(self):
        text = json.dumps(evidence(), indent=2)
        item = envelope(text=text)
        prepared = REQUEST.prepare_request(item)
        self.assertEqual(prepared["input"][0]["content"][0]["text"], text)
        item["InputJson"] += " "
        self.refuses(item)
        item = envelope()
        item["InputSha256"] = item["InputSha256"].upper()
        self.refuses(item)

    def test_bounded_envelope_and_input(self):
        with self.assertRaises(REQUEST.InvalidExplanationRequest):
            REQUEST.parse_envelope(b" " * (REQUEST.MAX_ENVELOPE_BYTES + 1))
        self.refuses(envelope(text=" " * (REQUEST.MAX_INPUT_JSON_BYTES + 1)))
        with self.assertRaises(REQUEST.InvalidExplanationRequest):
            REQUEST.parse_envelope(b"\xff")
        with self.assertRaises(REQUEST.InvalidExplanationRequest):
            REQUEST.parse_envelope("[" * 1500 + "]" * 1500)

    def test_accepts_windows_utf8_bom(self):
        raw = b"\xef\xbb\xbf" + json.dumps(envelope()).encode("utf-8")
        self.assertEqual(REQUEST.parse_envelope(raw), envelope())

    def test_model_configuration_is_data_only(self):
        self.assertEqual(REQUEST.prepare_request(envelope(), model="gpt-6.2-astra")["model"], "gpt-6.2-astra")
        for model in ("", "x\nsecret", [], "x" * 81):
            with self.assertRaises(REQUEST.InvalidExplanationRequest):
                REQUEST.prepare_request(envelope(), model=model)

    def test_cli_emits_request_without_modifying_input(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / "fictional.json"
            original = json.dumps(envelope()).encode("utf-8")
            path.write_bytes(original)
            output, errors = io.StringIO(), io.StringIO()
            with redirect_stdout(output), redirect_stderr(errors):
                code = REQUEST.main([str(path)])
            self.assertEqual(code, 0)
            self.assertEqual(errors.getvalue(), "")
            self.assertEqual(json.loads(output.getvalue())["model"], "gpt-6.2-sol")
            self.assertEqual(path.read_bytes(), original)
            self.assertEqual([x.name for x in Path(folder).iterdir()], ["fictional.json"])

    def test_cli_failure_does_not_echo_private_input_or_path(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / "PRIVATE-CANARY.json"
            path.write_text('{"PRIVATE-CANARY":"private data"}', encoding="utf-8")
            output, errors = io.StringIO(), io.StringIO()
            with redirect_stdout(output), redirect_stderr(errors):
                code = REQUEST.main([str(path)])
            self.assertEqual(code, 2)
            self.assertEqual(output.getvalue(), "")
            self.assertNotIn("PRIVATE-CANARY", errors.getvalue())
            self.assertNotIn(folder, errors.getvalue())


if __name__ == "__main__":
    unittest.main(verbosity=2)
