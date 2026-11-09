dofile('ForeverCompanion/QuestFieldGuide.lua')
dofile('ForeverCompanion/ObjectiveRoute.lua')
local r=ForeverCompanionObjectiveRoute
local a={id=1,title='Several objectives',objectives={'Finished','Collect supplies','Speak to scout'},objectiveStates={{known=true,done=true},{known=true,done=false},{known=false}}}
local b={id=2,title='Return',complete=true}
local c={id=3,title='Other zone',objectives={'Other objective'}}
local d={id=4,title='Unmatched',objectives={'Unmatched objective'}}
local e={id=5,title='No objective details'}
local function point(map,x,index,kind) return {map=map,x=x,y=.1,objectiveIndex=index,kind=kind} end
local data={
 [a]={point(1429,.11,1),point(1429,.4,2),point(1429,.2,2),point(1429,.3,3),point(1429,.01,nil)},
 [b]={point(1429,.6,nil,'turn-in')},[c]={point(1430,.2,1)},[d]={point(1429,.01,nil)},
}
local stops,stats=r.Build({a,b,c,d,e},data,1429,.1,.1,function(q) return q==a end)
assert(#stops==3 and stops[1].quest==a and stops[1].objectiveIndex==2 and stops[1].target.x==.2)
assert(stops[2].objectiveIndex==3 and stops[3].turnin,'multiple unfinished objectives and separate turn-in stops')
assert(stats.remaining==5 and stats.matched==3 and stats.unlocated==1 and stats.otherMaps==1 and stats.unknownQuests==1)
assert(stats.positionKnown)
local skip={[r.StepKey(stops[1])]=true}
local remaining,deferred=r.Build({a,b},data,1429,.1,.1,nil,{deferred=skip})
assert(#remaining==2 and deferred.deferred==1 and not a.objectiveStates[2].done,'set-aside planning never marks a quest objective complete')
local pinned,filtered=r.Build({a,b,c,d,e},data,1429,.1,.1,function(q) return q==a end,{filter='pinned'})
assert(#pinned==2 and filtered.excluded==4 and pinned[1].quest==a,'pinned filter retains every unfinished matched step')
local turnins=r.Build({a,b},data,1429,.1,.1,nil,{filter='turnin'})
assert(#turnins==1 and turnins[1].turnin)
local selected=r.Build({a,b},data,1429,.1,.1,nil,{filter='selected',selected={id=1}})
assert(#selected==2 and selected[1].quest==a,'focused quest filter survives replacement snapshots')
assert(#r.Build({a,b},data,1429,.1,.1,nil,{filter='selected'})==0,'no focused quest cannot expand to all quests')
local log=r.Build({a},data,1429,.1,.1,nil,{order='log'})
assert(log[1].target.x==.4,'quest-log ordering does not silently apply nearest-location ordering')
local unordered,unknown=r.Build({a,b},data,1429,nil,nil)
assert(not unknown.positionKnown and unordered[1].quest==b,'unknown position preserves priority, without claiming distance order')
local q,index,target=r.Resolve(stops[1],{a,b},function(quest) return data[quest] or {} end)
assert(q==a and index==1 and target.x==.2)
a.objectiveStates[2].done=true
assert(r.Resolve(stops[1],{a,b},function(quest) return data[quest] or {} end)==nil,'completed objectives reject old navigation')
a.objectiveStates[2].done=false
assert(r.Resolve(stops[1],{a,b},function() return {} end)==nil,'removed targets reject old navigation')
assert(r.Resolve(stops[3],{a},function() return {} end)==nil,'removed quests reject old navigation')
local many={id=6,title='Large fixture',objectives={}}
local targets={}
for i=1,45 do many.objectives[i]='Objective '..i;targets[i]=point(1429,.2,i) end
local bounded,coverage=r.Build({many},{[many]=targets},1429,.1,.1)
assert(#bounded==40 and coverage.matched==45,'bounded route must retain true coverage count')
ForeverCompanionDB={}
local supported=true
ForeverCompanionQuestPlanner={IsSupported=function() return supported end,GetLive=function() return {a,b} end,IsPinned=function() return false end,GetSelected=function() return a end,Select=function(i) assert(i==1) end}
local destination,showMap
ForeverCompanionQuestWaypoints={Targets=function(q) return data[q] or {} end,Navigate=function(t,open) destination=t;showMap=open;return 'Navigating' end}
C_Map={GetBestMapForUnit=function() return 1429 end,GetPlayerMapPosition=function() return {GetXY=function() return .1,.1 end} end}
assert(r.NavigateNext(a)=='Navigating' and destination.x==.2 and showMap==false,'tracker action navigates the live matched objective without forcing map open')
assert(r.NavigateNext(a,{map=1429,x=.2,y=.1})=='Navigating' and destination.x==.3,'manual advance excludes current destination without changing progress')
assert(r.SetAside(stops[1]));r.NavigateNext(a)
assert(destination.x==.3,'set-aside objective is skipped by Next objective')
assert(not a.objectiveStates[2].done,'setting aside leaves live progress untouched')
r.RestoreDeferred();r.NavigateNext(a);assert(destination.x==.2)
assert(r.SetAside(stops[1]));a.objectiveStates[2].done=true;r.NavigateNext(a)
a.objectiveStates[2].done=false;r.NavigateNext(a);assert(destination.x==.2,'completed steps release their temporary set-aside keys')
supported=false;destination=nil
r.NavigateNext(a);assert(destination==nil,'unavailable live snapshot cannot start navigation')
print('PASS: objective itinerary matching, completed removal, multiple steps, unknown positions, missing coverage, stale navigation and bounded work')

local distant={id=99,title='Travel reference',objectives={'Hunt'},objectiveStates={{known=true,kind='monster'}}}
local mixed={point(1429,.1,1),point(1430,.2,1)}
local uncertain,review=r.Build({distant},{[distant]=mixed},1429,.1,.1)
assert(#uncertain==0 and review.review==1,'cross-map objective references require a deliberate area choice')
mixed[2]=point(1429,.9,1)
assert(#r.Build({distant},{[distant]=mixed},1429,.1,.1)==0,'distant spawn clusters cannot be selected automatically')
