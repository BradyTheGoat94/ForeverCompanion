-- Independent native map artwork. Never takes ownership of WorldMapFrame.
local M={};ForeverCompanionMapOverlay=M
local frame,title,message,player,header,legend
local tiles,pins,badges={},{},{}
local mapID,artID,layout,editing,elapsed,slow
local forceVisible=false
local viewportWidth,viewportHeight
local inspecting,panStart,zoomLabel,inspectButton
local hitPins,pointCache={},{}
local explorationTiles,explorationLayout={},{}
local mapWorldWidth,mapWorldHeight
local function finite(n)
 return not(issecretvalue and issecretvalue(n)) and type(n)=='number' and n==n and math.abs(n)<math.huge
end
local function coord(n) return finite(n) and n>=0 and n<=1 end
local function settings()
 ForeverCompanionDB=ForeverCompanionDB or {}
 if type(ForeverCompanionDB.mapOverlay)~='table' then ForeverCompanionDB.mapOverlay={} end
 local d=ForeverCompanionDB.mapOverlay
 if not finite(d.opacity) then d.opacity=.35 end;d.opacity=math.max(.15,math.min(.8,d.opacity))
 if not finite(d.width) then d.width=600 end;d.width=math.max(300,math.min(900,d.width))
 if not finite(d.zoom) then d.zoom=1 end;d.zoom=math.max(1,math.min(4,d.zoom))
 local edge=.5/d.zoom
 d.centerX=finite(d.centerX) and math.max(edge,math.min(1-edge,d.centerX)) or .5
 d.centerY=finite(d.centerY) and math.max(edge,math.min(1-edge,d.centerY)) or .5
 return d
end
-- Native files are row-major; edge tiles must crop rather than stretch.
function M.Layout(layer,files,width)
 if type(layer)~='table' or type(files)~='table' or not finite(width) or width<=0 then return end
 for _,k in ipairs({'layerWidth','layerHeight','tileWidth','tileHeight'}) do
  if not finite(layer[k]) or layer[k]<=0 or layer[k]>32768 then return end
 end
 local cols=math.ceil(layer.layerWidth/layer.tileWidth);local rows=math.ceil(layer.layerHeight/layer.tileHeight)
 if cols*rows>64 then return end
 local scale=width/layer.layerWidth;local result={width=width,height=layer.layerHeight*scale}
 if result.height>width*3 then return end
 for row=1,rows do for col=1,cols do
  local i=(row-1)*cols+col;local file=files[i]
  if not finite(file) or file<=0 or file~=math.floor(file) then return end
  local w=math.min(layer.tileWidth,layer.layerWidth-(col-1)*layer.tileWidth)
  local h=math.min(layer.tileHeight,layer.layerHeight-(row-1)*layer.tileHeight)
  result[i]={file=file,x=(col-1)*layer.tileWidth*scale,y=(row-1)*layer.tileHeight*scale,w=w*scale,h=h*scale,u=w/layer.tileWidth,v=h/layer.tileHeight}
 end end
 return result
end
-- Outdoor map detail is a separate native exploration layer. Cities often
-- have complete base artwork, which masked this missing layer in earlier builds.
function M.ExplorationLayout(layer,overlays,width)
 local result={}
 if type(layer)~='table' or not finite(layer.layerWidth) or layer.layerWidth<=0 or not finite(width) or width<=0 then return result end
 local tw,th=layer.tileWidth,layer.tileHeight
 if not finite(tw) or not finite(th) or tw<=0 or th<=0 then return result end
 local scale=width/layer.layerWidth
 local function fileSize(n) local size=16;while size<n do size=size*2 end;return size end
 for _,o in ipairs(type(overlays)=='table' and overlays or {}) do
  if type(o)=='table' and not o.isShownByMouseOver and finite(o.textureWidth) and finite(o.textureHeight) and finite(o.offsetX) and finite(o.offsetY) and o.textureWidth>0 and o.textureHeight>0 and o.textureWidth<=32768 and o.textureHeight<=32768 and type(o.fileDataIDs)=='table' then
   local cols,rows=math.ceil(o.textureWidth/tw),math.ceil(o.textureHeight/th)
   if cols*rows<=64 then for row=1,rows do for col=1,cols do
    local file=o.fileDataIDs[(row-1)*cols+col]
    if finite(file) and file>0 and file%1==0 and #result<512 then
     local w,h=math.min(tw,o.textureWidth-(col-1)*tw),math.min(th,o.textureHeight-(row-1)*th)
     result[#result+1]={file=file,x=(o.offsetX+(col-1)*tw)*scale,y=(o.offsetY+(row-1)*th)*scale,w=w*scale,h=h*scale,
      u=w/(col<cols and tw or fileSize(w)),v=h/(row<rows and th or fileSize(h)),top=o.isDrawOnTopLayer==true}
    end
   end end end
  end
 end
 return result
end
function M.Project(x,y,width,height,view)
 if not coord(x) or not coord(y) or not finite(width) or not finite(height) or width<=0 or height<=0 then return end
 local px=(x-view.centerX)*view.zoom*width+width/2
 local py=(y-view.centerY)*view.zoom*height+height/2
 return px,py,px>=0 and px<=width and py>=0 and py<=height
end
-- Facing and texture rotation both increase counterclockwise from north.
-- Correct for maps whose artwork and world dimensions have different aspects.
function M.FacingAngle(facing,width,height,worldWidth,worldHeight)
 if not finite(facing) then return end
 if finite(worldWidth) and finite(worldHeight) and worldWidth>0 and worldHeight>0 then
  return math.atan2(math.sin(facing)*width/worldWidth,math.cos(facing)*height/worldHeight)
 end
 return facing
end
function M.Clip(tile,width,height,view)
 local left=(tile.x/width-view.centerX)*view.zoom*width+width/2
 local top=(tile.y/height-view.centerY)*view.zoom*height+height/2
 local w,h=tile.w*view.zoom,tile.h*view.zoom
 local x,y=math.max(0,left),math.max(0,top)
 local right,bottom=math.min(width,left+w),math.min(height,top+h)
 if right<=x or bottom<=y then return end
 return {x=x,y=y,w=right-x,h=bottom-y,u1=tile.u*(x-left)/w,u2=tile.u*(right-left)/w,v1=tile.v*(y-top)/h,v2=tile.v*(bottom-top)/h}
end
local function hide(list) for _,t in ipairs(list) do t:Hide() end end
local function safe(fn,...)
 if type(fn)~='function' then return end
 local ok,value=pcall(fn,...);if ok then return value end
end
local function position()
 local d=settings();frame:ClearAllPoints()
 if finite(d.x) and finite(d.y) then frame:SetPoint('CENTER',UIParent,'CENTER',d.x,d.y)
 else frame:SetPoint('CENTER',UIParent,'CENTER',0,60) end
end
local function publicText(s) return not(issecretvalue and issecretvalue(s)) and type(s)=='string' and s or nil end
function M.NavigateLocation(p)
 if p.kind=='note' then return ForeverCompanionMapTools.Navigate(p.target.id) end
 if p.kind=='service' then return ForeverCompanionServiceAtlas.Navigate(p.target) end
 if p.kind=='quest' then return ForeverCompanionMapHub.Activate({kind='quest',questID=p.questID,target=p.target}) end
 if p.kind=='poi' then
  local fresh=C_AreaPoiInfo and safe(C_AreaPoiInfo.GetAreaPOIInfo,p.target.map,p.poiID)
  local pos=type(fresh)=='table' and fresh.position
  local ok,x,y=false
  if pos and not(issecretvalue and issecretvalue(pos)) and type(pos.GetXY)=='function' then ok,x,y=pcall(pos.GetXY,pos) end
  if not ok or not coord(x) or not coord(y) or math.abs(x-p.target.x)>.00001 or math.abs(y-p.target.y)>.00001 then return 'This location changed. Refresh the overlay.' end
  return ForeverCompanionQuestWaypoints.Navigate(p.target,true,p.label)
 end
 return 'Location unavailable.'
end
function M.LocationMenu(p,anchor)
 local function report(msg) if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage(msg) end end
 local entries={{label='Navigate to reported position',action=function() report(M.NavigateLocation(p)) end},
  {label='Save position as a personal note',action=function() local _,msg=ForeverCompanionMapTools.Add(p.label,p.target.map,p.target.x,p.target.y);report(msg) end}}
 if p.symbol=='T' then entries[#entries+1]={label='Open Training Guide',action=function() ForeverCompanionTraining.Toggle() end} end
 ForeverCompanionInterface.Menu(anchor,'LOCATION ACTIONS',entries,nil,300)
end
local function refreshPins(reuse)
 hide(pins);hide(badges);if not inspecting then hide(hitPins) end
 if not layout then hide(hitPins);return end
 local points={};local d=settings();local planner=ForeverCompanionQuestPlanner;local way=ForeverCompanionQuestWaypoints
 local function add(target,symbol,label,texture,kind,extra)
  if type(target)=='table' and coord(target.x) and coord(target.y) then
   local p={x=target.x,y=target.y,symbol=symbol,label=publicText(label) or 'Reported location',texture=texture,target=target,kind=kind}
   for k,v in pairs(extra or {}) do p[k]=v end
   points[#points+1]=p;return p
  end
 end
 if reuse then points=pointCache else
  if d.quests~=false and planner and way and planner.IsSupported() then
   local selected=planner.GetSelected()
   for _,e in ipairs(way.MapLocations(mapID,selected and {selected} or {}) or {}) do
    add(e.target,'Q',e.quest.title,'Interface\\GossipFrame\\AvailableQuestIcon','quest',{questID=e.quest.id,detail=way.Describe(e.target)})
   end
  end
  if d.services and ForeverCompanionTownServices then
   local services=ForeverCompanionTownServices.ForMap(mapID)
   if ForeverCompanionServiceClusters then services=ForeverCompanionServiceClusters.Filter(services,ForeverCompanionDB.questMapHiddenServices or {}) end
   for _,p in ipairs(services or {}) do add(p,p.symbol,p.label,ForeverCompanionServiceAtlas and ForeverCompanionServiceAtlas.Icon(p.symbol) or 'Interface\\Icons\\INV_Misc_Map_01','service',{detail=(p.service or 'Service')..' · '..(p.observed and 'Visited nearby player position' or 'Provider reference'),description=p.subtitle}) end
  end
  if d.notes~=false and ForeverCompanionMapTools then
   for _,p in ipairs(ForeverCompanionMapTools.List(mapID)) do local style=ForeverCompanionMapTools.NoteStyle(p);add(p,'N',p.label,style.icon,'note',{color=style.color,detail=style.name..' · Personal note'}) end
  end
  if d.landmarks~=false and C_AreaPoiInfo then
   local ids=safe(C_AreaPoiInfo.GetAreaPOIForMap,mapID)
   if type(ids)=='table' then for i=1,math.min(200,#ids) do
    local info=safe(C_AreaPoiInfo.GetAreaPOIInfo,mapID,ids[i]);local pos=type(info)=='table' and info.position
    local ok,x,y=false
    if pos and not(issecretvalue and issecretvalue(pos)) and type(pos.GetXY)=='function' then ok,x,y=pcall(pos.GetXY,pos) end
    if ok and coord(x) and coord(y) then add({map=mapID,x=x,y=y,source='Blizzard area POI'},'P',publicText(info.name),'Interface\\Icons\\INV_Misc_Map_01','poi',{poiID=ids[i],detail='Client-reported map location',description=publicText(info.description)}) end
   end end
  end
  pointCache=points
 end
 local projected={}
 for _,p in ipairs(points) do
  local x,y,visible=M.Project(p.x,p.y,layout.width,layout.height,d)
  if visible then local c={};for k,v in pairs(p) do c[k]=v end;c.x=x/layout.width;c.y=y/layout.height;projected[#projected+1]=c end
 end
 local groups={}
 if ForeverCompanionServiceClusters then groups=ForeverCompanionServiceClusters.Build(projected,layout.width,layout.height,22)
 else for _,p in ipairs(projected) do groups[#groups+1]={p} end end
 if legend then legend:SetWidth(layout.width);legend:SetText((#groups>80 and ('80 / '..#groups..' clusters shown · ') or '')..(inspecting and 'Inspect: wheel to zoom · drag map to pan · hover/click markers for details' or 'Click-through · use Inspect for location details and wheel zoom')) end
 for i=1,math.min(80,#groups) do
  local group=groups[i];local t=group[1];local p=pins[i]
  for _,candidate in ipairs(group) do if candidate.symbol=='Q' then t=candidate;break end end
  if not p then p=frame:CreateTexture(nil,'OVERLAY');pins[i]=p end
  p:ClearAllPoints();p:SetSize(18,18);p:SetPoint('CENTER',frame,'TOPLEFT',t.x*layout.width,-t.y*layout.height);p:SetTexture(t.texture);p:SetVertexColor(unpack(t.color or {1,1,1}));p:Show()
  if #group>1 then
   local label=badges[i];if not label then label=ForeverCompanionInterface.Text(frame,11);badges[i]=label end
   label:ClearAllPoints();label:SetPoint('CENTER',p,'TOPRIGHT',2,0);label:SetText(tostring(#group));label:Show()
  end
  if inspecting then
   local hit=hitPins[i]
   if not hit then
    hit=CreateFrame('Button',nil,frame);hit:SetSize(24,24);hit:EnableMouse(true)
    hit:SetScript('OnEnter',function(self)
     if not GameTooltip or not self.group then return end
     GameTooltip:SetOwner(self,'ANCHOR_RIGHT');GameTooltip:SetText(self.group[1].label)
     for j=1,math.min(8,#self.group) do local v=self.group[j];if j>1 then GameTooltip:AddLine(v.label,1,.85,.5,true) end
      GameTooltip:AddLine((v.detail or 'Reported position')..(' · %.1f, %.1f'):format(v.target.x*100,v.target.y*100),.75,.85,1,true)
      if v.description then GameTooltip:AddLine(v.description,.8,.85,.9,true) end
     end
     GameTooltip:AddLine('Click to inspect actions / choose a nearby location',.9,.8,.5,true);GameTooltip:Show()
    end)
    hit:SetScript('OnLeave',function() if GameTooltip then GameTooltip:Hide() end end)
    hit:SetScript('OnClick',function(self)
     if not self.group then return end
     if #self.group==1 then M.LocationMenu(self.group[1],self);return end
     local entries={};for j=1,math.min(8,#self.group) do local v=self.group[j];entries[#entries+1]={label=v.label,action=function() M.LocationMenu(v,self) end} end
     entries[#entries+1]={label='Open full map search',action=function() ForeverCompanionMapHub.Open() end}
     ForeverCompanionInterface.Menu(self,'NEARBY LOCATIONS',entries,nil,320)
    end);hitPins[i]=hit
   end
   hit.group=group;hit:ClearAllPoints();hit:SetPoint('CENTER',frame,'TOPLEFT',t.x*layout.width,-t.y*layout.height);hit:Show()
  end
 end
 for i=math.min(80,#groups)+1,#hitPins do hitPins[i]:Hide() end
end
local function updatePlayer()
 player:Hide();if not layout then return end
 local current=safe(C_Map and C_Map.GetBestMapForUnit,'player')
 if not finite(current) or current~=mapID then
  hide(tiles);hide(explorationTiles);hide(pins);hide(badges);hide(hitPins);if legend then legend:Hide() end
  message:SetText('Updating current zone...');message:Show();return
 end
 local pos=safe(C_Map and C_Map.GetPlayerMapPosition,mapID,'player')
 if not pos or (issecretvalue and issecretvalue(pos)) or type(pos.GetXY)~='function' then return end
 local ok,x,y=pcall(pos.GetXY,pos)
 if not ok or not coord(x) or not coord(y) then return end
 local px,py,visible=M.Project(x,y,layout.width,layout.height,settings());if not visible then return end
 player:ClearAllPoints();player:SetPoint('CENTER',frame,'TOPLEFT',px,-py)
 local facing=safe(GetPlayerFacing)
 local angle=M.FacingAngle(facing,layout.width,layout.height,mapWorldWidth,mapWorldHeight)
 if not angle then return end
 player:SetRotation(angle);player:Show()
end
local function drawArt()
 hide(tiles);hide(explorationTiles);if not layout then return end
 local d=settings()
 for i,t in ipairs(layout) do
  local c=M.Clip(t,layout.width,layout.height,d)
  if c then
   local tile=tiles[i];if not tile then tile=frame:CreateTexture(nil,'BACKGROUND');tiles[i]=tile end
   tile:ClearAllPoints();tile:SetPoint('TOPLEFT',c.x,-c.y);tile:SetSize(c.w,c.h);tile:SetTexture(t.file);tile:SetTexCoord(c.u1,c.u2,c.v1,c.v2);tile:SetAlpha(d.opacity);tile:SetDesaturated(d.monochrome~=false);tile:Show()
  end
 end
 if d.detail~=false then for i,t in ipairs(explorationLayout) do
  local c=M.Clip(t,layout.width,layout.height,d)
  if c then
   local tile=explorationTiles[i]
   if not tile then tile=frame:CreateTexture(nil,'BACKGROUND',nil,t.top and 2 or 1);explorationTiles[i]=tile end
   if tile.SetDrawLayer then tile:SetDrawLayer('BACKGROUND',t.top and 2 or 1) end
   tile:ClearAllPoints();tile:SetPoint('TOPLEFT',c.x,-c.y);tile:SetSize(c.w,c.h);tile:SetTexture(t.file);tile:SetTexCoord(c.u1,c.u2,c.v1,c.v2);tile:SetAlpha(d.opacity);tile:SetDesaturated(d.monochrome~=false);tile:Show()
  end
 end end
 if zoomLabel then zoomLabel:SetText(('%.1f×'):format(d.zoom)) end
end
function M.Redraw() if frame and frame:IsShown() then drawArt();refreshPins(true);updatePlayer() end end
function M.SetZoom(value)
 if not finite(value) then return false end
 settings().zoom=math.max(1,math.min(4,value));settings();M.Redraw();return true
end
function M.Pan(dx,dy)
 if not finite(dx) or not finite(dy) then return false end
 local d=settings();d.centerX=d.centerX+dx;d.centerY=d.centerY+dy;settings();M.Redraw();return true
end
function M.CenterPlayer()
 local pos=mapID and safe(C_Map and C_Map.GetPlayerMapPosition,mapID,'player')
 if pos and not(issecretvalue and issecretvalue(pos)) and type(pos.GetXY)=='function' then local ok,x,y=pcall(pos.GetXY,pos);if ok and coord(x) and coord(y) then local d=settings();d.centerX=x;d.centerY=y;settings();M.Redraw();return true end end
 return false
end
function M.Inspect(value)
 inspecting=value==true;editing=false;panStart=nil;settings().controls=true
 frame:EnableMouse(inspecting);if frame.EnableMouseWheel then frame:EnableMouseWheel(inspecting) end;header:Show()
 if inspectButton then inspectButton:SetText(inspecting and 'Inspect: On' or 'Inspect: Off') end
 M.Redraw()
end
function M.ContextAlpha(combat,config,override)
 if issecretvalue and issecretvalue(combat) then combat=nil end
 return config and config.fadeCombat and combat==true and not override and .3 or 1
end
function M.ApplyContext()
 if not frame then return end
 local combat=safe(InCombatLockdown)
 local alpha=M.ContextAlpha(combat,settings(),forceVisible or editing)
 frame:SetAlpha(alpha)
end
function M.Refresh(force)
 if not frame or not frame:IsShown() then return end
 M.ApplyContext()
 local id=safe(C_Map and C_Map.GetBestMapForUnit,'player')
 if not finite(id) or id<=0 then id=nil end
 local art=id and safe(C_Map and C_Map.GetMapArtID,id)
 if not finite(art) or art<=0 then art=nil end
 local sw,sh=UIParent:GetWidth(),UIParent:GetHeight()
 if not finite(sw) then sw=nil end;if not finite(sh) then sh=nil end
 if force or id~=mapID or art~=artID or not art or not layout or sw~=viewportWidth or sh~=viewportHeight then
  viewportWidth,viewportHeight=sw,sh
  if id~=mapID then settings().centerX=.5;settings().centerY=.5;pointCache={} end
  mapID,artID=id,art;layout=nil;explorationLayout={};hide(tiles);hide(explorationTiles);hide(pins);hide(badges);hide(hitPins);player:Hide()
  mapWorldWidth,mapWorldHeight=nil,nil
  if id and C_Map and type(C_Map.GetMapWorldSize)=='function' then local ok,w,h=pcall(C_Map.GetMapWorldSize,id);if ok then mapWorldWidth,mapWorldHeight=w,h end end
  local layers=id and safe(C_Map and C_Map.GetMapArtLayers,id)
  local files=id and safe(C_Map and C_Map.GetMapArtLayerTextures,id,1)
  local d=settings();local width=d.width
  if finite(sw) and sw>100 then width=math.min(width,sw*.9) end
  layout=M.Layout(type(layers)=='table' and layers[1],files,width)
  if layout and finite(sh) and layout.height>sh*.8 then layout=M.Layout(layers[1],files,width*sh*.8/layout.height) end
  if layout then explorationLayout=M.ExplorationLayout(layers[1],safe(C_MapExplorationInfo and C_MapExplorationInfo.GetExploredMapTextures,id),layout.width) end
  frame:SetSize(layout and layout.width or width,layout and layout.height or 100)
  header:SetWidth(layout and layout.width or width);title:SetWidth(math.max(60,(layout and layout.width or width)-116))
  drawArt()
  local info=id and safe(C_Map and C_Map.GetMapInfo,id)
  title:SetText('Overlay · '..(type(info)=='table' and info.name or 'Current zone'))
  message:SetText(layout and '' or 'Map artwork unavailable here.');message:SetShown(not layout)
  if legend then legend:SetShown(layout~=nil) end
 end
 refreshPins();updatePlayer()
end
function M.Edit(value)
 inspecting=false;hide(hitPins);if frame.EnableMouseWheel then frame:EnableMouseWheel(false) end;if inspectButton then inspectButton:SetText('Inspect: Off') end;editing=value==true;settings().controls=true;frame:EnableMouse(editing);header:Show();M.ApplyContext()
 title:SetText(editing and 'Overlay · drag map to move · Options to lock' or 'Overlay · click-through')
end
local presets={
 detailed={opacity=.55,width=780,quests=true,services=true,notes=true,monochrome=false,detail=true},
 exploring={opacity=.2,width=780,quests=false,services=false,notes=true,monochrome=true},
 questing={opacity=.35,width=600,quests=true,services=false,notes=true,monochrome=true},
 town={opacity=.5,width=420,quests=false,services=true,notes=true,monochrome=false},
}
function M.Preset(name)
 local preset=presets[name];if not preset then return false end
 local d=settings();for k,v in pairs(preset) do d[k]=v end;d.preset=name
 M.Toggle(true);return true
end
function M.PresetMenu(anchor)
 local entries={}
 for _,name in ipairs({'detailed','exploring','questing','town'}) do local key=name
  entries[#entries+1]={label=name:sub(1,1):upper()..name:sub(2),selected=settings().preset==name,action=function() M.Preset(key) end}
 end
 ForeverCompanionInterface.Menu(anchor or header,'OVERLAY PRESETS',entries)
end
function M.Options()
 local U=ForeverCompanionInterface;local d=settings()
 if not frame then M.Toggle(true) end
 local function submenu(title,values,key,suffix)
  local entries={};for _,n in ipairs(values) do local value=n
   entries[#entries+1]={label=tostring(key=='opacity' and math.floor(n*100) or n)..suffix,action=function() d[key]=value;d.preset=nil;M.Refresh(true) end}
  end;U.Menu(header,title,entries)
 end
 U.Menu(header,'TRANSPARENT MAP',{
  {label=editing and 'Lock / click-through' or 'Move overlay',action=function() M.Edit(not editing) end},
  {label='Inspect location details',action=function() M.Inspect(not inspecting) end},
  {label='Reset zoom / pan',action=function() local d=settings();d.centerX=.5;d.centerY=.5;M.SetZoom(1) end},
  {label='Training Guide',action=function() ForeverCompanionTraining.Toggle() end},
  {label='Detailed / Exploring / Questing / Town',action=function() M.PresetMenu(header) end},
  {label='Artwork opacity...',action=function() submenu('ARTWORK OPACITY',{.2,.35,.5,.65},'opacity','%') end},
  {label='Overlay size...',action=function() submenu('OVERLAY WIDTH',{420,600,780},'width','') end},
  {label='Map layers...',action=function() U.Menu(header,'OVERLAY LAYERS',{
   {label='Explored terrain detail',selected=d.detail~=false,action=function() d.detail=d.detail==false;M.Refresh(true) end},
   {label='Monochrome artwork',selected=d.monochrome~=false,action=function() d.monochrome=d.monochrome==false;d.preset=nil;M.Refresh(true) end},
   {label='Focused quest markers',selected=d.quests~=false,action=function() d.quests=d.quests==false;d.preset=nil;M.Refresh(true) end},
   {label='Service markers',selected=d.services==true,action=function() d.services=not d.services;d.preset=nil;M.Refresh(true) end},
   {label='Native location landmarks',selected=d.landmarks~=false,action=function() d.landmarks=d.landmarks==false;M.Refresh(true) end},
   {label='Personal notes',selected=d.notes~=false,action=function() d.notes=d.notes==false;d.preset=nil;M.Refresh(true) end},
  }) end},
  {label='Search map companion',action=function() ForeverCompanionMapHub.Open() end},
  {label='Find nearby service...',action=function() ForeverCompanionMapTools.NearestMenu(header) end},
  {label='Hide controls (restore with command)',action=function() M.Inspect(false);editing=false;frame:EnableMouse(false);d.controls=false;header:Hide() end},
  {label='Fade during combat',selected=d.fadeCombat==true,action=function() d.fadeCombat=not d.fadeCombat;forceVisible=false;M.ApplyContext() end},
  {label=forceVisible and 'Use automatic fading' or 'Keep full visibility this session',action=function() forceVisible=not forceVisible;M.ApplyContext() end},
  {label='Reset position',action=function() d.x=nil;d.y=nil;position() end},
 })
end
local function create()
 if frame then return end
 local U=ForeverCompanionInterface
 frame=CreateFrame('Frame','ForeverCompanionMapOverlayFrame',UIParent);frame:Hide();frame:SetFrameStrata('LOW');frame:SetSize(600,400)
 frame:SetMovable(true);frame:SetClampedToScreen(true);frame:EnableMouse(false);frame:RegisterForDrag('LeftButton')
 frame:SetScript('OnDragStart',function()
  if editing then frame:StartMoving() elseif inspecting and layout and GetCursorPosition then
   local x,y=GetCursorPosition();local scale=frame:GetEffectiveScale();if finite(x) and finite(y) and finite(scale) and scale>0 then local d=settings();panStart={x=x/scale,y=y/scale,cx=d.centerX,cy=d.centerY} end
  end
 end)
 frame:SetScript('OnDragStop',function()
  if not editing then panStart=nil;return end
  frame:StopMovingOrSizing();local x,y=frame:GetCenter();local px,py=UIParent:GetCenter()
  local fs=frame:GetEffectiveScale();local ps=UIParent:GetEffectiveScale()
  if finite(x) and finite(y) and finite(px) and finite(py) and finite(fs) and finite(ps) and fs>0 then
   local d=settings();d.x=x-px*ps/fs;d.y=y-py*ps/fs
  end
 end)
 header=CreateFrame('Frame',nil,frame);header:SetPoint('BOTTOMLEFT',frame,'TOPLEFT',0,4);header:SetSize(420,25)
 title=U.Text(header,12,U.palette.muted);title:SetPoint('LEFT',0,0);title:SetWidth(285)
 local options=U.Button(header);options:SetSize(78,24);options:SetPoint('TOPRIGHT',header,'TOPRIGHT',-32,0);options:SetText('Options');options:SetScript('OnClick',M.Options)
 local close=U.Button(header);close:SetSize(26,24);close:SetPoint('TOPRIGHT',header,'TOPRIGHT',0,0);close:SetText('X');close:SetScript('OnClick',function() M.Toggle(false) end)
 local tools=CreateFrame('Frame',nil,header);tools:SetPoint('BOTTOMLEFT',header,'TOPLEFT',0,3);tools:SetSize(280,24)
 local minus=U.Button(tools);minus:SetSize(22,23);minus:SetPoint('LEFT',0,0);minus:SetText('-');minus:SetScript('OnClick',function() M.SetZoom(settings().zoom/1.25) end)
 zoomLabel=U.Text(tools,11);zoomLabel:SetPoint('LEFT',29,0);zoomLabel:SetWidth(42)
 local plus=U.Button(tools);plus:SetSize(22,23);plus:SetPoint('LEFT',76,0);plus:SetText('+');plus:SetScript('OnClick',function() M.SetZoom(settings().zoom*1.25) end)
 local center=U.Button(tools);center:SetSize(64,23);center:SetPoint('LEFT',106,0);center:SetText('My pos.');center:SetScript('OnClick',M.CenterPlayer)
 inspectButton=U.Button(tools);inspectButton:SetSize(98,23);inspectButton:SetPoint('LEFT',178,0);inspectButton:SetText('Inspect: Off');inspectButton:SetScript('OnClick',function() M.Inspect(not inspecting) end)
 frame:SetScript('OnHide',function() frame:StopMovingOrSizing();panStart=nil;inspecting=false;editing=false;hide(hitPins);if GameTooltip then GameTooltip:Hide() end end)
 frame:SetScript('OnMouseWheel',function(_,delta) if inspecting then M.SetZoom(settings().zoom*(delta>0 and 1.25 or .8)) end end)
 message=U.Text(frame,14,U.palette.muted);message:SetPoint('CENTER')
 legend=U.Text(frame,10,U.palette.muted);legend:SetPoint('TOPLEFT',frame,'BOTTOMLEFT',0,-6);legend:SetHeight(30);legend:SetWordWrap(true)
 player=frame:CreateTexture(nil,'OVERLAY',nil,7);player:SetSize(26,26);player:SetTexture('Interface\\Minimap\\MinimapArrow')
 frame:SetScript('OnUpdate',function(_,dt)
  if panStart and layout and GetCursorPosition then
   local x,y=GetCursorPosition();local scale=frame:GetEffectiveScale()
   if finite(x) and finite(y) and finite(scale) and scale>0 then local d=settings();d.centerX=panStart.cx-(x/scale-panStart.x)/(layout.width*d.zoom);d.centerY=panStart.cy+(y/scale-panStart.y)/(layout.height*d.zoom);settings();M.Redraw() end
  end
  elapsed=(elapsed or 0)+dt;slow=(slow or 0)+dt
  if slow>=1 then slow=0;elapsed=0;M.Refresh() elseif elapsed>=.05 then elapsed=0;updatePlayer() end
 end)
 position()
end
function M.Toggle(value)
 create();if value==nil then value=not frame:IsShown() end
 settings().visible=value==true;frame:SetShown(value==true)
 if value then frame:EnableMouse(false);if frame.EnableMouseWheel then frame:EnableMouseWheel(false) end;editing=false;inspecting=false;panStart=nil;hide(hitPins);if inspectButton then inspectButton:SetText('Inspect: Off') end;header:SetShown(settings().controls~=false);M.Refresh(true) end
end
function M.Command(command)
 if presets[command] then M.Preset(command)
 elseif command=='inspect' then M.Toggle(true);M.Inspect(true)
 elseif command=='zoom in' then M.Toggle(true);M.SetZoom(settings().zoom*1.25)
 elseif command=='zoom out' then M.Toggle(true);M.SetZoom(settings().zoom*.8)
 elseif command=='zoom reset' then M.Toggle(true);settings().centerX=.5;settings().centerY=.5;M.SetZoom(1)
 elseif command=='options' then M.Toggle(true);M.Options()
 elseif command=='edit' then M.Toggle(true);M.Edit(true)
 elseif command=='lock' then M.Toggle(true);M.Edit(false)
 elseif command=='controls' then M.Toggle(true);settings().controls=true;header:Show()
 elseif command=='reset' then local d=settings();d.x=nil;d.y=nil;M.Toggle(true);position()
 elseif command=='show' then forceVisible=true;M.Toggle(true)
 elseif command=='auto' then forceVisible=false;M.ApplyContext()
 elseif command=='hide' then M.Toggle(false)
 else M.Toggle() end
end
local events=CreateFrame('Frame');for _,event in ipairs({'PLAYER_ENTERING_WORLD','MAP_EXPLORATION_UPDATED','PLAYER_REGEN_DISABLED','PLAYER_REGEN_ENABLED'}) do events:RegisterEvent(event) end
events:SetScript('OnEvent',function(_,event) if event=='PLAYER_ENTERING_WORLD' then if settings().visible then M.Toggle(true) end elseif event=='MAP_EXPLORATION_UPDATED' then M.Refresh(true) else M.ApplyContext() end end)
