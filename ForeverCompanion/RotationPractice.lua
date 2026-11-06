-- Short Forever practice priorities. Boss and dungeon spell orders use the
-- published, per-specialization references in SpecPlaybooks.lua.
local practice={
 WARRIOR={
  Arms={
   opener="Battle Shout, then Charge when the pull is safe.",
   leveling={{"Rend","Use on enemies that will survive its ticks."},{"Overpower","Press after a dodge when it lights up."},{"Mortal Strike","Use when talented and affordable; otherwise keep swinging."}},
   aoe={{"Sweeping Strikes","Use the talent with a second target in reach."},{"Whirlwind","Hit a grouped pack when your stance permits."},{"Cleave","Spend spare Rage after your main attacks."}},
   pvp={{"Hamstring","Slow the target so you can stay in range."},{"Mortal Strike","Apply healing pressure if talented."},{"Pummel","Save it for a heal or dangerous cast."}},
  },
  Fury={
   opener="Battle Shout before the pull. Keep both weapon swings connecting.",
   leveling={{"Bloodthirst","Use when talented and affordable."},{"Execute","Finish low-health enemies if it saves time."},{"Heroic Strike","Spend surplus Rage; keep enough for Bloodthirst."}},
   aoe={{"Whirlwind","Press once enemies are in melee range."},{"Bloodthirst","Keep damage on the priority target."},{"Cleave","Use only with extra Rage and a second target."}},
   pvp={{"Hamstring","Stay in melee without chasing out of line of sight."},{"Bloodthirst","Pressure when you can safely connect."},{"Berserker Rage","Hold for fear when the matchup calls for it."}},
  },
  Protection={
   opener="Equip a shield, use Defensive Stance, and face the pack away from allies.",
   leveling={{"Shield Slam","Use if talented to build early threat."},{"Revenge","Press when available."},{"Sunder Armor","Build threat when higher-priority attacks are unavailable."}},
   aoe={{"Thunder Clap","Establish threat as the pack groups."},{"Revenge","Use procs while cycling through enemies."},{"Taunt","Recover a loose enemy, then follow with threat."}},
   pvp={{"Shield Bash","Stop a dangerous cast."},{"Hamstring","Peel a melee attacker off an ally."},{"Shield Wall","Use before a dangerous damage spike."}},
  },
 },
 HUNTER={
  ["Beast Mastery"]={
   opener="Send a healthy pet onto the target, then start Auto Shot.",
   leveling={{"Auto Shot","Let your pet get ahead on threat. Keep firing."},{"Serpent Sting","Use on a target that will live through several ticks."},{"Arcane Shot","Weave it in when Mana allows."}},
   aoe={{"Multi-Shot","Use on grouped targets clear of crowd control."},{"Bestial Wrath","Use when talented and your pet can stay on the priority target."},{"Volley","Channel only when the pack will stay in place."}},
   pvp={{"Concussive Shot","Keep space for ranged attacks."},{"Bestial Wrath","Commit once your pet can reliably reach the target."},{"Freezing Trap","Peel an attacker or isolate a second enemy."}},
  },
  Marksmanship={
   opener="Mark a durable target and start Auto Shot. Keep your pet on the kill target.",
   leveling={{"Aimed Shot","Use if talented when it fits between shots."},{"Arcane Shot","Use while moving or when an Aimed Shot cast is unsafe."},{"Auto Shot","Avoid delaying shots unnecessarily."}},
   aoe={{"Multi-Shot","Use over Aimed Shot when extra targets can be hit safely."},{"Volley","Use on a stationary pack if you can channel safely."},{"Arcane Shot","Pressure the priority target between pack abilities."}},
   pvp={{"Concussive Shot","Create a window for aimed pressure."},{"Aimed Shot","Use if talented when safe to stop and cast."},{"Freezing Trap","Protect your firing position or isolate an enemy."}},
  },
  Survival={
   opener="Set up the trap path and decide whether you can safely fight in melee.",
   leveling={{"Serpent Sting","Use while approaching a durable enemy."},{"Raptor Strike","Use if your build and positioning favor melee."},{"Wing Clip","Slow an enemy before you create distance."}},
   aoe={{"Explosive Trap","Place it where the tank will hold the pack."},{"Multi-Shot","Use if you are at range and can avoid controlled enemies."},{"Raptor Strike","Keep pressure on the priority target when fighting in melee."}},
   pvp={{"Freezing Trap","Put it where the attacker must move."},{"Wing Clip","Slow a target that reaches melee."},{"Concussive Shot","Rebuild range before committing another attack."}},
  },
 },
 ROGUE={
  Assassination={
   opener="Apply poisons. Open from Stealth when it is safe.",
   leveling={{"Mutilate","Use as your builder if talented and using two daggers."},{"Sinister Strike","Use your trained builder before Mutilate."},{"Eviscerate","Finish when the target will die before a bleed pays off."}},
   aoe={{"Mutilate","Build on the most dangerous target with the right daggers."},{"Rupture","Bleed a target that will live through the ticks."},{"Kick","Save Energy to interrupt a dangerous caster."}},
   pvp={{"Cheap Shot","Open with control when it gives you a safe damage window."},{"Mutilate","Build pressure if talented with daggers."},{"Kidney Shot","Spend points for control when a stun will matter."}},
  },
  Combat={
   opener="Apply poisons and equip your strongest appropriate main-hand weapon.",
   leveling={{"Sinister Strike","Build points without wasting Energy."},{"Riposte","Use after a parry if talented."},{"Slice and Dice","Maintain it on fights long enough to benefit."}},
   aoe={{"Blade Flurry","Use if talented when two enemies can stay in range."},{"Slice and Dice","Keep your swings fast during the cleave window."},{"Sinister Strike","Build on the target the group needs dead first."}},
   pvp={{"Gouge","Create room to reposition or wait for Energy."},{"Sinister Strike","Apply steady pressure when in range."},{"Kick","Save Energy for the next important cast."}},
  },
  Subtlety={
   opener="Enter Stealth early and pick an angle for your opener.",
   leveling={{"Ambush","Open from behind if using a dagger and safe to do so."},{"Backstab","Use when you have the weapon and position; otherwise use your builder."},{"Eviscerate","Finish before the target dies with unused points."}},
   aoe={{"Garrote","Open on a durable priority enemy if appropriate."},{"Slice and Dice","Maintain uptime while focusing that enemy."},{"Kick","Interrupt the dangerous caster; avoid breaking crowd control."}},
   pvp={{"Cheap Shot","Set up burst or stop an opener."},{"Kidney Shot","Control the target when it will make a difference."},{"Vanish","Save it for a reset or another opener."}},
  },
 },
 PRIEST={
  Discipline={
   opener="Check Fortitude, your position, and who will take the first hit.",
   leveling={{"Power Word: Shield","Shield before damage when it will save health or casts."},{"Shadow Word: Pain","Apply if the enemy will live through the ticks."},{"Smite","Cast safely, then wand when saving Mana."}},
   aoe={{"Power Word: Shield","Protect an ally about to take a spike."},{"Prayer of Healing","Use if trained and several party members are injured."},{"Dispel Magic","Remove dangerous effects before adding more healing."}},
   pvp={{"Power Word: Shield","Protect the focus target ahead of burst."},{"Dispel Magic","Remove a dangerous debuff or enemy buff as appropriate."},{"Psychic Scream","Peel when enemies reach your group."}},
  },
  Holy={
   opener="Start in healing range and leave yourself a safe line of sight.",
   leveling={{"Smite","Open at range; wand to save Mana if trained."},{"Renew","Use when damage is predictable and ticks will help."},{"Heal","Use an efficient direct heal when you have time."}},
   aoe={{"Prayer of Healing","Use when several party members actually need healing."},{"Renew","Cover steady damage across allies when Mana permits."},{"Flash Heal","Recover an ally who cannot wait for the slower cast."}},
   pvp={{"Renew","Keep healing while moving to cover."},{"Flash Heal","Stabilize an ally when a safe cast window opens."},{"Psychic Scream","Create space before attempting another heal."}},
  },
  Shadow={
   opener="Apply long-duration effects to enemies that will survive them.",
   leveling={{"Shadow Word: Pain","Use on enemies worth the full duration."},{"Mind Blast","Use for direct damage when Mana allows."},{"Mind Flay","Use if talented; wand if conserving Mana."}},
   aoe={{"Shadow Word: Pain","Spread it only to durable enemies."},{"Mind Blast","Focus down the dangerous target."},{"Mind Flay","Fill when safe to channel and no important refresh is due."}},
   pvp={{"Shadow Word: Pain","Keep pressure while moving."},{"Silence","Use if talented on a decisive cast."},{"Psychic Scream","Peel melee before committing to a channel."}},
  },
 },
 SHAMAN={
  Elemental={
   opener="Place useful totems, then start casting from safe range.",
   leveling={{"Lightning Bolt","Use as your efficient ranged attack."},{"Flame Shock","Use when a target will survive its ticks."},{"Earth Shock","Stop a dangerous cast when your Shock is ready."}},
   aoe={{"Chain Lightning","Use on grouped enemies when the tank has threat."},{"Fire Nova","Use with the right setup when enemies will stay in range."},{"Lightning Bolt","Focus the priority target between pack casts."}},
   pvp={{"Frost Shock","Create space or hold an enemy near your team."},{"Earth Shock","Save a Shock window for an important interrupt."},{"Chain Lightning","Use when you have a safe burst window."}},
  },
  Enhancement={
   opener="Check your weapon imbue and useful totems before closing to melee.",
   leveling={{"Stormstrike","Use if talented and affordable."},{"Flame Shock","Use on enemies that will survive the periodic damage."},{"Healing Wave","Heal between pulls rather than risking a second fight low."}},
   aoe={{"Fire Nova","Use on a stable pack when your totem setup supports it."},{"Stormstrike","Pressure the priority target while you keep swinging."},{"Earth Shock","Reserve it for a dangerous caster when needed."}},
   pvp={{"Frost Shock","Slow the target so you can keep connecting."},{"Stormstrike","Use talented melee pressure when in range."},{"Grounding Totem","Time it for an important hostile spell."}},
  },
  Restoration={
   opener="Set support totems within range and keep Mana for urgent heals.",
   leveling={{"Lightning Bolt","Open at range on a safe solo pull."},{"Flame Shock","Use on enemies that will live through the damage."},{"Healing Wave","Use an efficient rank when you have time to cast."}},
   aoe={{"Chain Heal","Use when several injured allies are close enough for bounces."},{"Healing Wave","Switch to direct healing if damage is concentrated."},{"Mana Tide Totem","Use if talented when the group needs Mana."}},
   pvp={{"Grounding Totem","Protect a healing window from a key spell."},{"Lesser Healing Wave","Use a faster cast when an ally needs immediate help."},{"Earth Shock","Interrupt dangerous casts when it is safe to spend the global."}},
  },
 },
 MAGE={
  Arcane={
   opener="Start with Arcane Intellect and enough Mana for the planned pull.",
   leveling={{"Arcane Missiles","Channel when safe and the target will survive."},{"Arcane Blast","Use when talented; switch to cheaper casts if Mana is tight."},{"Fire Blast","Finish or deal damage on the move when Mana permits."}},
   aoe={{"Arcane Explosion","Use when the pack is stable and melee range is safe."},{"Arcane Missiles","Focus a priority target when you can channel."},{"Frost Nova","Create room if enemies reach you."}},
   pvp={{"Polymorph","Isolate a second threat when allies can leave it alone."},{"Counterspell","Stop the cast that matters most."},{"Arcane Missiles","Commit only from a safe channeling position."}},
  },
  Fire={
   opener="Find a clear casting lane and open on the priority target.",
   leveling={{"Fireball","Use as your usual cast."},{"Pyroblast","Open with it or use the relevant proc if talented."},{"Fire Blast","Finish on the move when it saves a cast."}},
   aoe={{"Flamestrike","Place it on enemies that will stay grouped."},{"Blast Wave","Use if talented when close range is safe."},{"Fire Blast","Finish the dangerous target while moving."}},
   pvp={{"Fire Blast","Use while moving or to finish a low target."},{"Pyroblast","Take the safe cast or proc window if talented."},{"Frost Nova","Peel melee before resuming casts."}},
  },
  Frost={
   opener="Start at range with room to kite.",
   leveling={{"Frostbolt","Keep enemies slowed as you deal damage."},{"Frost Nova","Root enemies that reach you and step away."},{"Ice Lance","Use on an eligible frozen target when trained."}},
   aoe={{"Blizzard","Channel from safety on a controlled group."},{"Cone of Cold","Slow enemies that approach your position."},{"Frost Nova","Root only when it helps the group kite or recover."}},
   pvp={{"Frostbolt","Slow the target from a safe casting position."},{"Frost Nova","Peel or create a frozen damage window."},{"Ice Lance","Use the frozen-target opportunity if trained."}},
  },
 },
 WARLOCK={
  Affliction={
   opener="Send the appropriate demon and choose a utility Curse for the target.",
   leveling={{"Corruption","Apply to durable enemies."},{"Bane of Agony","Give it time to tick; skip it on targets dying soon."},{"Drain Life","Sustain health before spending it on Life Tap."}},
   aoe={{"Corruption","Spread to enemies that will live long enough."},{"Bane of Agony","Apply to durable enemies only."},{"Rain of Fire","Use if enemies are stacked and threat permits."}},
   pvp={{"Corruption","Keep pressure while moving."},{"Fear","Create distance or isolate an enemy."},{"Drain Life","Recover health when it is safe to channel."}},
  },
  Demonology={
   opener="Summon the demon your build expects and keep it alive and in range.",
   leveling={{"Corruption","Apply to durable enemies while the demon works."},{"Bane of Agony","Use when the target will live through the damage."},{"Shadow Bolt","Fill from range if you can stand still safely."}},
   aoe={{"Rain of Fire","Use on a held pack when safe to channel."},{"Corruption","Keep pressure on the priority enemy."},{"Health Funnel","Recover your demon when the damage trade is safe."}},
   pvp={{"Fear","Peel an attacker when allies can avoid breaking it."},{"Corruption","Apply pressure while repositioning."},{"Health Funnel","Protect the demon if it is focused and you can channel safely."}},
  },
  Destruction={
   opener="Start at range and choose the Fire or Shadow spells your build supports.",
   leveling={{"Immolate","Use in a Fire build when the enemy will live through ticks."},{"Shadow Bolt","Use as your trained filler until your build provides a better fit."},{"Conflagrate","Use if talented with its prerequisite effect active."}},
   aoe={{"Rain of Fire","Channel on a stable pack from safe range."},{"Hellfire","Use only when your health, threat and position allow it."},{"Immolate","Keep damage on a durable priority enemy."}},
   pvp={{"Fear","Create time for a safe damage cast."},{"Immolate","Set up Fire pressure when you can cast safely."},{"Conflagrate","Use the talented burst when the target meets its requirement."}},
  },
 },
 DRUID={
  Balance={
   opener="Start at range and keep space to cast.",
   leveling={{"Moonfire","Use on an enemy that will survive its damage."},{"Wrath","Use as a quick filler."},{"Starfire","Choose a safe longer cast, or use it for your talented Eclipse setup."}},
   aoe={{"Hurricane","Channel on a stable pack when learned."},{"Moonfire","Pressure durable targets while moving."},{"Wrath","Focus the dangerous enemy between pack casts."}},
   pvp={{"Entangling Roots","Control a target when the environment allows it."},{"Moonfire","Apply pressure while moving."},{"Wrath","Cast when you have room and a safe line of sight."}},
  },
  Feral={
   opener="Enter Cat Form for damage and get behind the target when safe.",
   leveling={{"Claw","Build combo points before you have a better talented or positional option."},{"Rip","Use when the enemy will survive the bleed."},{"Ferocious Bite","Finish a target that would die before Rip pays off."}},
   aoe={{"Rake","Spread only to enemies that will survive its ticks."},{"Rip","Bleed the priority target if it will live."},{"Ferocious Bite","Finish the priority enemy when a bleed would be wasted."}},
   pvp={{"Pounce","Open from Prowl when a stun gives you a window."},{"Rake","Keep pressure on a target you can reach."},{"Bash","Shift to Bear Form for emergency control when needed."}},
  },
  ["Guardian / Bear"]={
   opener="Use Bear Form and position enemies away from allies.",
   leveling={{"Maul","Spend Rage when you can keep enough for the next threat tool."},{"Swipe","Use when multiple enemies are in range."},{"Growl","Recover a loose enemy and follow with threat."}},
   aoe={{"Swipe","Build threat on enemies in front of you."},{"Maul","Keep pressure on the priority target."},{"Challenging Roar","Recover a dangerous pack when the group needs time."}},
   pvp={{"Bash","Stun an attacker to protect an ally."},{"Frenzied Regeneration","Recover during pressure if trained and appropriate."},{"Entangling Roots","Use outside Bear Form when safe and permitted."}},
  },
  Restoration={
   opener="Keep allies in range and apply healing over time ahead of predictable damage.",
   leveling={{"Wrath","Use for solo damage from range."},{"Moonfire","Add it when the target will survive its ticks."},{"Rejuvenation","Heal steady damage before the next pull."}},
   aoe={{"Wild Growth","Use if talented when several nearby allies need healing."},{"Rejuvenation","Cover steady damage where ticks will count."},{"Regrowth","Use when an injured ally needs a direct heal too."}},
   pvp={{"Rejuvenation","Heal while moving to safety."},{"Nature's Swiftness","Use if talented when an immediate cast can save an ally."},{"Entangling Roots","Peel attackers when the environment allows it."}},
  },
 },
}

local fury={"Righteous Fury","Apply before tanking. This long buff increases Holy threat.",16,25780}
local tankSeal={"Seal of Fury","Keep this short seal active with a shield. Melee hits add Holy damage and an absorb.",10,1311649}
local tankJudge={"Judgement","With Seal of Fury active, use it to taunt a loose enemy. Save it for swaps when needed.",4,20271}
local tankShield={"Holy Shield","Use if talented while taking melee hits. Equip a shield and keep Mana for it.",30,20925}
local tankStrike={"Holy Strike","Use in melee to build threat on the target you need to hold.",6,679}
local tankGround={"Consecration","Drop it when enemies are grouped and will stay in it. Keep Mana for the next pull.",20,26573}
local tankWall={"Templar's Bulwark","Use before a dangerous hit if talented. Check Forbearance first.",30,1311015}
local retSeal={"Seal of Righteousness","Keep it active until Seal of Command is learned. It also suits a Holy Shock hybrid.",1,21084}
local retCommand={"Seal of Command","Use this damage seal if talented, especially with a slow two-hander.",18,20375}
local retCrusader={"Seal of the Crusader","On durable enemies, apply its Judgement if assigned. Then switch to your damage seal.",6,21082}
local retJudge={"Judgement","Use when ready with your damage seal. Judgement leaves your seal active in Forever.",4,20271}
local retStrike={"Holy Strike","Press in melee when ready. Sacred Arbiter can refresh your applied Judgements.",6,679}
local retExecute={"Hammer of Wrath","Use below 20% health if trained and safe to cast.",44,24275}
local retSwap={"Unsealed Wrath","With the talent and a slow weapon, build 2–3 Command echoes, switch to Righteousness for one swing, then switch back.",30,1310735}
local retGround={"Consecration","Prioritize it on packs. Skip it on short solo fights or when Mana is tight.",20,26573}
local retExorcism={"Exorcism","Use on Undead or Demons when it fits between your main attacks.",20,879}
local earlyHeal={"Holy Light","Heal when needed; keep enough Mana for the next hit.",1,635}

practice.PALADIN={
 Protection={
  opener="Equip a shield. Keep Righteous Fury up when trained and use Seal of Fury while tanking.",
  dungeonOpener="Group the pack first. Use Consecration once it is held in place.",
  leveling={fury,tankSeal,tankJudge,tankStrike,tankGround,earlyHeal},
  boss={fury,tankSeal,tankJudge,tankShield,tankStrike,tankGround,tankWall},
  dungeon={fury,tankSeal,tankGround,tankShield,tankJudge,tankStrike,tankWall},
  aoe={fury,tankSeal,tankGround,tankShield,tankJudge,tankStrike},
  pvp={{"Hammer of Justice","Stun a threat to protect an ally or stop a cast.",8,853},{"Blessing of Freedom","Help yourself or an ally break roots.",18,1044},earlyHeal},
 },
 Retribution={
  opener="Put up your assigned Blessing and damage seal. Stay in melee so your swings land.",
  dungeonOpener="Let the tank establish threat before placing Consecration or committing damage.",
  leveling={retSeal,retCommand,retJudge,retStrike,retGround,retExecute},
  boss={retCrusader,retCommand,retSeal,retJudge,retExecute,retStrike,retSwap,retExorcism},
  dungeon={retCommand,retSeal,retJudge,retGround,retStrike,retExecute,retSwap,retExorcism},
  aoe={retCommand,retSeal,retGround,retJudge,retStrike,retExorcism},
  pvp={{"Hammer of Justice","Create a burst window or stop an important cast.",8,853},retCommand,retJudge,retStrike,{"Blessing of Freedom","Break roots to get back in melee.",18,1044}},
 },
 Holy={
  opener="Choose a safe healing position and put your assigned Blessing on allies.",
  leveling={retSeal,retJudge,{"Holy Strike","Use in melee on solo pulls when ready.",6,679},earlyHeal},
  aoe={{"Light's Vigil","If talented, set up Holy Shock before the group takes damage."},{"Holy Shock","Use if talented for urgent healing."},{"Flash of Light","Use for efficient follow-up heals.",20,19750},earlyHeal},
  pvp={{"Blessing of Freedom","Help a teammate escape a root.",18,1044},{"Holy Shock","Use if talented when there is no time to cast."},earlyHeal},
 },
}

function ForeverCompanionRotationPractice(class,spec,mode,level)
 local group=practice[class]
 local entry=group and group[spec]
 if not entry then return end
 local steps=entry[mode]
 if class=="PALADIN" and type(level)=="number" and level<10 and mode~="pvp" then
  steps=spec=="Holy" and mode~="leveling" and {earlyHeal,retSeal} or {retSeal,retJudge,retStrike,earlyHeal}
 end
 local summary={opener=mode=="dungeon" and entry.dungeonOpener or entry.opener,keepOrder=true,spellIDs={}}
 if not steps then return nil,nil,summary end
 local rows,primary={},{}
 for _,row in ipairs(steps) do
  if not row[3] or type(level)~="number" or level>=row[3] then
   rows[#rows+1]=row[1].." — "..row[2]
   primary[#rows]=row[1]
   summary.spellIDs[#rows]=row[4]
  end
 end
 if #rows==0 then rows[1]="Train your first abilities, then return here to practice." end
 return rows,primary,summary
end
