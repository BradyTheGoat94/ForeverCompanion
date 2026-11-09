-- A live objective itinerary, not a pre-authored or terrain-verified walkthrough.
local R={page=1}
ForeverCompanionObjectiveRoute=R
local root,rows,summary,notice,previous,nextPage,counter,optionsButton
local current={}
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
 local candidates,stats={},{remaining=0,matched=0,unlocated=0,otherMaps=0,unknownQuests=0,excluded=0,positionKnown=point(x,y)}
 for index,q in ipairs(quests or {}) do
  local isPinned=pinned and pinned(q)==true or false
  local include=not options.filter or options.filter=='all' or options.filter=='pinned' and isPinned or options.filter=='turnin' and q.complete==true or options.filter=='selected' and (q==options.selected or options.selected and q.id and q.id==options.selected.id)
  if include then
  local steps=ForeverCompanionQuestFieldGuide.Steps(q,targets[q] or {})
  if #steps==0 then stats.unknownQuests=stats.unknownQuests+1 end
  for _,step in ipairs(steps) do if not step.done then
   stats.remaining=stats.remaining+1
   local localTargets={}
   for _,t in ipairs(step.targets) do if t.map==map then localTargets[#localTargets+1]=t end end
   if #localTargets>0 then
    stats.matched=stats.matched+1
    candidates[#candidates+1]={quest=q,index=index,step=step,targets=localTargets,pinned=isPinned}
   elseif #step.targets>0 then stats.otherMaps=stats.otherMaps+1
   else stats.unlocated=stats.unlocated+1 end
  end end
  else stats.excluded=stats.excluded+1 end
 end
 local stops={}
 -- Bound the planning work for unexpectedly large provider/log snapshots.
 for _=1,math.min(40,#candidates) do
  local best,bestTarget,bestRank,bestDistance,bestIndex
  for i,c in ipairs(candidates) do
   local rank=c.pinned and 2 or (c.quest.complete and 1 or 0)
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
 return stops,stats
end
local function snapshot(quests,options)
 local map=C_Map and read(C_Map.GetBestMapForUnit,'player')
 if not finite(map) or map<=0 then map=nil end
 local position=map and read(C_Map.GetPlayerMapPosition,map,'player')
 local x,y
 if position and not (issecretvalue and issecretvalue(position)) then x,y=read(position.GetXY,position) end
 local targets={};for _,q in ipairs(quests) do targets[q]=ForeverCompanionQuestWaypoints.Targets(q) end
 return R.Build(quests,targets,map,x,y,ForeverCompanionQuestPlanner.IsPinned,options)
end
function R.NavigateNext(quest)
 local p=ForeverCompanionQuestPlanner
 if not p or not p.IsSupported() then return 'Quest snapshot unavailable. Open the quest log first.' end
 local quests=p.GetLive()
 local options={order=settings().order,filter=quest and 'selected' or settings().filter,selected=quest or p.GetSelected()}
 local stops=snapshot(quests,options)
 local stop=stops[1]
 if not stop then return 'No matched unfinished objective on this map. Open the field guide for other locations.' end
 local q,index,target=R.Resolve(stop,p.GetLive(),ForeverCompanionQuestWaypoints.Targets)
 if not target then return 'This objective changed. Choose it again.' end
 p.Select(index)
 return ForeverCompanionQuestWaypoints.Navigate(target,settings().openMap==true,q.title..' · '..stop.text)
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
  local row=CreateFrame('Frame',nil,root);row:SetPoint('TOPLEFT',16,-85-(i-1)*55);row:SetSize(738,51)
  row.bg=ForeverCompanionInterface.Surface(row)
  row.title=text(row,10,-5,580,12,'');row.detail=text(row,10,-25,580,11,'')
  row.go=ForeverCompanionInterface.Button(row);row.go:SetPoint('TOPRIGHT',-8,-12);row.go:SetSize(120,26);row.go:SetText('Go to objective')
  row.go:SetScript('OnClick',function()
   local p=ForeverCompanionQuestPlanner
   if not p.IsSupported() then notice:SetText('Quest snapshot unavailable. Open your quest log and try again.');return end
   local q,index,target=R.Resolve(row.stop,p.GetLive(),ForeverCompanionQuestWaypoints.Targets)
   if not target then R.Refresh();notice:SetText('This objective or location changed. Refresh the itinerary.');return end
   p.Select(index)
   notice:SetText(ForeverCompanionQuestWaypoints.Navigate(target,settings().openMap==true,q.title..' · '..row.stop.text))
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
 summary:SetText((cfg.filter or 'all')..' quests · '..#current..' / '..stats.matched..' mapped steps · '..stats.unlocated..' unlocated · '..stats.otherMaps..' on other maps · '..stats.unknownQuests..' without objectives')
 for i,row in ipairs(rows) do
  local stop=current[(R.page-1)*4+i];row.stop=stop;row:SetShown(stop~=nil)
  if stop then
   row.title:SetText(((R.page-1)*4+i)..'. '..stop.quest.title)
   row.detail:SetText((stop.turnin and 'Turn in' or stop.text)..' · '..(stop.target.reference and 'Reference location' or 'Client reported'))
   row.go:SetText(stop.turnin and 'Go to giver' or 'Go to objective');row.go:SetEnabled(p.IsSupported())
  end
 end
 notice:SetText(#current>0 and (cfg.order=='log' and 'Pinned first, then turn-ins; quest-log order within groups. Navigation starts only when you click.' or (stats.positionKnown and 'Pinned first, then turn-ins; approximate map distance. Terrain and travel paths are not evaluated.' or 'Position unavailable: quest-log order within priority groups. No distance order is inferred.')) or
  (p.IsSupported() and 'No matched unfinished objectives on this map. General quest POIs remain available in the journal. '..stats.unknownQuests..' quests have no objective details.' or 'Waiting for a successful quest-log scan. Cached quests cannot start navigation.'))
 previous:SetEnabled(R.page>1);nextPage:SetEnabled(R.page<pages);counter:SetText('Steps · '..R.page..' / '..pages)
 if profiler then profiler.Finish('itinerary',started) end
end
function R.GetHeight() return root and root:GetHeight() or 354 end
