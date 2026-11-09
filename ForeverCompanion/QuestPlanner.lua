-- Read-only live quest log with optional manual notes; no quest automation or invented route data.
local addonName = ...
local Planner = {}
ForeverCompanionQuestPlanner = Planner
local db
local function trim(s) return (s or ""):match("^%s*(.-)%s*$") end
local function say(s) print("|cffffcc66Forever Companion Planner:|r "..s) end
local function ensure()
  ForeverCompanionDB = ForeverCompanionDB or {}
  db = ForeverCompanionDB
  if type(db.quests) ~= "table" then db.quests = {} end
  if type(db.questSort) ~= "string" then db.questSort = "zone" end
  if type(db.questPins) ~= "table" then db.questPins = {} end
  return db.quests
end
local function clean(value, limit)
  value = trim(tostring(value or "")):gsub("[\r\n\t]", " ")
  return value:sub(1, limit)
end
function Planner.GetAll()
  return ensure()
end
function Planner.Add(name, zone)
  local entries=ensure()
  name=clean(name,100)
  zone=clean(zone,70)
  if name=="" then return false, "Provide a quest name." end
  if #entries>=100 then return false, "Quest planner limit (100) reached." end
  for _,e in ipairs(entries) do
    if type(e)=="table" and type(e.name)=="string" and e.name:lower()==name:lower() then return false,"Already tracked." end
  end
  entries[#entries+1]={name=name,zone=zone~="" and zone or "Unassigned",done=false}
  return true,"Added: "..name
end
function Planner.Toggle(index)
  local entries=ensure()
  index=tonumber(index)
  if not index or not entries[index] then return false,"Invalid quest number." end
  if type(entries[index])~="table" or type(entries[index].name)~="string" then return false,"Invalid saved quest entry." end
  entries[index].done=not entries[index].done
  return true,(entries[index].done and "Completed: " or "Reopened: ")..entries[index].name
end
function Planner.Remove(index)
  local entries=ensure()
  index=tonumber(index)
  if not index or not entries[index] then return false,"Invalid quest number." end
  local name=type(entries[index])=="table" and entries[index].name or "Invalid entry"
  table.remove(entries,index)
  return true,"Removed: "..name
end
function Planner.Summary()
  local entries=ensure()
  local done=0
  for _,e in ipairs(entries) do if type(e)=="table" and e.done==true then done=done+1 end end
  return done,#entries
end
function Planner.Format()
  local entries=ensure()
  local result={"PERSONAL NOTES (optional)", "Custom goals separate from the automatically detected quest log.", "Commands: /fcq add Quest name | Zone", "/fcq done 1   /fcq remove 1   /fcq list"}
  if #entries==0 then result[#result+1]="No quests tracked yet." end
  for i,e in ipairs(entries) do
    if type(e)=="table" and type(e.name)=="string" then
      result[#result+1]=i..". "..(e.done and "[x] " or "[ ] ")..clean(e.name,100).." — "..clean(e.zone or "Unassigned",70)
    else
      result[#result+1]=i..". [invalid saved quest entry — remove to repair]"
    end
  end
  local done,total=Planner.Summary()
  result[#result+1]="Progress: "..done.."/"..total
  return table.concat(result,"\n\n")
end

-- Read-only quest-log synchronization. Never accepts/turns in quests or changes tracking.
local auto = {entries={}, supported=false, scanned=false, lastCount=0, selected=1, filter="all"}
-- Keep the same objective contract across both modern log enumerators.
local function quantity(value)
 if issecretvalue and issecretvalue(value) then return nil end
 local n=tonumber(value)
 if type(n)=='number' and n==n and n>=0 and n<math.huge then return n end
end
local function objectiveState(obj)
 local ok,state=pcall(function()
  local current,required=quantity(obj.numFulfilled),quantity(obj.numRequired)
  local known,done=false,false
  if type(obj.finished)=='boolean' then known,done=true,obj.finished
  elseif type(obj.isComplete)=='boolean' then known,done=true,obj.isComplete
  elseif current and required and required>0 then known,done=true,current>=required end
  return {known=known,done=done,current=current,required=required,kind=type(obj.type)=='string' and obj.type or nil}
 end)
 return ok and state or {known=false,done=false}
end
local function questRows()
  local rows={}
  local modern=C_QuestLog
  if type(modern)=="table" then
    local indexed=type(modern.GetNumQuestLogEntries)=="function" and type(modern.GetInfo)=="function"
    local ok,count=false,0
    if indexed then ok,count=pcall(modern.GetNumQuestLogEntries) end
    local indexedValid=ok and type(count)=="number" and count>=0 and count<=1000
    -- Some clients hide entries beneath collapsed headers in the indexed log.
    -- Prefer the read-only full quest list when available, without expanding
    -- the player's headers or changing Blizzard's watched quest state.
    if type(modern.GetQuestLogQuests)=="function" then
      local allOK,all=pcall(modern.GetQuestLogQuests)
      if allOK and type(all)=="table" and #all>0 then
        local seen={}
        local result={}
        for _,info in ipairs(all) do
          if type(info)=="table" and type(info.title)=="string" and info.title~="" then
            local id=info.questID
            local key=type(id)=="number" and ("id:"..id) or ("title:"..info.title)
            if not seen[key] then
              seen[key]=true
              local completed=info.isComplete==true
              if type(id)=="number" and type(modern.IsComplete)=="function" then
                local done,value=pcall(modern.IsComplete,id)
                if done and type(value)=="boolean" then completed=value end
              end
              local objectives,objectiveStates={},{}
              if type(id)=="number" and type(modern.GetQuestObjectives)=="function" then
                local got,items=pcall(modern.GetQuestObjectives,id)
                if got and type(items)=="table" then
                  for _,obj in ipairs(items) do
                    if type(obj)=="table" and type(obj.text)=="string" then
                      objectives[#objectives+1]=clean(obj.text,140)
                      objectiveStates[#objectiveStates+1]=objectiveState(obj)
                    end
                  end
                end
              end
              local zone=type(info.zoneName)=="string" and info.zoneName or nil
              result[#result+1]={id=id,title=clean(info.title,100),level=quantity(info.level),
                zone=zone and clean(zone,70) or "Unspecified zone",zoneKnown=zone~=nil,
                complete=completed,objectives=objectives,objectiveStates=objectiveStates}
            end
          end
        end
        if #result>0 then return result,true end
      end
    end
    if not indexedValid then
      -- A missing or temporarily failing indexed API must not block the
      -- Classic-era fallback or wipe the previous successful snapshot.
      rows=nil
    else
    local header="Quest log"
    local headerKnown=false
    for i=1,count do
      local good,info=pcall(modern.GetInfo,i)
      if not good then info=nil end
      if type(info)=="table" then
        if info.isHeader then
          if type(info.title)=="string" and info.title~="" then
            header=clean(info.title,70)
            headerKnown=true
          end
        elseif type(info.title)=="string" and info.title~="" then
          local id=info.questID
          local completed=info.isComplete==true
          if type(id)=="number" and type(modern.IsComplete)=="function" then
            local done,value=pcall(modern.IsComplete,id)
            if done and type(value)=="boolean" then completed=value end
          end
          local objectives,objectiveStates={},{}
          if type(id)=="number" and type(modern.GetQuestObjectives)=="function" then
            local got,items=pcall(modern.GetQuestObjectives,id)
            if got and type(items)=="table" then
              for _,obj in ipairs(items) do
                if type(obj)=="table" and type(obj.text)=="string" then
                  objectives[#objectives+1]=clean(obj.text,140)
                  objectiveStates[#objectiveStates+1]=objectiveState(obj)
                end
              end
            end
          end
          local directZone=type(info.zoneName)=="string" and info.zoneName~="" and info.zoneName
            or (type(info.zone)=="string" and info.zone~="" and info.zone)
          local zoneKnown=not not (directZone or headerKnown)
          rows[#rows+1]={id=id,title=clean(info.title,100),level=quantity(info.level),zone=zoneKnown and clean(directZone or header,70) or "Unspecified zone",zoneKnown=zoneKnown,complete=completed,objectives=objectives,objectiveStates=objectiveStates}
        end
      end
    end
    return rows,true
    end
  end
  -- Some Classic-era clients expose only the legacy read-only quest-log API.
  -- Never select, accept, complete or change a quest while inspecting it.
  if type(GetNumQuestLogEntries)=="function" and type(GetQuestLogTitle)=="function" then
    local ok,count=pcall(GetNumQuestLogEntries)
    if not ok or type(count)~="number" or count<0 or count>1000 then return {},false end
    local header="Quest log"
    local headerKnown=false
    for i=1,count do
      local good,title,questLevel,suggestedGroup,isHeader,isCollapsed,isComplete,frequency,questID=pcall(GetQuestLogTitle,i)
      if not good then return {},false end
      if isHeader then
        if type(title)=="string" and title~="" then
          header=clean(title,70)
          headerKnown=true
        end
      elseif type(title)=="string" and title~="" then
        local objectives,objectiveStates={},{}
        if type(GetNumQuestLeaderBoards)=="function" and type(GetQuestLogLeaderBoard)=="function" then
          local countOK,objectiveCount=pcall(GetNumQuestLeaderBoards,i)
          if countOK and type(objectiveCount)=="number" and objectiveCount>=0 and objectiveCount<=100 then
            for j=1,objectiveCount do
              local itemOK,description,objectiveKind,finished=pcall(GetQuestLogLeaderBoard,j,i)
              if itemOK and type(description)=="string" and description~="" then
                objectives[#objectives+1]=clean(description,140)
                objectiveStates[#objectiveStates+1]={known=type(finished)=="boolean",done=finished==true,kind=type(objectiveKind)=="string" and objectiveKind or nil}
              end
            end
          end
        end
        rows[#rows+1]={
          id=type(questID)=="number" and questID or nil,level=quantity(questLevel),
          title=clean(title,100),zone=headerKnown and header or "Unspecified zone",zoneKnown=headerKnown,
          complete=isComplete==true or isComplete==1,
          objectives=objectives,objectiveStates=objectiveStates
        }
      end
    end
    return rows,true
  end
  return rows,false
end
local function refresh()
  if ForeverCompanionQuestMap then ForeverCompanionQuestMap.Refresh() end
  if ForeverCompanionRefresh then ForeverCompanionRefresh() end
end

function Planner.IsAutoFocus()
  ensure()
  return db.questAutoFocus~=false
end

function Planner.SetAutoFocus(enabled)
  ensure()
  db.questAutoFocus=enabled==true
  refresh()
end

local function questKey(quest)
  return quest.id or (quest.zone.."\n"..quest.title)
end

function Planner.Sync()
  local rows,supported=questRows()
  auto.supported=supported
  auto.scanned=true
  if not supported then
    -- Preserve last successful snapshot if the client temporarily cannot provide quest data.
    refresh()
    return false
  end
  local previous=auto.entries
  local old=previous[auto.selected]
  local oldKey=old and questKey(old)
  local known={}
  for _,quest in ipairs(previous) do known[questKey(quest)]=true end
  local firstNew,matched
  for i,quest in ipairs(rows) do
    local key=questKey(quest)
    if oldKey==key then matched=i end
    if not firstNew and not known[key] then firstNew=i end
  end
  auto.entries=rows
  auto.lastCount=#rows
  local followNew=Planner.IsAutoFocus() and not (old and Planner.IsPinned(old) and matched)
  auto.selected=(followNew and firstNew) or matched or 1
  refresh()
  return true
end
-- Pins are addon-only, per-character planning metadata. They never change the
-- game's quest tracking or map markers. Prefer stable quest IDs where supplied.
local function pinKey(quest)
  if type(quest)~="table" then return nil end
  if type(quest.id)=="number" and quest.id>0 then return "id:"..tostring(quest.id) end
  if type(quest.title)~="string" or quest.title=="" then return nil end
  return "name:"..quest.title:lower().."@"..tostring(quest.zone or ""):lower()
end
function Planner.IsPinned(quest)
  ensure()
  local key=pinKey(quest)
  return key~=nil and db.questPins[key]==true
end
function Planner.TogglePin(index)
  ensure()
  index=tonumber(index)
  if not index or index%1~=0 or index<1 or index>#auto.entries then return false,"Invalid active quest number." end
  local quest=auto.entries[index]
  local key=pinKey(quest)
  if not key then return false,"This quest has no usable identity." end
  if not db.questPins[key] then
    local count=0
    for _,pinned in pairs(db.questPins) do if pinned==true then count=count+1 end end
    if count>=100 then return false,"Pin limit reached (100); unpin an older quest first." end
    db.questPins[key]=true
  else
    db.questPins[key]=nil
  end
  if ForeverCompanionRefresh then ForeverCompanionRefresh() end
  return true,(db.questPins[key] and "Pinned: " or "Unpinned: ")..quest.title
end
function Planner.ClearPins()
  ensure()
  db.questPins={}
  if ForeverCompanionRefresh then ForeverCompanionRefresh() end
  return true,"Cleared all addon-only quest pins."
end
function Planner.PinnedCount()
  local count=0
  for _,quest in ipairs(auto.entries) do if Planner.IsPinned(quest) then count=count+1 end end
  return count
end
function Planner.GetPinned()
  for i,quest in ipairs(auto.entries) do
    if Planner.IsPinned(quest) then return quest,i end
  end
end
function Planner.AutoCount() return auto.lastCount end
function Planner.GetFilter() return auto.filter end
function Planner.IsSupported() return auto.supported end
function Planner.IsSnapshotStale() return auto.scanned and not auto.supported and #auto.entries>0 end
function Planner.HasZoneMetadata()
  for _,q in ipairs(auto.entries) do if q.zoneKnown then return true end end
  return false
end
function Planner.CycleFilter()
  if auto.filter=="all" then auto.filter="ready"
  elseif auto.filter=="ready" then auto.filter=Planner.HasZoneMetadata() and "zone" or "all"
  else auto.filter="all" end
  if ForeverCompanionRefresh then ForeverCompanionRefresh() end
end
local sortModes={"log","zone","ready","pinned"}
function Planner.GetSort()
  ensure()
  if db.questSort~="log" and db.questSort~="zone" and db.questSort~="ready" and db.questSort~="pinned" then
    db.questSort="log"
  end
  return db.questSort
end
function Planner.CycleSort()
  local mode=Planner.GetSort()
  for i,name in ipairs(sortModes) do
    if mode==name then
      db.questSort=sortModes[(i % #sortModes)+1]
      break
    end
  end
  if ForeverCompanionRefresh then ForeverCompanionRefresh() end
  return db.questSort
end
function Planner.GetVisible()
  local visible={}
  local zone
  if type(GetRealZoneText)=="function" then
    local ok,value=pcall(GetRealZoneText)
    if ok and type(value)=="string" then zone=value end
  end
  if not zone and type(GetZoneText)=="function" then
    local ok,value=pcall(GetZoneText)
    if ok and type(value)=="string" then zone=value end
  end
  local anyZoneKnown=Planner.HasZoneMetadata()
  for i,q in ipairs(auto.entries) do
    if auto.filter=="all" or (auto.filter=="ready" and q.complete)
      or (auto.filter=="zone" and (not zone or zone=="" or not anyZoneKnown or not q.zoneKnown or q.zone==zone)) then
      visible[#visible+1]={index=i,quest=q}
    end
  end
  local mode=Planner.GetSort()
  if mode~="log" then
    table.sort(visible,function(a,b)
      local aq,bq=a.quest,b.quest
      if mode=="ready" and aq.complete~=bq.complete then return aq.complete==true end
      if mode=="pinned" then
        local ap,bp=Planner.IsPinned(aq),Planner.IsPinned(bq)
        if ap~=bp then return ap end
      end
      local az,bz=(aq.zone or ""):lower(),(bq.zone or ""):lower()
      if az~=bz then return az<bz end
      local at,bt=(aq.title or ""):lower(),(bq.title or ""):lower()
      if at~=bt then return at<bt end
      return a.index<b.index
    end)
  end
  return visible
end
function Planner.ReadyCount()
  local count=0
  for _,q in ipairs(auto.entries) do if q.complete then count=count+1 end end
  return count
end
function Planner.ObjectiveProgress(quest)
  local q=quest
  if not q then q=auto.entries[auto.selected] end
  if type(q)~="table" or type(q.objectiveStates)~="table" then return nil end
  local known,done=0,0
  for _,state in ipairs(q.objectiveStates) do
    if type(state)=="table" and state.known then
      known=known+1
      if state.done then done=done+1 end
    end
  end
  if known==0 then return nil end
  return done,known
end
function Planner.GetLive() return auto.entries end
function Planner.GetSelected()
  if #auto.entries==0 then return nil end
  if auto.selected>#auto.entries then auto.selected=1 end
  return auto.entries[auto.selected],auto.selected
end
function Planner.Select(index)
  index=tonumber(index)
  if not index or not auto.entries[index] then return false end
  auto.selected=index
  Planner.SetAutoFocus(false)
  return true
end
function Planner.Next()
  if #auto.entries==0 then return false end
  return Planner.Select((auto.selected % #auto.entries)+1)
end
function Planner.Previous()
  if #auto.entries==0 then return false end
  return Planner.Select(((auto.selected-2) % #auto.entries)+1)
end
function Planner.Recommend()
  if not auto.supported then return "Quest data unavailable; last known quests may be outdated. Check the in-game quest log." end
  if #auto.entries==0 then return "No active quests detected yet." end
  local ready={}
  local unfinished={}
  for i,q in ipairs(auto.entries) do
    if q.complete then ready[#ready+1]=q.title else unfinished[#unfinished+1]={i=i,q=q} end
  end
  if #ready>0 then return "Ready for turn-in: "..ready[1]..". Check your in-game quest log for the destination." end
  local pinned=Planner.GetPinned()
  if pinned and not pinned.complete then return "Pinned priority: "..pinned.title..". Review its objectives below." end
  local selected=Planner.GetSelected()
  if selected and not selected.complete then return "Focus quest: "..selected.title..". Review its objectives below." end
  return "Choose a quest to focus on. No route optimization data is available yet."
end
function Planner.FormatFocused()
  local q,index=Planner.GetSelected()
  if not q then return "No quest selected. Your active quest log will appear here." end
  local lines={"FOCUSED QUEST "..index.."/"..#auto.entries, q.title, q.complete and "Ready for turn-in" or "In progress"}
  if not auto.supported then lines[#lines+1]="WARNING: cached quest data; verify in game." end
  if Planner.IsPinned(q) then lines[#lines+1]="PINNED: personal priority (not a game map marker)" end
  if q.zone then lines[#lines+1]="Zone: "..q.zone end
  local done,known=Planner.ObjectiveProgress(q)
  if known then lines[#lines+1]="Known objectives complete: "..done.."/"..known end
  if #q.objectives==0 then lines[#lines+1]="No objective details available from this client." end
  for _,objective in ipairs(q.objectives) do lines[#lines+1]="  "..objective end
  return table.concat(lines,"\n")
end
-- Snapshot analytics use only the client's read-only quest log and retain stale warnings.
function Planner.Overview()
  local groups={}
  local ready=0
  for _,q in ipairs(auto.entries) do
    if q.complete then ready=ready+1 end
    local zone=type(q.zone)=="string" and q.zone~="" and q.zone or "Unspecified zone"
    groups[zone]=(groups[zone] or 0)+1
  end
  local zones={}
  for zone,count in pairs(groups) do zones[#zones+1]={zone=zone,count=count} end
  table.sort(zones,function(a,b)
    if a.count==b.count then return a.zone<b.zone end
    return a.count>b.count
  end)
  return {
    scanned=auto.scanned,
    supported=auto.supported,
    stale=Planner.IsSnapshotStale(),
    total=#auto.entries,
    ready=ready,
    pinned=Planner.PinnedCount(),
    remaining=#auto.entries-ready,
    zones=zones
  }
end
function Planner.FormatOverview()
  local report=Planner.Overview()
  local lines={"QUEST JOURNAL SUMMARY"}
  if not report.scanned then
    lines[#lines+1]="Waiting for the first quest-log scan."
  elseif not report.supported then
    lines[#lines+1]="Client quest API unavailable. Cached entries may be outdated."
  else
    lines[#lines+1]=report.total.." active | "..report.remaining.." in progress | "..report.ready.." ready | "..report.pinned.." pinned"
  end
  if report.total>0 then
    lines[#lines+1]="QUESTS BY ZONE (reported by client)"
    for i=1,math.min(4,#report.zones) do
      local zone=report.zones[i]
      lines[#lines+1]=zone.zone..": "..zone.count
    end
    if #report.zones>4 then lines[#lines+1]="+"..(#report.zones-4).." more zones in quest log" end
  end
  return table.concat(lines,"\n")
end
function Planner.FormatAuto()
  local result={"ACTIVE QUESTS", "Automatically detected from your quest log.", "NEXT STEP: "..Planner.Recommend()}
  if not auto.scanned then
    result[#result+1]="Waiting for the first quest-log scan."
  elseif not auto.supported then
    result[#result+1]="Quest API unavailable or scan failed. Any quests shown below are from the last successful scan and may be stale."
  elseif #auto.entries==0 then
    result[#result+1]="No active quests in the quest log."
  else
    local groups={}
    local names={}
    local ready=0
    for _,q in ipairs(auto.entries) do
      local zone=q.zone or "Other quests"
      if not groups[zone] then groups[zone]={}; names[#names+1]=zone end
      groups[zone][#groups[zone]+1]=q
      if q.complete then ready=ready+1 end
    end
    table.sort(names)
    result[#result+1]=#auto.entries.." active  |  "..ready.." ready to turn in"
    for _,zone in ipairs(names) do
      result[#result+1]="\n"..string.upper(zone)
      table.sort(groups[zone],function(a,b) return a.title<b.title end)
      for _,q in ipairs(groups[zone]) do
        result[#result+1]=(Planner.IsPinned(q) and "[Pinned] " or "")..(q.complete and "[Ready] " or "[ ] ")..q.title
        for j=1,math.min(#q.objectives,4) do result[#result+1]="  - "..q.objectives[j] end
      end
    end
  end
  return table.concat(result,"\n")
end
local events=CreateFrame("Frame")
for _,event in ipairs({"PLAYER_ENTERING_WORLD","QUEST_LOG_UPDATE","QUEST_ACCEPTED","QUEST_REMOVED","QUEST_TURNED_IN","QUEST_WATCH_UPDATE","QUEST_POI_UPDATE","UNIT_QUEST_LOG_CHANGED"}) do
  pcall(function() events:RegisterEvent(event) end)
end
-- Coalesce bursts of quest events after kills, looting and zone changes.
-- The scan remains read-only and does not alter Blizzard's watched quests.
local syncPending=false
local function scheduleSync()
  if syncPending then return end
  if not C_Timer or type(C_Timer.After)~="function" then
    Planner.Sync()
    return
  end
  syncPending=true
  C_Timer.After(.12,function()
    syncPending=false
    Planner.Sync()
  end)
end
events:SetScript("OnEvent",function(_,event,unit)
  if event=="UNIT_QUEST_LOG_CHANGED" and unit and unit~="player" then return end
  if event=="PLAYER_ENTERING_WORLD" then Planner.Sync()
  else scheduleSync() end
end)

SLASH_FOREVERCOMPANIONQUEST1="/fcq"
SlashCmdList.FOREVERCOMPANIONQUEST=function(msg)
  msg=trim(msg)
  local name,zone=msg:match("^add%s+([^|]+)%s*|%s*(.*)$")
  if not name then name=msg:match("^add%s+(.+)$") end
  local ok,answer
  if name then ok,answer=Planner.Add(name,zone)
  elseif msg:match("^done%s+%d+$") then ok,answer=Planner.Toggle(msg:match("%d+"))
  elseif msg:match("^remove%s+%d+$") then ok,answer=Planner.Remove(msg:match("%d+"))
  elseif msg=="previous" then
    if not Planner.Previous() then say("No active quests detected.") end
    return
  elseif msg=="next" then
    if not Planner.Next() then say("No active quests detected.") end
    return
  elseif msg:match("^focus%s+%d+$") then
    if not Planner.Select(msg:match("%d+")) then say("Invalid active quest number.") end
    return
  elseif msg=="filter" then
    Planner.CycleFilter()
    say("Quest filter: "..Planner.GetFilter())
    return
  elseif msg=="sort" then
    say("Quest sort: "..Planner.CycleSort())
    return
  elseif msg=="pin selected" then
    ok,answer=Planner.TogglePin(auto.selected)
  elseif msg:match("^pin%s+%d+$") then
    ok,answer=Planner.TogglePin(msg:match("%d+"))
  elseif msg=="clearpins" then
    ok,answer=Planner.ClearPins()
  elseif msg=="pins" then
    say(Planner.PinnedCount().." pinned active quests (addon-only priorities).")
    for i,q in ipairs(auto.entries) do if Planner.IsPinned(q) then say(i..". "..q.title) end end
    return
  elseif msg=="sync" then
    if Planner.Sync() then say("Quest log synchronized: "..Planner.AutoCount().." active quests.") else say("Quest log API not available.") end
    return
  elseif msg=="list" or msg=="" then
    local entries=Planner.GetAll()
    local done,total=Planner.Summary()
    say(done.."/"..total.." complete")
    for i,e in ipairs(entries) do say(i..". "..(e.done and "[x] " or "[ ] ")..e.name.." ("..e.zone..")") end
    return
  else say("Use /fcq sync, /fcq filter, /fcq sort, /fcq next, /fcq previous, /fcq focus N, /fcq add Quest | Zone"); return end
  say(answer)
  if ForeverCompanionRefresh then ForeverCompanionRefresh() end
end
