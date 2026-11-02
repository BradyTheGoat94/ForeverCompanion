-- Passive compatibility diagnostics. Never changes game state or executes combat actions.
ForeverCompanionDiagnostics={}
local D=ForeverCompanionDiagnostics
local function available(obj,name)
 return type(obj)=="table" and type(obj[name])=="function"
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
 rows[#rows+1]="Addon: Forever Companion 3.14.0-beta"
 rows[#rows+1]="Client: "..build
 rows[#rows+1]="Manifest interface: 16001 (verify against live client)"
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
 add("Legacy professions",type(GetProfessions)=="function" and type(GetProfessionInfo)=="function")
 add("Modern quest log",available(C_QuestLog,"GetNumQuestLogEntries"))
 add("Quest objective API",available(C_QuestLog,"GetQuestObjectives"))
 add("XP read",type(UnitXP)=="function" and type(UnitXPMax)=="function")
 rows[#rows+1]="These checks show API presence only; they do not prove safe or correct behavior."
 return table.concat(rows,"\n")
end
SLASH_FOREVERCOMPANIONDIAGNOSTICS1="/fcdiag"
SlashCmdList.FOREVERCOMPANIONDIAGNOSTICS=function()
 print("|cffffcc66Forever Companion compatibility:|r")
 for line in D.Collect():gmatch("[^\n]+") do print(line) end
end
