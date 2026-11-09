-- A field guide grounded in live objectives and explicitly matched locations.
local G={page=1}
ForeverCompanionQuestFieldGuide=G
local root,title,summary,empty,rows,detailPanel,detailTitle,detailLocation,detailSource,detailHint,message,go,cycle,previous,nextPage,counter,mapButton
local panelHeight=490
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
function G.Steps(quest,targets)
 local result={}
 if not quest then return result end
 if quest.complete then result[1]={index=0,text='Return to the quest giver',known=true,done=false,turnin=true,targets={}}
 else
  for i,text in ipairs(quest.objectives or {}) do
   local state=(quest.objectiveStates or {})[i] or {}
   local current,required=state.current,state.required
   local ratio=finite(current) and finite(required) and current>=0 and required>0 and math.max(0,math.min(1,current/required)) or nil
   result[#result+1]={index=i,text=text,known=state.known==true,done=state.known==true and state.done==true,kind=state.kind,current=current,required=required,ratio=ratio,targets={}}
  end
 end
 for _,step in ipairs(result) do
  local seen={}
  if not step.done then for _,t in ipairs(targets or {}) do
   local matched=step.turnin and t.kind=='turn-in' or not step.turnin and (t.objectiveIndex==step.index or (not t.objectiveIndex and t.objective==step.text))
   if matched and valid(t) and not seen[key(t)] then seen[key(t)]=true;step.targets[#step.targets+1]=t end
  end end
 end
 return result
end
function G.Progress(quest)
 local done,known,total=0,0,#(quest and quest.objectives or {})
 for i=1,total do local state=(quest.objectiveStates or {})[i];if state and state.known then known=known+1;if state.done then done=done+1 end end end
 return done,total,known
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
 text(root,16,-12,400,'QUEST DETAILS',16)
 local back=U.Button(root);back:SetSize(110,25);back:SetPoint('TOPRIGHT',-200,-12);back:SetText('Back to list');back:SetScript('OnClick',function() if ForeverCompanionShowQuestList then ForeverCompanionShowQuestList() end end)
 mapButton=U.Button(root);mapButton:SetPoint('TOPRIGHT',-16,-12);mapButton:SetSize(174,25);mapButton:SetText('View quest map')
 mapButton:SetScript('OnClick',function() if selectedQuest and ForeverCompanionQuestPlanner.IsSupported() then message:SetText(ForeverCompanionQuestWaypoints.Show(selectedQuest)) end end)
 title=text(root,16,-45,738,'Choose an active quest',14)
 summary=text(root,16,-72,738,'',11)
 rows={}
 for i=1,4 do
  local row=CreateFrame('Button',nil,root);row:SetPoint('TOPLEFT',16,-101-(i-1)*47);row:SetSize(738,43);row.bg=U.Surface(row)
  row.title=text(row,10,-4,550,'',12);row.title:SetHeight(32);row.title:SetWordWrap(true)
  row.state=text(row,568,-5,158,'',11);row.state:SetJustifyH('RIGHT')
  row.locations=text(row,568,-24,158,'',10);row.locations:SetJustifyH('RIGHT')
  row.progress=CreateFrame('StatusBar',nil,row);row.progress:SetPoint('BOTTOMLEFT',10,1);row.progress:SetSize(530,2)
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
 empty=text(root,32,-105,706,'Objective text is unavailable. Check the in-game quest log.',13);empty:SetWordWrap(true);empty:SetHeight(44);empty:SetJustifyH('CENTER')
 local detail=CreateFrame('Frame',nil,root);detail:SetPoint('TOPLEFT',16,-301);detail:SetSize(738,135);U.Surface(detail)
 detailPanel=detail
 detailTitle=text(detail,12,-10,554,'',13);detailTitle:SetHeight(30);detailTitle:SetWordWrap(true)
 detailLocation=text(detail,12,-44,554,'',12)
 detailSource=text(detail,12,-66,554,'',11)
 detailHint=text(detail,12,-86,554,'',11);detailHint:SetWordWrap(true);detailHint:SetHeight(38)
 go=U.Button(detail);go:SetPoint('TOPRIGHT',-12,-12);go:SetSize(142,26);go:SetText('Navigate to objective')
 go:SetScript('OnClick',function()
  local step=steps[selectedStep];local t=step and step.targets[choice]
  if G.NeedsReview(step) and not areaChosen then message:SetText('Choose an area first. These locations disagree, so no destination has been picked for you.');return end
  local planner=ForeverCompanionQuestPlanner
  if not t or not planner.IsSupported() then message:SetText('Open the quest log to refresh objective information.');return end
  local stop={quest=selectedQuest,objectiveIndex=step.index,turnin=step.turnin,target=t}
  local quest,index,target=ForeverCompanionObjectiveRoute.Resolve(stop,planner.GetLive(),ForeverCompanionQuestWaypoints.Targets)
  if not target then G.Refresh();message:SetText('This objective or location changed. Choose an unfinished objective again.');return end
  planner.Select(index)
  message:SetText(ForeverCompanionQuestWaypoints.Navigate(target,true,quest.title,quest.id))
 end)
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
 message=text(root,16,-439,738,'',11)
 previous=U.Button(root);previous:SetPoint('BOTTOMLEFT',16,9);previous:SetSize(100,25);previous:SetText('Previous')
 nextPage=U.Button(root);nextPage:SetPoint('BOTTOMRIGHT',-16,9);nextPage:SetSize(100,25);nextPage:SetText('Next')
 previous:SetScript('OnClick',function() G.page=math.max(1,G.page-1);G.Refresh() end)
 nextPage:SetScript('OnClick',function() G.page=G.page+1;G.Refresh() end)
 counter=text(root,132,-466,500,'',11);counter:SetJustifyH('CENTER')
end
function G.Refresh()
 if not root or not root:IsShown() then return end
 local planner=ForeverCompanionQuestPlanner
 local q=planner.GetSelected();selectedQuest=q
 local identity=q and (q.id or q.title)
 local changed=identity~=questKey
 if changed then questKey=identity;selectedStep=1;G.page=1;targetKey=nil;choice=1;areaChosen=false;message:SetText('') end
 steps=G.Steps(q,q and ForeverCompanionQuestWaypoints.Targets(q) or {})
 if changed then for i,step in ipairs(steps) do if not step.done then selectedStep=i;G.page=math.floor((i-1)/4)+1;break end end end
 local detailTop=113+47*math.max(1,math.min(4,#steps))
 panelHeight=detailTop+189;root:SetHeight(panelHeight)
 detailPanel:ClearAllPoints();detailPanel:SetPoint('TOPLEFT',16,-detailTop)
 message:ClearAllPoints();message:SetPoint('TOPLEFT',16,-detailTop-138)
 counter:ClearAllPoints();counter:SetPoint('TOPLEFT',132,-panelHeight+24)
 selectedStep=math.max(1,math.min(selectedStep,#steps))
 title:SetText(q and (q.title..(showDetails and q.id and (' · #'..q.id) or '')) or 'Choose an active quest')
 local done,total,known=G.Progress(q)
 summary:SetText(not planner.IsSupported() and 'Open your in-game quest log to refresh this quest before traveling.' or (q and q.complete and 'All done! Your next step is to return to the quest giver.' or (done..' of '..total..' tasks complete'..(known<total and ' · Some progress needs checking in your quest log.' or ' · Choose a task to see where to go.'))))
 local pages=math.max(1,math.ceil(#steps/4));G.page=math.max(1,math.min(G.page,pages))
 for i,row in ipairs(rows) do
  local absolute=(G.page-1)*4+i;local step=steps[absolute]
  row.step=step;row:SetShown(step~=nil)
  if step then
   row.title:SetText(step.text);row.selected=absolute==selectedStep
   ForeverCompanionVisualTheme.SelectRow(row,row.bg,row.selected)
   local counts=finite(step.current) and finite(step.required) and step.required>0 and (' · '..step.current..'/'..step.required) or ''
   row.state:SetText((step.turnin and 'Ready to turn in' or (step.done and 'Complete' or (step.known and 'In progress' or 'Progress unknown')))..counts)
   row.state:SetTextColor(step.done and .48 or .8,step.done and .88 or .83,step.done and .58 or .87)
   row.locations:SetText(step.done and 'Done' or (G.NeedsReview(step) and 'Choose an area below' or (#step.targets>0 and 'Search area available' or 'Read quest instructions')))
   row.progress:SetShown(step.ratio~=nil);row.progress:SetValue(step.ratio or 0)
  end
 end
 empty:SetShown(#steps==0)
 local step=steps[selectedStep]
 choice=math.min(choice,step and math.max(1,#step.targets) or 1)
 if step and targetKey then
  local found=false;for i,t in ipairs(step.targets) do if key(t)==targetKey then choice=i;found=true;break end end
  if not found then areaChosen=false;targetKey=nil end
 end
 local t=step and step.targets[choice]
 if t then targetKey=key(t) end
 detailTitle:SetText(step and (step.turnin and 'Next: return to the quest giver' or (step.done and 'Task complete' or 'Your next step')) or 'Choose a quest to get started')
 local info=t and C_Map and read(C_Map.GetMapInfo,t.map)
 detailLocation:SetText(t and ((t.label or 'Search area')..' · '..(info and info.name or ('Map '..t.map))..(showDetails and (' · %.1f, %.1f'):format(t.x*100,t.y*100) or '')) or 'We do not have a reliable location for this task yet.')
 detailSource:SetText(t and (showDetails and ((t.source or 'Unknown source')..' · '..ForeverCompanionQuestWaypoints.Describe(t)) or 'This is a search area. The quest target may move or the data may be out of date.') or 'Read the quest instructions in your game’s quest log before traveling.')
 detailHint:SetText(step and (step.done and 'Choose an unfinished task above to continue.' or (G.NeedsReview(step) and not areaChosen and 'These locations cover different areas. Choose an area first; no arrow will start until you choose.' or (step.turnin and 'Speak to the quest giver when you arrive.' or (instructions[step.kind] or 'Follow the instructions for this task.')))) or 'Select a quest in the active list above to begin.')
 cycle:SetText(t and (areaChosen and 'Change area' or 'Choose area') or 'No area known')
 local supported=planner.IsSupported()
 cycle:SetShown(step~=nil and #G.Areas(step)>1);cycle:SetEnabled(supported and step~=nil and #step.targets>1);go:SetEnabled(supported and t~=nil and (not G.NeedsReview(step) or areaChosen))
 go:SetText(step and step.turnin and 'Go to quest giver' or 'Go to search area')
 mapButton:SetEnabled(supported and q~=nil)
 previous:SetEnabled(G.page>1);nextPage:SetEnabled(G.page<pages);counter:SetText('Objectives · '..G.page..' / '..pages)
end
function G.Show(show,parent,offset)
 if not root then return end
 root:SetShown(show)
 if show then root:ClearAllPoints();root:SetPoint('TOPLEFT',parent,'TOPLEFT',8,-offset);G.Refresh() end
end
function G.GetHeight() return panelHeight+14 end
