-- Personal bank snapshot. Read only while the character can see the banker.
local B={}
ForeverCompanionBankView=B
local bankOpen,pending
local root,header,search,back,nextPage,pageLabel,rows,empty
local page=1
local pageSize=16
local source='bank'
local owner,ownerButton,sourceButton,sortButton
local function character()
 return UnitName('player')..' - '..GetRealmName()
end
local function records()
 ForeverCompanionInventoryDB=ForeverCompanionInventoryDB or {}
 return ForeverCompanionInventoryDB
end
local function ownRecord()
 local all=records();local key=character();all[key]=all[key] or {}
 return all[key]
end
local function inboxCount(n)
 return not (issecretvalue and issecretvalue(n)) and type(n)=='number' and n>=0 and n<math.huge and n%1==0
end
function B.QuestItemCount(itemID)
 local record=records()[character()]
 local snapshot=record and record.bank or (ForeverCompanionDB and ForeverCompanionDB.bankSnapshot)
 if type(snapshot)~='table' or type(snapshot.items)~='table' then return end
 local count=0
 for _,item in ipairs(snapshot.items) do
  if item.id==itemID and inboxCount(item.count) then count=count+item.count end
 end
 return count
end
local outgoing,mailOpen
local function publicText(value,size)
 if (issecretvalue and issecretvalue(value)) or type(value)~='string' then return '' end
 return value:sub(1,size)
end
local function captureOutgoing(recipient,subject)
 if not mailOpen or outgoing then return end
 recipient=publicText(recipient,100)
 if recipient=='' then return end
 local draft={to=recipient,subject=publicText(subject,120),items={}}
 if GetSendMailItem then
  for slot=1,ATTACHMENTS_MAX_SEND or 12 do
   local ok,name,id,icon,count=pcall(GetSendMailItem,slot)
   if ok and inboxCount(id) and id>0 then
    draft.items[#draft.items+1]={name=publicText(name,100),id=id,count=inboxCount(count) and count or 1}
   end
  end
 end
 local money=GetSendMailMoney and GetSendMailMoney()
 local cod=GetSendMailCOD and GetSendMailCOD()
 draft.money=inboxCount(money) and money or 0
 draft.cod=inboxCount(cod) and cod or 0
 outgoing=draft
end
local function saveOutgoing()
 local message=outgoing;outgoing=nil
 if not message then return end
 message.savedAt=time()
 local record=ownRecord()
 if type(record.sent)~='table' then record.sent={} end
 table.insert(record.sent,1,message)
 if #record.sent>100 then table.remove(record.sent) end
 if root and root:IsShown() then B.Render() end
end
if hooksecurefunc and type(SendMail)=='function' then hooksecurefunc('SendMail',captureOutgoing) end
local function captureMail()
 if not GetInboxNumItems or not GetInboxHeaderInfo or not GetInboxItem or not GetInboxItemLink then return end
 local loaded,total=GetInboxNumItems()
 if not inboxCount(loaded) or not inboxCount(total) or total<loaded then return end
 local items={}
 for message=1,loaded do
  local _,_,sender,_,_,_,_,attachments=GetInboxHeaderInfo(message)
  local found=0
  for slot=1,ATTACHMENTS_MAX_RECEIVE or 16 do
   local name,id,icon,count=GetInboxItem(message,slot)
   if name then
    local link=GetInboxItemLink(message,slot)
    id=tonumber(id) or (link and tonumber(link:match('item:(%d+)')))
    if not id then return end
    items[#items+1]={name=name,id=id,icon=icon,count=count or 1,link=link,tab=sender or 'Mail'}
    found=found+1
   end
  end
  if attachments and (not inboxCount(attachments) or found~=attachments) then return end
 end
 local latestLoaded,latestTotal=GetInboxNumItems()
 if latestLoaded~=loaded or latestTotal~=total then return end
 local record=ownRecord()
 local snapshot={items=items,loaded=loaded,total=total,savedAt=time()}
 if snapshot.loaded<snapshot.total then
  record.partialMail=snapshot
  if not record.mail or (inboxCount(record.mail.loaded) and inboxCount(record.mail.total) and record.mail.loaded<record.mail.total) then record.mail=snapshot end
 else
  record.mail=snapshot;record.partialMail=nil
 end
 if root and root:IsShown() then B.Render() end
end

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
 ownRecord().bank=data
 if root and root:IsShown() then B.Render() end
end

local events=CreateFrame("Frame")
for _,event in ipairs({"PLAYER_LOGIN","MAIL_SHOW","MAIL_INBOX_UPDATE","MAIL_CLOSED","MAIL_SEND_SUCCESS","MAIL_FAILED","BANKFRAME_OPENED","BANKFRAME_CLOSED","PLAYERBANKSLOTS_CHANGED","BAG_UPDATE_DELAYED","BANK_TABS_CHANGED"}) do
 pcall(events.RegisterEvent,events,event)
end
events:SetScript("OnEvent",function(_,event)
 if event=='PLAYER_LOGIN' then
  if ForeverCompanionDB and ForeverCompanionDB.bankSnapshot then ownRecord().bank=ForeverCompanionDB.bankSnapshot end
  return
 elseif event=='MAIL_SHOW' then
  mailOpen=true
  if GetInboxNumItems and (GetInboxNumItems() or 0)>0 then captureMail() end
  return
 elseif event=='MAIL_SEND_SUCCESS' then saveOutgoing();return
 elseif event=='MAIL_FAILED' then outgoing=nil;return
 elseif event=='MAIL_CLOSED' then mailOpen=false;outgoing=nil;return
 elseif event=='MAIL_INBOX_UPDATE' then if mailOpen then captureMail() end;return end
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
 search=ForeverCompanionInterface.EditBox(root,"Search your saved bank…")
 search:SetSize(246,24);search:SetPoint("TOPLEFT",20,-47);if search.SetAutoFocus then search:SetAutoFocus(false) end
 search:SetScript("OnTextChanged",function() page=1;B.Render() end)
 search:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
 local filter=root:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
 filter:SetPoint("LEFT",search,"RIGHT",12,0);filter:SetText("Search items")
 sourceButton=makeButton(root,362,-47,'Mailbox',function()
  local entries={}
  for _,view in ipairs({{'bank','Bank'},{'mail','Inbox'},{'sent','Sent mail'}}) do
   local key=view[1];entries[#entries+1]={label=view[2],selected=source==key,action=function() source=key;page=1;B.Render() end}
  end
  ForeverCompanionInterface.Menu(sourceButton,'INVENTORY VIEW',entries)
 end)
 ownerButton=makeButton(root,452,-47,'Alts',function()
  local keys={character()};for key in pairs(records()) do if key~=character() then keys[#keys+1]=key end end
  table.sort(keys);local choices={{label='All characters and inventories',selected=owner==false,action=function() owner=false;page=1;B.Render() end}}
  for _,key in ipairs(keys) do local who=key
   choices[#choices+1]={label=who,selected=owner~=false and who==(owner or character()),action=function() owner=who;page=1;B.Render() end}
  end
  ForeverCompanionInterface.PagedMenu(ownerButton,'Choose character',choices,nil,290)
 end)
 sortButton=makeButton(root,542,-47,'Sort',function()
  local db=ForeverCompanionDB
  db.inventorySort=db.inventorySort=='category' and 'name' or 'category';page=1;B.Render()
 end)
 sortButton:SetWidth(130)
 local function wheel(_,delta) page=page+(delta<0 and 1 or -1);B.Render() end
 root:EnableMouseWheel(true);root:SetScript('OnMouseWheel',wheel)
 rows={}
 for i=1,pageSize do
  local row=CreateFrame("Frame",nil,root)
  row:SetSize(356,34)
  row:SetPoint("TOPLEFT",root,"TOPLEFT",17+((i-1)%2)*375,-82-math.floor((i-1)/2)*36)
  local bg=row:CreateTexture(nil,"BACKGROUND")
  bg:SetAllPoints(row);bg:SetColorTexture(.08,.11,.16,1)
  row.icon=row:CreateTexture(nil,"ARTWORK");row.icon:SetSize(25,25);row.icon:SetPoint("LEFT",5,0)
  row.name=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
  row.name:SetPoint("TOPLEFT",38,-5);row.name:SetWidth(254);row.name:SetJustifyH("LEFT");row.name:SetWordWrap(false);row.name:SetHeight(16)
  ForeverCompanionVisualTheme.Font(row.name,12)
  row.count=ForeverCompanionInterface.Text(row,11)
  row.count:SetPoint("TOPRIGHT",row,"TOPRIGHT",-7,-5);row.count:SetWidth(48);row.count:SetJustifyH("RIGHT")
  row.tab=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
  row.tab:SetPoint("TOPLEFT",38,-19);row.tab:SetTextColor(.60,.67,.75);row.tab:SetWidth(306);row.tab:SetWordWrap(false);row.tab:SetHeight(13)
  ForeverCompanionVisualTheme.Font(row.tab,10)
  ForeverCompanionVisualTheme.SelectRow(row,bg,false)
  row:EnableMouse(true)
  row:SetScript("OnEnter",function(self)
   if self.item and GameTooltip then
    GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
    if self.item.id then GameTooltip:SetHyperlink(self.item.link or ('item:'..self.item.id))
    else GameTooltip:SetText(self.item.name or 'Sent mail') end
    if self.item.sent then GameTooltip:AddLine(self.item.tab,.86,.82,.72,true) end
    GameTooltip:Show()
   end
  end)
  row:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
  row:EnableMouseWheel(true);row:SetScript("OnMouseWheel",wheel)
  rows[i]=row
 end
 back=makeButton(root,17,-381,"Previous",function() page=page-1;B.Render() end)
 nextPage=makeButton(root,108,-381,"Next",function() page=page+1;B.Render() end)
 empty=ForeverCompanionInterface.Text(root,14)
 empty:SetPoint("TOPLEFT",root,"TOPLEFT",32,-101);empty:SetWidth(706);empty:SetHeight(65);empty:SetWordWrap(true);empty:SetJustifyH("CENTER")
 pageLabel=root:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
 pageLabel:SetPoint("LEFT",nextPage,"RIGHT",14,0)
 root:Hide()
end

function B.Render()
 if not root then return end
 local who=owner or character()
 local saved=(records()[who] or {})[source]
 if not saved and who==character() and source=='bank' then saved=ForeverCompanionDB and ForeverCompanionDB.bankSnapshot end
 local byCategory=source~='sent' and ForeverCompanionDB and ForeverCompanionDB.inventorySort=='category'
 sourceButton:SetText(({bank='Bank',mail='Inbox',sent='Sent mail'})[source])
 sortButton:SetEnabled(source~='sent' or owner==false)
 sortButton:SetText(byCategory and 'Sort: category' or 'Sort: A-Z')
 local items=type(saved)=="table" and saved.items
 local matches={}
 local query=(search:GetText() or ""):lower()
 local function collect(items,location)
 for _,item in ipairs(type(items)=="table" and items or {}) do
  local name=item.name or (C_Item and C_Item.GetItemNameByID and C_Item.GetItemNameByID(item.id)) or ("Item "..item.id)
  if (name..(item.sent and (' '..item.tab..' '..item.subject) or '')):lower():find(query,1,true) then matches[#matches+1]={item=item,name=name,location=location} end
 end
 end
 sourceButton:SetEnabled(owner~=false)
 if owner==false then
  for name,record in pairs(records()) do
   for _,kind in ipairs({'bank','mail'}) do
    local snapshot=record[kind]
    if snapshot then collect(snapshot.items,name..' / '..(kind=='bank' and 'Bank' or 'Mailbox')) end
   end
  end
 elseif source=='sent' then
  local messages=type(saved)=='table' and saved or {}
  for index,message in ipairs(messages) do
   local context='To '..message.to..' / '..date('%b %d, %H:%M',message.savedAt)
   local items=message.items
   local currency=GetCoinTextureString
   local detail=message.money>0 and (' / '..(currency and currency(message.money) or message.money..' copper')) or ''
   if message.cod>0 then detail=detail..' / COD '..(currency and currency(message.cod) or message.cod..' copper') end
   if #items==0 then collect({{name=message.subject~='' and message.subject or 'Sent message',tab=context..detail,subject=message.subject,sent=index}}) end
   for _,item in ipairs(items) do
    collect({{name=item.name~='' and item.name or nil,id=item.id,count=item.count,
     tab=context..detail..(message.subject~='' and (' / '..message.subject) or ''),subject=message.subject,sent=index}})
   end
  end
 else collect(items) end
 for _,entry in ipairs(matches) do
  local info=C_Item and C_Item.GetItemInfo or GetItemInfo
  entry.category=byCategory and info and select(6,info(entry.item.id)) or 'Other'
 end
 table.sort(matches,function(a,b)
  if source=='sent' and owner~=false and a.item.sent~=b.item.sent then return a.item.sent<b.item.sent end
  if byCategory and a.category~=b.category then return a.category<b.category end
  if a.name~=b.name then return a.name:lower()<b.name:lower() end
  if a.location~=b.location then return (a.location or "")<(b.location or "") end
  return (a.item.count or 1)>(b.item.count or 1)
 end)
 if owner==false then header:SetText('All characters | Saved bank items and mailbox attachments')
 elseif source=='sent' then header:SetText(('%s | Sent mail | %d recorded messages'):format(who,type(saved)=='table' and #saved or 0))
 elseif source=='mail' and saved then
  local partial=(records()[who] or {}).partialMail
  local detail=partial and (saved==partial or saved.loaded<saved.total) and ' | Partial inbox' or (partial and (' | Latest read partial: '..partial.loaded..'/'..partial.total) or '')
  header:SetText(('%s | Mailbox | %d attachments | %d/%d messages | %s%s'):format(who,#items,saved.loaded,saved.total,date('%b %d, %H:%M',saved.savedAt),detail))
 elseif type(items)=="table" and type(saved.savedAt)=="number" and type(saved.slots)=="number" then
  header:SetText((who.." | Bank  ·  %d/%d slots  ·  Saved %s"):format(#items,saved.slots,date("%b %d, %H:%M",saved.savedAt)))
 else header:SetText(who..(source=='mail' and ' | Open this character mailbox to save attachments.' or ' | Visit a banker to save inventory.')) end
 local pages=math.max(1,math.ceil(#matches/pageSize))
 page=math.max(1,math.min(page,pages))
 local visible=math.min(pageSize,math.max(0,#matches-(page-1)*pageSize))
 local footerY=94+(visible==0 and 3 or math.ceil(visible/2))*36
 local priorHeight=root:GetHeight()
 ForeverCompanionVisualTheme.ResizePanel(root,footerY+44)
 if priorHeight~=root:GetHeight() and B.OnLayout then B.OnLayout(root:GetHeight()-priorHeight) end
 back:ClearAllPoints();back:SetPoint('TOPLEFT',root,'TOPLEFT',17,-footerY)
 nextPage:ClearAllPoints();nextPage:SetPoint('TOPLEFT',root,'TOPLEFT',108,-footerY)
 for i,row in ipairs(rows) do
  local entry=matches[(page-1)*pageSize+i]
  row.item=entry and entry.item
  if entry then
   local item=entry.item
   row.icon:SetTexture(item.icon or 134400)
   row.name:SetText(entry.name)
   row.count:SetText(item.sent and not item.id and '' or 'x'..tostring(item.count or 1))
   row.tab:SetText((entry.location and (entry.location..' / ') or '')..(byCategory and (entry.category..' / ') or '')..(item.tab or ''))
   row:Show()
  else row:Hide() end
 end
 empty:SetShown(#matches==0)
 empty:SetText(owner==false and "No matching items in saved banks or mailboxes." or source=='sent' and 'No matching sent mail. Messages appear after the game confirms sending.' or type(items)~="table" and "No snapshot recorded for this character and inventory." or (query~="" and "No items match this search. Try another name or clear the field." or "There are no items in this snapshot."))
 back:SetEnabled(page>1);nextPage:SetEnabled(page<pages)
 pageLabel:SetText(("%d matches  ·  Page %d of %d"):format(#matches,page,pages))
end

function B.GetHeight() return root and root:GetHeight() or 425 end

function B.Show(show)
 if not root then return end
 if show then root:Show();B.Render() else root:Hide() end
end
