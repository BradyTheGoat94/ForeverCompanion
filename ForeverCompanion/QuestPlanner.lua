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
    if e.name:lower()==name:lower() then return false,"Already tracked." end
  end
  entries[#entries+1]={name=name,zone=zone~="" and zone or "Unassigned",done=false}
  return true,"Added: "..name
end
function Planner.Toggle(index)
  local entries=ensure()
  index=tonumber(index)
  if not index or not entries[index] then return false,"Invalid quest number." end
  entries[index].done=not entries[index].done
  return true,(entries[index].done and "Completed: " or "Reopened: ")..entries[index].name
end
function Planner.Remove(index)
  local entries=ensure()
  index=tonumber(index)
  if not index or not entries[index] then return false,"Invalid quest number." end
  local name=entries[index].name
  table.remove(entries,index)
  return true,"Removed: "..name
end
function Planner.Summary()
  local entries=ensure()
  local done=0
  for _,e in ipairs(entries) do if e.done then done=done+1 end end
  return done,#entries
end
function Planner.Format()
  local entries=ensure()
  local result={"PERSONAL NOTES (optional)", "Custom goals separate from the automatically detected quest log.", "Commands: /fcq add Quest name | Zone", "/fcq done 1   /fcq remove 1   /fcq list"}
  if #entries==0 then result[#result+1]="No quests tracked yet." end
  for i,e in ipairs(entries) do
    result[#result+1]=i..". "..(e.done and "[x] " or "[ ] ")..e.name.." — "..e.zone
  end
  local done,total=Planner.Summary()
  result[#result+1]="Progress: "..done.."/"..total
  return table.concat(result,"\n\n")
end

-- Read-only quest-log synchronization. Never accepts/turns in quests or changes tracking.
local auto = {entries={}, supported=false, scanned=false, lastCount=0, selected=1, filter="all"}
local function questRows()
  local rows={}
  local modern=C_QuestLog
  if type(modern)=="table" and type(modern.GetNumQuestLogEntries)=="function" and type(modern.GetInfo)=="function" then
    local ok,count=pcall(modern.GetNumQuestLogEntries)
    if not ok or type(count)~="number" or count<0 or count>1000 then return rows,false end
    local header="Quest log"
    for i=1,count do
      local good,info=pcall(modern.GetInfo,i)
      if not good then return {},false end
      if type(info)=="table" then
        if info.isHeader then header=clean(info.title or header,70)
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
                  local known,done=false,false
                  local stateOK,stateKnown,stateDone=pcall(function()
                    if type(obj.finished)=="boolean" then return true,obj.finished end
                    if type(obj.isComplete)=="boolean" then return true,obj.isComplete end
                    local current=tonumber(obj.numFulfilled)
                    local required=tonumber(obj.numRequired)
                    if current and required and required>0 then return true,current>=required end
                    return false,false
                  end)
                  if stateOK then known,done=stateKnown,stateDone end
                  objectiveStates[#objectiveStates+1]={known=known,done=done}
                end
              end
            end
          end
          rows[#rows+1]={id=id,title=clean(info.title,100),zone=clean(info.zoneName or info.zone or header,70),complete=completed,objectives=objectives,objectiveStates=objectiveStates}
        end
      end
    end
    return rows,true
  end
  -- Some Classic-era clients expose only the legacy read-only quest-log API.
  -- Never select, accept, complete or change a quest while inspecting it.
  if type(GetNumQuestLogEntries)=="function" and type(GetQuestLogTitle)=="function" then
    local ok,count=pcall(GetNumQuestLogEntries)
    if not ok or type(count)~="number" or count<0 or count>1000 then return {},false end
    local header="Quest log"
    for i=1,count do
      local good,title,questLevel,suggestedGroup,isHeader,isCollapsed,isComplete,frequency,questID=pcall(GetQuestLogTitle,i)
      if not good then return {},false end
      if isHeader then
        header=clean(title or header,70)
      elseif type(title)=="string" and title~="" then
        local objectives,objectiveStates={},{}
        if type(GetNumQuestLeaderBoards)=="function" and type(GetQuestLogLeaderBoard)=="function" then
          local countOK,objectiveCount=pcall(GetNumQuestLeaderBoards,i)
          if countOK and type(objectiveCount)=="number" and objectiveCount>=0 and objectiveCount<=100 then
            for j=1,objectiveCount do
              local itemOK,description,_,finished=pcall(GetQuestLogLeaderBoard,j,i)
              if itemOK and type(description)=="string" and description~="" then
                objectives[#objectives+1]=clean(description,140)
                objectiveStates[#objectiveStates+1]={known=type(finished)=="boolean",done=finished==true}
              end
            end
          end
        end
        rows[#rows+1]={
          id=type(questID)=="number" and questID or nil,
          title=clean(title,100),zone=header,
          complete=isComplete==true or isComplete==1,
          objectives=objectives,objectiveStates=objectiveStates
        }
      end
    end
    return rows,true
  end
  return rows,false
end
function Planner.Sync()
  local rows,supported=questRows()
  auto.supported=supported
  auto.scanned=true
  if not supported then
    -- Preserve last successful snapshot if the client temporarily cannot provide quest data.
    if ForeverCompanionRefresh then ForeverCompanionRefresh() end
    return false
  end
  local old=auto.entries[auto.selected]
  auto.entries=rows
  auto.lastCount=#rows
  if old then
    local matched=false
    for i,q in ipairs(rows) do
      if (old.id and q.id==old.id) or (not old.id and q.title==old.title) then auto.selected=i; matched=true; break end
    end
    if not matched then auto.selected=1 end
  end
  if auto.selected>#rows then auto.selected=1 end
  if ForeverCompanionRefresh then ForeverCompanionRefresh() end
  return true
end
function Planner.AutoCount() return auto.lastCount end
function Planner.GetFilter() return auto.filter end
function Planner.IsSupported() return auto.supported end
function Planner.IsSnapshotStale() return auto.scanned and not auto.supported and #auto.entries>0 end
function Planner.HasZoneMetadata()
  for _,q in ipairs(auto.entries) do if type(q.zone)=="string" and q.zone~="" then return true end end
  return false
end
function Planner.CycleFilter()
  if auto.filter=="all" then auto.filter="ready"
  elseif auto.filter=="ready" then auto.filter=Planner.HasZoneMetadata() and "zone" or "all"
  else auto.filter="all" end
  if ForeverCompanionRefresh then ForeverCompanionRefresh() end
end
local sortModes={"log","zone","ready"}
function Planner.GetSort()
  ensure()
  if db.questSort~="log" and db.questSort~="zone" and db.questSort~="ready" then
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
  for i,q in ipairs(auto.entries) do
    if auto.filter=="all" or (auto.filter=="ready" and q.complete)
      or (auto.filter=="zone" and (not zone or zone=="" or not Planner.HasZoneMetadata() or not q.zone or q.zone==zone)) then
      visible[#visible+1]={index=i,quest=q}
    end
  end
  local mode=Planner.GetSort()
  if mode~="log" then
    table.sort(visible,function(a,b)
      local aq,bq=a.quest,b.quest
      if mode=="ready" and aq.complete~=bq.complete then return aq.complete==true end
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
  if not index or index<1 or index>#auto.entries then return false end
  auto.selected=index
  if ForeverCompanionRefresh then ForeverCompanionRefresh() end
  return true
end
function Planner.Next()
  if #auto.entries==0 then return false end
  auto.selected=(auto.selected % #auto.entries)+1
  if ForeverCompanionRefresh then ForeverCompanionRefresh() end
  return true
end
function Planner.Previous()
  if #auto.entries==0 then return false end
  auto.selected=((auto.selected-2) % #auto.entries)+1
  if ForeverCompanionRefresh then ForeverCompanionRefresh() end
  return true
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
  local selected=Planner.GetSelected()
  if selected and not selected.complete then return "Focus quest: "..selected.title..". Review its objectives below." end
  return "Choose a quest to focus on. No route optimization data is available yet."
end
function Planner.FormatFocused()
  local q,index=Planner.GetSelected()
  if not q then return "No quest selected. Your active quest log will appear here." end
  local lines={"FOCUSED QUEST "..index.."/"..#auto.entries, q.title, q.complete and "Ready for turn-in" or "In progress"}
  if not auto.supported then lines[#lines+1]="WARNING: cached quest data; verify in game." end
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
    lines[#lines+1]=report.total.." active | "..report.remaining.." in progress | "..report.ready.." ready"
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
        result[#result+1]=(q.complete and "[Ready] " or "[ ] ")..q.title
        for j=1,math.min(#q.objectives,4) do result[#result+1]="  - "..q.objectives[j] end
      end
    end
  end
  return table.concat(result,"\n")
end
local events=CreateFrame("Frame")
for _,event in ipairs({"PLAYER_ENTERING_WORLD","QUEST_LOG_UPDATE","QUEST_ACCEPTED","QUEST_REMOVED","QUEST_TURNED_IN"}) do
  pcall(function() events:RegisterEvent(event) end)
end
events:SetScript("OnEvent",function() Planner.Sync() end)

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
