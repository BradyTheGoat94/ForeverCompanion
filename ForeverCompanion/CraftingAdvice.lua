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
