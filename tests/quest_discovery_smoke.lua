dofile('ForeverCompanion/QuestDiscovery.lua')
local D=ForeverCompanionQuestDiscovery
local function e(id,title,label,reference,x)
 return {quest={id=id,title=title},target={label=label,map=1,x=x or .2,y=.3},reference=reference}
end
local entries={e(1,'Zebra','Scout',true),e(2,'Apple','Mayor',nil),e(1,'Zebra','Scout',true,.5),e(3,'Alpha','Miner',true)}
local all=D.Filter(entries,'',false)
assert(#all==3 and all[1].quest.id==2 and all[2].quest.id==3)
assert(#all[3].targets==2)
assert(#D.Filter(entries,'SCOUT',false)==1)
assert(#D.Filter(entries,'',true)==1)
assert(#D.Filter(entries,'[',false)==0,'search must be literal')
assert(#D.Filter({},'',false)==0)
print('PASS: quest discovery grouping, stable source sorting, literal search, giver search and native filter')
