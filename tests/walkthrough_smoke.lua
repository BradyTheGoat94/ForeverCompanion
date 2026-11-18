SlashCmdList={}
CreateFrame=function() return {RegisterEvent=function() end,SetScript=function() end} end
dofile('ForeverCompanion/WalkthroughData.lua')
dofile('ForeverCompanion/WalkthroughForever.lua')
dofile('ForeverCompanion/Walkthrough.lua')
local G=ForeverCompanionWalkthrough
local ids={}
for _,r in ipairs(ForeverCompanionWalkthroughRecords) do
 assert(not ids[r[1]],'Duplicate quest '..r[1]);ids[r[1]]=true
 for _,p in ipairs({r[6],r[7]}) do assert(type(p[1])=='string' and p[3]>=0 and p[3]<=100 and p[4]>=0 and p[4]<=100) end
end
for _,side in ipairs({'Alliance','Horde'}) do for level=1,60 do
 local chapter=G.Chapter(level,nil,side,side=='Alliance' and 'Human' or 'Orc')
 assert(chapter[2]<=level and chapter[3]>=level,side..' '..level)
end end
local chapter=G.Chapter(36,2548,'Alliance','Human')
local completed={}
local ctx={level=36,bit=1,active={},pickups={},skip={},completed=function(id) return completed[id]==true end}
local list=G.Build(chapter,ctx);assert(list[1].id==94613)
ctx.level=35;assert(G.Chapter(35,2548,'Alliance','Human')==chapter and #G.Build(chapter,ctx)==0)
assert(G.ChapterTip(chapter,'Alliance',35):find('Return at level 36',1,true))
ctx.level=36
local horde={level=36,bit=2,side='Horde',active={},pickups={},skip={},completed=function() return false end}
local steps=G.Build(chapter,horde);assert(steps[1].id==93787 and steps[1].target.label=="Krom'rosh")
for _,step in ipairs(steps) do assert(step.id~=94613 and step.id~=94999) end
completed[94613]=true;for _,s in ipairs(G.Build(chapter,ctx)) do assert(s.id~=94613 and s.id~=95913) end
ForeverCompanionLevelingPlan={NextStep=function() return 'Finish the current objective' end}
ctx.active={{id=94614,title='Freshwater Fiends',zone='Riverglades'}};ctx.location=function() end
assert(G.Build(chapter,ctx)[1].action=='Objective')
ctx.active[1].complete=true;local turn=G.Build(chapter,ctx)[1];assert(turn.action=='Turn in' and turn.target.label=='Benjy Wheeler')
ctx.skip[94614]=true;assert(G.Build(chapter,ctx)[1].id~=94614)
ctx.catalogReady=true;ctx.pickups={{quest={id=777,title='Native pickup'},target={map=2548,x=.5,y=.5}}}
assert(#G.Build(chapter,ctx)==1 and G.Build(chapter,ctx)[1].id==777)
print('Walkthrough data, 120 level/faction cases, resume, objectives, turn-in, skips and live pickups passed.')
local buttons={}
local noop=function() end
local function widget()
 local w={shown=true}
 return setmetatable(w,{__index=function(_,key)
  if key=='SetText' then return function(self,v) self.text=v end end
  if key=='SetScript' or key=='HookScript' then return function(self,k,v) self[k]=v end end
  if key=='IsShown' then return function(self) return self.shown end end
  if key=='Show' then return function(self) self.shown=true end end
  if key=='Hide' then return function(self) self.shown=false end end
  return noop
 end})
end
CreateFrame=widget;UIParent=widget()
ForeverCompanionInterface={Text=widget,Button=function() local b=widget();buttons[#buttons+1]=b;return b end,Surface=noop,PreparePanel=noop,CloseButton=noop}
UnitLevel=function() return 36 end;UnitRace=function() return 'Human','Human',1 end;UnitFactionGroup=function() return 'Alliance' end
C_Map={GetBestMapForUnit=function() return 2548 end}
C_QuestLog={IsQuestFlaggedCompleted=function() return false end}
ForeverCompanionQuestLocations={Provider=noop}
ForeverCompanionQuestPlanner={IsSupported=function() return true end,GetLive=function() return {} end}
ForeverCompanionQuestWaypoints={MapPickups=function() return {} end,Active=noop,Navigate=function(t) assert(t.map==2548);return 'ok' end}
ForeverCompanionAvailableQuests={Status=function() return {} end}
SlashCmdList.FCWALKTHROUGH()
local function click(name) for _,b in ipairs(buttons) do if b.text==name then b.OnClick(b);return end end;error(name) end
assert(G.steps[1].id==94613);click('Directions');click('Skip quest');assert(G.steps[1].id~=94613)
click('Restore skipped');click('Follow: off');click('Follow: on')
click('Compact');click('Expand')

