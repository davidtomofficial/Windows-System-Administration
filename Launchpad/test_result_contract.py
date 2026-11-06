"""Synthetic contract checks. No component commands or device operations run."""

import copy
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest


HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location("result_contract", HERE / "result_contract.py")
contract = importlib.util.module_from_spec(spec)
spec.loader.exec_module(contract)
FIXTURES = json.loads((HERE.parent / "Contracts/fixtures/task-result-cases.json").read_text(encoding="utf-8"))
CASES = {case["id"]: case for case in FIXTURES["cases"]}


class ResultContractTests(unittest.TestCase):
    def setUp(self):
        self.data = copy.deepcopy(CASES["observation-complete-retains-original-time"]["result"])

    def refused(self, change):
        change(self.data)
        with self.assertRaises(ValueError):
            contract.validate(self.data)

    def test_shared_positive_and_refusal_fixtures(self):
        self.assertEqual(FIXTURES["fixtureSchemaVersion"], 1)
        self.assertEqual(len(CASES), len(FIXTURES["cases"]), "fixture ids must be unique")
        for case in CASES.values():
            with self.subTest(case=case["id"]):
                raw = json.dumps(case["result"], allow_nan=False).encode("utf-8")
                if case["valid"]:
                    self.assertEqual(contract.loads(raw), case["result"])
                else:
                    with self.assertRaises(ValueError):
                        contract.loads(raw)

    def test_validation_preserves_identity_nulls_timestamps_and_phase_states(self):
        for case in CASES.values():
            if case["valid"]:
                with self.subTest(case=case["id"]):
                    value = copy.deepcopy(case["result"])
                    before = copy.deepcopy(value)
                    self.assertIs(contract.validate(value), value)
                    self.assertEqual(value, before)

    def test_valid_fixtures_express_every_distinct_status(self):
        statuses = {case["result"][phase]["status"] for case in CASES.values()
                    if case["valid"] for phase in contract.PHASES}
        self.assertEqual(statuses, contract.STATUSES)
        failed = CASES["successful-action-failed-verification"]["result"]
        self.assertEqual(failed["action"]["status"], "Succeeded")
        self.assertEqual(failed["verification"]["status"], "Failed")
        self.assertIs(CASES["failed-action-still-requires-restart"]["result"]["restartRequired"], True)
        self.assertEqual(CASES["cancellation-preserves-unknown-effects"]["result"]["effects"], "Unknown")

    def test_duplicate_json_keys_at_each_object_boundary(self):
        raw = json.dumps(self.data)
        duplicates = (
            ('"schemaVersion": 1', '"schemaVersion": 1, "schemaVersion": 1'),
            ('"component": "Synthetic.DeviceCare"', '"component": "Synthetic.DeviceCare", "component": "Synthetic.DeviceCare"'),
            ('"status": "Succeeded"', '"status": "Succeeded", "status": "Succeeded"'),
            ('"id": "snapshot"', '"id": "snapshot", "id": "snapshot"'),
        )
        for original, replacement in duplicates:
            with self.subTest(field=original):
                with self.assertRaisesRegex(ValueError, "Duplicate JSON key"):
                    contract.loads(raw.replace(original, replacement, 1).encode("utf-8"))

    def test_nonfinite_constants_and_numeric_overflow_are_refused(self):
        raw = json.dumps(self.data)
        for number in ("NaN", "Infinity", "-Infinity", "1e10000"):
            with self.subTest(number=number):
                with self.assertRaises(ValueError):
                    contract.loads(raw.replace('"schemaVersion": 1', '"schemaVersion": ' + number, 1).encode("utf-8"))

    def test_reader_refuses_invalid_utf8_bom_trailing_json_and_nesting(self):
        raw = json.dumps(self.data).encode("utf-8")
        for invalid in (b"\xff", b"\xef\xbb\xbf" + raw, raw + b"{}", b"[" * 2000 + b"]" * 2000):
            with self.subTest(length=len(invalid)):
                with self.assertRaises(ValueError):
                    contract.loads(invalid)
        with self.assertRaises(ValueError):
            contract.loads(raw.decode("utf-8"))

    def test_file_reader_enforces_exact_byte_boundary(self):
        raw = json.dumps(self.data).encode("utf-8")
        padded = raw + b" " * (contract.MAX_BYTES - len(raw))
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "result.json"
            path.write_bytes(padded)
            self.assertEqual(contract.load(path), self.data)
            path.write_bytes(padded + b" ")
            with self.assertRaisesRegex(ValueError, "1 MiB"):
                contract.load(path)

    def test_evidence_and_reference_count_boundaries(self):
        item = self.data["evidence"][0]
        self.data["evidence"] = [dict(item, id=f"e{index}") for index in range(128)]
        self.data["observation"]["evidenceIds"] = [entry["id"] for entry in self.data["evidence"]]
        contract.validate(self.data)
        too_many = copy.deepcopy(self.data)
        too_many["evidence"].append(dict(item, id="e128"))
        with self.assertRaises(ValueError):
            contract.validate(too_many)
        self.data["observation"]["evidenceIds"].append("e0")
        with self.assertRaises(ValueError):
            contract.validate(self.data)

    def test_generic_text_counts_scalars_and_refuses_surrogates_and_controls(self):
        # A valid supplementary scalar counts as one character, not two UTF-16 units.
        self.data["source"]["component"] = "\U0001f9ea" * 128
        contract.validate(self.data)
        self.data["source"]["component"] += "x"
        with self.assertRaises(ValueError):
            contract.validate(self.data)
        for value in ("\ud800", "\udfff", "\x00", "\x1f", "\x7f", " \t "):
            with self.subTest(value=repr(value)):
                self.data["source"]["component"] = value
                with self.assertRaises(ValueError):
                    contract.loads(json.dumps(self.data).encode("utf-8"))

    def test_timestamp_grammar_calendar_and_full_precision(self):
        for timestamp in (
                "0000-01-01T00:00:00Z", "2025-02-29T00:00:00Z", "2026-01-02T24:00:00Z",
                "2026-01-02T03:60:00Z", "2026-01-02T03:04:60Z", "2026-01-02T03:04:05.12345678Z",
                "2026-01-02T03:04:05+01:00", "2026-01-02T03:04:05-00:00", "2026-01-02t03:04:05z"):
            with self.subTest(timestamp=timestamp):
                self.data["evidence"][0]["collectedAtUtc"] = timestamp
                with self.assertRaises(ValueError):
                    contract.validate(self.data)
        self.data["evidence"][0]["collectedAtUtc"] = "2024-02-29T00:00:00+00:00"
        self.data["completedAtUtc"] = self.data["startedAtUtc"]
        contract.validate(self.data)
        self.data["completedAtUtc"] = "2026-01-02T03:04:05.1234568Z"
        contract.validate(self.data)
        self.data["completedAtUtc"] = "2026-01-02T03:04:05.1234566Z"
        with self.assertRaises(ValueError):
            contract.validate(self.data)

    def test_missing_fields_and_object_array_types_are_refused(self):
        for key in list(self.data):
            value = copy.deepcopy(self.data)
            del value[key]
            with self.subTest(missing=key):
                with self.assertRaises(ValueError):
                    contract.validate(value)
        for field, wrong in (("source", []), ("action", []), ("evidence", {}), ("evidence", ())):
            value = copy.deepcopy(self.data)
            value[field] = wrong
            with self.subTest(field=field, type=type(wrong).__name__):
                with self.assertRaises(ValueError):
                    contract.validate(value)

    def test_evidence_integer_boundaries(self):
        for accepted in (1, 2_147_483_647):
            self.data["evidence"][0]["schemaVersion"] = accepted
            contract.validate(self.data)
        for refused in (0, -1, 2_147_483_648, True, 1.0, "1", None):
            self.data["evidence"][0]["schemaVersion"] = refused
            with self.subTest(version=repr(refused)):
                with self.assertRaises(ValueError):
                    contract.validate(self.data)


if __name__ == "__main__":
    unittest.main(verbosity=2)
