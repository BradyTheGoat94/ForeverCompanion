-- A field guide grounded in live objectives and explicitly matched locations.
local G={page=1}
ForeverCompanionQuestFieldGuide=G
local root,title,summary,empty,rows,detailPanel,detailTitle,detailLocation,detailSource,detailHint,message,go,cycle,previous,nextPage,counter,mapButton,overallProgress,overallLabel
local itemSources
local panelHeight=490
local contextPanel,contextText,contextButton,showContext,pickupButton
local selectedQuest,selectedStep,steps,questKey,targetKey,choice= nil,1,{},nil,nil,1
local areaChosen,showDetails=false,false
local function read(fn,...)
 if type(fn)~='function' then return end
 local ok,a=pcall(fn,...);if ok then return a end
end
local function finite(n)
 return not (issecretvalue and issecretvalue(n)) and type(n)=='number' and n==n and math.abs(n)<math.huge
end
local function valid(t)
 return type(t)=='table' and finite(t.map) and t.map>0 and finite(t.x) and t.x>=0 and t.x<=1 and finite(t.y) and t.y>=0 and t.y<=1
end
local function key(t) return t.map..':'..t.x..':'..t.y end
local function safeSupported(planner)
 if not planner or type(planner.IsSupported)~='function' then return false end
 return read(planner.IsSupported)==true
end
local function safeTargets(q)
 local waypoints=ForeverCompanionQuestWaypoints
 if not q or not waypoints or type(waypoints.Targets)~='function' then return {} end
 local targets=read(waypoints.Targets,q)
 return type(targets)=='table' and targets or {}
end
-- This describes evidence, not a guarantee that a quest target is correct.
function G.LocationStatus(step)
 if not step or not step.targets or #step.targets==0 then
  return 'NO VERIFIED WAYPOINT', 'Use the in-game quest log. No matching coordinates are available.'
 end
 if G.NeedsReview(step) then
  return 'MULTIPLE POSSIBLE AREAS', 'Choose a search area before starting directions.'
 end
 local target=step.targets[1]
 if target.reference==true then
  return 'REFERENCE LOCATION', 'This location is from reference data. Confirm it on the map.'
 end
 return 'MATCHED SEARCH AREA', 'This is an objective search area, not a guaranteed NPC position.'
end
local function progressText(step)
 if step.turnin then return 'Ready to turn in' end
 if step.done then return 'Completed' end
 if step.ratio then return ('%d%% complete'):format(math.floor(step.ratio*100+.5)) end
 if step.known then return 'In progress' end
 return 'Check quest log'
end
function G.Steps(quest,targets)
 local result={}
 if type(quest)~='table' then return result end
 if quest.complete then result[1]={index=0,text='Return to the quest giver',known=true,done=false,turnin=true,targets={}}
 else
  for i,text in ipairs(type(quest.objectives)=='table' and quest.objectives or {}) do
   local state=(type(quest.objectiveStates)=='table' and quest.objectiveStates or {})[i]
   state=type(state)=='table' and state or {}
   local current,required=state.current,state.required
   local ratio=finite(current) and finite(required) and current>=0 and required>0 and math.max(0,math.min(1,current/required)) or nil
   if state.done==true and state.known==true then ratio=1 end
   result[#result+1]={index=i,text=type(text)=='string' and text or 'Review objective in your quest log',known=state.known==true,done=state.known==true and state.done==true,kind=state.kind,current=current,required=required,ratio=ratio,targets={}}
  end
 end
 for _,step in ipairs(result) do
  local seen={}
  if not step.done then for _,t in ipairs(type(targets)=='table' and targets or {}) do
   if type(t)=='table' then
   local matched=step.turnin and t.kind=='turn-in' or not step.turnin and (t.objectiveIndex==step.index or (not t.objectiveIndex and t.objective==step.text))
   if matched and valid(t) and not seen[key(t)] then seen[key(t)]=true;step.targets[#step.targets+1]=t end
   end
  end end
 end
 return result
end
function G.Progress(quest)
 local q=type(quest)=='table' and quest or {}
 local objectives=type(q.objectives)=='table' and q.objectives or {}
 local states=type(q.objectiveStates)=='table' and q.objectiveStates or {}
 local done,known,total=0,0,#objectives
 for i=1,total do local state=states[i];if type(state)=='table' and state.known==true then known=known+1;if state.done==true then done=done+1 end end end
 return done,total,known
end
-- Equal-weight objective progress; never treat an unknown objective as zero.
function G.ProgressFraction(quest)
 if type(quest)~='table' then return end
 if quest.complete==true then return 1 end
 local steps=G.Steps(quest,{})
 if #steps==0 then return end
 local sum=0
 for _,step in ipairs(steps) do
  if not step.known then return end
  sum=sum+(step.ratio or (step.done and 1 or 0))
 end
 return sum/#steps
end
function G.NextStep(quest,targets)
 for _,step in ipairs(G.Steps(quest,targets)) do if not step.done then return step end end
end
-- Widely separated or cross-map references need a deliberate location choice.
-- A quest-log zone is not a safe constraint: travel quests can leave that zone.
function G.NeedsReview(step)
 local first=step and step.targets and step.targets[1]
 if not first then return false end
 for _,t in ipairs(step.targets) do
  if t.map~=first.map or (t.x-first.x)^2+(t.y-first.y)^2>.35^2 then return true end
 end
 return false
end
function G.Areas(step,map,x,y)
 local groups={}
 for i,t in ipairs(step and step.targets or {}) do
  local group
  for _,g in ipairs(groups) do if g.map==t.map and (t.x-g.x)^2+(t.y-g.y)^2<=.15^2 then group=g;break end end
  if not group then group={map=t.map,x=t.x,y=t.y,index=i};groups[#groups+1]=group end
  if t.map==map and finite(x) and finite(y) then
   local distance=(t.x-x)^2+(t.y-y)^2
   if not group.distance or distance<group.distance then group.index=i;group.distance=distance end
  end
 end
 return groups
end
local reportPanel,reportEdit
function G.CopyReport(q)
 if not reportPanel then
  local U=ForeverCompanionInterface
  reportPanel=CreateFrame('Frame','ForeverCompanionQuestLocationReport',UIParent);reportPanel:SetSize(640,160);reportPanel:SetPoint('CENTER');reportPanel:SetFrameStrata('DIALOG');U.Surface(reportPanel);U.PreparePanel(reportPanel,'ForeverCompanionQuestLocationReport',640,160)
  local heading=U.Text(reportPanel,15);heading:SetPoint('TOPLEFT',16,-14);heading:SetText('Quest location report · saved on this character')
  local hint=U.Text(reportPanel,11);hint:SetPoint('TOPLEFT',16,-44);hint:SetText('Select the text and press Ctrl+C to share it. Nothing is sent automatically.')
  reportEdit=U.EditBox(reportPanel);reportEdit:SetSize(608,32);reportEdit:SetPoint('TOPLEFT',16,-70)
  reportEdit:SetScript('OnEscapePressed',function() reportPanel:Hide() end)
  local close=U.Button(reportPanel);close:SetSize(90,25);close:SetPoint('BOTTOMRIGHT',-16,12);close:SetText('Close');close:SetScript('OnClick',function() reportPanel:Hide() end)
 end
 reportEdit:SetText(ForeverCompanionQuestLocations.ReportText(q):gsub('\n',' / '));reportPanel:Show();reportEdit:SetFocus();if reportEdit.HighlightText then reportEdit:HighlightText() end
end
local instructions={monster='Defeat the enemies named in the objective.',item='Collect the requested item. Listed drop sources are references, not guaranteed drops.',object='Interact with the object named in the objective.',event='Follow the quest instructions in the reported area.'}
local function text(parent,x,y,width,value,size)
 local f=ForeverCompanionInterface.Text(parent,size or 12)
 f:SetPoint('TOPLEFT',parent,'TOPLEFT',x,y);f:SetWidth(width);f:SetText(value or '');return f
end
function G.Create(parent)
 local U=ForeverCompanionInterface
 root=CreateFrame('Frame','ForeverCompanionQuestFieldGuidePanel',parent);root:SetSize(770,490);U.Surface(root);root:Hide()
 text(root,16,-12,300,'QUEST DETAILS',16)
 contextButton=U.Button(root);contextButton:SetPoint('TOPLEFT',330,-12);contextButton:SetSize(126,25);contextButton:SetText('Giver and chain')
 contextButton:SetScript('OnClick',function() showContext=not showContext;if ForeverCompanionRefresh then ForeverCompanionRefresh() else G.Refresh() end end)
 local back=U.Button(root);back:SetSize(110,25);back:SetPoint('TOPRIGHT',-200,-12);back:SetText('Back to list');back:SetScript('OnClick',function() if ForeverCompanionShowQuestList then ForeverCompanionShowQuestList() end end)
 mapButton=U.Button(root);mapButton:SetPoint('TOPRIGHT',-16,-12);mapButton:SetSize(174,25);mapButton:SetText('View quest map')
 mapButton:SetScript('OnClick',function() if not selectedQuest then return end
  local planner=ForeverCompanionQuestPlanner
  local waypoints=ForeverCompanionQuestWaypoints
  if not safeSupported(planner) or not waypoints or type(waypoints.Show)~='function' then
   message:SetText('Map directions are not available. Check the game quest log.');return
  end
  local ok,result=pcall(waypoints.Show,selectedQuest)
  message:SetText(ok and (result or 'Check the world map.') or 'Map directions could not be opened.') end)
 title=text(root,16,-45,738,'Choose an active quest',14)
 summary=text(root,16,-72,738,'',11)
 overallProgress=CreateFrame('StatusBar',nil,root)
 overallProgress:SetPoint('TOPLEFT',16,-94);overallProgress:SetSize(738,5)
 overallProgress:SetStatusBarTexture('Interface\\Buttons\\WHITE8X8')
 overallProgress:SetStatusBarColor(.24,.72,.82,1);overallProgress:SetMinMaxValues(0,1)
 overallLabel=text(root,16,-105,738,'',10)
 rows={}
 for i=1,4 do
  local row=CreateFrame('Button',nil,root);row:SetPoint('TOPLEFT',16,-126-(i-1)*65);row:SetSize(738,59);row.bg=U.Surface(row)
  row.title=text(row,10,-5,480,'',12);row.title:SetHeight(36);row.title:SetWordWrap(true)
  row.state=text(row,500,-6,226,'',11);row.state:SetJustifyH('RIGHT')
  row.locations=text(row,500,-29,226,'',10);row.locations:SetJustifyH('RIGHT')
  row.progress=CreateFrame('StatusBar',nil,row);row.progress:SetPoint('BOTTOMLEFT',10,5);row.progress:SetSize(718,3)
  row.progress:SetStatusBarTexture('Interface\\Buttons\\WHITE8X8');row.progress:SetStatusBarColor(.48,.76,.58,1);row.progress:SetMinMaxValues(0,1)
  row:SetScript('OnClick',function()
   if row.step then selectedStep=(G.page-1)*4+i;targetKey=nil;choice=1;areaChosen=false;message:SetText('');G.Refresh() end
  end)
  row:SetScript('OnEnter',function(self)
   self.bg:SetColorTexture(.075,.09,.115,1)
   if GameTooltip and self.step then GameTooltip:SetOwner(self,'ANCHOR_RIGHT');GameTooltip:SetText(self.step.text);GameTooltip:AddLine('Click to inspect locations and the next action.',.75,.82,.9,true);GameTooltip:Show() end
  end)
  row:SetScript('OnLeave',function(self) ForeverCompanionVisualTheme.SelectRow(self,self.bg,self.selected);if GameTooltip then GameTooltip:Hide() end end)
  rows[i]=row
 end
 empty=text(root,32,-131,706,'Objective text is unavailable. Check the in-game quest log.',13);empty:SetWordWrap(true);empty:SetHeight(44);empty:SetJustifyH('CENTER')
 local detail=CreateFrame('Frame',nil,root);detail:SetPoint('TOPLEFT',16,-301);detail:SetSize(738,166);U.Surface(detail)
 detailPanel=detail
 detailTitle=text(detail,12,-10,554,'',13);detailTitle:SetHeight(36);detailTitle:SetWordWrap(true)
 detailLocation=text(detail,12,-48,554,'',12);detailLocation:SetWordWrap(true);detailLocation:SetHeight(32)
 detailSource=text(detail,12,-84,554,'',11);detailSource:SetWordWrap(true);detailSource:SetHeight(30)
 detailHint=text(detail,12,-119,714,'',11);detailHint:SetWordWrap(true);detailHint:SetHeight(38)
 go=U.Button(detail);go:SetPoint('TOPRIGHT',-12,-12);go:SetSize(142,26);go:SetText('Navigate to objective')
 go:SetScript('OnClick',function()
  local step=steps[selectedStep];local t=step and step.targets[choice]
  if G.NeedsReview(step) and not areaChosen then message:SetText('Choose an area first. These locations disagree, so no destination has been picked for you.');return end
  local planner=ForeverCompanionQuestPlanner
  if not t or not safeSupported(planner) then message:SetText('Directions unavailable. Open the game quest log to check this objective.');return end
  local stop={quest=selectedQuest,objectiveIndex=step.index,turnin=step.turnin,target=t}
  local route=ForeverCompanionObjectiveRoute
  local waypoints=ForeverCompanionQuestWaypoints
  if not route or type(route.Resolve)~='function' or not waypoints or type(waypoints.Navigate)~='function' then
   message:SetText('Navigation is not available. Open the game map to find this objective.');return
  end
  local live=type(planner.GetLive)=='function' and read(planner.GetLive) or {}
  local ok,quest,index,target=pcall(route.Resolve,stop,live,waypoints.Targets)
  if not ok then message:SetText('Could not verify this destination. Please check the game map.');return end
  if not target then G.Refresh();message:SetText('This objective or location changed. Choose an unfinished objective again.');return end
  if type(planner.Select)=='function' and index then pcall(planner.Select,index) end
  local navigated,result=pcall(waypoints.Navigate,target,true,quest and quest.title or '',quest and quest.id)
  message:SetText(navigated and (result or 'Destination sent to the map. Check the marker before traveling.') or 'Could not start directions. Check your world map.')
 end)
 itemSources=U.Button(detail);itemSources:SetPoint('TOPRIGHT',-12,-121);itemSources:SetSize(142,25);itemSources:SetText('Item sources')
 itemSources:SetScript('OnClick',function()
  local step=steps[selectedStep];local item=selectedQuest and step and ForeverCompanionQuestLocations.ObjectiveItem(selectedQuest,step.index)
  if not item or item.done then message:SetText('No unfinished item objective is uniquely matched. Inspect the quest log.');return end
  local ok,result=ForeverCompanionMaterialFinder.OpenQuestItem(selectedQuest.id,step.index,item.id,selectedQuest.title)
  message:SetText(result or (ok and 'Item references opened.' or 'Item sources are unavailable.'))
 end)
 itemSources:SetScript('OnEnter',function(self)
  if GameTooltip then GameTooltip:SetOwner(self,'ANCHOR_RIGHT');GameTooltip:SetText('Quest item sources');GameTooltip:AddLine('Requires a uniquely matched live item objective and compatible Forever reference data. Drops, objects and vendors remain references; availability is not guaranteed.',.8,.85,.9,true);GameTooltip:Show() end
 end)
 itemSources:SetScript('OnLeave',function() if GameTooltip then GameTooltip:Hide() end end)
 cycle=U.Button(detail);cycle:SetPoint('TOPRIGHT',-12,-49);cycle:SetSize(142,25)
 local function areaMenu(page)
  local step=steps[selectedStep];if not step then return end
  local map=C_Map and read(C_Map.GetBestMapForUnit,'player');local pos=map and read(C_Map.GetPlayerMapPosition,map,'player')
  local x,y;if pos and type(pos.GetXY)=='function' then local ok,a,b=pcall(pos.GetXY,pos);if ok then x,y=a,b end end
  local areas=G.Areas(step,map,x,y);local entries={};page=page or 1
  for i=(page-1)*8+1,math.min(page*8,#areas) do
   local index=areas[i].index;local t=step.targets[index];local info=C_Map and read(C_Map.GetMapInfo,t.map)
   entries[#entries+1]={label=(info and info.name or ('Map '..t.map))..(' · %.1f, %.1f'):format(t.x*100,t.y*100),selected=areaChosen and choice==index,action=function() choice=index;targetKey=key(t);areaChosen=true;message:SetText('Area selected. Check the location below, then choose Go.');G.Refresh() end}
  end
  if page>1 then entries[#entries+1]={label='Previous areas',action=function() areaMenu(page-1) end} end
  if page*8<#areas then entries[#entries+1]={label='More areas',action=function() areaMenu(page+1) end} end
  U.Menu(cycle,'CHOOSE A SEARCH AREA',entries,nil,340)
 end
 cycle:SetScript('OnClick',function() areaMenu(1) end)
 local locationOptions=U.Button(detail);locationOptions:SetPoint('TOPRIGHT',-12,-86);locationOptions:SetSize(142,25);locationOptions:SetText('Location options')
 locationOptions:SetScript('OnClick',function()
  local q=selectedQuest;local step=steps[selectedStep];local t=step and step.targets[choice]
  U.Menu(locationOptions,'QUEST LOCATION',{
   {label=showDetails and 'Hide source and coordinates' or 'Show source and coordinates',action=function() showDetails=not showDetails;G.Refresh() end},
   {label='Wrong destination: exclude this point',enabled=q~=nil and t~=nil and t.reference==true,action=function()
    message:SetText(ForeverCompanionQuestLocations.Report(q,t));targetKey=nil;choice=1;areaChosen=false;G.Refresh()
   end},
   {label='Copy saved location reports',enabled=q~=nil,action=function() G.CopyReport(q) end},
   {label='Restore excluded locations for this quest',enabled=q~=nil,action=function() ForeverCompanionQuestLocations.Restore(q);G.Refresh();message:SetText('Excluded locations restored for this quest.') end},
  },nil,380)
 end)
 contextPanel=CreateFrame('Frame',nil,root);contextPanel:SetSize(738,180);U.Surface(contextPanel)
 contextText=text(contextPanel,12,-12,714,'',12);contextText:SetWordWrap(true)
 pickupButton=U.Button(contextPanel);pickupButton:SetSize(180,25);pickupButton:SetPoint('BOTTOMLEFT',12,12);pickupButton:SetText('Givers and turn-in')
 pickupButton:SetScript('OnClick',function(self)
  if not safeSupported(ForeverCompanionQuestPlanner) then message:SetText('Quest scan unavailable. Open your quest log before requesting directions.');return end
  local quest=selectedQuest
  local locations=ForeverCompanionQuestLocations.GiverTargets(quest);local entries={}
  for i=1,#locations do
   local t=locations[i];local info=C_Map and read(C_Map.GetMapInfo,t.map)
   entries[#entries+1]={label=(t.kind=='turn-in' and 'Turn-in: ' or 'Pickup: ')..(t.label or 'Quest giver')..' · '..(info and info.name or ('Map '..t.map))..(' %.1f, %.1f (reference)'):format(t.x*100,t.y*100),action=function()
    local planner=ForeverCompanionQuestPlanner;local current=read(planner.GetSelected)
    local fresh=safeSupported(planner) and current and current.id==quest.id and ForeverCompanionQuestLocations.ResolveGiver(current,t)
    message:SetText(fresh and ForeverCompanionQuestWaypoints.Navigate(fresh,true,current.title,current.id) or 'Quest selection or reference changed. Reopen the location menu.')
   end}
  end
  U.PagedMenu(self,'GIVER REFERENCES / NOT LIVE VERIFIED',entries,nil,480)
 end)
 message=text(root,16,-439,738,'',11)
 previous=U.Button(root);previous:SetPoint('BOTTOMLEFT',16,9);previous:SetSize(100,25);previous:SetText('Previous')
 nextPage=U.Button(root);nextPage:SetPoint('BOTTOMRIGHT',-16,9);nextPage:SetSize(100,25);nextPage:SetText('Next')
 previous:SetScript('OnClick',function() G.page=math.max(1,G.page-1);G.Refresh() end)
 nextPage:SetScript('OnClick',function() G.page=G.page+1;G.Refresh() end)
 U.SetHoverHelp(go,'Directions','Start navigation to the selected objective or turn-in.')
 U.SetHoverHelp(mapButton,'Show on world map','Open the map for the current quest and its known locations.')
 U.SetHoverHelp(cycle,'Objective locations','Choose among available points or search areas for this objective.')
 U.SetHoverHelp(itemSources,'Item sources','Find reported drops and vendors for the selected quest item.')
 U.SetHoverHelp(locationOptions,'Location options','Show source details, report a wrong reference, or restore excluded points.')
 U.SetHoverHelp(pickupButton,'Quest givers','Browse reference pickup and turn-in locations.')
 counter=text(root,132,-466,500,'',11);counter:SetJustifyH('CENTER')
end
function G.Refresh()
 if not root or not root:IsShown() then return end
 local planner=ForeverCompanionQuestPlanner
 local q=planner and type(planner.GetSelected)=='function' and read(planner.GetSelected);selectedQuest=q
 local identity=q and (q.id or ((q.title or '')..'\n'..(q.zone or '')))
 local previousStep=steps[selectedStep]
 local changed=identity~=questKey
 if changed then questKey=identity;selectedStep=1;G.page=1;targetKey=nil;choice=1;areaChosen=false;message:SetText('') end
 steps=G.Steps(q,safeTargets(q))
 if not changed and previousStep and not previousStep.done and steps[selectedStep] and steps[selectedStep].done then
  changed=true;targetKey=nil;choice=1;areaChosen=false;message:SetText('Objective complete. Review your next step.')
 end
 if changed then for i,step in ipairs(steps) do if not step.done then selectedStep=i;G.page=math.floor((i-1)/4)+1;break end end end
 local detailTop=138+65*math.max(1,math.min(4,#steps))
 local contextHeight=0
 contextPanel:SetShown(showContext==true and q~=nil)
 if showContext and q then
  contextText:SetText(ForeverCompanionQuestLocations.DetailText(q))
  local height=contextText:GetStringHeight()+4;contextText:SetHeight(height)
  contextHeight=height+62;contextPanel:SetHeight(contextHeight)
  contextPanel:ClearAllPoints();contextPanel:SetPoint('TOPLEFT',16,-detailTop-174)
  pickupButton:SetEnabled(safeSupported(planner) and #ForeverCompanionQuestLocations.GiverTargets(q)>0)
 end
 panelHeight=detailTop+244+contextHeight;root:SetHeight(panelHeight)
 detailPanel:ClearAllPoints();detailPanel:SetPoint('TOPLEFT',16,-detailTop)
 message:ClearAllPoints();message:SetPoint('TOPLEFT',16,-detailTop-178-contextHeight)
 counter:ClearAllPoints();counter:SetPoint('TOPLEFT',132,-panelHeight+24)
 selectedStep=math.max(1,math.min(selectedStep,#steps))
 title:SetText(q and ((q.level and ('[Lv '..q.level..'] ') or '')..(q.title or 'Unnamed quest')..(showDetails and q.id and (' · #'..q.id) or '')) or 'Choose an active quest')
 local done,total,known=G.Progress(q)
 local completed=q and q.complete
 overallProgress:SetShown(total>0 and (known==total or completed))
 overallProgress:SetValue(G.ProgressFraction(q) or 0)
 overallLabel:SetText(not q and 'Select a quest to begin' or (completed and 'READY TO TURN IN' or (total==0 and 'OBJECTIVES UNAVAILABLE' or (known<total and 'PROGRESS PARTIALLY UNKNOWN' or ('OBJECTIVES  '..done..' / '..total..' complete')))))
 summary:SetText(not safeSupported(planner) and 'Quest data is limited. Open your game quest log to refresh.' or (not q and 'Select a quest from My Quests to see its objectives.' or (q.complete and 'Objectives complete · Return to the quest giver.' or (total==0 and 'Objectives not available · Check the game quest log.' or (known==0 and 'Progress not reported · Select an objective for guidance.' or (done..' / '..total..' objectives complete'..(known<total and ' · Some progress unknown' or ' · Select an objective below')))))))
 local pages=math.max(1,math.ceil(#steps/4));G.page=math.max(1,math.min(G.page,pages))
 for i,row in ipairs(rows) do
  local absolute=(G.page-1)*4+i;local step=steps[absolute]
  row.step=step;row:SetShown(step~=nil)
  if step then
   row.title:SetText(step.text);row.selected=absolute==selectedStep
   ForeverCompanionVisualTheme.SelectRow(row,row.bg,row.selected)
   local counts=not step.done and finite(step.current) and finite(step.required) and step.required>0 and (' · '..step.current..'/'..step.required) or ''
   row.state:SetText(progressText(step)..counts)
   row.state:SetTextColor(step.done and .48 or .8,step.done and .88 or .83,step.done and .58 or .87)
   row.locations:SetText(step.done and 'Complete' or G.LocationStatus(step))
   row.progress:SetShown(step.ratio~=nil or step.done)
   row.progress:SetValue(step.done and 1 or (step.ratio or 0))
  end
 end
 empty:SetShown(#steps==0)
 local step=steps[selectedStep]
 choice=math.min(choice,step and math.max(1,#step.targets) or 1)
 if step and targetKey then
  local found=false;for i,t in ipairs(step.targets) do if key(t)==targetKey then choice=i;found=true;break end end
  if not found then areaChosen=false;targetKey=nil end
 end
 local item=q and step and ForeverCompanionQuestLocations.ObjectiveItem(q,step.index)
 local isItem=step and step.kind=='item'
 itemSources:SetShown(isItem==true);itemSources:SetEnabled(safeSupported(planner) and item~=nil and not item.done)
 itemSources:SetText(item and (item.done and 'Item complete' or 'Item sources') or 'No item match')
 detailHint:SetWidth(isItem and 554 or 714)
 local t=step and step.targets[choice]
 if t then targetKey=key(t) end
 detailTitle:SetText(step and (step.turnin and 'NEXT: Return to quest giver' or (step.done and 'OBJECTIVE COMPLETE' or 'NEXT: '..(step.text or 'Review objective'))) or 'Choose a quest to get started')
 local info=t and C_Map and read(C_Map.GetMapInfo,t.map)
 detailLocation:SetText(t and ((t.label or 'Search area')..' · '..(info and info.name or ('Map '..t.map))..(showDetails and (' · %.1f, %.1f'):format(t.x*100,t.y*100) or '')) or 'We do not have a reliable location for this task yet.')
 detailSource:SetText(t and (showDetails and ((t.source or 'Unknown source')..' · '..(ForeverCompanionQuestWaypoints and type(ForeverCompanionQuestWaypoints.Describe)=='function' and (read(ForeverCompanionQuestWaypoints.Describe,t) or 'Source details unavailable') or 'Source details unavailable')) or (t.reference and 'Database reference · not verified in your live client.' or 'Client-reported search area · exact position is not guaranteed.')) or 'Read the quest instructions in your game’s quest log before traveling.')
 local evidence,evidenceHint=G.LocationStatus(step)
 if areaChosen and G.NeedsReview(step) then evidenceHint='Area selected. Confirm the reference on your map.' end
 detailHint:SetText(step and (step.done and 'Complete. Select the next unfinished objective.' or (G.NeedsReview(step) and not areaChosen and evidenceHint or (step.turnin and 'Speak to the quest giver when you arrive. Check your quest log for the correct NPC.' or (instructions[step.kind] or 'Follow the quest objective shown in your game log.'))..'  '..(t and evidenceHint or ''))) or 'Select a quest in your active list to begin.')
 cycle:SetText(t and (areaChosen and 'Change area' or 'Choose area') or 'No area known')
 local supported=safeSupported(planner)
 cycle:SetShown(step~=nil and #G.Areas(step)>1);cycle:SetEnabled(supported and step~=nil and #step.targets>1);go:SetEnabled(supported and t~=nil and (not G.NeedsReview(step) or areaChosen))
 go:SetText(step and step.turnin and 'Find quest giver' or 'Show direction')
 mapButton:SetEnabled(supported and q~=nil)
 mapButton:SetText(q and 'View quest on map' or 'Choose a quest first')
 previous:SetEnabled(G.page>1);nextPage:SetEnabled(G.page<pages);counter:SetText(#steps==0 and 'No objectives reported by the quest log' or ('Objectives '..(((G.page-1)*4)+1)..'–'..math.min(G.page*4,#steps)..' of '..#steps..'  ·  Select a row for details'))
end
function G.Show(show,parent,offset)
 if not root then return end
 root:SetShown(show)
 if show then root:ClearAllPoints();root:SetPoint('TOPLEFT',parent,'TOPLEFT',8,-offset);G.Refresh() end
end
function G.GetHeight() return panelHeight+14 end
