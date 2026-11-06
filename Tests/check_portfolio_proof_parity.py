"""Compare already-validated fictional proof outputs from the two PowerShell runtimes."""
import json
import re
import sys
from pathlib import Path


def main():
    if len(sys.argv) != 2:
        raise SystemExit('Usage: python Tests/check_portfolio_proof_parity.py <proof-root>')
    root = Path(sys.argv[1])
    environments = {}
    for runtime, version_prefix in (('WinPS51', '5.1.'), ('PS7', '7.')):
        record = json.loads((root / runtime / 'environment.json').read_text(encoding='utf-8-sig'))
        if (record.get('SchemaVersion') != 1 or
                not re.fullmatch('[0-9a-f]{40}', record.get('SourceCommit', '')) or
                not record.get('PowerShellVersion', '').startswith(version_prefix) or
                record.get('EvidenceKind') != 'SyntheticDeveloperProof' or
                record.get('LiveDeviceAcceptance') is not False or
                record.get('AttendedVisualOrAccessibilityAcceptance') is not False):
            raise SystemExit(f'{runtime}: missing or incompatible execution evidence')
        environments[runtime] = record
    if environments['WinPS51']['SourceCommit'] != environments['PS7']['SourceCommit']:
        raise SystemExit('The two runtimes did not record the same source commit')
    for component in ('DeviceCare', 'Imaging'):
        outputs = []
        for runtime in ('WinPS51', 'PS7'):
            path = root / runtime / component / 'summary.json'
            outputs.append(json.loads(path.read_text(encoding='utf-8-sig')))
        if outputs[0] != outputs[1]:
            raise SystemExit(f'{component}: normalized evidence differs between runtimes')
        print(f'{component}: independently checked JSON outputs match across PowerShell 5.1 and 7')
    print('Verified source: ' + environments['PS7']['SourceCommit'])


if __name__ == '__main__':
    main()
