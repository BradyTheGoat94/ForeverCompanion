-- Uses the optional Forever QuestieDB provider's documented service flags.
local S={}
ForeverCompanionTownServices=S

local services={
 {"BANKER","Bank","B"},
 {"AUCTIONEER","Auction house","AH"},
 {"FLIGHT_MASTER","Flight master","F"},
 {"INNKEEPER","Inn","I"},
 {"REPAIR","Repairs","R"},
 {"VENDOR","Vendor","V"},
 {"TRAINER","Trainer","T"},
 {"CLASS_TRAINER","Class trainer","T"},
 {"PROFESSION_TRAINER","Profession trainer","T"},
 {"MAILBOX","Mailbox","M"},
}
local database,faction,byMap,loaded,loadError
local function finite(n) return not (issecretvalue and issecretvalue(n)) and type(n)=='number' and n==n and math.abs(n)<math.huge end
local function text(s)
 if not (issecretvalue and issecretvalue(s)) and type(s)=='string' and s~='' then return s:gsub('[\r\n|]',' ') end
end
local function valid(p) return type(p)=='table' and finite(p.map) and p.map>0 and finite(p.x) and finite(p.y) and p.x>=0 and p.x<=1 and p.y>=0 and p.y<=1 and text(p.label) end
S.Valid=valid
local function read(fn,...)
 if type(fn)~="function" then return end
 local ok,value=pcall(fn,...)
 if ok then return value end
end

local function has(flags,bit)
 return type(bit)=="number" and bit>0 and math.floor(flags/bit)%2==1
end

local function indexNpc(db,id,flags,maps,side,results)
 local value=read(db.Npc.npcFlags,id)
 if not finite(value) or value<=0 then return end
 local matched,seen={},{}
 for _,candidate in ipairs(services) do
  if has(value,flags[candidate[1]]) and not seen[candidate[2]] then
   matched[#matched+1]=candidate
   seen[candidate[2]]=true
  end
 end
 if #matched==0 then return end
 local friendly=read(db.Npc.friendlyToFaction,id)
 if type(friendly)~="string" or not friendly:find(side,1,true) then return end
 local spawns=read(db.Npc.spawns,id)
 if type(spawns)~="table" then return end
 local name=text(read(db.Npc.name,id)) or matched[1][2]
 local subtitle=text(read(db.Npc.subName,id))
 for area,points in pairs(spawns) do
  local map=maps[area]
  if map and map>0 and type(points)=="table" then
   for _,point in ipairs(points) do if type(point)=='table' then
    local x,y,phase=point[1],point[2],point[3]
    if type(x)=="number" and type(y)=="number" and x>=0 and x<=100 and y>=0 and y<=100 and (not phase or phase==0) then
     local entries=results[map]
     if not entries then entries={};results[map]=entries end
     for _,service in ipairs(matched) do
      entries[#entries+1]={map=map,x=x/100,y=y/100,label=name,subtitle=subtitle,npcID=id,service=service[2],symbol=service[3],source='Forever QuestieDB reference'}
     end
    end
   end end
  end
 end
end

local function start(db,side)
 local flags=db.Enum and db.Enum.npcFlags
 if not flags or read(db.RequireContract,4)~=true or not db.Npc or not C_Timer or not C_Timer.After then
  database,faction,byMap,loaded,loadError=db,side,{},true,"Town service database contract unavailable"
  return
 end
 local ids=read(db.Npc.GetAllIds)
 if type(ids)~="table" then
  database,faction,byMap,loaded,loadError=db,side,{},true,"Town service NPC index unavailable"
  return
 end
 local maps=ForeverCompanionQuestLocations.AreaMaps(db)
 local results,index={},1
 database,faction,byMap,loaded,loadError=db,side,results,false,nil
 local function batch()
  if results~=byMap then return end
  for i=index,math.min(index+119,#ids) do indexNpc(db,ids[i],flags,maps,side,results) end
  index=index+120
  if index<=#ids then C_Timer.After(.02,batch)
  else
   loaded=true
   if ForeverCompanionQuestMap then ForeverCompanionQuestMap.Refresh() end
   if ForeverCompanionServiceAtlas then ForeverCompanionServiceAtlas.Refresh() end
  end
 end
 C_Timer.After(0,batch)
end

local function providerMap(map)
 local db=ForeverCompanionQuestLocations.Provider()
 local side=read(UnitFactionGroup,"player")
 if not db or (side~="Alliance" and side~="Horde") then
  database,faction,byMap,loaded,loadError=nil,nil,nil,nil,nil
  return {}, "QuestieDB needed for service pins"
 end
 side=side:sub(1,1)
 if database~=db or faction~=side then start(db,side) end
 if database~=db or faction~=side then return {}, "Town service data unavailable" end
 if not loaded then return {}, "Loading town services…" end
 if loadError then return {},loadError end
 -- NPC service locations can occur in outdoor zones, settlements,
 -- instances and other map types. Use the provider's mapped spawn data
 -- instead of assuming that only city/zone map types contain services.
 if type(map)~="number" then return {} end
 return byMap[map] or {}
end
function S.RefreshData()
 database,faction,byMap,loaded,loadError=nil,nil,nil,nil,nil
end
function S.Key(p)
 if not valid(p) then return end
 return p.map..':'..p.x..':'..p.y..':'..tostring(p.npcID or p.label)..':'..tostring(p.symbol)
end
local function visits()
 ForeverCompanionDB=ForeverCompanionDB or {}
 if type(ForeverCompanionDB.visitedMerchants)~='table' then ForeverCompanionDB.visitedMerchants={} end
 return ForeverCompanionDB.visitedMerchants
end
function S.RecordVisit(record)
 if not valid(record) or not finite(record.npcID) or record.npcID<=0 then return false end
 local records=visits()
 for i=#records,1,-1 do local old=records[i];if type(old)=='table' and old.map==record.map and old.npcID==record.npcID then table.remove(records,i) end end
 table.insert(records,1,{map=record.map,x=record.x,y=record.y,label=text(record.label),npcID=record.npcID,repair=record.repair==true,at=record.at})
 while #records>100 do table.remove(records) end
 return true
end
function S.ForMap(map)
 local points,notice=providerMap(map)
 local result,seen={},{}
 for _,p in ipairs(points) do
  local key=S.Key(p)
  if key and not seen[key] then result[#result+1]=p;seen[key]=true end
 end
 for _,p in ipairs(visits()) do if valid(p) and p.map==map then
  for _,service in ipairs(p.repair and {{'V','Vendor'},{'R','Repairs'}} or {{'V','Vendor'}}) do
   local candidate={map=p.map,x=p.x,y=p.y,label=p.label,npcID=p.npcID,symbol=service[1],service=service[2],observed=true,at=p.at,source='Visited nearby · player position at merchant visit'}
   local key=S.Key(candidate);if not seen[key] then result[#result+1]=candidate;seen[key]=true end
  end
 end end
 return result,notice
end
function S.ClearVisits() ForeverCompanionDB=ForeverCompanionDB or {};ForeverCompanionDB.visitedMerchants={} end
function S.Resolve(target)
 local key=S.Key(target);if not key then return end
 for _,p in ipairs(S.ForMap(target.map)) do if S.Key(p)==key then return target end end
end
function S.Status(map)
 local points,notice=S.ForMap(map);local counts,unique={},{}
 for _,p in ipairs(points) do counts[p.symbol]=(counts[p.symbol] or 0)+1;unique[(p.npcID or p.label)..':'..p.x..':'..p.y]=true end
 local total=0;for _ in pairs(unique) do total=total+1 end
 return {locations=total,services=#points,counts=counts,notice=notice,loading=loaded==false}
end
local events=CreateFrame('Frame')
pcall(events.RegisterEvent,events,'MERCHANT_SHOW')
events:SetScript('OnEvent',function()
 if ForeverCompanionDB and ForeverCompanionDB.recordMerchantVisits==false then return end
 local guid=read(UnitGUID,'npc');local name=text(read(UnitName,'npc'))
 if not text(guid) or not name then return end
 local id=tonumber(guid:match('^Creature%-%d+%-%d+%-%d+%-%d+%-(%d+)%-') or guid:match('^Vehicle%-%d+%-%d+%-%d+%-%d+%-(%d+)%-'))
 local map=C_Map and read(C_Map.GetBestMapForUnit,'player')
 local position=map and C_Map and read(C_Map.GetPlayerMapPosition,map,'player')
 local x,y
 if position and not (issecretvalue and issecretvalue(position)) and type(position.GetXY)=='function' then local ok,a,b=pcall(position.GetXY,position);if ok then x,y=a,b end end
 if S.RecordVisit({map=map,x=x,y=y,label=name,npcID=id,repair=read(CanMerchantRepair)==true,at=read(GetServerTime)}) then
  if ForeverCompanionQuestMap then ForeverCompanionQuestMap.Refresh() end
  if ForeverCompanionServiceAtlas then ForeverCompanionServiceAtlas.Refresh() end
 end
end)
