-- Original conservative route planner over attributed client recipe facts.
local P={};ForeverCompanionProfessionLeveling=P
local D=ForeverCompanionProfessionReference
P.names={'Alchemy','Blacksmithing','Enchanting','Engineering','Herbalism','Leatherworking','Mining','Skinning','Tailoring','Cooking','First Aid','Fishing'}
local gather={
 Herbalism={tool='Check your gathering skill and tracking before leaving town.',materials={'Peacebloom / Silverleaf','Briarthorn / Bruiseweed','Kingsblood / Goldthorn','Sungrass / Dreamfoil'},advice='Gather eligible herbs along your quest route. Prefer safe loops with nodes still giving skill-ups; competition and respawns change the time required.'},
 Mining={tool='Check mining tool requirements, tracking and smelting at a forge.',materials={'Copper Ore / Rough Stone','Tin Ore / Iron Ore','Mithril Ore / Solid Stone','Thorium Ore / Dense Stone'},advice='Mine eligible deposits while questing. Smelting can supplement early progress, but do not assume smelting alone reaches 300. Keep ore and bars as separate materials.'},
 Skinning={tool='Check your skinning tool requirement and creature eligibility in game.',materials={'Ruined Leather Scraps / Light Leather','Medium Leather / Heavy Leather','Heavy Leather / Thick Leather','Thick Leather / Rugged Leather'},advice='Skin eligible looted beasts that still offer skill-ups. Match creature difficulty to your character; leather and hide yields vary and are not a guaranteed material quota.'},
 Fishing={tool='Check pole, lure and water requirements in your current client.',materials={'Pole / optional bait','Optional bait / cooking fish','Optional bait / cooking fish','Optional bait / cooking fish'},advice='Fish in water where you can reliably catch fish. Higher skill can require multiple successful catches per point. Combine catches with Cooking where useful; there is no fixed reagent shopping quota.'}
}
P.gather=gather
local function integer(v,low,high)
 if issecretvalue and issecretvalue(v) then return end
 local n=tonumber(v);if n and n==n and n%1==0 and n>=low and n<=high then return n end
end
local function clean(s) return type(s)=='string' and s:lower():match('^%s*(.-)%s*$') or '' end
function P.Settings(name)
 ForeverCompanionDB=ForeverCompanionDB or {};local db=ForeverCompanionDB
 if type(db.professionLeveling)~='table' then db.professionLeveling={} end
 if type(db.professionLeveling[name])~='table' then db.professionLeveling[name]={} end
 local s=db.professionLeveling[name];s.current=integer(s.current,1,300) or 1;s.target=integer(s.target,s.current,300) or 300
 s.reserve=integer(s.reserve,0,100) or 25;return s
end
function P.LiveSkill(name)
 local scanner=ForeverCompanionProfessionScanner;if not scanner then return end
 local ok,entries=pcall(scanner.Read);if not ok or type(entries)~='table' then return end
 for _,r in ipairs(entries) do if clean(r.name)==clean(name) then return integer(r.skill,0,100000),integer(r.maxSkill,1,100000) end end
end
function P.Catalog(name) return D.professions[name] or {} end
function P.Start(recipe) return recipe.automatic and 1 or math.max(1,recipe.yellow,recipe.recipeItem and recipe.recipeItem.skill or 1) end
function P.Effort(recipe,skill)
 local cost=0
 for _,m in ipairs(recipe.materials) do cost=cost+m.count*(1+m.level/20)*(1+m.quality)^2 end
 if skill>=recipe.yellow then cost=cost*math.max(1,(recipe.gray-recipe.yellow)/math.max(1,recipe.gray-skill)) end
 return cost/recipe.ups
end
function P.Build(name,current,target,reserve)
 current=integer(current,1,300);target=integer(target,current or 1,300);reserve=integer(reserve,0,100)
 if not D.professions[name] or not current or not target or not reserve then return nil,'Choose a profession and whole skills from 1 to 300; target must not be lower than current.' end
 local plan={profession=name,current=current,target=target,reserve=reserve,steps={},materials={},gaps={},casts=0}
 if gather[name] then
  for i,band in ipairs({{1,75},{75,150},{150,225},{225,300}}) do
   local first,last=math.max(current,band[1]),math.min(target,band[2])
   if first<last then plan.steps[#plan.steps+1]={from=first,to=last,name=name..' field practice',note=gather[name].advice,materialsNote=gather[name].materials[i],tool=gather[name].tool,gather=true} end
  end
  plan.gather=true;return plan
 end
 local skill=current
 while skill<target do
  local best,value
  for _,r in ipairs(P.Catalog(name)) do
   if not r.restricted and (r.cooldown or 0)==0 and P.Start(r)<=skill and r.gray>skill and not r.name:lower():find('transmute',1,true) and not r.name:lower():find('camp',1,true) then
    local effort=P.Effort(r,skill)*(r.recipeItem and 100 or 1)
    if not value or effort<value or effort==value and r.id<best.id then best,value=r,effort end
   end
  end
  if not best then plan.gaps[#plan.gaps+1]=skill;skill=skill+1
  else
   local last=math.min(target,skill+best.ups);local step=plan.steps[#plan.steps]
   local band=math.floor(skill/75)
   if not step or step.recipe.id~=best.id or step.to~=skill or step.band~=band then
    step={from=skill,to=last,name=best.name,recipe=best,minimum=0,band=band};plan.steps[#plan.steps+1]=step
   end
   step.minimum=step.minimum+1;step.to=last;step.chance=step.chance or skill>=best.yellow;skill=last
  end
 end
 local totals={}
 for _,step in ipairs(plan.steps) do
  step.casts=math.ceil(step.minimum*(1+reserve/100));plan.casts=plan.casts+step.casts
  for _,m in ipairs(step.recipe.materials) do
   local row=totals[m.id] or {id=m.id,name=m.name,required=0,owned=0};totals[m.id]=row;row.required=row.required+m.count*step.casts
  end
 end
 local owned={};for _,m in ipairs(ForeverCompanionCraftingPlanner.GetEntries(name)) do owned[clean(m.name)]=m.owned or 0 end
 for _,m in pairs(totals) do m.owned=owned[clean(m.name)] or 0;m.shortage=math.max(0,m.required-m.owned);plan.materials[#plan.materials+1]=m end
 table.sort(plan.materials,function(a,b) return a.name<b.name end)
 return plan
end
function P.ImportStep(name,step)
 if not step or type(step.recipe)~='table' or type(step.recipe.materials)~='table' then return false,'Gathering stages do not have a fixed craft quantity.' end
 local r=step.recipe;local count=integer(step.casts or 1,1,9999);if not count then return false,'Craft count exceeds recipe plan limits.' end
 local recipes=ForeverCompanionRecipePlans;local ok,msg=recipes.Add(name,r.name,count);if not ok then return ok,msg end
 local index=#recipes.Get(name)
 for _,m in ipairs(r.materials) do
  local added,problem=recipes.Ingredient(name,index,m.name,m.count)
  if not added then recipes.Remove(name,index);return false,problem end
 end
 local saved=recipes.Get(name)[index];saved.guideSpellID=r.id;saved.guideBuild=D.build
 return true,'Added '..count..' planned crafts of '..r.name..'. Confirm recipe access before gathering.'
end
function P.ImportMaterials(plan)
 if not plan or plan.gather then return false,'Gathering has no fixed material quota.' end
 local ok,msg=ForeverCompanionCraftingPlanner.AddMissing(plan.profession,plan.materials)
 if not ok then msg=msg..' Choose a smaller skill range or add individual recipe steps.' end
 return ok,msg
end

-- Exact-ID, opt-in carried inventory snapshot. No saved/manual stock is changed.
function P.ReadCarriedStock(plan)
 if not plan or #plan.materials==0 then return false,'This guide has no fixed material shopping list.' end
 local fn=C_Item and C_Item.GetItemCount or GetItemCount
 if type(fn)~='function' then return false,'Carried inventory counts are unavailable on this client.' end
 local snapshot={}
 for _,row in ipairs(plan.materials) do
  local ok,count=pcall(fn,row.id,false,false)
  if not ok or not integer(count,0,999999) then return false,'Some carried counts are unavailable. Your current stock display was kept.' end
  snapshot[row.id]=count
 end
 for _,row in ipairs(plan.materials) do row.owned=snapshot[row.id];row.shortage=math.max(0,row.required-row.owned) end
 plan.stockBasis='carried bags'
 return true,'Carried stock snapshot updated; bank excluded. Manual goals are unchanged. Read again after inventory changes; updating the guide restores manual stock.'
end
local professionNames={[171]='Alchemy',[164]='Blacksmithing',[333]='Enchanting',[202]='Engineering',
 [182]='Herbalism',[165]='Leatherworking',[186]='Mining',[393]='Skinning',[197]='Tailoring',
 [185]='Cooking',[129]='First Aid',[356]='Fishing'}
local observed={}
local function readValue(fn,...)
 if type(fn)~='function' then return end
 local ok,result=pcall(fn,...)
 if ok and not (issecretvalue and issecretvalue(result)) then return result end
end
local function knownRecipes()
 ForeverCompanionDB=ForeverCompanionDB or {}
 if type(ForeverCompanionDB.knownRecipeSpells)~='table' then ForeverCompanionDB.knownRecipeSpells={} end
 return ForeverCompanionDB.knownRecipeSpells
end
function P.CaptureRecipeKnowledge()
 local api=C_TradeSkillUI or {}
 observed={}
 if readValue(api.IsTradeSkillLinked) or readValue(api.IsTradeSkillGuild)
  or readValue(api.IsNPCCrafting) or readValue(IsTradeSkillLinked) then return false end
 local known=knownRecipes()
 local info=readValue(api.GetBaseProfessionInfo)
 local name=type(info)=='table' and (professionNames[readValue(function() return info.professionID end)] or readValue(function() return info.professionName end))
 name=name or readValue(GetTradeSkillLine)
 if name=='Smelting' then name='Mining' end
 if not D.professions[name] then return false end
 local inCatalog={}
 for _,r in ipairs(P.Catalog(name)) do inCatalog[r.id]=true end
 local ids=readValue(api.GetAllRecipeIDs)
 local matched=false
 if type(ids)=='table' then
  for _,id in ipairs(ids) do
   if integer(id,1,100000000) and inCatalog[id] then
    local result=readValue(api.GetRecipeInfo,id)
    local returned=type(result)=='table' and readValue(function() return result.recipeID end) or nil
    local learned=type(result)=='table' and readValue(function() return result.learned end)
    if type(learned)=='boolean' and (returned==nil or returned==id) then
     observed[id]=learned;matched=true
     if learned then known[id]=true else known[id]=nil end
    end
   end
  end
 end
 local count=integer(readValue(GetNumTradeSkills),1,4096)
 if not matched and count then
  for i=1,count do
   local link=readValue(GetTradeSkillRecipeLink,i)
   local id=type(link)=='string' and tonumber(link:match('|Henchant:(%d+)'))
   if id and inCatalog[id] then known[id]=true;observed[id]=true;matched=true end
  end
 end
 return matched
end
function P.RecipeState(recipe)
 if observed[recipe.id]==true or knownRecipes()[recipe.id]==true then return 'Learned' end
 if observed[recipe.id]==false then return 'Not learned' end
 return 'Access unknown'
end
if CreateFrame then
 local events=CreateFrame('Frame')
 for _,event in ipairs({'TRADE_SKILL_SHOW','TRADE_SKILL_UPDATE','TRADE_SKILL_LIST_UPDATE','TRADE_SKILL_CLOSE','NEW_RECIPE_LEARNED'}) do
  pcall(events.RegisterEvent,events,event)
 end
 events:SetScript('OnEvent',function(_,event)
  if event=='TRADE_SKILL_CLOSE' then observed={};return end
  local function refresh()
   P.CaptureRecipeKnowledge()
   if ForeverCompanionProfessionGuideWorkspace then ForeverCompanionProfessionGuideWorkspace.Refresh() end
  end
  if ForeverCompanionRefreshQueue then ForeverCompanionRefreshQueue.Schedule('recipe-knowledge',refresh) else refresh() end
 end)
end

function P.ShowRecipeTooltip(owner,recipe)
 local tip=GameTooltip
 if not tip or not recipe then return end
 tip:SetOwner(owner,'ANCHOR_RIGHT')
 local function populateTooltip(method)
  if type(method)~='function' then return false end
  if tip.ClearLines then tip:ClearLines() end
  local ok,result=pcall(method,tip,recipe.id)
  return ok and result~=false and (not tip.NumLines or tip:NumLines()>0)
 end
 if not populateTooltip(tip.SetRecipeResultItem) and not populateTooltip(tip.SetSpellByID) then
  tip:SetText(recipe.name)
 end
 tip:AddLine(recipe.name..' · '..P.RecipeState(recipe),1,.82,.45,true)
 if recipe.recipeItem then
  tip:AddLine('Learn from '..recipe.recipeItem.name..' · skill '..recipe.recipeItem.skill,.85,.9,1,true)
 elseif recipe.automatic then
  tip:AddLine('Starter recipe',.85,.9,1)
 end
 if recipe.cooldown and recipe.cooldown>0 then
  tip:AddLine('Cooldown: '..recipe.cooldown/1000 ..' sec',.85,.9,1)
 end
 if recipe.restricted then tip:AddLine('Check class or race requirements in game.',1,.82,.45,true) end
 if #recipe.materials>0 then
  tip:AddLine('Ingredients per craft',1,.82,.45)
  for _,material in ipairs(recipe.materials) do tip:AddLine(material.count..' × '..material.name,1,1,1,true) end
 end
 tip:Show()
end
function P.HideRecipeTooltip(owner)
 if GameTooltip and (not GameTooltip.IsOwned or GameTooltip:IsOwned(owner)) then GameTooltip:Hide() end
end
