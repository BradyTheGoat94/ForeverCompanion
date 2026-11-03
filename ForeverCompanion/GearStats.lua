-- Source-reviewed Forever beta PvE references, not measured character stat weights.
-- Each profile is an original short summary of the cited author's recommendations.
local G={profiles={},reviewed="2026-11-02"}
ForeverCompanionGearStats=G
local base="https://www.wowhead.com/forever/guide/classes/"
local function add(class,spec,slug,order,note,role)
 G.profiles[class]=G.profiles[class] or {}
 G.profiles[class][spec]={order=order,note=note,source=base..class:lower().."/"..slug.."/stat-priority-pve-"..(role or "dps"),provider="Wowhead Forever",scope="Level 60 PvE beta estimate"}
end
add("WARRIOR","Arms","arms",{"Hit before its target","Expertise before its target","Critical Strike","Strength","Agility","Haste","Additional Hit"},"Compare complete items: a large Agility gain can outweigh a small Strength gain. This is a beta ordering, not a per-point conversion.")
add("WARRIOR","Fury","fury",{"Weapon Skill","Hit before its target","Critical Strike","Strength","Agility","Stamina"},"The source's ordered list and its explanation give different Hit targets. No numeric cap is asserted here; verify the current character-sheet tooltip and weapon skill.")
G.profiles.WARRIOR.Protection={order={"Survival: Stamina","Armor","Agility","Avoidance","Defense"},secondary="Threat: Expertise > Hit before its target > Agility > Strength > Stamina",note="Maintain enough threat to hold targets while choosing survival for the incoming damage. A defensive priority and an offensive priority answer different questions.",source="https://www.icy-veins.com/wow-forever/protection-warrior-tank-pve-stat-priority",provider="Icy Veins / Abide",scope="Level 60 PvE beta reference"}
add("PALADIN","Holy","holy",{"Healing Power","Intellect","Critical Strike","Spirit"},"Healing throughput and mana both matter. Spell Hit is not needed to make healing spells land.","healer")
add("PALADIN","Protection","protection",{"Balanced: Stamina","Spell Power","Hit before its melee target","Defense before its target","Armor","Expertise before its dodge target","Agility / Block Chance (lower priorities)"},"This is only the leading part of the source's BALANCED list. Defensive and offensive sets differ; do not trade away necessary survival for threat.","tank")
add("PALADIN","Retribution","retribution",{"Weapon Skill","Weapon DPS and speed","Hit before its target","Expertise before its target","Spell Damage","Intellect","Strength / Attack Power","Agility / Critical Strike"},"Weapon speed and spell-stat value depend on your seal and talents. Compare the weapon first, then the whole stat package; do not apply a retail Strength-only rule.")
for _,spec in ipairs({"Beast Mastery","Marksmanship"}) do
 add("HUNTER",spec,spec=="Beast Mastery" and "beast-mastery" or "marksmanship",{"Hit before its target","Agility","Critical Strike","Intellect","Ranged Attack Power","Spirit","Stamina"},"The source values Intellect with Careful Aim. Confirm that talent and your current Hit target; the rank order is a beta estimate.")
end
add("HUNTER","Survival","survival",{"Hit before its target","Agility","Critical Strike","Strength","Attack Power","Intellect","Spirit","Stamina"},"This is the source's Survival reference, not a copy of the ranged hunter list. Check your melee/ranged build and talents before choosing an item.")
for _,spec in ipairs({"Assassination","Combat","Subtlety"}) do
 add("ROGUE",spec,spec:lower(),{"Hit before the ability target","Expertise before the dodge target","Weapon Skill","Hit toward the poison target","Agility","Critical Strike / Haste","Strength","Attack Power"},"The source distinguishes ability, poison and dual-wield auto-attack Hit. Its prose treats Crit and Haste as close. Weapon quality also matters; do not chase one cap without comparing the full item.")
end
add("PRIEST","Discipline","discipline",{"Healing Power","Intellect","Spirit","Critical Strike","Spell Damage","Stamina"},"Balance healing output against mana for the expected fight duration. Spell Damage is lower-priority offensive flexibility, not a reason to sacrifice essential healing.","healer")
add("PRIEST","Holy","holy",{"Healing Power","Intellect","Mana per 5 seconds","Spirit","Critical Strike","Stamina"},"Mana sustain matters during long encounters. Healing spells do not need Spell Hit; avoid spending your healing budget on it.","healer")
add("PRIEST","Shadow","shadow",{"Hit before its target","Critical Strike","Spell Damage / Shadow Damage","Intellect","Spirit","Stamina"},"The beta reference values Crit with Shadowform's critical-damage interaction. Missing an important long-cooldown spell costs uptime; account for talent Hit bonuses.")
add("SHAMAN","Elemental","elemental",{"Spell Piercing","Haste / Cast Speed","Hit before its target","Spell Damage","Critical Strike","Nature / Fire Damage","Intellect","Spirit"},"This is Lucenia's approximate ordering, not a measured universal stat weight. Keep enough mana to sustain casts. Other guides order these stats differently; recheck after launch.")
add("SHAMAN","Enhancement","enhancement",{"Hit before its melee target","Expertise before its dodge target","Strength / Intellect","Spell Piercing","Haste","Critical Strike","Spell Damage","Agility"},"Melee Hit does not cover every spell miss. The source values both Strength and Intellect and warns against over-investing in Hit at the expense of the rest of the build.")
add("SHAMAN","Restoration","restoration",{"Healing Power","Critical Strike","Haste / Cast Speed","Intellect","Spirit","Mana per 5 seconds"},"Balance healing output and mana sustain for your encounter. The source's offensive leveling stats are not included in this healing order.","healer")
for _,spec in ipairs({"Arcane","Fire"}) do
 add("MAGE",spec,spec:lower(),{"Hit before its target","Spell Damage / matching-school damage","Critical Strike","Spell Piercing","Haste","Intellect","Spirit","Stamina"},spec=="Arcane" and "Arcane also uses mana-dependent interactions. Do not dismiss Intellect or Spirit merely because they appear below damage stats." or "The source values Crit with Ignite. Item availability and the value of Spell Piercing remain beta-dependent.")
end
add("MAGE","Frost","frost",{"Hit after accounting for talents","Critical Strike","Spell Damage / Frost and Arcane Damage","Intellect","Spirit","Stamina"},"The source's Hit recommendation assumes talent bonuses. It is not a gear-only requirement for every build; inspect your current talents before adding Hit.")
add("WARLOCK","Affliction","affliction",{"Spell Power / Shadow Damage","Critical Strike","Hit before its talent-adjusted target","Haste","Spell Pierce","Intellect","Spirit"},"The author derives this estimate from Affliction raid simulation builds. It has not been benchmarked by this addon; other guides place Hit first. Suppression changes the gear requirement.")
add("WARLOCK","Demonology","demonology",{"Spell Power / build-matching school damage","Hit before its talent-adjusted target","Critical Strike","Haste","Spell Pierce","Intellect","Spirit"},"The reference covers Fire/Imp and Shadow/Sayaad raid builds. School damage is build-specific. The author gives Hit added value through demon scaling; verify the live implementation.")
add("WARLOCK","Destruction","destruction",{"Spell Power / Fire Damage","Critical Strike","Hit before its talent-adjusted target","Haste","Spell Pierce","Intellect","Spirit"},"The source assumes an Incinerate/Sayaad raid build and finds Crit and Hit close. School-specific damage is not interchangeable with general Spell Power. Check Suppression and your actual build.")
add("DRUID","Balance","balance",{"Hit before its target","Spell Damage","Spell Penetration / Piercing","Critical Strike","Haste","Intellect","Spirit","Stamina"},"The source uses Spell Penetration terminology. Confirm the current client tooltip and talents; this is a beta raid reference rather than a leveling shopping rule.")
add("DRUID","Feral","feral",{"Critical Strike percentage","Hit percentage before its target","Dodge/parry reduction percentage","Haste percentage","Weapon DPS","Agility / Strength","Attack Power"},"The source compares PERCENTAGE increments before raw stat points; these are not equivalent item budgets. This is a Cat damage reference. A Bear survival set has different priorities.")
add("DRUID","Restoration","restoration",{"Healing Power","Critical Strike","Spell Haste","Spirit","Intellect","Mana per 5 seconds","Stamina"},"This reference emphasizes throughput while retaining mana sustain. A large mana-stat gain can justify a small healing-stat loss in a long encounter.","healer")
add("DRUID","Guardian / Bear","feral",{"Survival: Stamina","Defense before its target","Armor","Agility","Avoidance","Additional Defense"},"Bear tank gearing reference only. Guardian / Bear remains an unconfirmed planner label, not a claim that Forever has a separate Guardian talent specialization.","tank")
G.profiles.DRUID["Guardian / Bear"].secondary="Threat: Hit > dodge/parry reduction > Haste > Crit > Weapon DPS; balance against survival."
-- Reported targets retain source/build assumptions. Conflicting beta values are
-- deliberately not converted into a universal required amount on gear.
for class,profiles in pairs(G.profiles) do
 for spec,profile in pairs(profiles) do
  if class=="MAGE" and spec=="Frost" then
   profile.targets="Source assumes 5-6% talent Hit and lists 11-12% additional Hit. Verify the selected talent ranks and target level first."
  elseif class=="MAGE" or (class=="DRUID" and spec=="Balance") or (class=="PRIEST" and spec=="Shadow") or (class=="SHAMAN" and spec=="Elemental") then
   profile.targets="Source lists a 17% spell Hit raid reference. Talents and target level change how much must come from gear; check the current client tooltip."
  elseif class=="WARLOCK" then
   profile.targets="Source uses a 17% spell Hit reference reduced by Suppression: 12% from gear/buffs with all five points. Confirm the actual talent and build."
  elseif class=="ROGUE" then
   profile.targets="Source lists 8% ability Hit, 6.5% dodge reduction, 308 Weapon Skill and 17% poison Hit for its raid reference. These are separate checks; talent bonuses and weapon skill affect the comparison."
  elseif class=="WARRIOR" and spec=="Arms" then
   profile.targets="Source lists 8% special-attack Hit and 6.5% dodge reduction for its boss reference. Removing dodges does not remove frontal parries."
  elseif class=="WARRIOR" and spec=="Protection" then
   profile.targets="Source lists 8% Hit with weapon/shield, 6.5% dodge reduction and 14% parry reduction versus level-63 bosses. Survival and threat still need balancing."
  elseif class=="PALADIN" and spec=="Protection" then
   profile.targets="Source separates 8% melee Hit, 17% spell Hit and 440 total Defense in its raid reference. Talents reduce gear requirements. These numbers alone do not establish tank readiness."
  elseif class=="DRUID" and spec=="Feral" then
   profile.targets="Source lists 8% Hit and 6.5% dodge reduction as damage-reference targets; this is not a frontal parry cap. Frontal tanking has different needs; use the Bear reference for survival."
  elseif spec=="Guardian / Bear" then
   profile.targets="Source discusses 440 total Defense in its defensive reference. This is not a universal readiness requirement or proof of a separate Guardian spec."
  end
 end
end
function G.Get(class,spec)
 return G.profiles[class] and G.profiles[class][spec]
end
function G.Lines(class)
 local choice=ForeverCompanionSpecPlanner.Get(class)
 local spec=choice and choice[1]
 local profile=G.Get(class,spec)
 if not profile then return {"STAT PRIORITY / No source-reviewed profile for this selection. No ranking is inferred."} end
 local lines={"STAT PRIORITY / "..spec,"SOURCE-REVIEWED BETA THEORYCRAFT / NOT LIVE-TESTED",profile.scope..". Reviewed "..G.reviewed.."; not a PvP or leveling prescription."}
 local ranks={}
 for i,stat in ipairs(profile.order) do ranks[#ranks+1]=string.format("%02d  %s",i,stat) end
 lines[#lines+1]=table.concat(ranks,"\n")
 if profile.secondary then lines[#lines+1]=profile.secondary end
 if profile.targets then lines[#lines+1]="REPORTED TARGETS / BETA: "..profile.targets end
 lines[#lines+1]="HOW TO USE: "..profile.note
 lines[#lines+1]="CAPS & ITEM COMPARISONS: Check enemy level, talents and the current character-sheet tooltip. Rank order is not a numerical stat weight; one point of one stat is not equivalent to one percent of another. No live stats are scanned here."
 lines[#lines+1]="BIS & GEAR TARGETS / A complete, client-verified BiS set is not established in this addon. Open the loot catalog to save source-attributed targets by slot and mark acquisitions manually. Saved targets are not automatic upgrades."
 lines[#lines+1]="Source: "..profile.provider.."\n"..profile.source
 return lines
end
