-- Searchable service references. Never buys, repairs or changes vendor data.
local A={page=1}
ForeverCompanionServiceAtlas=A
local root,search,summary,rows,previous,nextPage,counter,categoryButton,sourceButton,zoneButton,favoriteButton,message
local lastMap
local categories={{'all','All services'},{'V','Vendors'},{'R','Repairs'},{'B','Banks'},{'AH','Auction houses'},{'F','Flight masters'},{'I','Inns'},{'T','Trainers'},{'M','Mailboxes'}}
local artwork={B='Banker',AH='Auctioneer',F='FlightMaster',I='Innkeeper',R='Repair',V='Reagents',T='Class',M='Mailbox'}
A.Categories=categories
local function read(fn,...)
 if type(fn)~='function' then return end
 local ok,a=pcall(fn,...);if ok then return a end
end
local function finite(n) return not (issecretvalue and issecretvalue(n)) and type(n)=='number' and n==n and math.abs(n)<math.huge end
local function positionKnown(x,y) return finite(x) and finite(y) and x>=0 and x<=1 and y>=0 and y<=1 end
local function preferences()
 ForeverCompanionDB=ForeverCompanionDB or {}
 if type(ForeverCompanionDB.serviceAtlas)~='table' then ForeverCompanionDB.serviceAtlas={} end
 if type(ForeverCompanionDB.serviceFavorites)~='table' then ForeverCompanionDB.serviceFavorites={} end
 return ForeverCompanionDB.serviceAtlas,ForeverCompanionDB.serviceFavorites
end
function A.Icon(symbol) return 'Interface\\Minimap\\Tracking\\'..(artwork[symbol] or artwork.V) end
function A.SetIcon(texture,symbol)
 if texture:SetTexture(A.Icon(symbol))==false then texture:SetTexture('Interface\\Icons\\INV_Misc_Map_01') end
end
function A.Key(p) return p.map..':'..tostring(p.npcID or p.label)..':'..p.x..':'..p.y end
function A.Query(points,query,options)
 options=options or {};query=type(query)=='string' and query:lower() or ''
 local groups,result={},{}
 for _,p in ipairs(points or {}) do if ForeverCompanionTownServices.Valid(p) and (not options.category or options.category=='all' or p.symbol==options.category) and
  (options.source~='visited' or p.observed) and (options.source~='reference' or not p.observed) then
  local key=A.Key(p);local g=groups[key]
  if not g then g={key=key,target=p,label=p.label,subtitle=p.subtitle,services={},seen={},favorite=options.favorites and options.favorites[key]==true};groups[key]=g;result[#result+1]=g end
  local service=type(p.service)=='string' and p.service or 'Service'
  if not g.seen[service] then g.seen[service]=true;g.services[#g.services+1]=service end
 end end
 local filtered={}
 for _,g in ipairs(result) do
  table.sort(g.services);g.roles=table.concat(g.services,' · ')
  local haystack=(g.label..' '..(g.subtitle or '')..' '..g.roles..' '..tostring(g.target.npcID or '')):lower()
  if haystack:find(query,1,true) and (not options.favoritesOnly or g.favorite) then
   g.distance=positionKnown(options.x,options.y) and ((g.target.x-options.x)^2+(g.target.y-options.y)^2) or nil
   filtered[#filtered+1]=g
  end
 end
 table.sort(filtered,function(a,b)
  if a.favorite~=b.favorite then return a.favorite end
  if options.nearest and a.distance and b.distance and a.distance~=b.distance then return a.distance<b.distance end
  if a.label~=b.label then return a.label<b.label end
  return a.key<b.key
 end)
 return filtered
end
function A.MapID()
 local cfg=preferences()
 if cfg.zone=='viewed' then
  return WorldMapFrame and read(WorldMapFrame.GetMapID,WorldMapFrame)
 end
 return C_Map and read(C_Map.GetBestMapForUnit,'player')
end
function A.Navigate(point)
 local target=ForeverCompanionTownServices.Resolve(point)
 if not target then return 'This service location changed. Refresh the atlas and choose it again.' end
 return ForeverCompanionQuestWaypoints.Navigate(target,true,target.label..(target.observed and ' · visited nearby' or ' · '..target.service))
end
local function label(parent,x,y,w,size,value)
 local f=ForeverCompanionInterface.Text(parent,size);f:SetPoint('TOPLEFT',x,y);f:SetWidth(w);f:SetText(value or '');return f
end
function A.Refresh()
 if not root or not root:IsShown() then return end
 local cfg,favorites=preferences();local map=A.MapID()
 if map~=lastMap then A.page=1;lastMap=map;message:SetText('') end
 local points,notice=ForeverCompanionTownServices.ForMap(map)
 local position=map and C_Map and read(C_Map.GetPlayerMapPosition,map,'player')
 local x,y
 if position and not (issecretvalue and issecretvalue(position)) and type(position.GetXY)=='function' then local ok,a,b=pcall(position.GetXY,position);if ok then x,y=a,b end end
 local found=A.Query(points,search:GetText(),{category=cfg.category,source=cfg.source,nearest=cfg.nearest~=false,favoritesOnly=cfg.favoritesOnly,favorites=favorites,x=x,y=y})
 local pages=math.max(1,math.ceil(#found/5));A.page=math.max(1,math.min(A.page,pages))
 local name=map and C_Map and read(C_Map.GetMapInfo,map)
 root.heading:SetText((name and name.name or 'ZONE')..' · SERVICE ATLAS')
 local visited=0;for _,g in ipairs(found) do if g.target.observed then visited=visited+1 end end
 summary:SetText(#found..' locations · '..(#found-visited)..' reference · '..visited..' visited nearby'..(notice and (' · '..notice) or '')..'\n'..(cfg.nearest~=false and positionKnown(x,y) and 'Favorites first, then approximate map proximity. Terrain is not evaluated.' or 'Favorites first, then name. Map position is unavailable or proximity sort is off.'))
 local category='All services';for _,c in ipairs(categories) do if c[1]==cfg.category then category=c[2] end end
 categoryButton:SetText(category)
 sourceButton:SetText(cfg.source=='visited' and 'Visited nearby' or (cfg.source=='reference' and 'Provider only' or 'All sources'))
 zoneButton:SetText(cfg.zone=='viewed' and 'World-map zone' or 'My current zone')
 favoriteButton:SetText(cfg.favoritesOnly and 'Favorites only' or 'All locations')
 for i,row in ipairs(rows) do
  local g=found[(A.page-1)*5+i];row.item=g;row:SetShown(g~=nil)
  if g then
   row.title:SetText(g.label);row.subtitle:SetText((g.subtitle and (g.subtitle..' · ') or '')..g.roles)
   row.source:SetText((g.target.observed and 'VISITED NEARBY' or 'DATABASE REFERENCE')..(' · %.1f, %.1f'):format(g.target.x*100,g.target.y*100))
   row.source:SetTextColor(g.target.observed and .30 or .85,g.target.observed and .84 or .73,g.target.observed and .86 or .50)
   A.SetIcon(row.icon,g.target.symbol);row.favorite:SetText(g.favorite and '*' or '+')
   ForeverCompanionInterface.StyleButton(row.favorite,nil,g.favorite)
  end
 end
 root.empty:SetShown(#found==0);root.empty:SetText(map and ('No locations match this view. Try All services, All sources, or clear the search.\n\n'..(notice or 'Update the compatible Forever QuestieDB provider and rescan to read its current locations.')) or 'Choose a zone on the world map or switch to My current zone.')
 previous:SetEnabled(A.page>1);nextPage:SetEnabled(A.page<pages);counter:SetText(A.page..' / '..pages)
end
function A.Toggle(viewed)
 local cfg=preferences()
 if viewed then cfg.zone='viewed' end
 if not root then
  local U=ForeverCompanionInterface
  root=CreateFrame('Frame','ForeverCompanionServiceAtlasPanel',UIParent);root:SetSize(730,650);root:SetPoint('CENTER');root:SetClampedToScreen(true);root:SetMovable(true);root:EnableMouse(true);root:SetFrameStrata('DIALOG');U.Surface(root);U.PreparePanel(root,'ForeverCompanionServiceAtlasPanel',730,650)
  local drag=CreateFrame('Frame',nil,root);drag:SetPoint('TOPLEFT',0,0);drag:SetSize(685,42);drag:EnableMouse(true);drag:RegisterForDrag('LeftButton')
  drag:SetScript('OnDragStart',function() root:StartMoving() end);drag:SetScript('OnDragStop',function() root:StopMovingOrSizing() end)
  root.heading=label(root,18,-14,650,17,'SERVICE ATLAS');U.CloseButton(root,function() root:Hide() end)
  search=U.EditBox(root,'Search vendor, service, specialty or NPC ID');search:SetSize(470,28);search:SetPoint('TOPLEFT',18,-54);search:SetMaxLetters(120)
  search:HookScript('OnTextChanged',function() A.page=1;A.Refresh() end);search:SetScript('OnEscapePressed',function(self) self:ClearFocus() end)
  local clear=U.Button(root);clear:SetSize(60,28);clear:SetPoint('TOPLEFT',496,-54);clear:SetText('Clear');clear:SetScript('OnClick',function() search:SetText('');search:ClearFocus() end)
  local rescan=U.Button(root);rescan:SetSize(148,28);rescan:SetPoint('TOPRIGHT',-18,-54);rescan:SetText('Rescan provider')
  rescan:SetScript('OnClick',function() ForeverCompanionTownServices.RefreshData();A.Refresh();if ForeverCompanionQuestMap then ForeverCompanionQuestMap.Refresh() end end)
  categoryButton=U.Button(root);categoryButton:SetSize(166,27);categoryButton:SetPoint('TOPLEFT',18,-94)
  categoryButton:SetScript('OnClick',function() local entries={};for _,c in ipairs(categories) do local key,name=c[1],c[2];entries[#entries+1]={label=name,selected=(cfg.category or 'all')==key,action=function() cfg.category=key;A.page=1;A.Refresh() end} end;U.Menu(categoryButton,'SERVICE TYPE',entries) end)
  sourceButton=U.Button(root);sourceButton:SetSize(166,27);sourceButton:SetPoint('TOPLEFT',194,-94)
  sourceButton:SetScript('OnClick',function() local entries={};for _,s in ipairs({{'all','All sources'},{'reference','Provider only'},{'visited','Visited nearby'}}) do local key,name=s[1],s[2];entries[#entries+1]={label=name,selected=(cfg.source or 'all')==key,action=function() cfg.source=key;A.page=1;A.Refresh() end} end;U.Menu(sourceButton,'LOCATION SOURCE',entries) end)
  zoneButton=U.Button(root);zoneButton:SetSize(166,27);zoneButton:SetPoint('TOPLEFT',370,-94);zoneButton:SetScript('OnClick',function() cfg.zone=cfg.zone=='viewed' and 'player' or 'viewed';A.page=1;A.Refresh() end)
  favoriteButton=U.Button(root);favoriteButton:SetSize(166,27);favoriteButton:SetPoint('TOPLEFT',546,-94);favoriteButton:SetScript('OnClick',function() cfg.favoritesOnly=not cfg.favoritesOnly;A.page=1;A.Refresh() end)
  summary=label(root,18,-134,694,11,'');summary:SetWordWrap(true);summary:SetHeight(46)
  rows={}
  for i=1,5 do
   local row=CreateFrame('Frame',nil,root);row:SetSize(694,66);row:SetPoint('TOPLEFT',18,-190-(i-1)*72);U.Surface(row)
   row.icon=row:CreateTexture(nil,'ARTWORK');row.icon:SetSize(28,28);row.icon:SetPoint('LEFT',10,0)
   row.title=label(row,48,-7,466,13,'');row.subtitle=label(row,48,-27,466,11,'');row.source=label(row,48,-47,466,9,'')
   row.favorite=U.Button(row);row.favorite:SetSize(28,28);row.favorite:SetPoint('TOPRIGHT',-98,-17)
   row.favorite:SetScript('OnClick',function() if row.item then local _,favorites=preferences();favorites[row.item.key]=not favorites[row.item.key];A.Refresh() end end)
   row.favorite:SetScript('OnEnter',function(self) if GameTooltip and row.item then GameTooltip:SetOwner(self,'ANCHOR_RIGHT');GameTooltip:SetText(row.item.favorite and 'Remove favorite' or 'Save favorite');GameTooltip:Show() end end)
   row.favorite:SetScript('OnLeave',function() if GameTooltip then GameTooltip:Hide() end end)
   row.go=U.Button(row);row.go:SetSize(80,28);row.go:SetPoint('TOPRIGHT',-8,-17);row.go:SetText('Navigate')
   row.go:SetScript('OnClick',function() if row.item then message:SetText(A.Navigate(row.item.target)) end end)
   row:EnableMouse(true);row:SetScript('OnEnter',function(self)
    if GameTooltip and self.item then local p=self.item.target;GameTooltip:SetOwner(self,'ANCHOR_RIGHT');GameTooltip:SetText(p.label);GameTooltip:AddLine(p.source or 'Provider reference',.8,.85,.9,true);GameTooltip:AddLine(p.observed and 'Coordinates are your position during a merchant visit, not an exact NPC position. Vendors may move.' or 'Provider spawn reference. Availability, phase and stock can change.',.95,.78,.4,true);GameTooltip:Show() end
   end)
   row:SetScript('OnLeave',function() if GameTooltip then GameTooltip:Hide() end end)
   rows[i]=row
  end
  root.empty=label(root,40,-218,650,13,'');root.empty:SetHeight(145);root.empty:SetWordWrap(true);root.empty:SetJustifyH('CENTER')
  message=label(root,18,-550,694,11,'');message:SetHeight(36);message:SetWordWrap(true)
  previous=U.Button(root);previous:SetSize(90,27);previous:SetPoint('BOTTOMLEFT',18,18);previous:SetText('Previous');previous:SetScript('OnClick',function() A.page=A.page-1;A.Refresh() end)
  nextPage=U.Button(root);nextPage:SetSize(90,27);nextPage:SetPoint('BOTTOMRIGHT',-18,18);nextPage:SetText('Next');nextPage:SetScript('OnClick',function() A.page=A.page+1;A.Refresh() end)
  counter=label(root,280,-610,170,11,'');counter:ClearAllPoints();counter:SetPoint('BOTTOM',0,24);counter:SetJustifyH('CENTER')
  local options=U.Button(root);options:SetSize(140,27);options:SetPoint('BOTTOMLEFT',120,18);options:SetText('Atlas options')
  options:SetScript('OnClick',function() U.Menu(options,'ATLAS OPTIONS',{
   {label='Refresh nearby order',action=A.Refresh},
   {label='Sort by approximate proximity',selected=cfg.nearest~=false,action=function() cfg.nearest=true;A.Refresh() end},
   {label='Sort by name',selected=cfg.nearest==false,action=function() cfg.nearest=false;A.Refresh() end},
   {label='Record merchant visit positions',selected=ForeverCompanionDB.recordMerchantVisits~=false,action=function() ForeverCompanionDB.recordMerchantVisits=ForeverCompanionDB.recordMerchantVisits==false end},
   {label='Quest data & setup',action=function() ForeverCompanionQuestSetup.Toggle() end},
   {label='Clear visited merchant positions...',action=function() U.Menu(options,'CLEAR LOCAL MERCHANT VISITS?',{
    {label='Clear local merchant visit records',action=function() ForeverCompanionTownServices.ClearVisits();A.Refresh();if ForeverCompanionQuestMap then ForeverCompanionQuestMap.Refresh() end end},
    {label='Cancel',action=function() end},
   }) end},
  }) end)
  root:Hide()
 end
 local w,h=UIParent:GetWidth(),UIParent:GetHeight();if finite(w) and finite(h) and w>32 and h>32 then root:SetScale(math.min(1,(w-32)/730,(h-32)/650)) end
 root:SetShown(not root:IsShown());A.Refresh()
end
local events=CreateFrame('Frame')
for _,event in ipairs({'ZONE_CHANGED','ZONE_CHANGED_NEW_AREA','PLAYER_ENTERING_WORLD'}) do pcall(events.RegisterEvent,events,event) end
events:SetScript('OnEvent',A.Refresh)
