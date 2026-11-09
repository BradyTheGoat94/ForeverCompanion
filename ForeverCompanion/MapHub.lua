-- One searchable index over existing information. Navigation is always clicked.
local H={page=1};ForeverCompanionMapHub=H
local root,search,summary,notice,rows,previous,nextPage,counter,kindButton,recentButton,quick
local filter='all';local recent=false
local cached,cachedStatus,cachedMap
local selectedIndex=1;local matches={}
local function read(fn,...)
 if type(fn)~='function' then return end
 local ok,value=pcall(fn,...);if ok then return value end
end
local function finite(n) return not(issecretvalue and issecretvalue(n)) and type(n)=='number' and n==n and math.abs(n)<math.huge end
local function coord(n) return finite(n) and n>=0 and n<=1 end
local function valid(p) return type(p)=='table' and finite(p.map) and p.map>0 and p.map%1==0 and coord(p.x) and coord(p.y) end
local function clean(s,limit)
 if type(s)~='string' then return '' end
 s=s:gsub('[%c|]',' ');local last=limit or 120
 while #s>last and last>0 do local b=s:byte(last+1);if b<128 or b>=192 then break end;last=last-1 end
 return s:sub(1,last)
end
local function prefs()
 ForeverCompanionDB=ForeverCompanionDB or {}
 if type(ForeverCompanionDB.mapHub)~='table' then ForeverCompanionDB.mapHub={} end
 if type(ForeverCompanionDB.travelRecent)~='table' then ForeverCompanionDB.travelRecent={} end
 return ForeverCompanionDB.mapHub,ForeverCompanionDB.travelRecent
end
local function copy(p)
 if not valid(p) then return end
 local r={map=p.map,x=p.x,y=p.y}
 for _,k in ipairs({'label','source','symbol','service','kind','objective'}) do if type(p[k])=='string' then r[k]=clean(p[k]) end end
 for _,k in ipairs({'id','npcID','objectiveIndex'}) do if finite(p[k]) then r[k]=p[k] end end
 r.observed=p.observed==true;r.reference=p.reference==true;return r
end
function H.Record(point,label,questID)
 local cfg,history=prefs();local target=copy(point)
 if cfg.remember==false or not target then return false end
 local kind=point.source=='Personal map note' and 'note' or (point.service and 'service' or (finite(questID) and 'quest' or 'point'))
 local key=kind..':'..target.map..':'..target.x..':'..target.y..':'..tostring(kind=='note' and point.id or questID or '')
 for i=#history,1,-1 do if type(history[i])~='table' or history[i].key==key or (kind=='note' and history[i].kind=='note' and history[i].noteID==point.id) then table.remove(history,i) end end
 local detail=kind=='note' and 'Personal note · uses its current saved position' or (kind=='quest' and 'Quest destination · must still match an active quest' or (kind=='service' and 'Service reference · rechecked when resumed' or 'Saved coordinate snapshot · no live location validation'))
 table.insert(history,1,{key=key,kind=kind,target=target,noteID=kind=='note' and point.id or nil,questID=questID,label=clean(label or point.label or 'Selected destination'),detail=detail})
 while #history>20 do table.remove(history) end
 return true
end
function H.Recent()
 local _,history=prefs();local result={};local allowed={note=true,quest=true,service=true,point=true}
 for _,r in ipairs(history) do if type(r)=='table' and valid(r.target) and type(r.label)=='string' and (r.detail==nil or type(r.detail)=='string') and allowed[r.kind] then result[#result+1]=r;if #result==20 then break end end end
 return result
end
function H.ClearRecent() local _=prefs();ForeverCompanionDB.travelRecent={};H.Refresh() end
function H.Query(records,query,kind)
 local terms={};for term in clean(query):lower():gmatch('%S+') do terms[#terms+1]=term end
 local result,total={},0
 for _,r in ipairs(records or {}) do
  if type(r)=='table' and type(r.label)=='string' and (not kind or kind=='all' or r.kind==kind) then
   local text=(r.label..' '..(type(r.detail)=='string' and r.detail or '')..' '..(type(r.tags)=='string' and r.tags or '')):lower();local match=true
   for _,term in ipairs(terms) do if not text:find(term,1,true) then match=false;break end end
   if match then total=total+1;if #result<300 then result[#result+1]=r end end
  end
 end
 return result,total
end
function H.Snapshot()
 local result={};local T=ForeverCompanionMapTools
 local map=C_Map and read(C_Map.GetBestMapForUnit,'player')
 if not finite(map) or map<=0 then map=nil end
 for _,p in ipairs(T.List()) do
  local style=T.NoteStyle(p)
  local info=C_Map and read(C_Map.GetMapInfo,p.map)
  result[#result+1]={kind='note',label=p.label,noteID=p.id,target=p,detail=(p.favorite and 'Starred · ' or '')..style.name..' · '..(info and info.name or ('Map '..p.map))..' · Personal saved position',tags=style.name}
 end
 local planner=ForeverCompanionQuestPlanner;local way=ForeverCompanionQuestWaypoints
 if planner.IsSupported() then for _,q in ipairs(planner.GetLive()) do
  local targets=way.Targets(q);local best=targets[1]
  for _,p in ipairs(targets) do if p.map==map then best=p;break end end
  result[#result+1]={kind='quest',label=q.title or 'Active quest',questID=q.id,target=best,detail=best and way.Describe(best) or way.Explain(q),tags=table.concat(q.objectives or {},' ')}
 end end
 local services,status=ForeverCompanionTownServices.ForMap(map)
 for _,g in ipairs(ForeverCompanionServiceAtlas.Query(services,'',{})) do
  result[#result+1]={kind='service',label=g.label,target=g.target,detail=g.roles..' · '..(g.target.observed and 'Visited nearby' or 'Provider reference'),tags=g.subtitle or ''}
 end
 return result,status
end
function H.Invalidate()
 cached=nil;cachedStatus=nil;cachedMap=nil
 if root and root:IsShown() then
  if ForeverCompanionRefreshQueue then ForeverCompanionRefreshQueue.Schedule('map-hub',H.Refresh) else H.Refresh() end
 end
end
function H.Index(force)
 local map=C_Map and read(C_Map.GetBestMapForUnit,'player')
 if not finite(map) or map<=0 then map=nil end
 if force or not cached or map~=cachedMap then cached,cachedStatus=H.Snapshot();cachedMap=map end
 return cached,cachedStatus
end
function H.MoveSelection(delta)
 if #matches==0 then return end
 selectedIndex=math.max(1,math.min(#matches,selectedIndex+delta));H.page=math.floor((selectedIndex-1)/6)+1;H.Refresh()
end
function H.ActivateSelected()
 if notice then notice:SetText(H.Activate(matches[selectedIndex]));H.Refresh() end
end
function H.Activate(r)
 if type(r)~='table' then return 'Choose a current result.' end
 if r.kind=='note' then return ForeverCompanionMapTools.Navigate(r.noteID) end
 if r.kind=='service' then return ForeverCompanionServiceAtlas.Navigate(r.target) end
 if r.kind=='quest' then
  local p=ForeverCompanionQuestPlanner;local w=ForeverCompanionQuestWaypoints
  if not p.IsSupported() then return 'Quest snapshot unavailable. Open the quest log first.' end
  for index,q in ipairs(p.GetLive()) do if q.id==r.questID then
   if r.target then
    for _,t in ipairs(w.Targets(q)) do if t.map==r.target.map and t.x==r.target.x and t.y==r.target.y then p.Select(index);return w.Navigate(t,true,q.title,q.id) end end
    return 'This quest destination changed. Search again to choose its current location.'
   end
   p.Select(index);return w.Show(q)
  end end
  return 'This quest is no longer active. Search again.'
 end
 if r.kind=='point' and valid(r.target) then return ForeverCompanionQuestWaypoints.Navigate(r.target,true,r.label) end
 return 'This destination is unavailable. Search again.'
end
local function text(parent,x,y,w,size,value)
 local f=ForeverCompanionInterface.Text(parent,size);f:SetPoint('TOPLEFT',x,y);f:SetWidth(w);f:SetText(value or '');return f
end
function H.Refresh(force)
 if not root or not root:IsShown() then return end
 local records,status
 if recent then records=H.Recent() else records,status=H.Index(force==true) end
 local found,total=H.Query(records,search:GetText(),filter)
 matches=found;selectedIndex=math.max(1,math.min(selectedIndex,#found))
 local pages=math.max(1,math.ceil(#found/6));H.page=math.max(1,math.min(H.page,pages))
 summary:SetText((recent and 'Recent destinations' or 'All saved notes · Active quests · Services in your current zone')..'\n'..total..' matches'..(total>300 and ' · first 300 shown; narrow your search' or '')..(status and (' · '..status) or ''))
 kindButton:SetText(filter=='all' and 'All result types' or (filter:sub(1,1):upper()..filter:sub(2)))
 recentButton:SetText(recent and 'Search current data' or 'Recent destinations')
 for i,row in ipairs(rows) do
  local r=found[(H.page-1)*6+i];row.result=r;row:SetShown(r~=nil)
  row.selected:SetShown(r~=nil and (H.page-1)*6+i==selectedIndex)
  if r then row.title:SetText(r.label);row.detail:SetText((r.kind=='point' and 'Saved point' or r.kind:upper())..' · '..(r.detail or 'Previously selected position'));row.go:SetText(r.target and 'Navigate' or 'Inspect') end
 end
 root.empty:SetShown(#found==0);root.empty:SetText(recent and 'No recent destinations match. Only successful navigation choices are remembered.' or 'No matches. Try a note name, active quest objective, vendor name or service type. Service coverage depends on your installed provider.')
 previous:SetEnabled(H.page>1);nextPage:SetEnabled(H.page<pages);counter:SetText(H.page..' / '..pages)
end
function H.Open(query,showRecent)
 if not root then
  local U=ForeverCompanionInterface
  root=CreateFrame('Frame','ForeverCompanionMapHubPanel',UIParent);root:SetSize(700,650);root:SetPoint('CENTER');root:SetFrameStrata('DIALOG');root:SetClampedToScreen(true);root:SetMovable(true);root:EnableMouse(true);U.Surface(root);U.PreparePanel(root,'ForeverCompanionMapHubPanel',700,650)
  local drag=CreateFrame('Frame',nil,root);drag:SetSize(650,40);drag:SetPoint('TOPLEFT');drag:EnableMouse(true);drag:RegisterForDrag('LeftButton');drag:SetScript('OnDragStart',function() root:StartMoving() end);drag:SetScript('OnDragStop',function() root:StopMovingOrSizing() end)
  text(root,18,-13,590,17,'MAP COMPANION');U.CloseButton(root,function() root:Hide() end)
  search=U.EditBox(root,'Search notes, quests, vendors or services');search:SetSize(664,29);search:SetPoint('TOPLEFT',18,-49);search:SetMaxLetters(120);search:HookScript('OnTextChanged',function() H.page=1;selectedIndex=1;H.Refresh() end)
  search:SetScript('OnEscapePressed',function(self) if self.ClearFocus then self:ClearFocus() end;root:Hide() end)
  search:SetScript('OnEnterPressed',H.ActivateSelected)
  search:SetScript('OnKeyDown',function(_,key) if key=='UP' then H.MoveSelection(-1) elseif key=='DOWN' then H.MoveSelection(1) end end)
  kindButton=U.Button(root);kindButton:SetSize(160,26);kindButton:SetPoint('TOPLEFT',18,-88)
  kindButton:SetScript('OnClick',function() local entries={};for _,pair in ipairs({{'all','All result types'},{'note','Personal notes'},{'quest','Active quests'},{'service','Services'},{'point','Saved coordinates'}}) do local k,label=pair[1],pair[2];entries[#entries+1]={label=label,action=function() filter=k;H.page=1;selectedIndex=1;H.Refresh() end} end;U.Menu(kindButton,'RESULT TYPE',entries) end)
  recentButton=U.Button(root);recentButton:SetSize(170,26);recentButton:SetPoint('TOPLEFT',188,-88);recentButton:SetScript('OnClick',function() recent=not recent;H.page=1;selectedIndex=1;H.Refresh() end)
  local tools=U.Button(root);tools:SetSize(150,26);tools:SetPoint('TOPLEFT',368,-88);tools:SetText('Quick actions');tools:SetScript('OnClick',function() H.Menu(tools) end)
  local refresh=U.Button(root);refresh:SetSize(154,26);refresh:SetPoint('TOPLEFT',528,-88);refresh:SetText('Refresh results');refresh:SetScript('OnClick',function() H.Refresh(true) end)
  summary=text(root,18,-127,664,11,'');summary:SetHeight(38);summary:SetWordWrap(true);rows={}
  for i=1,6 do
   local row=CreateFrame('Frame',nil,root);row:SetSize(664,57);row:SetPoint('TOPLEFT',18,-177-(i-1)*64);U.Surface(row)
   row.selected=row:CreateTexture(nil,'BORDER');row.selected:SetPoint('TOPLEFT',0,0);row.selected:SetPoint('BOTTOMLEFT',0,0);row.selected:SetWidth(3);row.selected:SetColorTexture(.3,.85,1,1);row.selected:Hide()
   row.title=text(row,10,-7,540,13,'');row.detail=text(row,10,-29,540,10,'');row.detail:SetWordWrap(false)
   row.go=U.Button(row);row.go:SetSize(86,27);row.go:SetPoint('RIGHT',-9,0);row.go:SetScript('OnClick',function() selectedIndex=(H.page-1)*6+i;notice:SetText(H.Activate(row.result));H.Refresh() end);rows[i]=row
   row:EnableMouse(true);row:SetScript('OnEnter',function(self) if GameTooltip and self.result then GameTooltip:SetOwner(self,'ANCHOR_RIGHT');GameTooltip:SetText(self.result.label);GameTooltip:AddLine(self.result.detail or 'Previously selected position',.8,.85,.9,true);GameTooltip:Show() end end);row:SetScript('OnLeave',function() if GameTooltip then GameTooltip:Hide() end end)
  end
  root.empty=text(root,30,-218,640,13,'');root.empty:SetHeight(110);root.empty:SetWordWrap(true)
  notice=text(root,18,-565,664,11,'');notice:SetHeight(37);notice:SetWordWrap(true)
  previous=U.Button(root);previous:SetSize(90,26);previous:SetPoint('BOTTOMLEFT',18,16);previous:SetText('Previous');previous:SetScript('OnClick',function() H.page=H.page-1;selectedIndex=math.max(1,(H.page-1)*6+1);H.Refresh() end)
  nextPage=U.Button(root);nextPage:SetSize(90,26);nextPage:SetPoint('BOTTOMRIGHT',-18,16);nextPage:SetText('Next');nextPage:SetScript('OnClick',function() H.page=H.page+1;selectedIndex=(H.page-1)*6+1;H.Refresh() end)
  counter=text(root,250,-610,200,11,'');counter:ClearAllPoints();counter:SetPoint('BOTTOM',0,22);counter:SetJustifyH('CENTER');root:Hide()
 end
 recent=showRecent==true;filter='all';H.page=1;selectedIndex=1;cached=nil;notice:SetText('Up / Down to select · Enter to open · Escape to close');root:Show();search:SetText(type(query)=='string' and query or '');H.Refresh();if search.SetFocus then search:SetFocus() end
end
function H.Menu(anchor)
 local U=ForeverCompanionInterface;local cfg=prefs()
 U.Menu(anchor or quick or root or UIParent,'MAP QUICK ACTIONS',{
  {label='Search map companion',action=function() H.Open() end},
  {label='Recent destinations',action=function() H.Open('',true) end},
  {label='Personal notes',action=function() ForeverCompanionMapTools.Toggle() end},
  {label='Find nearby service',action=function() ForeverCompanionMapTools.NearestMenu(anchor or quick or root) end},
  {label='Toggle transparent map',action=function() ForeverCompanionMapOverlay.Toggle() end},
  {label='Overlay presets',action=function() ForeverCompanionMapOverlay.PresetMenu(anchor or quick or root) end},
  {label='Travel display options',action=function() ForeverCompanionQuestDirection.OpenOptions(anchor or quick or root) end},
  {label=cfg.remember==false and 'Enable recent destinations' or 'Pause destination history',action=function() cfg.remember=cfg.remember==false end},
  {label='Clear recent destinations...',action=function() U.Menu(anchor or quick or root,'CLEAR RECENT DESTINATIONS?',{{label='Clear local destination history',action=H.ClearRecent},{label='Cancel',action=function() end}}) end},
  {label='Hide quick button (/fc map button)',action=function() cfg.hideButton=true;if quick then quick:Hide() end end},
 })
end
function H.ShowButton(reset)
 local cfg=prefs();cfg.hideButton=false
 if not quick then
  quick=ForeverCompanionInterface.Button(UIParent);quick:SetSize(48,26);quick:SetText('Map');quick:SetFrameStrata('MEDIUM');quick:SetMovable(true);quick:SetClampedToScreen(true);quick:RegisterForDrag('LeftButton')
  quick:SetScript('OnClick',function(_,button) if button=='RightButton' then H.Menu(quick) else H.Open() end end);quick:RegisterForClicks('LeftButtonUp','RightButtonUp')
  quick:SetScript('OnDragStart',function() quick:StartMoving() end)
  quick:SetScript('OnDragStop',function() quick:StopMovingOrSizing();local x,y=quick:GetCenter();local px,py=UIParent:GetCenter();local fs,ps=quick:GetEffectiveScale(),UIParent:GetEffectiveScale();if finite(x) and finite(y) and finite(px) and finite(py) and finite(fs) and fs>0 and finite(ps) then cfg.x=x-px*ps/fs;cfg.y=y-py*ps/fs end end)
  quick:SetScript('OnEnter',function(self) if GameTooltip then GameTooltip:SetOwner(self,'ANCHOR_LEFT');GameTooltip:SetText('Map Companion');GameTooltip:AddLine('Click to search · Right-click for actions\nDrag to move',.8,.85,.9,true);GameTooltip:Show() end end);quick:SetScript('OnLeave',function() if GameTooltip then GameTooltip:Hide() end end)
 end
 if reset then cfg.x=nil;cfg.y=nil end
 quick:ClearAllPoints();if finite(cfg.x) and finite(cfg.y) then quick:SetPoint('CENTER',UIParent,'CENTER',cfg.x,cfg.y) else quick:SetPoint('BOTTOMRIGHT',UIParent,'BOTTOMRIGHT',-24,140) end;quick:Show()
end
local events=CreateFrame('Frame');for _,event in ipairs({'PLAYER_ENTERING_WORLD','ZONE_CHANGED_NEW_AREA','QUEST_LOG_UPDATE','ADDON_LOADED'}) do events:RegisterEvent(event) end
events:SetScript('OnEvent',function(_,event)
 if event=='PLAYER_ENTERING_WORLD' then local cfg=prefs();if not cfg.hideButton then H.ShowButton() end end
 H.Invalidate()
end)
