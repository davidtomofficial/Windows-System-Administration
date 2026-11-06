"""Build/verify the explicit DTO source allowlist. No network or installer payloads."""
import argparse
import hashlib
import io
import json
from pathlib import Path
import zipfile

FILES = (
    'README.md', 'TODO.md', '.gitignore', 'LICENSE.md', 'brand/product.json', 'docs/MIGRATION.md',
    'docs/VALIDATION.md', 'src/DTOImaging.psm1', 'src/Get-DTOWorkstationSnapshot.ps1',
    'src/Get-DTOImageReview.ps1', 'src/DTOSnapshotComparison.psm1',
    'tests/Run-Checks.ps1', 'tests/Run-ComparisonChecks.ps1', 'tests/test_package.py',
    'tools/package.py',
)
STAMP = (2026, 11, 5, 0, 0, 0)

def sha(data):
    return hashlib.sha256(data).hexdigest()

def build(root):
    root = Path(root).resolve()
    payloads = {}
    for name in FILES:
        path = root / name
        if path.is_symlink() or not path.is_file() or not path.resolve().is_relative_to(root):
            raise ValueError('Missing or linked source: ' + name)
        payloads[name] = path.read_bytes()
    manifest = {'schemaVersion': 1, 'product': 'dto-imaging-provisioning',
                'version': '0.2.0', 'deploymentAccepted': False,
                'files': [{'path': n, 'bytes': len(b), 'sha256': sha(b)}
                          for n, b in sorted(payloads.items())]}
    payloads['MANIFEST.json'] = (json.dumps(manifest, indent=2) + '\n').encode()
    output = io.BytesIO()
    with zipfile.ZipFile(output, 'w', zipfile.ZIP_DEFLATED, compresslevel=9) as z:
        for name, data in sorted(payloads.items()):
            info = zipfile.ZipInfo(name, STAMP)
            info.create_system = 3
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o100644 << 16
            z.writestr(info, data)
    result = output.getvalue()
    verify(result)
    return result

def verify(data):
    if len(data) > 5 * 1024 * 1024:
        raise ValueError('Archive too large')
    with zipfile.ZipFile(io.BytesIO(data)) as z:
        names = z.namelist()
        if len(names) != len(set(names)) or set(names) != set(FILES) | {'MANIFEST.json'}:
            raise ValueError('Unexpected or duplicate archive members')
        if sum(i.file_size for i in z.infolist()) > 5 * 1024 * 1024:
            raise ValueError('Expanded archive too large')
        if z.testzip() is not None:
            raise ValueError('ZIP CRC failure')
        m = json.loads(z.read('MANIFEST.json'))
        if (m.get('schemaVersion') != 1 or m.get('version') != '0.2.0' or
                m.get('product') != 'dto-imaging-provisioning' or m.get('deploymentAccepted') is not False):
            raise ValueError('Invalid manifest identity')
        entries = m.get('files', [])
        if len(entries) != len(FILES) or {r['path'] for r in entries} != set(FILES):
            raise ValueError('Invalid manifest inventory')
        for r in entries:
            b = z.read(r['path'])
            if len(b) != r['bytes'] or sha(b) != r['sha256']:
                raise ValueError('Content mismatch: ' + r['path'])
        return m

if __name__ == '__main__':
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--root', type=Path, default=Path(__file__).resolve().parents[1])
    p.add_argument('--output', type=Path)
    p.add_argument('--verify', type=Path)
    a = p.parse_args()
    if a.verify:
        m = verify(a.verify.read_bytes())
        print(json.dumps({'verifiedFiles': len(m['files']), 'deploymentAccepted': False}))
    elif a.output:
        b = build(a.root)
        with a.output.open('xb') as f:
            f.write(b)
        print(json.dumps({'bytes': len(b), 'sha256': sha(b), 'deploymentAccepted': False}))
    else:
        p.error('Specify --output or --verify')
