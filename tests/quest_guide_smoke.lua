dofile('ForeverCompanion/QuestFieldGuide.lua')
dofile('ForeverCompanion/QuestTracker.lua')
local G,T=ForeverCompanionQuestFieldGuide,ForeverCompanionQuestTracker
local q={id=1,title='A sourced quest',objectives={'Wolves slain','Open the crate','Investigate'},objectiveStates={
 {known=true,done=false,current=1,required=3,kind='monster'},
 {known=true,done=true,current=1,required=1,kind='object'},
 {known=false,done=false},
}}
local targets={
 {map=1,x=.1,y=.2,source='Native quest POI'},
 {map=1,x=.2,y=.3,objectiveIndex=1,reference=true},
 {map=1,x=.2,y=.3,objectiveIndex=1,reference=true},
 {map=1,x=.4,y=.4,objectiveIndex=2,reference=true},
 {map=1,x=0/0,y=.4,objectiveIndex=3,reference=true},
}
local steps=G.Steps(q,targets)
assert(#steps==3 and #steps[1].targets==1 and #steps[2].targets==0 and #steps[3].targets==0)
assert(steps[1].ratio==1/3 and steps[2].ratio==1 and steps[3].ratio==nil)
assert(not steps[1].done and steps[2].done and not steps[3].known)
assert(steps[1].targets[1].reference,'general native POI must not masquerade as objective-specific data')
local done,total,known=G.Progress(q);assert(done==1 and total==3 and known==2)
assert(#G.Steps(nil,{})==0)
q.complete=true;targets[#targets+1]={map=1,x=.5,y=.6,kind='turn-in',reference=true}
steps=G.Steps(q,targets);assert(#steps==1 and steps[1].turnin and #steps[1].targets==1)
q.complete=false
local other={id=2,title='Ready',complete=true,zone='Other',zoneKnown=true}
local localQuest={id=3,title='Local',complete=false,zone='Here',zoneKnown=true,objectives={'First','Second','Third'},objectiveStates={{known=true,done=true},{known=true,done=false}}}
q.complete=false;q.zone='Other';q.zoneKnown=true
local ordered=T.Order({q,localQuest,other},'all','Here',function(quest) return quest==q end)
assert(ordered[1].quest==q and ordered[2].quest==other and ordered[3].quest==localQuest)
assert(#T.Order({q,localQuest,other},'ready','Here',function() return false end)==1)
assert(#T.Order({q,localQuest,other},'pinned','Here',function(quest) return quest==q end)==1)
assert(T.Preview(localQuest)=='Second\nThird','tracker shows unfinished objectives and retains unknown states')
assert(T.Preview(other):find('Ready to turn in',1,true))
dofile('ForeverCompanion/QuestWaypoints.lua')
local reference={map=100,x=.3,y=.4,objectiveIndex=1,source='QuestieDB npc'}
ForeverCompanionQuestLocations={ForQuest=function() return {reference,reference} end}
C_Map={GetBestMapForUnit=function() return 100 end}
C_QuestLog={GetNextWaypoint=function() return 200,.1,.2 end,GetQuestsOnMap=function() return {{questID=1,mapID=100,isQuestStart=false,x=.2,y=.4}} end}
local destinations=ForeverCompanionQuestWaypoints.Targets(q)
assert(#destinations==3,'collect cross-map native waypoint, current-map native POI and matched reference')
assert(destinations[1].reference==false and destinations[3].reference==true and destinations[3].objectiveIndex==1)
assert(reference.reference==nil,'provider records must remain unchanged')
assert(#ForeverCompanionQuestWaypoints.Targets(nil)==0)
print('PASS: objective-specific targets, progress unknowns, completed removal, turn-ins, tracker priorities and remaining-objective previews')

local found=T.Search({{quest={id=173,title='Worgen in the Woods',zone='Duskwood',objectives={'Nightbane Shadow Weaver'}}},{quest={id=221,title='Worgen in the Woods',zone='Duskwood',objectives={'Nightbane Dark Runner'}}}},'173')
assert(#found==1 and found[1].quest.id==173,'quest search distinguishes identically named chain parts')
