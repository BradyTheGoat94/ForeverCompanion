-- Class-specific leveling practice notes. General guidance, not verified Forever unlock data.
ForeverCompanionLevelingCurriculum={}
local C=ForeverCompanionLevelingCurriculum
C.classes={
 WARRIOR={
  [1]="Upgrade your main weapon before chasing minor armor gains; check the weapon skill requirement.",
  [2]="Practice safe single-target pulls and reserve rage when a defensive response may be needed.",
  [3]="At each trainer visit, check stance and interrupt access; quest-gated abilities require their quest.",
  [4]="For group tanking, carry a shield and establish threat before allies commit to burst.",
  [5]="At higher levels, practice target swaps, interrupts and defensive timing before dungeon pulls.",
 },
 PALADIN={
  [1]="Choose a role and carry suitable weapon or healing equipment; check active blessings.",
  [2]="Practice judging whether a seal, heal or damage action is worth its mana cost.",
  [3]="At trainer visits, review ranks, blessings and any available cleanse or defensive tools.",
  [4]="For dungeon healing, conserve mana between pulls; for tanking, check threat tools and positioning.",
  [5]="Before endgame groups, confirm role-specific talents and emergency utility in the client.",
 },
 HUNTER={
  [1]="Check pet behavior and ranged weapon before travel; avoid accidental pet pulls.",
  [2]="Practice pulling with enough space to kite and safely recover your pet.",
  [3]="At trainer visits, inspect pet skills, traps and ranged ability ranks.",
  [4]="In dungeons, set pet control deliberately and coordinate trap targets.",
  [5]="Before harder content, verify pet family abilities, ranged supplies and crowd control.",
 },
 ROGUE={
  [1]="Keep weapons current and learn how energy recovery affects short fights.",
  [2]="Practice opening from safe positions and retaining energy for an emergency control.",
  [3]="Review poisons, stealth, interrupts and finishing options at each trainer visit.",
  [4]="In groups, prioritize interrupts and avoid overtaking tank threat.",
  [5]="Practice target control and disengagement without assuming any fixed talent build.",
 },
 PRIEST={
  [1]="Keep your wand or available low-cost damage option current; plan recovery time.",
  [2]="Practice maintaining enough mana for an emergency heal during solo pulls.",
  [3]="Review healing, shielding, dispel and damage ranks at each trainer visit.",
  [4]="In groups, monitor dangerous incoming damage and communicate dispel assignments.",
  [5]="Before endgame, prepare healing and damage equipment separately where needed.",
 },
 SHAMAN={
  [1]="Review weapon and shield options for your intended role; track mana use.",
  [2]="Practice placing utility where you will actually fight rather than immediately moving away.",
  [3]="At trainers, check totem access, interrupt options and healing ranks.",
  [4]="For dungeons, coordinate buffs, interrupts and backup healing responsibilities.",
  [5]="At higher levels, test role-specific mana sustain and utility against actual encounters.",
 },
 MAGE={
  [1]="Use distance and safe pulls; carry mana recovery options.",
  [2]="Practice crowd control before damage, and avoid breaking controlled targets.",
  [3]="Review new spell ranks, shields, teleports and control tools at trainer visits.",
  [4]="For dungeons, communicate crowd-control targets and avoid unsafe area damage.",
  [5]="Before endgame, practice threat control and defensive cooldown timing.",
 },
 WARLOCK={
  [1]="Choose a pet for the encounter and avoid pulling extra enemies.",
  [2]="Practice maintaining damage-over-time effects without overcommitting mana or health.",
  [3]="At trainers, inspect pet abilities, control and available utility.",
  [4]="In dungeons, prepare summons and support items when available; control pet aggression.",
  [5]="At higher levels, plan threat management and crowd control alongside damage.",
 },
 DRUID={
  [1]="Choose your intended role and confirm appropriate form and equipment.",
  [2]="Practice switching between mobility, damage and recovery without overpulling.",
  [3]="Review form quests, healing ranks and utility at trainer visits.",
  [4]="In dungeons, verify the assigned role and bring appropriate gear for it.",
  [5]="At higher levels, plan role-specific utility, defensives and resource recovery.",
 },
} 
C.bands={{1,10,"Foundation"},{11,20,"Core habits"},{21,30,"Trainer and utility"},{31,45,"Dungeon readiness"},{46,60,"Advanced preparation"}}
function C.Stage(level)
 level=tonumber(level) or 1
 for i,band in ipairs(C.bands) do if level>=band[1] and level<=band[2] then return i,band end end
 return level>60 and 5 or 1,C.bands[level>60 and 5 or 1]
end
function C.Format(class,level)
 local notes=C.classes[class]
 if not notes then return "LEVELING PRACTICE: Class guide not yet available." end
 local stage,band=C.Stage(level)
 local lines={"LEVELING PRACTICE - "..band[3].." (Lv "..band[1].."-"..band[2]..")",notes[stage],"NEXT STAGE: "..(stage<5 and notes[stage+1] or "Review actual character skills and endgame role requirements."),"REFERENCE: General practice advice; confirm unlocks and class changes in the live Forever client."}
 return table.concat(lines,"\n")
end
