-- Cooldown planning reference only. These are examples, not verified Forever spell availability.
ForeverCompanionCooldownGuides={
 WARRIOR={offense={"Recklessness","Death Wish (talent-dependent)"},defense={"Shield Wall","Last Stand (talent-dependent)"},utility={"Pummel / Shield Bash","Intercept"}},
 PALADIN={offense={"Avenging Wrath (version-dependent)","Trinket or on-use effects"},defense={"Divine Shield","Lay on Hands","Divine Protection"},utility={"Hammer of Justice","Blessing of Freedom"}},
 HUNTER={offense={"Rapid Fire","Bestial Wrath (talent-dependent)"},defense={"Deterrence (version-dependent)","Feign Death"},utility={"Freezing Trap","Intimidation (talent-dependent)"}},
 ROGUE={offense={"Adrenaline Rush (talent-dependent)","Blade Flurry (talent-dependent)","Cold Blood (talent-dependent)"},defense={"Evasion","Vanish"},utility={"Kick","Sprint","Blind"}},
 PRIEST={offense={"Power Infusion (talent-dependent)","Shadowfiend (version-dependent)"},defense={"Power Word: Shield","Desperate Prayer (availability-dependent)"},utility={"Psychic Scream","Silence (talent-dependent)"}},
 SHAMAN={offense={"Bloodlust / Heroism (version-dependent)","Elemental Mastery (talent-dependent)"},defense={"Nature's Swiftness (talent-dependent)"},utility={"Earth Shock (interrupt behavior version-dependent)","Grounding Totem"}},
 MAGE={offense={"Arcane Power (talent-dependent)","Icy Veins (version-dependent)","Combustion (talent-dependent)"},defense={"Ice Block (talent-dependent)","Mana Shield"},utility={"Counterspell","Blink","Cold Snap (talent-dependent)"}},
 WARLOCK={offense={"On-use trinkets","Summon Infernal / Doomguard (availability-dependent)"},defense={"Death Coil (version-dependent)","Healthstone"},utility={"Spell Lock (pet-dependent)","Howl of Terror"}},
 DRUID={offense={"Berserk (version-dependent)","Tiger's Fury","Nature's Swiftness (talent-dependent)"},defense={"Barkskin","Survival Instincts (version-dependent)"},utility={"Bash","Innervate","Rebirth"}}
}
ForeverCompanionCooldownContexts={
 leveling="Save long cooldowns for elites, difficult pulls, or recovery; avoid delaying safe progress just to use them.",
 dungeon="Coordinate major damage cooldowns with tank pull size, interrupts, and healer resources.",
 boss="Use appropriate damage cooldowns during safe uptime or planned burst windows; keep defensive tools for mechanics.",
 aoe="Use burst only after the tank establishes control; preserve an escape or defensive option.",
 pvp="Track opponent defensives and crowd control; avoid committing burst into immunity, and keep an escape plan."
}
function ForeverCompanionFormatCooldowns(class,mode)
 local guide=ForeverCompanionCooldownGuides[class]
 if not guide then return "Cooldown guidance unavailable." end
 local lines={"COOLDOWN PLANNING (VERIFY SPELL AVAILABILITY)"}
 lines[#lines+1]=ForeverCompanionCooldownContexts[mode] or ""
 for _,category in ipairs({"offense","defense","utility"}) do
   lines[#lines+1]=string.upper(category)..": "..table.concat(guide[category] or {},", ")
 end
 lines[#lines+1]="Only use spells you actually know. These are candidate tools, not confirmed Forever rotations or timings."
 return table.concat(lines,"\n")
end
