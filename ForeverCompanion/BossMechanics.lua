-- Original encounter summaries, not copied guide text. Published references are
-- not a claim that these encounters have been verified in the live client.
local M={data={},quote='"DONT BE LIKE DRYST"',reviewed='2026-11-11'}
ForeverCompanionBossMechanics=M
local function dungeon(name,slug,rows)
 local records={};M.data[name]=records
 for _,row in ipairs(rows) do
  records[row[1]]={mechanics=row[2],notes=row[3],source='https://www.icy-veins.com/wow-forever/'..slug..'-guide/',reviewed=M.reviewed}
 end
end
dungeon('The Deadmines','deadmines',{
 {'Rhahk\'Zor',{'Healer: prepare for the tank stun.'}},
 {'Miner Johnson',{},'No notable boss abilities described in the reference; clear nearby miners.'},
 {'Sneed\'s Shredder',{'Clear space for the Shredder fear.','Sneed emerges after the machine falls; save resources.'}},
 {'Sneed',{'Disarm can disrupt tank threat; allow time to regain control.'}},
 {'Gilnid',{'Kill the engineer add before its robots overwhelm the group.','Watch tank threat during the fire debuff.'}},
 {'Mr. Smite',{'At 66% and 33%, group stuns accompany weapon changes.','Kill Blackguards first; prepare tank healing for the final weapon phase.'}},
 {'Captain Greenskin',{'Face Cleave away from allies.','Prioritize the Squallshaper add and its Frost Nova.'}},
 {'Edwin VanCleef',{'Pick up Blackguards at the start and again at half health.','Prepare tank healing for Thrash bursts.'}},
 {'Cookie',{'Interrupt Cookie\'s Cooking to prevent healing.'}},
})
dungeon('Ragefire Chasm','ragefire-chasm',{
 {'Oggleflint',{'Tank: direct Cleave away from allies.'}},
 {'Taragaman the Hungerer',{'Position knockbacks away from lava.','Ranged: stay outside Fire Nova reach.'}},
 {'Jergosh the Invoker',{'Remove Immolate and Curse of Weakness when your class can.','Control the two accompanying enemies.'}},
 {'Bazzalan',{'Healer: watch poison and Sinister Strike damage on the tank.'}},
})
dungeon('Hall of Thanes','hall-of-thanes',{
 {'Faldrim Anvilmar',{'Interrupt Mind Blast; expect slower attacks under Anvilmar Curse.'}},
 {'Magmatus',{'Kill the Dark Iron Summoner.','Ranged: avoid Fire Nova; heal players affected by Combustion.'}},
 {'Plunder',{'Keep knockbacks pointed away from uncleared enemies.'}},
 {'Durgen Dirgehammer',{'Handle both golems; leave safe space for fear.','Healer: watch Rend on the tank.'}},
})
dungeon('Ruins of Lordaeron','ruins-of-lordaeron',{
 {'Witherfang',{'Healer: watch poison damage on the tank.'}},
 {'The Baron',{'Stand behind Cleave.','Knockback reduces tank threat; pause damage while control returns.'}},
 {'Viktor the Vile',{},'No notable boss abilities described; conserve resources through the Grim Campfire event waves.'},
 {'The Abandoned',{'Stop Drain Life with interrupts or stuns.','Expect Frost Nova roots and Frost Armor slows.'}},
 {'Bjork',{'Position knockbacks away from additional enemies.'}},
 {'Rath\'mael',{'Stop Flamestrike; ranged players should avoid nearby area damage.'}},
 {'Lordaeron Captain',{},'No notable boss abilities described. This rare captain is hostile to Horde players.'},
})
dungeon('Wailing Caverns','wailing-caverns',{
 {'Lady Anacondra',{'Interrupt Healing Touch and Sleep.'}},
 {'Kresh',{},'No notable boss abilities described; expect high armor.'},
 {'Lord Cobrahn',{'Stop Sleep; collect python adds.','Serpent form increases incoming tank damage.'}},
 {'Skum',{'Spread apart to limit Chained Bolt damage.'}},
 {'Deviate Faerie Dragon',{},'No notable boss abilities described; nearby druids can cast Sleep.'},
 {'Lord Serpentis',{'Interrupt Healing Touch, Sleep and Lightning Bolt.'}},
 {'Verdan the Everliving',{'Ranged: stay beyond Grasping Vines to avoid roots and knockback.'}},
 {'Mutanus the Devourer',{'Expect Terrify fear and Naralex\'s Nightmare sleep.','Ranged: avoid nearby Thundercrack damage.'}},
})
dungeon('Shadowfang Keep','shadowfang-keep',{
 {'Rethilgore',{'Interrupt Soul Drain.'}},
 {'Razorclaw the Butcher',{'Healer: respond to Butcher Drain damage.'}},
 {'Baron Silverlaine',{'Remove Veil of Shadow with curse removal to restore healing.'}},
 {'Commander Springvale',{'Interrupt Holy Light.','Kill the Wailing Guardsman before its area silence disrupts healing.'}},
 {'Odo the Blindwatcher',{'Control bats; face their Cleave away from allies.'}},
 {'Deathsworn Captain',{},'No notable boss abilities described; control the accompanying enemies.'},
 {'Fenrus the Devourer',{'Healer: watch Toxic Saliva.','Tank: collect four Voidwalkers when they appear at half health.'}},
 {'Wolf Master Nandos',{'Pick up and defeat summoned worgs.'}},
 {'Archmage Arugal',{'Use walls to break sight of Void Bolt.','After teleportation, let the tank rebuild threat.'}},
})
dungeon('Blackfathom Deeps','blackfathom-deeps',{
 {'Ghamoo-ra',{'Ranged: keep away from Trample.'}},
 {'Lady Sarevess',{'Spread for Forked Lightning; remove Frost Nova from the tank.'}},
 {'Gelihast',{'Remove the tank\'s Net root when possible.'}},
 {'Lorgus Jett',{'Remove Lightning Shield with an offensive dispel when available.'}},
 {'Old Serra\'kis',{},'No notable boss abilities described; manage underwater breathing.'},
 {'Twilight Lord Kelris',{'Interrupt Mind Blast.','Sleep can remove the tank from combat; watch threat.'}},
 {'Aku\'mai',{'Leave Poison Clouds; prepare tank healing for Frenzied Rage.'}},
})
dungeon('The Stockade','the-stockade',{
 {'Targorr the Dread',{'Prepare tank healing for Thrash and the low-health enrage.'}},
 {'Kam Deepfury',{'Healer: anticipate Shield Slam stuns; defeat accompanying enemies.'}},
 {'Hamhock',{'Spread to limit Chain Lightning.'}},
 {'Bazil Thredd',{'Keep the tank healthy before Smoke Bomb stuns the group.'}},
 {'Dextren Ward',{'Clear nearby rooms before his area fear.'}},
 {'Bruegal Ironknuckle',{},'No notable boss abilities described; control nearby enemies.'},
})
dungeon('Excavation Site: Wetlands','excavation-site-wetlands',{
 {'Saltspine',{'Dust Storm reduces melee accuracy; expect Tendon Rip slows.'}},
 {'Shadetooth',{'Control adds that reduce healing through Infected Wound.','Prepare for fear, Rend and the low-health enrage.'}},
 {'Relic Guardian',{'Tank: prepare for stuns and knockbacks.','Ranged: stay outside Thunderclap.'}},
})
dungeon('City of Dalaran','city-of-dalaran',{
 {'Atrexis the Grave Knight',{'Collect summoned skeletons; allow for tank Disarm.'}},
 {'Lyn the Ignored',{'Heal through the uninterruptible Shadow Bolt Volley.','Remove Thorns curses; collect skeletons.'}},
 {'Arcane Anomaly',{'Dodge the rotating Focal Blast; avoid edge enemies.','Interrupt Arcane Bolt.'}},
 {'Mana Devourer',{'Budget healer mana against Debilitate.','Heal the tank through Drain Vitality.'}},
 {'Fel Ancient',{'Break Entangle roots and leave Fel Timbers poison pools.'}},
 {'Unstable Sentinel',{'Move beyond Malfunction\'s 25-yard area.'}},
 {'Arcanic Enigma',{'Kill mana-burning Mana Phantoms; collect manalings.','Ranged: avoid silence; dispel Manamorph.'}},
 {'Shade of the Archmage',{'Dodge Bounding Mana and avoid Arcane Explosion.','Prepare for group Polymorph and Evocation when boss mana empties.'}},
})
dungeon('Gnomeregan','gnomeregan',{
 {'Grubbis',{'Collect the event waves before focusing Grubbis.'}},
 {'Viscous Fallout',{},'No notable boss abilities described; clear space around the patrol.'},
 {'Electrocutioner 6000',{'Spread for Chain Bolt; stand behind frontal Megavolt.'}},
 {'Crowd Pummeler 9-60',{'Avoid frontal Arcing Smash.','Ranged: keep clear of Crowd Pummel and Trample.'}},
 {'Dark Iron Ambassador',{'Interrupt Fireball; kill Burning Servants.','Switch damage types during Fire Shield immunity.'}},
 {'Mekgineer Thermaplugg',{'Shut bomb dispensers with their buttons or kill Walking Bombs.','Pause damage after knockback until tank threat recovers.'}},
})
dungeon('Razorfen Kraul','razorfen-kraul',{
 {'Roogug',{},'No notable boss abilities described; control the accompanying earth elemental.'},
 {'Aggem Thorncurse',{'Defeat summoned Boar Spirits first.'}},
 {'Death Speaker Jargba',{'Do not kill allies affected by Dominate Mind.'}},
 {'Overlord Ramtusk',{'Ranged: avoid Thunderclap; control Spearhides.'}},
 {'Earthcaller Halmgar',{'Destroy Earthbind Totems; control the elemental.'}},
 {'Agathelos the Raging',{'Tank: prepare mitigation for the strike following Rushing Charge.'}},
 {'Blind Hunter',{'Stop Sonic Burst when possible to protect spellcasting.'}},
 {'Charlga Razorflank',{'Interrupt casts and healing; expect temporary immunity.'}},
})
dungeon('Scarlet Monastery: Graveyard','scarlet-monastery-graveyard',{
 {'Interrogator Vishas',{'Remove Immolate when a magic dispel is available.'}},
 {'Azshir the Sleepless',{'Leave safe space for fear; interrupt Soul Siphon.'}},
 {'Fallen Champion',{'Stand behind Cleave; prepare for low-health Berserker Rage.'}},
 {'Ironspine',{'Leave Poison Clouds; remove Curse of Weakness.'}},
 {'Bloodmage Thalnos',{'Ranged: avoid Fire Nova and Flame Spike.','Interrupt Shadow Bolt.'}},
})
dungeon('Scarlet Monastery: Library','scarlet-monastery-library',{
 {'Houndmaster Loksey',{'Defeat the three hounds before low-health Bloodlust.'}},
 {'Arcanist Doan',{'Everyone: leave the Detonation area.','Ranged: avoid Arcane Explosion; remove Polymorph and Silence when possible.'}},
})
dungeon('Razorfen Downs','unused',{
 {'Tuten\'kash',{'Stay behind Web Spray; prioritize curse removal on the healer.','Remove Virulent Poison when possible.'}},
 {'Plaguemaw the Rotting',{'Casters: avoid Putrid Stench silence.','Remove Withered Touch disease from mana users; protect the prisoner.'}},
 {'Mordresh Fire Eye',{'Interrupt Fireball; ranged players avoid Fire Nova.','Collect the remaining skeletons.'}},
 {'Ragglesnout',{'Save an interrupt for Heal.','Control mind-controlled allies without killing them.'}},
 {'Glutton',{'Ranged: leave Disease Cloud.','Prepare tank mitigation and healing for Enrage.'}},
 {'Amnennar the Coldbringer',{'Use a backstop against knockback; collect Frost Spectres.','Interrupt Frostbolt; ranged players avoid Frost Nova.'}},
})
dungeon('Scarlet Monastery: Armory','unused',{
 {'Herod',{'Tank, melee and pets: retreat during Whirlwind; magic attacks are ineffective then.','Collect Scarlet Trainees after his death before using area damage.'}},
})
dungeon('Scarlet Monastery: Cathedral','unused',{
 {'Scarlet Commander Mograine',{'Save resources for Whitemane after Mograine falls.'}},
 {'High Inquisitor Whitemane',{'Interrupt healing; expect Sleep and Mograine\'s resurrection.','Prepare to handle both bosses after resurrection.'}},
 {'High Inquisitor Fairbanks',{'Interrupt healing; expect Power Word: Shield.','Remove harmful magic when possible.'}},
})
for _,record in pairs(M.data['Razorfen Downs']) do record.source='https://azeroth.wiki/forever/dungeons/razorfen-downs' end
M.data['Scarlet Monastery: Armory'].Herod.source='https://azeroth.wiki/forever/dungeons/scarlet-monastery/herod'
for _,record in pairs(M.data['Scarlet Monastery: Cathedral']) do record.source='https://mobalytics.gg/wow-forever/dungeons/scarlet-monastery-cathedral-guide' end
local function key(value) return type(value)=='string' and value:lower():gsub('[^%w]','') or '' end
function M.Get(d,b)
 local entries=M.data[d];if not entries then return nil end
 if M.Canonical then b=M.Canonical(d,b) end
 if entries[b] then return entries[b] end
 for name,record in pairs(entries) do if key(name)==key(b) then return record end end
end
function M.Names(d)
 local names={};for name in pairs(M.data[d] or {}) do names[#names+1]=name end;table.sort(names);return names
end
function M.Format(d,b)
 local record=M.Get(d,b)
 if not record then return 'Mechanics research pending for this boss. Missing notes do not mean the encounter has no mechanics.' end
 if record.state=='pending' then return 'Mechanics not yet documented in the reviewed sources.\n\n'..(record.notes or 'This encounter is accounted for, but its abilities and tactics still need reliable evidence. This does not mean it has no mechanics.') end
 if record.state=='not-boss' then return record.notes or 'Regular-enemy loot reference. This is not a boss encounter.' end
 local lines={}
 if #record.mechanics>0 then
  for i,note in ipairs(record.mechanics) do lines[#lines+1]=i..'. '..note end
  lines[#lines+1]='';lines[#lines+1]=M.quote
 else lines[1]='No notable boss abilities described in the published reference.' end
 if record.notes then lines[#lines+1]='';lines[#lines+1]='Notes: '..record.notes end
 return table.concat(lines,'\n')
end
