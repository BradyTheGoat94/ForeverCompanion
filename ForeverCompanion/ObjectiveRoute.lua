-- A live objective itinerary, not a pre-authored or terrain-verified walkthrough.
local R={page=1}
ForeverCompanionObjectiveRoute=R
local root,rows,summary,notice,previous,nextPage,counter,optionsButton
local current={}
local deferred={}
local picked={}
function R.StepKey(stop)
 if type(stop)~='table' or type(stop.quest)~='table' or type(stop.quest.id)~='number' then return end
 return stop.quest.id..':'..tostring(stop.objectiveIndex)..':'..tostring(stop.turnin==true)..':'..tostring(stop.text)
end
function R.IsPicked(q) return q and q.id and picked[q.id]==q.title end
function R.TogglePicked(q)
 if not q or type(q.id)~='number' then return end
 if R.IsPicked(q) then picked[q.id]=nil else picked[q.id]=q.title end
 if R.RefreshPopup then R.RefreshPopup() end
end
local function settings()
 ForeverCompanionDB=ForeverCompanionDB or {}
 if type(ForeverCompanionDB.objectiveRoute)~='table' then ForeverCompanionDB.objectiveRoute={} end
 return ForeverCompanionDB.objectiveRoute
end
local function read(fn,...)
 if type(fn)~='function' then return end
 local ok,a,b=pcall(fn,...);if ok then return a,b end
end
local function finite(n) return not (issecretvalue and issecretvalue(n)) and type(n)=='number' and n==n and math.abs(n)<math.huge end
local function point(x,y) return finite(x) and finite(y) and x>=0 and x<=1 and y>=0 and y<=1 end
local function same(a,b) return a and b and a.map==b.map and a.x==b.x and a.y==b.y end
function R.Build(quests,targets,map,x,y,pinned,options)
 targets=targets or {}
 options=type(options)=='table' and options or {}
 if not finite(map) or map<=0 then map=nil end
 local candidates,stats={},{remaining=0,matched=0,unlocated=0,otherMaps=0,unknownQuests=0,excluded=0,deferred=0,review=0,positionKnown=point(x,y)}
 for index,q in ipairs(quests or {}) do
  local isPinned=pinned and pinned(q)==true or false
  local include=not options.filter or options.filter=='all' or options.filter=='pinned' and isPinned or options.filter=='turnin' and q.complete==true or options.filter=='picked' and R.IsPicked(q) or options.filter=='selected' and (q==options.selected or options.selected and q.id and q.id==options.selected.id)
  if include then
  local steps=ForeverCompanionQuestFieldGuide.Steps(q,targets[q] or {})
  if #steps==0 then stats.unknownQuests=stats.unknownQuests+1 end
  for _,step in ipairs(steps) do if not step.done then
   stats.remaining=stats.remaining+1
   local stepKey=R.StepKey({quest=q,objectiveIndex=step.index,turnin=step.turnin,text=step.text})
   if stepKey and options.deferred and options.deferred[stepKey] then stats.deferred=stats.deferred+1 else
   local localTargets={}
   for _,t in ipairs(step.targets) do if t.map==map then localTargets[#localTargets+1]=t end end
   if ForeverCompanionQuestFieldGuide.NeedsReview and ForeverCompanionQuestFieldGuide.NeedsReview(step) then stats.review=stats.review+1
   elseif #localTargets>0 then
    stats.matched=stats.matched+1
    candidates[#candidates+1]={quest=q,index=index,step=step,targets=localTargets,pinned=isPinned}
   elseif #step.targets>0 then stats.otherMaps=stats.otherMaps+1
   else stats.unlocated=stats.unlocated+1 end
   end
  end end
  else stats.excluded=stats.excluded+1 end
 end
 local startX,startY=x,y
 local stops={}
 -- Bound the planning work for unexpectedly large provider/log snapshots.
 for _=1,math.min(40,#candidates) do
  local best,bestTarget,bestRank,bestDistance,bestIndex
  for i,c in ipairs(candidates) do
   local rank=options.filter=='picked' and 0 or (c.pinned and 2 or (c.quest.complete and 1 or 0))
   for _,t in ipairs(c.targets) do
    local distance=options.order~='log' and stats.positionKnown and ((t.x-x)^2+(t.y-y)^2) or 0
    if not best or rank>bestRank or (rank==bestRank and distance<bestDistance) then
     best,bestTarget,bestRank,bestDistance,bestIndex=c,t,rank,distance,i
    end
   end
  end
  if not best then break end
  stops[#stops+1]={quest=best.quest,index=best.index,objectiveIndex=best.step.index,text=best.step.text,
   turnin=best.step.turnin,target=bestTarget,pinned=best.pinned}
  if stats.positionKnown then x,y=bestTarget.x,bestTarget.y end
  table.remove(candidates,bestIndex)
 end
 if options.filter=='picked' and stats.positionKnown then
  local function distance(a,b) return math.sqrt((a.x-b.x)^2+(a.y-b.y)^2) end
  local origin={x=startX,y=startY}
  for _=1,3 do
   for a=1,#stops-1 do for b=a+1,#stops do
    local left=a==1 and origin or stops[a-1].target
    local right=stops[b+1] and stops[b+1].target
    local before=distance(left,stops[a].target)+(right and distance(stops[b].target,right) or 0)
    local after=distance(left,stops[b].target)+(right and distance(stops[a].target,right) or 0)
    if after+1e-9<before then
     for i=0,math.floor((b-a-1)/2) do stops[a+i],stops[b-i]=stops[b-i],stops[a+i] end
    end
   end end
  end
 end
 return stops,stats
end
local function snapshot(quests,options)
 options=options or {};options.deferred=deferred
 local map=C_Map and read(C_Map.GetBestMapForUnit,'player')
 if not finite(map) or map<=0 then map=nil end
 local position=map and read(C_Map.GetPlayerMapPosition,map,'player')
 local x,y
 if position and not (issecretvalue and issecretvalue(position)) then x,y=read(position.GetXY,position) end
 local targets={};for _,q in ipairs(quests) do targets[q]=ForeverCompanionQuestWaypoints.Targets(q) end
 local alive={}
 for _,q in ipairs(quests) do for _,step in ipairs(ForeverCompanionQuestFieldGuide.Steps(q,targets[q])) do
  if not step.done then local key=R.StepKey({quest=q,objectiveIndex=step.index,turnin=step.turnin,text=step.text});if key then alive[key]=true end end
 end end
 if ForeverCompanionQuestPlanner.IsSupported() then for key in pairs(deferred) do if not alive[key] then deferred[key]=nil end end end
 return R.Build(quests,targets,map,x,y,ForeverCompanionQuestPlanner.IsPinned,options)
end
function R.SetAside(stop)
 local p=ForeverCompanionQuestPlanner
 if not p or not p.IsSupported() or not R.Resolve(stop,p.GetLive(),ForeverCompanionQuestWaypoints.Targets) then return false end
 local key=R.StepKey(stop);if not key then return false end
 deferred[key]=true;R.page=1;R.Refresh();return true
end
function R.RestoreDeferred() deferred={};R.page=1;R.Refresh() end
function R.NavigateNext(quest,exclude)
 local p=ForeverCompanionQuestPlanner
 if not p or not p.IsSupported() then return 'Quest snapshot unavailable. Open the quest log first.' end
 local quests=p.GetLive()
 local options={order=settings().order,filter=quest and 'selected' or settings().filter,selected=quest or p.GetSelected()}
 local stops=snapshot(quests,options)
 local stop
 for _,candidate in ipairs(stops) do if not same(candidate.target,exclude) then stop=candidate;break end end
 if not stop then
  if quest and ForeverCompanionOpenQuestGuide then ForeverCompanionOpenQuestGuide(quest.id) end
  return 'Review this quest in the field guide: no single nearby area can be chosen safely.'
 end
 local q,index,target=R.Resolve(stop,p.GetLive(),ForeverCompanionQuestWaypoints.Targets)
 if not target then return 'This objective changed. Choose it again.' end
 p.Select(index)
 return ForeverCompanionQuestWaypoints.Navigate(target,settings().openMap==true,q.title..' · '..stop.text,q.id)
end
function R.OpenOptions(anchor)
 local cfg=settings()
 local choices={}
 for _,entry in ipairs({{'all','All active quests'},{'pinned','Pinned quests'},{'turnin','Ready to turn in'},{'selected','Focused quest'}}) do
  local key,label=entry[1],entry[2]
  choices[#choices+1]={label=label,selected=(cfg.filter or 'all')==key,action=function() cfg.filter=key;R.page=1;R.Refresh() end}
 end
 choices[#choices+1]={label='Order by approximate distance',selected=cfg.order~='log',action=function() cfg.order='nearest';R.page=1;R.Refresh() end}
 choices[#choices+1]={label='Order by quest log',selected=cfg.order=='log',action=function() cfg.order='log';R.page=1;R.Refresh() end}
 choices[#choices+1]={label='Open map when navigating',selected=cfg.openMap==true,action=function() cfg.openMap=not cfg.openMap;R.Refresh() end}
 local count=0;for _ in pairs(deferred) do count=count+1 end
 choices[#choices+1]={label='Restore set-aside objectives ('..count..')',enabled=count>0,action=R.RestoreDeferred}
 choices[#choices+1]={label='Open leveling session',action=function() ForeverCompanionSessionProgress.Toggle() end}
 ForeverCompanionInterface.Menu(anchor or optionsButton,'OBJECTIVE ITINERARY',choices)
end
function R.Resolve(stop,quests,targets)
 if type(stop)~='table' or type(stop.quest)~='table' or type(targets)~='function' then return end
 for index,q in ipairs(quests or {}) do
  if q==stop.quest or (q.id and q.id==stop.quest.id) then
   for _,step in ipairs(ForeverCompanionQuestFieldGuide.Steps(q,targets(q))) do
    if not step.done and step.index==stop.objectiveIndex and not not step.turnin==not not stop.turnin then
     for _,target in ipairs(step.targets) do if same(target,stop.target) then return q,index,target end end
    end
   end
  end
 end
end
local function text(parent,x,y,width,size,value)
 local f=ForeverCompanionInterface.Text(parent,size);f:SetPoint('TOPLEFT',x,y);f:SetWidth(width);f:SetText(value or '');return f
end
function R.Create(parent)
 root=CreateFrame('Frame','ForeverCompanionObjectiveRoutePanel',parent);root:SetPoint('TOPLEFT',0,-402);root:SetSize(770,354)
 ForeverCompanionVisualTheme.Panel(root,770,354)
 text(root,16,-12,410,15,'LIVE OBJECTIVE ITINERARY')
 optionsButton=ForeverCompanionInterface.Button(root);optionsButton:SetSize(142,25);optionsButton:SetPoint('TOPRIGHT',-16,-8);optionsButton:SetText('Route options')
 optionsButton:SetScript('OnClick',function() R.OpenOptions(optionsButton) end)
 local nextObjective=ForeverCompanionInterface.Button(root);nextObjective:SetSize(142,25);nextObjective:SetPoint('TOPRIGHT',-166,-8);nextObjective:SetText('Next objective')
 nextObjective:SetScript('OnClick',function() notice:SetText(R.NavigateNext()) end)
 summary=text(root,16,-45,738,11,'');summary:SetWordWrap(true);summary:SetHeight(33)
 rows={}
 for i=1,4 do
  local row=CreateFrame('Button',nil,root);row:SetPoint('TOPLEFT',16,-85-(i-1)*55);row:SetSize(738,51)
  row:RegisterForClicks('RightButtonUp')
  row:SetScript('OnClick',function(self)
   if not self.stop then return end
   local stop=self.stop
   ForeverCompanionInterface.Menu(self,'OBJECTIVE ACTIONS',{
    {label='Set aside until restored or reload',action=function() R.SetAside(stop) end},
    {label='Restore set-aside objectives',action=R.RestoreDeferred},
   })
  end)
  row:SetScript('OnEnter',function(self)
   if GameTooltip and self.stop then GameTooltip:SetOwner(self,'ANCHOR_RIGHT');GameTooltip:SetText(self.stop.text);GameTooltip:AddLine('Right-click to set this objective aside. Quest progress stays unchanged.',.8,.85,.9,true);GameTooltip:Show() end
  end)
  row:SetScript('OnLeave',function() if GameTooltip then GameTooltip:Hide() end end)
  row.bg=ForeverCompanionInterface.Surface(row)
  row.title=text(row,10,-5,580,12,'');row.detail=text(row,10,-25,580,11,'')
  row.go=ForeverCompanionInterface.Button(row);row.go:SetPoint('TOPRIGHT',-8,-12);row.go:SetSize(120,26);row.go:SetText('Go to objective')
  row.go:SetScript('OnClick',function()
   local p=ForeverCompanionQuestPlanner
   if not p.IsSupported() then notice:SetText('Quest snapshot unavailable. Open your quest log and try again.');return end
   local q,index,target=R.Resolve(row.stop,p.GetLive(),ForeverCompanionQuestWaypoints.Targets)
   if not target then R.Refresh();notice:SetText('This objective or location changed. Refresh the itinerary.');return end
   p.Select(index)
   notice:SetText(ForeverCompanionQuestWaypoints.Navigate(target,settings().openMap==true,q.title..' · '..row.stop.text,q.id))
  end)
  rows[i]=row
 end
 notice=text(root,16,-298,738,10,'');notice:SetHeight(27);notice:SetWordWrap(true)
 previous=ForeverCompanionInterface.Button(root);previous:SetPoint('BOTTOMLEFT',16,10);previous:SetSize(94,25);previous:SetText('Previous')
 nextPage=ForeverCompanionInterface.Button(root);nextPage:SetPoint('BOTTOMRIGHT',-16,10);nextPage:SetSize(94,25);nextPage:SetText('Next')
 counter=text(root,130,-324,510,11,'');counter:SetJustifyH('CENTER')
 counter:ClearAllPoints();counter:SetPoint('BOTTOM',root,'BOTTOM',0,15)
 previous:SetScript('OnClick',function() R.page=R.page-1;R.Refresh() end)
 nextPage:SetScript('OnClick',function() R.page=R.page+1;R.Refresh() end)
end
function R.Refresh()
 if not root or not root:IsShown() then return end
 local profiler=ForeverCompanionRefreshQueue
 local started=profiler and profiler.Start('itinerary')
 local p=ForeverCompanionQuestPlanner
 local quests=p.IsSupported() and p.GetLive() or {}
 local cfg=settings()
 local stats;current,stats=snapshot(quests,{filter=cfg.filter,order=cfg.order,selected=p.GetSelected()})
 local pages=math.max(1,math.ceil(#current/4));R.page=math.max(1,math.min(R.page,pages))
 local visible=math.min(4,math.max(0,#current-(R.page-1)*4))
 local noticeY=90+math.max(1,visible)*55
 notice:ClearAllPoints();notice:SetPoint('TOPLEFT',root,'TOPLEFT',16,-noticeY)
 ForeverCompanionVisualTheme.ResizePanel(root,noticeY+70)
 summary:SetText(#current..' steps on this map · '..stats.review..' need an area choice · '..stats.unlocated..' without locations · '..stats.otherMaps..' on other maps')
 for i,row in ipairs(rows) do
  local stop=current[(R.page-1)*4+i];row.stop=stop;row:SetShown(stop~=nil)
  if stop then
   row.title:SetText(((R.page-1)*4+i)..'. '..stop.quest.title)
   row.detail:SetText((stop.turnin and 'Turn in' or stop.text)..' · '..ForeverCompanionQuestWaypoints.Describe(stop.target))
   row.go:SetText(stop.turnin and 'Go to giver' or 'Go to objective');row.go:SetEnabled(p.IsSupported())
  end
 end
 notice:SetText(#current>0 and (cfg.order=='log' and 'Pinned first, then turn-ins; quest-log order within groups. Navigation starts only when you click.' or (stats.positionKnown and 'Pinned first, then turn-ins; approximate map distance. Terrain and travel paths are not evaluated.' or 'Position unavailable: quest-log order within priority groups. No distance order is inferred.')) or
  (p.IsSupported() and 'No matched unfinished objectives on this map. General quest POIs remain available in the journal. '..stats.unknownQuests..' quests have no objective details.' or 'Waiting for a successful quest-log scan. Cached quests cannot start navigation.'))
 previous:SetEnabled(R.page>1);nextPage:SetEnabled(R.page<pages);counter:SetText('Steps · '..R.page..' / '..pages)
 if profiler then profiler.Finish('itinerary',started) end
end
function R.GetHeight() return root and root:GetHeight() or 354 end

local popup,routeRows,routeSummary,routeNotice,selectButton,tabs
local routePage=1
local function routeButton(parent,x,y,w,name,action,help)
 local U=ForeverCompanionInterface
 local b=U.Button(parent);b:SetSize(w,25);b:SetPoint('TOPLEFT',x,y);b:SetText(name);b:SetScript('OnClick',action)
 if help then U.SetHoverHelp(b,name,help) end
 return b
end
function R.RefreshPopup()
 if not popup or not popup:IsShown() then return end
 local planner=ForeverCompanionQuestPlanner
 local quests=planner.IsSupported() and planner.GetLive() or {}
 local count=0
 for _,q in ipairs(quests) do if R.IsPicked(q) then count=count+1 end end
 local stops,stats=snapshot(quests,{filter='picked',order='nearest',deferred=deferred})
 local pages=math.max(1,math.ceil(#stops/#routeRows));routePage=math.max(1,math.min(routePage,pages))
 routeSummary:SetText(('%d selected / %d stops on this map / Page %d of %d'):format(count,#stops,routePage,pages))
 routeNotice:SetText(not planner.IsSupported() and 'Open the game quest log to refresh active quests.' or count==0 and 'Choose quests above, or Shift-click their rows in the journal.' or
  ('%d on other maps / %d without a clear location. %s'):format(stats.otherMaps,stats.unlocated+stats.review,
   stats.positionKnown and 'Estimated by straight-line distance.' or 'Player position unavailable. Showing quest-log order.'))
 for i,row in ipairs(routeRows) do
  local n=(routePage-1)*#routeRows+i
  row.stop=stops[n];row:SetShown(row.stop~=nil)
  if row.stop then row:SetText(n..'. '..row.stop.quest.title..' / '..row.stop.text) end
 end
 tabs[1]:SetEnabled(routePage>1);tabs[2]:SetEnabled(routePage<pages)
end
local function openPickMenu(page)
 local U=ForeverCompanionInterface
 local planner=ForeverCompanionQuestPlanner
 local choices={}
 if planner.IsSupported() then for _,q in ipairs(planner.GetLive()) do
  if type(q.id)=='number' then choices[#choices+1]=q end
 end end
 local visible,current,pages=U.MenuPage(choices,page)
 local menu={}
 for _,quest in ipairs(visible) do
  menu[#menu+1]={label=quest.title,selected=R.IsPicked(quest),action=function() R.TogglePicked(quest);openPickMenu(current) end}
 end
 if #menu==0 then menu[1]={label='No active quests available',enabled=false} end
 if pages>1 then
  menu[#menu+1]={label='Previous page',enabled=current>1,action=function() openPickMenu(current-1) end}
  menu[#menu+1]={label='Next page',enabled=current<pages,action=function() openPickMenu(current+1) end}
 end
 U.Menu(selectButton,('SELECT ACTIVE QUESTS  /  %d of %d'):format(current,pages),menu,nil,350)
end
function R.OpenPopup()
 local U=ForeverCompanionInterface
 if not popup then
  popup=CreateFrame('Frame','ForeverCompanionQuestRoutePopup',UIParent)
  popup:SetSize(592,370);popup:SetPoint('CENTER');popup:SetFrameStrata('DIALOG');U.Surface(popup)
  U.WindowControls(popup,'ForeverCompanionQuestRoutePopup',592,370)
  text(popup,14,-9,430,15,'Quest route')
  U.CloseButton(popup,function() popup:Hide() end)
  routeSummary=text(popup,14,-70,556,12,'')
  selectButton=routeButton(popup,14,-35,170,'Choose quests',function() openPickMenu(1) end,'Toggle active quests to include them in this route.')
  routeButton(popup,193,-35,112,'Clear selected',function() picked={};routePage=1;R.RefreshPopup() end,'Remove all quests from this route.')
  routeButton(popup,314,-35,100,'Recalculate',R.RefreshPopup,'Reorder route stops from your current position.')
  routeRows={}
  for i=1,6 do
   local row
   row=routeButton(popup,14,-95-(i-1)*31,562,'',function()
    local p=ForeverCompanionQuestPlanner
    if p.IsSupported() then
     local q,index,target=R.Resolve(row.stop,p.GetLive(),ForeverCompanionQuestWaypoints.Targets)
     if target then
      p.Select(index)
      routeNotice:SetText(ForeverCompanionQuestWaypoints.Navigate(target,false,q.title..' / '..row.stop.text,q.id))
      return
     end
    end
    R.RefreshPopup()
   end,'Start directions to this stop.')
   local name=row:GetFontString()
   name:SetJustifyH('LEFT');name:SetWordWrap(false)
   routeRows[i]=row
  end
  routeNotice=text(popup,14,-288,562,11,'');routeNotice:SetHeight(32);routeNotice:SetWordWrap(true)
  tabs={
   routeButton(popup,14,-331,92,'Previous',function() routePage=routePage-1;R.RefreshPopup() end,'Show earlier route stops.'),
   routeButton(popup,114,-331,92,'Next',function() routePage=routePage+1;R.RefreshPopup() end,'Show later route stops.'),
  }
 end
 popup:Show();R.RefreshPopup()
end
