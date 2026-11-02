-- Optional manual cost estimates for tracked recipe ingredients.
-- Gold amounts are entered as COPPER per unit. No auction or vendor API is read.
ForeverCompanionCraftCosts={}
local C=ForeverCompanionCraftCosts
local function key(s) return tostring(s or ""):gsub("[%c]"," "):match("^%s*(.-)%s*$"):lower():sub(1,64) end
local function store()
 ForeverCompanionDB=ForeverCompanionDB or {}
 if type(ForeverCompanionDB.craftCosts)~="table" then ForeverCompanionDB.craftCosts={} end
 return ForeverCompanionDB.craftCosts
end
function C.Set(prof,material,copper)
 local p,m=key(prof),key(material)
 local n=tonumber(copper)
 if p=="" or m=="" or not n or n%1~=0 or n<0 or n>1000000000 then return false,"Use a valid profession, material and copper-per-unit amount." end
 local db=store()
 db[p]=db[p] or {}
 db[p][m]=n
 return true,"Saved manual unit cost for "..material
end
function C.Get(prof,material)
 local db=store()
 return db[key(prof)] and db[key(prof)][key(material)] or nil
end
function C.Estimate(prof)
 local recipes=ForeverCompanionRecipePlans
 local result={}
 for i,recipe in ipairs(recipes and recipes.Get and recipes.Get(prof) or {}) do
  local remaining=math.max(0,(tonumber(recipe.quantity) or 0)-(tonumber(recipe.done) or 0))
  local cost,missing=0,0
  for _,item in ipairs(recipe.ingredients or {}) do
   local price=C.Get(prof,item.name)
   if price==nil then missing=missing+1 else cost=cost+price*math.max(0,tonumber(item.count) or 0)*remaining end
  end
  result[#result+1]={index=i,name=recipe.name,remaining=remaining,copper=cost,unknown=missing,complete=missing==0 and #(recipe.ingredients or {})>0}
 end
 return result
end
function C.Format(prof)
 local lines={"RECIPE COST ESTIMATES (MANUAL COPPER PER UNIT)"}
 local rows=C.Estimate(prof)
 if #rows==0 then lines[#lines+1]="No tracked recipes." end
 for _,row in ipairs(rows) do
  local value=row.complete and (row.copper.." copper") or ("at least "..row.copper.." copper; "..row.unknown.." unknown prices")
  lines[#lines+1]=row.index..". "..tostring(row.name).." | remaining "..row.remaining.." | "..value
 end
 lines[#lines+1]="Prices are user-entered, not live market values. Estimates cover planned materials, not fees or yields."
 return table.concat(lines,"\n")
end
