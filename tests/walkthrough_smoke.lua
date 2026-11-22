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
local buttons,labels={},{}
local noop=function() end
local function widget()
 local w={shown=true}
 return setmetatable(w,{__index=function(_,key)
  if key=='SetText' then return function(self,v) self.text=v end end
  if key=='SetScript' or key=='HookScript' then return function(self,k,v) self[k]=v end end
  if key=='SetShown' then return function(self,v) self.shown=v end end
  if key=='IsShown' then return function(self) return self.shown end end
  if key=='Show' then return function(self) self.shown=true end end
  if key=='Hide' then return function(self) self.shown=false end end
  return noop
 end})
end
CreateFrame=widget;UIParent=widget()
ForeverCompanionInterface={Text=function() local t=widget();labels[#labels+1]=t;return t end,Button=function() local b=widget();buttons[#buttons+1]=b;return b end,Surface=noop,PreparePanel=noop,CloseButton=noop,SetHoverHelp=noop}
UnitLevel=function() return 36 end;UnitRace=function() return 'Human','Human',1 end;UnitFactionGroup=function() return 'Alliance' end
C_Map={GetBestMapForUnit=function() return 2548 end}
C_QuestLog={IsQuestFlaggedCompleted=function() return false end}
ForeverCompanionQuestLocations={Provider=noop}
ForeverCompanionQuestPlanner={IsSupported=function() return true end,GetLive=function() return {} end}
local active,navFails
ForeverCompanionQuestWaypoints={
 MapPickups=function() return {} end,
 Active=function() return active end,
 Clear=function() active=nil end,
 Navigate=function(t,_,title)
  assert(t.map==2548)
  if navFails then return 'Unavailable' end
  active={label=title,map=t.map,x=t.x,y=t.y};return 'ok'
 end,
}
ForeverCompanionAvailableQuests={Status=function() return {} end}
SlashCmdList.FCWALKTHROUGH()
local function click(name) for _,b in ipairs(buttons) do if b.text==name then b.OnClick(b);return end end;error(name) end
assert(G.steps[1].id==94613);click('Directions');click('Skip quest');assert(G.steps[1].id~=94613)
click('Restore skipped');click('Follow: off');click('Follow: on')
local upcoming
for _,t in ipairs(labels) do
 if type(t.text)=='string' and t.text:find('UP NEXT',1,true)==1 then upcoming=t;break end
end
assert(upcoming,'the upcoming section is labelled')
click('Compact');assert(not upcoming.shown,'compact mode hides the upcoming header')
click('Expand');assert(upcoming.shown,'expanding restores the upcoming header')
click('Follow: off');assert(active and active.label==G.steps[1].title)
local manual={label='Manual pin',map=2548,x=.3,y=.5}
active=manual;G.Refresh()
assert(active==manual,'a manual pin pauses Follow even when the guide step stays the same')
click('Follow: off');assert(active~=manual)
navFails=true;click('Skip quest')
assert(active==nil,'unavailable next waypoint clears the previous guide arrow')


local context={level=36,map=2548,x=.50,y=.50,side='Alliance',active={{id=94614,title='Freshwater Fiends',complete=true}},
 location=function() return {map=2548,x=.90,y=.90,label='Distant return'} end,
 pickups={{quest={id=998,title='At this camp'},target={map=2548,x=.51,y=.50}},
 {quest={id=999,title='Next to the first giver'},target={map=2548,x=.52,y=.50}}},
 skip={},completed=function() return false end,catalogReady=true}
local route=G.Build(chapter,context)
assert(route[1].id==998 and route[1].neighbors==1,'Collect nearby quests before a long return trip')
context.focus=94614
assert(G.Build(chapter,context)[1].id==94614,'Player-selected destination retains priority')

context.focus=nil;context.active={}
local function pickup(x,ref) return {quest={id=998,title='Multiple givers'},target={map=2548,x=x,y=.5},reference=ref} end
for _,entries in ipairs({{pickup(.9),pickup(.51)},{pickup(.51),pickup(.9)}}) do
 context.pickups=entries;local steps=G.Build(chapter,context)
 assert(#steps==1 and steps[1].target.x==.51,'Nearest native offer wins in either order')
end
context.pickups={pickup(.501,true),pickup(.65,false)}
assert(G.Build(chapter,context)[1].target.x==.65,'Native offer takes precedence over a reference spawn')
context.pickups={};context.active={{id=94614,title='Freshwater Fiends',complete=true}}
context.location=function() return {map=2548,x=.9,y=.9,kind='pickup'} end
assert(G.Build(chapter,context)[1].target.label=='Benjy Wheeler','Completed quest uses the turn-in contact')

context.active={{id=94614,title='Freshwater Fiends',complete=true},{id=94613,title='My Kingdom for a Horse',complete=true}}
context.location=function(q) return {map=2548,x=q.id==94614 and .574 or .575,y=.5} end
context.pickups={pickup(.50)};context.focus=nil
context.remainingXP=500;context.rewardXP=function() return 300 end
local ding=G.Build(chapter,context)[1]
assert(ding.action=='Turn in' and ding.ding and ding.hubXP==600)
context.remainingXP=601;assert(G.Build(chapter,context)[1].id==998)
context.remainingXP=10;context.rewardXP=function() end;assert(G.Build(chapter,context)[1].id==998)
context.rewardXP=function() return 300 end;context.location=function() return {map=2548,x=.95,y=.95} end
assert(G.Build(chapter,context)[1].id==998,'No cross-zone detour for a level')

context.logFull=true
for _,step in ipairs(G.Build(chapter,context)) do assert(step.rank<=2,'Full quest log only offers active work') end
assert(G.Build(chapter,context)[1].action=='Turn in')
context.logFull=false;assert(G.Build(chapter,context)[1].id==998,'Pickup returns when space opens')

local isle=G.Chapter(4,2521,'Horde','Skyborne')
local sky={level=4,bit=8589934592,side='Horde',class='WARRIOR',active={},skip={},pickups={},completed=function() return false end}
local function offered(id)
 for _,step in ipairs(G.Build(isle,sky)) do if step.id==id then return true end end
 return false
end
assert(not offered(92466))
sky.class='SHAMAN';assert(offered(92466) and not offered(92467))
sky.completed=function(id) return id==92466 end
assert(offered(92467) and not offered(92468))
assert(chapter[3]==44)

local zoneContext={level=36,bit=1,side='Alliance',active={},completed=function() return false end}
local starters=G.ZoneStarts(2548,zoneContext)
assert(#starters==1 and starters[1].quest.id==94613 and starters[1].zoneStart)
zoneContext.level=35
assert(#G.ZoneStarts(2548,zoneContext)==0)
zoneContext.level=36;zoneContext.side='Horde';zoneContext.bit=2
starters=G.ZoneStarts(2548,zoneContext)
assert(#starters==1 and starters[1].quest.id==93787)
zoneContext.active={{id=93787}}
assert(#G.ZoneStarts(2548,zoneContext)==0)
zoneContext.active={};zoneContext.completed=function() return true end
assert(#G.ZoneStarts(2548,zoneContext)==0)
