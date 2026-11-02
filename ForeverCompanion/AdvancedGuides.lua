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
  "Start: learn the profession and collect basic materials.",
  "Early progression: prefer readily available recipes or gathering nodes that can increase skill.",
  "Middle progression: check trainer unlocks, material supply and recipe colors.",
  "Later progression: compare vendor, auction and self-gathered material costs.",
  "Endgame: verify recipe sources, specialization choices and client-specific requirements."
  }},
  ["Blacksmithing"]={partner="Mining",materials="Ore and bars",output="Metal gear and utility",stages={
  "Start: learn the profession and collect basic materials.",
  "Early progression: prefer readily available recipes or gathering nodes that can increase skill.",
  "Middle progression: check trainer unlocks, material supply and recipe colors.",
  "Later progression: compare vendor, auction and self-gathered material costs.",
  "Endgame: verify recipe sources, specialization choices and client-specific requirements."
  }},
  ["Enchanting"]={partner="Tailoring",materials="Disenchanting materials",output="Gear enchants",stages={
  "Start: learn the profession and collect basic materials.",
  "Early progression: prefer readily available recipes or gathering nodes that can increase skill.",
  "Middle progression: check trainer unlocks, material supply and recipe colors.",
  "Later progression: compare vendor, auction and self-gathered material costs.",
  "Endgame: verify recipe sources, specialization choices and client-specific requirements."
  }},
  ["Engineering"]={partner="Mining",materials="Bars and components",output="Gadgets",stages={
  "Start: learn the profession and collect basic materials.",
  "Early progression: prefer readily available recipes or gathering nodes that can increase skill.",
  "Middle progression: check trainer unlocks, material supply and recipe colors.",
  "Later progression: compare vendor, auction and self-gathered material costs.",
  "Endgame: verify recipe sources, specialization choices and client-specific requirements."
  }},
  ["Leatherworking"]={partner="Skinning",materials="Leather and hides",output="Leather gear",stages={
  "Start: learn the profession and collect basic materials.",
  "Early progression: prefer readily available recipes or gathering nodes that can increase skill.",
  "Middle progression: check trainer unlocks, material supply and recipe colors.",
  "Later progression: compare vendor, auction and self-gathered material costs.",
  "Endgame: verify recipe sources, specialization choices and client-specific requirements."
  }},
  ["Tailoring"]={partner="Enchanting",materials="Cloth",output="Cloth gear and bags",stages={
  "Start: learn the profession and collect basic materials.",
  "Early progression: prefer readily available recipes or gathering nodes that can increase skill.",
  "Middle progression: check trainer unlocks, material supply and recipe colors.",
  "Later progression: compare vendor, auction and self-gathered material costs.",
  "Endgame: verify recipe sources, specialization choices and client-specific requirements."
  }},
  ["Herbalism"]={partner="Alchemy",materials="Herb nodes",output="Gathering",stages={
  "Start: learn the profession and collect basic materials.",
  "Early progression: prefer readily available recipes or gathering nodes that can increase skill.",
  "Middle progression: check trainer unlocks, material supply and recipe colors.",
  "Later progression: compare vendor, auction and self-gathered material costs.",
  "Endgame: verify recipe sources, specialization choices and client-specific requirements."
  }},
  ["Mining"]={partner="Blacksmithing / Engineering",materials="Ore nodes",output="Gathering and smelting",stages={
  "Start: learn the profession and collect basic materials.",
  "Early progression: prefer readily available recipes or gathering nodes that can increase skill.",
  "Middle progression: check trainer unlocks, material supply and recipe colors.",
  "Later progression: compare vendor, auction and self-gathered material costs.",
  "Endgame: verify recipe sources, specialization choices and client-specific requirements."
  }},
  ["Skinning"]={partner="Leatherworking",materials="Eligible creature corpses",output="Gathering",stages={
  "Start: learn the profession and collect basic materials.",
  "Early progression: prefer readily available recipes or gathering nodes that can increase skill.",
  "Middle progression: check trainer unlocks, material supply and recipe colors.",
  "Later progression: compare vendor, auction and self-gathered material costs.",
  "Endgame: verify recipe sources, specialization choices and client-specific requirements."
  }},
}}
