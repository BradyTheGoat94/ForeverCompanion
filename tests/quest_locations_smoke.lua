-- Contract tests for location data read from an independently installed provider.
dofile("ForeverCompanion/QuestLocations.lua")
local R=ForeverCompanionQuestLocations
C_Map={GetMapInfo=function(map)
 return ({[1429]={mapType=3},[947]={mapType=1},[310]={mapType=4}})[map]
end}
local function named(value) return function() return value end end
local spawns={[12]={{42,65},{51,65,9},{-1,-1}},[13]={{1,1}},[14]={{22,22}}}
LibQuestieDB={
 RequireContract=function(version) return version==1 end,
 ModeIndicator={GetStatus=named({expansion="Forever"})},
 Support={Get=named({private={areaIdToUiMapId="return {[12]=1429,[13]=947,[14]=310,}"}})},
 Quest={name=named("A Test Quest"),finishedBy=named({{1}}),
  objectives=named({{{1}},{{3}},{{2}}}),
  triggerEnd=named({"Scout the mine",{[12]={{63,65}}}})},
 Npc={name=function(id) return id==1 and "Forest Wolf" or "River Crawler" end,spawns=named(spawns)},
 Object={name=named("Supply Crate"),spawns=named({[12]={{20,21}}})},
 Item={name=named("Wolf Tooth"),npcDrops=named({2})},
}
local quest={id=11,title="A Test Quest",objectives={"Forest Wolves slain: 0/5","Wolf Tooth: 0/2","Supply Crate: 1/1","Scout the mine"},
 objectiveStates={{known=true,kind="monster",required=5},{known=true,kind="item",required=2},
  {known=true,done=true,kind="object",required=1},{known=true,kind="event"}}}
local points=R.ForQuest(quest)
assert(#points==3,"kill, item and event locations must be found, while invalid maps and phases are excluded")
assert(points[1].map==1429 and points[1].x==.42 and points[1].label=="Forest Wolf")
assert(points[2].kind=="drop" and points[2].label=="River Crawler")
assert(points[3].kind=="event" and points[3].x==.63)
assert(points[1].objectiveIndex==1 and points[2].objectiveIndex==2 and points[3].objectiveIndex==4,'provider matches preserve the exact live objective index')
quest.objectiveStates[1].done=true
quest.objectives[2]="Something unrelated"
assert(#R.ForQuest(quest)==1,"completed and unmatched objectives must disappear")
quest.complete=true
points=R.ForQuest(quest)
assert(#points==1 and points[1].kind=="turn-in")
quest.title="Wrong live quest"
assert(#R.ForQuest(quest)==0,"same ID with a different title must be skipped")
LibQuestieDB.ModeIndicator.GetStatus=named({expansion="Vanilla"})
assert(not R.IsAvailable(),"Era data cannot be used on Forever")
print("PASS: Forever quest objective matching, progress, turn-in, map types, phase and flavor guards")
