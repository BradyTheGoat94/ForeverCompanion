dofile('ForeverCompanion/Journey.lua')
local a,b,c={title='Objective'},{title='Turn in',complete=true},{title='Pinned'}
ForeverCompanionQuestPlanner={IsPinned=function(q) return q==c end}
local locations={
 {quest=a,target={x=.11,y=.1}},
 {quest=a,target={x=.7,y=.7}},
 {quest=b,target={x=.2,y=.1}},
 {quest=c,target={x=.8,y=.8}},
 {quest={title='Not live'},target={x=.1,y=.1}},
}
local j=ForeverCompanionJourney
local route=j.LocalRoute({a,b,c},locations,.1,.1,5)
assert(#route==3 and route[1].quest==c and route[2].quest==b and route[3].quest==a)
assert(route[3].target==locations[1].target,'choose nearest reported alternative')
assert(#j.LocalRoute({a,b,c},locations,nil,nil)==0,'unknown position cannot invent route')
assert(#j.LocalRoute({a,b,c},locations,0/0,.1)==0,'invalid position rejected')
ForeverCompanionQuestPlanner.IsPinned=function() return false end
b.complete=false
assert(j.LocalRoute({a,b,c},locations,.1,.1,1)[1].quest==a,'closest objective when priorities match')
dofile('ForeverCompanion/QuestDiscovery.lua')
local pickups={
 {quest={id=1,title='Far client'},target={map=1,x=.7,y=.7}},
 {quest={id=2,title='Near client'},target={map=1,x=.1,y=.1}},
 {quest={id=2,title='Near client'},target={map=1,x=.9,y=.9}},
 {quest={id=3,title='Reference'},target={map=1,x=.11,y=.1},reference=true},
}
local nextPickups=j.PickupStops(pickups,.1,.1,3)
assert(#nextPickups==3 and nextPickups[1].quest.id==2 and nextPickups[2].quest.id==1 and nextPickups[3].reference)
assert(nextPickups[1].pickup and nextPickups[1].target.x==.1)
assert(#j.PickupStops({},nil,nil,3)==0)
dofile('ForeverCompanion/LevelingCurriculum.lua')
assert(ForeverCompanionLevelingCurriculum.TravelPlan(1):find('FIRST TRIP',1,true))
assert(not ForeverCompanionLevelingCurriculum.TravelPlan(30):find('FIRST TRIP',1,true))
print('PASS: live quest stops, pin/turn-in priorities, deduplication, alternatives, unknown positions, beginner guidance')
