-- Passive compatibility diagnostics. Never changes game state or executes combat actions.
ForeverCompanionDiagnostics={}
local D=ForeverCompanionDiagnostics
local function available(obj,name)
 return type(obj)=="table" and type(obj[name])=="function"
end
function D.Version()
 local metadata=type(C_AddOns)=="table" and C_AddOns.GetAddOnMetadata
 local ok,version=pcall(metadata or GetAddOnMetadata,"ForeverCompanion","Version")
 return ok and type(version)=="string" and version or "3.36.0-beta"
end
function D.Collect()
 local rows={}
 local function add(label,ok)
  rows[#rows+1]=label..": "..(ok and "available" or "unavailable")
 end
 local build="unknown"
 if type(GetBuildInfo)=="function" then
  local ok,version,buildNumber,_,interface=pcall(GetBuildInfo)
  if ok then build=tostring(version or "?").." build "..tostring(buildNumber or "?").." interface "..tostring(interface or "?") end
 end
 rows[#rows+1]="Addon: Brady\'s Forever Companion "..D.Version()
 rows[#rows+1]="Client: "..build
 rows[#rows+1]="Manifest interface: 16001 (documented on Forever 1.60.1; verify current patch)"
 if type(GetBuildInfo)=="function" then
  local ok,_,_,_,interface=pcall(GetBuildInfo)
  if ok and type(interface)=="number" then
   rows[#rows+1]="Interface match: "..(interface==16001 and "yes" or "NO - verify addon manifest")
  end
 end
 add("Modern spellbook lines",available(C_SpellBook,"GetNumSpellBookSkillLines"))
 add("Modern spellbook entries",available(C_SpellBook,"GetSpellBookItemName"))
 add("Modern spellbook bank",type(Enum)=="table" and type(Enum.SpellBookSpellBank)=="table" and Enum.SpellBookSpellBank.Player~=nil)
 add("Modern spellbook line details",available(C_SpellBook,"GetSpellBookSkillLineInfo"))
 add("Modern talents",available(C_Traits,"GetConfigInfo"))
 add("Modern trait trees",available(C_Traits,"GetTreeNodes"))
 add("Modern spell API",available(C_Spell,"GetSpellInfo"))
 add("Modern quest entry details",available(C_QuestLog,"GetInfo"))
 add("Legacy UI toggle",type(ToggleLegacySystemUI)=="function")
 add("Retail specialization global (not expected on early Forever)",type(GetSpecialization)=="function")
 rows[#rows+1]="Spec picker: advisory; does not assume Retail specialization IDs"
 add("Legacy professions",type(GetProfessions)=="function" and type(GetProfessionInfo)=="function")
 add("Modern quest log",available(C_QuestLog,"GetNumQuestLogEntries"))
 add("Quest objective API",available(C_QuestLog,"GetQuestObjectives"))
 add("XP read",type(UnitXP)=="function" and type(UnitXPMax)=="function")
 if type(ForeverCompanionSpellbook)=="table" and type(ForeverCompanionSpellbook.Scan)=="function" then
  local ok,scan=pcall(ForeverCompanionSpellbook.Scan)
  if ok and type(scan)=="table" then
   rows[#rows+1]="Spellbook scan: "..(scan.supported and (scan.complete and "complete" or "partial") or "unsupported")
   rows[#rows+1]="Spellbook named entries: "..tostring(scan.inspected or 0)
  else
   rows[#rows+1]="Spellbook scan: error (inspect Lua errors)"
  end
 end
 if type(ForeverCompanionAbilityAudit)=="function" then
  local ok,audit=pcall(ForeverCompanionAbilityAudit)
  if ok and type(audit)=="table" then
   rows[#rows+1]="Curated ability records: "..tostring(audit.total or 0)
   rows[#rows+1]="Curated ability issues: "..tostring(type(audit.issues)=="table" and #audit.issues or "?")
  else
   rows[#rows+1]="Curated ability audit: error"
  end
 end
 rows[#rows+1]="These checks show API presence only; they do not prove safe or correct behavior."
 return table.concat(rows,"\n")
end
SLASH_FOREVERCOMPANIONDIAGNOSTICS1="/fcdiag"
SlashCmdList.FOREVERCOMPANIONDIAGNOSTICS=function()
 print("|cffffcc66Brady\'s Forever Companion compatibility:|r")
 for line in D.Collect():gmatch("[^\n]+") do print(line) end
end
