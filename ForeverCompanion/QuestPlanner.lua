-- Manual quest planner. No quest automation, map pins or unverified quest database.
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
  local result={"QUEST PLANNER (manual tracking)", "No automatic quest detection or navigation.", "Commands: /fcq add Quest name | Zone", "/fcq done 1   /fcq remove 1   /fcq list"}
  if #entries==0 then result[#result+1]="No quests tracked yet." end
  for i,e in ipairs(entries) do
    result[#result+1]=i..". "..(e.done and "[x] " or "[ ] ")..e.name.." — "..e.zone
  end
  local done,total=Planner.Summary()
  result[#result+1]="Progress: "..done.."/"..total
  return table.concat(result,"\n\n")
end

-- Read-only quest-log synchronization. Never accepts/turns in quests or changes tracking.
local auto = {entries={}, supported=false, scanned=false, lastCount=0}
local function questRows()
  local rows={}
  if C_QuestLog and type(C_QuestLog.GetNumQuestLogEntries)=="function" and type(C_QuestLog.GetInfo)=="function" then
    local count=C_QuestLog.GetNumQuestLogEntries() or 0
    for i=1,count do
      local info=C_QuestLog.GetInfo(i)
      if info and not info.isHeader and info.title then
        local id=info.questID
        local completed=info.isComplete or false
        local objectives={}
        if id and type(C_QuestLog.GetQuestObjectives)=="function" then
          local items=C_QuestLog.GetQuestObjectives(id)
          if type(items)=="table" then
            for _,obj in ipairs(items) do
              if obj.text then objectives[#objectives+1]=clean(obj.text,140) end
            end
          end
        end
        rows[#rows+1]={id=id,title=clean(info.title,100),complete=completed,objectives=objectives}
      end
    end
    return rows,true
  elseif type(GetNumQuestLogEntries)=="function" and type(GetQuestLogTitle)=="function" then
    local count=GetNumQuestLogEntries() or 0
    local header="Quest log"
    for i=1,count do
      local title,_,_,isHeader,_,isComplete,_,questID=GetQuestLogTitle(i)
      if isHeader then header=clean(title,70)
      elseif title then
        local objectives={}
        if type(GetNumQuestLeaderBoards)=="function" and type(GetQuestLogLeaderBoard)=="function" then
          local n=GetNumQuestLeaderBoards(i) or 0
          for j=1,n do
            local text=GetQuestLogLeaderBoard(j,i)
            if text then objectives[#objectives+1]=clean(text,140) end
          end
        end
        rows[#rows+1]={id=questID,title=clean(title,100),zone=header,complete=isComplete==1 or isComplete==true,objectives=objectives}
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
  if not supported then return false end
  auto.entries=rows
  auto.lastCount=#rows
  if ForeverCompanionRefresh then ForeverCompanionRefresh() end
  return true
end
function Planner.AutoCount() return auto.lastCount end
function Planner.FormatAuto()
  local result={"LIVE QUEST LOG (read-only)", "Automatically refreshes from supported quest-log APIs.", "Quests are detected from the game; no manual entry required."}
  if not auto.scanned then
    result[#result+1]="Waiting for the first quest-log scan."
  elseif not auto.supported then
    result[#result+1]="This client does not expose a recognized quest-log API. Report your client version."
  elseif #auto.entries==0 then
    result[#result+1]="No active quests in the quest log."
  else
    for i,q in ipairs(auto.entries) do
      result[#result+1]=(q.complete and "[Ready] " or "[Active] ")..q.title..(q.zone and " ("..q.zone..")" or "")
      for j=1,math.min(#q.objectives,5) do result[#result+1]="    "..q.objectives[j] end
    end
  end
  return table.concat(result,"\n")
end
local events=CreateFrame("Frame")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("QUEST_LOG_UPDATE")
events:RegisterEvent("QUEST_ACCEPTED")
events:RegisterEvent("QUEST_REMOVED")
events:RegisterEvent("QUEST_TURNED_IN")
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
  elseif msg=="sync" then
    if Planner.Sync() then say("Quest log synchronized: "..Planner.AutoCount().." active quests.") else say("Quest log API not available.") end
    return
  elseif msg=="list" or msg=="" then
    local entries=Planner.GetAll()
    local done,total=Planner.Summary()
    say(done.."/"..total.." complete")
    for i,e in ipairs(entries) do say(i..". "..(e.done and "[x] " or "[ ] ")..e.name.." ("..e.zone..")") end
    return
  else say("Use /fcq sync, /fcq list, /fcq add Quest name | Zone, /fcq done N, /fcq remove N"); return end
  say(answer)
  if ForeverCompanionRefresh then ForeverCompanionRefresh() end
end
