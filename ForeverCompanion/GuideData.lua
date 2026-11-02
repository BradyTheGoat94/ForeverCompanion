-- General reference content only; not verified Forever-specific quest or loot data.
ForeverCompanionData = {
  zones = {
    {1, 10, "Starting zones", "Complete introductory quests, train abilities, and learn your class."},
    {10, 20, "Early zones", "Coordinate quests and gather dungeon quests before entering."},
    {20, 30, "Mid-level zones", "Upgrade weapons and review class trainers and talent choices."},
    {30, 40, "Mid-level zones", "Prepare crowd control, consumables, and dungeon roles."},
    {40, 50, "Higher-level zones", "Review travel, profession materials, and role-specific gear."},
    {50, 60, "Endgame preparation", "Verify dungeon unlocks and equipment requirements in game."},
  },
  classes = {
    WARRIOR = {"Maintain a strong weapon; keep a shield for tanking.", "Coordinate pull targets, interrupts, and defensive abilities."},
    PALADIN = {"Select role-appropriate gear and talents.", "Coordinate blessings and emergency support."},
    HUNTER = {"Manage pet positioning to avoid extra pulls.", "Coordinate traps and crowd control."},
    ROGUE = {"Prioritize weapon upgrades and interrupts.", "Use stealth and crowd control deliberately."},
    PRIEST = {"Plan around mana and dispels.", "Communicate healing and utility responsibilities."},
    SHAMAN = {"Choose gear suited to your role.", "Coordinate buffs and interrupts."},
    MAGE = {"Prepare food and manage mana.", "Use Polymorph and slows to protect the party."},
    WARLOCK = {"Manage pet choice and damage-over-time spells.", "Coordinate Healthstones and crowd control."},
    DRUID = {"Choose gear and forms for your intended role.", "Prepare alternate equipment when switching roles."},
  },
  roleAdvice = {
    Tank = {
      "Before a pull: confirm healer mana and mark a priority target.",
      "Keep dangerous enemies facing away from the group; plan defensive cooldowns.",
      "Explain unusual pulls briefly instead of assuming everyone knows the route."
    },
    Damage = {
      "Focus the tank's target and avoid breaking crowd control.",
      "Interrupt dangerous casts when your class can; save burst for priority enemies.",
      "Manage threat, positioning and resources instead of chasing damage numbers."
    },
    Healer = {
      "Tell the group when you need mana or a pause.",
      "Prioritize survival and dispels; avoid standing in dangerous ground effects.",
      "Agree on emergency cooldowns before difficult pulls."
    }
  },
  beginnerTips = {
    "Quest log: use the Quests tab to see active objectives and turn-in status.",
    "Travel: group objectives by nearby zones when possible; no verified route optimization is available yet.",
    "Inventory: repair and clear bags before long dungeon or quest sessions.",
    "Group play: tell teammates your role and confirm who handles interrupts and crowd control.",
    "Progress: check your class trainer and profession trainer when returning to town."
  },
  dungeons = {
    {"Deadmines", "Plan patrols, interrupts, and crowd control."},
    {"Shadowfang Keep", "Manage caster pulls and line of sight."},
    {"The Stockade", "Avoid chain-pulling tightly packed enemies."},
    {"Scarlet Monastery", "Check wing and coordinate interrupts."},
    {"Zul'Farrak", "Coordinate event waves and crowd control."},
    {"Blackrock Depths", "Plan your route and objectives before entering."},
  },
  checklist = {
    Leveling = {"Review quests", "Train available abilities", "Repair equipment", "Coordinate group objectives"},
    Dungeons = {"Collect dungeon quests", "Confirm roles", "Assign crowd control", "Review verified boss mechanics"},
    Professions = {"Check skill levels", "Gather materials", "Visit trainers", "Coordinate recipes"},
    PvP = {"Check equipment", "Plan target focus", "Coordinate defensive abilities", "Review objectives"},
  },
}
