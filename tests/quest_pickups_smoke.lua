dofile('ForeverCompanion/QuestWaypoints.lua')
C_QuestLog={
 GetTitleForQuestID=function(id) return id~=4 and 'Native quest '..id or nil end,
 GetQuestsOnMap=function() return {
  {questID=1,mapID=100,isQuestStart=true,x=.2,y=.3},
  {questID=1,mapID=100,isQuestStart=true,x=.2,y=.3},
  {questID=2,mapID=100,isQuestStart=true,x=.3,y=.4},
  {questID=3,mapID=101,isQuestStart=true,x=.2,y=.3},
  {questID=4,mapID=100,isQuestStart=true,x=.4,y=.4},
  {questID=5,mapID=100,isQuestStart=false,x=.4,y=.4},
  {questID=6,mapID=100,isQuestStart=true,x=0/0,y=.4},
 } end,
}
local pickups=ForeverCompanionQuestWaypoints.MapPickups(100,{{id=2}})
assert(#pickups==1 and pickups[1].quest.id==1 and pickups[1].pickup)
assert(pickups[1].target.source=='WoW quest pickup')
C_QuestLog.GetQuestsOnMap=function() error('unavailable') end
assert(#ForeverCompanionQuestWaypoints.MapPickups(100,{})==0)
print('PASS: native pickups reject active quests, duplicates, other maps, missing titles and invalid coordinates')
