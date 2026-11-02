#!/usr/bin/env python3
"""Check release documentation and addon metadata without claiming client testing."""
from pathlib import Path

root=Path("ForeverCompanion")
toc=(root/"ForeverCompanion.toc").read_text(encoding="utf-8-sig")
meta={}
for line in toc.splitlines():
    if line.startswith("## ") and ":" in line:
        key,value=line[3:].split(":",1)
        meta[key.strip()]=value.strip()
for field in ("Interface","Title","Version","Notes"):
    assert meta.get(field),f"Missing required addon metadata: {field}"
assert meta["Version"].endswith("-beta"),"Pre-release must be clearly labeled beta"
assert meta["Interface"].isdigit(),"Interface field must be numeric"
for name in ("BETA_RELEASE_GATE.md","BETA_INSTALL_TEST.md","BETA_VERIFICATION_RECORD.md","BETA_RELEASE_NOTES.md"):
    path=Path(name)
    assert path.is_file() and path.stat().st_size>100,f"Missing beta documentation: {name}"
gate=Path("BETA_RELEASE_GATE.md").read_text(encoding="utf-8")
assert "actual" in gate.lower() and "client" in gate.lower(),"Missing live-client release gate"
assert "main" in gate,"Missing protected main branch policy"
print("PASS: beta metadata, required release docs and live-client gate present")
