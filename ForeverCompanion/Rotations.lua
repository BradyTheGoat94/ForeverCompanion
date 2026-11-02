-- Rotations are illustrative Classic-era priorities, NOT verified Forever-specific optimal sequences.
-- Icon references use client textures; missing icons should not block text rendering.
ForeverCompanionRotations = {
 WARRIOR={leveling={"Maintain Battle Shout when useful","Charge when safe to engage","Use primary rage spender appropriate to talents","Use defensive abilities when threatened"},dungeon={"Maintain assigned stance and threat if tanking","Prioritize dangerous casts and control","Spend rage without starving defensive tools"},boss={"Maintain useful self-buffs","Manage rage and threat","Use talent-specific abilities when available"},aoe={"Avoid pulling more than the group can control","Use available multi-target abilities when safe"},pvp={"Control engagement range","Manage rage and interrupts","Reserve mobility and defensive tools"}},
 PALADIN={leveling={"Maintain an appropriate blessing","Choose a suitable seal","Judge when beneficial","Manage mana and self-healing"},dungeon={"Maintain assigned blessings","Tank: establish threat; healer: conserve mana","Use emergency utility as needed"},boss={"Keep relevant buffs active","Follow talent-specific seal and judgement priorities"},aoe={"Manage mana and threat","Use safe area abilities when supported"},pvp={"Maintain positioning and blessings","Use crowd control and emergency support"}},
 HUNTER={leveling={"Keep pet controlled and healthy","Open at range","Use efficient ranged attacks","Manage mana and ammunition if required"},dungeon={"Keep pet on controlled targets","Use traps for assigned crowd control","Avoid breaking crowd control"},boss={"Maintain ranged uptime","Use specialization abilities as available","Manage pet positioning"},aoe={"Keep pet from accidental pulls","Use safe multi-target attacks"},pvp={"Create distance","Control pet and target","Use traps and defensive mobility"}},
 ROGUE={leveling={"Open from stealth when useful","Generate combo points","Use a suitable finishing move","Manage energy and cooldowns"},dungeon={"Focus assigned target","Interrupt dangerous casts","Avoid pulling threat"},boss={"Maintain important finishers when appropriate","Build and spend combo points efficiently","Use cooldowns around encounter needs"},aoe={"Control targets before cleaving","Avoid uncontrolled pulls"},pvp={"Plan opener","Manage control diminishing returns where applicable","Reserve energy for interrupts and escapes"}},
 PRIEST={leveling={"Maintain useful buffs","Use mana-efficient damage","Control dangerous targets","Recover mana safely"},dungeon={"Heal high-risk targets first","Dispel when required","Manage mana between pulls"},boss={"Healer: prioritize survival and dispels","Damage: maintain applicable effects and mana"},aoe={"Avoid drawing excess threat","Use control and healing as needed"},pvp={"Protect teammates","Use dispels and crowd control","Manage defensive cooldowns"}},
 SHAMAN={leveling={"Choose suitable weapon and buffs","Place useful totems where supported","Use mana-efficient attacks","Heal or retreat when needed"},dungeon={"Maintain group-appropriate totems","Interrupt dangerous casts","Heal or damage based on role"},boss={"Keep useful totems active","Use talent-appropriate abilities","Manage mana"},aoe={"Use controlled area damage where available","Keep interrupts ready"},pvp={"Coordinate totems and utility","Interrupt and kite","Preserve defensive resources"}},
 MAGE={leveling={"Keep protective buffs active","Open with efficient ranged damage","Slow or control dangerous enemies","Manage mana and food"},dungeon={"Polymorph assigned targets","Avoid breaking crowd control","Use controlled area damage"},boss={"Maintain appropriate specialization damage spells","Use cooldowns strategically","Manage mana"},aoe={"Group enemies safely","Apply slows and area damage","Escape before enemies reach you"},pvp={"Control range with slows and roots","Use defensive cooldowns","Time burst around enemy defenses"}},
 WARLOCK={leveling={"Select an appropriate pet","Maintain useful damage-over-time effects","Use efficient filler spells","Balance health and mana safely"},dungeon={"Keep pet from accidental pulls","Coordinate crowd control and Healthstones","Manage threat"},boss={"Maintain useful damage-over-time effects","Use specialization filler and cooldowns","Manage pet and resources"},aoe={"Control pet positioning","Apply multi-target damage safely"},pvp={"Maintain pressure with effects","Coordinate fear and pet utility","Use defensives proactively"}},
 DRUID={leveling={"Select form suited to current fight","Maintain appropriate buffs","Use form-specific resources efficiently","Heal between pulls when useful"},dungeon={"Tank: control threat and positioning","Healer: manage mana and dispels","Damage: maintain role-specific uptime"},boss={"Use specialization-specific form and abilities","Manage resources and cooldowns"},aoe={"Choose safe multi-target tools for your role","Avoid excessive threat"},pvp={"Shift forms for mobility and utility","Use control and healing","Manage defensive cooldowns"}}
}

-- Optional illustrative ability icons. A missing texture should fall back to readable text.
ForeverCompanionRotationIcons = {
 WARRIOR={"Interface\\Icons\\Ability_Warrior_BattleShout","Interface\\Icons\\Ability_Warrior_Charge"},
 PALADIN={"Interface\\Icons\\Spell_Holy_SealOfMight","Interface\\Icons\\Spell_Holy_HolyBolt"},
 HUNTER={"Interface\\Icons\\Ability_Hunter_BeastTaming","Interface\\Icons\\Ability_Hunter_AspectOfTheHawk"},
 ROGUE={"Interface\\Icons\\Ability_Stealth","Interface\\Icons\\Ability_Rogue_SliceDice"},
 PRIEST={"Interface\\Icons\\Spell_Holy_PowerWordShield","Interface\\Icons\\Spell_Holy_Renew"},
 SHAMAN={"Interface\\Icons\\Spell_Nature_Lightning","Interface\\Icons\\Spell_Nature_HealingWaveGreater"},
 MAGE={"Interface\\Icons\\Spell_Frost_FrostBolt02","Interface\\Icons\\Spell_Frost_FrostNova"},
 WARLOCK={"Interface\\Icons\\Spell_Shadow_CurseOfSargeras","Interface\\Icons\\Spell_Shadow_DeathCoil"},
 DRUID={"Interface\\Icons\\Ability_Druid_Maul","Interface\\Icons\\Spell_Nature_Rejuvenation"}
}

-- A guide presentation contract for a future clickable ability-card interface.
-- Data is explanatory, not a recommendation to automate gameplay.
ForeverCompanionRotationPresentation = {
  contexts = {
    leveling={title="Solo leveling",description="Safe, resource-conscious priority while questing."},
    dungeon={title="Dungeon party",description="Threat, control and assigned group role come first."},
    boss={title="Single-target boss",description="Sustained damage or role-specific survival priorities."},
    aoe={title="Multiple enemies",description="Use multi-target tools only when the pull is controlled."},
    pvp={title="Player versus player",description="React to opponents; there is no guaranteed fixed sequence."}
  },
  notice="Illustrative Classic-era guidance. Confirm abilities, talents and mechanics in the WoW Forever client."
}

-- Specialization-aware study notes. These are editorial prompts, not live-verified
-- WoW Forever spell availability or an automated combat sequence.
ForeverCompanionSpecGuidance = {
 WARRIOR={
  {name="Arms",focus="Two-handed weapon pacing, rage budgeting and stance awareness",levels="Check trained abilities and talent unlocks before adopting a priority",solo="Use safe openers; keep enough rage for interrupts and defensive responses",group="Confirm whether you are assigned to damage or tank; avoid overtaking tank threat"},
  {name="Fury",focus="Resource generation, weapon choices and sustained melee uptime",levels="Verify dual-wield access and current talent investment",solo="Avoid spending every resource when a dangerous pull is imminent",group="Watch threat and positioning during sustained damage"},
  {name="Protection",focus="Threat, mitigation and pull control",levels="Prioritize available defensive and threat tools rather than assuming endgame talents",solo="Trade damage for safer multi-enemy pulls when needed",group="Establish threat, face enemies away and reserve emergency mitigation"}},
 PALADIN={
  {name="Holy",focus="Efficient healing, blessings and emergency utility",levels="Verify trained healing ranks and mana costs",solo="Use a conservative damage approach between healing needs",group="Prioritize survival, cleansing and mana reserves"},
  {name="Protection",focus="Blessings, threat and mitigation",levels="Confirm available seals, judgements and defensive talents",solo="Choose controlled pulls and maintain mana",group="Coordinate tank role and avoid losing threat"},
  {name="Retribution",focus="Weapon pacing, seals and judgements",levels="Check seal and judgement availability by level",solo="Balance damage with self-healing",group="Maintain assigned blessing and manage threat"}},
 HUNTER={
  {name="Beast Mastery",focus="Pet control, positioning and sustained damage",levels="Verify pet abilities and training status",solo="Keep pet healthy and avoid accidental extra pulls",group="Respect crowd control and pet positioning"},
  {name="Marksmanship",focus="Ranged uptime and careful resource use",levels="Confirm trained shot ranks and ammunition requirements",solo="Maintain safe distance",group="Avoid threat spikes and coordinate target focus"},
  {name="Survival",focus="Traps, control and defensive spacing",levels="Check trap and talent unlocks",solo="Use crowd control before dangerous engagements",group="Coordinate traps with party assignments"}},
 ROGUE={
  {name="Assassination",focus="Combo-point planning and finishers",levels="Verify poison and finisher availability",solo="Choose safe stealth openers",group="Save resources for interrupts"},
  {name="Combat",focus="Sustained melee uptime and energy management",levels="Check weapon specialization and talent unlocks",solo="Avoid energy starvation during dangerous pulls",group="Stay behind targets when safe"},
  {name="Subtlety",focus="Stealth, control and repositioning",levels="Confirm available openers and control abilities",solo="Use resets and escape options deliberately",group="Coordinate crowd control without breaking it"}},
 PRIEST={
  {name="Discipline",focus="Mana efficiency, protection and utility",levels="Verify shield and healing spell ranks",solo="Balance damage with recovery",group="Anticipate incoming damage and conserve mana"},
  {name="Holy",focus="Healing throughput and efficient spell selection",levels="Check trained healing spells and talents",solo="Plan safe damage and recovery",group="Prioritize survival and dispels"},
  {name="Shadow",focus="Damage-over-time maintenance and mana control",levels="Verify damage spell and form unlocks",solo="Avoid pulling excess enemies",group="Respect threat and support dispels when needed"}},
 SHAMAN={
  {name="Elemental",focus="Ranged spell pacing and mana",levels="Confirm available shocks and lightning ranks",solo="Use control to preserve distance",group="Maintain assigned totems and interrupts"},
  {name="Enhancement",focus="Weapon buffs and melee resource management",levels="Verify weapon and talent availability",solo="Balance damage with emergency healing",group="Coordinate buffs and watch threat"},
  {name="Restoration",focus="Healing, cleansing and group totems",levels="Check healing ranks and totem training",solo="Use efficient attacks between recovery",group="Preserve mana for high-risk damage"}},
 MAGE={
  {name="Arcane",focus="Mana planning and utility",levels="Verify talent-supported spells before choosing a sequence",solo="Use control and recovery between pulls",group="Coordinate crowd control and avoid threat spikes"},
  {name="Fire",focus="Cast pacing, burst and target selection",levels="Check spell ranks and fire talent availability",solo="Keep an escape ready",group="Avoid breaking assigned control"},
  {name="Frost",focus="Slows, roots and safe kiting",levels="Confirm control and defensive spell unlocks",solo="Control distance and avoid accidental extra pulls",group="Coordinate roots and crowd control"}},
 WARLOCK={
  {name="Affliction",focus="Damage-over-time upkeep and resource conversion",levels="Verify curse, drain and talent availability",solo="Manage health and mana safely",group="Coordinate curses and crowd control"},
  {name="Demonology",focus="Pet survivability and utility",levels="Confirm pet summons and trained abilities",solo="Choose the right pet for the encounter",group="Prevent pet-initiated pulls"},
  {name="Destruction",focus="Direct damage pacing and threat",levels="Check available casts and talent investment",solo="Preserve defensive options",group="Watch threat during burst windows"}},
 DRUID={
  {name="Balance",focus="Ranged spell efficiency and control",levels="Verify form, spell and talent availability",solo="Balance damage with healing and recovery",group="Support control and avoid excessive threat"},
  {name="Feral",focus="Form-specific resources, positioning and finishers",levels="Check cat and bear form unlocks and trained skills",solo="Select forms for pull safety",group="Confirm tank or damage assignment"},
  {name="Restoration",focus="Healing-over-time planning and mana efficiency",levels="Check healing ranks and talent unlocks",solo="Use safe damage between recovery",group="Maintain group survival and dispel coverage"}}
}
