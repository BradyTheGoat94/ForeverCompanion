-- Manual planning UI. No inventory, trade, purchase or crafting actions.
local W={page=1,pageSize=5}
ForeverCompanionMaterialWorkspace=W
local root,profession,refresh,fields,rows,status,heading,counter,previous,nextPage,save,cancel,empty
local editIndex
local function input(parent,x,width,hint,max)
 local box=ForeverCompanionInterface.EditBox(parent,hint)
 box:SetPoint('TOPLEFT',parent,'TOPLEFT',x,-58);box:SetSize(width,27)
 box:SetMaxLetters(max)
 box:SetScript('OnEscapePressed',function(self) if self.ClearFocus then self:ClearFocus() end end)
 return box
end
local function label(parent,x,y,width,text,size)
 local f=ForeverCompanionInterface.Text(parent,size or 11)
 f:SetPoint('TOPLEFT',parent,'TOPLEFT',x,y);f:SetWidth(width);f:SetText(text or '')
 return f
end
local function reset()
 editIndex=nil
 fields.name:SetText('');fields.needed:SetText('');fields.owned:SetText('0')
 save:SetText('Add goal');cancel:Hide()
end
local function quantity(text,minimum)
 local value=tonumber(text)
 if type(value)=='number' and value==value and value>=minimum and value<=999999 and value==math.floor(value) then return value end
end
local function submit()
 if not profession then return end
 local name=(fields.name:GetText() or ''):match('^%s*(.-)%s*$')
 local need,owned=quantity(fields.needed:GetText(),1),quantity(fields.owned:GetText(),0)
 if name=='' then status:SetText('Enter a material name.');return end
 if #name>60 then status:SetText('Use a shorter material name.');return end
 if not need or not owned then status:SetText('Use whole quantities: needed 1–999999; owned 0–999999.');return end
 local model=ForeverCompanionCraftingPlanner
 local ok,message
 if editIndex then ok,message=model.Update(profession,editIndex,name,need,owned)
 else ok,message=model.Add(profession,name,need,owned) end
 if not ok then
  status:SetText(message and message:find('already tracked',1,true) and 'This material is already tracked. Use Edit on its row.' or message)
  return
 end
 reset();status:SetText('Saved for '..profession..'. Counts are entered manually.')
 if refresh then refresh() end
end
function W.Create(parent,onRefresh)
 refresh=onRefresh
 root=CreateFrame('Frame',nil,parent);root:SetPoint('TOPLEFT',parent,'TOPLEFT',8,-240);root:SetSize(770,220)
 ForeverCompanionVisualTheme.Panel(root,770,220)
 heading=label(root,16,-12,570,'MATERIAL GOALS',13)
 label(root,16,-39,300,'Material',10)
 label(root,336,-39,94,'Needed',10)
 label(root,442,-39,94,'Owned',10)
 fields={name=input(root,16,306,'Material name',60),needed=input(root,336,94,'Required',6),owned=input(root,442,94,'On hand',6)}
 W.fields=fields
 for _,box in pairs(fields) do box:SetScript('OnEnterPressed',submit) end
 save=ForeverCompanionInterface.Button(root);save:SetPoint('TOPLEFT',root,'TOPLEFT',548,-58);save:SetSize(106,27);save:SetText('Add goal');save:SetScript('OnClick',submit)
 cancel=ForeverCompanionInterface.Button(root);cancel:SetPoint('TOPLEFT',root,'TOPLEFT',664,-58);cancel:SetSize(90,27);cancel:SetText('Cancel');cancel:SetScript('OnClick',function() reset();status:SetText('Edit cancelled. Your saved goal is unchanged.') end)
 status=label(root,16,-92,738,'Counts are entered manually; these goals do not scan your bags.',10)
 status:SetWordWrap(false)
 label(root,16,-120,300,'MATERIAL',10)
 label(root,336,-120,92,'OWNED / NEEDED',10)
 label(root,452,-120,92,'STILL NEED',10)
 rows={};W.rows=rows
 for i=1,W.pageSize do
  local row=CreateFrame('Frame',nil,root);row:SetSize(738,34);row:SetPoint('TOPLEFT',root,'TOPLEFT',16,-141-(i-1)*37)
  ForeverCompanionInterface.Surface(row)
  row.name=label(row,8,-9,300,'',12)
  row.quantity=label(row,320,-9,105,'',12)
  row.remaining=label(row,436,-9,90,'',12)
  row.edit=ForeverCompanionInterface.Button(row);row.edit:SetSize(62,24);row.edit:SetPoint('TOPLEFT',row,'TOPLEFT',572,-5);row.edit:SetText('Edit')
  row.edit:SetScript('OnClick',function()
   local entry=ForeverCompanionCraftingPlanner.GetEntries(profession)[row.index]
   if type(entry)~='table' then return end
   editIndex=row.index;fields.name:SetText(entry.name);fields.needed:SetText(tostring(entry.needed));fields.owned:SetText(tostring(entry.owned))
   save:SetText('Save goal');cancel:Show();status:SetText('Editing '..entry.name..'. Enter saves; Cancel keeps the current goal.')
  end)
  row.remove=ForeverCompanionInterface.Button(row);row.remove:SetSize(88,24);row.remove:SetPoint('TOPLEFT',row,'TOPLEFT',642,-5);row.remove:SetText('Remove')
  row.remove:SetScript('OnClick',function()
   if row.index then
    ForeverCompanionCraftingPlanner.Remove(profession,row.index);reset();status:SetText('Goal removed. Inventory is unchanged.')
    if refresh then refresh() end
   end
  end)
  rows[i]=row
 end
 empty=label(root,24,-152,722,'No material goals yet. Add a name and quantities above to start planning.',13)
 empty:SetHeight(40);empty:SetWordWrap(true)
 previous=ForeverCompanionInterface.Button(root);previous:SetSize(90,24);previous:SetText('Previous');previous:SetScript('OnClick',function() W.page=math.max(1,W.page-1);if refresh then refresh() end end)
 nextPage=ForeverCompanionInterface.Button(root);nextPage:SetSize(90,24);nextPage:SetText('Next');nextPage:SetScript('OnClick',function() W.page=W.page+1;if refresh then refresh() end end)
 counter=label(root,222,-200,310,'',11);counter:SetJustifyH('CENTER')
 W.save=save;W.cancel=cancel
 root:Hide()
end
function W.Render(show,selectedProfession)
 if not root then return end
 if not show or not selectedProfession then root:Hide();return end
 if profession~=selectedProfession then profession=selectedProfession;W.page=1;reset();status:SetText('Counts are entered manually; these goals do not scan your bags.') end
 local entries=ForeverCompanionCraftingPlanner.GetEntries(profession)
 local pages=math.max(1,math.ceil(#entries/W.pageSize));W.page=math.max(1,math.min(pages,W.page))
 heading:SetText('MATERIAL GOALS / '..profession)
 local visible=math.max(0,math.min(W.pageSize,#entries-(W.page-1)*W.pageSize))
 for i,row in ipairs(rows) do
  local index=(W.page-1)*W.pageSize+i;local entry=entries[index]
  row.index=entry and index;row:SetShown(entry~=nil)
  if entry then
   local valid=type(entry)=='table' and type(entry.name)=='string' and type(entry.needed)=='number' and type(entry.owned)=='number'
   row.edit:SetEnabled(valid)
   row.name:SetText(valid and entry.name or 'Invalid saved goal - remove this entry')
   local needed=valid and entry.needed or 0
   local owned=valid and entry.owned or 0
   row.quantity:SetText(owned..' / '..needed)
   local remaining=math.max(0,needed-owned)
   row.remaining:SetText(remaining==0 and 'Ready' or tostring(remaining))
   row.remaining:SetTextColor(remaining==0 and .43 or .82,remaining==0 and .85 or .73,remaining==0 and .62 or .56)
  end
 end
 empty:SetShown(#entries==0)
 local footer=141+math.max(1,visible)*37+16
 previous:ClearAllPoints();previous:SetPoint('TOPLEFT',root,'TOPLEFT',16,-footer)
 nextPage:ClearAllPoints();nextPage:SetPoint('TOPRIGHT',root,'TOPRIGHT',-16,-footer)
 counter:ClearAllPoints();counter:SetPoint('TOPLEFT',root,'TOPLEFT',222,-footer-5)
 counter:SetText(#entries..(#entries==1 and ' goal' or ' goals')..'  /  Page '..W.page..' of '..pages)
 previous:SetEnabled(W.page>1);nextPage:SetEnabled(W.page<pages)
 previous:SetShown(pages>1);nextPage:SetShown(pages>1);counter:SetShown(#entries>0)
 ForeverCompanionVisualTheme.ResizePanel(root,#entries==0 and 206 or footer+40)
 root:Show()
end
function W.GetHeight() return root and root:GetHeight() or 220 end
