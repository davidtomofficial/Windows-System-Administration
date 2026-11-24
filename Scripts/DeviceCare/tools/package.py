"""Offline, deterministic DTO DeviceCare source package with explicit membership."""
import argparse, hashlib, io, json, re, stat, zipfile
from pathlib import Path
FILES = ('README.md','TODO.md','.gitignore','LICENSE.md','brand/product.json','docs/MIGRATION.md',
         'docs/VALIDATION.md','src/DeviceCare.psm1','src/Invoke-DTODeviceCare.ps1',
         'tests/Run-Checks.ps1','tests/test_package.py','tools/package.py',
         'src/Presentation.ps1','brand/report.html','brand/dto-header-monogram.svg','brand/ASSET-PROVENANCE.md',
         'docs/PROOF-PACKAGE.md','examples/Invoke-SyntheticProof.ps1',
         'examples/synthetic-snapshots.json','examples/expected-summary.json',
         'src/DeviceCare.Explanations.psm1','src/Explanation.ps1','src/ExplanationPresentation.ps1',
         'docs/EXPLANATIONS.md','tests/Run-ExplanationChecks.ps1',
         'ai/prepare_request.py','ai/explanation.schema.json','ai/instructions.txt',
         'tests/test_explanation_request.py')
STAMP=(2026,11,5,0,0,0)
MAX_ARCHIVE_BYTES=4*1024*1024
MAX_MANIFEST_BYTES=65536
MANIFEST_FIELDS={'schemaVersion','product','version','deploymentAccepted','files'}
RECORD_FIELDS={'path','bytes','sha256'}

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

def _unique_object(pairs):
    value={}
    for key,item in pairs:
        if key in value:raise ValueError('Duplicate manifest property')
        value[key]=item
    return value

def _invalid_constant(_value):
    raise ValueError('Invalid manifest number')

def _parse_manifest(raw):
    if len(raw)>MAX_MANIFEST_BYTES:raise ValueError('Manifest too large')
    try:
        value=json.loads(raw.decode('utf-8'),object_pairs_hook=_unique_object,parse_constant=_invalid_constant)
    except (ValueError,UnicodeError,RecursionError):
        raise ValueError('Bad manifest JSON') from None
    if not isinstance(value,dict) or set(value)!=MANIFEST_FIELDS:raise ValueError('Bad manifest fields')
    if (type(value['schemaVersion']) is not int or value['schemaVersion']!=1 or
        value['product']!='dto-devicecare' or value['version']!='0.2.0-dto-preview' or
        value['deploymentAccepted'] is not False):raise ValueError('Wrong product')
    records=value['files']
    if not isinstance(records,list) or len(records)!=len(FILES):raise ValueError('Bad manifest inventory')
    seen=set()
    for record in records:
        if not isinstance(record,dict) or set(record)!=RECORD_FIELDS:raise ValueError('Bad manifest record')
        name=record['path']
        if not isinstance(name,str) or name not in FILES or name in seen:raise ValueError('Bad manifest path')
        seen.add(name)
        size=record['bytes']
        if type(size) is not int or size<0 or size>MAX_ARCHIVE_BYTES:raise ValueError('Bad manifest size')
        fingerprint=record['sha256']
        if not isinstance(fingerprint,str) or re.fullmatch(r'[0-9a-f]{64}',fingerprint) is None:raise ValueError('Bad manifest hash')
    return value

def verify(raw):
    if not isinstance(raw,(bytes,bytearray)) or len(raw)>MAX_ARCHIVE_BYTES:raise ValueError('Archive too large or invalid')
    with zipfile.ZipFile(io.BytesIO(raw)) as z:
        names=z.namelist()
        if len(names)!=len(set(names)) or set(names)!=set(FILES)|{'MANIFEST.json'}:raise ValueError('Unexpected inventory')
        members=z.infolist()
        if sum(x.file_size for x in members)>MAX_ARCHIVE_BYTES:raise ValueError('Bad archive')
        for member in members:
            kind=stat.S_IFMT(member.external_attr>>16)
            # Some ordinary ZIP writers omit Unix type bits. Explicit types
            # must be regular files; reject links/devices and DOS directories.
            if member.is_dir() or member.external_attr&0x10 or kind not in (0,stat.S_IFREG):raise ValueError('Non-regular archive entry')
            if member.flag_bits&1:raise ValueError('Encrypted archive entry')
            if member.compress_type not in (zipfile.ZIP_STORED,zipfile.ZIP_DEFLATED):raise ValueError('Unsupported archive compression')
        manifest_info=z.getinfo('MANIFEST.json')
        if manifest_info.file_size>MAX_MANIFEST_BYTES:raise ValueError('Manifest too large')
        m=_parse_manifest(z.read(manifest_info))
        for r in m['files']:
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
