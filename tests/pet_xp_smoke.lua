local frames,labels={},{}
local function noop() end
local function widget()
 return setmetatable({}, {__index=function(_,key)
  if key=='SetScript' then return function(self,event,fn) self[event]=fn end end
  if key=='SetText' then return function(self,value) self.text=value end end
  if key=='Show' then return function(self) self.shown=true end end
  if key=='Hide' then return function(self) self.shown=false end end
  if key=='CreateTexture' then return widget end
  if key=='SetValue' then return function(self,x) self.value=x end end
  return noop
 end})
end
CreateFrame=function()
 local frame=widget()
 frames[#frames+1]=frame
 return frame
end
ForeverCompanionHunterGuide={
 Read=function(fn,...) if fn then return fn(...) end end,
 Finite=function(x) return type(x)=='number' and x==x and math.abs(x)<math.huge end,
}
local hunter,hasPet=true,true
local xp,required,level=100,200,30
UnitClass=function() return 'Test',hunter and 'HUNTER' or 'MAGE' end
UnitExists=function() return hasPet end
local guid='pet-one'
UnitGUID=function(unit) return unit=='player' and 'Player-1' or guid end
UnitName=function() return 'Wolf' end
UnitLevel=function() return level end
GetPetExperience=function() return xp,required end
ForeverCompanionDB={}
ForeverCompanionInterface={
 palette={},Surface=noop,CloseButton=widget,
 Text=function() local t=widget();labels[#labels+1]=t;return t end,
}
dofile('ForeverCompanion/PetXPTracker.lua')
local function fire(event,...) frames[1].OnEvent(frames[1],event,...) end
fire('PLAYER_ENTERING_WORLD')
assert(frames[2].shown and labels[1].text:find('Wolf',1,true))
assert(labels[2].text=='100 / 200 XP  |  50.0%' and frames[3].value==100)
assert(labels[4].text=='Confirmed kills this level: 0')
fire('PARTY_KILL','Player-1','Creature-1')
fire('PARTY_KILL','pet-one','Creature-2')
fire('PARTY_KILL','Player-other','Creature-3')
fire('PARTY_KILL','Player-1','Player-2')
assert(labels[4].text=='Confirmed kills this level: 2')
xp=150;fire('UNIT_PET_EXPERIENCE','pet')
assert(labels[2].text=='150 / 200 XP  |  75.0%' and frames[3].value==150)
assert(labels[3].text=='~1 kill to level')
fire('UNIT_PET_EXPERIENCE','pet')
assert(labels[3].text=='~1 kill to level','duplicate XP events do not count')
xp=160;fire('UNIT_PET_EXPERIENCE','pet')
assert(labels[3].text=='~2 kills to level')
guid='pet-two';xp=175;fire('UNIT_PET','player')
assert(labels[4].text=='Confirmed kills this level: 0')
assert(labels[3].text=='Kills to level: waiting for pet XP')
xp=180;fire('UNIT_PET_EXPERIENCE','pet')
assert(labels[3].text=='~4 kills to level')
fire('PARTY_KILL','pet-two','Creature-3')
assert(labels[4].text=='Confirmed kills this level: 1')
level=31;xp=5;required=300;fire('UNIT_LEVEL','pet')
assert(labels[4].text=='Confirmed kills this level: 0')
assert(labels[3].text=='Kills to level: waiting for pet XP')

hasPet=false;fire('UNIT_PET','player');assert(frames[2].shown==false)
hasPet=true;level=60;required=0;fire('UNIT_PET','player')
assert(frames[2].shown and labels[2].text=='Pet at max level')
ForeverCompanionPetXPTracker.Toggle()
assert(ForeverCompanionDB.petXPHidden and not frames[2].shown)
ForeverCompanionPetXPTracker.Toggle()
assert(frames[2].shown)
hunter=false;fire('PLAYER_ENTERING_WORLD');assert(not frames[2].shown)
print('PASS: Hunter pet XP display, events, pet changes, level cap and visibility')
