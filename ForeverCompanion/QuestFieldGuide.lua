-- A field guide grounded in live objectives and explicitly matched locations.
local G={page=1}
ForeverCompanionQuestFieldGuide=G
local root,title,summary,empty,rows,detailPanel,detailTitle,detailLocation,detailSource,detailHint,message,go,cycle,previous,nextPage,counter,mapButton
local panelHeight=490
local selectedQuest,selectedStep,steps,questKey,targetKey,choice= nil,1,{},nil,nil,1
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
local instructions={monster='Defeat the enemies named in the objective.',item='Collect the requested item. Listed drop sources are references, not guaranteed drops.',object='Interact with the object named in the objective.',event='Follow the quest instructions in the reported area.'}
local function text(parent,x,y,width,value,size)
 local f=ForeverCompanionInterface.Text(parent,size or 12)
 f:SetPoint('TOPLEFT',parent,'TOPLEFT',x,y);f:SetWidth(width);f:SetText(value or '');return f
end
function G.Create(parent)
 local U=ForeverCompanionInterface
 root=CreateFrame('Frame','ForeverCompanionQuestFieldGuidePanel',parent);root:SetSize(770,490);U.Surface(root);root:Hide()
 text(root,16,-12,500,'QUEST FIELD GUIDE',16)
 mapButton=U.Button(root);mapButton:SetPoint('TOPRIGHT',-16,-12);mapButton:SetSize(174,25);mapButton:SetText('Quest map destination')
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
   if row.step then selectedStep=(G.page-1)*4+i;targetKey=nil;choice=1;message:SetText('');G.Refresh() end
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
  if t and ForeverCompanionQuestPlanner.IsSupported() then message:SetText(ForeverCompanionQuestWaypoints.Navigate(t,true,selectedQuest.title)) end
 end)
 cycle=U.Button(detail);cycle:SetPoint('TOPRIGHT',-12,-49);cycle:SetSize(142,25)
 cycle:SetScript('OnClick',function() local step=steps[selectedStep];if step and #step.targets>1 then choice=choice%#step.targets+1;targetKey=key(step.targets[choice]);message:SetText('');G.Refresh() end end)
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
 if changed then questKey=identity;selectedStep=1;G.page=1;targetKey=nil;choice=1;message:SetText('') end
 steps=G.Steps(q,q and ForeverCompanionQuestWaypoints.Targets(q) or {})
 if changed then for i,step in ipairs(steps) do if not step.done then selectedStep=i;G.page=math.floor((i-1)/4)+1;break end end end
 local detailTop=113+47*math.max(1,math.min(4,#steps))
 panelHeight=detailTop+189;root:SetHeight(panelHeight)
 detailPanel:ClearAllPoints();detailPanel:SetPoint('TOPLEFT',16,-detailTop)
 message:ClearAllPoints();message:SetPoint('TOPLEFT',16,-detailTop-138)
 counter:ClearAllPoints();counter:SetPoint('TOPLEFT',132,-panelHeight+24)
 selectedStep=math.max(1,math.min(selectedStep,#steps))
 title:SetText(q and q.title or 'Choose an active quest')
 local done,total,known=G.Progress(q)
 summary:SetText(not planner.IsSupported() and 'Cached or unavailable quest data. Check the in-game quest log before navigating.' or (q and q.complete and 'Ready to turn in · choose a reported giver below.' or (done..' / '..total..' objectives complete'..(known<total and (' · '..(total-known)..' with unknown progress') or '')..' · Click an objective to inspect its locations.')))
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
   row.locations:SetText(step.done and 'Finished objective' or (#step.targets>0 and (#step.targets..' reported locations') or 'Location not reported'))
   row.progress:SetShown(step.ratio~=nil);row.progress:SetValue(step.ratio or 0)
  end
 end
 empty:SetShown(#steps==0)
 local step=steps[selectedStep]
 choice=math.min(choice,step and math.max(1,#step.targets) or 1)
 if step and targetKey then for i,t in ipairs(step.targets) do if key(t)==targetKey then choice=i;break end end end
 local t=step and step.targets[choice]
 if t then targetKey=key(t) end
 detailTitle:SetText(step and step.text or 'No objective selected')
 local info=t and C_Map and read(C_Map.GetMapInfo,t.map)
 detailLocation:SetText(t and ((t.label or 'Reported location')..' · '..(info and info.name or ('Map '..t.map))..(' · %.1f, %.1f'):format(t.x*100,t.y*100)) or 'No objective-specific location reported')
 detailSource:SetText(t and (t.reference and 'Forever QuestieDB reference · matched to this objective' or 'Client-reported destination') or 'General quest POIs are kept separate from objective-specific locations.')
 detailHint:SetText(step and (step.done and 'This objective is complete. Choose an unfinished objective to continue.' or (step.turnin and 'Return to the listed giver and inspect the turn-in in game.' or (instructions[step.kind] or 'Read the objective and follow the quest instructions.'))) or 'Select a quest in the active list above to begin.')
 cycle:SetText(t and ('Location '..choice..' / '..#step.targets) or 'No location reported')
 local supported=planner.IsSupported()
 cycle:SetEnabled(supported and step~=nil and #step.targets>1);go:SetEnabled(supported and t~=nil)
 go:SetText(step and step.turnin and 'Navigate to giver' or 'Navigate to objective')
 mapButton:SetEnabled(supported and q~=nil)
 previous:SetEnabled(G.page>1);nextPage:SetEnabled(G.page<pages);counter:SetText('Objectives · '..G.page..' / '..pages)
end
function G.Show(show,parent,offset)
 if not root then return end
 root:SetShown(show)
 if show then root:ClearAllPoints();root:SetPoint('TOPLEFT',parent,'TOPLEFT',8,-offset);G.Refresh() end
end
function G.GetHeight() return panelHeight+14 end
