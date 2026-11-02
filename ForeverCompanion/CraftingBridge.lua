-- Recipe-to-checklist bridge. Explicit, manual synchronization only.
ForeverCompanionCraftingBridge={}
local B=ForeverCompanionCraftingBridge
local function normalize(s)
 return tostring(s or ""):match("^%s*(.-)%s*$"):lower()
end
function B.Demand(prof)
 local goals=ForeverCompanionRecipePlans.Get(prof)
 local totals={}
 for _,recipe in ipairs(goals) do
  local remaining=math.max(0,(tonumber(recipe.quantity) or 0)-(tonumber(recipe.done) or 0))
  for _,ingredient in ipairs(recipe.ingredients or {}) do
   local key=normalize(ingredient.name)
   if key~="" then
    if not totals[key] then totals[key]={name=ingredient.name,needed=0} end
    totals[key].needed=totals[key].needed+remaining*math.max(0,tonumber(ingredient.count) or 0)
   end
  end
 end
 return totals
end
function B.Preview(prof)
 local demand=B.Demand(prof)
 local entries=ForeverCompanionCraftingPlanner.GetEntries(prof)
 local owned={}
 for _,item in ipairs(entries) do owned[normalize(item.name)]=tonumber(item.owned) or 0 end
 local keys={}
 for k in pairs(demand) do keys[#keys+1]=k end
 table.sort(keys)
 local lines={"RECIPE DEMAND VS MANUAL OWNED COUNTS"}
 if #keys==0 then lines[#lines+1]="No ingredients entered for outstanding recipe goals." end
 local missing=0
 for _,key in ipairs(keys) do
  local item=demand[key]
  local have=owned[key] or 0
  local need=math.max(0,item.needed-have)
  missing=missing+need
  lines[#lines+1]=item.name..": "..have.." owned / "..item.needed.." required / "..need.." missing"
 end
 lines[#lines+1]="TOTAL MISSING UNITS: "..missing.." (manual owned quantities; not bag data)"
 lines[#lines+1]="Use /fcbridge sync Profession to replace checklist targets with recipe demand. Existing owned counts are retained."
 return table.concat(lines,"\n")
end
function B.Sync(prof)
 local demand=B.Demand(prof)
 local entries=ForeverCompanionCraftingPlanner.GetEntries(prof)
 local present={}
 for i,item in ipairs(entries) do present[normalize(item.name)]=i end
 local count=0
 for key,item in pairs(demand) do
  if item.needed>0 and not present[key] then count=count+1 end
  if item.needed>999999 then return false,"Ingredient demand exceeds checklist quantity limit." end
 end
 if #entries+count>40 then return false,"Cannot sync: material checklist would exceed 40 items." end
 local changed,added=0,0
 for key,item in pairs(demand) do
  if item.needed>0 then
   if present[key] then
    local ok=ForeverCompanionCraftingPlanner.SetNeeded(prof,present[key],item.needed)
    if ok then changed=changed+1 end
   else
    local ok=ForeverCompanionCraftingPlanner.Add(prof,item.name,item.needed,0)
    if ok then added=added+1 end
   end
  end
 end
 return true,"Recipe sync: "..changed.." targets updated, "..added.." materials added; owned counts and unrelated goals preserved."
end
SLASH_FOREVERCOMPANIONBRIDGE1="/fcbridge"
SlashCmdList.FOREVERCOMPANIONBRIDGE=function(msg)
 local cmd,prof=tostring(msg or ""):match("^%s*(%S+)%s+(.+)%s*$")
 local result
 if cmd=="preview" and prof then result=B.Preview(prof)
 elseif cmd=="sync" and prof then local ok;ok,result=B.Sync(prof)
 else result="Commands: /fcbridge preview Profession; /fcbridge sync Profession" end
 print("|cffffcc66Forever Companion:|r "..result)
 if ForeverCompanionRefresh then ForeverCompanionRefresh() end
end
