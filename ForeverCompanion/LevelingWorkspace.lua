local W={page=1,view='suggestions'}
ForeverCompanionLevelingWorkspace=W
local root,search,summary,notice,metrics,empty,previous,nextPage,counter,modeButton,localButton
local rows,tabs={},{}
local zoneFilter
local modeNames={nearby='Nearby first',turnins='Turn-ins first',pinned='Pinned first'}
local P=ForeverCompanionLevelingPlan
local function read(fn,...)
 if type(fn)~='function' then return end
 local ok,a,b=pcall(fn,...);if ok then return a,b end
end
local function text(parent,x,y,width,size,value)
 local f=ForeverCompanionInterface.Text(parent,size);f:SetPoint('TOPLEFT',x,y);f:SetWidth(width);f:SetText(value or '');return f
end
local function button(parent,x,y,width,caption,action)
 local b=ForeverCompanionInterface.Button(parent);b:SetPoint('TOPLEFT',x,y);b:SetSize(width,27);b:SetText(caption);b:SetScript('OnClick',action);return b
end
local function status(message) if notice then notice:SetText(message or '') end end
local function sessionMetrics()
 if not metrics then return end
 local s=ForeverCompanionSessionProgress.Snapshot()
 metrics:SetText('THIS SESSION   '..ForeverCompanionSessionProgress.Duration(s.seconds)..(s.paused and ' (paused)' or '')..
  '    |    Observed XP: '..string.format('%.0f',s.xp or 0)..'    |    XP/hour: '..(s.rate and string.format('%.0f',s.rate) or 'unavailable')..
  '    |    Turn-ins: '..tostring(s.turnins or 0))
end
function W.Refresh()
 if not root or not root:IsShown() then return end
 local planner=ForeverCompanionQuestPlanner
 local supported=planner.IsSupported()
 local quests=supported and planner.GetLive() or {}
 local saved=P.Settings()
 local map=C_Map and read(C_Map.GetBestMapForUnit,'player')
 if (issecretvalue and issecretvalue(map)) or type(map)~='number' or map~=map or map<=0 or map==math.huge then map=nil end
 local position=map and C_Map and read(C_Map.GetPlayerMapPosition,map,'player')
 local x,y;if position then x,y=read(position.GetXY,position) end
 local locations=supported and map and ForeverCompanionQuestWaypoints.MapLocations(map,quests) or {}
 local pins={};for _,q in ipairs(quests) do if P.Identity(q) and planner.IsPinned(q) then pins[q.id]=true end end
 local all=P.Build(quests,locations,{map=map,x=x,y=y,pins=pins,mode=saved.mode})
 local records
 if W.view=='saved' then records=P.Saved(quests,supported)
 elseif W.view=='zones' then records=P.Zones(all)
 else records=P.Build(quests,locations,{map=map,x=x,y=y,pins=pins,mode=saved.mode,localOnly=saved.localOnly,query=search:GetText()}) end
 if zoneFilter and W.view=='suggestions' then
  local filtered={};for _,r in ipairs(records) do if r.zone==zoneFilter then filtered[#filtered+1]=r end end;records=filtered
 end
 local pages=math.max(1,math.ceil(#records/5));W.page=math.max(1,math.min(pages,W.page))
 local ready=0;for _,r in ipairs(all) do if r.ready then ready=ready+1 end end
 summary:SetText(not supported and 'Quest scan unavailable. Saved quests are retained, but quest actions are disabled.' or
  (#all..' live quests · '..ready..' ready to turn in · '..#saved.quests..'/8 saved'..(zoneFilter and (' · Zone: '..zoneFilter) or '')))
 summary:SetHeight(36);summary:SetWordWrap(true)
 modeButton:SetText(modeNames[saved.mode]);localButton:SetText(saved.localOnly and 'With map locations' or 'All quest locations')
 modeButton:SetEnabled(W.view=='suggestions');localButton:SetEnabled(W.view=='suggestions');search:SetShown(W.view=='suggestions')
 for view,b in pairs(tabs) do ForeverCompanionInterface.StyleButton(b,nil,W.view==view) end
 empty:SetShown(#records==0)
 empty:SetText(not supported and 'Open the in-game quest log and refresh. No cached quest is treated as actionable.' or
  W.view=='saved' and 'Build a short plan from Suggestions or the quest tracker menu. Add up to 8 quests, then arrange them in your preferred order.' or
  'No quests match this view. Try All quest locations, clear your search, or pick up a quest in game.')
 for i,row in ipairs(rows) do
  local r=records[(W.page-1)*5+i];row.record=r;row:SetShown(r~=nil)
  if r then
   local zones=W.view=='zones'
   row.title:SetText(zones and r.name or ((r.planIndex and (r.planIndex..'. ') or '')..r.title))
   row.detail:SetText(zones and (r.total..' quests · '..r.ready..' ready to turn in') or r.nextStep)
   row.reason:SetText(zones and (r.nearby..' with reported locations on your current map') or r.reason)
   row.guide:SetShown(not zones);row.map:SetShown(not zones)
   row.guide:SetEnabled(r.quest~=nil);row.map:SetEnabled(r.quest~=nil)
   row.add:SetText(zones and 'Show quests' or W.view=='saved' and 'Remove' or P.Contains(r) and 'In your plan' or 'Add to plan')
   row.add:SetEnabled(zones or W.view=='saved' or (not P.Contains(r) and #saved.quests<P.limit))
   row.up:SetShown(W.view=='saved');row.down:SetShown(W.view=='saved')
   row.up:SetEnabled(r.planIndex~=nil and r.planIndex>1);row.down:SetEnabled(r.planIndex~=nil and r.planIndex<#saved.quests)
  end
 end
 previous:SetEnabled(W.page>1);nextPage:SetEnabled(W.page<pages);counter:SetText(W.page..' / '..pages..'   ·   '..#records..' entries')
 sessionMetrics()
end
function W.Open(view)
 if not root then
  local U=ForeverCompanionInterface
  root=CreateFrame('Frame','ForeverCompanionLevelingPlanner',UIParent)
  root:SetSize(920,720);root:SetPoint('CENTER');root:SetFrameStrata('DIALOG');root:SetClampedToScreen(true);root:SetMovable(true);root:EnableMouse(true)
  U.Surface(root);U.PreparePanel(root,'ForeverCompanionLevelingPlanner',920,720)
  local drag=CreateFrame('Frame',nil,root);drag:SetPoint('TOPLEFT');drag:SetSize(870,40);drag:EnableMouse(true);drag:RegisterForDrag('LeftButton')
  drag:SetScript('OnDragStart',function() root:StartMoving() end);drag:SetScript('OnDragStop',function() root:StopMovingOrSizing() end)
  text(root,18,-14,570,18,'LEVELING SESSION PLANNER');button(root,640,-8,206,'Open 1-60 walkthrough',function() root:Hide();ForeverCompanionWalkthrough.Open() end);U.CloseButton(root,function() root:Hide() end)
  metrics=text(root,18,-53,884,12,'')
  text(root,18,-76,884,10,'Your plan is saved for this character. Session XP is observed since login/reset; missing samples do not produce an estimated rate.')
  for i,pair in ipairs({{'suggestions','Suggestions'},{'saved','My saved plan'},{'zones','Zone overview'}}) do
   local key=pair[1]
   tabs[key]=button(root,18+(i-1)*295,-103,284,pair[2],function() W.view=key;W.page=1;zoneFilter=nil;status('');W.Refresh() end)
  end
  search=U.EditBox(root,'Search quest, zone or ID');search:SetPoint('TOPLEFT',18,-143);search:SetSize(367,27);search:SetMaxLetters(100)
  search:HookScript('OnTextChanged',function() W.page=1;zoneFilter=nil;W.Refresh() end)
  search:SetScript('OnEscapePressed',function(self) self:SetText('');self:ClearFocus() end)
  search:SetScript('OnEnterPressed',function(self) self:ClearFocus() end)
  modeButton=button(root,395,-143,180,'',function(self)
   local entries={};for _,key in ipairs({'nearby','turnins','pinned'}) do
    local mode=key;entries[#entries+1]={label=modeNames[mode],selected=P.Settings().mode==mode,action=function() P.Settings().mode=mode;W.page=1;W.Refresh() end}
   end;U.Menu(self,'SUGGESTION PRIORITY',entries)
  end)
  localButton=button(root,585,-143,190,'',function() local s=P.Settings();s.localOnly=not s.localOnly;W.page=1;W.Refresh() end)
  button(root,785,-143,117,'Clear filters',function() zoneFilter=nil;P.Settings().localOnly=false;search:SetText('');W.page=1;W.Refresh() end)
  summary=text(root,18,-181,884,12,'')
  empty=text(root,35,-260,840,14,'');empty:SetHeight(100);empty:SetWordWrap(true)
  for i=1,5 do
   local row=CreateFrame('Frame',nil,root);row:SetPoint('TOPLEFT',18,-224-(i-1)*75);row:SetSize(884,70);U.Surface(row)
   row.title=text(row,12,-6,518,13,'');row.detail=text(row,12,-28,518,11,'');row.detail:SetHeight(32);row.detail:SetWordWrap(true);row.detail:SetJustifyV('TOP');row.reason=text(row,12,-48,518,10,'');row.reason:Hide()
   row.guide=button(row,540,-21,60,'Details',function()
    if not row.record then return end;local ok,message=P.Act(row.record,'guide');status(message);W.Refresh();if ok then root:Hide() end
   end)
   row.map=button(row,606,-21,60,'Map',function()
    if not row.record then return end;local _,message=P.Act(row.record,'map');status(message);W.Refresh()
   end)
   row.add=button(row,672,-21,92,'Add to plan',function()
    local r=row.record;if not r then return end
    if W.view=='zones' then
     local name=r.name;search:SetText('');P.Settings().localOnly=false;zoneFilter=name;W.view='suggestions';W.page=1;status('')
    elseif W.view=='saved' then P.Remove(r);status('Removed from your plan. Your in-game quest log is unchanged.')
    else local _,message=P.Add(r);status(message) end
    W.Refresh()
   end)
   row.up=button(row,772,-21,44,'Up',function() if row.record then P.Move(row.record,-1);W.Refresh() end end)
   row.down=button(row,824,-21,44,'Down',function() if row.record then P.Move(row.record,1);W.Refresh() end end)
   row:SetScript('OnEnter',function(self)
    if not GameTooltip or not self.record then return end
    GameTooltip:SetOwner(self,'ANCHOR_RIGHT');GameTooltip:SetText(self.record.title or self.record.name)
    if self.record.nextStep then GameTooltip:AddLine(self.record.nextStep,.85,.88,.93,true) end
    if self.record.reason then GameTooltip:AddLine(self.record.reason,.7,.8,.9,true) end;GameTooltip:Show()
   end)
   row:EnableMouse(true);row:SetScript('OnLeave',function() if GameTooltip then GameTooltip:Hide() end end)
   rows[i]=row
  end
  previous=button(root,18,-603,96,'Previous',function() W.page=W.page-1;W.Refresh() end)
  counter=text(root,130,-609,340,12,'')
  nextPage=button(root,806,-603,96,'Next',function() W.page=W.page+1;W.Refresh() end)
  notice=text(root,18,-638,884,11,'');notice:SetHeight(29);notice:SetWordWrap(true)
  button(root,18,-678,170,'Training guide',function() ForeverCompanionTraining.Open('') end)
  button(root,196,-678,170,'Class guide',function() SlashCmdList.FOREVERCOMPANION('open leveling');root:Hide() end)
  button(root,374,-678,170,'Material sources',function() ForeverCompanionMaterialFinder.Open() end)
  button(root,552,-678,170,'Session details',function() ForeverCompanionSessionProgress.Toggle() end)
  button(root,730,-678,172,'Refresh quests',function()
   ForeverCompanionQuestPlanner.Sync();W.Refresh()
   status(ForeverCompanionQuestPlanner.IsSupported() and 'Refreshed the reported quest log.' or 'Quest scan is unavailable. Saved entries are retained.')
  end)
  local elapsed=0;root:SetScript('OnUpdate',function(_,dt) elapsed=elapsed+dt;if elapsed>=1 then elapsed=0;sessionMetrics() end end)
  root:Hide()
 end
 W.view=(view=='saved' or view=='zones') and view or 'suggestions';W.page=1;zoneFilter=nil
 root:Show();status('');W.Refresh()
end
