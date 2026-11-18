-- Player-clicked navigation only. Never moves the player or changes quest progress.
local W={}
ForeverCompanionQuestWaypoints=W
local owned
local navigation,lastNotice
local function finite(n) return not(issecretvalue and issecretvalue(n)) and type(n)=='number' and n==n and math.abs(n)<math.huge end

local function read(fn,...)
 if type(fn)~="function" then return end
 local ok,a,b,c=pcall(fn,...)
 if ok then return a,b,c end
end

local function point(map,x,y,source)
 if not finite(map) or map<=0 or map%1~=0 then return end
 if not finite(x) or not (x>=0 and x<=1) then return end
 if not finite(y) or not (y>=0 and y<=1) then return end
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
 local result={}
 for _,t in ipairs(read(ForeverCompanionQuestLocations.ForQuest,quest) or {}) do
  local reported=ForeverCompanionQuestLocations.IsReported
  if (not reported or not reported(quest,t)) and (not ForeverCompanionQuestLocations.AllowsLocation or ForeverCompanionQuestLocations.AllowsLocation(quest,t)) then result[#result+1]=t end
 end
 return result
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
 local waypoint=read(nextWaypoint,quest.id)
 local allowed=ForeverCompanionQuestLocations.AllowsLocation
 if waypoint and (not allowed or allowed(quest,waypoint)) then return waypoint end
 for _,candidate in ipairs(W.Targets(quest)) do
  local state=quest.objectiveStates and quest.objectiveStates[candidate.objectiveIndex]
  if not quest.complete and state and not state.done then return candidate end
 end
 local native=read(clientLocation,quest.id)
 local allows=ForeverCompanionQuestLocations.AllowsLocation
 if native and (not allows or allows(quest,native)) then return native end
 return uniqueReference(quest)
end
-- Collect all actual destinations without pretending a general native POI
-- belongs to a specific objective. Provider matches retain objective indices.
function W.Targets(quest)
 if type(quest)~='table' or type(quest.id)~='number' or quest.id<=0 then return {} end
 local result,seen={},{}
 local function add(target,reference)
  if not target or not point(target.map,target.x,target.y,target.source) then return end
  if ForeverCompanionQuestLocations.AllowsLocation and not ForeverCompanionQuestLocations.AllowsLocation(quest,target) then return end
  local key=target.map..':'..target.x..':'..target.y..':'..tostring(target.objectiveIndex or target.objective or 'quest')
  if seen[key] then return end
  seen[key]=true
  local copy={}
  for k,v in pairs(target) do copy[k]=v end
  copy.reference=reference==true
  result[#result+1]=copy
 end
 add(read(nextWaypoint,quest.id),false)
 local map=C_Map and read(C_Map.GetBestMapForUnit,'player')
 if map then for _,target in pairs(mapPoints(map)[quest.id] or {}) do add(target,false) end end
 for _,target in ipairs(referenceLocations(quest)) do add(target,true) end
 table.sort(result,function(a,b)
  if a.source=='WoW quest log' and b.source~=a.source then return true end
  if b.source=='WoW quest log' and a.source~=b.source then return false end
  if a.reference~=b.reference then return not a.reference end
  if a.objectiveIndex~=b.objectiveIndex then return (a.objectiveIndex or math.huge)<(b.objectiveIndex or math.huge) end
  if a.map~=b.map then return a.map<b.map end
  if a.x~=b.x then return a.x<b.x end
  if a.y~=b.y then return a.y<b.y end
  return (a.objectiveIndex or 0)<(b.objectiveIndex or 0)
 end)
 return result
end

-- A coordinate is a reference point, not proof of exact objective position.
function W.Describe(target)
 if type(target)~='table' then return 'Location unavailable' end
 if target.source=='Personal map note' then return 'Personal saved position' end
 if target.observed then return 'Visited nearby · player position at interaction' end
 if target.service then return 'Service spawn reference · availability unverified' end
 if target.kind=='turn-in' then return 'Turn-in reference · inspect the giver in game' end
 if target.kind=='pickup' then return 'Quest-giver reference · confirm availability' end
 if target.kind or target.reference then
  return (target.objectiveIndex or target.objective) and 'Objective search reference · exact position unverified' or 'General quest reference · objective match unknown'
 end
 return 'Client-reported quest point · may represent a general search area'
end
function W.Explain(quest,map)
 local targets=W.Targets(quest)
 if #targets>0 then
  for _,t in ipairs(targets) do if not map or t.map==map then return W.Describe(t) end end
  return 'Reported destinations are on other maps. Open the field guide to inspect them.'
 end
 local provider=ForeverCompanionQuestLocations and ForeverCompanionQuestLocations.Provider
 if type(provider)=='function' and not read(provider) then return 'No client destination reported; compatible Forever QuestieDB references are unavailable.' end
 return 'No destination reported by the client or installed reference data. Read the quest text; no location is guessed.'
end

function W.MapLocations(map,quests)
 local points=mapPoints(map)
 local result={}
 for index,quest in ipairs(quests) do
  if type(quest.id)=="number" and quest.id>0 then
   local locations=points[quest.id] or {}
   local waypoint=read(nextWaypoint,quest.id)
   if waypoint and waypoint.map==map then
    locations[waypoint.x..":"..waypoint.y]=waypoint
   end
   for _,target in ipairs(referenceLocations(quest)) do
    if target.map==map then
     local key=target.x..":"..target.y
     if not locations[key] then locations[key]=target end
    end
   end
   for _,target in pairs(locations) do
    if not ForeverCompanionQuestLocations.AllowsLocation or ForeverCompanionQuestLocations.AllowsLocation(quest,target) then result[#result+1]={quest=quest,target=target,index=index} end
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
function W.MapPickups(map,quests,ignoreVisibility)
 if not ignoreVisibility and ForeverCompanionDB and ForeverCompanionDB.questMapHidePickups then return {} end
 local extra,status={}
 if ForeverCompanionAvailableQuests then extra,status=ForeverCompanionAvailableQuests.ForMap(map,quests,ignoreVisibility) end
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
 local before=W.HasNavigation()
 local stopped=ForeverCompanionQuestDirection.Stop()
 local locked=read(InCombatLockdown)==true
 if not locked and W.HasOwnPin() and type(C_Map.ClearUserWaypoint)=='function'
  and pcall(C_Map.ClearUserWaypoint) and not W.HasOwnPin() then owned=nil end
 local remains=W.HasNavigation()
 if not remains then navigation=nil
 elseif stopped then navigation=nil;lastNotice='On-screen directions stopped. The map pin remains; clear it on the world map when possible.' end
 return stopped==true or (before and not remains)
end
function W.Active()
 if not navigation or not W.HasNavigation() then return end
 local copy={};for k,v in pairs(navigation) do copy[k]=v end;return copy
end
function W.LastNotice() return lastNotice end
function W.DismissNotice() lastNotice=nil end
function W.SameTarget(a,b)
 if type(a)~='table' or type(b)~='table' then return false end
 if not point(a.map,a.x,a.y) or not point(b.map,b.x,b.y) then return false end
 return a.map==b.map and math.abs(a.x-b.x)<.000001 and math.abs(a.y-b.y)<.000001
  and a.objectiveIndex==b.objectiveIndex and a.kind==b.kind
  and (not a.entityID or a.entityID==b.entityID)
  and (not a.source or a.source==b.source)
end
-- Re-resolve identity and destination before acting on a marker from an older paint.
function W.ResolveActiveEntry(entry,quests,targetReader)
 if type(entry)~='table' or type(entry.quest)~='table' then return end
 local nativeReader=targetReader==nil
 targetReader=targetReader or W.Targets
 for index,q in ipairs(quests or {}) do
  if q.id and q.id==entry.quest.id then
   if q.complete~=entry.quest.complete then return end
   local state=q.objectiveStates and q.objectiveStates[entry.target and entry.target.objectiveIndex]
   if type(state)=='table' and state.known and state.done then return end
   for _,target in ipairs(read(targetReader,q) or {}) do
    if W.SameTarget(entry.target,target) then return q,index,target end
   end
   -- A viewed world map may differ from the player's current map.
   if nativeReader and entry.target and finite(entry.target.map) then
    for _,target in pairs(mapPoints(entry.target.map)[q.id] or {}) do
     if W.SameTarget(entry.target,target) then return q,index,target end
    end
   end
   return
  end
 end
end
-- Passive cleanup only: never picks a new objective, quest, waypoint or destination.
function W.Reconcile(quests,supported)
 if not navigation or not navigation.questID then return end
 if not W.HasNavigation() then navigation=nil;return end
 local reason
 if supported~=true then reason='Quest data unavailable. Directions paused; reopen the quest log and choose a destination again.'
 else
  local quest
  for _,q in ipairs(quests or {}) do if q.id==navigation.questID then quest=q;break end end
  if not quest then reason='Quest left your log. Old directions stopped.'
  elseif navigation.kind~='turn-in' and not navigation.completeAtStart and quest.complete then reason='Quest ready to turn in. Review the giver before starting new directions.'
  elseif navigation.objectiveIndex then
   local state=quest.objectiveStates and quest.objectiveStates[navigation.objectiveIndex]
   if type(state)=='table' and state.known and state.done then reason='Objective complete. Old directions stopped; choose your next objective.' end
  end
  if not reason and navigation.questItemID then
   local supplies=ForeverCompanionQuestSupplies
   local fresh=supplies and read(supplies.ResolveDestination,navigation,quests,supported)
   if not fresh or not W.SameTarget(navigation,fresh) then reason='Quest item source changed or was excluded. Review the quest guide before traveling.' end
  elseif not reason and navigation.reference then
   local found=false
   for _,target in ipairs(W.Targets(quest)) do if W.SameTarget(navigation,target) then found=true;break end end
   if not found then reason='Location reference changed or was excluded. Review the quest guide before traveling.' end
  end
 end
 if reason then
  W.Clear();navigation=nil;lastNotice=reason
  if W.HasOwnPin() then lastNotice=lastNotice..' The old map pin remains; clear it on the world map when possible.' end
 end
end

function W.Navigate(target,showMap,label,questID)
 if type(target)~='table' or not point(target.map,target.x,target.y) then return "No valid map location for this destination." end
 if questID and ForeverCompanionQuestLocations and ForeverCompanionQuestLocations.AllowsLocation and not ForeverCompanionQuestLocations.AllowsLocation({id=questID},target) then return 'This destination conflicts with the published current event area. Open quest details.' end
 if target.questItemID then
  local supplies=ForeverCompanionQuestSupplies;local planner=ForeverCompanionQuestPlanner
  local fresh=supplies and read(supplies.ResolveDestination,target,planner and read(planner.GetLive) or {},planner and read(planner.IsSupported)==true)
  if not fresh or fresh.questID~=questID then return 'Quest item source could not be revalidated. Reopen the quest guide.' end
  target=fresh
 end
 local direction=ForeverCompanionQuestDirection
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
 -- Start validates before replacing its previous arrow. Do not stop it merely
 -- because a new attempt failed; reconcile only after a successful handoff.
 if pinned and not hud then direction.Stop() end
 if hud and not pinned and W.HasOwnPin() and type(C_Map.ClearUserWaypoint)=='function' then
  if pcall(C_Map.ClearUserWaypoint) and not W.HasOwnPin() then owned=nil end
 end
 if showMap then
  local opened=type(OpenMapToUserWaypoint)=="function" and pinned and pcall(OpenMapToUserWaypoint)
  if not opened then openMap(target.map) end
 end
 if hud or pinned then
  navigation={map=target.map,x=target.x,y=target.y,questID=questID,objectiveIndex=target.objectiveIndex,kind=target.kind,entityID=target.entityID,source=target.source,reference=target.reference==true or target.kind~=nil,label=label,questItemID=target.questItemID,sourceField=target.sourceField,sourceEntityID=target.sourceEntityID,questTitle=target.questTitle}
  local planner=ForeverCompanionQuestPlanner
  for _,q in ipairs(planner and read(planner.GetLive) or {}) do if q.id==questID then navigation.completeAtStart=q.complete==true;break end end
  lastNotice=nil
 end
 if (hud or pinned) and ForeverCompanionMapHub then ForeverCompanionMapHub.Record(target,label,questID) end
 if hud then return "On-screen arrow active" end
 if not pinned then
  if direction.IsActive and direction.IsActive() then return 'New destination unavailable; previous navigation is still active.' end
  return "Navigation unavailable for this map."
 end
 local track=C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint
 local arrow=type(track)=="function" and pcall(track,true)
 local tracking=C_SuperTrack and C_SuperTrack.IsSuperTrackingUserWaypoint
 if arrow and type(tracking)=="function" then arrow=read(tracking)==true end
 return arrow and "Blizzard waypoint arrow active" or "Map pin set"
end


function W.Show(quest)
 local target=W.Location(quest)
 if target then
  return W.Navigate(target,true,quest.title,quest.id)
 end
 local map=referenceMap(quest)
 if map and openMap(map) then return "Click a highlighted marker to start the arrow." end
 local current=C_Map and read(C_Map.GetBestMapForUnit,"player")
 if current and #W.MapLocations(current,{quest})>0 and openMap(current) then
  return "Click a highlighted marker to start the arrow."
 end
 if #referenceLocations(quest)>0 then return "Open a zone map to choose a marker." end
 return W.Explain(quest)
end
