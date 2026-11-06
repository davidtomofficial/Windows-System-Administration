"""Validate and list planning entries only. No dispatch, subprocess or networking."""
import argparse, json
from pathlib import Path
CATEGORIES={"Prepare a device","Validate and hand off","Update and maintain","Connect to management","Troubleshoot and support","Manage a computer group","Return or remove a device"}
IMPACTS={"ReadOnly","DiagnosticWrites","DataChange","SystemChange","Disruptive","Destructive"}
def unique(pairs):
    result={}
    for key,value in pairs:
        if key in result: raise ValueError("Duplicate JSON key")
        result[key]=value
    return result

def validate(data):
    if not isinstance(data,dict) or set(data)!={"schemaVersion","kind","publisher","executionEnabled","actions"}: raise ValueError("Unexpected root fields")
    if type(data["schemaVersion"]) is not int or data["schemaVersion"]!=1 or data["kind"]!="PlanningCatalog" or data["publisher"]!="David Tom Official" or data["executionEnabled"] is not False: raise ValueError("Planning-only contract required")
    rows=data["actions"]
    if not isinstance(rows,list) or not 1<=len(rows)<=100: raise ValueError("Invalid action count")
    seen=set()
    for row in rows:
        if not isinstance(row,dict) or set(row)!={"id","label","category","impact","privilege","owner","taskId","description","state","launcher"}: raise ValueError("Unexpected action fields")
        if any(not isinstance(row[k],str) or not 1<=len(row[k])<=500 for k in row if k!="launcher"): raise ValueError("Invalid text")
        if row["id"] in seen or not all(c in "abcdefghijklmnopqrstuvwxyz0123456789-" for c in row["id"]): raise ValueError("Invalid or duplicate id")
        seen.add(row["id"])
        if row["category"] not in CATEGORIES or row["impact"] not in IMPACTS or row["privilege"] not in {"StandardUser","Administrator","Mixed","Delegated"}: raise ValueError("Invalid classification")
        if row["state"]!="Planned" or row["launcher"] is not None: raise ValueError("Executable entries are not supported")
    return data

def load(path):
    with Path(path).open("rb") as stream: raw=stream.read(262145)
    if len(raw)>262144: raise ValueError("Catalog too large")
    return validate(json.loads(raw.decode("utf-8"),object_pairs_hook=unique))

if __name__=="__main__":
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--catalog",type=Path,default=Path(__file__).with_name("catalog.plan.json"))
    args=parser.parse_args()
    try:
        data=load(args.catalog)
        for row in data["actions"]: print(f'{row["id"]}: {row["label"]} | {row["impact"]} | Planned; not executable')
        print(f'VALIDATED_PLANNED_ACTIONS={len(data["actions"])}; EXECUTION_ENABLED=False')
    except (ValueError,OSError,UnicodeError) as exc: parser.exit(2,f"Catalog refused: {exc}\n")
