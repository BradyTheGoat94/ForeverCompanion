from pathlib import Path
import sys
root=Path("ForeverCompanion")
toc=root/"ForeverCompanion.toc"
lines=toc.read_text().splitlines()
entries=[x.strip() for x in lines if x.strip() and not x.startswith("#")]
issues=[]
if len(entries)!=len(set(entries)): issues.append("Duplicate manifest entries")
if not entries or entries[-1]!="Core.lua": issues.append("Core.lua must load last")
for name in entries:
 if not (root/name).is_file(): issues.append("Missing: "+name)
for path in root.glob("*.lua"):
 if path.name not in entries: issues.append("Unlisted: "+path.name)
source="\n".join(path.read_text() for path in root.glob("*.lua"))
for pattern in ["GetNumSpellTabs(", "CombatLogGetCurrentEventInfo(", "CastSpellByName(", "RunMacroText(", "CastSpell(", "TargetUnit(", "UseAction(", "SendChatMessage(", "C_Timer.After(", "loadstring(", "load(", "HttpRequest(", "C_HTTP.", "C_Network.", "AcceptQuest(", "CompleteQuest(", "AbandonQuest(", "SelectQuestLogEntry(", "SetQuestLogSelection(", "C_QuestLog.SetSelectedQuest(", "C_QuestLog.SetAbandonQuest("]:
 if pattern in source: issues.append("Review legacy or automated API: "+pattern)
# The ZIP must contain source and client-native references, not extracted
# Blizzard artwork or executable payloads. Keep any future assets explicitly
# reviewed instead of silently expanding the allowed package surface.
allowed_extensions={".lua",".toc"}
reviewed_assets={"Media/Citadel.tga":(1024,256,24),"Media/Crest.tga":(256,256,32)}
for path in root.rglob("*"):
 if path.is_file() and path.relative_to(root).as_posix() in reviewed_assets:
  import struct
  data=path.read_bytes()
  width,height,bpp=reviewed_assets[path.relative_to(root).as_posix()]
  if len(data)<18 or data[2]!=2 or struct.unpack_from('<HHB',data,12)!=(width,height,bpp):
   issues.append("Invalid uncompressed project texture: "+str(path))
  continue
 if path.is_file() and path.suffix.lower() not in allowed_extensions:
  issues.append("Unexpected packaged asset (manual license review required): "+str(path))
if not Path('ARTWORK_PROVENANCE.md').is_file(): issues.append('Missing project artwork provenance')
for entry in entries:
 if "/" in entry or "\\\\" in entry or entry.startswith(".") or ".." in entry:
  issues.append("Unsafe manifest path: "+entry)
if "C_SpellBook" not in source: issues.append("Missing modern spellbook API")
for issue in issues: print("FAIL",issue)
if issues: sys.exit(1)
print("Release audit passed")
