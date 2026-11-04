-- Dungeon readiness checklists: generic role practices, not server-specific boss tactics.
ForeverCompanionDungeonPreparation={}
local P=ForeverCompanionDungeonPreparation
P.roles={
 Tank={
  "Confirm the healer is ready and establish a first target before pulling.",
  "Face dangerous enemies away from the group where encounter mechanics permit.",
  "Plan a defensive response and an interrupt or control backup.",
  "Avoid chaining pulls while the group is recovering mana or health."
 },
 Healer={
  "Confirm appropriate healing gear, mana and consumables before entering.",
  "Identify the tank and agree on pauses for recovery.",
  "Watch for dispellable effects and plan an emergency heal response.",
  "Communicate if incoming damage exceeds sustainable healing."
 },
 Damage={
  "Identify priority targets and avoid breaking assigned crowd control.",
  "Check whether you have an interrupt or control option in your current spellbook.",
  "Avoid attacking before the tank establishes threat.",
  "Keep a defensive or escape option available for unexpected damage."
 }
}
function P.Format(role)
 local items=P.roles[role] or P.roles.Damage
 local lines={"DUNGEON READY CHECK - "..tostring(role or "Damage")}
 for i,item in ipairs(items) do lines[#lines+1]=i..". "..item end
 lines[#lines+1]="Encounter mechanics, drops and routes are not verified Forever-specific data."
 return table.concat(lines,"\n")
end

-- Published suggested bands are planning cues, not admission requirements.
local launchDungeons={
 {"Hall of Thanes",13,18,"Dun Morogh"},
 {"Ruins of Lordaeron",15,20,"Tirisfal Glades"},
 {"Excavation Site",24,29,"Wetlands"},
 {"City of Dalaran",28,33,"Alterac Mountains"},
 {"The Drowned City",35,40,"Stranglethorn Vale"},
 {"Krol’dok Stronghold",40,45,"Riverglades"},
 {"Alcaz Prison",48,53,"Dustwallow Marsh"},
 {"Blackmaw Hold",55,60,"Azshara"},
 {"Shaper’s Terrace",58,60,"Un’Goro Crater"},
}
function P.LaunchReference(level)
 local lines={"NEW FOREVER DUNGEONS / BLIZZARD LAUNCH REFERENCE"}
 local matched=false
 for _,entry in ipairs(launchDungeons) do
  local inBand=type(level)=="number" and level>=entry[2] and level<=entry[3]
  if inBand then matched=true end
  lines[#lines+1]=string.format("%s%s  |  %d–%d  |  %s",
   inBand and "[YOUR LEVEL]  " or "",entry[1],entry[2],entry[3],entry[4])
 end
 if type(level)=="number" and not matched then
  lines[#lines+1]="Your level is outside the listed bands for these nine new dungeons. Check other dungeons in the client."
 end
 lines[#lines+1]="Published five-player dungeon ranges. Confirm entry requirements, encounters and loot in game. The historical loot catalog below is a separate reference."
 lines[#lines+1]="Source: https://news.blizzard.com/en-us/article/24301455/explore-the-new-dungeons-of-world-of-warcraft-forever"
 return table.concat(lines,"\n")
end
