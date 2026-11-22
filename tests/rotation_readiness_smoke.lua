-- Synthetic advice and spellbook fixtures. No spell effects are invented.
local known={};local named={}
ForeverCompanionDB={rotationGuide='bad'}
ForeverCompanionSpellbook={Scan=function() return {} end,HasName=function(_,name) return named[name]==true end,CanCheckEnglishNames=function() return true end}
ForeverCompanionIcons={SpellDetails=function(name,id) if name then return {name=name,spellID=id or 1,iconID=123} end end}
ForeverCompanionKnownSpell=function(id) return known[id] end
local refreshes=0;ForeverCompanionRefresh=function() refreshes=refreshes+1 end
dofile('ForeverCompanion/RotationWorkspace.lua')
local W=ForeverCompanionRotationWorkspace
assert(W.GetFilter()=='all' and W.SetFilter('learned') and refreshes==1)
assert(not W.SetFilter('bad') and W.GetFilter()=='learned')
local advice={'1. Untrained — inspect your trainer','2. Learned — practice safely','3. General positioning advice'}
known[22]=true
local plan,learned,missing=W.Plan(advice,{'Untrained','Learned'},'MAGE','MAGE',{spellIDs={11,22},keepOrder=true})
assert(learned==1 and missing==1 and plan[1].order==1 and plan[2].order==2,'source order and original priorities survive readiness checks')
local counts=W.Readiness(plan);assert(counts.learned==1 and counts.missing==1 and counts.advice==1)
local filtered=W.FilterPlan(plan,'','learned');assert(#filtered==1 and filtered[1].order==2)
assert(#W.FilterPlan(plan,'trainer','training')==1)
assert(#W.FilterPlan(plan,'22','learned')==1 and #W.FilterPlan(plan,'[','all')==0,'search is literal and includes spell IDs')
local sorted=W.Plan(advice,{'Untrained','Learned'},'MAGE','MAGE',{spellIDs={11,22}})
assert(sorted[1].order==2 and sorted[3].order==1,'learned-first view keeps source priority numbers')
local preview=W.Plan(advice,{'Untrained','Learned'},'WARRIOR','MAGE',{spellIDs={11,22}})
assert(W.Readiness(preview).preview==2 and #W.FilterPlan(preview,'','training')==0,'another class cannot inherit this character ownership')
ForeverCompanionSpellbook.CanCheckEnglishNames=function() return false end
known={};named={}
local uncertain=W.Plan(advice,{'Untrained','Learned'},'MAGE','MAGE',{spellIDs={11,22},keepOrder=true})
assert(W.Readiness(uncertain).unknown==2 and #W.FilterPlan(uncertain,'','training')==2 and #W.FilterPlan(uncertain,'','learned')==0,'unknown ownership must remain unknown')
named.Learned=true
local rank=W.Plan(advice,{'Untrained','Learned'},'MAGE','MAGE',{spellIDs={11,22},keepOrder=true})
assert(rank[2].readiness=='learned','a different learned rank can match the spellbook name')
print('PASS: rotation readiness, literal search, source numbering, class previews, rank matches and unknown ownership')

-- Exercise data used by the visible workspace, not just the source tables.
SlashCmdList={}
dofile('ForeverCompanion/SpecPlanner.lua')
dofile('ForeverCompanion/RotationPractice.lua')
dofile('ForeverCompanion/SpecPlaybooks.lua')

local function hasAbility(class,spec,mode,level,name)
 local _,abilities=ForeverCompanionRotationPractice(class,spec,mode,level)
 for _,ability in ipairs(abilities or {}) do
  if ability==name then return true end
 end
 return false
end

assert(not hasAbility('PALADIN','Protection','leveling',9,'Righteous Fury'))
assert(hasAbility('PALADIN','Protection','leveling',10,'Righteous Fury'))
assert(not hasAbility('PALADIN','Retribution','leveling',19,'Seal of Command'))
assert(hasAbility('PALADIN','Retribution','leveling',20,'Seal of Command'))
assert(not hasAbility('PALADIN','Retribution','leveling',39,'Unsealed Wrath'))
assert(hasAbility('PALADIN','Retribution','leveling',40,'Unsealed Wrath'))
assert(not hasAbility('HUNTER','Marksmanship','leveling',19,'Aimed Shot'))
assert(hasAbility('HUNTER','Marksmanship','leveling',20,'Aimed Shot'))
assert(hasAbility('HUNTER','Marksmanship','leveling',nil,'Aimed Shot'),
 'other-class previews can show trained abilities without assuming the current character level')

assert(ForeverCompanionSpecPlanner.Select('DRUID',4))
local bear,title,_,source,primary,summary=ForeverCompanionVisiblePriority('DRUID','boss',60,'Tank',{})
assert(title:find('Bear',1,true) and source and summary.keepOrder)
assert(primary[1]=='Primal Bite' and bear[2]:find('Lacerate',1,true))
local classes,specs=0,0
for class,choices in pairs(ForeverCompanionSpecs) do
 classes=classes+1
 for index,choice in ipairs(choices) do
  specs=specs+1
  assert(ForeverCompanionSpecPlanner.Select(class,index))
  for _,mode in ipairs({'leveling','dungeon','boss','aoe','pvp'}) do
   local steps,_,_,_,spells=ForeverCompanionVisiblePriority(class,mode,60,choice[2],{})
   assert(type(steps)=='table' and #steps>0,class..' '..choice[1]..' '..mode)
   for _,step in ipairs(steps) do assert(type(step)=='string' and step~='') end
   for key in pairs(spells or {}) do assert(key<=#steps,'card has no corresponding instruction') end
  end
 end
end
assert(classes==9 and specs==28)
print('PASS: nine classes and 28 spec/role views across five rotation modes, including training gates and Bear tank priorities')

