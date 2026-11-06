-- Player-clicked navigation only. Never moves the player or changes quest progress.
local W={}
ForeverCompanionQuestWaypoints=W
local owned

local function read(fn,...)
 if type(fn)~="function" then return end
 local ok,a,b,c=pcall(fn,...)
 if ok then return a,b,c end
end

local function point(map,x,y,source)
 if type(map)~="number" or map<=0 or map>=math.huge or map%1~=0 then return end
 if type(x)~="number" or not (x>=0 and x<=1) then return end
 if type(y)~="number" or not (y>=0 and y<=1) then return end
 return {map=map,x=x,y=y,source=source}
end

local function clientLocation(id)
 if type(C_QuestLog)~="table" then return end
 local map,x,y=read(C_QuestLog.GetNextWaypoint,id)
 local waypoint=point(map,x,y,"WoW quest log")
 if waypoint then return waypoint end
 -- The requested map is the coordinate frame for these POIs.
 if type(C_Map)~="table" then return end
 local current=read(C_Map.GetBestMapForUnit,"player")
 if type(current)~="number" or current<=0 then return end
 local records=read(C_QuestLog.GetQuestsOnMap,current)
 if type(records)~="table" then return end
 local found
 for _,entry in ipairs(records) do
  if type(entry)=="table" and entry.questID==id and entry.mapID==current and entry.isQuestStart==false then
   local candidate=point(current,entry.x,entry.y,"WoW quest map")
   if candidate then
    if found and (found.x~=candidate.x or found.y~=candidate.y) then return end
    found=candidate
   end
  end
 end
 return found
end

-- Optional public QuestieDB consumer API. Require the Forever flavor and
-- a single fixed turn-in location. Never execute the provider's map strings.
local function referenceTurnIn(quest)
 local db=LibQuestieDB
 if not quest.complete or type(db)~="table" then return end
 local status=db.ModeIndicator and read(db.ModeIndicator.GetStatus)
 local flavor=type(status)=="table" and status.expansion
 -- Baked QuestieDB releases advertise their flavor in TOC metadata.
 if not flavor then
  local metadata=type(C_AddOns)=="table" and C_AddOns.GetAddOnMetadata or GetAddOnMetadata
  flavor=read(metadata,"QuestieDB","X-Flavor")
 end
 if type(flavor)~="string" or flavor:lower()~="forever" or read(db.RequireContract,1)~=true then return end
 local qdb=db.Quest
 if type(qdb)~="table" or read(qdb.name,quest.id)~=quest.title then return end
 local ends=read(qdb.finishedBy,quest.id)
 if type(ends)~="table" then return end
 local kind,ids=next(ends)
 if not kind or next(ends,kind) or type(ids)~="table" or #ids~=1 then return end
 local entity=kind==1 and db.Npc or (kind==2 and db.Object)
 local spawns=entity and read(entity.spawns,ids[1])
 if type(spawns)~="table" then return end
 local area,coords=next(spawns)
 if type(area)~="number" or area%1~=0 or next(spawns,area)
  or type(coords)~="table" or #coords~=1 or type(coords[1])~="table" then return end
 local x,y,phase=coords[1][1],coords[1][2],coords[1][3]
 if type(x)~="number" or type(y)~="number" or (phase and phase~=0) then return end
 local zones=db.Support and read(db.Support.Get,"ZoneDB")
 local mapList=zones and zones.private and zones.private.areaIdToUiMapId
 if type(mapList)~="string" then return end
 local map=tonumber(mapList:match("%["..area.."%]%s*=%s*(%d+)%s*[,}]"))
 local candidate=point(map,x/100,y/100,"QuestieDB turn-in")
 if candidate and C_Map and type(read(C_Map.GetMapInfo,map))=="table" then return candidate end
end

function W.Location(quest)
 if type(quest)~="table" or type(quest.id)~="number" or quest.id<=0 then return end
 -- Some client builds restrict quest fields. Treat inaccessible values as missing.
 return read(function() return clientLocation(quest.id) or referenceTurnIn(quest) end)
end

local function sameWaypoint(wanted)
 local actual=C_Map and read(C_Map.GetUserWaypoint)
 if not actual or not wanted then return false end
 local position=actual.position
 local x,y
 if position then x,y=read(position.GetXY,position) end
 -- Vector2D normally exposes GetXY; some test clients expose plain coordinates.
 if position and x==nil then x,y=position.x,position.y end
 return actual.uiMapID==wanted.map and type(x)=="number" and type(y)=="number"
  and math.abs(x-wanted.x)<.00001 and math.abs(y-wanted.y)<.00001
end

function W.HasOwnPin()
 return read(sameWaypoint,owned)==true
end

function W.Clear()
 if not W.HasOwnPin() or type(C_Map.ClearUserWaypoint)~="function" then return false end
 if not pcall(C_Map.ClearUserWaypoint) or W.HasOwnPin() then return false end
 owned=nil
 return true
end

function W.Show(quest)
 local target=W.Location(quest)
 if not target then return "No map location for this quest." end
 if not C_Map or type(C_Map.SetUserWaypoint)~="function"
  or not UiMapPoint or type(UiMapPoint.CreateFromCoordinates)~="function" then
  return "This client can’t set a map pin."
 end
 if type(C_Map.CanSetUserWaypointOnMap)=="function" and read(C_Map.CanSetUserWaypointOnMap,target.map)~=true then
  return "This map doesn’t support pins."
 end
 local marker=read(UiMapPoint.CreateFromCoordinates,target.map,target.x,target.y)
 if not marker or not pcall(C_Map.SetUserWaypoint,marker)
  or (type(C_Map.GetUserWaypoint)=="function" and read(sameWaypoint,target)~=true) then
  return "Couldn’t set the map pin."
 end
 owned=target
 local track=C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint
 local arrow=type(track)=="function" and pcall(track,true)
 local tracking=C_SuperTrack and C_SuperTrack.IsSuperTrackingUserWaypoint
 if arrow and type(tracking)=="function" then arrow=read(tracking)==true end
 local open=C_Map.OpenWorldMap or OpenWorldMap
 local opened=type(OpenMapToUserWaypoint)=="function" and W.HasOwnPin() and pcall(OpenMapToUserWaypoint)
 if not opened and type(open)=="function" then pcall(open,target.map) end
 return (arrow and "Pin and arrow set" or "Map pin set").."  •  "..target.source
end
