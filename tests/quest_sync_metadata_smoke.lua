CreateFrame=function() return {RegisterEvent=function() end,SetScript=function() end} end
SlashCmdList={};ForeverCompanionDB={}
dofile('ForeverCompanion/QuestPlanner.lua')
local P=ForeverCompanionQuestPlanner
local info={questID=77,title='Matched objective quest',level=18,zoneName='Forest',isComplete=false}
local objectives={{text='Wolves slain: 2/5',type='monster',numFulfilled=2,numRequired=5,finished=false},{text='Crate: 1/1',type='object',numFulfilled=1,numRequired=1,finished=true},{text='Unknown',type='event'}}
C_QuestLog={GetQuestLogQuests=function() return {info} end,GetQuestObjectives=function() return objectives end}
assert(P.Sync())
local q=P.GetLive()[1]
assert(q.level==18 and q.objectiveStates[1].kind=='monster' and q.objectiveStates[1].current==2 and q.objectiveStates[1].required==5)
assert(q.objectiveStates[2].done and not q.objectiveStates[3].known)
C_QuestLog.GetQuestLogQuests=nil
C_QuestLog.GetNumQuestLogEntries=function() return 1 end
C_QuestLog.GetInfo=function() return info end
assert(P.Sync());q=P.GetLive()[1]
assert(q.objectiveStates[1].kind=='monster' and q.objectiveStates[1].current==2 and q.level==18,'indexed enumerator must preserve identical metadata')
C_QuestLog.GetNumQuestLogEntries=function() error('temporary failure') end
assert(not P.Sync() and P.GetLive()[1]==q,'failed sync preserves the snapshot')
print('PASS: modern enumerators share objective type/count/level metadata and failed scans preserve their snapshot')
