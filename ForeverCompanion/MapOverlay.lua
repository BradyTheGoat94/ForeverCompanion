-- Independent native map artwork. Never takes ownership of WorldMapFrame.
local M={};ForeverCompanionMapOverlay=M
local frame,title,message,player,header,legend
local tiles,pins,badges={},{},{}
local mapID,artID,layout,editing,elapsed,slow
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
local function refreshPins()
 hide(pins);hide(badges)
 if not layout then return end
 local points={};local d=settings();local planner=ForeverCompanionQuestPlanner;local way=ForeverCompanionQuestWaypoints
 local function add(x,y,symbol,label,texture)
  if coord(x) and coord(y) then points[#points+1]={x=x,y=y,symbol=symbol,label=label or '',texture=texture} end
 end
 if d.quests~=false and planner and way and planner.IsSupported() then
  local selected=planner.GetSelected()
  for _,e in ipairs(way.MapLocations(mapID,selected and {selected} or {}) or {}) do
   add(e.target.x,e.target.y,'Q',e.quest.title,'Interface\\GossipFrame\\AvailableQuestIcon')
  end
 end
 if d.services and ForeverCompanionTownServices then
  local services=ForeverCompanionTownServices.ForMap(mapID)
  if ForeverCompanionServiceClusters then services=ForeverCompanionServiceClusters.Filter(services,ForeverCompanionDB.questMapHiddenServices or {}) end
  for _,p in ipairs(services or {}) do add(p.x,p.y,p.symbol,p.label,ForeverCompanionServiceAtlas and ForeverCompanionServiceAtlas.Icon(p.symbol) or 'Interface\\Icons\\INV_Misc_Map_01') end
 end
 if d.notes~=false and ForeverCompanionMapTools then
  for _,p in ipairs(ForeverCompanionMapTools.List(mapID)) do add(p.x,p.y,'N',p.label,'Interface\\Icons\\INV_Misc_Note_01') end
 end
 local groups={}
 if ForeverCompanionServiceClusters then groups=ForeverCompanionServiceClusters.Build(points,layout.width,layout.height,22)
 else for _,p in ipairs(points) do groups[#groups+1]={p} end end
 local selected=d.quests~=false and planner and planner.IsSupported() and planner.GetSelected()
 local detail=selected and way and way.Describe and way.Explain(selected,mapID) or 'Quest, service and note clusters · counts include nearby markers'
 if legend then legend:SetWidth(layout.width);legend:SetText((#groups>80 and ('80 / '..#groups..' clusters shown · enlarge map or hide a layer. ') or '')..detail) end
 for i=1,math.min(80,#groups) do
  local group=groups[i];local t=group[1];local p=pins[i]
  for _,candidate in ipairs(group) do if candidate.symbol=='Q' then t=candidate;break end end
  if not p then p=frame:CreateTexture(nil,'OVERLAY');pins[i]=p end
  p:ClearAllPoints();p:SetSize(18,18);p:SetPoint('CENTER',frame,'TOPLEFT',t.x*layout.width,-t.y*layout.height);p:SetTexture(t.texture);p:Show()
  if #group>1 then
   local label=badges[i];if not label then label=ForeverCompanionInterface.Text(frame,11);badges[i]=label end
   label:ClearAllPoints();label:SetPoint('CENTER',p,'TOPRIGHT',2,0);label:SetText(tostring(#group));label:Show()
  end
 end
end
local function updatePlayer()
 player:Hide();if not layout then return end
 local pos=safe(C_Map and C_Map.GetPlayerMapPosition,mapID,'player')
 if not pos or type(pos.GetXY)~='function' then return end
 local ok,x,y=pcall(pos.GetXY,pos)
 if not ok or not coord(x) or not coord(y) then return end
 player:ClearAllPoints();player:SetPoint('CENTER',frame,'TOPLEFT',x*layout.width,-y*layout.height)
 local facing=safe(GetPlayerFacing);player:SetRotation(finite(facing) and -facing or 0);player:Show()
end
function M.Refresh(force)
 if not frame or not frame:IsShown() then return end
 local id=safe(C_Map and C_Map.GetBestMapForUnit,'player')
 if not finite(id) or id<=0 then id=nil end
 local art=id and safe(C_Map and C_Map.GetMapArtID,id)
 if force or id~=mapID or art~=artID or not layout then
  mapID,artID=id,art;layout=nil;hide(tiles);hide(pins);hide(badges);player:Hide()
  local layers=id and safe(C_Map and C_Map.GetMapArtLayers,id)
  local files=id and safe(C_Map and C_Map.GetMapArtLayerTextures,id,1)
  local d=settings();local width=d.width
  local sw=UIParent:GetWidth();local sh=UIParent:GetHeight()
  if finite(sw) and sw>100 then width=math.min(width,sw*.9) end
  layout=M.Layout(type(layers)=='table' and layers[1],files,width)
  if layout and finite(sh) and layout.height>sh*.8 then layout=M.Layout(layers[1],files,width*sh*.8/layout.height) end
  frame:SetSize(layout and layout.width or width,layout and layout.height or 100)
  for i,t in ipairs(layout or {}) do
   local tile=tiles[i];if not tile then tile=frame:CreateTexture(nil,'BACKGROUND');tiles[i]=tile end
   tile:ClearAllPoints();tile:SetPoint('TOPLEFT',t.x,-t.y);tile:SetSize(t.w,t.h);tile:SetTexture(t.file)
   tile:SetTexCoord(0,t.u,0,t.v);tile:SetAlpha(d.opacity);tile:SetDesaturated(d.monochrome~=false);tile:Show()
  end
  local info=id and safe(C_Map and C_Map.GetMapInfo,id)
  title:SetText('Overlay · '..(type(info)=='table' and info.name or 'Current zone'))
  message:SetText(layout and '' or 'Map artwork unavailable here.');message:SetShown(not layout)
  if legend then legend:SetShown(layout~=nil) end
 end
 refreshPins();updatePlayer()
end
function M.Edit(value)
 editing=value==true;settings().controls=true;frame:EnableMouse(editing);header:Show()
 title:SetText(editing and 'Overlay · drag map to move · Options to lock' or 'Overlay · click-through')
end
local presets={
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
 for _,name in ipairs({'exploring','questing','town'}) do local key=name
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
  {label='Exploring / Questing / Town',action=function() M.PresetMenu(header) end},
  {label='Artwork opacity...',action=function() submenu('ARTWORK OPACITY',{.2,.35,.5,.65},'opacity','%') end},
  {label='Overlay size...',action=function() submenu('OVERLAY WIDTH',{420,600,780},'width','') end},
  {label='Map layers...',action=function() U.Menu(header,'OVERLAY LAYERS',{
   {label='Monochrome artwork',selected=d.monochrome~=false,action=function() d.monochrome=d.monochrome==false;d.preset=nil;M.Refresh(true) end},
   {label='Focused quest markers',selected=d.quests~=false,action=function() d.quests=d.quests==false;d.preset=nil;M.Refresh(true) end},
   {label='Service markers',selected=d.services==true,action=function() d.services=not d.services;d.preset=nil;M.Refresh(true) end},
   {label='Personal notes',selected=d.notes~=false,action=function() d.notes=d.notes==false;d.preset=nil;M.Refresh(true) end},
  }) end},
  {label='Personal notes & nearby services',action=function() ForeverCompanionMapTools.Toggle() end},
  {label='Find nearby service...',action=function() ForeverCompanionMapTools.NearestMenu(header) end},
  {label='Hide controls (restore with command)',action=function() editing=false;frame:EnableMouse(false);d.controls=false;header:Hide() end},
  {label='Reset position',action=function() d.x=nil;d.y=nil;position() end},
 })
end
local function create()
 if frame then return end
 local U=ForeverCompanionInterface
 frame=CreateFrame('Frame','ForeverCompanionMapOverlayFrame',UIParent);frame:Hide();frame:SetFrameStrata('LOW');frame:SetSize(600,400)
 frame:SetMovable(true);frame:SetClampedToScreen(true);frame:EnableMouse(false);frame:RegisterForDrag('LeftButton')
 frame:SetScript('OnDragStart',function() if editing then frame:StartMoving() end end)
 frame:SetScript('OnDragStop',function()
  frame:StopMovingOrSizing();local x,y=frame:GetCenter();local px,py=UIParent:GetCenter()
  local fs=frame:GetEffectiveScale();local ps=UIParent:GetEffectiveScale()
  if finite(x) and finite(y) and finite(px) and finite(py) and finite(fs) and finite(ps) and fs>0 then
   local d=settings();d.x=x-px*ps/fs;d.y=y-py*ps/fs
  end
 end)
 header=CreateFrame('Frame',nil,frame);header:SetPoint('BOTTOMLEFT',frame,'TOPLEFT',0,4);header:SetSize(420,25)
 title=U.Text(header,12,U.palette.muted);title:SetPoint('LEFT',0,0);title:SetWidth(285)
 local options=U.Button(header);options:SetSize(78,24);options:SetPoint('LEFT',290,0);options:SetText('Options');options:SetScript('OnClick',M.Options)
 local close=U.Button(header);close:SetSize(26,24);close:SetPoint('LEFT',374,0);close:SetText('X');close:SetScript('OnClick',function() M.Toggle(false) end)
 message=U.Text(frame,14,U.palette.muted);message:SetPoint('CENTER')
 legend=U.Text(frame,10,U.palette.muted);legend:SetPoint('TOPLEFT',frame,'BOTTOMLEFT',0,-6);legend:SetHeight(30);legend:SetWordWrap(true)
 player=frame:CreateTexture(nil,'OVERLAY',nil,7);player:SetSize(26,26);player:SetTexture('Interface\\Minimap\\MinimapArrow')
 frame:SetScript('OnUpdate',function(_,dt)
  elapsed=(elapsed or 0)+dt;slow=(slow or 0)+dt
  if slow>=1 then slow=0;elapsed=0;M.Refresh() elseif elapsed>=.2 then elapsed=0;updatePlayer() end
 end)
 position()
end
function M.Toggle(value)
 create();if value==nil then value=not frame:IsShown() end
 settings().visible=value==true;frame:SetShown(value==true)
 if value then frame:EnableMouse(false);editing=false;header:SetShown(settings().controls~=false);M.Refresh(true) end
end
function M.Command(command)
 if presets[command] then M.Preset(command)
 elseif command=='options' then M.Toggle(true);M.Options()
 elseif command=='edit' then M.Toggle(true);M.Edit(true)
 elseif command=='lock' then M.Toggle(true);M.Edit(false)
 elseif command=='controls' then M.Toggle(true);settings().controls=true;header:Show()
 elseif command=='reset' then local d=settings();d.x=nil;d.y=nil;M.Toggle(true);position()
 elseif command=='show' then M.Toggle(true)
 elseif command=='hide' then M.Toggle(false)
 else M.Toggle() end
end
local events=CreateFrame('Frame');events:RegisterEvent('PLAYER_ENTERING_WORLD')
events:SetScript('OnEvent',function() if settings().visible then M.Toggle(true) end end)
