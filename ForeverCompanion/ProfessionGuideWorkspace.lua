-- Native profession handbook: original routes, shopping and client recipe facts.
local W={profession='Alchemy',view='route',offset=0,query=''};ForeverCompanionProfessionGuideWorkspace=W
local P=ForeverCompanionProfessionLeveling;local D=ForeverCompanionProfessionReference
local root,title,summary,notice,current,target,professionButton,reserveButton,search,slider,rows,detailTitle,detailBody,add,source,gather,import,tabs,rangeButton,stockButton
local selected,selectedKey,scopeButton
local combined,recipeOwner={},{}
local function allRecipes()
 if #combined==0 then
  for _,profession in ipairs(P.names) do
   for _,recipe in ipairs(P.Catalog(profession)) do
    combined[#combined+1]=recipe;recipeOwner[recipe]=profession
   end
  end
 end
 return combined
end
local function text(parent,x,y,width,size,height)
 local t=ForeverCompanionInterface.Text(parent,size);t:SetPoint('TOPLEFT',x,y);t:SetWidth(width)
 if height then t:SetHeight(height);t:SetWordWrap(true);t:SetJustifyV('TOP') end;return t
end
local function button(parent,x,y,width,label,fn)
 local b=ForeverCompanionInterface.Button(parent);b:SetPoint('TOPLEFT',x,y);b:SetSize(width,28);b:SetText(label);b:SetScript('OnClick',fn);return b
end
local function tell(s) notice:SetText(s or '') end
local function identity(r) return r and tostring(r.id or (r.recipe and r.recipe.id) or r.name)..':'..tostring(r.from or '') end
function W.Rebuild()
 local plan,message=P.Build(W.profession,current:GetText(),target:GetText(),P.Settings(W.profession).reserve)
 if not plan then tell(message);return false end
 local cfg=P.Settings(W.profession);cfg.current=plan.current;cfg.target=plan.target
 W.plan=plan;W.offset=0;selectedKey=nil;W.Refresh();tell('Guide updated. Confirm recipe access in game; skill-up attempts can require extra materials.');return true
end
function W.ScrollTo(value)
 if not root or not root:IsShown() then return end
 W.offset=math.max(0,math.min(math.max(0,#(W.results or {})-6),math.floor(value+.5)));W.Refresh()
end
local function openMaterial(item)
 local F=ForeverCompanionMaterialFinder
 if item.id and F.OpenItem(item.id,item.name) then return end
 F.Open(item.name)
end
function W.Refresh()
 if not root or not root:IsShown() or not W.plan then return end
 local plan=W.plan;local cfg=P.Settings(W.profession)
 professionButton:SetText(W.view=="recipes" and W.allProfessions and "All professions" or W.profession);reserveButton:SetText('Extra supply: '..cfg.reserve..'%')
 local skill,maximum=P.LiveSkill(W.profession)
 title:SetText('PROFESSION LEVELING JOURNAL · '..W.profession)
 summary:SetText((skill and ('Your skill '..skill..' / '..(maximum or '?')..' · ') or 'Profession preview · ')..plan.current..' → '..plan.target..' · '..#plan.steps..' steps · '..#plan.materials..' materials\n'..(plan.gather and 'Field practice guide: catches, skins and node yields have no fixed material quota.' or ('Planned attempts include '..plan.reserve..'% extra supply. Yellow skill-ups and recipe access need in-game checks; this is not a cheapest-price route.')))
 for key,b in pairs(tabs) do ForeverCompanionInterface.StyleButton(b,nil,W.view==key) end
 local list=W.view=='route' and plan.steps or W.view=='shopping' and plan.materials or (W.allProfessions and allRecipes() or P.Catalog(W.profession))
 local results={};local query=W.query:lower()
 for _,r in ipairs(list) do
  local match=query=='' or r.name:lower():find(query,1,true) or tostring(r.id or '')==query
  if not match and W.view~='shopping' then
   for _,m in ipairs((r.recipe or r).materials or {}) do
    if m.name:lower():find(query,1,true) or tostring(m.id)==query then match=true;break end
   end
  end
  if match then results[#results+1]=r end
 end
 if W.view=='recipes' then
  title:SetText(W.allProfessions and 'RECIPE CATALOG - ALL PROFESSIONS' or 'RECIPE CATALOG · '..W.profession)
  summary:SetText(#results..' of '..#list..' recipes'..(#list==0 and ' · No crafting recipes recorded' or ' · Hover for item and ingredients'))
 end
 W.results=results;W.offset=math.max(0,math.min(W.offset,math.max(0,#results-6)))
 W.sync=true;slider:SetMinMaxValues(0,math.max(0,#results-6));slider:SetValue(W.offset);W.sync=false;slider:SetShown(#results>6)
 selected=nil;for _,r in ipairs(results) do if identity(r)==selectedKey then selected=r;break end end
 selected=selected or results[W.offset+1];selectedKey=identity(selected);W.selected=selected
 for i,b in ipairs(rows) do
  local r=results[W.offset+i];if b.record~=r then P.HideRecipeTooltip(b) end;b.record=r;b:SetShown(r~=nil)
  if r then
   local recipe=W.view~='shopping' and (r.recipe or r)
   local ok,icon
   if W.view=='shopping' and C_Item and C_Item.GetItemIconByID then ok,icon=pcall(C_Item.GetItemIconByID,r.id)
   elseif recipe and recipe.id and C_Spell and C_Spell.GetSpellTexture then ok,icon=pcall(C_Spell.GetSpellTexture,recipe.id) end
   b.icon:SetTexture(ok and not (issecretvalue and issecretvalue(icon)) and icon or 'Interface\\Icons\\INV_Misc_Book_09')
   b.title:SetText(r.from and (r.from..'–'..r.to..' · '..r.name) or r.name)
   b.meta:SetText(W.view=='shopping' and (r.owned..' owned / '..r.required..' planned · '..r.shortage..' missing') or W.view=='recipes' and ((W.allProfessions and (recipeOwner[r]..' / ') or '')..P.RecipeState(r)..' · Yellow '..r.yellow..' · Gray '..r.gray) or r.gather and r.materialsNote or (r.casts..' planned crafts · '..(r.chance and 'chance-based skill-ups' or 'before yellow threshold')))
   ForeverCompanionInterface.StyleButton(b,nil,r==selected)
  end
 end
 stockButton:SetEnabled(#plan.materials>0);add:SetEnabled(false);source:SetEnabled(selected~=nil);import:SetEnabled(not plan.gather and #plan.materials>0)
 local lines={};detailTitle:SetText(selected and selected.name or 'No matching entries')
 if selected then
  if W.view=='shopping' then
   lines={selected.required..' planned input units',selected.owned..(plan.stockBasis=='carried bags' and ' carried in bags (snapshot; bank excluded)' or ' manually recorded as owned'),selected.shortage..' missing from recorded stock','Item #'..selected.id,'','Direct inputs only: bars, bolts and components are not automatically expanded into raw ingredients. Crafted outputs are not credited against later steps.','Existing material goals are preserved when adding missing goals.'}
  elseif selected.gather then lines={selected.from..'–'..selected.to..' skill',selected.tool,'',selected.note,'','Materials to keep / inspect: '..selected.materialsNote,'','Train the next rank when your actual cap is reached. Source records are reference locations, not a guaranteed farming loop.'}
  else
   local recipe=selected.recipe or selected;local casts=selected.casts or 1
   lines={selected.from and (selected.from..'–'..selected.to..' skill · '..casts..' planned attempts') or 'Client recipe reference / adding one craft',
    P.RecipeState(recipe)..' · Yellow '..recipe.yellow..' · Gray '..recipe.gray..' · '..recipe.ups..' reported skill point(s) on success',
    recipe.automatic and 'Starter recipe flag (client reference)' or recipe.recipeItem and ('Recipe item: '..recipe.recipeItem.name..' · requires '..recipe.recipeItem.skill) or 'Check trainer or recipe source in game.',
    (recipe.cooldown or 0)>0 and ('Recorded cooldown '..(recipe.cooldown/1000)..' sec; excluded from quick routes') or recipe.restricted and 'Class/race restriction recorded; inspect eligibility' or '',
    '','MATERIALS / per craft → planned total'}
   for _,m in ipairs(recipe.materials) do lines[#lines+1]=m.name..' · '..m.count..' → '..(m.count*casts) end
   lines[#lines+1]='';lines[#lines+1]='Trainer learning levels are not the yellow/gray thresholds. Route starts are conservative references; confirm the recipe before buying.'
   add:SetEnabled(true);add:SetText(W.view=='recipes' and 'Add 1 craft to plan' or 'Add step to recipe plan')
  end
 else lines={plan.gather and W.view=='shopping' and 'Gathering has no fixed purchase quota. Use Quick route for the materials to keep at each stage.' or 'Try a shorter search or another view.'} end
 local wrapped={}
 for _,line in ipairs(lines) do
  local part='';for word in tostring(line):gmatch('%S+') do
   if #part+#word+1>70 and part~='' then wrapped[#wrapped+1]=part;part=word else part=part=='' and word or part..' '..word end
  end;wrapped[#wrapped+1]=part
 end
 detailBody:SetText(table.concat(wrapped,'\n'))
 scopeButton:SetShown(W.view=='recipes');scopeButton:SetText(W.allProfessions and 'Scope: all professions' or 'Scope: this profession')
 local showRoute=W.view~='recipes'
 for _,control in ipairs(W.routeControls) do control:SetShown(showRoute) end
 W.detailText=detailBody
end
function W.Open(profession,view,all)
 W.allProfessions=all==true
 if not root then
  local U=ForeverCompanionInterface
  root=CreateFrame('Frame','ForeverCompanionProfessionLevelingJournal',UIParent,'BackdropTemplate');root:SetSize(960,700);root:SetPoint('CENTER');root:SetFrameStrata('DIALOG');U.Surface(root);U.PreparePanel(root,'ForeverCompanionProfessionLevelingJournal',960,700);U.CloseButton(root,function() root:Hide() end);W.root=root
  title=text(root,16,-16,890,17)
  professionButton=button(root,16,-63,220,'Profession',function(self)
   local entries={}
   if W.view=='recipes' then entries[1]={label='All professions',action=function() W.allProfessions=true;W.offset=0;selectedKey=nil;W.Refresh() end} end
   for _,name in ipairs(P.names) do local value=name;entries[#entries+1]={label=name,action=function() W.Open(value,W.view) end} end;U.PagedMenu(self,'PROFESSION / 1–300',entries,nil,260)
  end)
  rangeButton=button(root,248,-63,180,'Skill range',function(self)
   local entries={};for _,range in ipairs({{1,300},{1,75},{75,150},{150,225},{225,300}}) do local first,last=range[1],range[2];entries[#entries+1]={label=first..'–'..last,action=function() current:SetText(first);target:SetText(last);W.Rebuild() end} end;U.Menu(self,'QUICK SKILL RANGES',entries)
  end)
  scopeButton=button(root,248,-63,220,'Scope',function()
   W.allProfessions=not W.allProfessions;selectedKey=nil;W.offset=0;W.Refresh()
  end)
  local currentLabel=text(root,440,-47,70,10);currentLabel:SetText('Current')
  local targetLabel=text(root,520,-47,70,10);targetLabel:SetText('Target')
  current=U.EditBox(root,'1');current:SetSize(70,28);current:SetPoint('TOPLEFT',440,-63);current:SetAutoFocus(false);current:SetMaxLetters(3)
  target=U.EditBox(root,'300');target:SetSize(70,28);target:SetPoint('TOPLEFT',520,-63);target:SetAutoFocus(false);target:SetMaxLetters(3)
  for _,box in ipairs({current,target}) do box:SetScript('OnEnterPressed',function(self) W.Rebuild();self:ClearFocus() end) end
  reserveButton=button(root,602,-63,150,'Extra supply',function(self)
   local entries={};for _,value in ipairs({0,25,50,100}) do local n=value;entries[#entries+1]={label=n..'% extra supply',action=function() P.Settings(W.profession).reserve=n;W.Rebuild() end} end;U.Menu(self,'OPTIONAL MATERIAL RESERVE / NOT A GUARANTEE',entries,nil,350)
  end)
  local update=button(root,764,-63,180,'Update guide',W.Rebuild)
  W.routeControls={rangeButton,currentLabel,targetLabel,current,target,reserveButton,update}
  U.HoverNote(root,921,-109,'Recipe catalog','All recipes includes unlearned recipes. The leveling route uses recorded skill-up thresholds. Check the trainer or recipe item for learning requirements.')
  summary=text(root,16,-106,895,11,32)
  tabs={};for i,v in ipairs({{'route','Quick route'},{'shopping','Shopping list'},{'recipes','All recipes'}}) do local key=v[1];tabs[key]=button(root,16+(i-1)*158,-146,150,v[2],function() W.view=key;W.offset=0;selectedKey=nil;W.Refresh() end) end;W.tabs=tabs
  search=U.EditBox(root,'Search steps, recipes or materials');search:SetSize(438,28);search:SetPoint('TOPLEFT',506,-146);search:SetAutoFocus(false);search:SetMaxLetters(80);search:SetScript('OnTextChanged',function(self) W.query=self:GetText();W.offset=0;selectedKey=nil;W.Refresh() end)
  local function wheel(_,delta) W.ScrollTo(W.offset-(delta>0 and 1 or -1)) end
  rows={};for i=1,6 do
   local b=button(root,16,-186-(i-1)*70,420,'',function(self) selectedKey=identity(self.record);W.Refresh() end);b:SetHeight(64)
   b.icon=b:CreateTexture(nil,'ARTWORK');b.icon:SetSize(28,28);b.icon:SetPoint('LEFT',10,0)
   b.title=text(b,46,-8,364,12,30);b.meta=text(b,46,-42,364,10,18);b:EnableMouseWheel(true);b:SetScript('OnMouseWheel',wheel);rows[i]=b
   b:SetScript('OnEnter',function(self)
    local record=self.record
    if record and W.view~='shopping' and not record.gather then P.ShowRecipeTooltip(self,record.recipe or record) end
   end)
   b:SetScript('OnLeave',P.HideRecipeTooltip);b:SetScript('OnHide',P.HideRecipeTooltip)
  end;W.rows=rows
  slider=CreateFrame('Slider',nil,root);slider:SetSize(16,414);slider:SetPoint('TOPLEFT',442,-186);slider:SetOrientation('VERTICAL');slider:SetValueStep(1);if slider.SetObeyStepOnDrag then slider:SetObeyStepOnDrag(true) end
  local thumb=slider:CreateTexture(nil,'ARTWORK');thumb:SetSize(16,34);thumb:SetTexture('Interface\\Buttons\\UI-ScrollBar-Knob');slider:SetThumbTexture(thumb);slider:SetScript('OnValueChanged',function(_,n) if not W.sync then W.ScrollTo(n) end end);slider:EnableMouseWheel(true);slider:SetScript('OnMouseWheel',wheel)
  local detail=CreateFrame('Frame',nil,root);detail:SetSize(478,414);detail:SetPoint('TOPLEFT',466,-186);U.Surface(detail)
  detailTitle=text(detail,12,-12,454,14,42);detailBody=text(detail,12,-62,454,11,268)
  add=button(detail,12,-338,218,'Add step to recipe plan',function() local step=selected and (selected.recipe and selected or {recipe=selected,casts=1});local _,msg=P.ImportStep(W.view=="recipes" and W.allProfessions and recipeOwner[selected] or W.profession,step);tell(msg) end)
  source=button(detail,244,-338,218,'Material sources',function(self)
   if not selected then return end
   if W.view=='shopping' then openMaterial(selected);return end
   if selected.gather then ForeverCompanionMaterialFinder.Open(selected.materialsNote:match('^[^/]+'):match('^%s*(.-)%s*$'));return end
   local recipe=selected.recipe or selected;local entries={};for _,m in ipairs(recipe.materials) do local item=m;entries[#entries+1]={label=m.name,action=function() openMaterial(item) end} end;U.PagedMenu(self,'CHOOSE MATERIAL',entries,nil,350)
  end)
  gather=button(detail,12,-376,218,'Gather planned materials',function() ForeverCompanionGatheringPlan.Open(W.view=='recipes' and W.allProfessions and recipeOwner[selected] or W.profession) end)
  button(detail,244,-376,218,'Use my current skill',function() local n=P.LiveSkill(W.profession);if not n or n>300 then tell('Current profession skill is unavailable or outside this guide.');return end;current:SetText(math.max(1,n));if (tonumber(target:GetText()) or 300)<n then target:SetText(n) end;W.Rebuild() end)
  import=button(root,16,-620,250,'Add missing shopping goals',function() local _,msg=P.ImportMaterials(W.plan);W.Rebuild();tell(msg) end)
  stockButton=button(root,282,-620,180,'Read carried stock',function() local _,msg=P.ReadCarriedStock(W.plan);W.Refresh();tell(msg) end);W.stockButton=stockButton
  text(root,474,-628,470,10,24):SetText('Direct inputs · optional reserve · check trainer ranks at your actual cap · client build '..D.build)
  W.routeControls[#W.routeControls+1]=import;W.routeControls[#W.routeControls+1]=stockButton
  notice=text(root,16,-659,928,10,28)
  W.currentInput=current;W.targetInput=target;W.search=search;W.addButton=add;W.importButton=import;W.sourceButton=source
 end
 if type(profession)=='string' then for _,name in ipairs(P.names) do if name:lower()==profession:lower() then W.profession=name;break end end end
 W.view=(view=='recipes' or view=='shopping') and view or 'route';W.query='';search:SetText('');local cfg=P.Settings(W.profession);current:SetText(cfg.current);target:SetText(cfg.target)
 root:Show();W.Rebuild()
end
SLASH_FCPROFGUIDE1='/fcprofguide';SlashCmdList.FCPROFGUIDE=function(msg) W.Open(msg and msg:match('^%s*(.-)%s*$')) end
