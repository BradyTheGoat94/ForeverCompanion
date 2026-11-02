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
