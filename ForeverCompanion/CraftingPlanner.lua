-- Persistent, manual material planning. Never moves items or performs crafting.
ForeverCompanionCraftingPlanner={}
local P=ForeverCompanionCraftingPlanner
local function db()
  ForeverCompanionDB=ForeverCompanionDB or {}
  if type(ForeverCompanionDB.materials)~="table" then ForeverCompanionDB.materials={} end
  return ForeverCompanionDB.materials
end
local function clean(s)
  return tostring(s or ""):gsub("[%c]"," "):match("^%s*(.-)%s*$"):sub(1,60)
end
local function key(profession)
  return clean(profession or "General")
end
function P.Add(profession,name,needed,owned)
  local items=db()
  profession=key(profession)
  name=clean(name)
  needed=math.floor(tonumber(needed) or 0)
  owned=math.floor(tonumber(owned) or 0)
  if name=="" or needed<1 or needed>999999 or owned<0 or owned>999999 then
    return false,"Use /fcm add Profession | Material | Needed | Owned"
  end
  items[profession]=items[profession] or {}
  if #items[profession]>=40 then return false,"Material list limit reached (40)." end
  for _,item in ipairs(items[profession]) do
    if item.name:lower()==name:lower() then return false,"Material already tracked; use /fcm needed or /fcm owned." end
  end
  items[profession][#items[profession]+1]={name=name,needed=needed,owned=owned}
  return true,"Tracked "..name.." for "..profession
end
function P.GetEntries(profession)
  return db()[key(profession)] or {}
end
function P.AdjustOwned(profession,index,delta)
  local entries=P.GetEntries(profession)
  index=tonumber(index)
  delta=tonumber(delta)
  if not index or not entries[index] or not delta then return false,"Invalid material." end
  local amount=math.max(0,math.min(999999,(tonumber(entries[index].owned) or 0)+delta))
  return P.SetOwned(profession,index,amount)
end
function P.SetOwned(profession,index,amount)
  local entries=db()[key(profession)]
  index=tonumber(index)
  amount=tonumber(amount)
  if not entries or not index or not entries[index] or not amount or amount<0 or amount>999999 then return false,"Invalid material or quantity." end
  entries[index].owned=math.floor(amount)
  return true,"Updated "..entries[index].name
end
function P.Remove(profession,index)
  local entries=db()[key(profession)]
  index=tonumber(index)
  if not entries or not index or not entries[index] then return false,"Invalid material number." end
  local name=entries[index].name
  table.remove(entries,index)
  return true,"Removed "..name
end
function P.Summary()
  local all=db()
  local lists,materials,missing,complete=0,0,0,0
  for _,entries in pairs(all) do
    if type(entries)=="table" and #entries>0 then
      lists=lists+1
      for _,item in ipairs(entries) do
        local need=math.max(0,tonumber(item.needed) or 0)
        local owned=math.max(0,tonumber(item.owned) or 0)
        materials=materials+1
        missing=missing+math.max(0,need-owned)
        if owned>=need then complete=complete+1 end
      end
    end
  end
  return "CRAFTING GOALS: "..lists.." profession lists | "..complete.."/"..materials.." materials ready | "..missing.." units remaining"
end
function P.SetNeeded(profession,index,amount)
  local entries=db()[key(profession)]
  index=tonumber(index)
  amount=tonumber(amount)
  if not entries or not index or not entries[index] or not amount or amount<1 or amount>999999 then
    return false,"Invalid material or required quantity."
  end
  entries[index].needed=math.floor(amount)
  return true,"Updated target for "..entries[index].name
end
function P.ClearCompleted(profession)
  local entries=db()[key(profession)]
  if not entries then return true,"No tracked materials." end
  local removed=0
  for i=#entries,1,-1 do
    local item=entries[i]
    if (tonumber(item.owned) or 0)>=(tonumber(item.needed) or 0) then
      table.remove(entries,i)
      removed=removed+1
    end
  end
  return true,"Cleared "..removed.." completed material goals."
end
function P.Format(profession)
  local entries=db()[key(profession)] or {}
  local lines={"MATERIAL CHECKLIST (MANUAL)", "Use /fcm add "..key(profession).." | Material | Needed | Owned"}
  local complete=0
  if #entries==0 then lines[#lines+1]="No materials tracked for this profession." end
  for i,item in ipairs(entries) do
    local remaining=math.max(0,(tonumber(item.needed) or 0)-(tonumber(item.owned) or 0))
    if remaining==0 then complete=complete+1 end
    lines[#lines+1]=i..". "..item.name.."  "..item.owned.."/"..item.needed.."  |  Still need: "..remaining
  end
  lines[#lines+1]="Materials complete: "..complete.."/"..#entries
  return table.concat(lines,"\n")
end
SLASH_FOREVERCOMPANIONMATERIALS1="/fcm"
SlashCmdList.FOREVERCOMPANIONMATERIALS=function(msg)
  msg=tostring(msg or ""):match("^%s*(.-)%s*$")
  local profession,name,needed,owned=msg:match("^add%s+([^|]+)%s*|%s*([^|]+)%s*|%s*(%d+)%s*|%s*(%d+)%s*$")
  local p,i,n=msg:match("^owned%s+([^|]+)%s*|%s*(%d+)%s*|%s*(%d+)%s*$")
  local rp,ri=msg:match("^remove%s+([^|]+)%s*|%s*(%d+)%s*$")
  local np,ni,nn=msg:match("^needed%s+([^|]+)%s*|%s*(%d+)%s*|%s*(%d+)%s*$")
  local cp=msg:match("^clear%s+(.+)$")
  local ok,answer
  if profession then ok,answer=P.Add(profession,name,needed,owned)
  elseif p then ok,answer=P.SetOwned(p,i,n)
  elseif rp then ok,answer=P.Remove(rp,ri)
  elseif np then ok,answer=P.SetNeeded(np,ni,nn)
  elseif cp then ok,answer=P.ClearCompleted(cp)
  elseif msg=="summary" then answer=P.Summary()
  else answer="Commands: /fcm add Profession | Material | Needed | Owned; /fcm owned Profession | Index | Count; /fcm needed Profession | Index | Count; /fcm remove Profession | Index; /fcm clear Profession; /fcm summary" end
  print("|cffffcc66Forever Companion Materials:|r "..answer)
  if ForeverCompanionRefresh then ForeverCompanionRefresh() end
end
