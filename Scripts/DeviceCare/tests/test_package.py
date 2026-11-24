from pathlib import Path
import importlib.util, io, json, stat, tempfile, unittest, zipfile, hashlib, xml.etree.ElementTree as ET
ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('devicecare_pack',ROOT/'tools/package.py')
pkg=importlib.util.module_from_spec(spec);spec.loader.exec_module(pkg)
class Tests(unittest.TestCase):
    def setUp(self):self.raw=pkg.build(ROOT)
    def rewrite(self,target,data,raw=None):
        out=io.BytesIO()
        with zipfile.ZipFile(io.BytesIO(self.raw if raw is None else raw)) as source, zipfile.ZipFile(out,'w') as dest:
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
    def test_duplicate_manifest_properties_are_refused(self):
        with zipfile.ZipFile(io.BytesIO(self.raw)) as z:raw=z.read('MANIFEST.json')
        for replaced in (
            raw.replace(b'"deploymentAccepted": false',b'"deploymentAccepted": true, "deploymentAccepted": false'),
            raw.replace(b'"schemaVersion": 1',b'"schemaVersion": 999, "schemaVersion": 1'),
            raw.replace(b'"path": "',b'"bytes": 0, "path": "',1),
        ):
            with self.subTest(manifest=replaced[:80]), self.assertRaises(ValueError):
                pkg.verify(self.rewrite('MANIFEST.json',replaced))
    def test_manifest_schema_requires_integer(self):
        with zipfile.ZipFile(io.BytesIO(self.raw)) as z:m=json.loads(z.read('MANIFEST.json'))
        for value in (True,1.0,'1',None):
            m['schemaVersion']=value
            with self.subTest(value=value), self.assertRaises(ValueError):
                pkg.verify(self.rewrite('MANIFEST.json',json.dumps(m).encode()))
    def test_manifest_shapes_and_private_extra_fields_are_refused(self):
        with zipfile.ZipFile(io.BytesIO(self.raw)) as z:original=json.loads(z.read('MANIFEST.json'))
        mutations=[[],None,{'schemaVersion':1},dict(original,private='PRIVATE-CANARY')]
        for replacement in (None,{},'records',list(original['files'])+[original['files'][0]]):
            mutations.append(dict(original,files=replacement))
        for value in mutations:
            with self.subTest(value=type(value).__name__), self.assertRaises(ValueError):
                pkg.verify(self.rewrite('MANIFEST.json',json.dumps(value).encode()))
    def test_manifest_record_types_and_inventory_are_exact(self):
        with zipfile.ZipFile(io.BytesIO(self.raw)) as z:original=json.loads(z.read('MANIFEST.json'))
        for field,value in (('bytes',True),('bytes',1.0),('bytes','1'),('bytes',-1),('bytes',pkg.MAX_ARCHIVE_BYTES+1),
                            ('path',None),('path',[]),('path','../private.json'),
                            ('sha256',None),('sha256',[]),('sha256','A'*64),('sha256','0'*63),('private','PRIVATE-CANARY')):
            m=json.loads(json.dumps(original));m['files'][0][field]=value
            with self.subTest(field=field,value=value), self.assertRaises(ValueError):
                pkg.verify(self.rewrite('MANIFEST.json',json.dumps(m).encode()))
        for record in (None,[],{},original['files'][1]):
            m=json.loads(json.dumps(original));m['files'][0]=record
            with self.subTest(record=record), self.assertRaises(ValueError):
                pkg.verify(self.rewrite('MANIFEST.json',json.dumps(m).encode()))
    def test_nonregular_entries_are_refused(self):
        for mode in (stat.S_IFLNK|0o777,stat.S_IFDIR|0o755,stat.S_IFIFO|0o600,stat.S_IFCHR|0o600,stat.S_IFBLK|0o600,stat.S_IFSOCK|0o600):
            out=io.BytesIO()
            with zipfile.ZipFile(io.BytesIO(self.raw)) as source,zipfile.ZipFile(out,'w') as dest:
                for info in source.infolist():
                    data=source.read(info.filename)
                    if info.filename=='README.md':info.external_attr=mode<<16
                    dest.writestr(info,data)
            with self.subTest(mode=mode), self.assertRaises(ValueError):pkg.verify(out.getvalue())
    def test_manifest_byte_count_cannot_use_numeric_coercion(self):
        with zipfile.ZipFile(io.BytesIO(self.raw)) as z:original=json.loads(z.read('MANIFEST.json'))
        m=json.loads(json.dumps(original));m['files'][0]['bytes']=float(m['files'][0]['bytes'])
        with self.assertRaises(ValueError):pkg.verify(self.rewrite('MANIFEST.json',json.dumps(m).encode()))
        m=json.loads(json.dumps(original))
        record=next(item for item in m['files'] if item['path']=='README.md')
        record.update(bytes=True,sha256=hashlib.sha256(b'x').hexdigest())
        raw=self.rewrite('README.md',b'x')
        with self.assertRaises(ValueError):pkg.verify(self.rewrite('MANIFEST.json',json.dumps(m).encode(),raw=raw))
    def test_dos_directory_flag_is_refused(self):
        out=io.BytesIO()
        with zipfile.ZipFile(io.BytesIO(self.raw)) as source,zipfile.ZipFile(out,'w') as dest:
            for info in source.infolist():
                data=source.read(info.filename)
                if info.filename=='README.md':info.create_system=0;info.external_attr=0x10
                dest.writestr(info,data)
        with self.assertRaises(ValueError):pkg.verify(out.getvalue())
    def test_manifest_json_is_bounded_and_well_formed(self):
        for value in (b'{',b'\xff',b'{"schemaVersion":NaN}',b'['*2000+b']'*2000,b' '*pkg.MAX_MANIFEST_BYTES+b'{}'):
            with self.subTest(size=len(value)), self.assertRaises(ValueError):
                pkg.verify(self.rewrite('MANIFEST.json',value))
    def test_ordinary_archive_without_unix_type_bits_remains_valid(self):
        with zipfile.ZipFile(io.BytesIO(self.raw)) as z:readme=z.read('README.md')
        self.assertEqual(len(pkg.verify(self.rewrite('README.md',readme))['files']),len(pkg.FILES))
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
        script=(ROOT/'src/DeviceCare.psm1').read_text()+(ROOT/'src/Presentation.ps1').read_text()
        for forbidden in ('Set-Service','Stop-Service','Start-Service','Remove-Item','Set-ItemProperty','Invoke-WebRequest','Start-Process'):
            self.assertNotIn(forbidden,script)
    def test_asset_hash(self):
        brand=json.loads((ROOT/'brand/product.json').read_text())
        raw=(ROOT/'brand/dto-header-monogram.svg').read_bytes()
        self.assertEqual(hashlib.sha256(raw).hexdigest(),brand['branding']['headerAssetSha256'])
        self.assertEqual(hashlib.sha1(b'blob '+str(len(raw)).encode()+b'\0'+raw).hexdigest(),'dcec06a42443040f57ccffa486dd0a9965994b07')
        svg=ET.fromstring(raw)
        self.assertEqual(svg.attrib['viewBox'],'0 0 512 512')
        self.assertFalse(any(x.tag.endswith('script') for x in svg.iter()))
    def test_version_alignment(self):
        self.assertEqual(json.loads((ROOT/'brand/product.json').read_text())['version'],'0.2.0-dto-preview')
        self.assertIn('0.2.0 development preview',(ROOT/'brand/report.html').read_text())
    def test_report_is_offline(self):
        html=(ROOT/'brand/report.html').read_text()
        self.assertIn("default-src 'none'",html)
        self.assertIn('img-src data:',html)
        self.assertNotIn('<script',html)
        self.assertNotIn('src="http',html)
        self.assertNotIn('@import',html)
if __name__=='__main__':unittest.main(verbosity=2)
