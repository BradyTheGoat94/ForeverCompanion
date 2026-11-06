-- Blizzard's class sheet and read-only spell texture lookup. Never generated art.
-- Class crops: Blizzard_SharedXML/SharedConstants.lua (reviewed 2026-11-02).
local I={}
ForeverCompanionIcons=I
I.classTexture="Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes"
I.unknown="Interface\\Icons\\INV_Misc_QuestionMark"
local crops={
 WARRIOR={0,.25,0,.25}, MAGE={.25,.49609375,0,.25},
 ROGUE={.49609375,.7421875,0,.25}, DRUID={.7421875,.98828125,0,.25},
 HUNTER={0,.25,.25,.5}, SHAMAN={.25,.49609375,.25,.5},
 PRIEST={.49609375,.7421875,.25,.5}, WARLOCK={.7421875,.98828125,.25,.5},
 PALADIN={0,.25,.5,.75}
}
function I.Class(class)
 local c=crops[class]
 if not c then return I.unknown,{0,1,0,1} end
 return I.classTexture,{c[1],c[2],c[3],c[4]}
end
function I.ApplyClass(texture,class)
 local path,coords=I.Class(class)
 texture:SetTexture(path)
 if texture.SetTexCoord then texture:SetTexCoord(coords[1],coords[2],coords[3],coords[4]) end
end
function I.Spell(name)
 if type(name)~="string" or name=="" then return nil end
 local api=type(C_Spell)=="table" and C_Spell.GetSpellTexture
 if type(api)~="function" then api=type(GetSpellTexture)=="function" and GetSpellTexture or nil end
 if type(api)~="function" then return nil end
 local ok,value=pcall(function()
  local icon=api(name)
  if type(icon)=="number" and icon==icon and icon>0 and icon<math.huge and icon%1==0 then return icon end
  if type(icon)=="string" and (icon:sub(1,10)=="Interface\\" or icon:sub(1,10)=="Interface/") and not icon:find("..",1,true) then return icon end
 end)
 return ok and value or nil
end
function I.ApplyRotation(texture,class,mode,index)
 local path,cue,status=ForeverCompanionRotationCardIcon(class,mode,index)
 if status=="class" then I.ApplyClass(texture,class)
 else texture:SetTexture(path);if texture.SetTexCoord then texture:SetTexCoord(0,1,0,1) end end
 return cue,status
end

-- These are display cues, not ranks or assumptions about trained spells.
-- Resolve the spell ID and texture together from the active client's data.
local prioritySpells={
 PALADIN={"Seal of Righteousness","Seal of Command","Seal of the Crusader","Seal of Fury","Judgement","Holy Strike","Holy Light","Flash of Light","Holy Shock","Oath of Light","Light’s Vigil","Righteous Fury","Holy Shield","Consecration","Exorcism","Cleanse","Hammer of Justice","Templar's Bulwark","Divine Shield","Unsealed Wrath","Blessing of Protection","Blessing of Freedom"},
 WARRIOR={"Pummel","Shield Bash","Hamstring","Battle Shout","Charge","Overpower","Mortal Strike","Rend","Slam","Execute","Bloodthirst","Whirlwind","Heroic Strike","Cleave","Bloodrage","Shield Block","Shield Slam","Revenge","Sunder Armor","Thunder Clap","Shield Wall","Death Wish","Recklessness","Taunt"},
 DRUID={"Rejuvenation","Regrowth","Swiftmend","Wild Growth","Healing Touch","Nature's Swiftness","Innervate","Rebirth","Tranquility","Rake","Rip","Shred","Claw","Shifting Power","Ferocious Bite","Moonfire","Insect Swarm","Starfire","Wrath","Eclipse","Maul","Swipe","Lacerate","Growl","Entangling Roots","Bash"},
 HUNTER={"Hunter's Mark","Serpent Sting","Summon Hawk","Arcane Shot","Aimed Shot","Bestial Wrath","Rapid Fire","Multi-Shot","Volley","Tranquilizing Shot","Raptor Strike","Mongoose Bite","Strider Kick","Immolation Trap","Explosive Trap","Sniper Shot","Auto Shot","Concussive Shot"},
 MAGE={"Pyroblast","Scorch","Fireball","Fire Blast","Frostfire Bolt","Living Bomb","Combustion","Arcane Blast","Arcane Missiles","Arcane Power","Evocation","Frostbolt","Ice Lance","Fingers of Frost","Frozen Orb","Blizzard","Arcane Explosion","Frost Nova","Cone of Cold","Polymorph","Counterspell","Blink"},
 PRIEST={"Power Word: Shield","Prayer of Mending","Flash Heal","Greater Heal","Prayer of Healing","Renew","Smite","Penance","Holy Binding","Shadow Word: Pain","Shadow Word: Death","Vampiric Touch","Mind Blast","Mind Flay","Devouring Plague","Fade","Power Infusion","Dispel Magic","Psychic Scream"},
 ROGUE={"Slice and Dice","Sinister Strike","Backstab","Eviscerate","Adrenaline Rush","Blade Flurry","Kick","Garrote","Mutilate","Rupture","Envenom","Shiv","Hemorrhage","Premeditation","Preparation","Vanish","Cheap Shot","Kidney Shot","Gouge"},
 SHAMAN={"Flame Shock","Earth Shock","Lava Burst","Lightning Bolt","Chain Lightning","Stormstrike","Lava Lash","Maelstrom Weapon","Lightning Shield","Healing Wave","Lesser Healing Wave","Chain Heal","Earth Shield","Riptide","Nature's Swiftness","Windfury Totem","Searing Totem","Fire Nova","Frost Shock","Tremor Totem"},
 WARLOCK={"Corruption","Bane of Agony","Shadow Bolt","Life Tap","Immolate","Conflagrate","Incinerate","Shadowburn","Soul Fire","Bane of Havoc","Demonic Brand","Demonic Empowerment","Metamorphosis","Drain Soul","Drain Life","Siphon Life","Hellfire","Rain of Fire","Fear"},
}
local function normalizedSpellName(value)
 return value:gsub("’","'"):lower()
end
function I.PrioritySpell(instruction,class)
 local api=type(C_Spell)=="table" and C_Spell.GetSpellInfo
 if type(api)~="function" then return nil end
 local caption=normalizedSpellName(instruction)
 local first,best,spellName
 for _,name in ipairs(prioritySpells[class] or {}) do
  local key=normalizedSpellName(name)
  local start=caption:find("%f[%w]"..key:gsub("(%W)","%%%1").."%f[%W]")
  if start and (not first or start<first or (start==first and #key>#best)) then
   first,best,spellName=start,key,name
  end
 end
 if not best then return nil end
 local ok,spell=pcall(api,(spellName:gsub("’","'")))
 if ok and type(spell)=="table" and type(spell.name)=="string"
  and normalizedSpellName(spell.name)==best
  and type(spell.spellID)=="number" and spell.spellID>0
  and type(spell.iconID)=="number" and spell.iconID>0 then
  return spell
 end
end
