SlashCmdList={}
ForeverCompanionDB={}
dofile('ForeverCompanion/SpecPlanner.lua')
dofile('ForeverCompanion/SpecPlaybooks.lua')
dofile('ForeverCompanion/StudyBoard.lua')
dofile('ForeverCompanion/PracticeNotes.lua')
local b=ForeverCompanionStudyBoard
local db={}
assert(b.Get('Overview','MAGE',db)==nil)
local count=0
for class,specs in pairs(ForeverCompanionSpecs) do
 for i,spec in ipairs(specs) do
  ForeverCompanionDB.specSelections={[class]=i}
  local state=b.Get('Leveling',class,db)
  assert(state and state.total>=3,class..'/'..spec[1]..' missing practice')
  assert(state.done==0,'spec progress must start empty')
  assert(b.Toggle('Leveling',class,db,1))
  assert(b.Get('Leveling',class,db).done==1)
  b.Reset('Leveling',class,db)
  assert(b.Get('Leveling',class,db).done==0)
  local coaching=ForeverCompanionPracticeNotes.Lines(class)
  assert(#coaching==6 and coaching[1]:find(spec[1],1,true),'missing spec coaching')
  count=count+1
 end
end
assert(count>=27)
assert(not b.Toggle('Legacy','MAGE',db,0))
assert(not b.Toggle('Legacy','MAGE',db,1.5))
assert(not b.Toggle('Legacy','MAGE',db,6))
assert(b.Toggle('Legacy','MAGE',db,1))
assert(b.Get('Alts','MAGE',db).done==0,'legacy/alt isolation')
assert(b.Get('Legacy','MAGE',db).done==1)
db.studyChecks='corrupt'
assert(b.Toggle('Alts','MAGE',db,1),'recover malformed saved state')
assert(b.Get('Alts','MAGE',db).done==1)
print('PASS: study board isolation, persistence, reset and '..count..' specialization alternatives')
