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

local function mapPoints(map)
 local records=type(C_QuestLog)=="table" and read(C_QuestLog.GetQuestsOnMap,map)
 local points={}
 if type(records)~="table" then return points end
 for _,entry in ipairs(records) do
  local id,candidate=read(function()
   if type(entry.questID)=="number" and entry.questID>0 and entry.mapID==map and entry.isQuestStart==false then
    return entry.questID,point(map,entry.x,entry.y,"WoW quest map")
   end
  end)
  if candidate then
   local locations=points[id] or {}
   points[id]=locations
   locations[candidate.x..":"..candidate.y]=candidate
  end
 end
 return points
end

local function nextWaypoint(id)
 if type(C_QuestLog)~="table" then return end
 local map,x,y=read(C_QuestLog.GetNextWaypoint,id)
 return point(map,x,y,"WoW quest log")
end

local function clientLocation(id)
 local waypoint=read(nextWaypoint,id)
 if waypoint then return waypoint end
 -- The requested map is the coordinate frame for these POIs.
 if type(C_Map)~="table" then return end
 local current=read(C_Map.GetBestMapForUnit,"player")
 if type(current)~="number" or current<=0 then return end
 local locations=mapPoints(current)[id]
 if not locations then return end
 local key,found=next(locations)
 if key and not next(locations,key) then return found end
end

local function referenceLocations(quest)
 return read(ForeverCompanionQuestLocations.ForQuest,quest) or {}
end

local function uniqueReference(quest)
 local target
 for _,candidate in ipairs(referenceLocations(quest)) do
  if target and (target.map~=candidate.map or target.x~=candidate.x or target.y~=candidate.y) then return end
  target=candidate
 end
 return target
end

function W.Location(quest)
 if type(quest)~="table" or type(quest.id)~="number" or quest.id<=0 then return end
 return read(clientLocation,quest.id) or uniqueReference(quest)
end

function W.MapLocations(map,quests)
 local points=mapPoints(map)
 local result={}
 for index,quest in ipairs(quests) do
  if type(quest.id)=="number" and quest.id>0 then
   local locations=points[quest.id] or {}
   local waypoint=read(nextWaypoint,quest.id)
   if not next(locations) and waypoint and waypoint.map==map then
    locations[waypoint.x..":"..waypoint.y]=waypoint
   end
   for _,target in ipairs(referenceLocations(quest)) do
    if target.map==map then
     local key=target.x..":"..target.y
     if not locations[key] then locations[key]=target end
    end
   end
   for _,target in pairs(locations) do
    result[#result+1]={quest=quest,target=target,index=index}
   end
  end
 end
 table.sort(result,function(a,b)
  if a.index~=b.index then return a.index<b.index end
  if a.target.x~=b.target.x then return a.target.x<b.target.x end
  return a.target.y<b.target.y
 end)
 return result
end

local function openMap(map)
 local open=(C_Map and C_Map.OpenWorldMap) or OpenWorldMap
 return type(open)=="function" and pcall(open,map)
end

local function referenceMap(quest)
 local first,ambiguous
 local current=C_Map and read(C_Map.GetBestMapForUnit,"player")
 for _,target in ipairs(referenceLocations(quest)) do
  if target.map==current then return current end
  if first and target.map~=first then ambiguous=true end
  first=first or target.map
 end
 if not ambiguous then return first end
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

function W.Navigate(target,showMap)
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
 if showMap then
  local opened=type(OpenMapToUserWaypoint)=="function" and W.HasOwnPin() and pcall(OpenMapToUserWaypoint)
  if not opened then openMap(target.map) end
 end
 return (arrow and "Pin and arrow set" or "Map pin set").."  •  "..target.source
end


function W.Show(quest)
 local target=W.Location(quest)
 if target then
  local message=W.Navigate(target,true)
  if not W.HasOwnPin() then openMap(target.map) end
  return message
 end
 local map=referenceMap(quest)
 if map and openMap(map) then return "Shift-click a map marker for an arrow." end
 local current=C_Map and read(C_Map.GetBestMapForUnit,"player")
 if current and #W.MapLocations(current,{quest})>0 and openMap(current) then
  return "Shift-click a map marker for an arrow."
 end
 if #referenceLocations(quest)>0 then return "Open a zone map to choose a marker." end
 return "No map location for this quest."
end
