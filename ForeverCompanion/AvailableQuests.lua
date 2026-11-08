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
local function matches(mask,bit)
 if type(mask)~='number' or mask<0 then return false end
 if mask==0 then return true end
 return type(bit)=='number' and bit>0 and math.floor(mask/bit)%2==1
end
local function character(db)
 local level=read(UnitLevel,'player')
 local _,class=read(UnitClass,'player')
 local _,_,race=read(UnitRace,'player')
 if type(level)~='number' or level<1 then return end
 local enum=db.Enum or {}
 return {level=level,class=enum.classKeys and enum.classKeys[class],race=enum.raceMaskById and enum.raceMaskById[race],key=tostring(level)..':'..tostring(class)..':'..tostring(race)}
end
local function eligibleBasics(db,id,who)
 local level=field(db,id,'requiredLevel')
 if type(level)~='number' or level>who.level then return false end
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
     local record={id=id,title=title,level=field(db,id,'questLevel'),single=field(db,id,'preQuestSingle'),group=field(db,id,'preQuestGroup'),exclusive=field(db,id,'exclusiveTo'),parent=field(db,id,'parentQuest'),breadcrumb=field(db,id,'breadcrumbForQuestId')}
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
   if ForeverCompanionQuestMap then ForeverCompanionQuestMap.Refresh() end
  end
 end
 C_Timer.After(0,batch)
 return true
end
local function requirements(record,active,completed)
 if active[record.id] or completed(record.id)~=false then return false end
 if type(record.exclusive)=='table' then
  for _,id in ipairs(record.exclusive) do if active[id] or completed(id)==true then return false end end
 end
 if type(record.breadcrumb)=='number' and record.breadcrumb>0 and (active[record.breadcrumb] or completed(record.breadcrumb)==true) then return false end
 if type(record.parent)=='number' and record.parent>0 and not active[record.parent] then return false end
 if type(record.single)=='table' and #record.single>0 then
  local found=false
  for _,id in ipairs(record.single) do if type(id)=='number' and id>0 and completed(id)==true then found=true;break end end
  if not found then return false end
 elseif type(record.group)=='table' then
  for _,id in ipairs(record.group) do
   if type(id)~='number' or id==0 or completed(math.abs(id))~=true then return false end
  end
 end
 return true
end
function A.ForMap(map,quests,ignoreVisibility)
 if not ignoreVisibility and ForeverCompanionDB and ForeverCompanionDB.questMapHidePickups then return {} end
 local db=ForeverCompanionQuestLocations.Provider()
 if not db or read(db.RequireContract,4)~=true or type(db.Quest.GetAllIds)~='function' then return {},'Install current Forever QuestieDB for more quest pickups' end
 if not C_QuestLog or type(C_QuestLog.IsQuestFlaggedCompleted)~='function' then return {},'Quest completion API unavailable; native pickups only' end
 local who=character(db)
 if not who then return {},'Waiting for character information' end
 if database~=db or identity~=who.key then
  if not build(db,who) then return {},'Quest pickup indexing unavailable' end
 end
 if loading then return {},'Loading quest-giver locations…' end
 local active,completion,result,seen={},{},{},{}
 for _,q in ipairs(quests or {}) do if q.id then active[q.id]=true end end
 local function completed(id)
  if completion[id]==nil then
   local value=read(C_QuestLog.IsQuestFlaggedCompleted,id)
   if type(value)=='boolean' then completion[id]=value else completion[id]='unknown' end
  end
  return completion[id]
 end
 for _,entry in ipairs(index and index[map] or {}) do
  local record,target=entry.record,entry.target
  if read(C_QuestLog.IsOnQuest,record.id)~=true and requirements(record,active,completed) then
   local key=record.id..':'..target.x..':'..target.y
   if not seen[key] then
    seen[key]=true
    result[#result+1]={quest={id=record.id,title=record.title,level=record.level,complete=false},target=target,pickup=true,reference=true}
   end
  end
 end
 return result
end
function A.Invalidate()
 generation=generation+1
 database,identity,index,loading=nil,nil,nil,false
end
