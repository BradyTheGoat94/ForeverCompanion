-- Quest evidence, zone grouping and a read-only activity journal.
local J={history={},previous=nil};ForeverCompanionQuestJourney=J
local function finite(n) return not (issecretvalue and issecretvalue(n)) and type(n)=='number' and n==n and math.abs(n)<math.huge end
local function safe(s) return not (issecretvalue and issecretvalue(s)) and type(s)=='string' and s or '' end
local function call(fn,...) if type(fn)~='function' then return end;local ok,a=pcall(fn,...);if ok then return a end end
function J.Settings()
 ForeverCompanionDB=ForeverCompanionDB or {};local c=ForeverCompanionDB.questJourney
 if type(c)~='table' then c={} end
 if type(c.collapsedZones)~='table' then c.collapsedZones={} end
 ForeverCompanionDB.questJourney=c;return c
end
function J.Zone(q) return q.zoneKnown and safe(q.zone)~='' and q.zone or 'Zone not reported' end
function J.Group(items,collapsed)
 local groups,order={},{}
 for _,item in ipairs(items or {}) do
  local zone=J.Zone(item.quest);local g=groups[zone]
  if not g then g={zone=zone,items={},ready=0};groups[zone]=g;order[#order+1]=g end
  g.items[#g.items+1]=item;if item.quest.complete then g.ready=g.ready+1 end
 end
 local out={}
 for _,g in ipairs(order) do
  out[#out+1]={zoneHeader=true,zone=g.zone,count=#g.items,ready=g.ready,collapsed=collapsed and collapsed[g.zone]==true}
  if not (collapsed and collapsed[g.zone]) then for _,item in ipairs(g.items) do out[#out+1]=item end end
 end
 return out
end
function J.Resolve(q)
 local p=ForeverCompanionQuestPlanner
 if not p or not p.IsSupported() or type(q)~='table' then return end
 local found,index,count=nil,nil,0
 for i,fresh in ipairs(p.GetLive()) do if fresh.id==q.id then count=count+1;if fresh.title==q.title then found,index=fresh,i end end end
 if count==1 then return found,index end
end
function J.Focus(q)
 local fresh,index=J.Resolve(q);if not fresh then return false,'Quest changed or scan unavailable.' end
 J.Settings().focus={id=fresh.id,title=fresh.title};ForeverCompanionQuestPlanner.Select(index)
 return true,'Focused '..fresh.title
end
function J.Observe(quests,supported)
 if not supported then return end
 local snapshot,counts={},{}
 for _,q in ipairs(quests or {}) do if finite(q.id) then counts[q.id]=(counts[q.id] or 0)+1 end end
 local events={}
 for _,q in ipairs(quests or {}) do if counts[q.id]==1 then
  local parts={}
  for i,line in ipairs(q.objectives or {}) do
   local s=(q.objectiveStates or {})[i];s=type(s)=='table' and s or {}
   parts[#parts+1]=safe(line)..':'..tostring(s.known==true)..':'..tostring(s.done==true)..':'..(finite(s.current) and s.current or '?')
  end
  local now={id=q.id,title=safe(q.title),complete=q.complete==true,digest=table.concat(parts,'|')};snapshot[q.id]=now
  local old=J.previous and J.previous[q.id]
  if J.previous then
   local event
   if not old or old.title~=now.title then event='Accepted'
   elseif not old.complete and now.complete then event='Ready to turn in'
   elseif old.digest~=now.digest then event='Objectives updated' end
   if event then events[#events+1]={id=q.id,title=now.title,event=event};J.notice=event..': '..now.title end
  end
 end end
 if J.previous then for id,old in pairs(J.previous) do if not snapshot[id] then events[#events+1]={id=id,title=old.title,event='Left quest log'} end end end
 for _,event in ipairs(events) do table.insert(J.history,1,event);while #J.history>8 do table.remove(J.history) end end
 J.previous=snapshot;return events
end
function J.Coverage(q,targets,details)
 local G=ForeverCompanionQuestFieldGuide;details=details or {}
 local steps=G.Steps(q,targets);local report={unfinished=0,matched=0,review=0,reference=0,missing=0,pickups=#(details.pickups or {}),turnins=#(details.turnins or {})}
 for _,step in ipairs(steps) do if not step.done then
  report.unfinished=report.unfinished+1
  if #step.targets==0 then report.missing=report.missing+1
  elseif G.NeedsReview(step) then report.review=report.review+1
  else report.matched=report.matched+1 end
  for _,t in ipairs(step.targets) do if t.reference then report.reference=report.reference+1;break end end
 end end
 return report
end
function J.Recommend(quests,targetReader,map,x,y,pin)
 local candidates={}
 for i,q in ipairs(quests or {}) do
  local nearest,valid=nil,false
  local targets=call(targetReader,q) or {}
  for _,step in ipairs(ForeverCompanionQuestFieldGuide.Steps(q,targets)) do
   if not step.done and not ForeverCompanionQuestFieldGuide.NeedsReview(step) then
    for _,t in ipairs(step.targets) do if t.map==map then
     valid=true
     if finite(x) and finite(y) then local d=(t.x-x)^2+(t.y-y)^2;if not nearest or d<nearest then nearest=d end end
    end end
   end
  end
  local pinned=call(pin,q)==true
  local rank=valid and (q.complete and 6 or pinned and 5 or 4) or (pinned and 3 or q.complete and 2 or 1)
  candidates[#candidates+1]={quest=q,index=i,rank=rank,distance=nearest,reason=valid and (q.complete and 'Turn-in reference on your map' or pinned and 'Pinned quest with a matched area on your map' or 'Matched unfinished area on your map') or (pinned and 'Pinned by you; review travel' or q.complete and 'Ready to turn in; review travel' or 'Quest-log order; no safe local area known')}
 end
 table.sort(candidates,function(a,b) if a.rank~=b.rank then return a.rank>b.rank end;if a.distance and b.distance and a.distance~=b.distance then return a.distance<b.distance end;return a.index<b.index end)
 return candidates[1],candidates
end
local panel,body,heading,selected,status
function J.Show(q)
 local fresh=J.Resolve(q);if not fresh then return false end;selected={id=fresh.id,title=fresh.title}
 if not panel then
  local U=ForeverCompanionInterface
  panel=CreateFrame('Frame','ForeverCompanionQuestIntelligence',UIParent,'BackdropTemplate');panel:SetSize(650,480);panel:SetPoint('CENTER');panel:SetFrameStrata('DIALOG');panel:SetMovable(true);panel:EnableMouse(true);panel:RegisterForDrag('LeftButton');panel:SetScript('OnDragStart',function(self) self:StartMoving() end);panel:SetScript('OnDragStop',function(self) self:StopMovingOrSizing() end);panel:SetClampedToScreen(true);U.Surface(panel);U.PreparePanel(panel,'ForeverCompanionQuestIntelligence',650,480);U.CloseButton(panel,function() panel:Hide() end)
  heading=U.Text(panel,16);heading:SetPoint('TOPLEFT',16,-18);heading:SetWidth(585)
  body=U.Text(panel,12);body:SetPoint('TOPLEFT',16,-54);body:SetSize(618,340);body:SetWordWrap(true)
  status=U.Text(panel,11);status:SetPoint('BOTTOMLEFT',16,48);status:SetWidth(618)
  local function button(x,w,label,action) local b=U.Button(panel);b:SetPoint('BOTTOMLEFT',x,12);b:SetSize(w,26);b:SetText(label);b:SetScript('OnClick',function() local live=J.Resolve(selected);if not live then status:SetText('Quest changed or scan unavailable. Reopen this report.');return end;action(live) end) end
  button(16,140,'Focus quest',function(live) local _,msg=J.Focus(live);status:SetText(msg);if ForeverCompanionQuestTracker then ForeverCompanionQuestTracker.Refresh() end end)
  button(166,140,'Next objective',function(live) status:SetText(ForeverCompanionObjectiveRoute.NavigateNext(live)) end)
  button(316,140,'Quest details',function(live) ForeverCompanionOpenQuestGuide(live.id);panel:Hide() end)
  button(466,168,'Reward equipment',function(live) if ForeverCompanionQuestRewards then ForeverCompanionQuestRewards.Open(live) end end)
 end
 local details=ForeverCompanionQuestLocations.Details(fresh);local targets=ForeverCompanionQuestWaypoints.Targets(fresh)
 local c=J.Coverage(fresh,targets,details)
 local lines={'NEXT STEP',ForeverCompanionLevelingPlan.NextStep(fresh),'','LOCATION COVERAGE / references are not live verification',c.matched..' matched · '..c.review..' need an area choice · '..c.missing..' missing / '..c.unfinished..' unfinished steps',c.pickups..' pickup references · '..c.turnins..' turn-in references','',details.source or 'No matching quest database reference. In-game quest instructions take priority.','Prerequisites: '..(#(details.prerequisites or {})>0 and 'Review conditions in Quest details' or 'Not documented; this does not prove none apply'),'','RECENT QUEST ACTIVITY'}
 for i=1,math.min(4,#J.history) do local e=J.history[i];lines[#lines+1]=e.event..' · '..e.title end
 if #J.history==0 then lines[#lines+1]='Activity will appear after successful quest updates.' end
 heading:SetText('QUEST INTELLIGENCE · '..fresh.title);body:SetText(table.concat(lines,'\n'));status:SetText('Choose directions deliberately. No route is started automatically.');panel:Show();return true
end
