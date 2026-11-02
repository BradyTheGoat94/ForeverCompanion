-- General Classic-era orientation; NOT verified talent builds or Forever-specific mechanics.
ForeverCompanionAdvanced = {classes={
  WARRIOR={specializations={"Arms","Fury","Protection"},core="Weapon damage and rage management",party="Tank: shield, threat and defensive cooldowns; damage: threat discipline",sections={
  "Check weapon damage frequently; it affects how comfortably you generate and spend rage.",
  "Before a pull, decide whether you need a shield and defensive stance or a damage setup.",
  "Use interrupts and control for dangerous enemy casts; save rage for key defensive tools when tanking.",
  "Plan food, bandages and downtime so you do not enter the next pull unprepared.",
  "In groups, establish threat before heavy damage and communicate when changing targets.",
  "For PvP, manage engagement range and avoid spending every mobility tool at once.",
  "Verify stance, talent and ability availability against the actual Forever client."
  }},
  PALADIN={specializations={"Holy","Protection","Retribution"},core="Mana, seals and blessing upkeep",party="Holy: healing and dispels; Protection: threat; Retribution: support utility",sections={
  "Review blessings and seal options with your current role before leaving town.",
  "Balance offensive spells, judgement usage and self-healing against your mana reserve.",
  "Carry a suitable healing or tanking equipment set if you intend to fill those roles.",
  "Coordinate blessings and emergency utility with your party instead of duplicating buffs.",
  "Watch enemy casts and preserve defensives for moments when teammates need protection.",
  "In PvP, positioning and support timing may matter more than chasing damage.",
  "Verify available seals, talents and mana costs on the Forever client."
  }},
  HUNTER={specializations={"Beast Mastery","Marksmanship","Survival"},core="Pet control, ranged weapon and ammunition checks",party="Prevent accidental pet pulls; traps and controlled damage",sections={
  "Confirm pet stance and control before entering a crowded area or dungeon.",
  "Keep ranged weapon equipment current; check ammunition only if the client requires it.",
  "Practice opening from a safe range and repositioning without dragging extra enemies.",
  "Assign crowd-control targets before pulls; protect traps and other control from stray damage.",
  "Watch pet health and threat so it does not create unexpected downtime.",
  "For PvP, create distance and coordinate pet utility with your own escape tools.",
  "Verify pet abilities, ammunition rules and specialization options in game."
  }},
  ROGUE={specializations={"Assassination","Combat","Subtlety"},core="Weapon quality, energy and combo point management",party="Interrupt priority targets and avoid excess threat",sections={
  "Plan a safe opener and leave enough energy for interrupts or emergency control.",
  "Use combo points deliberately; choose finishers that fit the fight duration.",
  "Keep weapon upgrades current and check whether poisons are available in your client.",
  "Stealth and crowd control can bypass unnecessary enemies, but do not assume a safe route.",
  "In groups, attack the assigned target and avoid overtaking the tank's threat.",
  "For PvP, stagger control and defensive cooldowns rather than spending them together.",
  "Verify positional requirements, talents and available finishers on Forever."
  }},
  PRIEST={specializations={"Discipline","Holy","Shadow"},core="Mana efficiency and safe spell selection",party="Healing, dispels and crowd control; Shadow: threat management",sections={
  "Maintain useful personal buffs and manage mana between fights.",
  "For solo leveling, compare efficient damage options and safe recovery tools.",
  "In healing groups, prioritize dangerous damage patterns and dispel responsibilities.",
  "Keep a reserve for emergency heals rather than spending every resource on damage.",
  "Coordinate crowd control and defensive utility with the party.",
  "In PvP, protect positioning and teammates while watching for dispel opportunities.",
  "Check which spells, talents and ranks are actually available in the client."
  }},
  SHAMAN={specializations={"Elemental","Enhancement","Restoration"},core="Totem utility, mana and weapon suitability",party="Interrupt, buff and heal based on assigned role",sections={
  "Plan totem placement around movement and group positioning, if totems are supported.",
  "Choose gear and weapon options that suit your current damage or healing role.",
  "Watch mana use during repeated pulls; keep enough for emergency support.",
  "Coordinate interrupts, buffs and healing responsibilities before a dungeon.",
  "Avoid placing utility where the party will immediately move out of range.",
  "In PvP, time interrupts and defensive tools around enemy pressure.",
  "Confirm totem, talent and weapon mechanics on the actual Forever build."
  }},
  MAGE={specializations={"Arcane","Fire","Frost"},core="Mana efficiency, control and damage pacing",party="Polymorph, food and water, controlled AoE",sections={
  "Keep food, water and defensive buffs ready before extended leveling sessions.",
  "Practice controlling dangerous enemies before committing to longer casts.",
  "Use slows and positioning to reduce incoming damage and preserve mana.",
  "Coordinate polymorph or other crowd control before multi-target dungeon pulls.",
  "Treat area damage as a threat-management decision, not an automatic default.",
  "In PvP, preserve escapes for meaningful threats and avoid standing still unnecessarily.",
  "Verify spell ranks, talent effects and supported control mechanics in game."
  }},
  WARLOCK={specializations={"Affliction","Demonology","Destruction"},core="Pet utility, DoT uptime and health/mana balance",party="Summons, Healthstones, pet control and crowd control",sections={
  "Choose a pet for the encounter and keep it from starting unintended fights.",
  "Maintain useful damage-over-time effects when their duration justifies the cost.",
  "Plan health and mana recovery; avoid unsafe resource trades during heavy damage.",
  "Coordinate summoning, Healthstones and crowd control when supported by the client.",
  "Watch pet positioning and threat in dungeons, especially around crowd-controlled targets.",
  "In PvP, use defensive positioning while maintaining pressure and pet utility.",
  "Check shard requirements, spell ranks and talent behavior on Forever."
  }},
  DRUID={specializations={"Balance","Feral Combat","Restoration"},core="Form selection and role-appropriate gear",party="Flexible tank, damage and healer support",sections={
  "Choose a form that matches the role and fight instead of switching reflexively.",
  "Maintain separate equipment priorities for healing, tanking and damage where useful.",
  "Watch the resource costs of changing forms and of returning to healing.",
  "Before dungeons, agree on a primary role and prepare its consumables and utility.",
  "Use mobility and control to avoid extra pulls while questing.",
  "In PvP, use form changes for positioning and survival when supported.",
  "Verify available forms, talent branches and form-specific abilities in game."
  }},
},crafting={
  ["Alchemy"]={partner="Herbalism",materials="Herbs",output="Potions and elixirs",stages={
  "Start with available herb-based recipes; track your current trainer and learned formulas.",
  "Before crafting in bulk, compare recipe color and expected skill gains in the live UI.",
  "Plan herbs and vendor components together so a missing reagent does not halt progress.",
  "Keep separate material goals for personal consumables and items intended for trade.",
  "Check whether stronger potions, elixirs or flasks are supported before planning around them.",
  "Verify recipes, ingredient counts and profession caps on the actual client."
  }},
  ["Blacksmithing"]={partner="Mining",materials="Ore and bars",output="Metal gear and utility",stages={
  "Track ore, smelted bars and any vendor materials as separate manual goals.",
  "Before crafting equipment, compare metal cost with the expected benefit or sale value.",
  "Choose repeatable recipes based on your current skill range, not a guessed fixed route.",
  "Coordinate ore supply with Mining or another gathering source.",
  "Check for trainer upgrades and any specialization requirements in game.",
  "Verify all recipes and bar conversions before buying expensive materials."
  }},
  ["Enchanting"]={partner="Tailoring",materials="Disenchanting materials",output="Gear enchants",stages={
  "Disenchant only items you intend to sacrifice; the addon never selects items for you.",
  "Track dust, essences, shards and any required rods as manual material goals.",
  "Compare the value of an item with the expected materials before disenchanting.",
  "Keep a short list of useful enchants for your own gear and party roles.",
  "Confirm recipe availability and reagent counts from the live enchanting interface.",
  "Do not assume an expansion's enchanting rules apply to this client."
  }},
  ["Engineering"]={partner="Mining",materials="Bars and components",output="Gadgets",stages={
  "Track metal bars, stone and intermediate components before planning finished gadgets.",
  "Consider whether utility items justify their material cost for your playstyle.",
  "Avoid crafting large batches until the current recipe skill color is verified.",
  "Reserve shared ore for Mining, Engineering and other crafting plans deliberately.",
  "Check device restrictions and skill requirements in the live client.",
  "Use the manual recipe planner for multi-component items; no crafting is automated."
  }},
  ["Leatherworking"]={partner="Skinning",materials="Leather and hides",output="Leather gear",stages={
  "Track leather, hides and any cured or treated intermediate materials separately.",
  "If gathering yourself, coordinate Skinning with the creature types you already encounter.",
  "Compare armor kits, gear and other utility recipes against your actual needs.",
  "Check recipe skill colors and trainer availability before bulk production.",
  "Keep rare materials out of speculative recipes until their use is verified.",
  "Verify any specialization branches or expansion-specific patterns in game."
  }},
  ["Tailoring"]={partner="Enchanting",materials="Cloth",output="Cloth gear and bags",stages={
  "Track cloth drops, thread and vendor components before starting a crafting session.",
  "Consider bags and useful gear when deciding which recipes to prioritize.",
  "Keep separate material goals for personal upgrades and sale inventory.",
  "If pairing with Enchanting, decide which crafted items you truly want to disenchant.",
  "Review recipe colors and skill requirements in the live profession window.",
  "Verify bag sizes, pattern sources and cloth availability on the target client."
  }},
  ["Herbalism"]={partner="Alchemy",materials="Herb nodes",output="Gathering",stages={
  "Gather only nodes your character can safely reach; avoid assuming a fixed route is optimal.",
  "Use the live skill and node colors to judge when to seek a higher-level area.",
  "Track herb types separately so you can plan Alchemy recipes or market sales.",
  "Check inventory space before a long gathering session.",
  "Combine herb collection with nearby quests when it does not create dangerous detours.",
  "Verify node locations and skill thresholds in game; no map pathfinding is provided."
  }},
  ["Mining"]={partner="Blacksmithing / Engineering",materials="Ore nodes",output="Gathering and smelting",stages={
  "Choose ore nodes appropriate to your current skill and combat safety.",
  "Track ore and smelted bars separately when both matter to your crafting goals.",
  "Compare demand from Blacksmithing and Engineering before selling or converting ore.",
  "Use the live profession window to confirm smelting skill gains and trainer options.",
  "Plan bag space and repair needs before extended gathering.",
  "Verify node locations, smelting conversions and requirements on the actual client."
  }},
  ["Skinning"]={partner="Leatherworking",materials="Eligible creature corpses",output="Gathering",stages={
  "Check whether defeated creatures are eligible before planning a skinning session.",
  "Combine gathering with relevant combat quests when practical and safe.",
  "Track leather, hides and any special materials as distinct manual goals.",
  "Coordinate supplies with Leatherworking or compare selling raw materials.",
  "Review trainer and skill thresholds as your character progresses.",
  "Do not assume every creature or dungeon mob can be skinned on Forever."
  }},
}}
