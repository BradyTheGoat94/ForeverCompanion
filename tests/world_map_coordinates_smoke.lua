CreateFrame=function() return {RegisterEvent=function() end,SetScript=function() end} end
Enum={UIMapType={Zone=3,Continent=2}}
C_Map={
 GetBestMapForUnit=function() return 10 end,
 GetMapInfo=function(id) return {mapType=id==11 and 2 or 3,name='Zone '..id} end,
 GetMapLevels=function(id) if id~=12 then return 36,44 end end,
}
local shown,id,over=true,13,true
local x,y=.35,.97
WorldMapFrame={
 IsShown=function() return shown end,
 GetMapID=function() return id end,
 ScrollContainer={
  IsMouseOver=function() return over end,
  GetNormalizedCursorPosition=function() return x,y end,
 },
}
local target
ForeverCompanionQuestWaypoints={Navigate=function(t) target=t;return 'Started' end}
dofile('ForeverCompanion/QuestMap.lua')
local m=ForeverCompanionQuestMap
local cx,cy=m.CursorCoordinates(WorldMapFrame)
assert(cx==.35 and cy==.97)
x=-.01;assert(m.CursorCoordinates(WorldMapFrame)==nil)
x=.35;over=false;assert(m.CursorCoordinates(WorldMapFrame)==nil)
assert(m.ZoneLevelText(10)=='Lv. 36-44')
assert(m.ZoneLevelText(11)==nil and m.ZoneLevelText(12)==nil)
assert(m.GoToCoordinates('42.5 67.1')=='Started' and target.map==13 and target.x==.425)
shown=false
assert(m.GoToCoordinates('0,100')=='Started' and target.map==10 and target.x==0 and target.y==1)
target=nil;assert(m.GoToCoordinates('100.1 10'):find('Enter',1,true) and target==nil)
shown=true;id=11
assert(m.GoToCoordinates('10 10'):find('Choose a zone',1,true) and target==nil)
print('PASS: map coordinates, unavailable cursor, level labels and validated coordinate destinations')
