-- Optional reverse reward index over QuestieDB's documented Item.questRewards API.
-- Runtime reads only: no third-party database is bundled and no reward is selected.
local Q={entries={},loading=false,generation=0};ForeverCompanionQuestRewards=Q
local function call(fn,...) if type(fn)~='function' then return end;local ok,a=pcall(fn,...);if ok then return a end end
local function id(n) return not (issecretvalue and issecretvalue(n)) and type(n)=='number' and n==n and n>0 and n%1==0 and n<1e9 end
local function provider() return ForeverCompanionQuestLocations and call(ForeverCompanionQuestLocations.Provider) end
local function live(q) return ForeverCompanionQuestJourney and ForeverCompanionQuestJourney.Resolve(q) end
function Q.Cancel() Q.generation=Q.generation+1;Q.loading=false end
function Q.Scan(quest,callback)
 Q.Cancel();local db=provider();local fresh=live(quest)
 if not fresh then return false,'Quest changed or quest scan unavailable.' end
 if not db or not db.Item or type(db.Item.questRewards)~='function' then return false,'Compatible Forever QuestieDB reward references are unavailable.' end
 local ids=call(db.Item.GetAllIds)
 if type(ids)~='table' or not C_Timer or type(C_Timer.After)~='function' then return false,'Reward search is unavailable on this client.' end
 Q.provider=db;Q.loading=true;local cursor,token,found=1,Q.generation,{}
 local identity={id=fresh.id,title=fresh.title}
 local function batch()
  if token~=Q.generation then return end
  if db~=provider() or not live(identity) then Q.Cancel();Q.message='Quest or reference data changed. Search again.';if callback then callback() end;return end
  for i=cursor,math.min(cursor+79,#ids) do
   local itemID=ids[i]
   if id(itemID) then
    local rewards=call(db.Item.questRewards,itemID)
    for _,questID in ipairs(type(rewards)=='table' and rewards or {}) do if questID==identity.id then
     local name=call(db.Item.name,itemID)
     if type(name)=='string' then found[#found+1]={itemID=itemID,item=name,questID=identity.id,questTitle=identity.title};if #found>=100 then break end end
    end end
   end
   if #found>=100 then break end
  end
  cursor=cursor+80
  if cursor<=#ids and #found<100 then C_Timer.After(.01,batch)
  else
   table.sort(found,function(a,b) return a.itemID<b.itemID end);Q.entries[identity.id]=found;Q.loading=false
   Q.message=#found..' item reward references'..(#found>=100 and ' (limited to 100)' or '')..'. Choices, quantities and eligibility must be checked in game.'
   if ForeverCompanionGearFinder then ForeverCompanionGearFinder.Invalidate() end
   if callback then callback() end
  end
 end
 C_Timer.After(0,batch);return true,'Searching item reward references in bounded batches…'
end
function Q.ForQuest(quest)
 if provider()~=Q.provider then return {} end
 local result={};local db=provider()
 for _,r in ipairs(Q.entries[quest.id] or {}) do
  if r.questTitle==quest.title and call(db.Quest.name,r.questID)==quest.title then
   for _,qid in ipairs(call(db.Item.questRewards,r.itemID) or {}) do if qid==quest.id then result[#result+1]=r;break end end
  end
 end
 return result
end
local slots={INVTYPE_HEAD='Head',INVTYPE_NECK='Neck',INVTYPE_SHOULDER='Shoulder',INVTYPE_CHEST='Chest',INVTYPE_ROBE='Chest',INVTYPE_WAIST='Waist',INVTYPE_LEGS='Legs',INVTYPE_FEET='Feet',INVTYPE_WRIST='Wrist',INVTYPE_HAND='Hands',INVTYPE_FINGER='Finger',INVTYPE_TRINKET='Trinket',INVTYPE_CLOAK='Back',INVTYPE_WEAPON='One-Hand',INVTYPE_2HWEAPON='Two-Hand',INVTYPE_WEAPONMAINHAND='Main Hand',INVTYPE_WEAPONOFFHAND='Off Hand',INVTYPE_SHIELD='Off Hand',INVTYPE_HOLDABLE='Off Hand',INVTYPE_RANGED='Ranged',INVTYPE_RANGEDRIGHT='Ranged',INVTYPE_THROWN='Ranged'}
function Q.Catalog()
 local result={}
 for questID,list in pairs(Q.entries) do
  local title=list[1] and list[1].questTitle
  if title then for _,r in ipairs(Q.ForQuest({id=questID,title=title})) do
   local name,link,quality,level,required,kind,subkind,stack,equip=ForeverCompanionGearFinder.Call(C_Item and C_Item.GetItemInfo,r.itemID)
   if type(name)~='string' then ForeverCompanionGearFinder.Request(r.itemID) end
   if type(name)=='string' and slots[equip] then result[#result+1]={itemID=r.itemID,item=r.item,slot=slots[equip],dungeon='Quest rewards',boss=title,questID=questID,status='QuestieDB reward reference; check reward choices in game',source='Installed Forever QuestieDB Item.questRewards public API'} end
  end end
 end
 return result
end
local panel,title,body,status,selected,page,buttons
function Q.Refresh()
 if not panel or not panel:IsShown() then return end
 local fresh=live(selected);local rows=fresh and Q.ForQuest(fresh) or {};local pages=math.max(1,math.ceil(#rows/4));page=math.min(page,pages)
 title:SetText('QUEST REWARD EQUIPMENT · '..(selected.title or 'Quest'));status:SetText(not fresh and 'Quest changed or scan unavailable. Reopen this review.' or Q.loading and 'Searching the installed database…' or Q.message or 'Search the installed reference database.')
 body:SetText('Reference rewards can be alternatives, not all guaranteed. Hover an item to review its exact tooltip. Compare uses your gear weights; no reward is selected or equipped.')
 for i,b in ipairs(buttons) do
  local r=rows[(page-1)*4+i];b.record=r;b:SetShown(r~=nil)
  if r then
   local info=ForeverCompanionGearFinder.Read(r.itemID)
   local row=info and ForeverCompanionGearFinder.CompareLink(info.link)
   b:SetText(r.item..'\n'..(row and row.reason or 'Item stats loading / manual review'))
  end
 end
end
function Q.Open(quest)
 if not live(quest) then return false end
 selected={id=quest.id,title=quest.title};page=1
 if not panel then
  local U=ForeverCompanionInterface
  panel=CreateFrame('Frame','ForeverCompanionQuestRewardReview',UIParent,'BackdropTemplate');panel:SetSize(650,430);panel:SetPoint('CENTER');panel:SetFrameStrata('DIALOG');U.Surface(panel);U.PreparePanel(panel,'ForeverCompanionQuestRewardReview',650,430);U.CloseButton(panel,function() Q.Cancel();panel:Hide() end)
  title=U.Text(panel,15);title:SetPoint('TOPLEFT',16,-18);title:SetWidth(584)
  body=U.Text(panel,11);body:SetPoint('TOPLEFT',16,-52);body:SetSize(618,48);body:SetWordWrap(true)
  status=U.Text(panel,11);status:SetPoint('TOPLEFT',16,-344);status:SetSize(618,42);status:SetWordWrap(true)
  buttons={}
  for i=1,4 do local b=U.Button(panel);b:SetPoint('TOPLEFT',16,-105-(i-1)*58);b:SetSize(618,52);b:GetFontString():SetWordWrap(true);b:GetFontString():SetHeight(44)
   b:SetScript('OnClick',function() if not live(selected) or not b.record then status:SetText('Quest changed. Reopen reward review.');return end;local info=ForeverCompanionGearFinder.Read(b.record.itemID);if not info or not slots[info.equip] then status:SetText('Item is not cached equipment. Refresh comparisons or inspect its tooltip.');return end;ForeverCompanionGearFinderWorkspace.Open(b.record.itemID) end)
   b:SetScript('OnEnter',function(self) if self.record and GameTooltip then GameTooltip:SetOwner(self,'ANCHOR_RIGHT');GameTooltip:SetHyperlink('item:'..self.record.itemID);GameTooltip:Show() end end);b:SetScript('OnLeave',function() if GameTooltip then GameTooltip:Hide() end end);buttons[i]=b
  end
  local function button(x,w,label,fn) local b=U.Button(panel);b:SetPoint('BOTTOMLEFT',x,12);b:SetSize(w,26);b:SetText(label);b:SetScript('OnClick',fn) end
  button(16,150,'Search rewards',function() local _,msg=Q.Scan(selected,Q.Refresh);Q.message=msg;Q.Refresh() end)
  button(176,100,'Previous',function() page=math.max(1,page-1);Q.Refresh() end)
  button(286,100,'Next',function() page=page+1;Q.Refresh() end)
  button(396,238,'Refresh item comparisons',function() ForeverCompanionGearFinder.LoadBatch();Q.Refresh() end)
  panel:HookScript('OnHide',Q.Cancel)
 end
 panel:Show();Q.message='Press Search rewards to inspect source-attributed rewards.';Q.Refresh();return true
end
