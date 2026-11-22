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
local panel,heading,selected,status,nextStep,metrics,activity,empty
local function create()
 local U=ForeverCompanionInterface
 local name='ForeverCompanionQuestIntelligence'
 panel=CreateFrame('Frame',name,UIParent,'BackdropTemplate')
 panel:SetSize(680,444);panel:SetPoint('CENTER');panel:SetFrameStrata('DIALOG')
 U.Surface(panel);U.PreparePanel(panel,name,680,444);
 ForeverCompanionVisualTheme.EnvironmentArt(panel,'TOPRIGHT',-2,-2,412,53,'Quests',.76,.086,'BORDER',1);U.CloseButton(panel,function() panel:Hide() end)
 local function text(parent,x,y,w,size)
  local label=U.Text(parent,size);label:SetPoint('TOPLEFT',x,y);label:SetWidth(w);return label
 end
 heading=text(panel,16,-12,610,18);heading:SetHeight(40);heading:SetWordWrap(true);heading:SetJustifyV('TOP')
 local card=CreateFrame('Frame',nil,panel);card:SetPoint('TOPLEFT',16,-57);card:SetSize(648,68);U.Surface(card)
 local label=text(card,12,-8,610,11);label:SetText('Next step');label:SetTextColor(unpack(U.palette.muted))
 nextStep=text(card,12,-27,624,15);nextStep:SetHeight(38);nextStep:SetWordWrap(true);nextStep:SetJustifyV('TOP')
 card:EnableMouse(true);U.SetHoverHelp(card,'Next step',function() return nextStep:GetText() end)
 metrics={
  U.MetricTile(panel,16,-136,208,'Matched areas','Unfinished steps with a matched location.'),
  U.MetricTile(panel,236,-136,208,'Choose an area','Unfinished steps that need a location choice.'),
  U.MetricTile(panel,456,-136,208,'Missing location','Unfinished steps without a matched location.'),
 }
 text(panel,16,-213,460,13):SetText('Recent quest activity')
 activity={}
 for i=1,4 do
  local row=CreateFrame('Frame',nil,panel);row:SetPoint('TOPLEFT',16,-236-(i-1)*27);row:SetSize(648,24)
  U.Surface(row,{background=U.palette.surface,flat=true})
  row.quest=text(row,9,-3,430,12)
  row.event=text(row,447,-3,191,11);row.event:SetJustifyH('RIGHT');row.event:SetTextColor(unpack(U.palette.accent))
  row:EnableMouse(true);U.SetHoverHelp(row,'Quest update',function() return row.quest:GetText()..'\n'..row.event:GetText() end)
  activity[i]=row
 end
 empty=text(panel,17,-243,644,12);empty:SetText('No quest updates recorded')
 status=text(panel,16,-353,648,11);status:SetHeight(35);status:SetWordWrap(true)
 local function button(x,y,w,label,help,action)
  local b=U.Button(panel);b:SetPoint('TOPLEFT',x,y);b:SetSize(w,25);b:SetText(label)
  U.SetHoverHelp(b,label,help)
  b:SetScript('OnClick',function()
   local live=J.Resolve(selected)
   if not live then status:SetText('Quest changed or scan unavailable. Reopen this view.');return end
   action(live)
  end)
 end
 button(529,-207,135,'Location sources','Review coverage, prerequisites and reference data for this quest.',function(live)
  local details=ForeverCompanionQuestLocations.Details(live)
  local c=J.Coverage(live,ForeverCompanionQuestWaypoints.Targets(live),details)
  ForeverCompanionReferenceWorkspace.Open(live.title,{
   {title='Map coverage',body=c.matched..' matched, '..c.review..' need an area choice, '..c.missing..' missing / '..c.unfinished..' unfinished steps\n\n'..c.pickups..' pickup references / '..c.turnins..' turn-in references'},
   {title='Location sources',body=details.source or 'No matching quest database reference. In-game quest instructions take priority.'},
   {title='Prerequisites',body=#(details.prerequisites or {})>0 and 'Review conditions in Quest details.' or 'Prerequisites are undocumented. Confirm with the giver.'},
  })
 end)
 button(16,-403,148,'Focus quest','Select this quest in your journal and tracker.',function(live)
  local _,msg=J.Focus(live);status:SetText(msg)
  if ForeverCompanionQuestTracker then ForeverCompanionQuestTracker.Refresh() end
 end)
 button(179,-403,148,'Next objective','Start directions for the next objective with a usable location.',function(live)
  status:SetText(ForeverCompanionObjectiveRoute.NavigateNext(live))
 end)
 button(342,-403,148,'Quest details','Open the quest in the main journal.',function(live)
  ForeverCompanionOpenQuestGuide(live.id);panel:Hide()
 end)
 button(505,-403,159,'Reward equipment','Compare equipment offered by this quest.',function(live)
  if ForeverCompanionQuestRewards then ForeverCompanionQuestRewards.Open(live) end
 end)
end
function J.Show(q)
 local fresh=J.Resolve(q)
 if not fresh then return false end
 selected={id=fresh.id,title=fresh.title}
 if not panel then create() end
 local details=ForeverCompanionQuestLocations.Details(fresh)
 local c=J.Coverage(fresh,ForeverCompanionQuestWaypoints.Targets(fresh),details)
 heading:SetText(fresh.title)
 nextStep:SetText(ForeverCompanionLevelingPlan.NextStep(fresh))
 metrics[1].value:SetText(c.matched);metrics[2].value:SetText(c.review);metrics[3].value:SetText(c.missing)
 for i,row in ipairs(activity) do
  local entry=J.history[i];row:SetShown(entry~=nil)
  if entry then row.quest:SetText(entry.title);row.event:SetText(entry.event) end
 end
 empty:SetShown(#J.history==0)
 status:SetText('');panel:Show();return true
end
