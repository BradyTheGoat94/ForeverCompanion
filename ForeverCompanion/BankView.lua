-- Personal bank snapshot. Read only while the character can see the banker.
local B={}
ForeverCompanionBankView=B
local bankOpen,pending
local root,header,search,back,nextPage,pageLabel,rows
local page=1
local pageSize=16

local function capture()
 if not C_Bank or not C_Container or not Enum or not Enum.BankType then return end
 local kind=Enum.BankType.Character
 if kind==nil or not C_Bank.CanViewBank(kind) then return end
 local tabs=C_Bank.FetchPurchasedBankTabData(kind)
 if type(tabs)~="table" or #tabs==0 then return end
 local items,slots={},0
 for i,tab in ipairs(tabs) do
  local count=C_Container.GetContainerNumSlots(tab.ID)
  if type(count)~="number" or count<1 or count>1000 then return end
  slots=slots+count
  for slot=1,count do
   local item=C_Container.GetContainerItemInfo(tab.ID,slot)
   if item then
    if type(item.itemID)~="number" then return end
    local link=item.hyperlink
    items[#items+1]={id=item.itemID,count=item.stackCount or 1,icon=item.iconFileID,
     link=link,name=type(link)=="string" and link:match("%[(.-)%]") or nil,tab=tab.name or ("Tab "..i)}
   end
  end
 end
 return {items=items,slots=slots,savedAt=(GetServerTime and GetServerTime()) or time()}
end

local function updateSnapshot()
 pending=false
 if not bankOpen then return end
 local ok,data=pcall(capture)
 if not ok or not data then return end
 ForeverCompanionDB=ForeverCompanionDB or {}
 ForeverCompanionDB.bankSnapshot=data
 if root and root:IsShown() then B.Render() end
end

local events=CreateFrame("Frame")
for _,event in ipairs({"BANKFRAME_OPENED","BANKFRAME_CLOSED","PLAYERBANKSLOTS_CHANGED","BAG_UPDATE_DELAYED","BANK_TABS_CHANGED"}) do
 pcall(events.RegisterEvent,events,event)
end
events:SetScript("OnEvent",function(_,event)
 if event=="BANKFRAME_CLOSED" then bankOpen=false;return end
 if event=="BANKFRAME_OPENED" then
  bankOpen=true
 elseif bankOpen then
  updateSnapshot()
  return
 end
 if not bankOpen or pending then return end
 if C_Timer and C_Timer.After then
  pending=true
  C_Timer.After(.12,updateSnapshot)
 else updateSnapshot() end
end)

local function makeButton(parent,x,y,label,click)
 local button=ForeverCompanionInterface.Button(parent)
 button:SetSize(82,24)
 button:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
 button:SetText(label)
 button:SetScript("OnClick",click)
 return button
end

function B.Create(parent)
 root=CreateFrame("Frame",nil,parent)
 root:SetPoint("TOPLEFT",parent,"TOPLEFT",8,-7)
 root:SetSize(770,425)
 ForeverCompanionVisualTheme.Panel(root,770,425)
 header=root:CreateFontString(nil,"OVERLAY","GameFontHighlight")
 header:SetPoint("TOPLEFT",17,-22)
 header:SetWidth(735)
 header:SetJustifyH("LEFT")
 search=ForeverCompanionInterface.EditBox(root)
 search:SetSize(246,24);search:SetPoint("TOPLEFT",20,-47);if search.SetAutoFocus then search:SetAutoFocus(false) end
 search:SetScript("OnTextChanged",function() page=1;B.Render() end)
 search:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
 local filter=root:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
 filter:SetPoint("LEFT",search,"RIGHT",12,0);filter:SetText("Search items")
 rows={}
 for i=1,pageSize do
  local row=CreateFrame("Frame",nil,root)
  row:SetSize(356,34)
  row:SetPoint("TOPLEFT",root,"TOPLEFT",17+((i-1)%2)*375,-82-math.floor((i-1)/2)*36)
  local bg=row:CreateTexture(nil,"BACKGROUND")
  bg:SetAllPoints(row);bg:SetColorTexture(.08,.11,.16,1)
  row.icon=row:CreateTexture(nil,"ARTWORK");row.icon:SetSize(25,25);row.icon:SetPoint("LEFT",5,0)
  row.name=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
  row.name:SetPoint("TOPLEFT",38,-5);row.name:SetWidth(312);row.name:SetJustifyH("LEFT")
  row.tab=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
  row.tab:SetPoint("TOPLEFT",38,-19);row.tab:SetTextColor(.62,.76,.83)
  row:EnableMouse(true)
  row:SetScript("OnEnter",function(self)
   if self.item and GameTooltip then
    GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
    GameTooltip:SetHyperlink(self.item.link or ("item:"..self.item.id))
    GameTooltip:Show()
   end
  end)
  row:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
  rows[i]=row
 end
 back=makeButton(root,17,-381,"Previous",function() page=page-1;B.Render() end)
 nextPage=makeButton(root,108,-381,"Next",function() page=page+1;B.Render() end)
 pageLabel=root:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
 pageLabel:SetPoint("LEFT",nextPage,"RIGHT",14,0)
 root:Hide()
end

function B.Render()
 if not root then return end
 local saved=ForeverCompanionDB and ForeverCompanionDB.bankSnapshot
 local items=type(saved)=="table" and saved.items
 local matches={}
 local query=(search:GetText() or ""):lower()
 for _,item in ipairs(type(items)=="table" and items or {}) do
  local name=item.name or (C_Item and C_Item.GetItemNameByID and C_Item.GetItemNameByID(item.id)) or ("Item "..item.id)
  if name:lower():find(query,1,true) then matches[#matches+1]={item=item,name=name} end
 end
 if type(items)=="table" and type(saved.savedAt)=="number" and type(saved.slots)=="number" then
  header:SetText(("Personal bank snapshot  ·  %d/%d slots  ·  Saved %s"):format(#items,saved.slots,date("%b %d, %H:%M",saved.savedAt)))
 else header:SetText("Visit a banker once to save a copy of your personal bank.") end
 local pages=math.max(1,math.ceil(#matches/pageSize))
 page=math.max(1,math.min(page,pages))
 for i,row in ipairs(rows) do
  local entry=matches[(page-1)*pageSize+i]
  row.item=entry and entry.item
  if entry then
   local item=entry.item
   row.icon:SetTexture(item.icon or 134400)
   row.name:SetText(("%s  ×%d"):format(entry.name,item.count))
   row.tab:SetText(item.tab)
   row:Show()
  else row:Hide() end
 end
 back:SetEnabled(page>1);nextPage:SetEnabled(page<pages)
 pageLabel:SetText(("%d matches  ·  Page %d of %d"):format(#matches,page,pages))
end

function B.Show(show)
 if not root then return end
 if show then root:Show();B.Render() else root:Hide() end
end
