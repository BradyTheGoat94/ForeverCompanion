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

-- Only native, explicitly reported quest starts. This is not an eligibility
-- inference: the player must inspect and accept the quest in the game.
function W.MapPickups(map,quests)
 if ForeverCompanionDB and ForeverCompanionDB.questMapHidePickups then return {} end
 local extra,status={}
 if ForeverCompanionAvailableQuests then extra,status=ForeverCompanionAvailableQuests.ForMap(map,quests) end
 W.PickupStatus=status
 local api=C_QuestLog
 if type(api)~="table" then return extra end
 local records=read(api.GetQuestsOnMap,map)
 if type(records)~="table" then return extra end
 local active,seen,result={},{},{}
 for _,q in ipairs(quests or {}) do if q.id then active[q.id]=true end end
 for _,entry in ipairs(records) do
  local candidate=read(function()
   if entry.mapID~=map or entry.isQuestStart~=true or type(entry.questID)~="number" or entry.questID<=0 or active[entry.questID] then return end
   local target=point(map,entry.x,entry.y,"WoW quest pickup")
   local title=read(api.GetTitleForQuestID,entry.questID)
   if not target or type(title)~="string" or title=="" then return end
   target.kind="pickup"
   return {quest={id=entry.questID,title=title,complete=false},target=target,pickup=true}
  end)
  if candidate then
   local key=candidate.quest.id..":"..candidate.target.x..":"..candidate.target.y
   if not seen[key] then seen[key]=true;result[#result+1]=candidate end
  end
 end
 for _,entry in ipairs(extra) do
  local key=entry.quest.id..":"..entry.target.x..":"..entry.target.y
  if not seen[key] then seen[key]=true;result[#result+1]=entry end
 end
 table.sort(result,function(a,b)
  if a.quest.id~=b.quest.id then return a.quest.id<b.quest.id end
  if a.target.x~=b.target.x then return a.target.x<b.target.x end
  return a.target.y<b.target.y
 end)
 return result
end

local function openMap(map)
 local open=(C_Map and C_Map.OpenWorldMap) or OpenWorldMap
 return type(open)=="function" and pcall(open,map)
end

W.OpenMap=openMap

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

function W.HasNavigation()
 return ForeverCompanionQuestDirection.IsActive() or W.HasOwnPin()
end

function W.Clear()
 local stopped=ForeverCompanionQuestDirection.Stop()
 if W.HasOwnPin() and type(C_Map.ClearUserWaypoint)=="function"
  and pcall(C_Map.ClearUserWaypoint) and not W.HasOwnPin() then
  owned=nil
  return true
 end
 return stopped
end

function W.Navigate(target,showMap,label)
 if not target then return "No map location for this quest." end
 local direction=ForeverCompanionQuestDirection
 direction.Stop()
 local hud=direction.Start(target,label)
 local pinned=false
 if C_Map and type(C_Map.SetUserWaypoint)=="function"
  and UiMapPoint and type(UiMapPoint.CreateFromCoordinates)=="function"
  and (type(C_Map.CanSetUserWaypointOnMap)~="function" or read(C_Map.CanSetUserWaypointOnMap,target.map)==true) then
  local marker=read(UiMapPoint.CreateFromCoordinates,target.map,target.x,target.y)
  pinned=marker and pcall(C_Map.SetUserWaypoint,marker)
   and (type(C_Map.GetUserWaypoint)~="function" or read(sameWaypoint,target)==true)
  if pinned then owned=target end
 end
 if showMap then
  local opened=type(OpenMapToUserWaypoint)=="function" and pinned and pcall(OpenMapToUserWaypoint)
  if not opened then openMap(target.map) end
 end
 if hud then return "On-screen arrow active" end
 if not pinned then return "Navigation unavailable for this map." end
 local track=C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint
 local arrow=type(track)=="function" and pcall(track,true)
 local tracking=C_SuperTrack and C_SuperTrack.IsSuperTrackingUserWaypoint
 if arrow and type(tracking)=="function" then arrow=read(tracking)==true end
 return arrow and "Blizzard waypoint arrow active" or "Map pin set"
end


function W.Show(quest)
 local target=W.Location(quest)
 if target then
  return W.Navigate(target,true,quest.title)
 end
 local map=referenceMap(quest)
 if map and openMap(map) then return "Click a highlighted marker to start the arrow." end
 local current=C_Map and read(C_Map.GetBestMapForUnit,"player")
 if current and #W.MapLocations(current,{quest})>0 and openMap(current) then
  return "Click a highlighted marker to start the arrow."
 end
 if #referenceLocations(quest)>0 then return "Open a zone map to choose a marker." end
 return "No map location for this quest."
end
