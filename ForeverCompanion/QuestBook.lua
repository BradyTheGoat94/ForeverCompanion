-- Zone giver catalog and observed history use different evidence and counts.
local B={page=1}
ForeverCompanionQuestBook=B
local root,title,subtitle,cards,search,filterButton,zoneButton,summary,rows,empty,detailTitle,detailBody,detailLocation,detailSource,go,cycle,guide,previous,nextPage,counter,message
local mode='catalog'
local filter,oldest,localHistory='all',false,false
local selectedID,selectedKey,selection,choice,chosenTarget=nil,nil,nil,1,nil
local cachedMap,cachedCatalog,cachedStatus
local function read(fn,...)
 if type(fn)~='function' then return end
 local ok,a=pcall(fn,...);if ok then return a end
end
local labels={active='Active',available='Pickup reference',completed='Completed',locked='Blocked reference',unknown='Unknown'}
local ranks={active=1,available=2,locked=3,completed=4,unknown=5}
local statusColors={active={.64,.82,.96},available={.94,.78,.48},completed={.48,.86,.60},locked={.87,.68,.47},unknown={.66,.72,.79}}
function B.FilterCatalog(entries,query,state)
 local result={};query=string.lower(query or '')
 for _,entry in ipairs(entries or {}) do
  local haystack=string.lower(entry.title..' '..entry.id..' '..(entry.reason or '')..' '..table.concat(entry.dependencies or {},' '))
  if (not state or state=='all' or entry.status==state) and haystack:find(query,1,true) then result[#result+1]=entry end
 end
 table.sort(result,function(a,b)
  local ar,br=ranks[a.status] or 9,ranks[b.status] or 9
  if ar~=br then return ar<br end
  if a.title~=b.title then return a.title<b.title end
  return a.id<b.id
 end)
 return result
end
function B.Counts(entries)
 local counts={total=0,active=0,available=0,completed=0,locked=0,unknown=0}
 for _,entry in ipairs(entries or {}) do counts.total=counts.total+1;counts[entry.status]=(counts[entry.status] or 0)+1 end
 return counts
end
local function text(parent,x,y,width,value,size)
 local f=ForeverCompanionInterface.Text(parent,size or 11);f:SetPoint('TOPLEFT',parent,'TOPLEFT',x,y);f:SetWidth(width);f:SetText(value or '');return f
end
local function targetKey(t) return t.map..':'..t.x..':'..t.y end
local function stamp(entry)
 return entry.at and (read(date,'%b %d, %Y %H:%M',entry.at) or 'Date unavailable') or 'Time not recorded'
end
function B.Create(parent)
 local U=ForeverCompanionInterface
 root=CreateFrame('Frame','ForeverCompanionQuestBookPanel',parent);root:SetSize(770,562);U.Surface(root);root:Hide()
 title=text(root,16,-12,738,'QUEST ATLAS',16)
 subtitle=text(root,16,-38,738,'',11)
 cards={}
 for i=1,4 do
  local card=CreateFrame('Frame',nil,root);card:SetPoint('TOPLEFT',16+(i-1)*186,-64);card:SetSize(174,51);U.Surface(card)
  cards[i]={label=text(card,10,-7,154,'',10),value=text(card,10,-25,154,'',16)}
 end
 search=U.EditBox(root,'Search quest, requirement or ID');search:SetPoint('TOPLEFT',16,-127);search:SetSize(354,27)
 search:SetScript('OnTextChanged',function() B.page=1;B.Refresh(false) end)
 search:SetScript('OnEscapePressed',function(self) self:ClearFocus() end)
 filterButton=U.Button(root);filterButton:SetPoint('TOPLEFT',382,-127);filterButton:SetSize(178,27)
 filterButton:SetScript('OnClick',function()
  if mode=='history' then oldest=not oldest;B.page=1;B.Refresh(false);return end
  local entries={}
  for _,key in ipairs({'all','available','active','completed','locked','unknown'}) do
   local state=key
   entries[#entries+1]={label=labels[state] or 'All quests',selected=filter==state,action=function() filter=state;B.page=1;B.Refresh(false) end}
  end
  U.Menu(filterButton,'QUEST ATLAS STATE',entries)
 end)
 zoneButton=U.Button(root);zoneButton:SetPoint('TOPLEFT',576,-127);zoneButton:SetSize(178,27)
 zoneButton:SetScript('OnClick',function()
  if mode=='history' then localHistory=not localHistory else
   local D=ForeverCompanionQuestDiscovery;D.SetZoneMode(D.GetZoneMode()=='player' and 'viewed' or 'player')
  end
  B.page=1;B.Refresh()
 end)
 summary=text(root,16,-163,738,'',11)
 rows={}
 for i=1,5 do
  local row=CreateFrame('Button',nil,root);row:SetPoint('TOPLEFT',16,-184-(i-1)*40);row:SetSize(738,36);row.bg=U.Surface(row)
  row.title=text(row,9,-3,500,'',12);row.meta=text(row,9,-20,500,'',10)
  row.status=text(row,520,-8,206,'',11);row.status:SetJustifyH('RIGHT')
  row:SetScript('OnClick',function()
   if row.entry then selectedKey=row.key;selectedID=row.entry.id;choice=1;chosenTarget=nil;message:SetText('');B.Refresh(false) end
  end)
  row:SetScript('OnEnter',function(self)
   self.bg:SetColorTexture(.075,.09,.115,1)
   if GameTooltip and self.entry then
    GameTooltip:SetOwner(self,'ANCHOR_RIGHT');GameTooltip:SetText(self.entry.title)
    if mode=='catalog' then
     GameTooltip:AddLine(self.entry.reason,.83,.86,.9,true)
     for _,dependency in ipairs(self.entry.dependencies or {}) do GameTooltip:AddLine('Requirement: '..dependency,.9,.76,.48,true) end
     GameTooltip:AddLine('Mapped giver reference; special requirements may apply.',.8,.75,.6,true)
    else GameTooltip:AddLine('Observed turn-in. Older completion flags are not imported as events.',.83,.86,.9,true) end
    GameTooltip:Show()
   end
  end)
  row:SetScript('OnLeave',function(self) ForeverCompanionVisualTheme.SelectRow(self,self.bg,self.key==selectedKey);if GameTooltip then GameTooltip:Hide() end end)
  rows[i]=row
 end
 empty=text(root,32,-225,706,'',13);empty:SetHeight(90);empty:SetWordWrap(true);empty:SetJustifyH('CENTER')
 local detail=CreateFrame('Frame',nil,root);detail:SetPoint('TOPLEFT',16,-390);detail:SetSize(738,120);U.Surface(detail)
 detailTitle=text(detail,12,-9,552,'Select a quest',13)
 detailBody=text(detail,12,-33,552,'',11);detailBody:SetHeight(42);detailBody:SetWordWrap(true)
 detailLocation=text(detail,12,-81,552,'',11)
 detailSource=text(detail,12,-103,552,'',10)
 guide=U.Button(detail);guide:SetPoint('TOPRIGHT',-12,-6);guide:SetSize(150,25);guide:SetText('Open field guide')
 guide:SetScript('OnClick',function() if selection and ForeverCompanionOpenQuestGuide then ForeverCompanionOpenQuestGuide(selection.id) end end)
 go=U.Button(detail);go:SetPoint('TOPRIGHT',-12,-41);go:SetSize(150,25);go:SetText('Show giver map')
 go:SetScript('OnClick',function()
  local t=selection and mode=='catalog' and selection.targets[choice]
  if not t then return end
  local id,title=selection.id,selection.title
  local map=ForeverCompanionQuestDiscovery.MapID()
  local entries=map==cachedMap and ForeverCompanionAvailableQuests.Catalog(map,ForeverCompanionQuestPlanner.GetLive()) or {}
  local target=B.Resolve(entries,id,t)
  if not target then B.Refresh();message:SetText('This giver location changed. Choose a current catalog entry.');return end
  message:SetText(ForeverCompanionQuestWaypoints.Navigate(target,true,title))
 end)
 cycle=U.Button(detail);cycle:SetPoint('TOPRIGHT',-12,-78);cycle:SetSize(150,25)
 cycle:SetScript('OnClick',function() if mode=='catalog' and selection and #selection.targets>1 then choice=choice%#selection.targets+1;chosenTarget=targetKey(selection.targets[choice]);B.Refresh(false) end end)
 message=text(root,16,-513,738,'',10);message:SetHeight(12)
 previous=U.Button(root);previous:SetPoint('BOTTOMLEFT',16,9);previous:SetSize(100,25);previous:SetText('Previous')
 nextPage=U.Button(root);nextPage:SetPoint('BOTTOMRIGHT',-16,9);nextPage:SetSize(100,25);nextPage:SetText('Next')
 previous:SetScript('OnClick',function() B.page=math.max(1,B.page-1);B.Refresh(false) end)
 nextPage:SetScript('OnClick',function() B.page=B.page+1;B.Refresh(false) end)
 counter=text(root,132,-539,500,'',11);counter:SetJustifyH('CENTER')
end
function B.Resolve(entries,id,target)
 if type(target)~='table' then return end
 for _,entry in ipairs(entries or {}) do if entry.id==id then
  for _,t in ipairs(entry.targets or {}) do if t.map==target.map and t.x==target.x and t.y==target.y then return t end end
 end end
end
function B.Refresh(force)
 if not root or not root:IsShown() then return end
 local planner=ForeverCompanionQuestPlanner
 local map
 if mode=='history' then map=C_Map and read(C_Map.GetBestMapForUnit,'player') else map=ForeverCompanionQuestDiscovery.MapID() end
 local entries,stats,raw,status
 if mode=='catalog' then
  if force~=false or cachedMap~=map or not cachedCatalog then
   if cachedMap~=map then selectedID,selectedKey,selection,chosenTarget=nil,nil,nil,nil;choice=1;B.page=1;message:SetText('') end
   cachedMap=map
   if map then cachedCatalog,cachedStatus=ForeverCompanionAvailableQuests.Catalog(map,planner.GetLive()) else cachedCatalog,cachedStatus={},'Select a zone on the world map or choose Zone: mine.' end
  end
  raw,status=cachedCatalog,cachedStatus
  entries=B.FilterCatalog(raw,search:GetText(),filter);stats=B.Counts(raw)
  title:SetText('QUEST ATLAS');subtitle:SetText('Mapped giver quests for your race and class · special requirements may apply.')
  local values={{'MAPPED QUESTS',stats.total},{'COMPLETED QUESTS',stats.completed},{'ACTIVE QUESTS',stats.active},{'PICKUP REFERENCES',stats.available}}
  for i,card in ipairs(cards) do card.label:SetText(values[i][1]);card.value:SetText(status and '—' or values[i][2]) end
  filterButton:SetText('State: '..(labels[filter] or 'All'))
  zoneButton:SetText(ForeverCompanionQuestDiscovery.GetZoneMode()=='player' and 'Zone: mine' or 'Zone: world map')
  local info=map and C_Map and read(C_Map.GetMapInfo,map)
  summary:SetText(status or ((info and info.name or 'Zone unavailable')..' · '..#entries..' matches · '..stats.locked..' blocked · '..stats.unknown..' unknown'))
 else
  if localHistory and not map then raw={};status='Current turn-in map is unavailable.' else raw=ForeverCompanionQuestHistory.List(search:GetText(),localHistory and map or nil) end
  entries={}
  if oldest then for i=#raw,1,-1 do entries[#entries+1]=raw[i] end else entries=raw end
  stats=ForeverCompanionQuestHistory.Summary(raw)
  title:SetText('MY QUEST HISTORY');subtitle:SetText('Turn-ins recorded while Forever Companion is running · latest 300 retained per character.')
  local values={{'TURN-INS SHOWN',stats.turnins},{'DISTINCT QUESTS',stats.unique},{'REPORTED XP',stats.xpKnown>0 and stats.xp or 'Unknown'},{'REPORTED MONEY',stats.moneyKnown>0 and ForeverCompanionQuestHistory.Money(stats.money) or 'Unknown'}}
  for i,card in ipairs(cards) do card.label:SetText(values[i][1]);card.value:SetText(values[i][2]) end
  filterButton:SetText(oldest and 'Oldest first' or 'Newest first');zoneButton:SetText(localHistory and 'Turn-in map: here' or 'Turn-in map: all')
  summary:SetText(#entries..' observed · XP '..stats.xpKnown..'/'..stats.turnins..' · money '..stats.moneyKnown..'/'..stats.turnins..' reported · latest '..ForeverCompanionQuestHistory.limit..' retained')
 end
 local pages=math.max(1,math.ceil(#entries/5));B.page=math.max(1,math.min(B.page,pages))
 selection=nil
 for index,entry in ipairs(entries) do
  local key=mode=='history' and ('history:'..entry.sequence) or tostring(entry.id)
  if key==selectedKey then selection=entry end
 end
 if not selection then selectedID,selectedKey,chosenTarget=nil,nil,nil;message:SetText('') end
 for i,row in ipairs(rows) do
  local index=(B.page-1)*5+i;local entry=entries[index]
  row.entry=entry;row:SetShown(entry~=nil)
  if entry then
   row.key=mode=='history' and ('history:'..entry.sequence) or tostring(entry.id)
   row.title:SetText(entry.title)
   row.meta:SetText(mode=='catalog' and ('Quest '..entry.id..' · minimum level '..entry.minimum..' · '..#entry.targets..' giver locations') or (stamp(entry)..' · '..(entry.mapName or (entry.map and ('Map '..entry.map) or 'Turn-in map unavailable'))))
   row.status:SetText(mode=='catalog' and (entry.ready and 'Ready to turn in' or labels[entry.status]) or 'Observed turn-in')
   row.status:SetTextColor(unpack(mode=='catalog' and (statusColors[entry.status] or statusColors.unknown) or statusColors.completed))
   ForeverCompanionVisualTheme.SelectRow(row,row.bg,row.key==selectedKey)
  end
 end
 empty:SetShown(#entries==0)
 empty:SetText(status or (mode=='history' and 'No matching turn-ins have been observed yet. Complete a quest while the addon is loaded to begin your history.' or 'No mapped quests match this view. Try another state, search or zone.'))
 detailTitle:SetText(selection and selection.title or 'Select a quest')
 local t=selection and mode=='catalog' and selection.targets[math.min(choice,#selection.targets)]
 if selection and mode=='catalog' then
  choice=math.max(1,math.min(choice,#selection.targets))
  if chosenTarget then for i,target in ipairs(selection.targets) do if targetKey(target)==chosenTarget then choice=i;break end end end
  t=selection.targets[choice];if t then chosenTarget=targetKey(t) end
  detailBody:SetText(selection.reason..(#selection.dependencies>0 and ('\nRequirements: '..table.concat(selection.dependencies,' / ')) or ''))
  detailLocation:SetText(t and ((t.label or 'Quest giver')..(' · %.1f, %.1f'):format(t.x*100,t.y*100)) or 'No fixed giver location reported')
  detailSource:SetText('Catalog scope: mapped quest givers · completion flags from the client')
 elseif selection then
  detailBody:SetText('Observed '..stamp(selection)..'\nXP: '..tostring(selection.xp or 'Not reported')..' · Money: '..ForeverCompanionQuestHistory.Money(selection.money))
  detailLocation:SetText('Turn-in map: '..(selection.mapName or (selection.map and ('Map '..selection.map) or 'Not recorded')))
  detailSource:SetText('Recorded when you turned in the quest; older completion flags are separate')
 else detailBody:SetText('Choose a row to inspect its evidence and next step.');detailLocation:SetText('');detailSource:SetText('') end
 local live=false
 if selection then for _,q in ipairs(planner.GetLive()) do if q.id==selection.id then live=true;break end end end
 guide:SetEnabled(live);go:SetEnabled(mode=='catalog' and type(t)=='table');cycle:SetEnabled(selection~=nil and mode=='catalog' and #selection.targets>1)
 guide:SetShown(live);go:SetShown(mode=='catalog');cycle:SetShown(mode=='catalog' and selection~=nil and #selection.targets>1)
 for _,label in ipairs({detailBody,detailLocation,detailSource}) do label:SetWidth(mode=='history' and 714 or 552) end
 detailTitle:SetWidth(live and 552 or 714)
 guide:SetText(mode=='history' and 'Open active quest' or 'Open field guide')
 cycle:SetText(t and ('Location '..choice..' / '..#selection.targets) or 'No giver selected')
 previous:SetEnabled(B.page>1);nextPage:SetEnabled(B.page<pages);counter:SetText('Page '..B.page..' / '..pages)
end
function B.GetHeight() return root and root:GetHeight()+14 or 576 end
function B.Show(show,parent,offset,view)
 if not root then return end
 root:SetShown(show)
 if show then
  if mode~=view then mode=view;selectedID,selectedKey,selection,chosenTarget=nil,nil,nil,nil;choice=1;B.page=1;search:SetText('');message:SetText('') end
  root:ClearAllPoints();root:SetPoint('TOPLEFT',parent,'TOPLEFT',8,-offset);B.Refresh()
 end
end
local events=CreateFrame('Frame')
for _,event in ipairs({'ZONE_CHANGED_NEW_AREA','ZONE_CHANGED','PLAYER_ENTERING_WORLD','PLAYER_LEVEL_UP'}) do pcall(events.RegisterEvent,events,event) end
events:SetScript('OnEvent',function() B.Refresh() end)
