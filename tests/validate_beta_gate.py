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
# Conservative release audit: block direct calls that could perform protected
# gameplay actions or solicit money inside the addon. This is not a substitute
# for manual source review or testing against the real Forever client.
import re
lua_files=list(root.rglob("*.lua"))
assert lua_files,"No Lua addon source found"
for source in lua_files:
    code=source.read_text(encoding="utf-8-sig")
    for forbidden in ("CastSpellByName","CastSpellByID","UseAction",
                      "UseInventoryItem","UseContainerItem","RunMacroText",
                      "TargetUnit","AttackTarget","StartAttack",
                      "AcceptQuest","CompleteQuest","BuyMerchantItem"):
        assert not re.search(r"\b"+forbidden+r"\s*\(",code), (
            f"Potential protected gameplay call {forbidden} in {source}"
        )
policy=Path("CURSEFORGE_COMPLIANCE.md")
assert policy.is_file(),"Missing CurseForge compliance review"
review=policy.read_text(encoding="utf-8").lower()
for requirement in ("free","source","donation","advertis","screenshot",
                    "forever","manual","license"):
    assert requirement in review,f"Compliance review missing: {requirement}"
print("PASS: static protected-action scan and CurseForge review present")
# Native class icons must be referenced from the installed client, never
# external URLs or shipped artwork. Require all nine class entries.
guide=(root/"GuideData.lua").read_text(encoding="utf-8")
import re
section=guide.split("classHandbook = {",1)[1].split("professionHandbook = {",1)[0]
for class_name in ("WARRIOR","PALADIN","HUNTER","ROGUE","PRIEST",
                   "SHAMAN","MAGE","WARLOCK","DRUID"):
    entry=re.search(r"\\b"+class_name+r"\\s*=\\s*\\{icon=([^,]+),",section)
    assert entry,f"Missing native class icon for {class_name}"
    icon=entry.group(1)
    assert icon.startswith('"Interface\\\\\\\\Icons\\\\\\\\'),(
        f"Class icon for {class_name} must use a Blizzard client icon path"
    )
    assert "http" not in icon.lower(),f"External icon reference for {class_name}"
print("PASS: nine class icons reference native Blizzard interface textures")

print("PASS: beta metadata, required release docs and live-client gate present")
