-- Synthetic records exercise evidence boundaries; none are shipped quest data.
SlashCmdList={}
dofile('ForeverCompanion/QuestFieldGuide.lua')
dofile('ForeverCompanion/QuestTracker.lua')
local G,T=ForeverCompanionQuestFieldGuide,ForeverCompanionQuestTracker
local q={id=10,title='Synthetic quest',zone='Camp',objectives={'Supplies','Scout'},objectiveStates={{known=true,current=2,required=5},{known=true,done=true}}}
assert(math.abs(G.ProgressFraction(q)-.7)<.000001,'numeric objective quantities contribute to progress')
q.objectiveStates[2]={known=false};assert(G.ProgressFraction(q)==nil,'unknown is not fabricated as zero progress')
q.objectiveStates[2]=true;assert(#G.Steps(q,{true,'bad'})==2,'malformed states and targets cannot crash the guide')
assert(G.ProgressFraction({})==nil and #G.Steps(false,{})==0)
q.complete=true;assert(G.ProgressFraction(q)==1 and G.NextStep(q,{}).turnin)
q.complete=false;q.objectiveStates={{known=true,done=true},{known=false}}
assert(T.Preview(q)=='NEXT: Scout' and G.NextStep(q,{}).index==2,'unknown unfinished objectives remain visible')
local a={id=10,title='A',complete=false}
assert(#T.ObserveReady({a},true)==0)
a.complete=true;assert(T.ObserveReady({a},false)==nil and T.readyNotice==nil,'failed scans cannot create turn-in notifications')
assert(#T.ObserveReady({a},true)==1 and #T.ObserveReady({a},true)==0,'one notification per observed completion transition')
T.ObserveReady({},true);assert(#T.ObserveReady({a},true)==0,'login/accepting an already-complete quest does not manufacture a transition')

dofile('ForeverCompanion/QuestLocations.lua')
local R=ForeverCompanionQuestLocations
assert(R.Details(q).source==nil and R.DetailText(q):find('no reward is guessed',1,true))
local queued={};C_Timer={After=function(_,fn) queued[#queued+1]=fn end}
local function drain() while #queued>0 do local fn=table.remove(queued,1);fn() end end
local records={
 [10]={name='Synthetic quest',zoneOrSort=1,startedBy={{100}},preQuestSingle={8,9},preQuestGroup={7},childQuests={11},nextQuestInChain=999,requiredLevel=12,questLevel=15,requiredRaces=0,objectivesText={'Reference objective'}},
 [11]={name='Next quest',zoneOrSort=1},[8]={name='Either A'},[9]={name='Either B'},[7]={name='Required'},
 [20]={name='Outdoor quest',zoneOrSort=2},[21]={name='False dungeon',zoneOrSort=3},
}
for i=1000,1165 do records[i]={name='Other reference '..i,zoneOrSort=2} end
local db={RequireContract=function(v) return v==1 end,ModeIndicator={GetStatus=function() return {expansion='Forever'} end}}
db.Quest={GetAllIds=function() local list={};for id in pairs(records) do list[#list+1]=id end;table.sort(list);return list end}
for _,key in ipairs({'name','zoneOrSort','startedBy','preQuestSingle','preQuestGroup','childQuests','nextQuestInChain','requiredLevel','questLevel','requiredRaces','objectivesText'}) do
 local field=key;db.Quest[field]=function(id) return records[id] and records[id][field] end
end
db.Npc={name=function() return 'Synthetic giver' end,spawns=function() return {[2]={{30,40}}} end}
db.Support={Get=function() return {private={areaIdToUiMapId='{[1]=101,[2]=102,[3]=103,}'}} end}
LibQuestieDB=db
C_Map={GetMapInfo=function(id)
 if id==101 then return {name='The Deadmines',mapType=4} end
 if id==102 then return {name='Westfall',mapType=3} end
 return {name='The Deadmines',mapType=3}
end}
C_QuestLog={IsQuestFlaggedCompleted=function(id) if id==11 then return true elseif id==10 then return false end end}
local details=R.Details(q)
assert(#details.pickups==1 and details.pickups[1].x==.3 and #details.givers==1)
assert(#details.requirements==2 and details.requirements[1]:find('All:',1,true) and details.requirements[2]:find('One of:',1,true))
assert(#details.followups==1 and details.followups[1]=='Next quest','availability-chain field must not be misrepresented as a follow-up')
assert(not R.DetailText(q):find('999',1,true))
assert(R.Details({id=10,title='Wrong quest'}).source==nil,'ID and name must agree before attaching reference details')

dofile('ForeverCompanion/DungeonQuests.lua')
local D=ForeverCompanionDungeonQuests
assert(D.Matches('The Stockade','Stockades') and not D.Matches('Deadmines','Dead'),'only exact canonical dungeon identities match')
assert(D.StartScan());assert(#queued==1)
local entries,status=D.Entries('Deadmines',{})
assert(status.loading and #entries==0,'a pending index is not a completed empty catalog')
table.remove(queued,1)();assert(#queued==1,'large scans yield between bounded batches')
drain()
entries,status=D.Entries('Deadmines',{q})
assert(not status.loading and #entries==2 and entries[1].id==10 and entries[1].live==q)
assert(entries[2].state=='Completed','completion status comes from the client')
assert(#D.Entries('Dead',{})==0,'similar names cannot acquire a different dungeon’s quests')
local oldCount=#queued;assert(D.StartScan() and #queued==oldCount,'repaints do not rescan the full database')
assert(D.StartScan(true));LibQuestieDB=nil;assert(not D.StartScan());drain()
entries,status=D.Entries('Deadmines',{{id=77,title='Live dungeon quest',zoneKnown=true,zone='The Deadmines'}})
assert(#entries==1 and entries[1].id==77 and not status.provider,'provider removal cancels stale indexing and keeps live-log matches')

dofile('ForeverCompanion/MaterialFinder.lua')
ForeverCompanionCraftingPlanner={GetEntries=function() return {{name='Synthetic material'}} end}
local materials=ForeverCompanionMaterialFinder.Search('Synthetic material')
assert(#materials==1 and materials[1].kind=='Missing sources','shared material goals stay searchable without duplicating missing-source results')
print('PASS: quest quantities/unknowns, malformed data, turn-in transitions, reference chains, bounded dungeon indexing and material source gaps')

local detail=D.DetailRows({minimum=18,live={objectives={'Collect shard','Open door','Read plaque'},objectiveStates={{known=true,done=true},{known=true}}}},true)
assert(detail[1].label=='Required level' and detail[2].value=='Done' and detail[3].value=='Remaining' and detail[4].value=='Unknown')
assert(D.DetailRows({live={objectives={'Cached'},objectiveStates={{known=true,done=true}}}},false)[1].value=='Cached')
assert(D.DetailRows({source='Published',start={'Town','NPC'},prerequisites={'Earlier Quest'}},false)[1].value=='Pickup reference')
