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
  classHandbook = {
    WARRIOR={icon="Interface\\Icons\\Ability_Warrior_BattleShout",leveling="Keep weapon damage current. Plan rage and downtime between pulls.",dungeon="Tank: control pulls and threat. Damage: avoid attacking before the tank establishes threat.",pvp="Watch positioning and save mobility for important engagements.",professions="Mining and Blacksmithing are a thematic equipment-focused pairing; compare gathering income before committing."},
    PALADIN={icon="Interface\\Icons\\Spell_Holy_HolyBolt",leveling="Use role-appropriate seals, buffs, and mana management.",dungeon="Coordinate blessings, healing support, and defensive utility.",pvp="Save defensive and support tools for high-pressure moments.",professions="Mining and Blacksmithing can support plate equipment; gathering is also an option."},
    HUNTER={icon="Interface\\Icons\\Ability_Hunter_BeastTaming",leveling="Maintain pet happiness and appropriate ammunition if the client uses those systems.",dungeon="Control pet aggression, traps, and threat before pulls.",pvp="Use range, terrain, pet control, and crowd control deliberately.",professions="Skinning and Leatherworking pair naturally for leather materials."},
    ROGUE={icon="Interface\\Icons\\Ability_Stealth",leveling="Prioritize weapon upgrades, energy use, and avoiding unnecessary multi-target pulls.",dungeon="Interrupt and control dangerous enemies; respect threat.",pvp="Plan openers, control chains, and safe disengagements.",professions="Skinning and Leatherworking are a practical self-supply option."},
    PRIEST={icon="Interface\\Icons\\Spell_Holy_PowerWordShield",leveling="Balance damage, mana recovery, and survivability.",dungeon="Track party health, dispels, and healer mana.",pvp="Coordinate defensive cooldowns and crowd control with teammates.",professions="Tailoring and Enchanting can support cloth gear progression."},
    SHAMAN={icon="Interface\\Icons\\Spell_Nature_Lightning",leveling="Choose equipment and ability priorities based on your intended role.",dungeon="Coordinate totems, interrupts, and healing or damage duties.",pvp="Use utility, positioning, and timely interrupts.",professions="Herbalism and Alchemy provide consumables for multiple roles."},
    MAGE={icon="Interface\\Icons\\Spell_Frost_FrostBolt02",leveling="Use crowd control and mana-efficient spells; manage downtime.",dungeon="Provide food, crowd control, and controlled area damage.",pvp="Plan slows, defensive cooldowns, and positioning.",professions="Tailoring and Enchanting pair well for cloth gear."},
    WARLOCK={icon="Interface\\Icons\\Spell_Shadow_DeathCoil",leveling="Manage pet utility, damage-over-time effects, and health/mana recovery.",dungeon="Coordinate summons, Healthstones, and pet control.",pvp="Use pressure, fears, and pet utility with team coordination.",professions="Tailoring and Enchanting or gathering plus Alchemy are options."},
    DRUID={icon="Interface\\Icons\\Ability_Druid_Maul",leveling="Use forms and talents suited to your preferred combat style.",dungeon="Prepare to fulfill the selected role and communicate off-role utility.",pvp="Take advantage of mobility, forms, and control.",professions="Herbalism and Alchemy support consumables and flexible roles."}
  },
  professionHandbook = {
    {name="Alchemy",icon="Interface\\Icons\\Trade_Alchemy",pair="Herbalism",summary="Gather herbs and convert them into potions, elixirs, and other consumables where recipes are available.",steps={"Visit the trainer and learn available recipes.","Track herb requirements before gathering.","Craft orange/yellow skill-up recipes where practical.","Revisit trainers as new skill tiers unlock."}},
    {name="Blacksmithing",icon="Interface\\Icons\\Trade_BlackSmithing",pair="Mining",summary="Work metal bars into equipment and utility items.",steps={"Train the profession and gather ore.","Smelt ore if the client supports that recipe.","Compare recipe material costs and expected skill gains.","Save useful bars for later recipes."}},
    {name="Enchanting",icon="Interface\\Icons\\Trade_Engraving",pair="Tailoring",summary="Use materials from disenchanting and other sources to enhance gear.",steps={"Learn available enchant recipes.","Check whether an item can be disenchanted before destroying it.","Store enchanting reagents by tier.","Review skill-up recipes before spending rare materials."}},
    {name="Engineering",icon="Interface\\Icons\\Trade_Engineering",pair="Mining",summary="Create utility gadgets and devices when supported by the client.",steps={"Train Engineering and collect metal materials.","Review schematic requirements.","Keep frequently used components organized.","Verify device restrictions in-game."}},
    {name="Leatherworking",icon="Interface\\Icons\\Trade_LeatherWorking",pair="Skinning",summary="Craft leather-related gear and supplies.",steps={"Train Leatherworking and collect skins.","Process leather if required by your recipes.","Compare gear upgrades with material cost.","Keep spare leather for later tiers."}},
    {name="Tailoring",icon="Interface\\Icons\\Trade_Tailoring",pair="Enchanting",summary="Turn cloth drops into equipment and bags where available.",steps={"Train Tailoring and save cloth drops.","Check bag recipes and material requirements.","Craft skill-up items with useful resale or disenchant value.","Revisit trainers for new patterns."}},
    {name="Herbalism",icon="Interface\\Icons\\Trade_Herbalism",pair="Alchemy",summary="Collect herbs for consumables and crafting.",steps={"Train Herbalism.","Gather herbs while questing where safe.","Organize herbs by recipe tier.","Check gathering requirements before visiting new zones."}},
    {name="Mining",icon="Interface\\Icons\\Trade_Mining",pair="Blacksmithing / Engineering",summary="Gather ore and stone for metal-based crafting.",steps={"Train Mining.","Gather nodes during normal travel.","Smelt materials when appropriate.","Keep bars and stone needed by your chosen crafting profession."}},
    {name="Skinning",icon="Interface\\Icons\\INV_Misc_Pelt_Wolf_01",pair="Leatherworking",summary="Collect hides and leather from eligible creatures.",steps={"Train Skinning.","Skin eligible kills while questing.","Sort hides and leather by tier.","Reserve materials for Leatherworking recipes."}}
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
