local status={provider=false,completion=true}
ForeverCompanionAvailableQuests={Status=function() return status end}
ForeverCompanionQuestPlanner={IsSupported=function() return true end}
dofile('ForeverCompanion/QuestSetup.lua')
local s=ForeverCompanionQuestSetup
local function lines() return table.concat(s.Lines(1429),'\n') end
assert(lines():find('generic Questie data is not assumed compatible',1,true))
status={provider=true,contract=false,completion=true}
assert(lines():find('interface is too old',1,true))
status.contract=true;status.loading=true
assert(lines():find('small batches',1,true))
status.loading=false
assert(lines():find('Open Find new quests',1,true))
status.initialized=true;status.quests=42;status.locations=65;status.completion=false
assert(lines():find('42 character-compatible mapped quests / 65 giver references',1,true))
assert(lines():find('eligibility stays unknown',1,true))
assert(lines():find('not a count of quests currently available',1,true))
print('PASS: quest setup distinguishes native/provider/old-contract/loading/coverage/unknown eligibility')
