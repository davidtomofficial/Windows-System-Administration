"""Prepare an OpenAI Responses request from selected DeviceCare evidence.

This developer utility is offline: it reads one explicit input file and writes
the prepared request to stdout. It does not read an API key, contact a service,
collect device information, or execute recommendations. The SHA-256 binds the
exact input bytes; it does not authenticate an assessment or its author.
"""

import argparse
from datetime import datetime
import hashlib
import hmac
import json
import math
from pathlib import Path
import re
import sys


ROOT = Path(__file__).resolve().parent
MAX_ENVELOPE_BYTES = 65536
MAX_INPUT_JSON_BYTES = 16384
DEFAULT_MODEL = "gpt-6.2-sol"
UTC_TIMESTAMP = re.compile(
    r"[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}"
    r"(?:\.[0-9]{1,7})?Z"
)
ENVELOPE_FIELDS = {"SchemaVersion", "InputJson", "InputSha256"}
INPUT_FIELDS = {
    "schema_version", "product", "rules_version", "observed_at_utc",
    "maintenance_authorized", "findings",
}
FINDING_FIELDS = {"id", "state", "observed", "units", "threshold"}
STATES = {"Observed", "Review", "Unknown"}


class InvalidExplanationRequest(ValueError):
    """A bounded, selected-evidence request did not satisfy the contract."""


def _fail(reason):
    # Fixed reasons never interpolate potentially private input values.
    raise InvalidExplanationRequest(reason)


def _unique_object(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            _fail("Duplicate JSON property.")
        result[key] = value
    return result


def _constant(_value):
    _fail("Non-finite JSON number.")


def _load_json(text):
    try:
        return json.loads(
            text, object_pairs_hook=_unique_object, parse_constant=_constant
        )
    except InvalidExplanationRequest:
        raise
    except (ValueError, TypeError, RecursionError):
        _fail("Invalid JSON document.")


def _exact_fields(value, expected):
    if not isinstance(value, dict) or set(value) != expected:
        _fail("Unexpected or missing properties.")


def _number(value, minimum, maximum=None, nullable=False):
    if value is None and nullable:
        return
    # bool subclasses int in Python, so it must be excluded explicitly.
    if type(value) not in (int, float):
        _fail("Invalid numeric evidence.")
    try:
        valid = math.isfinite(value) and value >= minimum
        if maximum is not None:
            valid = valid and value <= maximum
    except (OverflowError, ValueError):
        valid = False
    if not valid:
        _fail("Numeric evidence outside the supported range.")


def _timestamp(value):
    if value is None:
        return
    if not isinstance(value, str) or UTC_TIMESTAMP.fullmatch(value) is None:
        _fail("Invalid UTC observation time.")
    try:
        datetime.fromisoformat(value[:-1] + "+00:00")
    except ValueError:
        _fail("Invalid UTC observation time.")


def validate_input(value):
    """Validate selected evidence without recalculating rounded thresholds."""
    _exact_fields(value, INPUT_FIELDS)
    if type(value["schema_version"]) is not int or value["schema_version"] != 1:
        _fail("Unsupported input schema.")
    if value["product"] != "DeviceCare" or value["rules_version"] != "dto-0.2":
        _fail("Unsupported product or finding rules.")
    if value["maintenance_authorized"] is not False:
        _fail("An explanation cannot authorize maintenance.")
    _timestamp(value["observed_at_utc"])
    findings = value["findings"]
    if not isinstance(findings, list) or len(findings) != 2:
        _fail("Exactly two known findings are required.")
    seen = set()
    for finding in findings:
        _exact_fields(finding, FINDING_FIELDS)
        identity = finding["id"]
        state = finding["state"]
        if not isinstance(identity, str) or identity not in {"memory", "system-disk"}:
            _fail("Unknown finding identity.")
        if identity in seen:
            _fail("Duplicate finding identity.")
        seen.add(identity)
        if not isinstance(state, str) or state not in STATES:
            _fail("Unknown finding state.")
        if identity == "memory":
            if finding["units"] != "percent":
                _fail("Incorrect finding units.")
            _number(finding["threshold"], 1, 99, nullable=True)
            if state != "Unknown":
                _number(finding["observed"], 0, 100)
        else:
            if finding["units"] != "GiB":
                _fail("Incorrect finding units.")
            _number(finding["threshold"], 1, 1024, nullable=True)
            if state != "Unknown":
                _number(finding["observed"], 0)
        if state == "Unknown" and finding["observed"] is not None:
            _fail("Unknown findings must omit their measurement.")
    return value


def validate_envelope(envelope):
    """Return validated evidence, retaining the original InputJson verbatim."""
    _exact_fields(envelope, ENVELOPE_FIELDS)
    if type(envelope["SchemaVersion"]) is not int or envelope["SchemaVersion"] != 1:
        _fail("Unsupported envelope schema.")
    input_json = envelope["InputJson"]
    digest = envelope["InputSha256"]
    if not isinstance(input_json, str):
        _fail("InputJson must be a string.")
    try:
        encoded = input_json.encode("utf-8")
    except UnicodeError:
        _fail("InputJson must contain valid UTF-8 text.")
    if not encoded or len(encoded) > MAX_INPUT_JSON_BYTES:
        _fail("Selected evidence exceeds the input limit.")
    if not isinstance(digest, str) or re.fullmatch(r"[0-9a-f]{64}", digest) is None:
        _fail("Invalid input fingerprint.")
    if not hmac.compare_digest(hashlib.sha256(encoded).hexdigest(), digest):
        _fail("Input fingerprint does not match the selected evidence.")
    return validate_input(_load_json(input_json))


def parse_envelope(raw):
    """Read bounded UTF-8 JSON, including an optional outer UTF-8 BOM."""
    try:
        encoded = raw.encode("utf-8") if isinstance(raw, str) else raw
        if not isinstance(encoded, bytes):
            _fail("The envelope must be UTF-8 JSON.")
        if not encoded or len(encoded) > MAX_ENVELOPE_BYTES:
            _fail("The request envelope exceeds the input limit.")
        # Windows PowerShell 5.1 may emit a BOM when exporting UTF-8 JSON.
        value = _load_json(encoded.decode("utf-8-sig"))
    except UnicodeError:
        _fail("The envelope must be UTF-8 JSON.")
    validate_envelope(value)
    return value


def prepare_request(envelope, model=DEFAULT_MODEL):
    """Build request data only. The caller owns any eventual API transport."""
    validate_envelope(envelope)
    if not isinstance(model, str) or re.fullmatch(r"[a-z0-9][a-z0-9._:-]{0,79}", model) is None:
        _fail("Invalid model identifier.")
    instructions = (ROOT / "instructions.txt").read_text(encoding="utf-8")
    schema = _load_json((ROOT / "explanation.schema.json").read_text(encoding="utf-8"))
    return {
        "model": model,
        "store": False,
        "max_output_tokens": 1500,
        "instructions": instructions,
        "input": [
            {"role": "user", "content": [
                {"type": "input_text", "text": envelope["InputJson"]}
            ]}
        ],
        "text": {"format": {
            "type": "json_schema",
            "name": "devicecare_explanation",
            "strict": True,
            "schema": schema,
        }},
    }


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("request_file", type=Path, help="Explicit selected-evidence envelope JSON file")
    parser.add_argument("--model", default=DEFAULT_MODEL, help="Model identifier for the prepared request")
    args = parser.parse_args(argv)
    try:
        with args.request_file.open("rb") as source:
            raw = source.read(MAX_ENVELOPE_BYTES + 1)
        request = prepare_request(parse_envelope(raw), args.model)
    except (OSError, InvalidExplanationRequest):
        # Do not print file paths, raw inputs, or detailed service information.
        print("DeviceCare request preparation failed: input or contract could not be validated.", file=sys.stderr)
        return 2
    print(json.dumps(request, ensure_ascii=True, allow_nan=False, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
