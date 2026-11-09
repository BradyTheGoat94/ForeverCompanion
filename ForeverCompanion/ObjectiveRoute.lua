-- A live objective itinerary, not a pre-authored or terrain-verified walkthrough.
local R={page=1}
ForeverCompanionObjectiveRoute=R
local root,rows,summary,notice,previous,nextPage,counter
local current={}
local function read(fn,...)
 if type(fn)~='function' then return end
 local ok,a,b=pcall(fn,...);if ok then return a,b end
end
local function finite(n) return not (issecretvalue and issecretvalue(n)) and type(n)=='number' and n==n and math.abs(n)<math.huge end
local function point(x,y) return finite(x) and finite(y) and x>=0 and x<=1 and y>=0 and y<=1 end
local function same(a,b) return a and b and a.map==b.map and a.x==b.x and a.y==b.y end
function R.Build(quests,targets,map,x,y,pinned)
 targets=targets or {}
 if not finite(map) or map<=0 then map=nil end
 local candidates,stats={},{remaining=0,matched=0,unlocated=0,otherMaps=0,unknownQuests=0,positionKnown=point(x,y)}
 for index,q in ipairs(quests or {}) do
  local steps=ForeverCompanionQuestFieldGuide.Steps(q,targets[q] or {})
  if #steps==0 then stats.unknownQuests=stats.unknownQuests+1 end
  for _,step in ipairs(steps) do if not step.done then
   stats.remaining=stats.remaining+1
   local localTargets={}
   for _,t in ipairs(step.targets) do if t.map==map then localTargets[#localTargets+1]=t end end
   if #localTargets>0 then
    stats.matched=stats.matched+1
    candidates[#candidates+1]={quest=q,index=index,step=step,targets=localTargets,pinned=pinned and pinned(q)==true or false}
   elseif #step.targets>0 then stats.otherMaps=stats.otherMaps+1
   else stats.unlocated=stats.unlocated+1 end
  end end
 end
 local stops={}
 -- Bound the planning work for unexpectedly large provider/log snapshots.
 for _=1,math.min(40,#candidates) do
  local best,bestTarget,bestRank,bestDistance,bestIndex
  for i,c in ipairs(candidates) do
   local rank=c.pinned and 2 or (c.quest.complete and 1 or 0)
   for _,t in ipairs(c.targets) do
    local distance=stats.positionKnown and ((t.x-x)^2+(t.y-y)^2) or 0
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
 text(root,16,-12,738,15,'LIVE OBJECTIVE ITINERARY')
 summary=text(root,16,-45,738,11,'')
 rows={}
 for i=1,4 do
  local row=CreateFrame('Frame',nil,root);row:SetPoint('TOPLEFT',16,-72-(i-1)*55);row:SetSize(738,51)
  row.bg=ForeverCompanionInterface.Surface(row)
  row.title=text(row,10,-5,580,12,'');row.detail=text(row,10,-25,580,11,'')
  row.go=ForeverCompanionInterface.Button(row);row.go:SetPoint('TOPRIGHT',-8,-12);row.go:SetSize(120,26);row.go:SetText('Go to objective')
  row.go:SetScript('OnClick',function()
   local p=ForeverCompanionQuestPlanner
   if not p.IsSupported() then notice:SetText('Quest snapshot unavailable. Open your quest log and try again.');return end
   local q,index,target=R.Resolve(row.stop,p.GetLive(),ForeverCompanionQuestWaypoints.Targets)
   if not target then R.Refresh();notice:SetText('This objective or location changed. Refresh the itinerary.');return end
   p.Select(index)
   notice:SetText(ForeverCompanionQuestWaypoints.Navigate(target,true,q.title))
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
 local map=C_Map and read(C_Map.GetBestMapForUnit,'player')
 if not finite(map) or map<=0 then map=nil end
 local position=map and read(C_Map.GetPlayerMapPosition,map,'player')
 local x,y
 if position and not (issecretvalue and issecretvalue(position)) then x,y=read(position.GetXY,position) end
 local quests=p.IsSupported() and p.GetLive() or {}
 local targets={};for _,q in ipairs(quests) do targets[q]=ForeverCompanionQuestWaypoints.Targets(q) end
 local stats;current,stats=R.Build(quests,targets,map,x,y,p.IsPinned)
 local pages=math.max(1,math.ceil(#current/4));R.page=math.max(1,math.min(R.page,pages))
 local visible=math.min(4,math.max(0,#current-(R.page-1)*4))
 local noticeY=77+math.max(1,visible)*55
 notice:ClearAllPoints();notice:SetPoint('TOPLEFT',root,'TOPLEFT',16,-noticeY)
 ForeverCompanionVisualTheme.ResizePanel(root,noticeY+70)
 summary:SetText(map and (#current..' / '..stats.matched..' mapped steps shown · '..stats.unlocated..' unlocated · '..stats.otherMaps..' on other maps · '..stats.unknownQuests..' without objectives') or 'Current map unavailable. Move into a zone and try again.')
 for i,row in ipairs(rows) do
  local stop=current[(R.page-1)*4+i];row.stop=stop;row:SetShown(stop~=nil)
  if stop then
   row.title:SetText(((R.page-1)*4+i)..'. '..stop.quest.title)
   row.detail:SetText((stop.turnin and 'Turn in' or stop.text)..' · '..(stop.target.reference and 'Reference location' or 'Client reported'))
   row.go:SetText(stop.turnin and 'Go to giver' or 'Go to objective');row.go:SetEnabled(p.IsSupported())
  end
 end
 notice:SetText(#current>0 and (stats.positionKnown and 'Pinned first, then turn-ins; approximate map distance. Terrain and travel paths are not evaluated.' or 'Position unavailable: quest-log order within priority groups. No distance order is inferred.') or
  (p.IsSupported() and 'No matched unfinished objectives on this map. General quest POIs remain available in the journal. '..stats.unknownQuests..' quests have no objective details.' or 'Waiting for a successful quest-log scan. Cached quests cannot start navigation.'))
 previous:SetEnabled(R.page>1);nextPage:SetEnabled(R.page<pages);counter:SetText('Steps · '..R.page..' / '..pages)
 if profiler then profiler.Finish('itinerary',started) end
end
function R.GetHeight() return root and root:GetHeight() or 354 end
