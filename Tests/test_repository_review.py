"""Repository review checks. No endpoint actions, telemetry or licensing server calls."""
import hashlib, importlib.util, io, json, re, subprocess, unittest, zipfile
from pathlib import Path
from urllib.parse import unquote
ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('review_bundle',ROOT/'Tools/build_review_bundle.py');bundle=importlib.util.module_from_spec(spec);spec.loader.exec_module(bundle)
class ReviewTests(unittest.TestCase):
 def test_required_inventory(self):
  for name in bundle.FILES:self.assertTrue((ROOT/name).is_file(),name)
 def test_notices_match(self):
  expected=(ROOT/'LICENSE.md').read_bytes()
  for component in ('DeviceCare','Imaging-Provisioning'):self.assertEqual((ROOT/f'Scripts/{component}/LICENSE.md').read_bytes(),expected)
 def test_permission_exceptions(self):
  text=(ROOT/'LICENSE.md').read_text()
  for phrase in ('explicit written permission','previously granted licenses','third-party','view and fork','not an executed customer agreement'):self.assertIn(phrase,text)
 def test_checkin_honesty(self):
  p=json.loads((ROOT/'Config/check-in.policy.example.json').read_text())
  self.assertIs(p['requiredForFuturePermissionLicensedBuilds'],True);self.assertIs(p['runtimeEnabled'],False);self.assertIsNone(p['endpoint']);self.assertIsNone(p['credentials'])
  self.assertEqual(p['implementationStatus'],'NotImplemented');self.assertIs(p['cadenceAndRetentionApproved'],False)
 def test_checkin_privacy(self):
  p=json.loads((ROOT/'Config/check-in.policy.example.json').read_text())
  for key in ('collectHardwareIdentifiers','uploadDiagnosticReports','allowRemoteCommands','interruptActiveMaintenanceOnExpiry'):self.assertIs(p[key],False)
 def test_core_links(self):
  owned=('Scripts/DeviceCare/README.md','Scripts/Imaging-Provisioning/README.md','README.md','Launchpad/README.md','CONTRIBUTING.md','Docs/REVIEWER-GUIDE.md','Docs/REPOSITORY-MIGRATION.md','Docs/LICENSING.md','Docs/USAGE-CHECK-IN.md','Docs/DTO-WINDOWS-ADMIN-TODO.md','Docs/REPOSITORY-REVIEW-TODO.md','Docs/WORK-AGENT-HANDOFF.md')
  owned+=('Docs/PROOF-PACKAGES.md','Scripts/DeviceCare/docs/PROOF-PACKAGE.md','Scripts/Imaging-Provisioning/docs/PROOF-PACKAGE.md')
  for name in owned:
   for target in re.findall(r'\[[^\]]*\]\(([^)]+)\)',(ROOT/name).read_text()):
    if target.startswith(('https:','http:','mailto:','#')):continue
    path=unquote(target.split('#',1)[0]);self.assertTrue((ROOT/name).parent.joinpath(path).exists(),(name,target))
 def test_licensed_source_packages(self):
  for component in ('DeviceCare','Imaging-Provisioning'):
   path=ROOT/f'Scripts/{component}/tools/package.py';s=importlib.util.spec_from_file_location('pack_'+component,path);m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
   with zipfile.ZipFile(io.BytesIO(m.build(path.parents[1]))) as z:self.assertEqual(z.read('LICENSE.md'),(ROOT/'LICENSE.md').read_bytes())
 def test_reproducible_source_bundle(self):
  a=bundle.build(ROOT,'0'*40);self.assertEqual(a,bundle.build(ROOT,'0'*40));self.assertEqual(len(bundle.verify(a)['files']),len(bundle.FILES))
 def test_false_release_refused(self):
  raw=bundle.build(ROOT,'0'*40);out=io.BytesIO()
  with zipfile.ZipFile(io.BytesIO(raw)) as source,zipfile.ZipFile(out,'w') as dest:
   for name in source.namelist():
    data=source.read(name)
    if name=='SOURCE-MANIFEST.json':m=json.loads(data);m['networkTrackingImplemented']=True;data=json.dumps(m).encode()
    dest.writestr(name,data)
  with self.assertRaises(ValueError):bundle.verify(out.getvalue())
 def test_planner_stays_nonexecuting(self):
  p=json.loads((ROOT/'Launchpad/catalog.plan.json').read_text());self.assertIs(p['executionEnabled'],False)
  for a in p['actions']:self.assertIsNone(a['launcher']);self.assertEqual(a['state'],'Planned')
 def test_original_runtime_preserved(self):
  for commit,prefix in (('3ce2a915c20a2d6bb504280b2171cf7a3d5ce9b9','Scripts/DeviceCare/src/'),('173cda83ef639f16a7a5acf641f350bca79c7cca','Scripts/Imaging-Provisioning/src/')):
   names=subprocess.check_output(['git','ls-tree','-r','--name-only',commit,'--',prefix],cwd=ROOT,text=True).splitlines();self.assertTrue(names)
   for name in names:self.assertEqual(subprocess.check_output(['git','show',commit+':'+name],cwd=ROOT),(ROOT/name).read_bytes(),name)
 def test_platform_stable_zip_headers(self):
  with zipfile.ZipFile(io.BytesIO(bundle.build(ROOT,'0'*40))) as z:
   self.assertTrue(all(info.create_system==3 for info in z.infolist()))
  for component in ('DeviceCare','Imaging-Provisioning'):
   path=ROOT/f'Scripts/{component}/tools/package.py';s=importlib.util.spec_from_file_location('header_'+component,path);m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
   with zipfile.ZipFile(io.BytesIO(m.build(path.parents[1]))) as z:self.assertTrue(all(info.create_system==3 for info in z.infolist()))
 def test_no_grade_awarded(self):
  text=(ROOT/'Docs/REPOSITORY-A-PLUS.md').read_text();self.assertIn('Not graded',text);self.assertIn('97.00/100',text)
if __name__=='__main__':unittest.main(verbosity=2)
