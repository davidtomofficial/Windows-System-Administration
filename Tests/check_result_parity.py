"""Check actual PowerShell-produced fixture JSON against the Python consumer."""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "Launchpad"))
import result_contract


def main(path):
    fixtures = json.loads((ROOT / "Contracts/fixtures/task-result-cases.json").read_text(encoding="utf-8"))
    expected = [case for case in fixtures["cases"] if case["valid"]]
    raw = Path(path).read_bytes()
    if len(raw) > 8 * 1048576:
        raise ValueError("Parity input too large")
    lines = raw.splitlines()
    if len(lines) != len(expected):
        raise ValueError("Missing or additional PowerShell results")
    for row, original in zip(lines, expected):
        result = result_contract.loads(row)
        if result != original["result"]:
            raise ValueError("PowerShell changed fixture values: " + original["id"])
    print("RESULT_CONTRACT_CROSS_LANGUAGE_MATCHES=" + str(len(expected)))


if __name__ == "__main__":
    main(sys.argv[1])
