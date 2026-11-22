-- Client-native recipe catalog, leveling route and shopping workspace.
local W={profession='Alchemy',view='route',offset=0,query=''}
ForeverCompanionProfessionGuideWorkspace=W
local P=ForeverCompanionProfessionLeveling
local U=ForeverCompanionInterface
local root,title,subtitle,hero,notice,current,target,professionButton,reserveButton,search,slider,rows
local selectionTitle,selectionMeta,selectionIcon,detailBody,stats,materials,add,source,gather,import
local tabs,scopeButton,stockButton,listHeading,listEmpty,pageLabel,previous,nextPage
local selected,selectedKey
local pageSize,rowHeight=6,28
local ink={.94,.95,.98,1}
local muted={.65,.72,.80,1}
local gold={1,.66,.34,1}
local yellow={1,.81,.34,1}
local green={.53,.85,.71,1}
local border={.18,.24,.31,1}
local buttonPalette={flat=true,text=ink,accent=gold,border=border,surface={.09,.126,.17,1},rail={.20,.17,.12,1}}
local primaryPalette={flat=true,text={.12,.08,.04,1},accent=gold,border={.82,.47,.22,1},surface={.99,.58,.28,1}}
local backgrounds={main={.025,.035,.048,.99},header={.043,.062,.085,1},pane={.037,.053,.073,1},tile={.065,.095,.132,1},list={.053,.075,.101,1}}
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
local function text(parent,x,y,width,size,color,height)
 local t=U.Text(parent,size,color)
 t:SetPoint('TOPLEFT',x,y)
 t:SetWidth(width)
 if height then t:SetHeight(height);t:SetWordWrap(true);t:SetJustifyV('TOP') end
 return t
end
local function block(parent,x,y,w,h,color)
 local frame=CreateFrame('Frame',nil,parent)
 frame:SetPoint('TOPLEFT',x,y)
 frame:SetSize(w,h)
 U.Surface(frame,{background=color,border=border,flat=true})
 return frame
end
local function rule(parent,x,y,width,color)
 local t=parent:CreateTexture(nil,'ARTWORK')
 t:SetColorTexture(unpack(color))
 t:SetPoint('TOPLEFT',x,y)
 t:SetSize(width,1)
end
local function moreInfo(owner,heading,description)
 if not GameTooltip then return end
 GameTooltip:SetOwner(owner,'ANCHOR_RIGHT')
 GameTooltip:SetText(heading or '',1,.83,.54,true)
 if description and description~='' then GameTooltip:AddLine(description,.87,.90,.96,true) end
 GameTooltip:Show()
end
local function hover(frame,heading,description)
 frame:EnableMouse(true)
 frame:SetScript('OnEnter',function(self)
  local name=type(heading)=='function' and heading() or heading
  local body=type(description)=='function' and description() or description
  moreInfo(self,name,body)
 end)
 frame:SetScript('OnLeave',P.HideRecipeTooltip)
 frame:SetScript('OnHide',P.HideRecipeTooltip)
end
local function button(parent,x,y,width,label,fn,help,palette,height)
 local b=U.Button(parent,palette or buttonPalette)
 b:SetPoint('TOPLEFT',x,y);b:SetSize(width,height or 30)
 b:SetText(label);b:SetScript('OnClick',fn)
 if help then hover(b,function() return b:GetText() end,help) end
 return b
end
local function icon(parent,x,y,size)
 local image=parent:CreateTexture(nil,'ARTWORK')
 image:SetPoint('TOPLEFT',x,y);image:SetSize(size,size);image:SetTexCoord(.07,.93,.07,.93)
 return image
end
local function professionIcon(profession)
 local data=ForeverCompanionData
 for _,entry in ipairs(data and data.professionHandbook or {}) do
  if entry.name==profession and entry.icon then return entry.icon end
 end
 return 'Interface\\Icons\\INV_Misc_Book_09'
end
local function itemIcon(fn,id,fallback)
 if type(fn)~='function' or not id then return fallback end
 local ok,value=pcall(fn,id)
 if ok and not (issecretvalue and issecretvalue(value)) and value and value~=134400 then return value end
 return fallback
end
local function entryIcon(r,recipe)
 if recipe then
  return itemIcon(C_Spell and C_Spell.GetSpellTexture,recipe.id,professionIcon(recipeOwner[recipe] or W.profession))
 end
 if W.view=='shopping' then
  return itemIcon(C_Item and C_Item.GetItemIconByID,r.id,'Interface\\Icons\\INV_Misc_Bag_08')
 end
 return professionIcon(W.profession)
end
local function tell(s) notice:SetText(s or '') end
local function identity(r)
 return r and tostring(recipeOwner[r] or W.profession)..':'..tostring(r.id or (r.recipe and r.recipe.id) or r.name)..':'..tostring(r.from or '')
end
local function activeProfession()
 return W.view=='recipes' and W.allProfessions and selected and recipeOwner[selected] or W.profession
end
local function recipeNote(recipe)
 local lines={}
 if recipe.automatic then lines[1]='Starter recipe'
 elseif recipe.recipeItem then lines[1]='Learn from '..recipe.recipeItem.name..' (skill '..recipe.recipeItem.skill..')'
 else lines[1]='Check the trainer or recipe source for the learning requirement.' end
 if (recipe.cooldown or 0)>0 then lines[#lines+1]='Cooldown: '..recipe.cooldown/1000 ..' sec' end
 if recipe.restricted then lines[#lines+1]='Check class and race requirements.' end
 return table.concat(lines,'\n')
end
local function openMaterial(item)
 local F=ForeverCompanionMaterialFinder
 if item.id and F.OpenItem(item.id,item.name) then return end
 F.Open(item.name)
end
function W.Rebuild()
 local plan,message=P.Build(W.profession,current:GetText(),target:GetText(),P.Settings(W.profession).reserve)
 if not plan then tell(message);return false end
 local cfg=P.Settings(W.profession);cfg.current=plan.current;cfg.target=plan.target
 W.plan=plan;W.offset=0;selectedKey=nil
 W.Refresh()
 tell('')
 return true
end
function W.ScrollTo(value)
 if not root or not root:IsShown() then return end
 W.offset=math.max(0,math.min(math.max(0,#(W.results or {})-pageSize),math.floor(value+.5)))
 W.Refresh()
end
local function setMaterialScroll(value)
 local maxScroll=math.max(0,((materials.count or 0)-4)*rowHeight)
 local position=math.min(maxScroll,math.max(0,value))
 materials.scroll:SetVerticalScroll(position)
 materials.position=position
 materials.up:SetEnabled(position>0)
 materials.down:SetEnabled(position<maxScroll)
end
local function renderMaterials(recipe,casts)
 materials.root:SetShown(recipe~=nil)
 local items=recipe and recipe.materials or {}
 materials.count=#items
 if materials.recipe~=recipe then materials.position=0 end
 materials.recipe=recipe
 materials.child:SetHeight(math.max(112,#items*rowHeight))
 for i,item in ipairs(items) do
  local row=materials.rows[i]
  if not row then
   row=button(materials.child,0,-(i-1)*rowHeight,508,'',function(self) openMaterial(self.item) end,nil,buttonPalette,26)
   row.itemIcon=icon(row,8,-3,20)
   row.label=text(row,37,-5,294,13,ink)
   row.count=text(row,338,-5,64,13,ink);row.count:SetJustifyH('RIGHT')
   row.total=text(row,423,-5,67,13,gold);row.total:SetJustifyH('RIGHT')
   hover(row,function() return row.item.name end,function()
    return row.item.count..' per craft / '..row.item.count*row.casts..' planned\nClick to find material sources.'
   end)
   row:EnableMouseWheel(true);row:SetScript('OnMouseWheel',function(_,delta)
    setMaterialScroll((materials.position or 0)-delta*rowHeight)
   end)
   materials.rows[i]=row
  end
  row.item,row.casts=item,casts
  row.itemIcon:SetTexture(itemIcon(C_Item and C_Item.GetItemIconByID,item.id,'Interface\\Icons\\INV_Misc_Bag_08'))
  row.label:SetText(item.name);row.count:SetText(item.count);row.total:SetText(item.count*casts)
  row:Show()
 end
 for i=#items+1,#materials.rows do materials.rows[i]:Hide() end
 materials.empty:SetShown(#items==0)
 materials.up:SetShown(#items>4);materials.down:SetShown(#items>4)
 setMaterialScroll(materials.position or 0)
end
local function renderDetails(plan)
 local r=selected
 local recipe=r and W.view~='shopping' and not r.gather and (r.recipe or r) or nil
 local showStats=r and not r.gather
 local casts=r and r.casts or 1
 selectionTitle:SetText(r and r.name or 'No selection')
 selectionIcon:SetTexture(r and entryIcon(r,recipe) or professionIcon(W.profession))
 selectionMeta:SetText(recipe and ((recipeOwner[recipe] or W.profession)..'  /  '..P.RecipeState(recipe))
  or r and (r.gather and ('Skill '..r.from..'-'..r.to) or W.profession) or W.profession)
 for _,card in ipairs(stats) do card.root:SetShown(not not showStats) end
 detailBody:ClearAllPoints()
 detailBody:SetPoint('TOPLEFT',18,showStats and -154 or -104)
 detailBody:SetHeight(recipe and 57 or 160)
 detailBody.hover:ClearAllPoints()
 detailBody.hover:SetAllPoints(detailBody)
 if recipe then
  stats[1].set('Turns yellow',recipe.yellow,'The recorded point at which skill-ups become chance-based.',yellow)
  stats[2].set('Turns gray',recipe.gray,'At this recorded threshold, crafting no longer gives skill points.')
  stats[3].set('Skill gain',recipe.ups,'Recorded skill points when a craft awards a skill-up.',green)
  detailBody:SetText(recipeNote(recipe))
 elseif r and r.gather then
  detailBody:SetText(table.concat({r.tool,r.note,'Keep or inspect: '..r.materialsNote},'\n\n'))
 elseif r then
  stats[1].set('Planned',r.required,'Total direct input units in the plan.')
  stats[2].set('On hand',r.owned,plan.stockBasis=='carried bags' and 'Snapshot of carried bags.' or 'Amount recorded as owned.',green)
  stats[3].set('Still needed',r.shortage,'Planned amount minus recorded stock.',gold)
  detailBody:SetText(plan.stockBasis=='carried bags' and 'Counts are from carried bags. Bank items are excluded.' or 'On-hand counts use your manually recorded stock.')
 else
  detailBody:SetText(plan.gather and W.view=='shopping' and 'Gathering routes have no fixed shopping quantities.' or 'Select an entry from the list.')
 end
 renderMaterials(recipe,casts)
 add:SetEnabled(recipe~=nil)
 add:SetText(W.view=='recipes' and 'Add 1 craft' or 'Add route step')
 source:SetEnabled(r~=nil and (not recipe or #recipe.materials>0))
 stockButton:SetEnabled(#plan.materials>0)
 import:SetEnabled(not plan.gather and #plan.materials>0)
 W.detailText=detailBody
end
local views={route={'Leveling route','Steps'},shopping={'Shopping list','Materials'},recipes={'Recipe catalog','Recipes'}}
function W.Refresh()
 if not root or not root:IsShown() or not W.plan then return end
 local plan=W.plan
 local recipes=W.view=='recipes'
 local skill,maximum=P.LiveSkill(W.profession)
 local all=recipes and W.allProfessions
 title:SetText(views[W.view][1])
 subtitle:SetText((all and 'All professions' or W.profession)..(not all and skill and ('  /  Skill '..skill..' of '..(maximum or '?')) or ''))
 hero:SetTexture(professionIcon(not all and W.profession or nil))
 professionButton:SetText(W.profession)
 reserveButton:SetText('Reserve '..P.Settings(W.profession).reserve..'%')
 scopeButton:SetText(all and 'All professions' or 'This profession')
 scopeButton:SetShown(recipes)
 for _,control in ipairs(W.routeControls) do control:SetShown(not recipes) end
 for key,b in pairs(tabs) do U.StyleButton(b,buttonPalette,W.view==key) end
 local list=W.view=='route' and plan.steps or W.view=='shopping' and plan.materials or (all and allRecipes() or P.Catalog(W.profession))
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
 W.results=results
 local limit=math.max(0,#results-pageSize)
 W.offset=math.max(0,math.min(W.offset,limit))
 W.sync=true;slider:SetMinMaxValues(0,limit);slider:SetValue(W.offset);W.sync=false;slider:SetShown(limit>0)
 listHeading:SetText(views[W.view][2]..'  /  '..#results..(query~='' and (' of '..#list) or ''))
 listEmpty:SetText(query~='' and 'No matches' or 'No entries recorded')
 listEmpty:SetShown(#results==0)
 pageLabel:SetText(#results>0 and (W.offset+1)..'-'..math.min(#results,W.offset+pageSize)..' of '..#results or '0 results')
 previous:SetEnabled(W.offset>0);nextPage:SetEnabled(W.offset<limit)
 selected=nil
 for _,r in ipairs(results) do if identity(r)==selectedKey then selected=r;break end end
 selected=selected or results[W.offset+1];selectedKey=identity(selected);W.selected=selected
 for i,b in ipairs(rows) do
  local r=results[W.offset+i];if b.record~=r then P.HideRecipeTooltip(b) end
  b.record=r;b:SetShown(r~=nil)
  if r then
   local recipe=W.view~='shopping' and not r.gather and (r.recipe or r)
   b.icon:SetTexture(entryIcon(r,recipe))
   b.title:SetText(r.name)
   local meta=recipes and (all and (recipeOwner[r]..'  /  ') or '')..P.RecipeState(r)
    or W.view=='shopping' and (r.owned..' on hand  /  '..r.shortage..' needed')
    or ('Skill '..r.from..'-'..r.to..(r.gather and '' or ('  /  '..r.casts..' crafts')))
   b.meta:SetText(meta)
   b.value:SetText(recipes and ('Y '..r.yellow..'  /  G '..r.gray) or W.view=='shopping' and tostring(r.required) or '')
   U.StyleButton(b,buttonPalette,r==selected)
  end
 end
 renderDetails(plan)
end

local function makeFilters()
 professionButton=button(root,20,-129,160,'Profession',function(self)
  local entries={}
  for _,name in ipairs(P.names) do
   local value=name
   entries[#entries+1]={label=name,selected=name==W.profession,action=function() W.Open(value,W.view) end}
  end
  U.PagedMenu(self,'Choose profession',entries,buttonPalette,245)
 end,'Choose the profession shown in this workspace.')
 scopeButton=button(root,190,-129,174,'This profession',function()
  W.allProfessions=not W.allProfessions;selectedKey=nil;W.offset=0;W.Refresh()
 end,'Switch between the selected profession and the full recipe catalog.')
 local range=button(root,190,-129,124,'Skill ranges',function(self)
  local entries={}
  for _,pair in ipairs({{1,300},{1,75},{75,150},{150,225},{225,300}}) do
   local first,last=pair[1],pair[2]
   entries[#entries+1]={label=first..'-'..last,action=function()
    current:SetText(first);target:SetText(last);W.Rebuild()
   end}
  end
  U.Menu(self,'Choose skill range',entries,buttonPalette)
 end,'Set the start and end of your leveling plan together.')
 local function skillBox(x,caption,description)
  local box=U.EditBox(root,caption)
  box:SetSize(58,30);box:SetPoint('TOPLEFT',x,-129);box:SetMaxLetters(3)
  box:SetScript('OnEnterPressed',function(self) W.Rebuild();self:ClearFocus() end)
  hover(box,caption,description)
  return box
 end
 current=skillBox(324,'From','The skill level where your plan starts.')
 target=skillBox(390,'To','The skill level you want to reach.')
 reserveButton=button(root,456,-129,108,'Reserve',function(self)
  local entries={}
  for _,value in ipairs({0,25,50,100}) do
   local n=value
   entries[#entries+1]={label=n..'% extra materials',action=function()
    P.Settings(W.profession).reserve=n;W.Rebuild()
   end}
  end
  U.Menu(self,'Extra material reserve',entries,buttonPalette,242)
 end,'Include extra materials for crafts that may fail to grant skill points.')
 local update=button(root,572,-129,100,'Apply range',W.Rebuild,'Recalculate the route and shopping list for this skill range.')
 local liveSkill=button(root,680,-129,104,'Use my skill',function()
  local n=P.LiveSkill(W.profession)
  if not n or n>300 then tell('Current profession skill is unavailable or outside this guide.');return end
  current:SetText(math.max(1,n))
  if (tonumber(target:GetText()) or 300)<n then target:SetText(n) end
  W.Rebuild()
 end,'Read your current profession skill and use it as the start of the route.')
 W.routeControls={range,current,target,reserveButton,update,liveSkill}
 -- Labels and fields are hidden together when the recipe catalog is active.
 local fromLabel=text(root,324,-112,58,11,muted)
 local toLabel=text(root,390,-112,58,11,muted)
 fromLabel:SetText('From');toLabel:SetText('To')
 W.routeControls[#W.routeControls+1]=fromLabel;W.routeControls[#W.routeControls+1]=toLabel
end
local function makeList()
 local pane=block(root,20,-180,374,455,backgrounds.pane)
 listHeading=text(pane,14,-11,340,14,ink)
 listEmpty=text(pane,14,-55,328,15,muted)
 rule(pane,14,-34,344,border)
 local function wheel(_,delta) W.ScrollTo(W.offset-(delta>0 and 1 or -1)) end
 pane:EnableMouseWheel(true);pane:SetScript('OnMouseWheel',wheel)
 rows={}
 for i=1,pageSize do
  local row=button(pane,12,-40-(i-1)*60,330,'',function(self)
   selectedKey=identity(self.record);W.Refresh()
  end,nil,buttonPalette,54)
  row.icon=icon(row,9,-11,32)
  row.title=text(row,51,-5,267,13,ink,29)
  row.meta=text(row,51,-36,179,11,muted)
  row.value=text(row,228,-36,89,11,gold);row.value:SetJustifyH('RIGHT')
  row:EnableMouseWheel(true);row:SetScript('OnMouseWheel',wheel)
  row:SetScript('OnEnter',function(self)
   local r=self.record
   if not r then return end
   if W.view=='shopping' then
    moreInfo(self,r.name,r.required..' planned / '..r.owned..' on hand / '..r.shortage..' needed')
   elseif r.gather then
    moreInfo(self,r.name,r.note)
   else
    P.ShowRecipeTooltip(self,r.recipe or r)
   end
  end)
  row:SetScript('OnLeave',P.HideRecipeTooltip);row:SetScript('OnHide',P.HideRecipeTooltip)
  rows[i]=row
 end
 W.rows=rows
 slider=CreateFrame('Slider',nil,pane)
 slider:SetSize(12,351);slider:SetPoint('TOPLEFT',348,-40)
 slider:SetOrientation('VERTICAL');slider:SetValueStep(1)
 if slider.SetObeyStepOnDrag then slider:SetObeyStepOnDrag(true) end
 local thumb=slider:CreateTexture(nil,'ARTWORK');thumb:SetSize(6,24);thumb:SetColorTexture(.71,.61,.44,1)
 slider:SetThumbTexture(thumb)
 slider:SetScript('OnValueChanged',function(_,n) if not W.sync then W.ScrollTo(n) end end)
 slider:EnableMouseWheel(true);slider:SetScript('OnMouseWheel',wheel)
 hover(slider,'Scroll results','Drag the thumb or use the mouse wheel to browse the list.')
 rule(pane,14,-406,344,border)
 previous=button(pane,12,-415,82,'Previous',function() W.ScrollTo(W.offset-pageSize) end,'Show the previous group of results.')
 nextPage=button(pane,280,-415,82,'Next',function() W.ScrollTo(W.offset+pageSize) end,'Show the next group of results.')
 pageLabel=text(pane,97,-422,180,12,muted);pageLabel:SetJustifyH('CENTER')
end
local function makeStat(parent,x)
 local frame=block(parent,x,-91,165,55,backgrounds.tile)
 local caption=text(frame,10,-8,145,12,muted)
 local value=text(frame,10,-25,145,18,ink)
 local help
 hover(frame,function() return caption:GetText() end,function() return help end)
 return {root=frame,set=function(label,n,description,color)
  caption:SetText(label);value:SetText(n);value:SetTextColor(unpack(color or ink));help=description
 end}
end
local function makeMaterials(parent)
 local frame=block(parent,18,-215,528,171,backgrounds.list)
 text(frame,10,-6,390,14,ink):SetText('Materials')
 text(frame,8,-31,320,11,muted):SetText('Ingredient')
 local per=text(frame,338,-31,64,11,muted);per:SetText('Per craft');per:SetJustifyH('RIGHT')
 local total=text(frame,423,-31,67,11,muted);total:SetText('Planned');total:SetJustifyH('RIGHT')
 local scroll=CreateFrame('ScrollFrame',nil,frame)
 scroll:SetSize(508,112);scroll:SetPoint('TOPLEFT',8,-48)
 local child=CreateFrame('Frame',nil,scroll);child:SetSize(508,112);scroll:SetScrollChild(child)
 scroll:EnableMouseWheel(true)
 scroll:SetScript('OnMouseWheel',function(_,delta)
  setMaterialScroll((materials.position or 0)-delta*rowHeight)
 end)
 local empty=text(frame,10,-59,460,13,muted);empty:SetText('No materials recorded')
 local up=button(frame,456,-6,28,'^',function() setMaterialScroll(materials.position-rowHeight) end,'Show earlier materials.',nil,22)
 local down=button(frame,490,-6,28,'v',function() setMaterialScroll(materials.position+rowHeight) end,'Show more materials.',nil,22)
 materials={root=frame,scroll=scroll,child=child,rows={},up=up,down=down,empty=empty}
 W.materials=materials
end
local function makeDetails()
 local pane=block(root,406,-180,574,455,backgrounds.pane)
 local header=block(pane,1,-1,572,77,backgrounds.header)
 selectionIcon=icon(header,17,-13,48)
 selectionTitle=text(header,78,-9,476,20,ink,48)
 selectionMeta=text(header,78,-59,476,12,gold)
 hover(header,function() return selected and selected.name or 'Selection' end,function()
  if not selected then return 'Choose an entry from the list.' end
  if W.view=='shopping' then return 'Select Material sources to find where this item comes from.' end
  if selected.gather then return selected.tool..'\n'..selected.note end
  return recipeNote(selected.recipe or selected)
 end)
 stats={makeStat(pane,18),makeStat(pane,199),makeStat(pane,380)}
 detailBody=text(pane,18,-154,528,13,muted,57)
 local explanation=CreateFrame('Frame',nil,pane)
 explanation:SetPoint('TOPLEFT',pane,'TOPLEFT',18,-154);explanation:SetSize(528,57)
 hover(explanation,'Recipe and route notes',function() return detailBody:GetText() end)
 detailBody.hover=explanation
 makeMaterials(pane)
 rule(pane,18,-393,528,border)
 add=button(pane,18,-410,164,'Add 1 craft',function()
  if not selected then return end
  local step=selected.recipe and selected or {recipe=selected,casts=1}
  local _,message=P.ImportStep(activeProfession(),step);tell(message)
 end,'Add this craft or route step to the recipe plan.',primaryPalette)
 source=button(pane,194,-410,160,'Material sources',function(self)
  if not selected then return end
  if W.view=='shopping' then openMaterial(selected);return end
  if selected.gather then
   ForeverCompanionMaterialFinder.Open(selected.materialsNote:match('^[^/]+'):match('^%s*(.-)%s*$'))
   return
  end
  local recipe=selected.recipe or selected
  local entries={}
  for _,m in ipairs(recipe.materials) do
   local item=m;entries[#entries+1]={label=m.name,action=function() openMaterial(item) end}
  end
  U.PagedMenu(self,'Choose material',entries,buttonPalette,320)
 end,'Find reported vendors, drops, gathering locations, or other sources for an ingredient.')
 gather=button(pane,366,-410,180,'Open gathering plan',function()
  ForeverCompanionGatheringPlan.Open(activeProfession())
 end,'Open the materials still needed for the selected profession.')
end
local function create()
 local name='ForeverCompanionProfessionLevelingJournal'
 root=CreateFrame('Frame',name,UIParent,'BackdropTemplate')
 root:SetSize(1000,692);root:SetPoint('CENTER');root:SetFrameStrata('DIALOG')
 U.Surface(root,{background=backgrounds.main,border=border,flat=true})
 U.PreparePanel(root,name,1000,692)
 if root.SetBackdrop then
  root:SetBackdrop({edgeFile='Interface\\Buttons\\WHITE8X8',edgeSize=1})
  if root.SetBackdropBorderColor then root:SetBackdropBorderColor(.31,.36,.42,1) end
 end
 root:Hide();W.root=root
 local header=block(root,1,-1,998,72,backgrounds.header)
 if ForeverCompanionVisualTheme then
  ForeverCompanionVisualTheme.EnvironmentArt(header,'TOPRIGHT',-1,-1,625,70,'Professions',.94,.087,'BORDER',1)
 end
 hero=icon(header,19,-15,42)
 title=text(header,75,-10,780,24,ink)
 subtitle=text(header,76,-43,780,13,gold)
 button(header,950,-17,30,'X',function() root:Hide() end,'Close this window.')
 local countHelp=CreateFrame('Frame',nil,header);countHelp:SetSize(800,38);countHelp:SetPoint('TOPLEFT',12,-31)
 hover(countHelp,function() return title:GetText() end,'Browse, plan and source materials for your profession.')
 rule(header,20,-71,958,border)
 tabs={}
 for i,entry in ipairs({
  {'route','Leveling route','Plan skill-ups between two skill levels.'},
  {'shopping','Shopping list','See planned quantities, what you have and what is still missing.'},
  {'recipes','Recipe catalog','Browse learned and unlearned recipes. Search by recipe or ingredient.'},
 }) do
  local key=entry[1]
  tabs[key]=button(root,20+(i-1)*164,-82,154,entry[2],function()
   W.view=key;W.offset=0;selectedKey=nil;tell('');W.Refresh()
  end,entry[3])
 end
 W.tabs=tabs
 search=U.EditBox(root,'Search recipe or material')
 search:SetSize(438,30);search:SetPoint('TOPLEFT',542,-82);search:SetMaxLetters(80)
 search:SetScript('OnTextChanged',function(self) W.query=self:GetText();W.offset=0;selectedKey=nil;W.Refresh() end)
 search:SetScript('OnEscapePressed',function(self) self:ClearFocus() end)
 hover(search,'Search recipes or materials','Search by recipe name, ingredient name, or exact item ID.')
 makeFilters();makeList();makeDetails()
 import=button(root,20,-645,176,'Add missing goals',function()
  local _,msg=P.ImportMaterials(W.plan);W.Rebuild();tell(msg)
 end,'Add missing materials to the planner without replacing existing goals.')
 stockButton=button(root,206,-645,188,'Scan carried materials',function()
  local _,msg=P.ReadCarriedStock(W.plan);W.Refresh();tell(msg)
 end,'Read on-hand quantities from your carried bags. Bank items are excluded.')
 W.routeControls[#W.routeControls+1]=import;W.routeControls[#W.routeControls+1]=stockButton
 notice=text(root,406,-647,558,12,gold,31)
 W.currentInput=current;W.targetInput=target;W.search=search
 W.addButton=add;W.importButton=import;W.sourceButton=source;W.stockButton=stockButton
end
function W.Open(profession,view,all)
 W.allProfessions=all==true
 if not root then create() end
 if type(profession)=='string' then
  for _,name in ipairs(P.names) do if name:lower()==profession:lower() then W.profession=name;break end end
 end
 W.view=(view=='recipes' or view=='shopping') and view or 'route'
 W.query='';search:SetText('')
 local cfg=P.Settings(W.profession);current:SetText(cfg.current);target:SetText(cfg.target)
 root:Show();W.Rebuild()
end
SLASH_FCPROFGUIDE1='/fcprofguide'
SlashCmdList.FCPROFGUIDE=function(msg) W.Open(msg and msg:match('^%s*(.-)%s*$')) end
