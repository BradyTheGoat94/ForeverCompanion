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
          local objectives={}
          if type(id)=="number" and type(modern.GetQuestObjectives)=="function" then
            local got,items=pcall(modern.GetQuestObjectives,id)
            if got and type(items)=="table" then
              for _,obj in ipairs(items) do
                if type(obj)=="table" and type(obj.text)=="string" then objectives[#objectives+1]=clean(obj.text,140) end
              end
            end
          end
          rows[#rows+1]={id=id,title=clean(info.title,100),zone=info.zoneName or info.zone or header,complete=completed,objectives=objectives}
        end
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
    auto.entries={}
    auto.lastCount=0
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
function Planner.GetVisible()
  local visible={}
  local zone
  if type(GetRealZoneText)=="function" then zone=GetRealZoneText()
  elseif type(GetZoneText)=="function" then zone=GetZoneText() end
  for i,q in ipairs(auto.entries) do
    if auto.filter=="all" or (auto.filter=="ready" and q.complete)
      or (auto.filter=="zone" and (not zone or zone=="" or not Planner.HasZoneMetadata() or not q.zone or q.zone==zone)) then
      visible[#visible+1]={index=i,quest=q}
    end
  end
  return visible
end
function Planner.ReadyCount()
  local count=0
  for _,q in ipairs(auto.entries) do if q.complete then count=count+1 end end
  return count
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
  if q.zone then lines[#lines+1]="Zone: "..q.zone end
  if #q.objectives==0 then lines[#lines+1]="No objective details available from this client." end
  for _,objective in ipairs(q.objectives) do lines[#lines+1]="  "..objective end
  return table.concat(lines,"\n")
end
function Planner.FormatAuto()
  local result={"ACTIVE QUESTS", "Automatically detected from your quest log.", "NEXT STEP: "..Planner.Recommend()}
  if not auto.scanned then
    result[#result+1]="Waiting for the first quest-log scan."
  elseif not auto.supported then
    result[#result+1]="This client does not expose a recognized quest-log API. Report your client version."
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
  elseif msg=="sync" then
    if Planner.Sync() then say("Quest log synchronized: "..Planner.AutoCount().." active quests.") else say("Quest log API not available.") end
    return
  elseif msg=="list" or msg=="" then
    local entries=Planner.GetAll()
    local done,total=Planner.Summary()
    say(done.."/"..total.." complete")
    for i,e in ipairs(entries) do say(i..". "..(e.done and "[x] " or "[ ] ")..e.name.." ("..e.zone..")") end
    return
  else say("Use /fcq sync, /fcq filter, /fcq next, /fcq previous, /fcq focus N, /fcq add Quest | Zone"); return end
  say(answer)
  if ForeverCompanionRefresh then ForeverCompanionRefresh() end
end
