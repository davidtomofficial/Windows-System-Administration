import importlib.util
import io
import json
from pathlib import Path
import tempfile
import unittest
import zipfile

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('dto_package', ROOT / 'tools/package.py')
pkg = importlib.util.module_from_spec(spec)
spec.loader.exec_module(pkg)

class PackagingTests(unittest.TestCase):
    def setUp(self):
        self.data = pkg.build(ROOT)

    def mutate(self, name, body):
        output = io.BytesIO()
        with zipfile.ZipFile(io.BytesIO(self.data)) as source, zipfile.ZipFile(output, 'w') as dest:
            for n in source.namelist():
                dest.writestr(n, body if n == name else source.read(n))
        return output.getvalue()

    def test_roundtrip(self):
        self.assertEqual(len(pkg.verify(self.data)['files']), len(pkg.FILES))

    def test_reproducible(self):
        self.assertEqual(self.data, pkg.build(ROOT))

    def test_tamper(self):
        with self.assertRaises(ValueError):
            pkg.verify(self.mutate('README.md', b'changed'))

    def test_manifest_promotion(self):
        with zipfile.ZipFile(io.BytesIO(self.data)) as z:
            m = json.loads(z.read('MANIFEST.json'))
        m['deploymentAccepted'] = True
        with self.assertRaises(ValueError):
            pkg.verify(self.mutate('MANIFEST.json', json.dumps(m).encode()))

    def test_duplicate(self):
        output = io.BytesIO(self.data)
        with zipfile.ZipFile(output, 'a') as z:
            z.writestr('unlisted.txt', b'not allowed')
        with self.assertRaises(ValueError):
            pkg.verify(output.getvalue())

    def test_secrets_excluded(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            for n in pkg.FILES:
                p = root / n
                p.parent.mkdir(parents=True, exist_ok=True)
                p.write_bytes((ROOT / n).read_bytes())
            (root / 'private-device-report.json').write_text('private fixture')
            with zipfile.ZipFile(io.BytesIO(pkg.build(root))) as z:
                self.assertNotIn('private-device-report.json', z.namelist())

    def test_missing_source(self):
        with tempfile.TemporaryDirectory() as temp:
            with self.assertRaises(ValueError):
                pkg.build(Path(temp))

    def test_branding(self):
        p = json.loads((ROOT / 'brand/product.json').read_text())
        self.assertEqual(p['supportEmail'], 'david.tom@davidtomofficial.com')
        self.assertEqual(p['contactUrl'], 'https://davidtomofficial.com/#contact')
        self.assertEqual(p['colors']['navy'], '#0F2747')
        code = (ROOT / 'src/DTOImaging.psm1').read_text()
        self.assertNotIn('support@davidtomsolutions.com', code)
        for color in p['colors'].values():
            self.assertIn(color, code)

if __name__ == '__main__':
    unittest.main(verbosity=2)
