#!/usr/bin/env python3
"""Generate an immutable, human-readable beta artifact provenance record."""
import hashlib
import json
import os
from pathlib import Path
from zipfile import ZipFile

path=Path("ForeverCompanion.zip")
assert path.is_file(), "Package must exist before provenance generation"
sha=hashlib.sha256(path.read_bytes()).hexdigest()
with ZipFile(path) as z:
    toc=z.read("ForeverCompanion/ForeverCompanion.toc").decode("utf-8-sig")
meta={}
for line in toc.splitlines():
    if line.startswith("## ") and ":" in line:
        k,v=line[3:].split(":",1)
        meta[k.strip()]=v.strip()
record={
    "package":path.name,
    "sha256":sha,
    "commit":os.getenv("GITHUB_SHA","local-unverified"),
    "ref":os.getenv("GITHUB_REF","local-unverified"),
    "run_id":os.getenv("GITHUB_RUN_ID","local-unverified"),
    "addon_version":meta.get("Version","unknown"),
    "manifest_interface":meta.get("Interface","unknown"),
    "in_game_tested":False,
    "release_approved":False,
}
Path("beta-build-manifest.json").write_text(json.dumps(record,indent=2,sort_keys=True)+"\n",encoding="utf-8")
print("Generated beta-build-manifest.json SHA256",sha)
