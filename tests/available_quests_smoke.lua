-- Database-backed unaccepted quests: eligibility, verified spawns and async lifecycle.
local queued={}
C_Timer={After=function(_,fn) queued[#queued+1]=fn end}
local race=1
UnitLevel=function() return 20 end
UnitClass=function() return 'Warrior','WARRIOR' end
UnitRace=function() return 'Human','Human',race end
C_Map={GetMapInfo=function() return {mapType=3} end}
local complete={[2]=true,[200]=true,[201]=true,[202]=false}
C_QuestLog={IsQuestFlaggedCompleted=function(id) return complete[id]==true end}
local rows={}
for i=1,19 do rows[i]={name='Reference quest '..i,requiredLevel=10,requiredRaces=0,requiredClasses=0,startedBy={[1]={i}}} end
rows[4].requiredLevel=40
rows[5].requiredRaces=2
rows[6].requiredClasses=2
rows[7].preQuestSingle={200,202}
rows[8].preQuestSingle={202}
rows[9].preQuestGroup={200,201}
rows[10].preQuestGroup={200,202}
rows[11].exclusiveTo={2}
rows[12].preQuestGroup={-200}
rows[14].startedBy={[2]={14}}
rows[15].startedBy={[3]={15}}
rows[17].parentQuest=202
rows[18].breadcrumbForQuestId=2
rows[19].requiredRaces=4294967296
local db={Enum={raceMaskById={[1]=1,[95]=4294967296},classKeys={WARRIOR=1}},RequireContract=function(v) return v==4 end}
local quest={GetAllIds=function() local ids={};for i=1,19 do ids[i]=i end;return ids end}
for _,key in ipairs({'name','requiredLevel','requiredRaces','requiredClasses','questLevel','startedBy','preQuestSingle','preQuestGroup','exclusiveTo','parentQuest','breadcrumbForQuestId'}) do
 local field=key
 quest[field]=function(id) return rows[id] and rows[id][field] end
end
db.Quest=quest
db.Npc={name=function(id) return 'Giver '..id end,spawns=function(id)
 if id==13 then return {[12]={{50,50,9}}} end
 if id==16 then return {[12]={{0/0,50}}} end
 return {[12]={{40+id,50}}}
end}
db.Object={name=function() return 'Notice board' end,spawns=function() return {[12]={{23,45}}} end}
ForeverCompanionQuestLocations={Provider=function() return db end,AreaMaps=function() return {[12]=1429} end}
ForeverCompanionQuestMap={Refresh=function() end}
dofile('ForeverCompanion/AvailableQuests.lua')
local a=ForeverCompanionAvailableQuests
local points,message=a.ForMap(1429,{{id=3}})
assert(#points==0 and message:find('Loading',1,true))
local function drain() while #queued>0 do table.remove(queued,1)() end end
drain()
points=a.ForMap(1429,{{id=3}})
local found={}
for _,entry in ipairs(points) do found[entry.quest.id]=true;assert(entry.reference and entry.pickup) end
for _,id in ipairs({1,7,9,12,14}) do assert(found[id],'missing eligible giver '..id) end
for _,id in ipairs({2,3,4,5,6,8,10,11,13,15,16,17,18,19}) do assert(not found[id],'ineligible quest leaked '..id) end
local catalog=a.Catalog(1429,{{id=3,title='Live quest title',complete=true}})
local catalogByID={}
for _,entry in ipairs(catalog) do catalogByID[entry.id]=entry end
assert(#catalog==13,'catalog includes mapped character-compatible giver references, including higher-level quests')
assert(catalogByID[2].status=='completed')
assert(catalogByID[3].status=='active' and catalogByID[3].ready and catalogByID[3].title=='Live quest title')
assert(catalogByID[4].status=='locked' and catalogByID[4].reason:find('40',1,true))
assert(catalogByID[8].status=='locked' and catalogByID[8].dependencies[1]=='Quest 202')
assert(catalogByID[1].status=='available' and catalogByID[14].targets[1].label=='Notice board')
local completionAPI=C_QuestLog.IsQuestFlaggedCompleted
C_QuestLog.IsQuestFlaggedCompleted=function(id) if id==202 then return nil end;return completionAPI(id) end
catalogByID={};for _,entry in ipairs(a.Catalog(1429,{})) do catalogByID[entry.id]=entry end
assert(catalogByID[8].status=='unknown' and catalogByID[10].status=='unknown','unknown prerequisites must not become pickup availability claims')
assert(catalogByID[7].status=='available','one known completed prerequisite is sufficient for an OR group')
C_QuestLog.IsQuestFlaggedCompleted=completionAPI
complete[1]=true
for _,entry in ipairs(a.ForMap(1429,{{id=3}})) do assert(entry.quest.id~=1,'turn-in immediately removes old pickup') end
race=95
a.ForMap(1429,{})
drain()
found={}
for _,entry in ipairs(a.ForMap(1429,{})) do found[entry.quest.id]=true end
assert(found[19],'Skyborne race bit above 32 bits is preserved')
ForeverCompanionDB={questMapHidePickups=true}
assert(#a.ForMap(1429,{})==0)
ForeverCompanionDB={}
C_QuestLog.IsQuestFlaggedCompleted=nil
assert(#a.ForMap(1429,{})==0,'missing completion API cannot claim availability')
for _,entry in ipairs(a.Catalog(1429,{})) do assert(entry.status=='unknown','missing completion API cannot become a completed or available catalog claim') end
print('PASS: database quest pickups, asynchronous indexing, completion, active, level, race/class, prerequisites, exclusions, objects, phases, Skyborne masks and toggle')
