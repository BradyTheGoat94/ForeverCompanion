-- Specialization planning matrix, advisory only. Not verified for WoW Forever.
ForeverCompanionSpecs={
 WARRIOR={{"Arms","Damage","Weapon-based pressure and rage management"},{"Fury","Damage","Sustained melee uptime and rage spending"},{"Protection","Tank","Threat, positioning, and survival"}},
 PALADIN={{"Holy","Healer","Efficient healing, cleansing, and mana"},{"Protection","Tank","Threat, mitigation, and group control"},{"Retribution","Damage","Weapon uptime, seals, and support"}},
 HUNTER={{"Beast Mastery","Damage","Pet uptime, positioning, and ranged attacks"},{"Marksmanship","Damage","Ranged burst and careful resource use"},{"Survival","Damage","Control, traps, and safe positioning"}},
 ROGUE={{"Assassination","Damage","Poison and finisher management"},{"Combat","Damage","Sustained uptime and energy management"},{"Subtlety","Damage","Control, positioning, and planned burst"}},
 PRIEST={{"Discipline","Healer","Prevention, dispels, and mana efficiency"},{"Holy","Healer","Direct healing and group recovery"},{"Shadow","Damage","Damage-over-time uptime and resource use"}},
 SHAMAN={{"Elemental","Damage","Spell pressure and totem utility"},{"Enhancement","Damage","Melee uptime and supportive totems"},{"Restoration","Healer","Healing throughput and mana"}},
 MAGE={{"Arcane","Damage","Burst windows and mana planning"},{"Fire","Damage","Sustained spell pressure and positioning"},{"Frost","Damage","Control, survivability, and uptime"}},
 WARLOCK={{"Affliction","Damage","Damage-over-time upkeep and pet utility"},{"Demonology","Damage","Pet support and survivability"},{"Destruction","Damage","Direct spell damage and threat"}},
 DRUID={{"Balance","Damage","Spell uptime and mana management"},{"Feral","Damage","Form-specific resources and positioning"},{"Restoration","Healer","Healing-over-time and mana efficiency"},{"Guardian / Bear","Tank","Bear-form threat and survival (availability depends on version)"}}
}
ForeverCompanionSpecPlanner={}
local P=ForeverCompanionSpecPlanner
local modes={"leveling","dungeon","boss","aoe","pvp"}
local function db()
 if type(ForeverCompanionDB)~="table" then ForeverCompanionDB={} end
 if type(ForeverCompanionDB.specSelections)~="table" then ForeverCompanionDB.specSelections={} end
 return ForeverCompanionDB.specSelections
end
function P.Get(class)
 local choices=ForeverCompanionSpecs[class] or {}
 local saved=class~=nil and db()[class] or nil
 local index=(type(saved)=="number" or type(saved)=="string") and tonumber(saved) or 1
 if not index or index~=index or index<1 or index>#choices or index%1~=0 then index=1 end
 return choices[index],index,#choices
end
function P.Next(class)
 local _,index,total=P.Get(class)
 if total==0 then return end
 db()[class]=(index%total)+1
end
-- Some planner alternatives are illustrative rather than confirmed client specs.
-- Keep them visible for reference, but never silently present them as verified.
function P.Evidence(class)
 local choice=P.Get(class)
 local name=type(choice)=="table" and choice[1]
 if class=="DRUID" and name=="Guardian / Bear" then
  return "UNCONFIRMED: Guardian / Bear is a planner alternative; check the Forever talent tree."
 end
 return "ADVISORY: spec availability, talent ranks and rotations require live-client checks."
end
local plans={
 Damage={
  leveling={"Keep enemies controlled and sustain damage without exhausting resources.","Use burst only when a difficult pull warrants it.","Save an escape or defensive ability for mistakes."},
  dungeon={"Follow the tank's target and avoid breaking crowd control.","Coordinate offensive cooldowns with safe pull windows.","Reserve interrupts and defensives for dangerous casts."},
  boss={"Maintain specialization-specific damage effects and resource flow.","Align offensive cooldowns with uptime, encounter mechanics, and group buffs.","Use defensive cooldowns proactively for predictable damage."},
  aoe={"Wait for the tank to establish threat before cleaving.","Use area damage appropriate to the number of controlled targets.","Retain crowd control and defensive tools for unexpected adds."},
  pvp={"Establish control and pressure before committing burst.","Watch enemy immunities and defensives; do not waste offensive cooldowns.","Reserve mobility, interrupts, and survival cooldowns for counterplay."}
 },
 Tank={
  leveling={"Keep enemies positioned in front and manage defensive resources.","Use threat tools when fighting multiple enemies.","Save a major defensive for dangerous pulls."},
  dungeon={"Establish threat and position enemies away from the group.","Plan mitigation around heavy pulls and dangerous casts.","Communicate defensive cooldown usage with the healer."},
  boss={"Maintain threat and face the boss safely.","Plan major defensives around predictable damage or swaps.","Avoid spending all mitigation cooldowns simultaneously without a reason."},
  aoe={"Group enemies and establish multi-target threat.","Use control and mitigation as pack damage ramps up.","Protect healers and avoid excessive pulls."},
  pvp={"Peel attackers from teammates and protect objectives.","Use defensive cooldowns when pressured, not merely on availability.","Coordinate crowd control and utility."}
 },
 Healer={
  leveling={"Use efficient damage between necessary heals.","Preserve mana and avoid dangerous overpulls.","Keep an emergency defensive or recovery tool available."},
  dungeon={"Keep the tank and threatened allies alive; dispel as needed.","Save throughput cooldowns for heavy damage or mistakes.","Manage mana and communicate before difficult pulls."},
  boss={"Plan healing and defensive cooldowns around predictable raid damage.","Use efficient spells outside high-pressure windows.","Coordinate major cooldowns to avoid redundant overlap."},
  aoe={"Prepare for heavy tank damage during multi-target pulls.","Use group recovery only when necessary.","Preserve control and emergency healing for unexpected adds."},
  pvp={"Stay positioned safely and protect vulnerable allies.","Trade defensives against enemy burst instead of overlapping everything.","Dispel and crowd-control when safe."}
 }
}
function P.Format(class,mode)
 local spec,index,total=P.Get(class)
 if not spec then return "No specialization plans available." end
 local role=spec[2]
 local lines={"SPECIALIZATION PLAN: "..spec[1].." ("..role..") ["..index.."/"..total.."]","Focus: "..spec[3]}
 for i,step in ipairs((plans[role] and plans[role][mode]) or {}) do lines[#lines+1]=i..". "..step end
 lines[#lines+1]="COOLDOWN TIMING: Offense during safe uptime; defense for incoming danger; utility for casts, control, or movement."
 lines[#lines+1]="Spec names and abilities may differ on Forever. These are role-based planning principles, not a verified spell priority or talent build."
 return table.concat(lines,"\n")
end
SLASH_FOREVERCOMPANIONSPEC1="/fcspec"
SlashCmdList.FOREVERCOMPANIONSPEC=function(msg)
 local class=tostring(msg or ""):upper():match("^%s*(%a+)%s*$")
 if not class or not ForeverCompanionSpecs[class] then
  print("|cffffcc66Forever Companion:|r /fcspec WARRIOR (or another class) cycles its specialization preview.")
  return
 end
 P.Next(class)
 local spec=P.Get(class)
 print("|cffffcc66Forever Companion:|r "..class.." preview: "..spec[1])
end
