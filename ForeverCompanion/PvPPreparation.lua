-- PvP preparation guidance only; no opponent tracking or protected actions.
ForeverCompanionPvPPreparation={}
local P=ForeverCompanionPvPPreparation
P.classes={
 WARRIOR={"Check stance and available mobility before committing to a fight.","Save an interrupt or control option for dangerous enemy casts.","Plan defensive cooldowns before chasing a target out of healer range."},
 PALADIN={"Confirm your selected blessing and defensive utility.","Coordinate protection and dispel responsibilities with allies.","Avoid spending every defensive option during the first enemy burst."},
 HUNTER={"Check pet control and available traps before engagement.","Keep safe distance and watch terrain that blocks line of sight.","Save an escape or control response when an opponent closes distance."},
 ROGUE={"Choose a safe opener and preserve energy for control.","Watch diminishing-return interactions where the client supports them.","Plan an escape route before committing to a long fight."},
 PRIEST={"Protect positioning and maintain emergency healing resources.","Coordinate dispels and crowd control with teammates.","Prepare a defensive response before focusing on damage."},
 SHAMAN={"Check totems or equivalent utility actually available in your client.","Coordinate interrupts and emergency healing responsibilities.","Use terrain to avoid unnecessary exposure while supporting allies."},
 MAGE={"Check control, defensive and movement options in your spellbook.","Avoid breaking crowd control with incidental damage.","Plan line-of-sight and escape paths before using major cooldowns."},
 WARLOCK={"Confirm pet choice and control abilities before combat.","Plan pressure and crowd control without exposing yourself unnecessarily.","Keep a defensive option available when an enemy closes distance."},
 DRUID={"Confirm form-specific utility and role before engagement.","Use mobility and terrain to protect yourself and teammates.","Coordinate control and emergency support without overcommitting."}
}
function P.Format(class)
 local notes=P.classes[class]
 if not notes then return "PVP FIELD NOTES: No curated class guidance." end
 local lines={"PVP FIELD NOTES - "..class}
 for i,n in ipairs(notes) do lines[#lines+1]=i..". "..n end
 lines[#lines+1]="General practice only; confirm spells, talents and PvP rules in WoW Forever."
 return table.concat(lines,"\n")
end
