-- Clickable catalog rows and source detail. All progress is entered manually.
local W={pageSize=6}
ForeverCompanionLootWorkspace=W
local root,summary,detail,detailPanel,empty,pageText,previous,nextPage,research,slotButton,statusButton,disclosure,current,navigate,refresh
local scope,itemTitle,searchBox,wishButton,obtainedButton,savedButton,resetButton
local function text(parent,x,y,width,value,size)
 local f=parent:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
 f:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y);f:SetWidth(width);f:SetJustifyH("LEFT");f:SetText(value or "")
 ForeverCompanionVisualTheme.Font(f,size or 12)
 return f
end
local function button(parent,x,y,width,caption,callback)
 local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate");b:SetSize(width,25);b:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y);b:SetText(caption);b:SetScript("OnClick",callback);return b
end
local function cycle(list,value)
 for i,name in ipairs(list) do if name==value then return list[i+1] or "" end end
 return list[1] or ""
end
function W.SetScope(dungeon,boss,record,query)
 local ui=ForeverCompanionLootUI
 ui.dungeon=dungeon or "";ui.boss=boss or "";ui.query=query or ""
 ui.savedOnly=false;ui.acquisition="";ui.slot="";ui.selectedIndex=1
 if record then
  for index,drop in ipairs(ForeverCompanionLoot.BossDrops(ui.dungeon,ui.boss)) do
   if drop==record then ui.selectedIndex=index;break end
  end
 end
 searchBox:SetText(ui.query)
end
function W.Create(parent,openPage,onRefresh)
 navigate=openPage;refresh=onRefresh
 root=CreateFrame("Frame","ForeverCompanionLootCatalog",parent);root:SetPoint("TOPLEFT",parent,"TOPLEFT",8,-5);root:SetSize(770,530);W.root=root
 ForeverCompanionVisualTheme.Panel(root,770,530)
 text(root,16,-13,550,"Loot Catalog",18):SetTextColor(.97,.80,.48)
 button(root,607,-10,147,"Dungeon Journal",function() navigate("Dungeons") end)
 text(root,16,-47,52,"Search",11)
 searchBox=CreateFrame("EditBox",nil,root,"InputBoxTemplate")
 searchBox:SetSize(290,24);searchBox:SetPoint("TOPLEFT",root,"TOPLEFT",68,-41)
 if searchBox.SetAutoFocus then searchBox:SetAutoFocus(false) end
 if searchBox.SetMaxLetters then searchBox:SetMaxLetters(80) end
 searchBox:SetScript("OnTextChanged",function(self,userInput)
  if userInput then
   local ui=ForeverCompanionLootUI
   ui.query=self:GetText();ui.selectedIndex=1;refresh()
  end
 end)
 searchBox:SetScript("OnEnterPressed",function(self) if self.ClearFocus then self:ClearFocus() end end)
 searchBox:SetScript("OnEscapePressed",function(self) if self.ClearFocus then self:ClearFocus() end end)
 savedButton=button(root,372,-41,156,"Wishlist: All",function()
  local ui=ForeverCompanionLootUI
  ui.savedOnly=not ui.savedOnly;ui.selectedIndex=1;refresh()
 end)
 resetButton=button(root,636,-41,118,"Clear filters",function() W.SetScope();refresh() end)
 scope=text(root,16,-74,730,"",12)
 scope:SetTextColor(.93,.79,.51)
 summary=text(root,16,-132,735,"",11)
 statusButton=button(root,16,-99,185,"Acquisition: All",function()
  local ui=ForeverCompanionLootUI
  ui.acquisition=ui.acquisition=="outstanding" and "obtained" or (ui.acquisition=="obtained" and "" or "outstanding")
  ui.selectedIndex=1;refresh()
 end)
 slotButton=button(root,211,-99,154,"Slot: All",function()
  local ui=ForeverCompanionLootUI;ui.slot=cycle(ForeverCompanionLoot.SlotNames(),ui.slot);ui.selectedIndex=1;refresh()
 end)
 W.rows={};W.statusButton=statusButton;W.slotButton=slotButton
 for i=1,W.pageSize do
  local row=CreateFrame("Button",nil,root);row:SetSize(410,42);row:SetPoint("TOPLEFT",root,"TOPLEFT",16,-149-(i-1)*44)
  row.bg=ForeverCompanionVisualTheme.Button(row,410,42)
  row.icon=row:CreateTexture(nil,"ARTWORK")
  row.icon:SetPoint("LEFT",row,"LEFT",10,0);row.icon:SetSize(32,32)
  row.name=text(row,52,-8,346,"",13);row.name:SetHeight(18)
  row.meta=text(row,52,-26,346,"",10);row.meta:SetHeight(16)
  row:SetScript("OnClick",function(self) if self.resultIndex then ForeverCompanionLootUI.selectedIndex=self.resultIndex;refresh() end end)
  row:SetScript("OnEnter",function(self)
   ForeverCompanionLoot.ShowItemTooltip(self,self.record)
  end)
  row:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
  W.rows[i]=row
 end
 empty=text(root,28,-177,380,"No matching records. Clear filters or choose another acquisition state.",13)
 detailPanel=CreateFrame("Frame",nil,root);detailPanel:SetSize(312,320);detailPanel:SetPoint("TOPLEFT",root,"TOPLEFT",442,-149)
 ForeverCompanionVisualTheme.Panel(detailPanel,312,320)
 text(detailPanel,12,-12,288,"Selected item",15):SetTextColor(.97,.80,.48)
 itemTitle=text(detailPanel,12,-47,288,"",14)
 itemTitle:SetTextColor(.97,.80,.48)
 detail=text(detailPanel,12,-92,288,"",12);detail:SetJustifyV("TOP");W.detail=detail;W.detailPanel=detailPanel
 wishButton=button(detailPanel,12,-216,140,"Add to wishlist",function()
  if current and current.selected then
   ForeverCompanionLoot.ToggleWish(current.db,current.selected.item);refresh()
  end
 end)
 obtainedButton=button(detailPanel,160,-216,140,"Mark obtained",function()
  if current and current.selected then
   ForeverCompanionLoot.ToggleObtained(current.db,current.selected.item);refresh()
  end
 end)
 research=button(detailPanel,12,-251,288,"View source boss",function()
  if not current or not current.selected then return end
  ForeverCompanionEncounterBrowser.Focus(current.selected.dungeon,current.selected.boss)
  navigate("Dungeons")
 end)
 W.researchButton=research
 local ui=ForeverCompanionLootUI
 ui.searchBox=searchBox;ui.wishButton=wishButton;ui.obtainedButton=obtainedButton
 ui.savedButton=savedButton;ui.resetButton=resetButton;ui.itemCard=detailPanel;ui.itemTitle=itemTitle
 previous=button(root,16,-420,125,"Previous page",function()
  if current and current.page>1 then ForeverCompanionLootUI.selectedIndex=(current.page-2)*W.pageSize+1;refresh() end
 end)
 nextPage=button(root,301,-420,125,"Next page",function()
  if current and current.page<current.pages then ForeverCompanionLootUI.selectedIndex=current.page*W.pageSize+1;refresh() end
 end)
 pageText=text(root,150,-427,145,"",11);pageText:SetJustifyH("CENTER")
 W.previous=previous;W.nextPage=nextPage
 disclosure=text(root,16,-469,735,"Hover an item for stats. Wishlist and obtained marks are manual.",10)
 root:Hide()
end
function W.GetHeight() return root and root:GetHeight() or 530 end
function W.Render(tab,db,matches)
 if not root then return end
 if tab~="Loot" then root:Hide();detailPanel:Hide();obtainedButton:Hide();current=nil;return end
 local ui=ForeverCompanionLootUI;local loot=ForeverCompanionLoot
 local count=#matches
 ui.selectedIndex=math.max(1,math.min(count,ui.selectedIndex))
 local page=math.floor((ui.selectedIndex-1)/W.pageSize)+1
 local pages=math.max(1,math.ceil(count/W.pageSize))
 local selected=matches[ui.selectedIndex]
 current={page=page,pages=pages,selected=selected,db=db}
 local saved,obtained=0,0
 for _,record in ipairs(matches) do
  if loot.Wishlist(db)[record.item] then saved=saved+1 end
  if loot.Obtained(db,record.item) then obtained=obtained+1 end
 end
 summary:SetText(count.." items  •  "..saved.." wishlisted  •  "..obtained.." marked obtained")
 scope:SetText(ui.dungeon~="" and (ui.dungeon.."  /  "..(ui.boss~="" and ui.boss or "All bosses")) or "All dungeons")
 savedButton:SetText(ui.savedOnly and "Wishlist only" or "Wishlist: All")
 statusButton:SetText("Acquisition: "..(ui.acquisition=="outstanding" and "Not marked" or (ui.acquisition=="obtained" and "Obtained (manual)" or "All")))
 slotButton:SetText("Slot: "..(ui.slot and ui.slot~="" and ui.slot or "All"))
 for i,row in ipairs(W.rows) do
  local index=(page-1)*W.pageSize+i;local record=matches[index]
  row.resultIndex=record and index;row.record=record
  if record then
   row.icon:SetTexture(loot.ItemIcon(record))
   row.name:SetText(record.item)
   local flags=(loot.Wishlist(db)[record.item] and "  •  Wishlisted" or "")..(loot.Obtained(db,record.item) and "  •  Obtained" or "")
   row.meta:SetText((record.slot or "Slot unknown")..flags)
   row.bg:SetColorTexture(index==ui.selectedIndex and .09 or .025,index==ui.selectedIndex and .17 or .028,index==ui.selectedIndex and .24 or .034,1)
   row:Show()
  else row:Hide() end
 end
 if count==0 then empty:Show() else empty:Hide() end
 itemTitle:SetText(selected and selected.item or "No matching loot")
 detail:SetText(selected and table.concat({
  selected.dungeon,selected.boss,selected.slot or "Slot unknown",
  "Item #"..tostring(selected.itemID or "Unknown").."  •  "..(selected.encounterSource and "Icy Veins" or "Wowhead"),
  selected.status,
 },"\n") or "Clear filters or try a different search.")
 local detailHeight=detail:GetStringHeight()+8
 detail:SetHeight(detailHeight)
 local actionY=math.max(216,92+detailHeight+8)
 wishButton:ClearAllPoints();wishButton:SetPoint("TOPLEFT",detailPanel,"TOPLEFT",12,-actionY)
 obtainedButton:ClearAllPoints();obtainedButton:SetPoint("TOPLEFT",detailPanel,"TOPLEFT",160,-actionY)
 research:ClearAllPoints();research:SetPoint("TOPLEFT",detailPanel,"TOPLEFT",12,-actionY-35)
 wishButton:SetText(selected and loot.Wishlist(db)[selected.item] and "Remove wishlist" or "Add to wishlist")
 obtainedButton:SetText(selected and loot.Obtained(db,selected.item) and "Unmark obtained" or "Mark obtained")
 wishButton:SetEnabled(selected~=nil);obtainedButton:SetEnabled(selected~=nil)
 obtainedButton:Show();detailPanel:Show()
 local height=math.max(320,actionY+74)
 ForeverCompanionVisualTheme.ResizePanel(detailPanel,height)
 local disclosureTop=math.max(469,149+height+14)
 disclosure:ClearAllPoints()
 disclosure:SetPoint("TOPLEFT",root,"TOPLEFT",16,-disclosureTop)
 ForeverCompanionVisualTheme.ResizePanel(root,disclosureTop+25)
 pageText:SetText("Page "..page.." / "..pages)
 if previous.SetEnabled then previous:SetEnabled(page>1);nextPage:SetEnabled(page<pages);research:SetEnabled(selected~=nil) end
 root:Show()
end
