-- Clickable catalog rows and source detail. All progress is entered manually.
local W={pageSize=6}
ForeverCompanionLootWorkspace=W
local root,summary,detail,detailPanel,empty,pageText,previous,nextPage,research,slotButton,statusButton,current,navigate,refresh
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
function W.Create(parent,openPage,onRefresh)
 navigate=openPage;refresh=onRefresh
 root=CreateFrame("Frame","ForeverCompanionLootCatalog",parent);root:SetPoint("TOPLEFT",parent,"TOPLEFT",8,-210);root:SetSize(770,530);W.root=root
 ForeverCompanionVisualTheme.Panel(root,770,530)
 text(root,16,-13,730,"GEAR TARGET CATALOG",18):SetTextColor(.97,.80,.48)
 summary=text(root,16,-43,735,"")
 statusButton=button(root,16,-69,222,"Acquisition: All",function()
  local ui=ForeverCompanionLootUI
  ui.acquisition=ui.acquisition=="outstanding" and "obtained" or (ui.acquisition=="obtained" and "" or "outstanding")
  ui.selectedIndex=1;refresh()
 end)
 slotButton=button(root,248,-69,220,"Slot: All",function()
  local ui=ForeverCompanionLootUI;ui.slot=cycle(ForeverCompanionLoot.SlotNames(),ui.slot);ui.selectedIndex=1;refresh()
 end)
 research=button(root,478,-69,276,"Open selected boss research",function()
  if not current or not current.selected then return end
  local selected=current.selected
  local browser=ForeverCompanionEncounterBrowser
  browser.dungeon=selected.dungeon;browser.boss=selected.boss;browser.query="";browser.page=1
  if browser.searchBox then browser.searchBox:SetText("") end
  -- Focus the selected boss's catalog page as well as its notebook context.
  for i,entry in ipairs(browser.Results(browser.dungeon,"")) do
   if entry.boss==browser.boss then browser.page=math.floor((i-1)/browser.pageSize)+1;break end
  end
  navigate("Dungeons")
 end)
 W.rows={};W.statusButton=statusButton;W.slotButton=slotButton;W.researchButton=research
 for i=1,W.pageSize do
  local row=CreateFrame("Button",nil,root);row:SetSize(410,52);row:SetPoint("TOPLEFT",root,"TOPLEFT",16,-111-(i-1)*57)
  row.bg=ForeverCompanionVisualTheme.Button(row,410,52)
  row.name=text(row,12,-8,386,"",13);row.name:SetHeight(18)
  row.meta=text(row,12,-30,386,"",10);row.meta:SetHeight(16)
  row:SetScript("OnClick",function(self) if self.resultIndex then ForeverCompanionLootUI.selectedIndex=self.resultIndex;refresh() end end)
  row:SetScript("OnEnter",function(self)
   if self.record and GameTooltip then
    GameTooltip:SetOwner(self,"ANCHOR_RIGHT");GameTooltip:SetText(self.record.item,1,.8,.4)
    GameTooltip:AddLine(self.record.boss.." / "..self.record.dungeon,1,1,1,true)
    GameTooltip:AddLine(self.record.status,.7,.8,.9,true);GameTooltip:Show()
   end
  end)
  row:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
  W.rows[i]=row
 end
 empty=text(root,28,-135,380,"No matching records. Clear filters or choose another acquisition state.",13)
 detailPanel=CreateFrame("Frame",nil,root);detailPanel:SetSize(312,370);detailPanel:SetPoint("TOPLEFT",root,"TOPLEFT",442,-111)
 ForeverCompanionVisualTheme.Panel(detailPanel,312,370)
 text(detailPanel,12,-12,288,"ITEM & SOURCE",15):SetTextColor(.97,.80,.48)
 detail=text(detailPanel,12,-46,288,"",12);detail:SetJustifyV("TOP");W.detail=detail;W.detailPanel=detailPanel
 previous=button(root,16,-464,125,"Previous page",function()
  if current and current.page>1 then ForeverCompanionLootUI.selectedIndex=(current.page-2)*W.pageSize+1;refresh() end
 end)
 nextPage=button(root,301,-464,125,"Next page",function()
  if current and current.page<current.pages then ForeverCompanionLootUI.selectedIndex=current.page*W.pageSize+1;refresh() end
 end)
 pageText=text(root,150,-472,145,"",11);pageText:SetJustifyH("CENTER")
 W.previous=previous;W.nextPage=nextPage
 text(root,16,-505,735,"Partial beta catalog / manual marks are not inventory checks, drop guarantees or BiS rankings.",10)
 root:Hide()
end
function W.GetHeight() return root and root:GetHeight() or 530 end
function W.Render(tab,db,matches)
 if not root then return end
 if tab~="Loot" then root:Hide();current=nil;return end
 local ui=ForeverCompanionLootUI;local loot=ForeverCompanionLoot
 local count=#matches
 ui.selectedIndex=math.max(1,math.min(count,ui.selectedIndex))
 local page=math.floor((ui.selectedIndex-1)/W.pageSize)+1
 local pages=math.max(1,math.ceil(count/W.pageSize))
 local selected=matches[ui.selectedIndex]
 current={page=page,pages=pages,selected=selected}
 local saved,obtained=0,0
 for _,record in ipairs(matches) do
  if loot.Wishlist(db)[record.item] then saved=saved+1 end
  if loot.Obtained(db,record.item) then obtained=obtained+1 end
 end
 summary:SetText(count.." matching records  /  "..saved.." saved targets  /  "..obtained.." manually marked obtained")
 statusButton:SetText("Acquisition: "..(ui.acquisition=="outstanding" and "Not marked" or (ui.acquisition=="obtained" and "Obtained (manual)" or "All")))
 slotButton:SetText("Slot: "..(ui.slot and ui.slot~="" and ui.slot or "All"))
 for i,row in ipairs(W.rows) do
  local index=(page-1)*W.pageSize+i;local record=matches[index]
  row.resultIndex=record and index;row.record=record
  if record then
   row.name:SetText(record.item)
   row.meta:SetText((record.slot or "Slot unknown").."  /  "..(loot.Wishlist(db)[record.item] and "SAVED" or "Not saved").."  /  "..(loot.Obtained(db,record.item) and "Obtained (manual)" or "Not marked"))
   row.bg:SetColorTexture(index==ui.selectedIndex and .09 or .025,index==ui.selectedIndex and .17 or .028,index==ui.selectedIndex and .24 or .034,1)
   row:Show()
  else row:Hide() end
 end
 if count==0 then empty:Show() else empty:Hide() end
 detail:SetText(selected and loot.Detail(selected,db) or "No selected item. Clear filters to browse the sourced catalog. Unknown records never become automatic gear recommendations.")
 local height=math.max(370,detail:GetStringHeight()+65)
 detail:SetHeight(height-58)
 ForeverCompanionVisualTheme.ResizePanel(detailPanel,height)
 ForeverCompanionVisualTheme.ResizePanel(root,math.max(530,111+height+18))
 pageText:SetText("Page "..page.." / "..pages)
 if previous.SetEnabled then previous:SetEnabled(page>1);nextPage:SetEnabled(page<pages);research:SetEnabled(selected~=nil) end
 root:Show()
end
