-- Browse real quest-giver locations without changing map marker preferences.
local D={page=1}
ForeverCompanionQuestDiscovery=D
local root,search,summary,empty,counter,back,forward,rows,modeButton,sortButton,levelButton,zoneButton
local details,detailTitle,detailLocation,detailSource,detailHint,detailGo,detailCycle,detailStatus
local nativeOnly,nearLevel=false,false
local sortMode='source'
local zoneMode='player'
local selectedID,selectedMap,selectedTarget,selection,currentMap
local choices={}
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
function D.MapID()
 if zoneMode=='viewed' then
  local map=WorldMapFrame and read(WorldMapFrame.GetMapID,WorldMapFrame)
  if finite(map) and map>0 then return map end
  return nil
 end
 return C_Map and read(C_Map.GetBestMapForUnit,'player')
end
function D.SetZoneMode(mode)
 if mode~='player' and mode~='viewed' then return false end
 zoneMode=mode;D.page=1;D.Refresh();return true
end
function D.GetZoneMode() return zoneMode end
function D.TargetKey(t) return t.map..':'..t.x..':'..t.y end
function D.Filter(entries,query,native,options)
 options=options or {}
 local grouped,result={},{}
 query=string.lower(query or '')
 for _,entry in ipairs(entries or {}) do
  local q,t=entry.quest,entry.target
  local level=q and q.level
  local levelOK=not options.nearLevel or not finite(options.level) or not finite(level) or level<=0 or math.abs(level-options.level)<=5
  if q and finite(q.id) and q.id>0 and type(q.title)=='string' and valid(t) and levelOK and (not native or not entry.reference) and (string.find(string.lower(q.title),query,1,true) or string.find(string.lower(type(t.label)=='string' and t.label or ''),query,1,true)) then
   local item=grouped[q.id]
   if not item then item={quest=q,targets={},reference=entry.reference==true,seen={}};grouped[q.id]=item;result[#result+1]=item end
   local key=D.TargetKey(t)
   local existing=item.seen[key]
   if not existing then
    local target={map=t.map,x=t.x,y=t.y,label=t.label,kind=t.kind,source=t.source,reference=entry.reference==true}
    item.targets[#item.targets+1]=target;item.seen[key]=target
   elseif not entry.reference then existing.reference=false;existing.source=t.source end
   if not entry.reference then item.reference=false end
  end
 end
 local positioned=finite(options.x) and finite(options.y)
 for _,item in ipairs(result) do
  table.sort(item.targets,function(a,b)
   if a.reference~=b.reference then return not a.reference end
   if positioned then
    local da=(a.x-options.x)^2+(a.y-options.y)^2
    local db=(b.x-options.x)^2+(b.y-options.y)^2
    if da~=db then return da<db end
   end
   return D.TargetKey(a)<D.TargetKey(b)
  end)
  item.distance=math.huge
  if positioned then for _,t in ipairs(item.targets) do item.distance=math.min(item.distance,(t.x-options.x)^2+(t.y-options.y)^2) end end
 end
 table.sort(result,function(a,b)
  if options.sort=='recommended' and a.reference~=b.reference then return not a.reference end
  if options.sort=='recommended' and a.distance~=b.distance then return a.distance<b.distance end
  if options.sort=='proximity' and a.distance~=b.distance then return a.distance<b.distance end
  if options.sort=='level' then
   local al=finite(a.quest.level) and a.quest.level>0 and a.quest.level or math.huge
   local bl=finite(b.quest.level) and b.quest.level>0 and b.quest.level or math.huge
   if al~=bl then return al<bl end
  end
  if options.sort~='name' and a.reference~=b.reference then return not a.reference end
  local x,y=string.lower(a.quest.title),string.lower(b.quest.title)
  if x~=y then return x<y end
  return a.quest.id<b.quest.id
 end)
 return result
end
local function text(parent,x,y,width,value,size)
 local f=ForeverCompanionInterface.Text(parent,size or 12)
 f:SetPoint('TOPLEFT',parent,'TOPLEFT',x,y);f:SetWidth(width);f:SetText(value or '');return f
end
function D.Create(parent)
 local U=ForeverCompanionInterface
 root=CreateFrame('Frame','ForeverCompanionQuestDiscoveryPanel',parent);root:SetSize(770,562);U.Surface(root);root:Hide()
 text(root,16,-13,730,'DISCOVER QUESTS',16)
 text(root,16,-39,730,'Quest pickup locations · browse your zone or the selected world-map zone.',12)
 search=U.EditBox(root,'Search quest or quest giver');search:SetPoint('TOPLEFT',16,-66);search:SetSize(470,27)
 search:SetScript('OnTextChanged',function() D.page=1;D.Refresh() end)
 search:SetScript('OnEscapePressed',function(self) self:ClearFocus() end)
 modeButton=U.Button(root);modeButton:SetPoint('TOPLEFT',500,-66);modeButton:SetSize(254,27)
 modeButton:SetScript('OnClick',function() nativeOnly=not nativeOnly;D.page=1;D.Refresh() end)
 sortButton=U.Button(root);sortButton:SetPoint('TOPLEFT',16,-102);sortButton:SetSize(230,25)
 sortButton:SetScript('OnClick',function()
  local nextMode={source='name',name='level',level='proximity',proximity='source'}
  sortMode=nextMode[sortMode];D.page=1;D.Refresh()
 end)
 levelButton=U.Button(root);levelButton:SetPoint('TOPLEFT',258,-102);levelButton:SetSize(228,25)
 levelButton:SetScript('OnClick',function() nearLevel=not nearLevel;D.page=1;D.Refresh() end)
 zoneButton=U.Button(root);zoneButton:SetPoint('TOPLEFT',500,-102);zoneButton:SetSize(126,25)
 zoneButton:SetScript('OnClick',function() D.SetZoneMode(zoneMode=='player' and 'viewed' or 'player') end)
 zoneButton:SetScript('OnEnter',function(self)
  if GameTooltip then GameTooltip:SetOwner(self,'ANCHOR_TOP');GameTooltip:SetText('Quest discovery zone');GameTooltip:AddLine('Choose your current zone or the zone selected on the world map. Change the map to browse another zone.',.8,.85,.9,true);GameTooltip:Show() end
 end)
 zoneButton:SetScript('OnLeave',function() if GameTooltip then GameTooltip:Hide() end end)
 local reset=U.Button(root);reset:SetPoint('TOPLEFT',634,-102);reset:SetSize(120,25);reset:SetText('Reset filters')
 reset:SetScript('OnClick',function() nativeOnly=false;nearLevel=false;sortMode='source';zoneMode='player';D.page=1;search:SetText('');D.Refresh() end)
 summary=text(root,16,-137,738,'',11)
 rows={}
 for i=1,4 do
  local row=CreateFrame('Button',nil,root);row:SetSize(738,43);row:SetPoint('TOPLEFT',16,-159-(i-1)*47);row.bg=U.Surface(row)
  row.title=text(row,9,-4,475,'',13);row.detail=text(row,9,-24,475,'',11)
  row.cycle=U.Button(row);row.cycle:SetSize(108,29);row.cycle:SetPoint('TOPRIGHT',-119,-7)
  row.cycle:SetScript('OnClick',function() row.choice=row.choice%#row.item.targets+1;D.Select(row) end)
  row.go=U.Button(row);row.go:SetSize(103,29);row.go:SetPoint('TOPRIGHT',-7,-7);row.go:SetText('Navigate')
  row.go:SetScript('OnClick',function() D.Select(row);D.Navigate() end)
  row:SetScript('OnClick',function() D.Select(row) end)
  row:SetScript('OnEnter',function(self)
   self.bg:SetColorTexture(.075,.09,.115,1)
   if GameTooltip and self.item then
    GameTooltip:SetOwner(self,'ANCHOR_RIGHT');GameTooltip:SetText(self.item.quest.title)
    GameTooltip:AddLine('Click to inspect quest giver and source details.',.75,.8,.86,true);GameTooltip:Show()
   end
  end)
  row:SetScript('OnLeave',function(self) ForeverCompanionVisualTheme.SelectRow(self,self.bg,self.item and self.item.quest.id==selectedID);if GameTooltip then GameTooltip:Hide() end end)
  rows[i]=row
 end
 empty=text(root,28,-179,714,'',13);empty:SetHeight(120);empty:SetWordWrap(true);empty:SetJustifyH('CENTER')
 details=CreateFrame('Frame',nil,root);details:SetPoint('TOPLEFT',16,-354);details:SetSize(738,144);U.Surface(details)
 detailTitle=text(details,12,-10,558,'Select a quest to inspect its giver',14)
 detailLocation=text(details,12,-38,558,'',12)
 detailSource=text(details,12,-61,558,'',11)
 detailHint=text(details,12,-83,558,'',11);detailHint:SetHeight(32);detailHint:SetWordWrap(true)
 detailStatus=text(details,12,-120,710,'',11)
 detailGo=U.Button(details);detailGo:SetPoint('TOPRIGHT',-12,-10);detailGo:SetSize(140,27);detailGo:SetText('Navigate to giver');detailGo:SetScript('OnClick',D.Navigate)
 detailCycle=U.Button(details);detailCycle:SetPoint('TOPRIGHT',-12,-48);detailCycle:SetSize(140,27)
 detailCycle:SetScript('OnClick',function()
  if not selection then return end
  local choice=choices[selectedID] or 1;choices[selectedID]=choice%#selection.targets+1
  selectedTarget=D.TargetKey(selection.targets[choices[selectedID]]);detailStatus:SetText('');D.Refresh()
 end)
 back=U.Button(root);back:SetPoint('BOTTOMLEFT',16,14);back:SetSize(100,26);back:SetText('Previous')
 forward=U.Button(root);forward:SetPoint('BOTTOMRIGHT',-16,14);forward:SetSize(100,26);forward:SetText('Next')
 counter=text(root,133,-523,500,'',11);counter:SetJustifyH('CENTER')
 counter:ClearAllPoints();counter:SetPoint('BOTTOM',root,'BOTTOM',0,19)
 back:SetScript('OnClick',function() D.page=math.max(1,D.page-1);D.Refresh() end)
 forward:SetScript('OnClick',function() D.page=D.page+1;D.Refresh() end)
 local events=CreateFrame('Frame',nil,root)
 for _,event in ipairs({'QUEST_LOG_UPDATE','QUEST_POI_UPDATE','QUEST_TURNED_IN','PLAYER_LEVEL_UP','ZONE_CHANGED_NEW_AREA','ZONE_CHANGED'}) do events:RegisterEvent(event) end
 events:SetScript('OnEvent',function() D.Refresh() end)
end
function D.Select(row)
 if not row.item then return end
 selectedID=row.item.quest.id;selectedMap=currentMap;choices[selectedID]=row.choice
 selectedTarget=D.TargetKey(row.item.targets[row.choice]);detailStatus:SetText('');D.Refresh()
end
function D.Navigate()
 if selection then
  local target=selection.targets[choices[selectedID] or 1]
  detailStatus:SetText(ForeverCompanionQuestWaypoints.Navigate(target,true,selection.quest.title))
 end
end
function D.Paint(row)
 local item=row.item;local t=item.targets[row.choice]
 row.title:SetText((finite(item.quest.level) and item.quest.level>0 and ('['..item.quest.level..'] ') or '')..item.quest.title)
 row.detail:SetText((t.reference and 'Database reference · ' or 'Client reported · ')..(t.label or 'Quest giver')..(' · %.1f, %.1f'):format(t.x*100,t.y*100))
 ForeverCompanionVisualTheme.SelectRow(row,row.bg,item.quest.id==selectedID)
 row.cycle:SetText('Giver '..row.choice..' / '..#item.targets);row.cycle:SetEnabled(#item.targets>1)
end
function D.Refresh()
 if not root or not root:IsShown() then return end
 local map=D.MapID()
 currentMap=map
 if selectedMap~=map then selectedID,selectedTarget,selection=nil,nil,nil;selectedMap=map;choices={};D.page=1;detailStatus:SetText('') end
 local info=map and read(C_Map.GetMapInfo,map)
 local entries=map and ForeverCompanionQuestWaypoints.MapPickups(map,ForeverCompanionQuestPlanner.GetLive(),true) or {}
 local position=map and C_Map and read(C_Map.GetPlayerMapPosition,map,'player')
 local x,y
 if position and position.GetXY then local ok,a,b=pcall(position.GetXY,position);if ok then x,y=a,b end end
 local found=D.Filter(entries,search:GetText(),nativeOnly,{sort=sortMode,nearLevel=nearLevel,level=read(UnitLevel,'player'),x=x,y=y})
 local pages=math.max(1,math.ceil(#found/4));D.page=math.max(1,math.min(D.page,pages))
 local visible=math.min(4,math.max(0,#found-(D.page-1)*4))
 local detailY=166+(visible==0 and 3 or visible)*47
 details:ClearAllPoints();details:SetPoint('TOPLEFT',root,'TOPLEFT',16,-detailY)
 local priorHeight=root:GetHeight()
 root:SetHeight(detailY+208)
 if priorHeight~=root:GetHeight() and D.OnLayout then D.OnLayout(root:GetHeight()-priorHeight) end
 modeButton:SetText(nativeOnly and 'Source: client reported' or 'Source: client + database')
 zoneButton:SetText(zoneMode=='player' and 'Zone: mine' or 'Zone: world map')
 local sortLabels={source='Client reported first',name='Quest name',level='Quest level',proximity='Map proximity'}
 sortButton:SetText('Sort: '..sortLabels[sortMode]);levelButton:SetText(nearLevel and 'Level: within 5 (or unknown)' or 'Level: all eligible')
 summary:SetText((info and info.name or (zoneMode=='viewed' and 'Open a zone on the world map' or 'Current zone unavailable'))..' · '..#found..' quests'..(sortMode=='proximity' and (finite(x) and finite(y) and ' · Approximate map proximity; terrain not evaluated.' or ' · Position unavailable; using source order.') or ' · Click a quest for giver details.'))
 selection=nil
 for _,item in ipairs(found) do if item.quest.id==selectedID then selection=item;break end end
 if not selection then selectedID,selectedTarget=nil,nil;detailStatus:SetText('') end
 for i,row in ipairs(rows) do
  local item=found[(D.page-1)*4+i]
  row.item=item;row:SetShown(item~=nil)
  if item then
   row.choice=math.min(choices[item.quest.id] or 1,#item.targets)
   if item.quest.id==selectedID and selectedTarget then for j,t in ipairs(item.targets) do if D.TargetKey(t)==selectedTarget then row.choice=j;break end end end
   choices[item.quest.id]=row.choice;D.Paint(row)
  end
 end
 empty:SetShown(#found==0)
 empty:SetText((search:GetText()~='' and 'No quests match this search. Try a quest giver name or clear the search.' or 'No unaccepted quests reported here. Try another zone or speak to nearby quest givers.')..'\n\n'..(ForeverCompanionQuestWaypoints.PickupStatus or 'Native quest markers depend on information available to your client.'))
 counter:SetText('Page '..D.page..' / '..pages);back:SetEnabled(D.page>1);forward:SetEnabled(D.page<pages)
 if selection then
  local choice=math.min(choices[selectedID] or 1,#selection.targets)
  if selectedTarget then for j,t in ipairs(selection.targets) do if D.TargetKey(t)==selectedTarget then choice=j;break end end end
  choices[selectedID]=choice
  local t=selection.targets[choice];selectedTarget=D.TargetKey(t)
  detailTitle:SetText(selection.quest.title)
  detailLocation:SetText((t.label or 'Quest giver')..(' · %.1f, %.1f'):format(t.x*100,t.y*100))
  detailSource:SetText('Quest '..selectedID..' · '..(t.reference and 'Forever QuestieDB reference location' or 'Quest start reported by your client'))
  detailHint:SetText(t.reference and 'Confirm requirements with the giver. Reputation, profession, seasonal and other special rules may apply.' or 'Visit this location and inspect the quest in game. Accepting the quest remains your choice.')
  detailCycle:SetText('Giver '..choice..' / '..#selection.targets)
 else
  detailTitle:SetText('Select a quest to inspect its giver');detailLocation:SetText('');detailSource:SetText('');detailHint:SetText('Each location keeps its own source. No quest is accepted automatically.');detailCycle:SetText('No giver selected')
 end
 detailGo:SetEnabled(selection~=nil);detailCycle:SetEnabled(selection~=nil and #selection.targets>1)
end
function D.Show(show,parent,offset)
 if not root then return end
 root:SetShown(show)
 if show then root:ClearAllPoints();root:SetPoint('TOPLEFT',parent,'TOPLEFT',8,-offset);D.Refresh() end
end
function D.GetHeight() return root and root:GetHeight()+14 or 576 end
