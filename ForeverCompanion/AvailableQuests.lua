-- Unaccepted quest-giver locations from the optional Forever QuestieDB.
-- Native pickups remain authoritative. Database markers are reference locations,
-- never a claim that seasonal, profession or reputation requirements are met.
local A={}
ForeverCompanionAvailableQuests=A
local database,identity,index,loading,generation=nil,nil,nil,false,0
local function read(fn,...)
 if type(fn)~='function' then return end
 local ok,a,b,c=pcall(fn,...)
 if ok then return a,b,c end
end
local function field(db,id,key) return read(db.Quest[key],id) end
local function finite(n)
 return not (issecretvalue and issecretvalue(n)) and type(n)=='number' and n==n and math.abs(n)<math.huge
end
local function matches(mask,bit)
 if not finite(mask) or mask<0 then return false end
 if mask==0 then return true end
 return finite(bit) and bit>0 and math.floor(mask/bit)%2==1
end
local function character(db)
 local level=read(UnitLevel,'player')
 local _,class=read(UnitClass,'player')
 local _,_,race=read(UnitRace,'player')
 if not finite(level) or level<1 then return end
 local enum=db.Enum or {}
 return {level=level,class=enum.classKeys and enum.classKeys[class],race=enum.raceMaskById and enum.raceMaskById[race],key=tostring(level)..':'..tostring(class)..':'..tostring(race)}
end
local function eligibleBasics(db,id,who)
 local level=field(db,id,'requiredLevel')
 if not finite(level) or level<0 then return false end
 return matches(field(db,id,'requiredRaces'),who.race) and matches(field(db,id,'requiredClasses'),who.class)
end
local function append(db,results,maps,record,entity,id)
 if type(entity)~='table' then return end
 local spawns=read(entity.spawns,id)
 if type(spawns)~='table' then return end
 local label=read(entity.name,id)
 for area,points in pairs(spawns) do
  local map=maps[area]
  local info=map and C_Map and read(C_Map.GetMapInfo,map)
  if type(info)=='table' and (info.mapType==3 or info.mapType==5) and type(points)=='table' then
   for _,xy in ipairs(points) do
    if type(xy)=="table" then
    local x,y,phase=xy[1],xy[2],xy[3]
    if type(x)=='number' and x>=0 and x<=100 and type(y)=='number' and y>=0 and y<=100 and (not phase or phase==0) then
     results[map]=results[map] or {}
     results[map][#results[map]+1]={record=record,target={map=map,x=x/100,y=y/100,kind='pickup',label=label,source='Forever QuestieDB quest giver'}}
    end
    end
   end
  end
 end
end
local function build(db,who)
 local ids=read(db.Quest.GetAllIds)
 if type(ids)~='table' or not C_Timer or type(C_Timer.After)~='function' then return false end
 local maps=ForeverCompanionQuestLocations.AreaMaps(db)
 generation=generation+1
 local token,results,cursor=generation,{},1
 database,identity,index,loading=db,who.key,results,true
 local function batch()
  if token~=generation then return end
  for i=cursor,math.min(cursor+59,#ids) do
   local id=ids[i]
   if type(id)=='number' and id>0 and eligibleBasics(db,id,who) then
    local title=field(db,id,'name')
    local starts=field(db,id,'startedBy')
    if type(title)=='string' and title~='' and type(starts)=='table' then
     local record={id=id,title=title,level=field(db,id,'questLevel'),minimum=field(db,id,'requiredLevel'),single=field(db,id,'preQuestSingle'),group=field(db,id,'preQuestGroup'),exclusive=field(db,id,'exclusiveTo'),parent=field(db,id,'parentQuest'),breadcrumb=field(db,id,'breadcrumbForQuestId')}
     -- Item-start quests have no single fixed pickup coordinate; do not guess one.
     for kind,entity in ipairs({db.Npc or {},db.Object or {}}) do
      for _,giver in ipairs(type(starts[kind])=='table' and starts[kind] or {}) do append(db,results,maps,record,entity,giver) end
     end
    end
   end
  end
  cursor=cursor+60
  if cursor<=#ids then C_Timer.After(.01,batch)
  else
   loading=false
   if ForeverCompanionQuestDiscovery then ForeverCompanionQuestDiscovery.Refresh() end
   if ForeverCompanionQuestBook then ForeverCompanionQuestBook.Refresh() end
   if ForeverCompanionQuestMap then ForeverCompanionQuestMap.Refresh() end
   if ForeverCompanionRefresh then ForeverCompanionRefresh() end
  end
 end
 C_Timer.After(0,batch)
 return true
end
local function requirements(record,active,completed,who)
 if active[record.id] then return false,'Already in your quest log','active' end
 local state=completed(record.id)
 if state==true then return false,'Client reports this quest completed','completed' end
 if state~=false then return false,'Completion state is unavailable','unknown' end
 if type(record.minimum)~='number' or record.minimum~=record.minimum then return false,'Level requirement is unavailable','unknown' end
 if who and record.minimum>who.level then return false,'Requires character level '..record.minimum,'level' end
 if type(record.exclusive)=='table' then
  for _,id in ipairs(record.exclusive) do
   local done=completed(id)
   if active[id] or done==true then return false,'An alternate quest choice is active or completed','choice' end
   if done~=false then return false,'Alternate quest completion is unavailable','unknown' end
  end
 end
 if type(record.breadcrumb)=='number' and record.breadcrumb>0 then
  local done=completed(record.breadcrumb)
  if active[record.breadcrumb] or done==true then return false,'The destination quest is already active or completed','breadcrumb' end
  if done~=false then return false,'Destination quest completion is unavailable','unknown' end
 end
 if type(record.parent)=='number' and record.parent>0 and not active[record.parent] then return false,'The parent quest must be active','parent' end
 if type(record.single)=='table' and #record.single>0 then
  local found,unknown=false,false
  for _,id in ipairs(record.single) do
   local done='unknown'
   if type(id)=='number' and id>0 then done=completed(id) end
   if done==true then found=true;break end
   if done~=false then unknown=true end
  end
  if not found then return false,unknown and 'Prerequisite completion is unavailable' or 'Complete one prerequisite quest',unknown and 'unknown' or 'prerequisite' end
 elseif type(record.group)=='table' then
  for _,id in ipairs(record.group) do
   if type(id)~='number' or id==0 then return false,'Prerequisite information is unavailable','unknown' end
   local done=completed(math.abs(id))
   if done~=true then return false,done==false and 'Complete every prerequisite quest' or 'Prerequisite completion is unavailable',done==false and 'prerequisite' or 'unknown' end
  end
 end
 return true,'Basic level, race, class and chain checks passed; confirm special requirements with the giver','available'
end
local function prepare()
 local db=ForeverCompanionQuestLocations.Provider()
 if not db or read(db.RequireContract,4)~=true or type(db.Quest.GetAllIds)~='function' then return nil,nil,'Install current Forever QuestieDB for mapped quest references' end
 local who=character(db)
 if not who then return nil,nil,'Waiting for character information' end
 if database~=db or identity~=who.key then
  if not build(db,who) then return nil,nil,'Quest pickup indexing unavailable' end
 end
 if loading then return nil,nil,'Loading quest-giver locations…' end
 return index,who
end
local function completionReader()
 local cache={}
 return function(id)
  if not finite(id) or id<=0 or id~=math.floor(id) then return 'unknown' end
  if cache[id]==nil then
   local value=C_QuestLog and read(C_QuestLog.IsQuestFlaggedCompleted,id)
   if not (issecretvalue and issecretvalue(value)) and type(value)=='boolean' then cache[id]=value else cache[id]='unknown' end
  end
  return cache[id]
 end
end
function A.ForMap(map,quests,ignoreVisibility)
 if not ignoreVisibility and ForeverCompanionDB and ForeverCompanionDB.questMapHidePickups then return {} end
 if not C_QuestLog or type(C_QuestLog.IsQuestFlaggedCompleted)~='function' then return {},'Quest completion API unavailable; native pickups only' end
 local data,who,status=prepare()
 if not data then return {},status end
 local active,result,seen={},{},{}
 for _,q in ipairs(quests or {}) do if q.id then active[q.id]=true end end
 local completed=completionReader()
 for _,entry in ipairs(data[map] or {}) do
  local record,target=entry.record,entry.target
  if read(C_QuestLog.IsOnQuest,record.id)~=true and requirements(record,active,completed,who) then
   local key=record.id..':'..target.x..':'..target.y
   if not seen[key] then
    seen[key]=true
    result[#result+1]={quest={id=record.id,title=record.title,level=record.level,complete=false},target=target,pickup=true,reference=true}
   end
  end
 end
 return result
end
function A.Catalog(map,quests)
 local data,who,status=prepare()
 if not data then return {},status end
 local active,grouped,result={},{},{}
 for i,q in ipairs(quests or {}) do if q.id then active[q.id]={quest=q,index=i} end end
 local completed=completionReader()
 for _,entry in ipairs(data[map] or {}) do
  local record,t=entry.record,entry.target
  local item=grouped[record.id]
  if not item then
   local accepted=active[record.id] or (C_QuestLog and read(C_QuestLog.IsOnQuest,record.id)==true)
   local done=completed(record.id)
   local ok,reason,code=requirements(record,active,completed,who)
   local state=accepted and 'active' or (done==true and 'completed' or (done~=false and 'unknown' or (ok and 'available' or (code=='unknown' and 'unknown' or 'locked'))))
   item={id=record.id,title=type(accepted)=='table' and accepted.quest.title or record.title,level=record.level,minimum=record.minimum,status=state,reason=reason,targets={},seen={},dependencies={}}
   if type(accepted)=='table' then item.liveIndex=accepted.index;item.ready=accepted.quest.complete==true end
   if state=='active' then item.reason=item.ready and 'Ready to turn in; open the field guide for a destination' or 'Currently in your quest log' end
   if state=='completed' then item.reason='Your game reports this quest completed. Its turn-in date and rewards were not recorded.' end
   local ids=code=='parent' and {record.parent} or (code=='prerequisite' and (type(record.single)=='table' and #record.single>0 and record.single or record.group))
   for _,id in ipairs(type(ids)=='table' and ids or {}) do
    if #item.dependencies>=3 then break end
    if type(id)=='number' and id~=0 then
     id=math.abs(id)
     if completed(id)~=true then item.dependencies[#item.dependencies+1]=field(database,id,'name') or ('Quest '..id) end
    end
   end
   grouped[record.id]=item;result[#result+1]=item
  end
  local key=t.x..':'..t.y
  if not item.seen[key] then item.seen[key]=true;item.targets[#item.targets+1]=t end
 end
 table.sort(result,function(a,b) if a.title~=b.title then return a.title<b.title end;return a.id<b.id end)
 return result
end
function A.Invalidate()
 generation=generation+1
 database,identity,index,loading=nil,nil,nil,false
end
-- Read existing indexing state for setup/diagnostics without starting a scan.
function A.Status(map)
 local db=ForeverCompanionQuestLocations.Provider()
 local contract=db and read(db.RequireContract,4)==true or false
 local who=db and character(db)
 local current=database==db and who and identity==who.key
 local count,locations,seen=0,0,{}
 if not loading and current then
  for _,entry in ipairs(index and index[map] or {}) do
   locations=locations+1
   if not seen[entry.record.id] then seen[entry.record.id]=true;count=count+1 end
  end
 end
 return {provider=db~=nil,contract=contract,loading=loading,initialized=current and index~=nil or false,
  quests=count,locations=locations,completion=C_QuestLog and type(C_QuestLog.IsQuestFlaggedCompleted)=='function' or false}
end
