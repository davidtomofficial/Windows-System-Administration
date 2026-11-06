"""Validate a DTO v1 task result. This module never executes an operation.

The three phase statuses are independent claims. Validation establishes contract
conformance, not authenticity, permission to change a device, or device health.
Original evidence timestamps and references are returned without normalization.
"""

import argparse
from datetime import date
import json
from pathlib import Path
import re


MAX_BYTES = 1024 * 1024
MAX_EVIDENCE = 128
STATUSES = frozenset({
    "Succeeded", "Failed", "Partial", "Skipped", "Unknown", "Cancelled",
    "RestartRequired",
})
PHASES = ("observation", "action", "verification")
ROOT_FIELDS = frozenset({
    "schemaVersion", "operationId", "runId", "operationKind", "source",
    "startedAtUtc", "completedAtUtc", "changesAttempted", "effects",
    "restartRequired", "observation", "action", "verification", "evidence",
})
TOKEN = re.compile(r"[A-Za-z][A-Za-z0-9._-]*\Z")
RUN_ID = re.compile(r"[0-9a-f]{8}-(?:[0-9a-f]{4}-){3}[0-9a-f]{12}\Z")
REVISION = re.compile(r"[0-9a-f]{40}\Z")
SHA256 = re.compile(r"[0-9a-f]{64}\Z")
UTC_TIME = re.compile(
    r"([0-9]{4})-([0-9]{2})-([0-9]{2})T([0-9]{2}):([0-9]{2}):([0-9]{2})"
    r"(?:\.([0-9]{1,7}))?(?:Z|\+00:00)\Z"
)


def _object(value, fields, location):
    if type(value) is not dict or set(value) != set(fields):
        raise ValueError(f"{location}: unexpected or missing fields")


def _text(value, maximum, location):
    if (type(value) is not str or not 1 <= len(value) <= maximum
            or not value.strip() or any(
                ord(char) < 32 or ord(char) == 127 or 0xD800 <= ord(char) <= 0xDFFF
                for char in value)):
        raise ValueError(f"{location}: invalid text")


def _token(value, maximum, location):
    if type(value) is not str or not 1 <= len(value) <= maximum or not TOKEN.fullmatch(value):
        raise ValueError(f"{location}: invalid identifier")


def _choice(value, choices, location):
    if type(value) is not str or value not in choices:
        raise ValueError(f"{location}: unsupported value")


def _timestamp(value, location):
    """Return 100 ns calendar ticks for comparison; never change the input."""
    if value is None:
        return None
    match = UTC_TIME.fullmatch(value) if type(value) is str else None
    if match is None:
        raise ValueError(f"{location}: expected UTC timestamp or null")
    year, month, day, hour, minute, second = map(int, match.groups()[:6])
    try:
        ordinal = date(year, month, day).toordinal()
    except ValueError as exc:
        raise ValueError(f"{location}: invalid calendar date") from exc
    if hour > 23 or minute > 59 or second > 59:
        raise ValueError(f"{location}: invalid time of day")
    fraction = int((match.group(7) or "").ljust(7, "0"))
    return ((ordinal * 86400 + hour * 3600 + minute * 60 + second) * 10_000_000
            + fraction)


def validate(data):
    """Refuse malformed/contradictory v1 records; return the unchanged object."""
    _object(data, ROOT_FIELDS, "result")
    if type(data["schemaVersion"]) is not int or data["schemaVersion"] != 1:
        raise ValueError("schemaVersion: only integer 1 is supported")
    _token(data["operationId"], 128, "operationId")
    if type(data["runId"]) is not str or not RUN_ID.fullmatch(data["runId"]):
        raise ValueError("runId: expected lowercase UUID")
    _choice(data["operationKind"], {"Observation", "Plan", "Change"}, "operationKind")
    source = data["source"]
    _object(source, {"component", "version", "revision"}, "source")
    _text(source["component"], 128, "source.component")
    _text(source["version"], 64, "source.version")
    if type(source["revision"]) is not str or not REVISION.fullmatch(source["revision"]):
        raise ValueError("source.revision: expected full lowercase Git SHA-1")
    started = _timestamp(data["startedAtUtc"], "startedAtUtc")
    completed = _timestamp(data["completedAtUtc"], "completedAtUtc")
    if started is not None and completed is not None and completed < started:
        raise ValueError("completedAtUtc: precedes startedAtUtc")
    if type(data["changesAttempted"]) is not bool:
        raise ValueError("changesAttempted: expected boolean")
    _choice(data["effects"], {"None", "Observed", "Unknown"}, "effects")
    if data["restartRequired"] is not None and type(data["restartRequired"]) is not bool:
        raise ValueError("restartRequired: expected boolean or null")

    evidence = data["evidence"]
    if type(evidence) is not list or len(evidence) > MAX_EVIDENCE:
        raise ValueError("evidence: expected at most 128 descriptors")
    by_id = {}
    for index, item in enumerate(evidence):
        location = f"evidence[{index}]"
        _object(item, {"id", "type", "schemaVersion", "collectedAtUtc", "coverage", "sha256"}, location)
        _token(item["id"], 64, location + ".id")
        if item["id"] in by_id:
            raise ValueError("evidence: duplicate id")
        by_id[item["id"]] = item
        _text(item["type"], 128, location + ".type")
        if type(item["schemaVersion"]) is not int or not 1 <= item["schemaVersion"] <= 2_147_483_647:
            raise ValueError(location + ".schemaVersion: expected positive 32-bit integer")
        _timestamp(item["collectedAtUtc"], location + ".collectedAtUtc")
        _choice(item["coverage"], {"Complete", "Partial", "Unknown"}, location + ".coverage")
        digest = item["sha256"]
        if digest is not None and (type(digest) is not str or not SHA256.fullmatch(digest)):
            raise ValueError(location + ".sha256: expected lowercase SHA-256 or null")

    for phase_name in PHASES:
        phase = data[phase_name]
        _object(phase, {"status", "reasonCode", "evidenceIds"}, phase_name)
        _choice(phase["status"], STATUSES, phase_name + ".status")
        _token(phase["reasonCode"], 64, phase_name + ".reasonCode")
        refs = phase["evidenceIds"]
        if type(refs) is not list or len(refs) > MAX_EVIDENCE:
            raise ValueError(phase_name + ".evidenceIds: expected at most 128 references")
        seen = set()
        for ref in refs:
            _token(ref, 64, phase_name + ".evidenceIds")
            if ref in seen or ref not in by_id:
                raise ValueError(phase_name + ".evidenceIds: duplicate or unresolved reference")
            seen.add(ref)
        if phase_name != "action" and phase["status"] == "RestartRequired":
            raise ValueError(phase_name + ": RestartRequired is an action status only")
        if phase_name != "action" and phase["status"] == "Succeeded":
            if not refs or any(by_id[ref]["coverage"] != "Complete" for ref in refs):
                raise ValueError(phase_name + ": Succeeded requires complete referenced evidence")

    action = data["action"]["status"]
    if data["operationKind"] != "Change" and (
            data["changesAttempted"] or action != "Skipped"
            or data["effects"] != "None" or data["restartRequired"] is True):
        raise ValueError("operationKind: Observation/Plan cannot claim a change action")
    if not data["changesAttempted"] and (
            data["effects"] != "None" or data["restartRequired"] is True
            or action in {"Succeeded", "Partial", "RestartRequired"}):
        raise ValueError("changesAttempted: false conflicts with action/effects/restart")
    if data["changesAttempted"] and action == "Skipped":
        raise ValueError("action: an attempted change cannot be Skipped")
    if action == "RestartRequired" and (
            data["restartRequired"] is not True
            or data["verification"]["status"] not in {"Skipped", "Unknown"}):
        raise ValueError("action: RestartRequired needs a required restart and pending verification")
    return data


def _unique(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError("Duplicate JSON key")
        result[key] = value
    return result


def _nonfinite(_value):
    raise ValueError("Non-finite JSON number")


def loads(raw):
    """Read bounded UTF-8 bytes. No BOM, duplicate keys, or nonfinite constants."""
    if type(raw) is not bytes:
        raise ValueError("Expected UTF-8 bytes")
    if len(raw) > MAX_BYTES:
        raise ValueError("Task result exceeds 1 MiB")
    try:
        data = json.loads(raw.decode("utf-8"), object_pairs_hook=_unique,
                          parse_constant=_nonfinite)
    except (UnicodeError, RecursionError) as exc:
        raise ValueError("Invalid UTF-8 or excessive JSON nesting") from exc
    return validate(data)


def load(path):
    with Path(path).open("rb") as stream:
        return loads(stream.read(MAX_BYTES + 1))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("result", type=Path)
    args = parser.parse_args()
    try:
        result = load(args.result)
    except (ValueError, OSError) as exc:
        parser.exit(2, f"Task result refused: {exc}\n")
    print("VALIDATED_TASK_RESULT_SCHEMA=1; DEVICE_HEALTH_OR_CHANGE_AUTHORITY_NOT_ASSERTED")
