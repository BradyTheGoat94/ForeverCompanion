-- Inventory observations, a small pinned-hunt tracker and local acquisition notices.
local H={};ForeverCompanionGearHunts=H
local G=ForeverCompanionGearFinder
local V=ForeverCompanionGearVisuals
local tracker,trackerTitle,trackerSource,toast,toastText,toastID
local hooks=setmetatable({},{__mode='k'})
local function text(parent,x,y,width,size)
 local f=ForeverCompanionInterface.Text(parent,size);f:SetPoint('TOPLEFT',x,y);f:SetWidth(width);return f
end
local function button(parent,x,y,width,label,action)
 local b=ForeverCompanionInterface.Button(parent,V.Palette('hunts'));b:SetPoint('TOPLEFT',x,y);b:SetSize(width,25);b:SetText(label);b:SetScript('OnClick',action);return b
end
function H.Refresh()
 local cfg=G.Settings();if not cfg.tracked or cfg.trackerHidden then if tracker then tracker:Hide() end;return end
 local _,catalog=G.Catalog();local entry=catalog[tonumber(cfg.tracked)]
 if not entry or cfg.trackerHidden then if tracker then tracker:Hide() end;return end
 if not tracker then
  tracker=CreateFrame('Frame','ForeverCompanionGearHuntTracker',UIParent);H.tracker=tracker
  tracker:SetSize(330,125);tracker:SetPoint('BOTTOMLEFT',UIParent,'BOTTOMLEFT',20,180);tracker:SetFrameStrata('MEDIUM');tracker:SetClampedToScreen(true)
  V.Compact(tracker,330,125,'hunts');ForeverCompanionInterface.PreparePanel(tracker,'ForeverCompanionGearHuntTracker',330,125)
  tracker:SetMovable(true);tracker:EnableMouse(true);tracker:RegisterForDrag('LeftButton');tracker:SetScript('OnDragStart',function(self) self:StartMoving() end);tracker:SetScript('OnDragStop',function(self) self:StopMovingOrSizing() end)
  local heading=text(tracker,12,-8,306,10);heading:SetText('PINNED GEAR HUNT · DRAG TO MOVE');heading:SetTextColor(unpack(V.colors.amber))
  tracker.icon=tracker:CreateTexture(nil,'ARTWORK');tracker.icon:SetSize(28,28);tracker.icon:SetPoint('TOPLEFT',12,-33);tracker.iconBorder=V.Rectangle(tracker,10,31,32,32,V.colors.amber,'BORDER')
  trackerTitle=text(tracker,48,-31,270,14);trackerSource=text(tracker,48,-55,270,11);trackerSource:SetHeight(30);trackerSource:SetWordWrap(true)
  button(tracker,12,-90,145,'Open hunt',function() local selected=G.Settings().tracked;if selected then ForeverCompanionGearFinderWorkspace.Open(tonumber(selected)) end end)
  button(tracker,170,-90,148,'Hide tracker',function() G.Settings().trackerHidden=true;tracker:Hide() end)
 end
 local _,_,quality=G.Call((C_Item or {}).GetItemInfo,entry.record.itemID)
 tracker.icon:SetTexture(ForeverCompanionLoot.ItemIcon(entry.record));V.Tint(tracker.iconBorder,V.Quality(quality));trackerTitle:SetTextColor(unpack(V.Quality(quality)))
 trackerTitle:SetText(entry.record.item);local target=G.SavedSource(entry.record.itemID) or entry.record;trackerSource:SetText(target.dungeon..'\n'..target.boss);tracker:Show()
end
function H.Notify(acquired)
 if #acquired==0 then return end
 if not toast then
  toast=CreateFrame('Frame','ForeverCompanionGearAcquiredToast',UIParent);H.toast=toast
  toast:SetSize(390,113);toast:SetPoint('TOP',UIParent,'TOP',0,-120);toast:SetFrameStrata('DIALOG');V.Compact(toast,390,113,'completed')
  ForeverCompanionInterface.PreparePanel(toast,'ForeverCompanionGearAcquiredToast',390,113)
  local heading=text(toast,14,-7,350,13);heading:SetText('GEAR HUNT ACQUIRED');heading:SetTextColor(unpack(V.colors.green))
  toast.icon=toast:CreateTexture(nil,'ARTWORK');toast.icon:SetSize(30,30);toast.icon:SetPoint('TOPLEFT',14,-36)
  toastText=text(toast,58,-36,318,12);toastText:SetHeight(30);toastText:SetWordWrap(true)
  local open=button(toast,14,-77,174,'View acquired gear',function() toast:Hide();local W=ForeverCompanionGearFinderWorkspace;W.view='completed';G.Settings().slot=0;G.Settings().dungeon='';W.selected=toastID;W.page=1;if W.search then W.search:SetText('') end;W.Open() end);V.Style(open,'completed',true)
  local dismiss=button(toast,202,-77,174,'Dismiss',function() toast:Hide() end);V.Style(dismiss,'completed',false)
 end
 toast.icon:SetTexture(ForeverCompanionLoot.ItemIcon(acquired[1]));toast:SetAlpha(1)
 toastID=acquired[1].itemID;toastText:SetText(acquired[1].item..(#acquired>1 and (' and '..(#acquired-1)..' more saved hunts') or '')..'\nObserved in your carried inventory / equipment.')
 local elapsed=0;toast:SetScript('OnUpdate',function(self,dt) elapsed=elapsed+dt;if elapsed>=8 then self:Hide();self:SetAlpha(1);self:SetScript('OnUpdate',nil) elseif elapsed>7.5 then self:SetAlpha((8-elapsed)/.5) end end);toast:Show()
end
function H.InstallHooks()
 if ForeverCompanionGearTooltips then ForeverCompanionGearTooltips.Install() end
 local names={'Head','Neck','Shoulder','Chest','Waist','Legs','Feet','Wrist','Hands','Finger0','Finger1','Trinket0','Trinket1','Back','MainHand','SecondaryHand','Ranged'}
 for i,name in ipairs(names) do
  local index=i;local frame=_G['Character'..name..'Slot']
  if frame and frame.HookScript and not hooks[frame] then
   hooks[frame]=true
   frame:HookScript('OnMouseUp',function(_,key)
    if key=='RightButton' and type(IsAltKeyDown)=='function' and IsAltKeyDown() then
     G.Settings().slot=index;local W=ForeverCompanionGearFinderWorkspace;W.view='discover';W.page=1;W.selected=nil;W.Open()
    end
   end)
  end
 end
end
local events=CreateFrame('Frame');H.events=events
local pending,inventory,silent,initialized,elapsed=false,false,true,false,0
for _,event in ipairs({'PLAYER_ENTERING_WORLD','BAG_UPDATE_DELAYED','PLAYER_EQUIPMENT_CHANGED','PLAYER_LEVEL_UP','GET_ITEM_INFO_RECEIVED','ITEM_DATA_LOAD_RESULT','UNIT_INVENTORY_CHANGED','SKILL_LINES_CHANGED','SPELLS_CHANGED','UPDATE_FACTION','ADDON_LOADED'}) do pcall(events.RegisterEvent,events,event) end
local function flush(_,dt)
 elapsed=elapsed+dt;if elapsed<.04 then return end
 events:SetScript('OnUpdate',nil);elapsed=0;pending=false
 if inventory then local acquired=G.ObserveHunts();if initialized and not silent then H.Notify(acquired) end;initialized=true;inventory=false;H.Refresh() end
 silent=false
 if ForeverCompanionGearTooltips then ForeverCompanionGearTooltips.Refresh() end
 local W=ForeverCompanionGearFinderWorkspace;if W and W.root and W.root:IsShown() then W.QueueRefresh() end
end
events:SetScript('OnEvent',function(_,event,itemID)
 if event=='ADDON_LOADED' then H.InstallHooks();return end
 if event=='UNIT_INVENTORY_CHANGED' and itemID~='player' then return end
 if event=='GET_ITEM_INFO_RECEIVED' or event=='ITEM_DATA_LOAD_RESULT' then if not G.interested[itemID] then return end
 elseif event=='PLAYER_ENTERING_WORLD' then inventory=true;silent=true;initialized=false;H.InstallHooks()
 elseif event=='BAG_UPDATE_DELAYED' or event=='PLAYER_EQUIPMENT_CHANGED' or event=='UNIT_INVENTORY_CHANGED' then inventory=true end
 G.Invalidate()
 if not pending then pending=true;elapsed=0;events:SetScript('OnUpdate',flush) end
end)
