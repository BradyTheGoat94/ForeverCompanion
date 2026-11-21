dofile('ForeverCompanion/ZoneBriefing.lua')
local B=ForeverCompanionZoneBriefing
local types={World=1,Continent=2,Zone=3}
assert(B.Tier(1,types,0,true)=='overview')
assert(B.Tier(2,types,1,true)=='overview')
assert(B.Tier(3,types,.2,true)=='zone' and B.Tier(3,types,.75,true)=='detail')
assert(B.Tier(2,types,0,false)=='detail' and B.Tier(nil,types,nil,true)=='detail')
local function entry(id,x,pickup,starter,complete,map)
 return {quest={id=id,title='Quest '..id,complete=complete},target={map=map or 2548,x=x,y=.3},pickup=pickup,zoneStart=starter}
end
local active=entry(1,.8,false,false,false)
local ret=entry(2,.9,false,false,true)
local starter=entry(3,.7,true,true)
local nearby=entry(4,.1,true)
local wrong=entry(5,.1,false,false,true,12)
assert(B.Choose(2548,{wrong},{nearby,starter},.1,.3)==starter)
assert(B.Choose(2548,{active},{starter},.1,.3)==active)
assert(B.Choose(2548,{active,ret},{starter},.1,.3)==ret)
assert(B.Choose(2548,{wrong},{})==nil)
assert(B.Choose(2548,{}, {entry(9,1.3,true)})==nil)
assert(B.Choose(2548,{}, {nearby,entry(6,.2,true)},.19,.3).quest.id==6)
starter.reference=true
assert(B.Reason(starter):find('Confirm availability',1,true))
assert(B.Reason(ret)=='Ready to turn in')

local action,navigated
local function noop() end
local function widget()
 return {SetSize=noop,SetPoint=noop,SetFrameLevel=noop,GetFrameLevel=function() return 1 end,
  SetWidth=noop,SetHeight=noop,SetWordWrap=noop,SetText=noop,Show=noop,Hide=noop,SetEnabled=noop,
  SetScript=function(_,_,fn) action=fn end}
end
CreateFrame=widget
ForeverCompanionInterface={Text=widget,Button=widget,Surface=noop,palette={}}
ForeverCompanionQuestWaypoints={
 SameTarget=function(a,b) return a.map==b.map and a.x==b.x and a.y==b.y end,
 Navigate=function(_,_,_,questID) navigated=questID;return 'Directions set' end,
}
local current=active
B.Show(widget(),2548,'Riverglades',active,'',function() return current end)
action();assert(navigated==1)
current=ret;navigated=nil;action();assert(navigated==nil,'stale briefing must not navigate')
B.Hide();action();assert(navigated==nil,'hidden briefing must not navigate')
print('PASS: zoom tiers, quest priority, source labels and stale briefing guards')
