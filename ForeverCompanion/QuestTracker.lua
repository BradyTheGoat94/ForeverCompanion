-- Optional addon-owned quest tracker. Never changes Blizzard's watched quests.
local T={page=1}
local filterButton,readyLabel,groupButton
local readySeen={}
local readyInitialized=false
ForeverCompanionQuestTracker=T
local root,heading,rows,footer,previous,nextPage,collapse,openQuest,openDiscover,empty,findQuests,recommend,searchBox,clearSearch,guideButton
local function settings()
 ForeverCompanionDB=ForeverCompanionDB or {}
 if type(ForeverCompanionDB.questTracker)~='table' then ForeverCompanionDB.questTracker={} end
 return ForeverCompanionDB.questTracker
end
local function read(fn,...)
 if type(fn)~='function' then return end
 local ok,a=pcall(fn,...);if ok then return a end
end
local function finite(v) return not (issecretvalue and issecretvalue(v)) and type(v)=='number' and v==v and math.abs(v)<math.huge end
local function safeText(v) return (not (issecretvalue and issecretvalue(v)) and type(v)=='string') and v or '' end
local function sameQuest(a,b)
 if type(a)~='table' or type(b)~='table' then return false end
 if a.id and b.id then return a.id==b.id end
 return not a.id and not b.id and a.title==b.title and a.zone==b.zone
end
local function recommended(items)
 -- Turn-ins, then pinned quests, then quests in the current zone; never claim optimal routing.
 for _,item in ipairs(items) do if item.quest.complete then return item end end
 for _,item in ipairs(items) do if item.pinned and item.localZone then return item end end
 for _,item in ipairs(items) do if item.localZone then return item end end
 return items[1]
end
local function safeLive(planner)
 if not planner or type(planner.GetLive)~='function' then return {} end
 local ok,result=pcall(planner.GetLive)
 return ok and type(result)=='table' and result or {}
end
local function isSupported(planner)
 if not planner or type(planner.IsSupported)~='function' then return false end
 local ok,result=pcall(planner.IsSupported)
 return ok and result==true
end
local function pinLookup(planner)
 if not planner or type(planner.IsPinned)~='function' then return nil end
 return function(q)
  local ok,result=pcall(planner.IsPinned,q)
  return ok and result==true
 end
end
local function navigate(quest)
 local route=ForeverCompanionObjectiveRoute
 if not route or type(route.NavigateNext)~='function' then return 'Directions unavailable. Open the quest guide.' end
 local ok,message=pcall(route.NavigateNext,quest)
 return ok and (message or 'Check your world map for the selected objective.') or 'Directions unavailable. Open the quest guide.'
end
local function showOnMap(quest)
 local waypoints=ForeverCompanionQuestWaypoints
 if not waypoints or type(waypoints.Show)~='function' then return 'Map location unavailable for this quest.' end
 local ok,message=pcall(waypoints.Show,quest)
 return ok and (message or 'Check the world map for available quest information.') or 'Map location unavailable for this quest.'
end
function T.Search(items,query)
 local term=type(query)=='string' and query:lower():match('^%s*(.-)%s*$') or ''
 if term=='' then return items end
 local result={}
 for _,item in ipairs(items or {}) do
  local q=type(item)=='table' and type(item.quest)=='table' and item.quest or {}
  local objectives={}
  for _,objective in ipairs(type(q.objectives)=='table' and q.objectives or {}) do objectives[#objectives+1]=safeText(objective) end
  local haystack=table.concat({safeText(q.title),safeText(q.zone),tostring(q.id or ''),table.concat(objectives,' ')},' '):lower()
  if haystack:find(term,1,true) then result[#result+1]=item end
 end
 return result
end
function T.Order(quests,mode,zone,pinned)
 local result={}
 for i,q in ipairs(quests or {}) do
  if type(q)=='table' then
  local pin=type(pinned)=='function' and pinned(q)==true
  if (mode~='pinned' and mode~='ready' and mode~='zone') or (mode=='pinned' and pin) or (mode=='ready' and q.complete) or (mode=='zone' and q.zoneKnown and type(zone)=='string' and zone~='' and q.zone==zone) then
   result[#result+1]={quest=q,index=i,pinned=pin,localZone=q.zoneKnown and type(zone)=='string' and zone~='' and q.zone==zone}
  end
  end
 end
 table.sort(result,function(a,b)
  if a.pinned~=b.pinned then return a.pinned end
  local ar,br=a.quest.complete==true,b.quest.complete==true
  if ar~=br then return ar end
  if not not a.localZone~=not not b.localZone then return a.localZone==true end
  return a.index<b.index
 end)
 return result
end
function T.Preview(q)
 if type(q)~='table' then return 'Open the quest log to see your objectives.' end
 if q.complete then return 'All objectives done. Return to the quest giver; check your quest log for the location.' end
 local lines={}
 for i,text in ipairs(type(q.objectives)=='table' and q.objectives or {}) do
  local states=type(q.objectiveStates)=='table' and q.objectiveStates or {}
  local state=states[i];state=type(state)=='table' and state or nil
  if not state or not state.known or not state.done then
   local objective=safeText(text)
   if objective~='' then lines[#lines+1]=objective;break end
  end
 end
 return #lines>0 and ('NEXT: '..table.concat(lines,'\n')) or 'Open the quest log to review your next objective.'
end
-- Observe only successful live scans. No chat spam, sound or automatic quest action.
function T.ObserveReady(quests,supported)
 if not supported then return end
 local nextSeen,new={},{}
 for _,q in ipairs(quests or {}) do
  if type(q)=='table' and q.id then
   nextSeen[q.id]=q.complete==true
   if readyInitialized and q.complete==true and readySeen[q.id]==false then new[#new+1]=q.title or 'Quest' end
  end
 end
 readySeen=nextSeen;readyInitialized=true
 if #new>0 then T.readyNotice=#new==1 and (new[1]..' is ready to turn in') or (#new..' quests are ready to turn in') end
 return new
end
function T.ApplyScale()
 if not root then return end
 local scale=settings().scale
 root.fcScaleBase=finite(scale) and scale or 1;root.fcApplyScale=T.ApplyScale
 scale=(finite(scale) and math.max(.85,math.min(1.3,scale)) or 1)*ForeverCompanionInterface.SizePreference(root)
 if UIParent and UIParent.GetWidth and UIParent.GetHeight then
  local ok,w,h=pcall(function() return UIParent:GetWidth(),UIParent:GetHeight() end)
  if not ok then w,h=nil,nil end
  if finite(w) and finite(h) and w>32 and h>32 then scale=math.min(scale,(w-24)/380,(h-24)/root:GetHeight()) end
 end
 root:SetScale(scale)
end
local function filterMenu(anchor)
 local cfg=settings();local entries={}
 for _,v in ipairs({{'all','All active quests'},{'zone','In my zone'},{'pinned','Pinned quests'},{'ready','Ready to turn in'}}) do
  local key,name=v[1],v[2]
  entries[#entries+1]={label=name,selected=(cfg.mode or 'all')==key,action=function() cfg.mode=key;T.page=1;T.Refresh() end}
 end
 ForeverCompanionInterface.Menu(anchor,'SHOW QUESTS',entries)
end
local function label(parent,x,y,width,size)
 local f=ForeverCompanionInterface.Text(parent,size or 11);f:SetPoint('TOPLEFT',parent,'TOPLEFT',x,y);f:SetWidth(width);return f
end
local function open(item)
 if not item then return end
 local planner=ForeverCompanionQuestPlanner
 local live=safeLive(planner)
 -- Resolve current identity rather than navigating a stale ranking index.
 for index,q in ipairs(live) do
  if sameQuest(q,item.quest) then
   if openQuest then openQuest(q,index) end
   return
  end
 end
 T.Refresh()
end
function T.Configure(callback,discover) openQuest=callback;openDiscover=discover end
local function create()
 local U=ForeverCompanionInterface
 root=CreateFrame('Frame','ForeverCompanionQuestTrackerFrame',UIParent);root:SetSize(380,540);root:SetPoint('RIGHT',UIParent,'RIGHT',-35,0)
 U.Surface(root);U.WindowControls(root,'ForeverCompanionQuestTrackerFrame',380,540);root:SetClampedToScreen(true);root:SetMovable(true);root:EnableMouse(true)
 local db=settings()
 if type(db.position)=='table' and finite(db.position.x) and finite(db.position.y) then root:ClearAllPoints();root:SetPoint('CENTER',UIParent,'CENTER',db.position.x,db.position.y) end
 heading=label(root,12,-8,264,13)
 local drag=CreateFrame('Frame',nil,root);drag:SetPoint('TOPLEFT',0,0);drag:SetSize(278,27);drag:EnableMouse(true);drag:RegisterForDrag('LeftButton')
 drag:SetScript('OnDragStart',function() if not settings().locked then root:StartMoving() end end)
 drag:SetScript('OnDragStop',function()
  root:StopMovingOrSizing()
  if root.GetCenter and UIParent.GetCenter then
   local x,y=root:GetCenter();local px,py=UIParent:GetCenter()
   local fs=root.GetEffectiveScale and root:GetEffectiveScale();local ps=UIParent.GetEffectiveScale and UIParent:GetEffectiveScale()
   if finite(fs) and fs>0 and finite(ps) and ps>0 then px,py=px*ps/fs,py*ps/fs end
   if finite(x) and finite(y) and finite(px) and finite(py) then settings().position={x=x-px,y=y-py} end
  end
 end)
 collapse=U.Button(root);collapse:SetSize(24,22);collapse:SetPoint('TOPRIGHT',-63,-3)
 collapse:SetScript('OnClick',function() settings().collapsed=not settings().collapsed;T.Refresh() end)
 local options=U.Button(root);options:SetSize(28,22);options:SetPoint('TOPRIGHT',-32,-3);options:SetText('...')
 options:SetScript('OnClick',function()
  local cfg=settings()
  U.PagedMenu(options,'QUEST TRACKER',{
   {label=cfg.grouped and 'Use flat quest list' or 'Group quests by zone',action=function() cfg.grouped=not cfg.grouped;T.page=1;T.Refresh() end},
   {label='Clear focused-quest filter',enabled=cfg.focusOnly==true,action=function() cfg.focusOnly=false;T.page=1;T.Refresh() end},
   {label='Expand every zone',action=function() if ForeverCompanionQuestJourney then ForeverCompanionQuestJourney.Settings().collapsedZones={} end;T.page=1;T.Refresh() end},
   {label='All active quests',selected=cfg.mode==nil or cfg.mode=='all',action=function() cfg.mode='all';T.page=1;T.Refresh() end},
   {label='Pinned quests only',selected=cfg.mode=='pinned',action=function() cfg.mode='pinned';T.page=1;T.Refresh() end},
   {label='Ready to turn in',selected=cfg.mode=='ready',action=function() cfg.mode='ready';T.page=1;T.Refresh() end},
   {label='Quests in my zone',selected=cfg.mode=='zone',action=function() cfg.mode='zone';T.page=1;T.Refresh() end},
   {label='Compact: two quests',selected=cfg.compact==true,action=function() cfg.compact=true;T.page=1;T.Refresh() end},
   {label='Standard: four quests',selected=cfg.compact~=true,action=function() cfg.compact=false;T.page=1;T.Refresh() end},
   {label='Text and interface: 100%',selected=(cfg.scale or 1)==1,action=function() cfg.scale=1;T.ApplyScale() end},
   {label='Text and interface: 115%',selected=cfg.scale==1.15,action=function() cfg.scale=1.15;T.ApplyScale() end},
   {label='Text and interface: 130%',selected=cfg.scale==1.3,action=function() cfg.scale=1.3;T.ApplyScale() end},
   {label=cfg.locked and 'Unlock tracker' or 'Lock tracker',selected=cfg.locked==true,action=function() cfg.locked=not cfg.locked end},
   {label='Reset tracker position',action=function() cfg.position=nil;root:ClearAllPoints();root:SetPoint('RIGHT',UIParent,'RIGHT',-35,0) end},
   {label='Stop current directions',enabled=ForeverCompanionQuestWaypoints.HasNavigation(),action=function() ForeverCompanionQuestWaypoints.Clear();T.Refresh() end},
   {label='Dismiss navigation message',enabled=ForeverCompanionQuestWaypoints.LastNotice()~=nil,action=function() ForeverCompanionQuestWaypoints.DismissNotice();T.Refresh() end},
   {label='Minimap mailboxes',selected=ForeverCompanionQuestMinimap.MailEnabled(),action=function() local m=ForeverCompanionQuestMinimap;m.SetMailEnabled(not m.MailEnabled()) end},
   {label='Minimap quest markers',selected=not ForeverCompanionDB.questMinimap or ForeverCompanionDB.questMinimap.enabled~=false,action=function() if ForeverCompanionQuestMinimap then ForeverCompanionQuestMinimap.SetEnabled(not ForeverCompanionQuestMinimap.IsEnabled()) end end},
   {label='Quest history',action=function() if ForeverCompanionOpenQuestBook then ForeverCompanionOpenQuestBook('history') end end},
   {label='Zone quest catalog',action=function() if ForeverCompanionOpenQuestBook then ForeverCompanionOpenQuestBook('catalog') end end},
   {label='Hide tracker',action=T.Hide},
  })
 end)
 groupButton=U.Button(root);groupButton:SetSize(48,20);groupButton:SetPoint('TOPRIGHT',-12,-66);groupButton:SetText('Zones');groupButton:SetScript('OnClick',function() settings().grouped=not settings().grouped;T.page=1;T.Refresh() end)
 local close=U.Button(root);close:SetSize(24,22);close:SetPoint('TOPRIGHT',-5,-3);close:SetText('x');close:SetScript('OnClick',T.Hide)
 searchBox=U.EditBox(root,'Search quests, objectives or ID')
 searchBox:SetSize(220,26);searchBox:SetPoint('TOPLEFT',12,-35);searchBox:SetMaxLetters(70)
 searchBox:SetScript('OnTextChanged',function() T.page=1;T.Refresh() end)
 searchBox:SetScript('OnEscapePressed',function(self) self:ClearFocus() end)
 searchBox:SetScript('OnEnterPressed',function(self) self:ClearFocus() end)
 filterButton=U.Button(root);filterButton:SetSize(128,26);filterButton:SetPoint('TOPRIGHT',-12,-35)
 filterButton:SetScript('OnClick',function(self) filterMenu(self) end)
 clearSearch=U.Button(root);clearSearch:SetSize(48,20);clearSearch:SetPoint('TOPRIGHT',-64,-66);clearSearch:SetText('Clear')
 clearSearch:SetScript('OnClick',function() searchBox:SetText('');searchBox:ClearFocus();T.page=1;T.Refresh() end)
 readyLabel=U.Button(root);readyLabel:SetPoint('TOPLEFT',12,-66);readyLabel:SetSize(244,20)
 readyLabel:SetScript('OnClick',function() settings().mode='ready';T.readyNotice=nil;T.page=1;T.Refresh() end)

 rows={}
 for i=1,4 do
  local row=CreateFrame('Button',nil,root);row:SetPoint('TOPLEFT',12,-94-(i-1)*119);row:SetSize(356,113);row.bg=U.Surface(row)
  row.title=label(row,10,-7,242,13);row.title:SetWordWrap(true);row.title:SetHeight(32)
  row.tag=label(row,10,-43,330,10)
  row.preview=label(row,10,-60,332,11);row.preview:SetWordWrap(true);row.preview:SetHeight(30)
  row.meta=label(row,10,-94,332,10)
  row.progressBg=row:CreateTexture(nil,'ARTWORK');row.progressBg:SetColorTexture(.15,.18,.23,.95);row.progressBg:SetPoint('BOTTOMLEFT',10,3);row.progressBg:SetSize(336,3)
  row.progress=row:CreateTexture(nil,'OVERLAY');row.progress:SetColorTexture(.29,.72,.88,1);row.progress:SetPoint('LEFT',row.progressBg,'LEFT',0,0);row.progress:SetSize(1,3)
  row.map=U.Button(row);row.map:SetSize(88,24);row.map:SetPoint('TOPRIGHT',-5,-3);row.map:SetText('Map')
  row.map:SetScript('OnClick',function()
   if not row.item then return end
   if not isSupported(ForeverCompanionQuestPlanner) or not row.actionable then open(row.item);return end
   local route=ForeverCompanionObjectiveRoute
   if route and type(route.NavigateNext)=='function' then footer:SetText(navigate(row.item.quest))
   else open(row.item) end
  end)
  row.map:SetText('Guide')
  row.pin=U.Button(row);row.pin:SetSize(88,20);row.pin:SetPoint('TOPRIGHT',-5,-30)
  row.pin:SetScript('OnClick',function()
   if not row.item then return end
   local planner=ForeverCompanionQuestPlanner
   if not isSupported(planner) then return end
   for index,q in ipairs(safeLive(planner)) do if sameQuest(q,row.item.quest) then planner.TogglePin(index);break end end
   T.Refresh()
  end)

  row:RegisterForClicks('LeftButtonUp','RightButtonUp')
  row:SetScript('OnClick',function(self,button)
   if self.zoneGroup then local j=ForeverCompanionQuestJourney;local c=j.Settings().collapsedZones;c[self.zoneGroup.zone]=not c[self.zoneGroup.zone];T.Refresh();return end
   if not self.item then return end
   if button=='RightButton' then
    local item=self.item
    U.Menu(self,'QUEST ACTIONS',{
     {label='Go to next matched objective',action=function() footer:SetText(navigate(item.quest)) end},
     {label='Show quest on map',action=function() footer:SetText(showOnMap(item.quest)) end},
     {label='Open field guide',action=function() open(item) end},
     {label='Quest intelligence / location audit',action=function() if ForeverCompanionQuestJourney then ForeverCompanionQuestJourney.Show(item.quest) end end},
     {label='Focus only this quest',action=function() if ForeverCompanionQuestJourney and ForeverCompanionQuestJourney.Focus(item.quest) then settings().focusOnly=true;T.page=1;T.Refresh() end end},
     {label='Review quest reward equipment',action=function() if ForeverCompanionQuestRewards then ForeverCompanionQuestRewards.Open(item.quest) end end},
     {label='Add to leveling plan',enabled=isSupported(ForeverCompanionQuestPlanner),action=function()
      local _,message=ForeverCompanionLevelingPlan.Add(item.quest);footer:SetText(message)
      ForeverCompanionLevelingWorkspace.Refresh()
     end},
     {label='Open saved leveling plan',action=function() ForeverCompanionLevelingWorkspace.Open('saved') end},
     {label='Quest item sources',enabled=(isSupported(ForeverCompanionQuestPlanner) and ForeverCompanionQuestSupplies and #ForeverCompanionQuestSupplies.ItemsForQuest(item.quest)>0)==true,action=function() footer:SetText(ForeverCompanionQuestSupplies.Open(self,item.quest.id,item.quest.title,function(result) footer:SetText(result) end)) end},
     {label=item.pinned and 'Unpin quest' or 'Pin quest',action=function()
      local planner=ForeverCompanionQuestPlanner
      for index,q in ipairs(safeLive(planner)) do
       if sameQuest(q,item.quest) then if type(planner.TogglePin)=='function' then planner.TogglePin(index) end;break end
      end
      T.Refresh()
     end},
    })
   else open(self.item) end
  end)
  row:SetScript('OnEnter',function(self)
   self.bg:SetColorTexture(.075,.09,.115,1)
   if GameTooltip and self.item then
    GameTooltip:SetOwner(self,'ANCHOR_LEFT');GameTooltip:SetText(safeText(self.item.quest.title)~='' and self.item.quest.title or 'Quest')
    local states=type(self.item.quest.objectiveStates)=='table' and self.item.quest.objectiveStates or {}
    for idx,line in ipairs(type(self.item.quest.objectives)=='table' and self.item.quest.objectives or {}) do
     if type(line)=='string' then
      local state=states[idx]
      local prefix=type(state)=='table' and state.known and (state.done and '[Done] ' or '[To do] ') or '[Objective] '
      GameTooltip:AddLine(prefix..line,.85,.9,.94,true)
     end
    end
    GameTooltip:AddLine('Click: quest details. Right-click: pin or map. Directions appear only when location data is available.',.8,.72,.5,true);GameTooltip:Show()
   end
  end)
  row:SetScript('OnLeave',function(self) if ForeverCompanionVisualTheme and type(ForeverCompanionVisualTheme.SelectRow)=='function' then ForeverCompanionVisualTheme.SelectRow(self,self.bg,self.selected) end;if GameTooltip then GameTooltip:Hide() end end)
  rows[i]=row
 end
 empty=label(root,16,-100,344,12);empty:SetHeight(43);empty:SetWordWrap(true)
 empty:SetText('No quests match. Clear your search or choose All active quests from the menu.')
 findQuests=U.Button(root);findQuests:SetSize(140,24);findQuests:SetPoint('TOPLEFT',16,-150);findQuests:SetText('Find quests')
 findQuests:SetScript('OnClick',function() if openDiscover then openDiscover() end end)
 footer=label(root,12,-413,354,10);footer:SetWordWrap(true);footer:SetHeight(30)
 guideButton=U.Button(root);guideButton:SetSize(58,20);guideButton:SetPoint('BOTTOMLEFT',12,7);guideButton:SetText('Help')
 guideButton:SetScript('OnClick',function()
  local U=ForeverCompanionInterface
  U.Menu(guideButton,'QUEST TRACKER HELP',{
   {label='1. Select a quest to see its objectives',action=function() end},
   {label='2. Use Directions only for known locations',action=function() end},
   {label='3. Right-click to pin or view a quest on the map',action=function() end},
   {label='4. Search by quest name, zone or objective',action=function() if searchBox then searchBox:SetFocus() end end},
   {label='5. Filters and compact mode are in the ... menu',action=function() end},
   {label='Open quest catalog',action=function() if openDiscover then openDiscover() end end},
  })
 end)
 recommend=U.Button(root);recommend:SetSize(82,20);recommend:SetPoint('BOTTOMLEFT',78,7);recommend:SetText('Pick quest')
 recommend:SetScript('OnClick',function()
  local cfg=settings();cfg.mode='all';searchBox:SetText('');T.page=1;T.Refresh()
  local planner=ForeverCompanionQuestPlanner
  if not planner or type(planner.GetLive)~='function' then return end
  local live=safeLive(planner)
  local ordered=T.Order(live,'all',read(GetRealZoneText) or read(GetZoneText),pinLookup(planner))
  local pick=recommended(ordered)
  if isSupported(planner) and ForeverCompanionQuestJourney then
   local map=C_Map and read(C_Map.GetBestMapForUnit,'player');local pos=map and C_Map and read(C_Map.GetPlayerMapPosition,map,'player');local x,y
   if pos and pos.GetXY then local ok,a,b=pcall(pos.GetXY,pos);if ok then x,y=a,b end end
   pick=ForeverCompanionQuestJourney.Recommend(live,ForeverCompanionQuestWaypoints.Targets,map,x,y,pinLookup(planner)) or pick
  end
  if pick then open(pick) else footer:SetText('No active quest to suggest. Open your quest log or find quests.') end
 end)
 previous=U.Button(root);previous:SetSize(23,21);previous:SetPoint('BOTTOMRIGHT',-35,4);previous:SetText('<')
 nextPage=U.Button(root);nextPage:SetSize(23,21);nextPage:SetPoint('BOTTOMRIGHT',-9,4);nextPage:SetText('>')
 previous:SetScript('OnClick',function() T.page=math.max(1,T.page-1);T.Refresh() end)
 nextPage:SetScript('OnClick',function() T.page=T.page+1;T.Refresh() end)
 root:EnableMouseWheel(true);root:SetScript('OnMouseWheel',function(_,delta) T.page=math.max(1,T.page+(delta<0 and 1 or -1));T.Refresh() end)
 root:RegisterEvent('UI_SCALE_CHANGED');root:RegisterEvent('DISPLAY_SIZE_CHANGED')
 root:SetScript('OnEvent',T.ApplyScale)
 root:Hide()
end
function T.IsShown() return settings().visible==true end
function T.Refresh()
 local planner=ForeverCompanionQuestPlanner
 local live=safeLive(planner);T.ObserveReady(live,isSupported(planner))
 if ForeverCompanionQuestJourney then ForeverCompanionQuestJourney.Observe(live,isSupported(planner)) end
 if not root or not root:IsShown() then return end
 local cfg=settings();local ordered=T.Order(live,cfg.mode,read(GetRealZoneText) or read(GetZoneText),pinLookup(planner))
 ordered=T.Search(ordered,searchBox and searchBox:GetText() or '')
 local matching=#ordered
 local journey=ForeverCompanionQuestJourney
 local selectedQuest=read(planner and planner.GetSelected)
 local selectedKey=selectedQuest and tostring(selectedQuest.id)..':'..tostring(selectedQuest.title)
 local follow=cfg.followSelection~=false and isSupported(planner) and selectedKey~=T.lastFocus and (searchBox:GetText() or '')=='' and (cfg.mode==nil or cfg.mode=='all')
 T.lastFocus=selectedKey
 if follow and journey and cfg.grouped then journey.Settings().collapsedZones[journey.Zone(selectedQuest)]=nil end
 if cfg.focusOnly and journey and isSupported(planner) then
  local focus=journey.Settings().focus;local found=false
  for _,q in ipairs(live) do if focus and q.id==focus.id and q.title==focus.title then found=true;break end end
  if not found then cfg.focusOnly=false;T.page=1;T.focusNotice='Focused quest left your log; focused filter cleared.' else T.focusNotice=nil end
 end
 if cfg.focusOnly and journey then local focus=journey.Settings().focus;local filtered={};for _,item in ipairs(ordered) do if focus and item.quest.id==focus.id and item.quest.title==focus.title then filtered[#filtered+1]=item end end;ordered=filtered;matching=#ordered end
 if cfg.grouped and journey then ordered=journey.Group(ordered,journey.Settings().collapsedZones) end
 local count=cfg.compact and 2 or 4;local pages=math.max(1,math.ceil(#ordered/count))
 if follow then for i,item in ipairs(ordered) do if item.quest and sameQuest(item.quest,selectedQuest) then T.page=math.floor((i-1)/count)+1;break end end end
 T.page=math.max(1,math.min(T.page,pages))
 root:SetHeight(cfg.collapsed and 30 or (#ordered==0 and 240 or (154+math.min(count,#ordered)*119)))
 groupButton:SetShown(not cfg.collapsed);searchBox:SetShown(not cfg.collapsed);clearSearch:SetShown(not cfg.collapsed and searchBox:GetText()~='');filterButton:SetShown(not cfg.collapsed);readyLabel:SetShown(not cfg.collapsed);collapse:SetText(cfg.collapsed and '+' or '-')
 T.ApplyScale()
 local ready=0;for _,q in ipairs(live) do if q.complete then ready=ready+1 end end
 readyLabel:SetEnabled(ready>0)
 readyLabel:SetText(ready>0 and ((T.readyNotice and 'New: ' or '')..ready..' ready to turn in · View') or (T.focusNotice or journey and journey.notice or 'Select a quest to see your next step'))
 if ready==0 then T.readyNotice=nil end
 filterButton:SetText(({all='All quests',zone='My zone',pinned='Pinned',ready='Ready to turn in'})[cfg.mode or 'all'] or 'All quests')
 heading:SetText('MY QUESTS  ·  '..#live..' active'..(not isSupported(planner) and ' · cached' or ''))
 local focused=read(planner and planner.GetSelected)
 empty:SetShown(not cfg.collapsed and #ordered==0);findQuests:SetShown(not cfg.collapsed and #ordered==0)
 if #ordered==0 then
  local query=searchBox and searchBox:GetText() or ''
  if #live==0 then empty:SetText('No active quests detected. Open your quest log or browse available quests.')
  elseif cfg.focusOnly then empty:SetText('Your focused quest is hidden by these filters. Clear the focused-quest filter in options or choose All quests.')
  elseif query~='' then empty:SetText('No matching quests. Try another search or press Clear.')
  else empty:SetText('No quests in this filter. Choose All quests above to see your active quests.') end
 end
 for i,row in ipairs(rows) do
  local item=i<=count and ordered[(T.page-1)*count+i]
  row.item=item;row:SetShown(not cfg.collapsed and item~=nil)
  row.zoneGroup=item and item.zoneHeader and item or nil
  if item and item.zoneHeader then
   row.item=nil;row:SetHeight(30);row.title:SetHeight(20);row.title:SetWidth(330)
   row.title:SetText((item.collapsed and '+ ' or '- ')..item.zone..' ('..item.count..', '..item.ready..' ready)');row.title:SetTextColor(.94,.75,.38)
   for _,widget in ipairs({row.tag,row.preview,row.meta,row.map,row.pin,row.progress,row.progressBg}) do widget:Hide() end
  elseif item then
   row:SetHeight(113);row.title:SetHeight(32);row.title:SetWidth(242)
   for _,widget in ipairs({row.tag,row.preview,row.meta,row.map,row.pin}) do widget:Show() end
   row.title:SetText((item.quest.level and ('['..item.quest.level..'] ') or '')..(safeText(item.quest.title)~='' and item.quest.title or 'Unnamed quest'))
   row.pin:SetText(item.pinned and 'Unpin' or 'Pin quest');row.pin:SetEnabled(isSupported(planner))
   local active=ForeverCompanionQuestWaypoints.Active and ForeverCompanionQuestWaypoints.Active()
   row.tag:SetText((active and active.questID==item.quest.id and 'NAVIGATING  ·  ' or '')..(item.quest.complete and 'READY TO TURN IN' or (sameQuest(focused,item.quest) and 'SELECTED' or 'ACTIVE'))..(item.pinned and '  ·  PINNED' or '')..(item.localZone and '  ·  MY ZONE' or ''))
   row.tag:SetTextColor(item.quest.complete and .36 or (item.pinned and .97 or .66),item.quest.complete and .83 or (item.pinned and .78 or .71),item.quest.complete and .52 or .90)
   row.preview:SetText(T.Preview(item.quest))
   local guide=ForeverCompanionQuestFieldGuide
   local done,total,known=0,0,0
   if guide and type(guide.Progress)=='function' then local ok,a,b,c=pcall(guide.Progress,item.quest);if ok then done,total,known=a,b,c end end
   done=finite(done) and done or 0;total=finite(total) and total or 0;known=finite(known) and known or 0
   local progressText=item.quest.complete and 'Complete' or (total==0 and 'Objectives unavailable' or (known==0 and 'Progress unavailable' or (done..'/'..total..' objectives')))
   local zone=safeText(item.quest.zone)
   if zone=='' then zone='Zone unknown' end
   row.meta:SetText(zone..'  ·  '..progressText)
   local ratio=guide and guide.ProgressFraction and guide.ProgressFraction(item.quest)
   local hasProgress=ratio~=nil
   ratio=ratio or 0
   if item.quest.complete then ratio=1 end
   row.progress:SetWidth(math.max(1,336*ratio))
   row.progress:SetShown(item.quest.complete or hasProgress)
   row.progressBg:SetShown(item.quest.complete or hasProgress)
   row.progress:SetColorTexture(item.quest.complete and .36 or .29,item.quest.complete and .83 or .72,item.quest.complete and .52 or .88,1)
   local actionable=false
   if isSupported(planner) and ForeverCompanionQuestWaypoints and type(ForeverCompanionQuestWaypoints.Targets)=='function' then
    local ok,targets=pcall(ForeverCompanionQuestWaypoints.Targets,item.quest)
    if ok and type(targets)=='table' then
     local steps={}
     if guide and type(guide.Steps)=='function' then local good,value=pcall(guide.Steps,item.quest,targets);if good and type(value)=='table' then steps=value end end
     for _,step in ipairs(steps) do
      if type(step)=='table' and not step.done and type(step.targets)=='table' and #step.targets>0 then
       local reviewed=false
       if guide and type(guide.NeedsReview)=='function' then local good,value=pcall(guide.NeedsReview,step);reviewed=not good or value==true end
       if not reviewed then
        local map=C_Map and read(C_Map.GetBestMapForUnit,'player')
        for _,t in ipairs(step.targets) do if t.map==map then actionable=true;break end end
        if actionable then break end
       end
      end
     end
    end
   end
   row.actionable=actionable
   row.map:SetText(actionable and 'Directions' or 'Guide')
   if actionable then row.map:SetAlpha(1) else row.map:SetAlpha(.88) end
   row.map:SetScript('OnEnter',function(self)
    if not GameTooltip then return end
    GameTooltip:SetOwner(self,'ANCHOR_RIGHT')
    GameTooltip:SetText(actionable and 'Quest directions' or 'Quest guide')
    GameTooltip:AddLine(actionable and 'A quest objective has a usable location. Confirm the destination on your map.' or 'No usable objective location is available. Open the guide to review the quest.',.85,.88,.93,true)
    GameTooltip:Show()
   end)
   row.map:SetScript('OnLeave',function() if GameTooltip then GameTooltip:Hide() end end)
   row.selected=sameQuest(focused,item.quest)
   if ForeverCompanionVisualTheme and type(ForeverCompanionVisualTheme.SelectRow)=='function' then ForeverCompanionVisualTheme.SelectRow(row,row.bg,row.selected) end
   row.title:SetTextColor(item.quest.complete and .48 or .94,item.quest.complete and .88 or .95,item.quest.complete and .58 or .97)
   row.map:SetEnabled(true)
  end
 end
 local cursor=94
 for _,row in ipairs(rows) do if row:IsShown() then row:ClearAllPoints();row:SetPoint('TOPLEFT',12,-cursor);cursor=cursor+row:GetHeight()+6 end end
 if not cfg.collapsed and #ordered>0 then root:SetHeight(cursor+60) end
 footer:ClearAllPoints();footer:SetPoint('BOTTOMLEFT',12,32);footer:SetShown(not cfg.collapsed)
 recommend:SetShown(not cfg.collapsed and #ordered>0);guideButton:SetShown(not cfg.collapsed)
 footer:SetText(not isSupported(planner) and 'Quest API unavailable · check game quest log' or (#ordered==0 and 'No matching quests' or ('Page '..T.page..'/'..pages..' · '..matching..' matching quests')))
 local navigationNotice=ForeverCompanionQuestWaypoints.LastNotice()
 if navigationNotice then footer:SetText(navigationNotice) end
 local footerHeight=math.max(30,math.min(72,footer:GetStringHeight()+4));footer:SetHeight(footerHeight)
 if not cfg.collapsed then root:SetHeight(root:GetHeight()+footerHeight-30);T.ApplyScale() end
 previous:SetShown(not cfg.collapsed);nextPage:SetShown(not cfg.collapsed)
 previous:SetEnabled(T.page>1);nextPage:SetEnabled(T.page<pages)
end
function T.Show()
 if not root then create() end
 settings().visible=true;root:Show();T.Refresh()
 if ForeverCompanionQuestBriefing and type(ForeverCompanionQuestBriefing.Render)=='function' then pcall(ForeverCompanionQuestBriefing.Render) end
end
function T.Hide()
 settings().visible=false;if root then root:Hide() end
 if ForeverCompanionQuestBriefing and type(ForeverCompanionQuestBriefing.Render)=='function' then pcall(ForeverCompanionQuestBriefing.Render) end
end
function T.Toggle() if T.IsShown() then T.Hide() else T.Show() end end
