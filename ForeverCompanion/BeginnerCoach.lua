-- Beginner coaching reference. Read-only data: never performs protected actions.
-- All recommendations are conditional and illustrative until checked in the Forever client.
ForeverCompanionBeginnerCoach = {
  WARRIOR={resource="Rage",first="Keep Battle Shout active if trained.",loop="Open safely, build rage with attacks, and spend only when enough rage remains for interrupts or defense.",recover="If rage is low, wait for attacks rather than repeatedly pressing an unaffordable ability.",check="Confirm stance and whether you are tanking before following damage advice."},
  PALADIN={resource="Mana",first="Choose a trained Blessing and Seal appropriate to your role.",loop="Attack while managing mana; use Judgement when its effect matters, and check whether your Seal must be reapplied.",recover="If mana is low, favor safe attacks and conserve enough for emergency healing.",check="Verify Forever-specific Seal and Judgement behavior in your spellbook and combat log."},
  HUNTER={resource="Mana and pet",first="Check pet control, ranged weapon, and ammunition requirements.",loop="Send the pet only to the intended target; maintain ranged attacks and use trained shots without unnecessary clipping.",recover="If enemies reach melee range, reposition and control the pet before continuing.",check="Verify shared cooldown behavior for Aimed Shot and Multi-Shot."},
  ROGUE={resource="Energy and combo points",first="Apply an appropriate trained poison if available.",loop="Build combo points with a trained builder; maintain Slice and Dice on sufficiently long fights and spend remaining points appropriately.",recover="When energy is low, allow it to regenerate; save enough for an urgent interrupt.",check="Do not recommend a finisher without sufficient combo points."},
  PRIEST={resource="Mana",first="Keep trained self-buffs active before engaging.",loop="Apply damage-over-time effects to durable targets; cast trained filler spells and use a wand when mana conservation matters.",recover="Heal or shield when survival requires it; dungeon healers prioritize the group.",check="Verify Shadow talent availability and healing assignment."},
  SHAMAN={resource="Mana and totems",first="Choose an appropriate weapon imbue and trained totems.",loop="Use trained melee or spell attacks for your specialization; weave shocks only when mana allows.",recover="Preserve enough mana for emergency healing or interrupts.",check="Verify which totems and shock ranks are actually learned."},
  MAGE={resource="Mana",first="Keep Arcane Intellect active if trained.",loop="Use a trained primary spell suited to your spec; control enemies with available slows and roots before resuming damage.",recover="When pressured, create distance and recover mana rather than assuming uninterrupted casts.",check="Do not assume retail Arcane Charges or modern Arcane Barrage exist in Forever."},
  WARLOCK={resource="Health, mana and pet",first="Summon and control an appropriate pet.",loop="Apply trained damage-over-time effects to targets that will live long enough; fill with direct casts or wand attacks.",recover="Use Life Tap only when health permits and recover safely.",check="Verify pet spells, curses, and learned damage effects."},
  DRUID={resource="Mana, energy or rage by form",first="Select a form appropriate to your trained abilities and role.",loop="In Cat Form build and spend combo points; in caster form use trained spells; in Bear Form prioritize survival and threat.",recover="Change form or heal only when safe; avoid suggesting spells unusable in the current form.",check="Verify form unlocks, talents and resources before displaying a priority."}
}
function ForeverCompanionGetBeginnerCoach(classToken)
  if type(classToken) ~= "string" then return nil end
  return ForeverCompanionBeginnerCoach[classToken]
end

-- Specialization-specific beginner decision prompts. These are coaching cues,
-- not verified spell rotations, talent builds, or one-button macros.
ForeverCompanionSpecCoach = {
 WARRIOR={Arms={"Keep weapon attacks connected and spend rage deliberately.","Check whether your target is in execute range."},Fury={"Maintain melee uptime without wasting rage.","Keep an interrupt or defensive available for danger."},Protection={"Face enemies away from allies and maintain threat.","Use mitigation before predictable heavy damage."}},
 PALADIN={Holy={"Prioritize injured allies over personal damage.","Avoid draining all mana on unnecessary healing."},Protection={"Establish threat before the group begins area damage.","Keep a defensive response ready for large pulls."},Retribution={"Maintain an appropriate trained Seal.","Check Judgement interactions and mana before repeating."}},
 HUNTER={["Beast Mastery"]={"Keep the pet alive and attacking the intended target.","Avoid accidental pet pulls."},Marksmanship={"Maintain safe ranged positioning.","Avoid interrupting valuable ranged attacks with movement."},Survival={"Plan traps and control before a difficult pull.","Use distance and pet control to survive."}},
 ROGUE={Assassination={"Maintain appropriate poisons and position safely.","Spend combo points before switching targets."},Combat={"Keep consistent melee uptime.","Pool energy when an important ability is nearly ready."},Subtlety={"Plan your opening and control window.","Save energy for a critical interrupt or escape."}},
 PRIEST={Discipline={"Prevent dangerous damage when your trained tools permit.","Keep mana for emergency healing."},Holy={"Heal the most threatened ally first.","Avoid overhealing when mana is scarce."},Shadow={"Apply damage-over-time spells to durable targets.","Watch mana and threat during longer fights."}},
 SHAMAN={Elemental={"Keep casting safely while maintaining useful totems.","Reserve mana for control or emergency healing."},Enhancement={"Keep melee uptime and an appropriate weapon imbue.","Use shocks without exhausting emergency mana."},Restoration={"Keep allies stable and position to avoid interrupts.","Choose useful totems without neglecting healing."}},
 MAGE={Arcane={"Check the actual Forever spellbook before planning burst.","Manage mana and avoid assuming retail-era Arcane Charges."},Fire={"Keep a safe casting position.","Avoid committing long casts when movement is required."},Frost={"Use slows and roots to create safe casting windows.","Control dangerous enemies before resuming damage."}},
 WARLOCK={Affliction={"Keep damage-over-time effects on durable targets.","Do not overapply effects to enemies that will die immediately."},Demonology={"Keep your pet alive and correctly controlled.","Check pet abilities before relying on their utility."},Destruction={"Plan direct casts around safe uptime.","Watch threat and reserve defensive tools."}},
 DRUID={Balance={"Stay in the correct form for your spells.","Manage mana during sustained casting."},Feral={"Check whether Cat or Bear form matches your role.","Build and spend resources without losing positioning."},Restoration={"Prioritize threatened allies and mana efficiency.","Use trained healing-over-time spells when appropriate."},["Guardian / Bear"]={"Check whether this spec is actually supported in Forever.","If tanking in Bear Form, prioritize threat and survival."}}
}
function ForeverCompanionSpecCoachLines(classToken)
 local result={}
 local planner=ForeverCompanionSpecPlanner
 local selected=type(planner)=="table" and type(planner.Get)=="function" and planner.Get(classToken)
 local name=type(selected)=="table" and selected[1]
 local class=ForeverCompanionSpecCoach[classToken]
 local notes=type(class)=="table" and class[name]
 if not notes then return result end
 result[#result+1]="SPEC PRACTICE: "..name.." (ILLUSTRATIVE)"
 for i,note in ipairs(notes) do result[#result+1]=i..". "..note end
 result[#result+1]="Always check trained spells, role, and actual Forever talents."
 return result
end

-- Guide status is explicitly tracked per information source, not inferred from
-- a successful addon build or from a class having a text entry.
ForeverCompanionGuideEvidence={
  reference="Forever client-data snapshot 1.60.1.70707; partial Mage/Warrior entries",
  classes={"WARRIOR","PALADIN","HUNTER","ROGUE","PRIEST","SHAMAN","MAGE","WARLOCK","DRUID"},
  evidence="Unverified gameplay guidance",
  clientTested=false,
  combatLogValidated=false
}
function ForeverCompanionGuideEvidenceLines(classToken)
 local result={"GUIDE EVIDENCE / SAFETY"}
 local evidence=ForeverCompanionGuideEvidence
 local abilities=ForeverCompanionVerifiedAbilities
 local entries=type(abilities)=="table" and type(abilities.entries)=="table" and abilities.entries[classToken]
 local count=type(entries)=="table" and #entries or 0
 result[#result+1]="Curated client-data spell entries: "..count.." (not proof they are trained)."
 result[#result+1]="Specialization coaching: illustrative; not benchmark validated."
 result[#result+1]="Live Forever spellbook and combat-log validation: pending."
 result[#result+1]="If a suggested ability is missing, skip it and check your trainer or talents."
 return result
end
