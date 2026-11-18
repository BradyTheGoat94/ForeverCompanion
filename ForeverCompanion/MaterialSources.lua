-- Search a separately installed Forever database on explicit request only.
-- Original adapter; all records remain references, never verified drop rates.
local S={};ForeverCompanionMaterialSources=S
local generation,results,provider,query,loading,truncated=0,{},nil,'',false,false
local function read(fn,...)
 if type(fn)~='function' then return end
 local ok,a=pcall(fn,...);if ok then return a end
end
local function finite(n) return not (issecretvalue and issecretvalue(n)) and type(n)=='number' and n==n and math.abs(n)<math.huge end
local function clean(s) return type(s)=='string' and s:lower():match('^%s*(.-)%s*$') or '' end
local function database()
 local r=ForeverCompanionQuestLocations;local db=r and read(r.Provider)
 return db and type(db.Item)=='table' and db or nil
end
function S.Cancel()
 generation=generation+1;loading=false;results={};query=''
end
function S.Results()
 if provider~=database() then S.Cancel();provider=nil;results={} end
 return results,loading,truncated,query
end
function S.Search(term,onComplete)
 S.Cancel();results={};provider=database();query=clean(term);truncated=false
 local numeric=tonumber(query)
 if not finite(numeric) or numeric<=0 or numeric%1~=0 then numeric=nil end
 if #query<2 and not numeric then return false,'Enter at least two letters or an exact item ID.' end
 if not provider then return false,'Compatible Forever QuestieDB item data is unavailable. General references and your manual goals still work.' end
 local items=provider.Item
 local ids=numeric and numeric>0 and numeric%1==0 and {numeric} or read(items.GetAllIds)
 if type(ids)~='table' or not C_Timer or type(C_Timer.After)~='function' then return false,'Database search is unavailable on this client.' end
 loading=true;local cursor,token=1,generation;local db=provider
 local function batch()
  if token~=generation then return end
  if database()~=db then S.Cancel();results={};return end
  for i=cursor,math.min(cursor+79,#ids) do
   local id=ids[i]
   if finite(id) and id>0 and id%1==0 then
    local name=read(items.name,id)
    if type(name)=='string' and (numeric==id or clean(name):find(query,1,true)) then
     results[#results+1]={id=id,name=name,kind='Database',source='Forever QuestieDB item reference',zone='Select Sources to inspect recorded drops, objects and vendors',status='Reference data; availability and drop rates are unverified'}
     if #results>=100 then truncated=true;break end
    end
   end
  end
  cursor=cursor+80
  if not truncated and cursor<=#ids then C_Timer.After(.01,batch)
  else
   loading=false;table.sort(results,function(a,b) if a.name~=b.name then return a.name<b.name end;return a.id<b.id end)
   if type(onComplete)=='function' then onComplete() end
  end
 end
 C_Timer.After(0,batch)
 return true,'Searching the installed Forever item database…'
end
local function locations(db,entity,id)
 local r=ForeverCompanionQuestLocations;local maps=r.AreaMaps(db)
 local spawns=entity and read(entity.spawns,id);local points,seen={},{}
 for area,list in pairs(type(spawns)=='table' and spawns or {}) do
  local map=maps[area];local info=map and C_Map and read(C_Map.GetMapInfo,map)
  if type(info)=='table' and (info.mapType==3 or info.mapType==5) then
   for _,xy in ipairs(type(list)=='table' and list or {}) do
    if type(xy)=='table' and finite(xy[1]) and finite(xy[2]) and xy[1]>=0 and xy[1]<=100 and xy[2]>=0 and xy[2]<=100 and (xy[3]==nil or xy[3]==0) then
     local key=map..':'..xy[1]..':'..xy[2]
     if not seen[key] then seen[key]=true;points[#points+1]={map=map,x=xy[1]/100,y=xy[2]/100,zone=info.name or ('Map '..map),source='Forever QuestieDB material source',reference=true,entityID=id} end
     if #points>=48 then break end
    end
   end
  end
  if #points>=48 then break end
 end
 table.sort(points,function(a,b) if a.map~=b.map then return a.map<b.map end;if a.x~=b.x then return a.x<b.x end;return a.y<b.y end)
 return points
end
function S.ItemName(itemID)
 local db=database();if not db or not finite(itemID) or itemID<=0 or itemID%1~=0 then return end
 local name=read(db.Item.name,itemID)
 if not (issecretvalue and issecretvalue(name)) and type(name)=='string' and name~='' then return name end
end
function S.ForItem(itemID)
 local db=database();if not db or not finite(itemID) or itemID<=0 or itemID%1~=0 then return {},'Item source data unavailable.' end
 local result,seen={},{}
 local name=read(db.Item.name,itemID)
 if type(name)~='string' or name=='' then return {},'This item is no longer present in the installed source.' end
 for _,spec in ipairs({{'npcDrops',db.Npc,'Enemy drop'},{'objectDrops',db.Object,'Gather / open object'},{'vendors',db.Npc,'Vendor reference'},{'itemDrops',db.Item,'Container reference'}}) do
  local entity=spec[2]
  local ids=read(db.Item[spec[1]],itemID)
  for _,id in ipairs(type(ids)=='table' and ids or {}) do
   local key=spec[1]..':'..tostring(id)
   if finite(id) and id>0 and id%1==0 and not seen[key] then
    seen[key]=true
    local sourceName=entity and read(entity.name,id)
    local source={id=id,itemID=itemID,field=spec[1],name=type(sourceName)=='string' and sourceName or ('Source #'..id),kind=spec[3],points=spec[1]=='itemDrops' and {} or locations(db,entity,id)}
    result[#result+1]=source;if #result>=60 then return result,'Showing the first 60 source references; narrow the search in game.' end
   end
  end
 end
 return result,#result>0 and 'Forever database references. No drop rate, current spawn or vendor stock is guaranteed.' or 'No recorded drop, object, vendor or container source. This does not prove the item has no source.'
end
function S.Resolve(itemID,field,entityID,target)
 if type(target)~='table' or not finite(target.x) or not finite(target.y) then return end
 for _,source in ipairs(S.ForItem(itemID)) do
  if source.field==field and source.id==entityID then
   for _,point in ipairs(source.points) do
    if point.map==target.map and math.abs(point.x-target.x)<.000001 and math.abs(point.y-target.y)<.000001 then return point end
   end
  end
 end
end
