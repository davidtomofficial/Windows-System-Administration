"""Offline, deterministic DTO DeviceCare source package with explicit membership."""
import argparse, hashlib, io, json, zipfile
from pathlib import Path
FILES = ('README.md','TODO.md','.gitignore','LICENSE.md','brand/product.json','docs/MIGRATION.md',
         'docs/VALIDATION.md','src/DeviceCare.psm1','src/Invoke-DTODeviceCare.ps1',
         'tests/Run-Checks.ps1','tests/test_package.py','tools/package.py',
         'src/Presentation.ps1','brand/report.html','brand/dto-header-monogram.svg','brand/ASSET-PROVENANCE.md',
         'docs/PROOF-PACKAGE.md','examples/Invoke-SyntheticProof.ps1',
         'examples/synthetic-snapshots.json','examples/expected-summary.json')
STAMP=(2026,11,5,0,0,0)

def digest(data):return hashlib.sha256(data).hexdigest()

def build(root):
    root=Path(root).resolve()
    src={}
    for path in FILES:
        f=root/path
        if not f.is_file() or f.is_symlink() or not f.resolve().is_relative_to(root):raise ValueError('Missing or unsafe file: '+path)
        src[path]=f.read_bytes()
    manifest={'schemaVersion':1,'product':'dto-devicecare','version':'0.2.0-dto-preview',
              'deploymentAccepted':False,
              'files':[{'path':n,'bytes':len(b),'sha256':digest(b)} for n,b in sorted(src.items())]}
    src['MANIFEST.json']=(json.dumps(manifest,indent=2)+'\n').encode()
    out=io.BytesIO()
    with zipfile.ZipFile(out,'w',zipfile.ZIP_DEFLATED,compresslevel=9) as z:
        for n,b in sorted(src.items()):
            info=zipfile.ZipInfo(n,STAMP)
            info.create_system=3
            info.compress_type=zipfile.ZIP_DEFLATED
            info.external_attr=0o100644<<16
            z.writestr(info,b)
    raw=out.getvalue();verify(raw);return raw

def verify(raw):
    if len(raw)>4*1024*1024:raise ValueError('Archive too large')
    with zipfile.ZipFile(io.BytesIO(raw)) as z:
        names=z.namelist()
        if len(names)!=len(set(names)) or set(names)!=set(FILES)|{'MANIFEST.json'}:raise ValueError('Unexpected inventory')
        if sum(x.file_size for x in z.infolist())>4*1024*1024:raise ValueError('Bad archive')
        if z.testzip() is not None:raise ValueError('Bad archive')
        m=json.loads(z.read('MANIFEST.json'))
        if m.get('schemaVersion')!=1 or m.get('product')!='dto-devicecare' or m.get('version')!='0.2.0-dto-preview' or m.get('deploymentAccepted') is not False:raise ValueError('Wrong product')
        records=m.get('files',[])
        if len(records)!=len(FILES) or {r['path'] for r in records}!=set(FILES):raise ValueError('Bad manifest')
        for r in records:
            b=z.read(r['path'])
            if len(b)!=r['bytes'] or digest(b)!=r['sha256']:raise ValueError('Content mismatch')
        return m

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--root',type=Path,default=Path(__file__).resolve().parents[1]);p.add_argument('--output',type=Path);p.add_argument('--verify',type=Path);a=p.parse_args()
    if a.verify:print(json.dumps({'verifiedFiles':len(verify(a.verify.read_bytes())['files'])}))
    elif a.output:
        b=build(a.root)
        with a.output.open('xb') as f:f.write(b)
        print(json.dumps({'bytes':len(b),'sha256':digest(b)}))
    else:p.error('Provide --output or --verify')
