-- Manual recipe plans. No unverified server recipe database or automated crafting.
ForeverCompanionRecipePlans={}
local P=ForeverCompanionRecipePlans
local function store()
  ForeverCompanionDB=ForeverCompanionDB or {}
  if type(ForeverCompanionDB.recipes)~="table" then ForeverCompanionDB.recipes={} end
  return ForeverCompanionDB.recipes
end
local function trim(v)
  return tostring(v or ""):gsub("[%c]"," "):match("^%s*(.-)%s*$"):sub(1,64)
end
local function list(prof)
  local all=store()
  prof=trim(prof)
  if type(all[prof])~="table" then all[prof]={} end
  return all[prof]
end
function P.Get(prof) return list(prof) end
function P.Add(prof,name,quantity)
  prof=trim(prof); name=trim(name); quantity=tonumber(quantity)
  if prof=="" or name=="" or not quantity or quantity<1 or quantity>9999 then return false,"Invalid recipe name or quantity." end
  local entries=list(prof)
  if #entries>=30 then return false,"Maximum 30 recipe goals per profession." end
  for _,v in ipairs(entries) do if v.name:lower()==name:lower() then return false,"Recipe already tracked." end end
  entries[#entries+1]={name=name,quantity=math.floor(quantity),done=0,ingredients={}}
  return true,"Added "..name.." to "..prof
end
function P.Ingredient(prof,index,name,perCraft)
  local entry=list(prof)[tonumber(index) or 0]
  name=trim(name); perCraft=tonumber(perCraft)
  if not entry or name=="" or not perCraft or perCraft<1 or perCraft>99999 then return false,"Invalid recipe, ingredient, or amount." end
  if #entry.ingredients>=15 then return false,"Maximum 15 ingredients per recipe." end
  for _,v in ipairs(entry.ingredients) do if v.name:lower()==name:lower() then return false,"Ingredient already listed." end end
  entry.ingredients[#entry.ingredients+1]={name=name,count=math.floor(perCraft)}
  return true,"Added "..name.." to "..entry.name
end
function P.Done(prof,index,quantity)
  local entry=list(prof)[tonumber(index) or 0]
  quantity=tonumber(quantity)
  if not entry or not quantity or quantity<0 or quantity>entry.quantity then return false,"Invalid completed craft count." end
  entry.done=math.floor(quantity)
  return true,"Updated crafted count for "..entry.name
end
function P.Remove(prof,index)
  local entries=list(prof); index=tonumber(index)
  if not index or not entries[index] then return false,"Recipe not found." end
  local name=entries[index].name
  table.remove(entries,index)
  return true,"Removed "..name
end
function P.Format(prof)
  local entries=list(prof)
  local lines={"RECIPE GOALS (MANUALLY ENTERED)"}
  if #entries==0 then lines[#lines+1]="No recipes tracked. Use /fcr add Profession | Recipe | Quantity." end
  local aggregate={}
  for i,entry in ipairs(entries) do
    local remaining=math.max(0,(tonumber(entry.quantity) or 0)-(tonumber(entry.done) or 0))
    lines[#lines+1]=i..". "..entry.name.."  crafted "..entry.done.."/"..entry.quantity
    for _,ingredient in ipairs(entry.ingredients) do
      local total=remaining*(tonumber(ingredient.count) or 0)
      lines[#lines+1]="   "..ingredient.name..": "..ingredient.count.."/craft; "..total.." for remaining crafts"
      local k=ingredient.name:lower()
      if not aggregate[k] then aggregate[k]={name=ingredient.name,count=0} end
      aggregate[k].count=aggregate[k].count+total
    end
  end
  local names={}
  for k in pairs(aggregate) do names[#names+1]=k end
  table.sort(names)
  if #names>0 then lines[#lines+1]="TOTAL INGREDIENT DEMAND (NOT INVENTORY-AWARE)" end
  for _,k in ipairs(names) do
    local item=aggregate[k]
    lines[#lines+1]=item.name..": "..item.count
  end
  return table.concat(lines,"\n")
end
SLASH_FOREVERCOMPANIONRECIPES1="/fcr"
SlashCmdList.FOREVERCOMPANIONRECIPES=function(msg)
  msg=tostring(msg or ""):match("^%s*(.-)%s*$")
  local prof,name,amount=msg:match("^add%s+([^|]+)%s*|%s*([^|]+)%s*|%s*(%d+)%s*$")
  local ip,ii,ingredient,per=msg:match("^ingredient%s+([^|]+)%s*|%s*(%d+)%s*|%s*([^|]+)%s*|%s*(%d+)%s*$")
  local dp,di,dc=msg:match("^done%s+([^|]+)%s*|%s*(%d+)%s*|%s*(%d+)%s*$")
  local rp,ri=msg:match("^remove%s+([^|]+)%s*|%s*(%d+)%s*$")
  local sp=msg:match("^show%s+(.+)$")
  local ok,result
  if prof then ok,result=P.Add(prof,name,amount)
  elseif ip then ok,result=P.Ingredient(ip,ii,ingredient,per)
  elseif dp then ok,result=P.Done(dp,di,dc)
  elseif rp then ok,result=P.Remove(rp,ri)
  elseif sp then result=P.Format(sp)
  else result="Commands: /fcr add Profession | Recipe | Quantity; /fcr ingredient Profession | RecipeIndex | Material | PerCraft; /fcr done Profession | RecipeIndex | Crafted; /fcr remove Profession | RecipeIndex; /fcr show Profession" end
  print("|cffffcc66Forever Companion Recipes:|r "..result)
end
