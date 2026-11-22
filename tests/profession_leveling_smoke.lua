SlashCmdList={};ForeverCompanionDB={}
dofile('ForeverCompanion/CraftingPlanner.lua');dofile('ForeverCompanion/RecipePlans.lua')
dofile('ForeverCompanion/ProfessionReference.lua');dofile('ForeverCompanion/ProfessionLeveling.lua')
local P=ForeverCompanionProfessionLeveling
local count=0
for _,name in ipairs(P.names) do
 local plan=assert(P.Build(name,1,300,25));assert(#plan.gaps==0)
 local skill=1;local sums={}
 for _,s in ipairs(plan.steps) do
  assert(s.from==skill and s.to>s.from and s.to<=300);skill=s.to
  if s.recipe then
   assert(not s.recipe.restricted and (s.recipe.cooldown or 0)==0,'restricted/cooldown recipes are not repeatable route candidates')
   assert(s.casts==math.ceil(s.minimum*1.25) and s.recipe.gray>=s.to)
   for _,m in ipairs(s.recipe.materials) do assert(m.id>0 and m.count>0);sums[m.id]=(sums[m.id] or 0)+m.count*s.casts end
  else assert(plan.gather and s.gather and s.materialsNote) end
 end
 assert(skill==300)
 for _,m in ipairs(plan.materials) do assert(m.required==sums[m.id] and m.shortage==m.required) end
 if plan.gather then assert(#plan.materials==0 and plan.casts==0) end
 for _,r in ipairs(P.Catalog(name)) do
  count=count+1;assert(r.gray>0 and r.ups>=1)
  if not r.automatic then assert(P.Start(r)>=r.yellow,'yellow threshold must not be misrepresented as an earlier trainer unlock') end
 end
end
assert(count>1900)
assert(not P.Build('Invented',1,300,25) and not P.Build('Alchemy',150,75,25) and not P.Build('Alchemy',1,300,0/0))
local plan=assert(P.Build('Alchemy',75,150,0));assert(plan.steps[1].from==75 and plan.steps[#plan.steps].to==150)
local empty=P.Build('Alchemy',300,300,0);assert(#empty.steps==0 and #empty.materials==0)
assert(plan.steps[1].to>76,'a 75-point range must not split unnecessarily at 76')
local step=plan.steps[1];assert(P.ImportStep('Alchemy',step))
local entries=ForeverCompanionRecipePlans.Get('Alchemy');assert(entries[1].guideSpellID==step.recipe.id and #entries[1].ingredients==#step.recipe.materials)
assert(not P.ImportStep('Alchemy',step) and #entries==1,'repeat import cannot duplicate a craft plan')
assert(not P.ImportStep('Mining',{gather=true}))
assert(ForeverCompanionCraftingPlanner.Add('Alchemy',plan.materials[1].name,900,12))
local existing=ForeverCompanionCraftingPlanner.GetEntries('Alchemy')[1]
assert(P.ImportMaterials(plan));assert(existing.needed==900 and existing.owned==12,'manual goals and owned counts are preserved')
local updated=P.Build('Alchemy',75,150,0);assert(updated.materials[1].owned==12)
local engineering=P.Build('Engineering',1,300,25);if #engineering.materials>40 then assert(not P.ImportMaterials(engineering) and #ForeverCompanionCraftingPlanner.GetEntries('Engineering')==0,'oversized shopping import is atomic') end
ForeverCompanionDB.professionLeveling={Alchemy={current=0/0,target=-5,reserve=math.huge}}
local cfg=P.Settings('Alchemy');assert(cfg.current==1 and cfg.target==300 and cfg.reserve==25)
ForeverCompanionProfessionScanner={Read=function() return {{name='Alchemy',skill=81,maxSkill=150}} end}
assert(P.LiveSkill('Alchemy')==81);ForeverCompanionProfessionScanner.Read=function() error('unavailable') end;assert(P.LiveSkill('Alchemy')==nil)
print('PASS: twelve profession routes, '..count..' recipe references, material arithmetic, conservative thresholds, optional reserve, no gathering quotas, atomic imports and live skill guards')

local sample={materials={{id=1,name='One',required=10,owned=2,shortage=8},{id=2,name='Two',required=3,owned=1,shortage=2}}}
local calls=0;C_Item={GetItemCount=function(id,bank,uses) calls=calls+1;assert(bank==false and uses==false);return id==1 and 7 or 0 end}
assert(P.ReadCarriedStock(sample) and calls==2 and sample.materials[1].shortage==3 and sample.materials[2].shortage==3 and sample.stockBasis=='carried bags')
assert(existing.owned==12,'reading carried stock cannot mutate manual goals')
C_Item.GetItemCount=function(id) if id==1 then return 50 end end
assert(not P.ReadCarriedStock(sample) and sample.materials[1].owned==7,'partial failures preserve the complete prior snapshot')
local protected={};issecretvalue=function(v) return v==protected end;C_Item.GetItemCount=function() return protected end
assert(not P.ReadCarriedStock(sample) and sample.materials[1].owned==7)
C_Item=nil;GetItemCount=nil;assert(not P.ReadCarriedStock(sample))
local current=P.Catalog('Blacksmithing')
local first,second=current[1],current[2]
local linked=false
C_TradeSkillUI={
 GetBaseProfessionInfo=function() return {professionID=164} end,
 GetAllRecipeIDs=function() return {first.id,second.id} end,
 IsTradeSkillLinked=function() return linked end,
 GetRecipeInfo=function(id) return {learned=id==first.id} end,
}
assert(P.RecipeState(first)=='Access unknown')
assert(P.CaptureRecipeKnowledge() and P.RecipeState(first)=='Learned' and P.RecipeState(second)=='Not learned')
linked=true
C_TradeSkillUI.GetRecipeInfo=function() return {learned=true} end
assert(not P.CaptureRecipeKnowledge())
assert(P.RecipeState(first)=='Learned' and P.RecipeState(second)=='Access unknown')
linked=false
C_TradeSkillUI.GetRecipeInfo=function() return {recipeID=999,learned=true} end
assert(not P.CaptureRecipeKnowledge() and P.RecipeState(second)=='Access unknown')
C_TradeSkillUI.GetRecipeInfo=function() return {learned=protected} end
assert(not P.CaptureRecipeKnowledge() and P.RecipeState(second)=='Access unknown')
C_TradeSkillUI=nil
GetTradeSkillLine=function() return 'Blacksmithing' end
GetNumTradeSkills=function() return 1 end
GetTradeSkillRecipeLink=function() return '|Henchant:'..second.id..'|h[Test]|h' end
assert(P.CaptureRecipeKnowledge() and P.RecipeState(second)=='Learned')
print('PASS: recipe knowledge uses player-owned snapshots and exact recipe links; external and unavailable evidence stays unknown')
local recipe={id=123,name='Test recipe',recipeItem={name='Test formula',skill=55},materials={{name='Test herb',count=2}}}
local owner={}
local tooltip={}
function tooltip:SetOwner(value) self.owner=value;self.lines={} end
function tooltip:IsOwned(value) return self.owner==value end
function tooltip:ClearLines() self.lines={} end
function tooltip:NumLines() return #self.lines end
function tooltip:SetRecipeResultItem() end
function tooltip:SetSpellByID(id) assert(id==123);self:AddLine('Native recipe effect') end
function tooltip:SetText(line) self.lines={line} end
function tooltip:AddLine(line) self.lines[#self.lines+1]=line end
function tooltip:Show() self.shown=true end
function tooltip:Hide() self.shown=false end
GameTooltip=tooltip
P.ShowRecipeTooltip(owner,recipe)
assert(tooltip.shown and tooltip.lines[1]=='Native recipe effect')
assert(tooltip.lines[3]:find('Test formula',1,true) and tooltip.lines[5]:find('Test herb',1,true))
P.HideRecipeTooltip({});assert(tooltip.shown)
P.HideRecipeTooltip(owner);assert(not tooltip.shown)
tooltip.SetSpellByID=nil
P.ShowRecipeTooltip(owner,recipe);assert(tooltip.lines[1]==recipe.name)
