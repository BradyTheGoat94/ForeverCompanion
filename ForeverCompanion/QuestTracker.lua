-- Optional addon-owned quest tracker. Never changes Blizzard's watched quests.
local T={page=1}
ForeverCompanionQuestTracker=T
local root,heading,rows,footer,previous,nextPage,collapse,openQuest,openDiscover,empty,findQuests
local function settings()
 ForeverCompanionDB=ForeverCompanionDB or {}
 if type(ForeverCompanionDB.questTracker)~='table' then ForeverCompanionDB.questTracker={} end
 return ForeverCompanionDB.questTracker
end
local function read(fn,...)
 if type(fn)~='function' then return end
 local ok,a=pcall(fn,...);if ok then return a end
end
local function finite(v) return type(v)=='number' and v==v and math.abs(v)<math.huge end
function T.Order(quests,mode,zone,pinned)
 local result={}
 for i,q in ipairs(quests or {}) do
  local pin=pinned and pinned(q)==true
  if mode~='pinned' and mode~='ready' or mode=='pinned' and pin or mode=='ready' and q.complete then
   result[#result+1]={quest=q,index=i,pinned=pin,localZone=q.zoneKnown and q.zone==zone}
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
 if q.complete then return 'Ready to turn in. Visit the quest giver.' end
 local lines={}
 for i,text in ipairs(q.objectives or {}) do
  local state=(q.objectiveStates or {})[i]
  if not state or not state.known or not state.done then lines[#lines+1]=text;if #lines==2 then break end end
 end
 return #lines>0 and table.concat(lines,'\n') or 'Check the quest log for the next step.'
end
local function label(parent,x,y,width,size)
 local f=ForeverCompanionInterface.Text(parent,size or 11);f:SetPoint('TOPLEFT',parent,'TOPLEFT',x,y);f:SetWidth(width);return f
end
local function open(item)
 if not item then return end
 local planner=ForeverCompanionQuestPlanner
 local live=planner.GetLive()
 -- Resolve current identity rather than navigating a stale ranking index.
 for index,q in ipairs(live) do
  if (q.id and q.id==item.quest.id) or (not q.id and q.title==item.quest.title and q.zone==item.quest.zone) then
   if openQuest then openQuest(q,index) end
   return
  end
 end
 T.Refresh()
end
function T.Configure(callback,discover) openQuest=callback;openDiscover=discover end
local function create()
 local U=ForeverCompanionInterface
 root=CreateFrame('Frame','ForeverCompanionQuestTrackerFrame',UIParent);root:SetSize(334,384);root:SetPoint('RIGHT',UIParent,'RIGHT',-35,0)
 U.Surface(root);root:SetClampedToScreen(true);root:SetMovable(true);root:EnableMouse(true)
 local db=settings()
 if type(db.position)=='table' and finite(db.position.x) and finite(db.position.y) then root:ClearAllPoints();root:SetPoint('CENTER',UIParent,'CENTER',db.position.x,db.position.y) end
 heading=label(root,10,-7,220,12)
 local drag=CreateFrame('Frame',nil,root);drag:SetPoint('TOPLEFT',0,0);drag:SetSize(234,27);drag:EnableMouse(true);drag:RegisterForDrag('LeftButton')
 drag:SetScript('OnDragStart',function() if not settings().locked then root:StartMoving() end end)
 drag:SetScript('OnDragStop',function()
  root:StopMovingOrSizing()
  if root.GetCenter and UIParent.GetCenter then
   local x,y=root:GetCenter();local px,py=UIParent:GetCenter()
   if finite(x) and finite(y) and finite(px) and finite(py) then settings().position={x=x-px,y=y-py} end
  end
 end)
 collapse=U.Button(root);collapse:SetSize(24,22);collapse:SetPoint('TOPRIGHT',-63,-3)
 collapse:SetScript('OnClick',function() settings().collapsed=not settings().collapsed;T.Refresh() end)
 local options=U.Button(root);options:SetSize(28,22);options:SetPoint('TOPRIGHT',-32,-3);options:SetText('...')
 options:SetScript('OnClick',function()
  local cfg=settings()
  U.Menu(options,'QUEST TRACKER',{
   {label='All active quests',selected=cfg.mode~='pinned' and cfg.mode~='ready',action=function() cfg.mode='all';T.page=1;T.Refresh() end},
   {label='Pinned quests only',selected=cfg.mode=='pinned',action=function() cfg.mode='pinned';T.page=1;T.Refresh() end},
   {label='Ready to turn in',selected=cfg.mode=='ready',action=function() cfg.mode='ready';T.page=1;T.Refresh() end},
   {label='Compact: two quests',selected=cfg.compact==true,action=function() cfg.compact=true;T.page=1;T.Refresh() end},
   {label='Standard: four quests',selected=cfg.compact~=true,action=function() cfg.compact=false;T.page=1;T.Refresh() end},
   {label=cfg.locked and 'Unlock tracker' or 'Lock tracker',selected=cfg.locked==true,action=function() cfg.locked=not cfg.locked end},
   {label='Reset tracker position',action=function() cfg.position=nil;root:ClearAllPoints();root:SetPoint('RIGHT',UIParent,'RIGHT',-35,0) end},
   {label='Hide tracker',action=T.Hide},
  })
 end)
 local close=U.Button(root);close:SetSize(24,22);close:SetPoint('TOPRIGHT',-5,-3);close:SetText('x');close:SetScript('OnClick',T.Hide)
 rows={}
 for i=1,4 do
  local row=CreateFrame('Button',nil,root);row:SetPoint('TOPLEFT',10,-33-(i-1)*82);row:SetSize(314,78);row.bg=U.Surface(row)
  row.title=label(row,7,-5,246,12)
  row.preview=label(row,7,-26,300,11);row.preview:SetWordWrap(true);row.preview:SetHeight(31)
  row.meta=label(row,7,-61,300,10)
  row.map=U.Button(row);row.map:SetSize(47,22);row.map:SetPoint('TOPRIGHT',-5,-3);row.map:SetText('Map')
  row.map:SetScript('OnClick',function() if row.item and ForeverCompanionQuestPlanner.IsSupported() then footer:SetText(ForeverCompanionQuestWaypoints.Show(row.item.quest)) end end)
  row:RegisterForClicks('LeftButtonUp','RightButtonUp')
  row:SetScript('OnClick',function(self,button)
   if not self.item then return end
   if button=='RightButton' then
    local item=self.item
    U.Menu(self,'QUEST ACTIONS',{
     {label='Open field guide',action=function() open(item) end},
     {label=item.pinned and 'Unpin quest' or 'Pin quest',action=function()
      local planner=ForeverCompanionQuestPlanner
      for index,q in ipairs(planner.GetLive()) do
       if (q.id and q.id==item.quest.id) or (not q.id and q.title==item.quest.title and q.zone==item.quest.zone) then planner.TogglePin(index);break end
      end
      T.Refresh()
     end},
    })
   else open(self.item) end
  end)
  row:SetScript('OnEnter',function(self)
   self.bg:SetColorTexture(.075,.09,.115,1)
   if GameTooltip and self.item then
    GameTooltip:SetOwner(self,'ANCHOR_LEFT');GameTooltip:SetText(self.item.quest.title)
    for _,line in ipairs(self.item.quest.objectives or {}) do GameTooltip:AddLine(line,.85,.9,.94,true) end
    GameTooltip:AddLine('Click: field guide. Right-click: pin and actions.',.8,.72,.5,true);GameTooltip:Show()
   end
  end)
  row:SetScript('OnLeave',function(self) ForeverCompanionVisualTheme.SelectRow(self,self.bg,self.selected);if GameTooltip then GameTooltip:Hide() end end)
  rows[i]=row
 end
 empty=label(root,16,-43,302,12);empty:SetHeight(43);empty:SetWordWrap(true)
 empty:SetText('No active quests in this view. Find a quest giver or change the tracker filter.')
 findQuests=U.Button(root);findQuests:SetSize(140,24);findQuests:SetPoint('TOPLEFT',16,-90);findQuests:SetText('Find quests')
 findQuests:SetScript('OnClick',function() if openDiscover then openDiscover() end end)
 footer=label(root,10,-365,252,10)
 previous=U.Button(root);previous:SetSize(23,21);previous:SetPoint('BOTTOMRIGHT',-35,4);previous:SetText('<')
 nextPage=U.Button(root);nextPage:SetSize(23,21);nextPage:SetPoint('BOTTOMRIGHT',-9,4);nextPage:SetText('>')
 previous:SetScript('OnClick',function() T.page=math.max(1,T.page-1);T.Refresh() end)
 nextPage:SetScript('OnClick',function() T.page=T.page+1;T.Refresh() end)
 root:EnableMouseWheel(true);root:SetScript('OnMouseWheel',function(_,delta) T.page=math.max(1,T.page+(delta<0 and 1 or -1));T.Refresh() end)
 root:Hide()
end
function T.IsShown() return settings().visible==true end
function T.Refresh()
 if not root or not root:IsShown() then return end
 local cfg=settings();local planner=ForeverCompanionQuestPlanner
 local live=planner.GetLive();local ordered=T.Order(live,cfg.mode,read(GetRealZoneText) or read(GetZoneText),planner.IsPinned)
 local count=cfg.compact and 2 or 4;local pages=math.max(1,math.ceil(#ordered/count))
 T.page=math.max(1,math.min(T.page,pages))
 root:SetHeight(cfg.collapsed and 28 or (56+math.max(1,math.min(count,#ordered))*82));collapse:SetText(cfg.collapsed and '+' or '-')
 heading:SetText('QUESTS · '..#live..' active'..(not planner.IsSupported() and ' · cached' or ''))
 local focused=planner.GetSelected()
 empty:SetShown(not cfg.collapsed and #ordered==0);findQuests:SetShown(not cfg.collapsed and #ordered==0)
 for i,row in ipairs(rows) do
  local item=i<=count and ordered[(T.page-1)*count+i]
  row.item=item;row:SetShown(not cfg.collapsed and item~=nil)
  if item then
   row.title:SetText((item.pinned and '* ' or '')..item.quest.title)
   row.preview:SetText(T.Preview(item.quest))
   local done,total=ForeverCompanionQuestFieldGuide.Progress(item.quest)
   row.meta:SetText((item.quest.zone or 'Zone not reported')..' · '..done..'/'..total..' objectives')
   row.selected=focused==item.quest;ForeverCompanionVisualTheme.SelectRow(row,row.bg,row.selected)
   row.title:SetTextColor(item.quest.complete and .48 or .94,item.quest.complete and .88 or .95,item.quest.complete and .58 or .97)
   row.map:SetEnabled(planner.IsSupported())
  end
 end
 footer:ClearAllPoints();footer:SetPoint('BOTTOMLEFT',10,7);footer:SetShown(not cfg.collapsed)
 footer:SetText(not planner.IsSupported() and 'Cached / unavailable · check quest log' or (#ordered==0 and 'No quests match this tracker view.' or ('Page '..T.page..'/'..pages..' · Pinned, ready, current zone')))
 previous:SetShown(not cfg.collapsed);nextPage:SetShown(not cfg.collapsed)
 previous:SetEnabled(T.page>1);nextPage:SetEnabled(T.page<pages)
end
function T.Show()
 if not root then create() end
 settings().visible=true;root:Show();T.Refresh()
 if ForeverCompanionQuestBriefing then ForeverCompanionQuestBriefing.Render() end
end
function T.Hide()
 settings().visible=false;if root then root:Hide() end
 if ForeverCompanionQuestBriefing then ForeverCompanionQuestBriefing.Render() end
end
function T.Toggle() if T.IsShown() then T.Hide() else T.Show() end end
