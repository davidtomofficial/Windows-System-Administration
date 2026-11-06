from pathlib import Path
import importlib.util, io, json, tempfile, unittest, zipfile
ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('devicecare_pack',ROOT/'tools/package.py')
pkg=importlib.util.module_from_spec(spec);spec.loader.exec_module(pkg)
class Tests(unittest.TestCase):
    def setUp(self):self.raw=pkg.build(ROOT)
    def rewrite(self,target,data):
        out=io.BytesIO()
        with zipfile.ZipFile(io.BytesIO(self.raw)) as source, zipfile.ZipFile(out,'w') as dest:
            for n in source.namelist():dest.writestr(n,data if n==target else source.read(n))
        return out.getvalue()
    def test_identical(self):self.assertEqual(self.raw,pkg.build(ROOT))
    def test_manifest_roundtrip(self):self.assertEqual(len(pkg.verify(self.raw)['files']),len(pkg.FILES))
    def test_tamper(self):
        with self.assertRaises(ValueError):pkg.verify(self.rewrite('README.md',b'altered'))
    def test_promotion_refusal(self):
        with zipfile.ZipFile(io.BytesIO(self.raw)) as z:m=json.loads(z.read('MANIFEST.json'))
        m['deploymentAccepted']=True
        with self.assertRaises(ValueError):pkg.verify(self.rewrite('MANIFEST.json',json.dumps(m).encode()))
    def test_unknown_entry(self):
        out=io.BytesIO(self.raw)
        with zipfile.ZipFile(out,'a') as z:z.writestr('secret.txt','not allowed')
        with self.assertRaises(ValueError):pkg.verify(out.getvalue())
    def test_missing_source(self):
        with tempfile.TemporaryDirectory() as p:
            with self.assertRaises(ValueError):pkg.build(Path(p))
    def test_extra_private_file_not_packaged(self):
        with tempfile.TemporaryDirectory() as p:
            d=Path(p)
            for n in pkg.FILES:
                f=d/n;f.parent.mkdir(parents=True,exist_ok=True);f.write_bytes((ROOT/n).read_bytes())
            (d/'private-device.json').write_text('private')
            with zipfile.ZipFile(io.BytesIO(pkg.build(d))) as z:self.assertNotIn('private-device.json',z.namelist())
    def test_brand_and_public_boundary(self):
        p=json.loads((ROOT/'brand/product.json').read_text())
        self.assertEqual(p['publisher'],'David Tom Official')
        self.assertEqual(p['contactEmail'],'david.tom@davidtomofficial.com')
        self.assertEqual(p['branding']['navy'],'#0F2747')
        for n in pkg.FILES:
            if n == 'tests/test_package.py':
                continue  # This test must name its own forbidden fixtures.
            s=(ROOT/n).read_text(errors='replace').lower()
            for secret in ('davidtomsolutions','davidtompublishing','david tom holdings','cjis','private-github-backup'):
                self.assertNotIn(secret,s,(n,secret))
    def test_no_mutation_calls(self):
        script=(ROOT/'src/DeviceCare.psm1').read_text()
        for forbidden in ('Set-Service','Stop-Service','Start-Service','Remove-Item','Set-ItemProperty','Invoke-WebRequest','Start-Process'):
            self.assertNotIn(forbidden,script)
if __name__=='__main__':unittest.main(verbosity=2)
