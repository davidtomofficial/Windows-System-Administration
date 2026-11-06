"""Build a reproducible source-only review bundle; no device collection or networking."""
import argparse, hashlib, io, json, re, zipfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
EXACT=(
 'README.md','LICENSE.md','CONTRIBUTING.md','Config/check-in.policy.example.json',
 'Docs/REVIEWER-GUIDE.md','Docs/REPOSITORY-MIGRATION.md','Docs/LICENSING.md',
 'Docs/USAGE-CHECK-IN.md','Docs/REPOSITORY-A-PLUS.md','Docs/REPOSITORY-REVIEW-TODO.md',
 'Docs/WORK-AGENT-HANDOFF.md','Docs/DTO-WINDOWS-ADMIN-TODO.md',
 'Docs/DTO-WINDOWS-ADMIN-WORKSTREAMS.md','Docs/DTO-WINDOWS-ADMIN-PROGRESS.md',
 'Docs/Technician-Migration-and-Cleanup.md','Tools/build_review_bundle.py',
 'Tests/test_repository_review.py','.github/workflows/dto-integration-review.yml',
 'Docs/TASK-RESULT-CONTRACT.md','Contracts/fixtures/task-result-cases.json',
 'Shared/ResultContract.psm1','Tests/Run-ResultContractChecks.ps1','Tests/check_result_parity.py',
)
PRODUCTS={
 'Scripts/DeviceCare':('.gitignore','README.md','TODO.md','LICENSE.md','brand/product.json','brand/report.html','brand/dto-header-monogram.svg','brand/ASSET-PROVENANCE.md','docs/MIGRATION.md','docs/VALIDATION.md','src/DeviceCare.psm1','src/Presentation.ps1','src/Invoke-DTODeviceCare.ps1','tests/Run-Checks.ps1','tests/test_package.py','tools/package.py'),
 'Scripts/Imaging-Provisioning':('.gitignore','README.md','TODO.md','LICENSE.md','brand/product.json','docs/MIGRATION.md','docs/VALIDATION.md','docs/SNAPSHOT-COMPARISON.md','src/DTOImaging.psm1','src/Get-DTOWorkstationSnapshot.ps1','src/Get-DTOImageReview.ps1','src/DTOSnapshotComparison.psm1','tests/Run-Checks.ps1','tests/Run-ComparisonChecks.ps1','tests/test_package.py','tools/package.py'),
 'Launchpad':('README.md','DESIGN.md','TODO.md','catalog.plan.json','plan.py','test_plan.py','result_contract.py','test_result_contract.py'),
}
FILES=tuple(sorted(EXACT+tuple(f'{prefix}/{name}' for prefix,names in PRODUCTS.items() for name in names)))
def digest(data):return hashlib.sha256(data).hexdigest()
def build(root,commit):
 if not re.fullmatch('[0-9a-f]{40}',commit):raise ValueError('Exact source commit required')
 root=Path(root).resolve();items={}
 for name in FILES:
  path=root/name
  if path.is_symlink() or not path.is_file() or not path.resolve().is_relative_to(root):raise ValueError('Missing or unsafe source: '+name)
  data=path.read_bytes()
  if len(data)>1024*1024:raise ValueError('Unexpected source size')
  items[name]=data
 manifest={'schemaVersion':1,'kind':'SourceReviewNotOperationalRelease','sourceCommit':commit,'networkTrackingImplemented':False,'grade':None,'files':[{'path':name,'bytes':len(data),'sha256':digest(data)}for name,data in sorted(items.items())]}
 items['SOURCE-MANIFEST.json']=(json.dumps(manifest,indent=2)+'\n').encode()
 out=io.BytesIO()
 with zipfile.ZipFile(out,'w',zipfile.ZIP_DEFLATED,compresslevel=9) as archive:
  for name,data in sorted(items.items()):
   info=zipfile.ZipInfo(name,(2026,11,5,0,0,0));info.create_system=3;info.compress_type=zipfile.ZIP_DEFLATED;info.external_attr=0o100644<<16
   archive.writestr(info,data)
 raw=out.getvalue();verify(raw);return raw

def verify(raw):
 if len(raw)>8*1024*1024:raise ValueError('Archive too large')
 with zipfile.ZipFile(io.BytesIO(raw)) as archive:
  names=archive.namelist()
  if len(names)!=len(set(names)) or set(names)!=set(FILES)|{'SOURCE-MANIFEST.json'}:raise ValueError('Unexpected source membership')
  if sum(x.file_size for x in archive.infolist())>8*1024*1024:raise ValueError('Expanded archive too large')
  if archive.testzip() is not None:raise ValueError('CRC failure')
  m=json.loads(archive.read('SOURCE-MANIFEST.json'))
  if m.get('kind')!='SourceReviewNotOperationalRelease' or m.get('networkTrackingImplemented') is not False or m.get('grade') is not None:raise ValueError('False release claim')
  if not re.fullmatch('[0-9a-f]{40}',m.get('sourceCommit','')):raise ValueError('Missing source identity')
  if len(m['files'])!=len(FILES) or {x['path'] for x in m['files']}!=set(FILES):raise ValueError('Invalid manifest')
  for row in m['files']:
   data=archive.read(row['path'])
   if len(data)!=row['bytes'] or digest(data)!=row['sha256']:raise ValueError('Source mismatch')
  return m

if __name__=='__main__':
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('--output',type=Path,required=True);p.add_argument('--commit',required=True);args=p.parse_args()
 data=build(ROOT,args.commit)
 with args.output.open('xb') as stream:stream.write(data)
 print(json.dumps({'sourceFiles':len(FILES),'sha256':digest(data),'bytes':len(data),'sourceCommit':args.commit,'trackingImplemented':False,'grade':None}))
