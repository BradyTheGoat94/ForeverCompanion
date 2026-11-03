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
-- Missing or malformed character settings must not crash reset actions.
assert(b.Reset('Legacy','MAGE',nil)==nil)
assert(b.Reset('Legacy','MAGE',false)==nil)
assert(b.Reset('Legacy','MAGE','bad saved variables')==nil)
assert(b.Reset('Legacy','MAGE',{studyChecks='corrupt'})==nil)
db.studyChecks='corrupt'
assert(b.Toggle('Alts','MAGE',db,1),'recover malformed saved state')
assert(b.Get('Alts','MAGE',db).done==1)
print('PASS: study board isolation, persistence, reset and '..count..' specialization alternatives')

for class in pairs(ForeverCompanionSpecs) do
 local accent=b.Accent("Leveling",class)
 assert(#accent==3)
 for _,value in ipairs(accent) do assert(value>=0 and value<=1) end
end
assert(b.Accent("Leveling","MAGE")[3]>b.Accent("Leveling","MAGE")[1])
assert(b.Accent("Alts","MAGE")[1]~=b.Accent("Legacy","MAGE")[1])
assert(b.Accent("Leveling","UNKNOWN")[1]>0)
print("PASS: class accents, planning palettes and fallback")

-- Old or edited SavedVariables must not blank specialization-dependent pages.
for class in pairs(ForeverCompanionSpecs) do
 for _,bad in ipairs({0,-1,1.5,math.huge,-math.huge,0/0,"1.5","not a spec",{},true}) do
  ForeverCompanionDB.specSelections={[class]=bad}
  local selected,index=ForeverCompanionSpecPlanner.Get(class)
  assert(selected and index==1,"invalid saved selection must fall back: "..class)
  ForeverCompanionSpecPlanner.Next(class)
  local nextChoice,nextIndex=ForeverCompanionSpecPlanner.Get(class)
  assert(nextChoice and nextIndex==2,"cycling must recover after invalid selection")
 end
 ForeverCompanionDB.specSelections={[class]="2"}
 assert(select(2,ForeverCompanionSpecPlanner.Get(class))==2,"valid numeric strings remain supported")
end
-- Unknown and malformed class identifiers must use safe fallbacks.
for _,badClass in ipairs({false,42,{}}) do
 local spec,index,total=ForeverCompanionSpecPlanner.Get(badClass)
 assert(spec==nil and index==1 and total==0)
 assert(ForeverCompanionSpecPlanner.Next(badClass)==nil)
 assert(b.Get('Leveling',badClass,db)==nil)
 assert(#b.Accent('Leveling',badClass)==3)
end
-- Missing class context must not index SavedVariables with nil.
local missing,missingIndex,missingTotal=ForeverCompanionSpecPlanner.Get(nil)
assert(missing==nil and missingIndex==1 and missingTotal==0,'nil class lookup must remain safe')
assert(ForeverCompanionSpecPlanner.Next(nil)==nil,'nil class cycling must be a no-op')
ForeverCompanionDB="malformed"
assert(ForeverCompanionSpecPlanner.Get("MAGE"),"malformed database should recover")
print("PASS: specialization selection recovery across all classes")
