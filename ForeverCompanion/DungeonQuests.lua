-- Original journal integration. No third-party database is bundled.
-- Associations require a client-reported dungeon map name and a compatible
-- Forever QuestieDB AreaTable mapping, or an exact live quest-log zone.
local D={page=1}
ForeverCompanionDungeonQuests=D
local database,index,loading,generation=nil,{},false,0
local panel,heading,summary,rows,back,nextPage,counter,body,scroll,detailBack,pickup,guide,rescan
local selectedID,dungeon
local searchBox,filterButton,planButton
local query,filter="","all"
local displayedDetailID
local function read(fn,...)
 if type(fn)~='function' then return end
 local ok,a=pcall(fn,...);if ok then return a end
end
local function finite(n) return not (issecretvalue and issecretvalue(n)) and type(n)=='number' and n==n and math.abs(n)<math.huge end
local function normalize(s)
 if type(s)~='string' then return '' end
 return s:lower():gsub('^the%s+',''):gsub('[%p%s]','')
end
function D.Matches(a,b)
 local x,y=normalize(a),normalize(b)
 if x=='' or y=='' then return false end
 if x==y then return true end
 -- Known names for the same dungeon, not a fuzzy substring match.
 local aliases={stockades='stockade',stormwindstockade='stockade',sunkentemple='templeofatalhakkar'}
 return (aliases[x] or x)==(aliases[y] or y)
end
local function faction(db,races)
 if races==0 then return 'Both factions (reference)' end
 if not finite(races) or races<1 or races%1~=0 then return 'Faction restriction not documented' end
 local masks=db.Enum and db.Enum.factionRaceMasks
 local function subset(mask)
  if not finite(mask) or mask<=0 or mask%1~=0 then return false end
  local value=races
  while value>0 do
   if value%2==1 and mask%2~=1 then return false end
   value,mask=math.floor(value/2),math.floor(mask/2)
  end
  return true
 end
 if masks and subset(masks.Alliance) then return 'Alliance races (reference)' end
 if masks and subset(masks.Horde) then return 'Horde races (reference)' end
 return 'Race-restricted (reference); inspect the giver'
end
function D.StartScan(force)
 local locations=ForeverCompanionQuestLocations
 local db=locations and read(locations.Provider)
 if not db then database=nil;index={};generation=generation+1;loading=false;return false end
 if not force and database==db then return true end
 local ids=read(db.Quest.GetAllIds)
 if type(ids)~='table' or not C_Timer or type(C_Timer.After)~='function' then database=nil;index={};generation=generation+1;loading=false;return false end
 database=db;index={};loading=true;generation=generation+1
 local token,cursor=generation,1
 local maps=locations.AreaMaps(db)
 local function batch()
  if token~=generation then return end
  for i=cursor,math.min(cursor+79,#ids) do
   local id=ids[i]
   if finite(id) and id>0 and id%1==0 then
    local area=read(db.Quest.zoneOrSort,id)
    local map=finite(area) and area>0 and maps[area]
    local info=map and C_Map and read(C_Map.GetMapInfo,map)
    if type(info)=='table' and info.mapType==4 and type(info.name)=='string' and info.name~='' then
     local title=read(db.Quest.name,id)
     if type(title)=='string' and title~='' then
      local key=info.name
      index[key]=index[key] or {}
      local races=read(db.Quest.requiredRaces,id)
      index[key][#index[key]+1]={id=id,title=title,level=read(db.Quest.questLevel,id),minimum=read(db.Quest.requiredLevel,id),races=races,faction=faction(db,races),map=map}
     end
    end
   end
  end
  cursor=cursor+80
  if cursor<=#ids then C_Timer.After(.01,batch)
  else loading=false;if panel and panel:IsShown() and ForeverCompanionRefresh then ForeverCompanionRefresh() end end
 end
 C_Timer.After(0,batch)
 return true
end
local function plans()
 ForeverCompanionDB=ForeverCompanionDB or {}
 if type(ForeverCompanionDB.dungeonQuestPlans)~='table' then ForeverCompanionDB.dungeonQuestPlans={} end
 return ForeverCompanionDB.dungeonQuestPlans
end
function D.IsPlanned(id) return plans()[id]==true end
function D.SetPlanned(id,value)
 if not finite(id) or id<=0 or id%1~=0 or type(value)~='boolean' then return false end
 local saved=plans()
 if value then
  local count=0;for _,v in pairs(saved) do if v==true then count=count+1 end end
  if count>=200 and saved[id]~=true then return false end
  saved[id]=true
 else saved[id]=nil end
 return true
end
function D.Entries(name,quests)
 local result,seen,active={},{},{}
 for _,q in ipairs(quests or {}) do if type(q)=='table' and q.id then active[q.id]=q end end
 for zone,entries in pairs(index) do if D.Matches(name,zone) then
  for _,entry in ipairs(entries) do
   local copy={};for k,v in pairs(entry) do copy[k]=v end
   copy.live=active[entry.id];result[#result+1]=copy;seen[entry.id]=true
  end
 end end
 for _,q in ipairs(quests or {}) do
  if q.id and not seen[q.id] and q.zoneKnown and D.Matches(name,q.zone) then
   result[#result+1]={id=q.id,title=q.title,level=q.level,live=q};seen[q.id]=true
  end
 end
 for _,entry in ipairs(result) do
  entry.planned=D.IsPlanned(entry.id)
  local completed=C_QuestLog and read(C_QuestLog.IsQuestFlaggedCompleted,entry.id)
  entry.state=entry.live and (entry.live.complete and 'Ready to turn in' or 'In your quest log') or (completed==true and 'Completed' or (completed==false and 'Not completed' or 'Completion unknown'))
 end
 local reference=ForeverCompanionDungeonQuestReference and ForeverCompanionDungeonQuestReference[name]
 for i,r in ipairs(reference and reference.rows or {}) do
  result[#result+1]={id='reference:'..i,title=r[1],faction=r[2]~='' and r[2] or nil,
   minimum=r[3]>0 and r[3] or nil,start=r[4],prerequisites=r[5],source=reference.source,
   shared=reference.shared,state=reference.shared and 'Shared instance listing; check wing' or 'Published pickup reference'}
 end
 table.sort(result,function(a,b)
  if not not a.live~=not not b.live then return a.live~=nil end
  if a.title~=b.title then return a.title<b.title end
  return tostring(a.id)<tostring(b.id)
 end)
 return result,{loading=loading,provider=database~=nil}
end
-- Filtering never infers player eligibility from incomplete references.
function D.Filter(entries,term,mode)
 local result={};term=type(term)=='string' and term:lower():gsub('^%s+',''):gsub('%s+$','') or ''
 for _,entry in ipairs(entries or {}) do
  local matches=term=='' or (tostring(entry.title or '')..' '..tostring(entry.id or '')..' '..tostring(entry.faction or '')..' '..table.concat(entry.start or {},' ')):lower():find(term,1,true)
  local state=mode=='active' and entry.live~=nil or mode=='ready' and entry.live and entry.live.complete==true or mode=='completed' and entry.state=='Completed' or mode=='uncompleted' and entry.state=='Not completed' or mode=='planned' and entry.planned==true or mode==nil or mode=='all'
  if matches and state then result[#result+1]=entry end
 end
 return result
end
function D.Progress(quest)
 if type(quest)~='table' then return 'Progress unavailable' end
 if quest.complete then return 'Ready to turn in' end
 local total,done,known=0,0,0
 for i in ipairs(type(quest.objectives)=='table' and quest.objectives or {}) do
  total=total+1;local state=type(quest.objectiveStates)=='table' and quest.objectiveStates[i]
  if type(state)=='table' and state.known==true then known=known+1;if state.done then done=done+1 end end
 end
 if total==0 then return 'Inspect objectives in the quest log' end
 return done..' / '..total..' objectives complete'..(known<total and ' · some progress unknown' or '')
end
function D.ResolvePickup(entry,target)
 return ForeverCompanionQuestLocations.ResolveGiver(entry,target)
end
local function text(parent,x,y,w,size)
 local t=ForeverCompanionInterface.Text(parent,size or 11);t:SetPoint('TOPLEFT',x,y);t:SetWidth(w);return t
end
local function button(parent,x,y,w,label,action)
 local b=ForeverCompanionInterface.Button(parent);b:SetSize(w,24);b:SetPoint('TOPLEFT',x,y);b:SetText(label);b:SetScript('OnClick',action);return b
end
local function render() if ForeverCompanionRefresh then ForeverCompanionRefresh() end end
function D.Create(parent)
 local U=ForeverCompanionInterface
 panel=CreateFrame('Frame','ForeverCompanionDungeonQuestsPanel',parent,'BackdropTemplate');panel:SetPoint('TOPLEFT',214,-72);panel:SetSize(544,302);ForeverCompanionDungeonChrome.Skin(panel,544,302,32)
 heading=text(panel,12,-10,390,13);heading:SetText('DUNGEON QUESTS')
 rescan=button(panel,436,-7,96,'Refresh data',function() D.StartScan(true);render() end)
 searchBox=U.EditBox(panel,'Search quest, giver or zone');searchBox:SetPoint('TOPLEFT',12,-40);searchBox:SetSize(348,26);searchBox:SetMaxLetters(100)
 searchBox:SetScript('OnTextChanged',function(self) query=self:GetText();D.page=1;selectedID=nil;D.Render(dungeon) end)
 filterButton=button(panel,370,-40,162,'All quests',function(self)
  local menu={}
  for _,option in ipairs({{'all','All quests'},{'planned','Planned for a run'},{'active','In quest log'},{'ready','Ready to turn in'},{'uncompleted','Not completed'},{'completed','Completed'}}) do
   local key,label=option[1],option[2]
   menu[#menu+1]={label=label,action=function() filter=key;filterButton:SetText(label);D.page=1;selectedID=nil;D.Render(dungeon) end}
  end
  U.Menu(self,'QUEST STATUS',menu,nil,260)
 end)
 rows={}
 for i=1,4 do
  local row=CreateFrame('Button',nil,panel);row:SetPoint('TOPLEFT',12,-80-(i-1)*43);row:SetSize(520,39);row.bg=U.Surface(row)
  row.title=text(row,8,-4,504,12);row.state=text(row,8,-22,504,10)
  row:SetScript('OnClick',function() if row.entry then selectedID=row.entry.id;D.Render(dungeon) end end)
  rows[i]=row
 end
 summary=text(panel,12,-253,520,11);summary:SetWordWrap(true);summary:SetHeight(17)
 back=button(panel,12,-273,90,'Previous',function() D.page=math.max(1,D.page-1);D.Render(dungeon) end)
 nextPage=button(panel,442,-273,90,'Next',function() D.page=D.page+1;D.Render(dungeon) end)
 counter=text(panel,114,-278,310,11);counter:SetJustifyH('CENTER')
 detailBack=button(panel,12,-80,96,'Back to quests',function() selectedID=nil;D.Render(dungeon) end)
 pickup=button(panel,118,-80,172,'Givers / turn-in',function(self)
  local entries=D.Entries(dungeon,read(ForeverCompanionQuestPlanner.GetLive) or {})
  local selected;for _,entry in ipairs(entries) do if entry.id==selectedID then selected=entry end end
  local details=selected and ForeverCompanionQuestLocations.Details(selected)
  local menu={}
  local targets={}
  for _,t in ipairs(details and details.pickups or {}) do targets[#targets+1]=t end
  for _,t in ipairs(details and details.turnins or {}) do targets[#targets+1]=t end
  for i=1,#targets do
   local target=targets[i];local info=C_Map and read(C_Map.GetMapInfo,target.map)
   menu[#menu+1]={label=(target.kind=='turn-in' and 'Turn-in: ' or 'Pickup: ')..(target.label or 'Quest giver')..' · '..(info and info.name or ('Map '..target.map))..' (reference)',action=function()
    local fresh=D.ResolvePickup(selected,target)
    summary:SetText(fresh and ForeverCompanionQuestWaypoints.Navigate(fresh,true,selected.title,selected.id) or 'This pickup reference changed or was excluded. Reopen the quest to review current data.')
   end}
  end
  U.PagedMenu(self,'QUEST LOCATIONS / VERIFY IN GAME',menu,nil,420)
 end)
 guide=button(panel,300,-80,128,'Active guide',function() if selectedID then ForeverCompanionOpenQuestGuide(selectedID) end end)
 planButton=button(panel,438,-80,94,'Plan this run',function()
  if selectedID then
   local ok=D.SetPlanned(selectedID,not D.IsPlanned(selectedID));D.Render(dungeon)
   if not ok then summary:SetText('Plan limit reached (200 quests). Remove an old planned quest first.') end
  end
 end)
 scroll=CreateFrame('ScrollFrame',nil,panel,'UIPanelScrollFrameTemplate');scroll:SetPoint('TOPLEFT',12,-115);scroll:SetSize(498,133);scroll:SetClipsChildren(true)
 local child=CreateFrame('Frame',nil,scroll);child:SetSize(498,200);scroll:SetScrollChild(child);scroll.child=child
 body=text(child,0,0,488,12);body:SetWordWrap(true)
 scroll:EnableMouseWheel(true);scroll:SetScript('OnMouseWheel',function(self,delta)
  local maximum=math.max(0,child:GetHeight()-self:GetHeight());self:SetVerticalScroll(math.max(0,math.min(maximum,self:GetVerticalScroll()-delta*36)))
 end)
 panel:Hide()
end
function D.Render(name)
 if not panel then return end
 if dungeon~=name then dungeon=name;selectedID=nil;D.page=1 end
 local live=read(ForeverCompanionQuestPlanner.GetLive) or {}
 local liveSupported=read(ForeverCompanionQuestPlanner.IsSupported)==true
 local allEntries,status=D.Entries(name,live)
 local entries=D.Filter(allEntries,query,filter)
 local pages=math.max(1,math.ceil(#entries/4));D.page=math.max(1,math.min(D.page,pages))
 local selected;for _,entry in ipairs(allEntries) do if entry.id==selectedID then selected=entry end end
 selectedID=selected and selected.id
 for i,row in ipairs(rows) do
  local entry=entries[(D.page-1)*4+i];row.entry=entry;row:SetShown(not selected and entry~=nil)
  if entry then row.title:SetText((finite(entry.level) and ('['..entry.level..'] ') or '')..(entry.planned and '[Plan] ' or '')..entry.title);row.state:SetText((entry.live and not liveSupported and 'Cached quest log; confirm in game' or (entry.live and (liveSupported and D.Progress(entry.live) or entry.state) or entry.state))..(entry.source and (entry.start[1] and (' · '..entry.start[1]) or '') or entry.map and ' · Forever database reference' or ' · Log zone association')) end
 end
 back:SetShown(not selected);nextPage:SetShown(not selected);counter:SetShown(not selected)
 back:SetEnabled(D.page>1);nextPage:SetEnabled(D.page<pages);counter:SetText(#entries..' / '..#allEntries..' matching quests · '..D.page..' / '..pages)
 planButton:SetShown(selected~=nil);
 detailBack:SetShown(selected~=nil);pickup:SetShown(selected~=nil);guide:SetShown(selected~=nil);scroll:SetShown(selected~=nil)
 if selected and selected.source then
  heading:SetText('QUEST PICKUP')
  planButton:Hide();pickup:Hide();guide:Hide()
  local lines={selected.title,selected.state}
  if selected.minimum then lines[#lines+1]='Minimum level: '..selected.minimum end
  lines[#lines+1]='Faction: '..(selected.faction or 'Not established')
  local start=selected.start
  lines[#lines+1]='Starts at: '..(start[1] and table.concat(start,' · ') or 'Pickup not documented')
  if #selected.prerequisites>0 then lines[#lines+1]='Prerequisite references: '..table.concat(selected.prerequisites,', ') end
  lines[#lines+1]='Source: '..selected.source
  body:SetText(table.concat(lines,'\n\n'))
  local h=body:GetStringHeight()+8;body:SetHeight(h);scroll.child:SetHeight(h)
  if displayedDetailID~=selected.id then scroll:SetVerticalScroll(0) end
  displayedDetailID=selected.id
 elseif selected then
  heading:SetText(selected.title)
  planButton:SetText(selected.planned and 'Remove plan' or 'Plan this run')
  local lines={selected.title,selected.live and not liveSupported and 'Cached quest log; confirm in game' or selected.state}
  if finite(selected.minimum) then lines[#lines+1]='Required level (reference): '..selected.minimum end
  lines[#lines+1]=selected.faction or 'Faction/race restrictions: check giver; eligibility is not assumed'
  local q=selected.live or selected
  local objectives=selected.live and selected.live.objectives or ForeverCompanionQuestLocations.Details(q).objectives
  if selected.live then lines[#lines+1]=liveSupported and D.Progress(selected.live) or 'Progress is cached; confirm in game' end
  lines[#lines+1]='Objectives'..(selected.live and (liveSupported and ' (live log):' or ' (cached log):') or ' (reference):')
  if type(objectives)=='table' and #objectives>0 then for i,line in ipairs(objectives) do
   local states=selected.live and selected.live.objectiveStates;local state=type(states)=='table' and states[i]
   local prefix=type(state)=='table' and state.known==true and (state.done and '[Done] ' or '[Next] ') or '[Check] '
   lines[#lines+1]=prefix..tostring(line)
  end else lines[#lines+1]='Not available. Inspect the quest in game.' end
  lines[#lines+1]=ForeverCompanionQuestLocations.DetailText(q)
  body:SetText(table.concat(lines,'\n\n'));local h=body:GetStringHeight()+8;body:SetHeight(h);scroll.child:SetHeight(h)
  if displayedDetailID~=selected.id then scroll:SetVerticalScroll(0) else scroll:SetVerticalScroll(math.min(scroll:GetVerticalScroll(),math.max(0,h-scroll:GetHeight()))) end
  displayedDetailID=selected.id
  local locations=ForeverCompanionQuestLocations.Details(q)
  pickup:SetEnabled(#locations.pickups+#locations.turnins>0)
  guide:SetEnabled(selected.live~=nil)
 else heading:SetText('DUNGEON QUESTS');displayedDetailID=nil end
 summary:SetText(status.loading and 'Indexing Forever references in small batches…' or (#entries==0 and (#allEntries>0 and 'No quests match these filters. Clear search or choose All quests.' or status.provider and 'No matching dungeon references found. This is incomplete coverage, not proof this dungeon has no quests.' or 'No compatible Forever database installed. Published references and exact live log matches are shown.') or 'Partial coverage · published pickups and live quest status.'))
 panel:Show()
end
function D.Hide() if panel then panel:Hide() end end
