local events={}
CreateFrame=function() local f={RegisterEvent=function() end,SetScript=function(self,k,v) self[k]=v end};events[#events+1]=f;return f end
ForeverCompanionDB={};dofile('ForeverCompanion/TrainingData.lua');dofile('ForeverCompanion/TrainingGuide.lua')
local t=ForeverCompanionTraining;local data=ForeverCompanionTrainingData
local classes,total=0,0
for class in pairs(data.classes) do classes=classes+1;local list=t.Reference(class,1,'Alliance');assert(#list>30);total=total+#list end
assert(classes==9 and total>900,'reference covers nine class datasets')
local function contains(list,id) for _,r in ipairs(list) do if r.id==id then return true end end end
assert(contains(t.Reference('MAGE',1,'Alliance'),3561) and not contains(t.Reference('MAGE',1,'Horde'),3561),'faction gating')
assert(contains(t.Reference('WARRIOR',1,'Alliance'),71),'race-matched quest rewards are kept separate')
local entries={{id=1,level=1,cost=10},{id=2,level=2,requiredIds={1},cost=20},{id=3,level=10},
 {id=4,level=2,requiredTalentId=999},{id=5,level=2,quest=true},{id=6,level=2,skills={{skill=40,level=100}}},{id=7,level=2},{id=8,level=2}}
local known={[1]=true,[2]=false,[3]=false,[4]=false,[5]=false,[6]=false,[8]=false,[999]=false}
local result=t.Build(entries,{level=4,ignored={[8]=true},known=function(id) return known[id] end})
local by={};for _,r in ipairs(result) do by[r.id]=r end
assert(by[1].state=='known' and by[2].state=='ready' and by[3].state=='upcoming')
assert(by[4].state=='requirements' and by[5].state=='quest' and by[6].state=='requirements')
assert(by[7].state=='unknown' and by[8].state=='ignored','unknown ownership is never treated as trainable')
local higher=t.Build({{id=1,level=1},{id=2,level=2,requiredIds={1}}},{level=5,ignored={},known=function(id) return id==2 end})
assert(higher[1].state=='known' and higher[1].status:find('higher rank'),'known higher ranks suppress obsolete lower-rank reminders')
UnitClass=function() return 'Warrior','WARRIOR' end;UnitRace=function() return 'Human','Human',1 end
UnitFactionGroup=function() return 'Alliance' end;UnitLevel=function() return 4 end
ForeverCompanionKnownSpell=function() return false end
C_Spell={GetSpellInfo=function(id) return {name='Spell '..id,iconID=123} end}
UnitName=function() return 'Observed class trainer' end;GetNumTrainerServices=function() return 1 end
GetTrainerServiceInfo=function() return 'Charge','available',123,4,'Rank 1' end
GetTrainerServiceCost=function() return 95 end
Enum={TooltipDataType={Spell=1}};C_TooltipInfo={GetTrainerService=function() return {id=100,type=1} end}
events[1].OnEvent(nil,'TRAINER_SHOW')
assert(ForeverCompanionDB.trainingGuide.observed[100].cost==95,'modern trainer return order and live price recorded')
local current=t.Current();local available=t.Filter(current,'','available');assert(#available==1 and available[1].id==100)
events[1].OnEvent(nil,'TRAINER_CLOSED');assert(#t.Filter(t.Current(),'','available')==0,'closed trainer observations cannot claim current availability')
assert(ForeverCompanionDB.trainingGuide.observed[100],'last visit remains separately labeled')
assert(t.Money(12345)=='1g 23s 45c' and t.Money(nil)=='Price unavailable')
local file=assert(io.open('ForeverCompanion/TrainingData.lua'));local source=file:read('*a');file:close()
assert(source:find('MIT License',1,true) and source:find('Copyright (c) 2019',1,true) and source:find(data.commit,1,true),'shipped dataset preserves upstream attribution and license')
print('PASS: nine-class training reference, eligibility, rank/prerequisite states, live trainer observations and MIT attribution')

assert(t.Money(95)=='95c' and t.Money(0)=='Free' and t.Money(100)=='1s')
C_Spell.GetSpellInfo=function() return nil end
C_Spell.GetSpellTexture=function() return 456 end
GetSpellInfo=function(id) return 'Localized spell '..id,'Rank 2',789 end
C_Spell.GetSpellSubtext=function() return 'Rank 3' end
events[1].OnEvent(nil,'SPELLS_CHANGED')
local enriched=t.Current()[1]
assert(enriched.icon==456 and enriched.name:find('Localized spell',1,true) and enriched.rank=='Rank 3','client texture, localized name fallback and native rank text')
