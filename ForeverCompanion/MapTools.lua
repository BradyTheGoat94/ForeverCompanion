-- Personal annotations and player-requested service lookup. No location inference.
local T={page=1};ForeverCompanionMapTools=T
local root,entry,summary,notice,rows,counter,previous,nextPage,selected
local mapPins={}
local categoryFilter='all'
local categories={
 {key='general',name='General',icon='Interface\\Icons\\INV_Misc_Note_01',color={.85,.9,1}},
 {key='farming',name='Farming',icon='Interface\\Icons\\INV_Misc_Bag_10',color={.4,1,.5}},
 {key='rare',name='Rare sightings',icon='Interface\\Icons\\INV_Misc_Gem_Variety_02',color={.85,.5,1}},
 {key='gathering',name='Gathering',icon='Interface\\Icons\\INV_Misc_Herb_01',color={1,.82,.3}},
 {key='reminder',name='Reminders',icon='Interface\\Icons\\INV_Misc_PocketWatch_01',color={.35,.85,1}},
}
T.NoteCategories=categories
function T.NoteStyle(note)
 for _,c in ipairs(categories) do if note and note.category==c.key then return c end end
 return categories[1]
end
local function finite(n) return not(issecretvalue and issecretvalue(n)) and type(n)=='number' and n==n and math.abs(n)<math.huge end
local function coord(n) return finite(n) and n>=0 and n<=1 end
local function read(fn,...)
 if type(fn)~='function' then return end
 local ok,a,b=pcall(fn,...);if ok then return a,b end
end
local function clean(text,limit)
 if type(text)~='string' then return '' end
 text=text:gsub('|',''):gsub('[%c]',' '):gsub('^%s+',''):gsub('%s+$','')
 local last=limit or 80
 while #text>last and last>0 do local b=text:byte(last+1);if b<128 or b>=192 then break end;last=last-1 end
 return text:sub(1,last)
end
local function notes()
 ForeverCompanionDB=ForeverCompanionDB or {}
 if type(ForeverCompanionDB.mapNotes)~='table' then ForeverCompanionDB.mapNotes={} end
 return ForeverCompanionDB.mapNotes
end
function T.Valid(p)
 return type(p)=='table' and finite(p.id) and p.id>0 and finite(p.map) and p.map>0 and p.map%1==0 and coord(p.x) and coord(p.y) and clean(p.label)~=''
end
function T.Position()
 local map=C_Map and read(C_Map.GetBestMapForUnit,'player')
 if not finite(map) or map<=0 then return end
 local pos=read(C_Map.GetPlayerMapPosition,map,'player')
 if not pos or (issecretvalue and issecretvalue(pos)) then return end
 local x,y=read(pos.GetXY,pos)
 if coord(x) and coord(y) then return map,x,y end
end
function T.List(map,category)
 local result={}
 for _,p in ipairs(notes()) do if T.Valid(p) and (not map or p.map==map) and (not category or category=='all' or T.NoteStyle(p).key==category) then result[#result+1]=p end end
 table.sort(result,function(a,b) if a.map~=b.map then return a.map<b.map end;if a.label~=b.label then return a.label<b.label end;return a.id<b.id end)
 return result
end
function T.Find(id)
 for _,p in ipairs(notes()) do if T.Valid(p) and p.id==id then return p end end
end
local function changed()
 if ForeverCompanionQuestMap then ForeverCompanionQuestMap.Refresh() end
 if ForeverCompanionMapOverlay then ForeverCompanionMapOverlay.Refresh() end
 if T.Refresh then T.Refresh() end
 if ForeverCompanionMapHub then ForeverCompanionMapHub.Refresh() end
end
function T.Add(label,map,x,y)
 label=clean(label)
 if label=='' then return nil,'Enter a name for this spot.' end
 if not finite(map) or map<=0 or map%1~=0 or not coord(x) or not coord(y) then return nil,'Your map position is unavailable. No note was saved.' end
 local list=notes();if #list>=100 then return nil,'You have 100 saved notes. Remove one to save another.' end
 local id=finite(ForeverCompanionDB.mapNoteSerial) and ForeverCompanionDB.mapNoteSerial or 0;for _,p in ipairs(list) do if T.Valid(p) then id=math.max(id,p.id) end end
 ForeverCompanionDB.mapNoteSerial=id+1
 local p={id=id+1,map=map,x=x,y=y,label=label,symbol='N',source='Personal map note'}
 list[#list+1]=p;changed();return p,'Saved '..label..' at your current position.'
end
function T.SaveHere(label) local map,x,y=T.Position();return T.Add(label,map,x,y) end
function T.Rename(id,label)
 local p=T.Find(id);label=clean(label);if not p or label=='' then return false end
 p.label=label;changed();return true
end
function T.SetCategory(id,key)
 local p=T.Find(id);if not p then return false end
 for _,c in ipairs(categories) do if c.key==key then p.category=key;changed();return true end end
 return false
end
function T.CategoryMenu(anchor,id)
 local entries={}
 for _,c in ipairs(categories) do local key=c.key;entries[#entries+1]={label=c.name,action=function() T.SetCategory(id,key) end} end
 ForeverCompanionInterface.Menu(anchor,'NOTE CATEGORY',entries)
end
function T.Remove(id)
 for i,p in ipairs(notes()) do if type(p)=='table' and p.id==id then table.remove(notes(),i);changed();return true end end
 return false
end
function T.Navigate(id)
 local p=T.Find(id);if not p then return 'This note was removed. Choose a current note.' end
 return ForeverCompanionQuestWaypoints.Navigate(p,true,'Note · '..p.label)
end
local aliases={repair='R',repairs='R',mail='M',mailbox='M',inn='I',flight='F',fly='F',vendor='V',bank='B',auction='AH',trainer='T'}
T.ServiceAliases=aliases
local function world(map,x,y)
 if not C_Map or not CreateVector2D or type(C_Map.GetWorldPosFromMapPos)~='function' then return end
 local pos=read(CreateVector2D,x,y);if not pos then return end
 local continent,v=read(C_Map.GetWorldPosFromMapPos,map,pos)
 if not finite(continent) or not v or (issecretvalue and issecretvalue(v)) then return end
 local a,b=read(v.GetXY,v);if finite(a) and finite(b) then return continent,a,b end
end
function T.RankServices(points,map,x,y,symbol)
 if not finite(map) or not coord(x) or not coord(y) then return {},'Position unavailable' end
 local result={};local c,a,b=world(map,x,y);local measured=c~=nil
 for _,p in ipairs(points or {}) do
  if ForeverCompanionTownServices.Valid(p) and p.map==map and (not symbol or p.symbol==symbol) then
   local pc,pa,pb=world(map,p.x,p.y)
   local distance=c and pc==c and ((pa-a)^2+(pb-b)^2) or nil
   if not distance then measured=false end
   result[#result+1]={target=p,worldDistance=distance,mapDistance=(p.x-x)^2+(p.y-y)^2}
  end
 end
 for _,g in ipairs(result) do g.distance=math.sqrt(measured and g.worldDistance or g.mapDistance) end
 table.sort(result,function(a,b) if a.distance~=b.distance then return a.distance<b.distance end;return ForeverCompanionServiceAtlas.Key(a.target)<ForeverCompanionServiceAtlas.Key(b.target) end)
 return result,measured and 'Straight-line yards; travel paths not evaluated' or 'Approximate map proximity; yards unavailable',measured
end
function T.Nearest(kind,anchor)
 local symbol=aliases[(kind or ''):lower()] or kind
 local known=false;for _,v in pairs(aliases) do if symbol==v then known=true end end
 if not known then return 'Choose repair, mail, inn, flight, vendor, bank, auction or trainer.' end
 local map,x,y=T.Position();if not map then return 'Your position is unavailable. No nearby order can be calculated.' end
 local points,status=ForeverCompanionTownServices.ForMap(map)
 local found,basis,yards=T.RankServices(points,map,x,y,symbol)
 if #found==0 then return status or 'No reported service locations of that type in this zone. Try the Service Atlas or update/rescan your provider.' end
 local choices={{label=yards and 'Straight-line distance (yards)' or 'Approximate map order',enabled=false,action=function() end}}
 for i=1,math.min(6,#found) do
  local p=found[i].target;local distance=found[i].distance
  local label=clean(p.label,30)..(#p.label>30 and '...' or '')
  choices[#choices+1]={label=label..(yards and (' · '..math.floor(distance+.5)..' yd') or '')..(p.observed and ' · visited' or ' · reference'),tooltip=p.label..'\n'..(p.source or 'Service reference')..'\n'..basis..'\n'..(p.observed and 'Your position during a merchant visit, not an exact NPC position.' or 'Phase and availability may differ.'),action=function()
   local result=ForeverCompanionServiceAtlas.Navigate(p)
   if notice then notice:SetText(result) end
   if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage(result) end
  end}
 end
 choices[#choices+1]={label='Open full Service Atlas',action=function() ForeverCompanionServiceAtlas.Toggle() end}
 local category='SERVICES';for _,c in ipairs(ForeverCompanionServiceAtlas.Categories or {}) do if c[1]==symbol then category=c[2]:upper() end end
 ForeverCompanionInterface.Menu(anchor or root or UIParent,'NEARBY '..category,choices,nil,380)
 return basis..'. Choose a destination; availability is unverified.'
end
function T.NearestMenu(anchor)
 local entries={}
 for _,c in ipairs(ForeverCompanionServiceAtlas.Categories) do if c[1]~='all' then
  local symbol,label=c[1],c[2];entries[#entries+1]={label=label,action=function() local msg=T.Nearest(symbol,anchor);if notice then notice:SetText(msg) end;if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage(msg) end end}
 end end
 ForeverCompanionInterface.Menu(anchor,'FIND NEARBY SERVICE',entries)
end
local function text(parent,x,y,w,size,value)
 local f=ForeverCompanionInterface.Text(parent,size);f:SetPoint('TOPLEFT',x,y);f:SetWidth(w);f:SetText(value or '');return f
end
function T.Refresh()
 if not root or not root:IsShown() then return end
 local list=T.List(nil,categoryFilter);local pages=math.max(1,math.ceil(#list/5));T.page=math.max(1,math.min(T.page,pages))
 summary:SetText(#list..' shown · '..#T.List()..' / 100 saved notes\nSelect a row to rename, or use Actions to change its category.')
 for i,row in ipairs(rows) do
  local p=list[(T.page-1)*5+i];row.note=p;row:SetShown(p~=nil)
  if p then
   local info=C_Map and read(C_Map.GetMapInfo,p.map)
   row.title:SetText(p.label);row.detail:SetText(T.NoteStyle(p).name..' · '..(info and info.name or ('Map '..p.map))..(' · %.1f, %.1f'):format(p.x*100,p.y*100))
   ForeverCompanionInterface.StyleButton(row,nil,selected==p.id)
  end
 end
 previous:SetEnabled(T.page>1);nextPage:SetEnabled(T.page<pages);counter:SetText(T.page..' / '..pages)
end
function T.Toggle()
 if not root then
  local U=ForeverCompanionInterface
  root=CreateFrame('Frame','ForeverCompanionMapToolsPanel',UIParent);root:SetSize(620,590);root:SetPoint('CENTER');root:SetClampedToScreen(true);root:SetMovable(true);root:EnableMouse(true);root:SetFrameStrata('DIALOG');U.Surface(root)
  local drag=CreateFrame('Frame',nil,root);drag:SetSize(570,38);drag:SetPoint('TOPLEFT');drag:EnableMouse(true);drag:RegisterForDrag('LeftButton');drag:SetScript('OnDragStart',function() root:StartMoving() end);drag:SetScript('OnDragStop',function() root:StopMovingOrSizing() end)
  text(root,18,-13,520,17,'MAP NOTES & NEARBY SERVICES');U.CloseButton(root,function() root:Hide() end)
  summary=text(root,18,-49,420,11,'');summary:SetHeight(36)
  local filterButton=U.Button(root);filterButton:SetSize(150,26);filterButton:SetPoint('TOPRIGHT',-18,-54);filterButton:SetText('All note categories')
  filterButton:SetScript('OnClick',function()
   local entries={{label='All note categories',action=function() categoryFilter='all';filterButton:SetText('All note categories');T.page=1;T.Refresh() end}}
   for _,c in ipairs(categories) do local key,name=c.key,c.name;entries[#entries+1]={label=name,action=function() categoryFilter=key;filterButton:SetText(name);T.page=1;T.Refresh() end} end
   U.Menu(filterButton,'NOTE CATEGORY FILTER',entries)
  end)
  entry=U.EditBox(root,'Name a farming spot, rare sighting, or place to revisit');entry:SetSize(388,28);entry:SetPoint('TOPLEFT',18,-96);entry:SetMaxLetters(80);entry:SetScript('OnEscapePressed',function(self) self:ClearFocus() end)
  local save=U.Button(root);save:SetSize(184,28);save:SetPoint('TOPLEFT',418,-96);save:SetText('Save current position')
  save:SetScript('OnClick',function() local p,msg=T.SaveHere(entry:GetText());notice:SetText(msg);if p then entry:SetText('');selected=nil;T.Refresh() end end)
  local rename=U.Button(root);rename:SetSize(184,26);rename:SetPoint('TOPLEFT',18,-134);rename:SetText('Rename selected note')
  rename:SetScript('OnClick',function() notice:SetText(T.Rename(selected,entry:GetText()) and 'Note renamed.' or 'Select a note and enter a name first.') end)
  local nearest=U.Button(root);nearest:SetSize(184,26);nearest:SetPoint('TOPLEFT',214,-134);nearest:SetText('Find nearby service');nearest:SetScript('OnClick',function() T.NearestMenu(nearest) end)
  local overlay=U.Button(root);overlay:SetSize(192,26);overlay:SetPoint('TOPLEFT',410,-134);overlay:SetText('Overlay presets');overlay:SetScript('OnClick',function() ForeverCompanionMapOverlay.PresetMenu(overlay) end)
  rows={}
  for i=1,5 do
   local row=U.Button(root);row:SetSize(584,58);row:SetPoint('TOPLEFT',18,-176-(i-1)*64)
   row.title=text(row,10,-8,450,13,'');row.detail=text(row,10,-31,450,11,'')
   row:SetScript('OnClick',function() if row.note then selected=row.note.id;entry:SetText(row.note.label);T.Refresh() end end)
   local actions=U.Button(row);actions:SetSize(86,27);actions:SetPoint('RIGHT',-9,0);actions:SetText('Actions')
   actions:SetScript('OnClick',function()
    if not row.note then return end;local id=row.note.id
    U.Menu(actions,'PERSONAL NOTE',{
     {label='Navigate to saved position',action=function() notice:SetText(T.Navigate(id)) end},
     {label='Category, icon & color',action=function() T.CategoryMenu(actions,id) end},
     {label='Rename (select this note)',action=function() local p=T.Find(id);if p then selected=id;entry:SetText(p.label);T.Refresh() end end},
     {label='Delete note...',action=function() U.Menu(actions,'DELETE THIS NOTE?',{{label='Delete personal note',action=function() T.Remove(id);selected=nil;T.Refresh();notice:SetText('Note removed.') end},{label='Cancel',action=function() end}}) end},
    })
   end);rows[i]=row
  end
  notice=text(root,18,-502,584,11,'');notice:SetHeight(38);notice:SetWordWrap(true)
  previous=U.Button(root);previous:SetSize(90,26);previous:SetPoint('BOTTOMLEFT',18,15);previous:SetText('Previous');previous:SetScript('OnClick',function() T.page=T.page-1;T.Refresh() end)
  nextPage=U.Button(root);nextPage:SetSize(90,26);nextPage:SetPoint('BOTTOMRIGHT',-18,15);nextPage:SetText('Next');nextPage:SetScript('OnClick',function() T.page=T.page+1;T.Refresh() end)
  counter=text(root,220,-550,180,11,'');counter:ClearAllPoints();counter:SetPoint('BOTTOM',0,21);counter:SetJustifyH('CENTER');root:Hide()
 end
 if root:IsShown() then root:Hide() else T.Refresh();root:Show();T.Refresh() end
end
function T.DrawMap(canvas,map,width,height,scale)
 for _,p in ipairs(mapPins) do p:Hide() end
 local points={};for _,note in ipairs(T.List(map)) do points[#points+1]={x=note.x,y=note.y,label=note.label,symbol='N',note=note} end
 local groups=ForeverCompanionServiceClusters.Build(points,width*scale,height*scale,20)
 for i,group in ipairs(groups) do
  local note=group[1].note
  local p=mapPins[i]
  if p and p.canvas~=canvas then p:Hide();p=nil end
  if not p then
   p=CreateFrame('Button',nil,canvas);p:SetSize(18,18);p:SetFrameLevel(canvas:GetFrameLevel()+105)
   p.icon=p:CreateTexture(nil,'ARTWORK');p.icon:SetAllPoints(p)
   p.count=ForeverCompanionInterface.Text(p,10);p.count:SetPoint('CENTER',p,'TOPRIGHT',0,0)
   p:SetScript('OnEnter',function(self) if GameTooltip and self.note then GameTooltip:SetOwner(self,'ANCHOR_RIGHT');GameTooltip:SetText(self.note.label);GameTooltip:AddLine(#self.group>1 and (#self.group..' notes nearby · click to choose') or 'Personal note · click to navigate',.5,.85,1,true);GameTooltip:Show() end end)
   p:SetScript('OnLeave',function() if GameTooltip then GameTooltip:Hide() end end)
   p:SetScript('OnClick',function(self)
    if not self.note then return end
    if #self.group==1 then T.Navigate(self.note.id);return end
    local entries={};for j=1,math.min(8,#self.group) do local n=self.group[j].note
     entries[#entries+1]={label=n.label,action=function() T.Navigate(n.id) end}
    end
    entries[#entries+1]={label='Browse all personal notes',action=T.Toggle}
    ForeverCompanionInterface.Menu(self,'NEARBY PERSONAL NOTES',entries,nil,340)
   end);mapPins[i]=p
  end
  local style=T.NoteStyle(note);p.icon:SetTexture(style.icon);p.icon:SetVertexColor(unpack(style.color))
  p.canvas=canvas;p.note=note;p.group=group;p.count:SetText(#group>1 and tostring(#group) or '');p:ClearAllPoints();p:SetPoint('CENTER',canvas,'TOPLEFT',note.x*width*scale,-note.y*height*scale);p:SetScale(1/scale);p:Show()
 end
end
function T.HideMap() for _,p in ipairs(mapPins) do p:Hide() end end
