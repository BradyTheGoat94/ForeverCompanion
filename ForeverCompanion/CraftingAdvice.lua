-- Read-only crafting decision support. Never crafts, buys or moves items.
ForeverCompanionCraftingAdvice={}
local A=ForeverCompanionCraftingAdvice
local function clean(s) return tostring(s or ""):gsub("[%c]"," "):match("^%s*(.-)%s*$") end
function A.Plan(profession)
 local recipes=ForeverCompanionRecipePlans
 if not recipes or not recipes.Get then return {lines={"Recipe planner unavailable."},ready=0,blocked=0} end
 local forecast=recipes.MaterialForecast and recipes.MaterialForecast(profession) or {}
 local available={}
 for _,row in ipairs(forecast) do available[clean(row.name):lower()]=tonumber(row.owned) or 0 end
 local result={lines={"CRAFTING DECISION GUIDE (MANUAL MATERIAL COUNTS)"},ready=0,blocked=0}
 for index,recipe in ipairs(recipes.Get(profession)) do
  local remaining=math.max(0,(tonumber(recipe.quantity) or 0)-(tonumber(recipe.done) or 0))
  if remaining>0 then
   local possible=remaining
   local hasIngredients=false
   for _,ingredient in ipairs(recipe.ingredients or {}) do
    local per=tonumber(ingredient.count) or 0
    if per>0 then
     hasIngredients=true
     local owned=available[clean(ingredient.name):lower()] or 0
     possible=math.min(possible,math.floor(owned/per))
    end
   end
   if not hasIngredients then
    result.blocked=result.blocked+1
    result.lines[#result.lines+1]=index..". "..clean(recipe.name).." | MATERIAL DATA MISSING | Enter per-craft ingredients"
   elseif possible>0 then
    result.ready=result.ready+1
    result.lines[#result.lines+1]=index..". "..clean(recipe.name).." | UP TO "..possible.." crafts with tracked materials | "..remaining.." remaining"
   else
    result.blocked=result.blocked+1
    result.lines[#result.lines+1]=index..". "..clean(recipe.name).." | GATHER MATERIALS | "..remaining.." remaining"
   end
  end
 end
 if result.ready+result.blocked==0 then result.lines[#result.lines+1]="No unfinished recipe goals." end
 result.lines[#result.lines+1]="Craftable estimates are independent per recipe; shared materials cannot be spent twice."
 result.lines[#result.lines+1]="Manual goals are not verified Forever recipes, trainer unlocks, or live bag inventory."
 return result
end
function A.Format(profession) return table.concat(A.Plan(profession).lines,"\n") end

-- Plan a conservative craft order. Reserve materials after each proposed craft
-- so overlapping recipes cannot claim the same inventory twice.
function A.Allocation(profession)
 local recipes=ForeverCompanionRecipePlans
 if not recipes or not recipes.Get then return {} end
 local stock={}
 local planner=ForeverCompanionCraftingPlanner
 local tracked=planner and planner.GetEntries and planner.GetEntries(profession) or {}
 for _,row in ipairs(tracked) do stock[clean(row.name):lower()]=math.max(0,tonumber(row.owned) or 0) end
 local result={}
 for index,recipe in ipairs(recipes.Get(profession)) do
  local remaining=math.max(0,(tonumber(recipe.quantity) or 0)-(tonumber(recipe.done) or 0))
  local craftable=remaining
  local ingredients=recipe.ingredients or {}
  if #ingredients==0 then craftable=0 end
  for _,ingredient in ipairs(ingredients) do
   local count=tonumber(ingredient.count) or 0
   if count<=0 then craftable=0; break end
   craftable=math.min(craftable,math.floor((stock[clean(ingredient.name):lower()] or 0)/count))
  end
  craftable=math.max(0,math.floor(craftable))
  for _,ingredient in ipairs(ingredients) do
   local key=clean(ingredient.name):lower()
   stock[key]=math.max(0,(stock[key] or 0)-craftable*(tonumber(ingredient.count) or 0))
  end
  result[#result+1]={index=index,name=recipe.name,remaining=remaining,craftable=craftable,blocked=remaining-craftable}
 end
 return result
end
function A.FormatAllocation(profession)
 local lines={"CRAFTING QUEUE (SHARED MATERIALS RESERVED IN RECIPE ORDER)"}
 local entries=A.Allocation(profession)
 if #entries==0 then lines[#lines+1]="No recipe goals recorded." end
 for _,row in ipairs(entries) do
  if row.remaining>0 then lines[#lines+1]=row.index..". "..clean(row.name).." | craft now "..row.craftable.." | still blocked "..row.blocked end
 end
 lines[#lines+1]="Planning only: no items are consumed, crafted or moved. Change recipe order to reprioritize."
 return table.concat(lines,"\n")
end
