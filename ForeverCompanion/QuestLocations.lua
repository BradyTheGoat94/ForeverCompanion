-- Runtime reader for the separately installed Forever QuestieDB public API.
local R={}
ForeverCompanionQuestLocations=R

local function read(fn,...)
 if type(fn)~="function" then return end
 local ok,value=pcall(fn,...)
 if ok then return value end
end

local function provider()
 local db=LibQuestieDB
 if type(db)~="table" or read(db.RequireContract,1)~=true then return end
 local status=db.ModeIndicator and read(db.ModeIndicator.GetStatus)
 local flavor=type(status)=="table" and status.expansion
 if not flavor then
  local metadata=C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata
  flavor=read(metadata,"QuestieDB","X-Flavor")
 end
 if type(flavor)=="string" and flavor:lower()=="forever" and type(db.Quest)=="table" then return db end
end

local mapText,areaMaps
local function maps(db)
 local zones=db.Support and read(db.Support.Get,"ZoneDB")
 local raw=zones and zones.private and zones.private.areaIdToUiMapId
 if type(raw)~="string" then return {} end
 if raw~=mapText then
  mapText,areaMaps=raw,{}
  -- The provider exposes Lua text. Read numeric entries only.
  local clean=raw:gsub("%-%-[^\r\n]*","")
  for area,map in clean:gmatch("%[(%d+)%]%s*=%s*(%d+)%s*[,}]") do
   areaMaps[tonumber(area)]=tonumber(map)
  end
 end
 return areaMaps
end

R.Provider=provider
R.AreaMaps=maps

local function append(result,zoneMaps,spawns,kind,name,objective)
 if type(spawns)~="table" then return end
 for area,coords in pairs(spawns) do
  local map=zoneMaps[area]
  local info=map and map>0 and C_Map and read(C_Map.GetMapInfo,map)
  -- Reject continent/world aliases. Dungeon entries require verified native
  -- coordinates; provider compatibility mappings alone cannot establish them.
  if type(info)=="table" and (info.mapType==3 or info.mapType==5) and type(coords)=="table" then
   for _,xy in ipairs(coords) do
    if type(xy)=="table" then
     local x,y,phase=xy[1],xy[2],xy[3]
     if type(x)=="number" and type(y)=="number" and x>=0 and x<=100 and y>=0 and y<=100 and (not phase or phase==0) then
      result[#result+1]={map=map,x=x/100,y=y/100,source="QuestieDB "..kind,kind=kind,label=name,objective=objective}
     end
    end
   end
  end
 end
end

local function entity(result,mapsByArea,db,kind,id,action,objective)
 if not db or type(id)~="number" or id<=0 then return end
 local spawns=read(db.spawns,id)
 local name=read(db.name,id)
 append(result,mapsByArea,spawns,action or kind,name,objective)
end

local function normalized(text)
 if type(text)~="string" then return "" end
 return text:lower():gsub("[%p%s]+"," "):match("^%s*(.-)%s*$")
end

local function mentions(text,name)
 local term=normalized(name)
 if #term<3 then return false end
 local haystack=" "..normalized(text).." "
 if haystack:find(" "..term.." ",1,true) then return true end
 if not haystack:find(" "..term.."s ",1,true) and not haystack:find(" "..term.."es ",1,true) then
  local plural=term:gsub("fe$","ves"):gsub("f$","ves"):gsub("y$","ies")
  return plural~=term and haystack:find(" "..plural.." ",1,true)~=nil
 end
 return true
end

local function candidates(db,objectives)
 local result={monster={},object={},item={}}
 local lists={[1]=result.monster,[2]=result.object,[3]=result.item,[5]=result.monster}
 local sources={[1]=db.Npc,[2]=db.Object,[3]=db.Item,[5]=db.Npc}
 for _,kind in ipairs({1,2,3,5}) do
  local source=sources[kind]
  for _,row in ipairs(type(objectives[kind])=="table" and objectives[kind] or {}) do
   if type(row)=="table" then
    local credit=kind==5
    local id,description,count=row[1],row[2],row[3]
    if credit then id,description,count=row[2],row[3],row[4] end
    lists[kind][#lists[kind]+1]={id=id,name=source and read(source.name,id),description=description,count=count,
     alternates=credit and row[1] or nil}
   end
  end
 end
 return result
end

local function objectiveMatch(list,text,required)
 local matched
 for _,row in ipairs(list) do
  local countMatches=not required or type(row.count)~="number" or row.count<=0 or required==row.count
  if countMatches and (mentions(text,row.name) or mentions(text,row.description)) then
   if matched then return end
   matched=row
  end
 end
 return matched
end

function R.ForQuest(quest)
 local db=provider()
 if not db or not quest or type(quest.id)~="number" or quest.id<=0 then return {} end
 local result={}
 if normalized(read(db.Quest.name,quest.id))~=normalized(quest.title) then return result end
 local zones=maps(db)
 if quest.complete then
  local endings=read(db.Quest.finishedBy,quest.id)
  if type(endings)=="table" then
   for _,id in ipairs(type(endings[1])=="table" and endings[1] or {}) do entity(result,zones,db.Npc,"npc",id,"turn-in") end
   for _,id in ipairs(type(endings[2])=="table" and endings[2] or {}) do entity(result,zones,db.Object,"object",id,"turn-in") end
  end
 else
  local objectives=read(db.Quest.objectives,quest.id)
  local groups=candidates(db,type(objectives)=="table" and objectives or {})
  local states=quest.objectiveStates or {}
  for i,state in ipairs(states) do
   if state.known and not state.done then
    local kind,text=state.kind,quest.objectives[i]
    local list=kind and groups[kind]
    local row=list and objectiveMatch(list,text,state.required)
    if row and kind=="monster" then
     if type(row.alternates)=="table" and #row.alternates>0 then
      for _,id in ipairs(row.alternates) do entity(result,zones,db.Npc,"npc",id,nil,text) end
     else
      entity(result,zones,db.Npc,"npc",row.id,nil,text)
     end
    elseif row and kind=="object" then
     entity(result,zones,db.Object,"object",row.id,nil,text)
    elseif row and kind=="item" and db.Item then
     local npcs,objects=read(db.Item.npcDrops,row.id),read(db.Item.objectDrops,row.id)
     for _,id in ipairs(type(npcs)=="table" and npcs or {}) do entity(result,zones,db.Npc,"npc",id,"drop",text) end
     for _,id in ipairs(type(objects)=="table" and objects or {}) do entity(result,zones,db.Object,"object",id,"drop",text) end
    elseif kind=="event" then
     local trigger=read(db.Quest.triggerEnd,quest.id)
     if type(trigger)=="table" and mentions(text,trigger[1]) then
      append(result,zones,trigger[2],"event",trigger[1],text)
     end
    end
   end
  end
 end
 return result
end

function R.IsAvailable() return provider()~=nil end
