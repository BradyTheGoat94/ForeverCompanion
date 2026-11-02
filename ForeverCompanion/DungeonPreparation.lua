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
