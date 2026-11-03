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
  if type(icon)=="string" and icon~="" then return icon end
 end)
 return ok and value or nil
end
function I.ApplyRotation(texture,class,mode,index)
 local path,cue,status=ForeverCompanionRotationCardIcon(class,mode,index)
 if status=="class" then I.ApplyClass(texture,class)
 else texture:SetTexture(path);texture:SetTexCoord(0,1,0,1) end
 return cue,status
end
