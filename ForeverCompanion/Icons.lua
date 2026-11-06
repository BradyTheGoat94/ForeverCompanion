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

-- Read spell identity and artwork together from the active client.
function I.SpellDetails(name,referenceID)
 if type(name)~="string" then return nil end
 local api=type(C_Spell)=="table" and C_Spell.GetSpellInfo
 if type(api)~="function" then return nil end
 local query=(name:gsub("’","'"))
 local function valid(spell)
  return type(spell)=="table" and type(spell.name)=="string"
   and type(spell.spellID)=="number" and spell.spellID>0
   and type(spell.iconID)=="number" and spell.iconID>0
 end
 local ok,spell=pcall(api,query)
 if ok and valid(spell) and spell.name:gsub("’","'"):lower()==query:lower() then return spell end
 if referenceID then
  ok,spell=pcall(api,referenceID)
  if ok and valid(spell) and spell.spellID==referenceID then return spell end
 end
end
