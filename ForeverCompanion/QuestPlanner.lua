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
SLASH_FOREVERCOMPANIONQUEST1="/fcq"
SlashCmdList.FOREVERCOMPANIONQUEST=function(msg)
  msg=trim(msg)
  local name,zone=msg:match("^add%s+([^|]+)%s*|%s*(.*)$")
  if not name then name=msg:match("^add%s+(.+)$") end
  local ok,answer
  if name then ok,answer=Planner.Add(name,zone)
  elseif msg:match("^done%s+%d+$") then ok,answer=Planner.Toggle(msg:match("%d+"))
  elseif msg:match("^remove%s+%d+$") then ok,answer=Planner.Remove(msg:match("%d+"))
  elseif msg=="list" or msg=="" then
    local entries=Planner.GetAll()
    local done,total=Planner.Summary()
    say(done.."/"..total.." complete")
    for i,e in ipairs(entries) do say(i..". "..(e.done and "[x] " or "[ ] ")..e.name.." ("..e.zone..")") end
    return
  else say("Use /fcq add Quest name | Zone, /fcq done N, /fcq remove N, /fcq list"); return end
  say(answer)
  if ForeverCompanionRefresh then ForeverCompanionRefresh() end
end
