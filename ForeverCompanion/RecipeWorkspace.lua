-- A manual recipe-to-material workflow in the existing professions panel.
-- No recipe data is invented, and no button crafts, buys, consumes or moves items.
local W={page=1,ingredientPage=1};ForeverCompanionRecipeWorkspace=W
local readiness
local root,profession,selected,notice,recipeRows,ingredientRows,nameInput,amountInput,ingredientInput,countInput,targetInput,doneInput,selectedTitle,recipePages,ingredientPages
local function text(parent,x,y,w,value,size)
 local t=ForeverCompanionInterface.Text(parent,size or 11);t:SetPoint('TOPLEFT',x,y);t:SetWidth(w);t:SetText(value or '');return t
end
local function box(parent,x,y,w,hint,max)
 local t=ForeverCompanionInterface.EditBox(parent,hint);t:SetPoint('TOPLEFT',x,y);t:SetSize(w,26);t:SetMaxLetters(max or 60);return t
end
local function button(parent,x,y,w,label,fn)
 local b=ForeverCompanionInterface.Button(parent);b:SetPoint('TOPLEFT',x,y);b:SetSize(w,25);b:SetText(label);b:SetScript('OnClick',fn);return b
end
local function recipes() return ForeverCompanionRecipePlans.Get(profession) end
local function selection()
 for i,r in ipairs(recipes()) do if r==selected then return i,r end end
end
local function refresh(message)
 if message then notice:SetText(message) end
 if ForeverCompanionRefresh then ForeverCompanionRefresh() else W.Render(true,profession) end
end
function W.Create(parent)
 local U=ForeverCompanionInterface
 root=CreateFrame('Frame','ForeverCompanionRecipeWorkspacePanel',parent);root:SetPoint('TOPLEFT',16,-46);root:SetSize(738,432);U.Surface(root)
 text(root,12,-10,710,'RECIPE PLANS · manually entered ingredients',13)
 nameInput=box(root,12,-42,260,'Recipe name');amountInput=box(root,282,-42,68,'Crafts',4)
 button(root,360,-42,106,'Add recipe',function()
  local ok,message=ForeverCompanionRecipePlans.Add(profession,nameInput:GetText(),amountInput:GetText())
  if ok then nameInput:SetText('');amountInput:SetText('');W.page=math.ceil(#recipes()/4) end
  refresh(message)
 end)
 button(root,476,-42,250,'Add missing material goals',function()
  local ok,message=ForeverCompanionRecipePlans.ImportMaterials(profession)
  refresh(message)
 end)
 text(root,12,-78,300,'RECIPES / select one to edit',10)
 text(root,332,-78,394,'INGREDIENTS / verify in the game',10)
 recipeRows={}
 for i=1,4 do
  local row=CreateFrame('Button',nil,root);row:SetPoint('TOPLEFT',12,-100-(i-1)*51);row:SetSize(304,46);row.bg=U.Surface(row)
  row.title=text(row,8,-5,288,'',12);row.title:SetWordWrap(true);row.title:SetHeight(18)
  row.meta=text(row,8,-27,288,'',10)
  row:SetScript('OnClick',function() selected=row.record;W.ingredientPage=1;W.Render(true,profession) end);recipeRows[i]=row
  row:SetScript('OnEnter',function(self)
   local planner=ForeverCompanionProfessionLeveling
   if not planner or not self.record or not self.record.guideSpellID then return end
   for _,recipe in ipairs(planner.Catalog(profession)) do
    if recipe.id==self.record.guideSpellID then planner.ShowRecipeTooltip(self,recipe);return end
   end
  end)
  local function hideTooltip(self)
   if ForeverCompanionProfessionLeveling then ForeverCompanionProfessionLeveling.HideRecipeTooltip(self) end
  end
  row:SetScript('OnLeave',hideTooltip);row:SetScript('OnHide',hideTooltip)
 end
 selectedTitle=text(root,332,-100,394,'Select a recipe',12);selectedTitle:SetWordWrap(true);selectedTitle:SetHeight(22)
 text(root,332,-124,60,'Target',9):SetHeight(11)
 text(root,402,-124,60,'Crafted',9):SetHeight(11)
 targetInput=box(root,332,-137,60,'Target',4);doneInput=box(root,402,-137,60,'Done',4)
 button(root,472,-137,108,'Save counts',function()
  local index,record=selection();if not index then refresh('Choose a recipe first.');return end
  local target,done=tonumber(targetInput:GetText()),tonumber(doneInput:GetText())
  if not target or not done or target~=target or done~=done or target%1~=0 or done%1~=0 or target<1 or target>9999 or done<0 or done>target then refresh('Target: whole crafts 1–9999. Done: 0 up to target.');return end
  ForeverCompanionRecipePlans.SetQuantity(profession,index,target);ForeverCompanionRecipePlans.Done(profession,index,done);refresh('Manual craft counts saved. No materials were consumed.')
 end)
 button(root,590,-137,136,'Remove recipe',function()
  local index=selection();if not index then refresh('Choose a recipe first.');return end
  ForeverCompanionRecipePlans.Remove(profession,index);selected=nil;refresh('Recipe plan removed. Material goals are unchanged.')
 end)
 ingredientInput=box(root,332,-173,220,'Ingredient name');countInput=box(root,562,-173,60,'Each',5)
 button(root,632,-173,94,'Add',function()
  local index=selection();if not index then refresh('Choose a recipe first.');return end
  local ok,message=ForeverCompanionRecipePlans.Ingredient(profession,index,ingredientInput:GetText(),countInput:GetText())
  if ok then ingredientInput:SetText('');countInput:SetText('');W.ingredientPage=math.ceil(#selected.ingredients/3) end
  refresh(message)
 end)
 ingredientRows={}
 for i=1,3 do
  local row=CreateFrame('Frame',nil,root);row:SetPoint('TOPLEFT',332,-210-(i-1)*37);row:SetSize(394,33);U.Surface(row)
  row.name=text(row,7,-3,252,'',11);row.meta=text(row,7,-19,252,'',10)
  row.sources=button(row,264,-4,70,'Sources',function() if row.record then ForeverCompanionMaterialFinder.Open(row.record.name) end end)
  row.remove=button(row,342,-4,45,'x',function()
   local index,record=selection()
   if not index or record.ingredients[row.index]~=row.record then refresh('This ingredient changed. Select the recipe again.');return end
   ForeverCompanionRecipePlans.RemoveIngredient(profession,index,row.index);refresh('Ingredient removed from the manual plan.')
  end)
  ingredientRows[i]=row
 end
 button(root,12,-317,70,'Previous',function() W.page=math.max(1,W.page-1);W.Render(true,profession) end)
 button(root,246,-317,70,'Next',function() W.page=W.page+1;W.Render(true,profession) end)
 recipePages=text(root,87,-322,150,'',10);recipePages:SetJustifyH('CENTER')
 button(root,332,-328,55,'<',function() W.ingredientPage=math.max(1,W.ingredientPage-1);W.Render(true,profession) end)
 button(root,671,-328,55,'>',function() W.ingredientPage=W.ingredientPage+1;W.Render(true,profession) end)
 ingredientPages=text(root,397,-333,264,'',10);ingredientPages:SetJustifyH('CENTER')
 button(root,12,-351,304,'Gather missing ingredients',function() if ForeverCompanionGatheringPlan then ForeverCompanionGatheringPlan.Open(profession) end end)
 readiness=text(root,332,-359,394,'',10)
 notice=text(root,12,-389,714,'Enter recipe quantities and ingredients from your game. Inventory counts remain manual.',11);notice:SetWordWrap(true);notice:SetHeight(31)
 W.root=root;W.nameInput=nameInput;W.amountInput=amountInput;W.ingredientInput=ingredientInput;W.countInput=countInput;W.recipeRows=recipeRows;W.ingredientRows=ingredientRows
 root:Hide()
end
function W.Render(show,prof)
 if not root then return end
 root:SetShown(show==true)
 if not show then return end
 if profession~=prof then profession=prof;selected=nil;W.page=1;W.ingredientPage=1 end
 local list=recipes();local index=selection()
 if not index then selected=list[1] end
 local pages=math.max(1,math.ceil(#list/4));W.page=math.max(1,math.min(W.page,pages))
 for i,row in ipairs(recipeRows) do
  local r=list[(W.page-1)*4+i];if row.record~=r and ForeverCompanionProfessionLeveling then ForeverCompanionProfessionLeveling.HideRecipeTooltip(row) end;row.record=r;row:SetShown(r~=nil)
  if r then row.title:SetText(r.name);row.meta:SetText(r.done..' / '..r.quantity..' crafted · '..#r.ingredients..' ingredients');ForeverCompanionVisualTheme.SelectRow(row,row.bg,r==selected) end
 end
 recipePages:SetText(#list==0 and 'No recipes planned' or ('Page '..W.page..' / '..pages))
 selectedTitle:SetText(selected and selected.name or 'Add a recipe to start planning')
 if ForeverCompanionGatheringPlan then
  for _,r in ipairs(ForeverCompanionGatheringPlan.Readiness(profession)) do if r.recipe==selected then readiness:SetText(r.known and (r.craftable..' / '..r.remaining..' crafts covered by your plan') or 'Add ingredients to check supplies') end end
 end
 -- Do not overwrite a count while the player is typing in it.
 if selected then
  if selected~=W.lastSelected or not targetInput:HasFocus() then targetInput:SetText(tostring(selected.quantity)) end
  if selected~=W.lastSelected or not doneInput:HasFocus() then doneInput:SetText(tostring(selected.done)) end
  W.lastSelected=selected
 end
 local ingredients=selected and selected.ingredients or {};local ipages=math.max(1,math.ceil(#ingredients/3));W.ingredientPage=math.max(1,math.min(W.ingredientPage,ipages))
 for i,row in ipairs(ingredientRows) do
  local index=(W.ingredientPage-1)*3+i;local ingredient=ingredients[index];row.record=ingredient;row.index=index;row:SetShown(ingredient~=nil)
  if ingredient then row.name:SetText(ingredient.name);row.meta:SetText(ingredient.count..' / craft · '..ingredient.count*math.max(0,selected.quantity-selected.done)..' needed') end
 end
 ingredientPages:SetText(#ingredients==0 and 'No ingredients entered' or (#ingredients..' ingredients · '..W.ingredientPage..' / '..ipages))
end
function W.GetHeight() return 494 end
