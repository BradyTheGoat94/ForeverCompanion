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

-- Match whole words in the provider's NPC subtitle. Keep unmatched subtitles
-- intact and avoid guessing a merchant's trade from a character name.
local vendorRoles={
 {'Mounts','Ability_Mount_RidingHorse',{'mount','mounts','horse breeder','ram breeder','wolf breeder','raptor breeder'}},
 {'Pet supplies','Ability_Hunter_BeastCall',{'pet','pets','stable master','animal companion','animal companions'}},
 {'Ammo & ranged supplies','INV_Ammo_Arrow_01',{'ammo','ammunition','arrows','bullets','bows','guns','gun merchant','bowyer','gunsmith'}},
 {'Food & drink','INV_Misc_Food_15',{'food','drink','drinks','bread','meat','cheese','fruit','fishmonger','baker','butcher','bartender','wine','ale','water','refreshments'}},
 {'Poison supplies','Ability_Poisons',{'poison','poisons','poison supplies'}},
 {'Reagents','INV_Misc_Dust_02',{'reagent','reagents','spell components'}},
 {'Patterns & recipes','INV_Scroll_03',{'recipe','recipes','pattern','patterns','schematic','schematics','plans','formula','formulas'}},
 {'Weapons & armor','INV_Sword_04',{'weapon','weapons','weaponsmith','armor','armour','armorer','armourer','armorsmith','mail armor','cloth armor','shields','staff merchant','daggers'}},
 {'Potions & alchemy','INV_Potion_54',{'potion','potions','alchemy','alchemical'}},
 {'Enchanting supplies','INV_Enchant_DustStrange',{'enchanting'}},
 {'Fishing supplies','INV_Fishingpole_02',{'fishing'}},
 {'Cooking supplies','INV_Misc_Food_19',{'cooking'}},
 {'Crafting materials','INV_Ingot_03',{'trade goods','crafting supplies','blacksmithing','engineering','tailoring','leatherworking','mining supplies','herbalism','clothier'}},
 {'PvP rewards','INV_BannerPVP_02',{'pvp','honor rewards','arena rewards','battleground rewards'}},
 {'General supplies','INV_Misc_Bag_08',{'general goods','general supplies','provisions'}},
}
function S.VendorProfile(subtitle)
 local cleaned=text(subtitle)
 if not cleaned then return end
 local words=' '..cleaned:lower():gsub('[^%w]+',' ')..' '
 local matches,icon={}
 for _,role in ipairs(vendorRoles) do
  for _,phrase in ipairs(role[3]) do
   if words:find(' '..phrase..' ',1,true) then
    matches[#matches+1]=role[1]
    icon=icon or role[2]
    break
   end
  end
 end
 if icon then return {label=table.concat(matches,', '),texture='Interface\\Icons\\'..icon} end
end
function S.ServiceLabel(point)
 local profile=point.vendorProfile
 return point.symbol=='V' and profile and profile.label or point.service or 'Service'
end
function S.StockLine(point)
 if point.symbol=='V' and type(point.stock)=='table' and #point.stock>0 then
  return 'Previously seen stock: '..table.concat(point.stock,', ')
 end
end
function S.ServiceDetails(point)
 local lines={}
 if point.subtitle then lines[#lines+1]=point.subtitle end
 if point.symbol=='V' then
  if point.canRepair then lines[#lines+1]='Also repairs equipment' end
  lines[#lines+1]=S.StockLine(point) or 'No item examples recorded'
 elseif point.symbol=='R' then
  lines[#lines+1]='Repairs equipment'
 end
 return table.concat(lines,'\n')
end

function S.MatchesRepairVendor(repair,vendor)
 return repair.symbol=='R' and vendor.symbol=='V' and vendor.vendorProfile and repair.npcID
  and repair.npcID==vendor.npcID and repair.x==vendor.x and repair.y==vendor.y
end

local stockLimit=5
local function cleanStock(names)
 if (issecretvalue and issecretvalue(names)) or type(names)~='table' then return end
 local result,seen={},{}
 for i=1,math.min(#names,stockLimit) do
  local name=text(names[i])
  if name and #name<=160 and not seen[name] then
   result[#result+1]=name
   seen[name]=true
  end
 end
 if #result>0 then return result end
end
function S.ReadMerchantStock()
 local count=read(GetMerchantNumItems)
 if not finite(count) or count<1 then return end
 local names,seen={},{}
 for i=1,math.min(count,30) do
  local info=C_MerchantFrame and read(C_MerchantFrame.GetItemInfo,i)
  local name
  if not (issecretvalue and issecretvalue(info)) and type(info)=='table' then name=text(info.name) end
  name=name or text(read(GetMerchantItemInfo,i))
  if name and #name<=160 and not seen[name] then
   names[#names+1]=name
   seen[name]=true
   if #names==stockLimit then break end
  end
 end
 if #names>0 then return names end
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
 local profile=seen.Vendor and S.VendorProfile(subtitle)
 for area,points in pairs(spawns) do
  local map=maps[area]
  if map and map>0 and type(points)=="table" then
   for _,point in ipairs(points) do if type(point)=='table' then
    local x,y,phase=point[1],point[2],point[3]
    if type(x)=="number" and type(y)=="number" and x>=0 and x<=100 and y>=0 and y<=100 and (not phase or phase==0) then
     local entries=results[map]
     if not entries then entries={};results[map]=entries end
     for _,service in ipairs(matched) do
      entries[#entries+1]={map=map,x=x/100,y=y/100,label=name,subtitle=subtitle,npcID=id,service=service[2],symbol=service[3],vendorProfile=profile,canRepair=seen.Repairs==true,source='Forever QuestieDB reference'}
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
 -- Mailboxes are also world objects; NPC flags alone miss these spawns.
 local object=db.Object
 local spawns=object and read(object.spawns,32349)
 for area,points in pairs(type(spawns)=='table' and spawns or {}) do
  local map=maps[area]
  if map and type(points)=='table' then
   for _,xy in ipairs(points) do
    if type(xy)=='table' and finite(xy[1]) and finite(xy[2]) and (not xy[3] or xy[3]==0) then
     local pin={map=map,x=xy[1]/100,y=xy[2]/100,label='Mailbox',symbol='M',service='Mailbox',source='Forever QuestieDB mailbox object'}
     if valid(pin) then results[map]=results[map] or {};table.insert(results[map],pin) end
    end
   end
  end
 end
 database,faction,byMap,loaded,loadError=db,side,results,false,nil
 local function batch()
  if results~=byMap then return end
  for i=index,math.min(index+119,#ids) do indexNpc(db,ids[i],flags,maps,side,results) end
  index=index+120
  if index<=#ids then C_Timer.After(.02,batch)
  else
   loaded=true
   if ForeverCompanionQuestMinimap then ForeverCompanionQuestMinimap.Refresh() end
   if ForeverCompanionQuestMap then ForeverCompanionQuestMap.Refresh() end
   if ForeverCompanionServiceAtlas then ForeverCompanionServiceAtlas.Refresh() end
   if ForeverCompanionMapHub then ForeverCompanionMapHub.Invalidate() end
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
 if ForeverCompanionMapHub then ForeverCompanionMapHub.Invalidate() end
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
 local stock=cleanStock(record.stock)
 for i=#records,1,-1 do
  local old=records[i]
  if type(old)=='table' and old.map==record.map and old.npcID==record.npcID then
   stock=stock or cleanStock(old.stock)
   table.remove(records,i)
  end
 end
 table.insert(records,1,{map=record.map,x=record.x,y=record.y,label=text(record.label),npcID=record.npcID,repair=record.repair==true,at=record.at,stock=stock})
 while #records>100 do table.remove(records) end
 if ForeverCompanionMapHub then ForeverCompanionMapHub.Invalidate() end
 return true
end
-- Rounded city coordinates from Forever Guide (Forever Scout / EG Link).
-- https://guide.wow4ever.se/en/objects/{696278,650666,650577,658926,658920}
-- EG Link attribution: https://creativecommons.org/licenses/by/4.0/
local cityMail={
 ['Stormwind City']={{61,49}},
 ['Ironforge']={{72,50},{22,52}},
 ['Orgrimmar']={{52,47},{38,75}},
}
function S.ForMap(map)
 local points,notice=providerMap(map)
 local result,seen,known,localVisits={},{},{},{}
 for _,p in ipairs(visits()) do
  if valid(p) and p.map==map and finite(p.npcID) then
   localVisits[p.npcID]=localVisits[p.npcID] or p
  end
 end
 for _,p in ipairs(points) do
  local key=S.Key(p)
  if key and not seen[key] then
   if p.symbol=='V' then
    known[p.npcID]=p
    local visit=localVisits[p.npcID]
    if visit then
     local enriched={}
     for field,value in pairs(p) do enriched[field]=value end
     enriched.stock=cleanStock(visit.stock)
     enriched.canRepair=p.canRepair or visit.repair==true
     p=enriched
    end
   end
   result[#result+1]=p;seen[key]=true
  end
 end
 local info=C_Map and read(C_Map.GetMapInfo,map)
 for _,xy in ipairs(cityMail[info and info.name] or {}) do
  local x,y=xy[1]/100,xy[2]/100
  local duplicate=false
  for _,pin in ipairs(result) do
   if pin.symbol=='M' and math.abs(pin.x-x)<.006 and math.abs(pin.y-y)<.006 then duplicate=true;break end
  end
  if not duplicate then result[#result+1]={map=map,x=x,y=y,label='Mailbox',symbol='M',service='Mailbox',subtitle='Approximate city location',source='Forever Guide city reference'} end
 end
 for _,p in ipairs(visits()) do if valid(p) and p.map==map and finite(p.npcID) then
  local reference=known[p.npcID]
  for _,service in ipairs(p.repair and {{'V','Vendor'},{'R','Repairs'}} or {{'V','Vendor'}}) do
   local candidate={map=p.map,x=p.x,y=p.y,label=p.label,npcID=p.npcID,symbol=service[1],service=service[2],observed=true,at=p.at,subtitle=reference and reference.subtitle,vendorProfile=reference and reference.vendorProfile,canRepair=p.repair==true,stock=cleanStock(p.stock),source='Visited nearby · player position at merchant visit'}
   local key=S.Key(candidate);if not seen[key] then result[#result+1]=candidate;seen[key]=true end
  end
 end end
 return result,notice
end
function S.ClearVisits()
 ForeverCompanionDB=ForeverCompanionDB or {};ForeverCompanionDB.visitedMerchants={}
 if ForeverCompanionMapHub then ForeverCompanionMapHub.Invalidate() end
end
function S.Resolve(target)
 local key=S.Key(target);if not key then return end
 for _,p in ipairs(S.ForMap(target.map)) do if S.Key(p)==key and (p.observed==true)==(target.observed==true) then return p end end
end
function S.Status(map)
 local points,notice=S.ForMap(map);local counts,unique={},{}
 for _,p in ipairs(points) do counts[p.symbol]=(counts[p.symbol] or 0)+1;unique[(p.npcID or p.label)..':'..p.x..':'..p.y]=true end
 local total=0;for _ in pairs(unique) do total=total+1 end
 return {locations=total,services=#points,counts=counts,notice=notice,loading=loaded==false}
end
local events=CreateFrame('Frame')
pcall(events.RegisterEvent,events,'MERCHANT_SHOW')
pcall(events.RegisterEvent,events,'MERCHANT_UPDATE')
pcall(events.RegisterEvent,events,'MERCHANT_CLOSED')
local pendingStock
events:SetScript('OnEvent',function(_,event)
 if event=='MERCHANT_CLOSED' then pendingStock=nil;return end
 if event=='MERCHANT_SHOW' or not event then pendingStock=nil end
 if event=='MERCHANT_UPDATE' and not pendingStock then return end
 if ForeverCompanionDB and ForeverCompanionDB.recordMerchantVisits==false then return end
 local guid=read(UnitGUID,'npc');local name=text(read(UnitName,'npc'))
 if not text(guid) or not name then return end
 -- An update may arrive after changing NPC targets.
 if event=='MERCHANT_UPDATE' and pendingStock~=guid then pendingStock=nil;return end
 local stock=S.ReadMerchantStock()
 if event=='MERCHANT_UPDATE' and not stock then return end
 pendingStock=not stock and guid or nil
 local id=tonumber(guid:match('^Creature%-%d+%-%d+%-%d+%-%d+%-(%d+)%-') or guid:match('^Vehicle%-%d+%-%d+%-%d+%-%d+%-(%d+)%-'))
 local map=C_Map and read(C_Map.GetBestMapForUnit,'player')
 local position=map and C_Map and read(C_Map.GetPlayerMapPosition,map,'player')
 local x,y
 if position and not (issecretvalue and issecretvalue(position)) and type(position.GetXY)=='function' then local ok,a,b=pcall(position.GetXY,position);if ok then x,y=a,b end end
 if S.RecordVisit({map=map,x=x,y=y,label=name,npcID=id,repair=read(CanMerchantRepair)==true,at=read(GetServerTime),stock=stock}) then
  if ForeverCompanionQuestMap then ForeverCompanionQuestMap.Refresh() end
  if ForeverCompanionServiceAtlas then ForeverCompanionServiceAtlas.Refresh() end
  if ForeverCompanionMapOverlay then ForeverCompanionMapOverlay.Refresh(true) end
 end
end)
