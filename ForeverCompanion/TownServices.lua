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
 if type(value)~="number" or value<=0 then return end
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
 local name=read(db.Npc.name,id) or matched[1][2]
 for area,points in pairs(spawns) do
  local map=maps[area]
  if map and map>0 and type(points)=="table" then
   for _,point in ipairs(points) do
    local x,y,phase=point[1],point[2],point[3]
    if type(x)=="number" and type(y)=="number" and x>=0 and x<=100 and y>=0 and y<=100 and (not phase or phase==0) then
     local entries=results[map]
     if not entries then entries={};results[map]=entries end
     for _,service in ipairs(matched) do
      entries[#entries+1]={map=map,x=x/100,y=y/100,label=name,service=service[2],symbol=service[3]}
     end
    end
   end
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
  end
 end
 C_Timer.After(0,batch)
end

function S.ForMap(map)
 local db=ForeverCompanionQuestLocations.Provider()
 local side=read(UnitFactionGroup,"player")
 if not db or (side~="Alliance" and side~="Horde") then
  database,faction,byMap,loaded,loadError=nil,nil,nil,nil,nil
  return {}, "QuestieDB needed for town pins"
 end
 side=side:sub(1,1)
 if database~=db or faction~=side then start(db,side) end
 if database~=db or faction~=side then return {}, "Town service data unavailable" end
 if not loaded then return {}, "Loading town services…" end
 if loadError then return {},loadError end
 local info=C_Map and read(C_Map.GetMapInfo,map)
 if type(info)~="table" or (info.mapType~=3 and info.mapType~=5) then return {} end
 return byMap[map] or {}
end
