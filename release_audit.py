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
if "C_SpellBook" not in source: issues.append("Missing modern spellbook API")
for issue in issues: print("FAIL",issue)
if issues: sys.exit(1)
print("Release audit passed")
