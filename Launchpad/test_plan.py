import copy, importlib.util, json, tempfile, unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location("lp_plan",ROOT/"plan.py");p=importlib.util.module_from_spec(spec);spec.loader.exec_module(p)
class Tests(unittest.TestCase):
 def setUp(self):self.data=p.load(ROOT/"catalog.plan.json")
 def reject(self,change):
  change(self.data)
  with self.assertRaises(ValueError):p.validate(self.data)
 def test_inventory(self):self.assertEqual(len(self.data["actions"]),26)
 def test_execution_refused(self):self.reject(lambda d:d.update(executionEnabled=True))
 def test_numeric_false_refused(self):self.reject(lambda d:d.update(executionEnabled=0))
 def test_command_refused(self):self.reject(lambda d:d["actions"][0].update(command="anything"))
 def test_launcher_refused(self):self.reject(lambda d:d["actions"][0].update(launcher="run.bat"))
 def test_duplicate_id(self):self.reject(lambda d:d["actions"].append(copy.deepcopy(d["actions"][0])))
 def test_bad_category(self):self.reject(lambda d:d["actions"][0].update(category="unknown"))
 def test_bad_impact(self):self.reject(lambda d:d["actions"][0].update(impact="Safe"))
 def test_released_refused(self):self.reject(lambda d:d["actions"][0].update(state="Released"))
 def test_duplicate_json(self):
  with self.assertRaises(ValueError):json.loads('{"a":1,"a":2}',object_pairs_hook=p.unique)
 def test_oversize(self):
  with tempfile.TemporaryDirectory() as temp:
   path=Path(temp)/"large.json";path.write_bytes(b" "*262145)
   with self.assertRaises(ValueError):p.load(path)
 def test_no_dispatch(self):
  source=(ROOT/"plan.py").read_text()
  for word in ("import subprocess","os.system","eval(","exec(","urllib","requests"):self.assertNotIn(word,source)
if __name__=="__main__":unittest.main(verbosity=2)
