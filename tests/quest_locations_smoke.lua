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

LibQuestieDB.ModeIndicator.GetStatus=named({expansion='Forever'})
local chain={[173]={'Nightbane Shadow Weaver',533},[221]={'Nightbane Dark Runner',205},[222]={'Nightbane Vile Fang',206}}
LibQuestieDB.Quest.name=named('Worgen in the Woods')
LibQuestieDB.Quest.objectives=function(id) return {{{chain[id][2],nil,6}}} end
LibQuestieDB.Npc.name=function(id) for _,r in pairs(chain) do if r[2]==id then return r[1] end end end
for id,r in pairs(chain) do
 local q={id=id,title='Worgen in the Woods',objectives={r[1]..' slain: 0/6'},objectiveStates={{known=true,kind='monster',required=6}}}
 local locations=R.ForQuest(q);assert(#locations==1 and locations[1].entityID==r[2],'chain parts must resolve their own exact objective identity')
end
local q={id=173,title='Worgen in the Woods',objectives={'Nightbane Shadow Weaver slain: 0/6'},objectiveStates={{known=true,kind='monster',required=6}}}
local t=R.ForQuest(q)[1];ForeverCompanionDB={}
assert(not R.IsReported(q,t));R.Report(q,t);assert(R.IsReported(q,t));R.Report(q,t)
assert(#ForeverCompanionDB.questLocationReports==1,'duplicate reports do not grow storage')
assert(not R.IsReported({id=221},t),'same-title followup is not excluded')
assert(R.ReportText(q):find('Quest #173',1,true) and R.ReportText(q):find('533',1,true))
R.Restore(q);assert(not R.IsReported(q,t))
print('PASS: Worgen chain identity and reversible local location reports (synthetic coordinates, not live verification)')

local eventQuest={id=7905}
C_DateAndTime={GetCurrentCalendarTime=function() return {year=2026,month=11,monthDay=9} end}
assert(R.EventArea(eventQuest)==12)
assert(R.AllowsLocation(eventQuest,{map=1429,areaID=12}) and not R.AllowsLocation(eventQuest,{map=1412,areaID=215}),'Faire references respect the current event camp')
assert(R.AllowsLocation(eventQuest,{map=1429}) and not R.AllowsLocation(eventQuest,{map=1412}),'stale native cross-continent points are rejected too')
C_DateAndTime.GetCurrentCalendarTime=function() return {year=2026,month=12,monthDay=9} end
assert(R.EventArea(eventQuest)==nil and R.AllowsLocation(eventQuest,{map=1412}),'event-specific rule expires instead of hardcoding Alliance forever')
C_DateAndTime=nil

C_DateAndTime={GetCurrentCalendarTime=function() return {year=2026,month=11,monthDay=9} end}
LibQuestieDB.Quest.name=named('The Darkmoon Faire')
LibQuestieDB.Quest.finishedBy=named({{14828}})
LibQuestieDB.Npc.name=named('Gelvas Grimegate')
LibQuestieDB.Npc.spawns=named({[12]={{42,69}},[215]={{36,38}}})
LibQuestieDB.Support.Get=named({private={areaIdToUiMapId='return {[12]=1429,[215]=1412,}'}})
C_Map.GetMapInfo=function() return {mapType=3} end
C_Map.GetBestMapForUnit=function() return 1429 end
C_QuestLog={GetNextWaypoint=function() return 1412,.36,.38 end,GetQuestsOnMap=function() return {{questID=7905,mapID=1412,isQuestStart=false,x=.36,y=.38}} end}
dofile('ForeverCompanion/QuestWaypoints.lua')
local faire={id=7905,title='The Darkmoon Faire',complete=true}
local way=ForeverCompanionQuestWaypoints
assert(way.Location(faire).map==1429,'opening-week Faire rejects a stale Kalimdor client waypoint and chooses the existing Elwynn reference')
assert(#way.Targets(faire)==1 and way.Targets(faire)[1].map==1429)
assert(#way.MapLocations(1412,{faire})==0,'wrong-continent marker is removed from maps as well')
print('PASS: opening-week Darkmoon route, destination and map marker agree on Elwynn; no coordinates invented')
