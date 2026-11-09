-- Blizzard-native map artwork with a Companion overlay. Never replaces map tiles,
-- changes watched quests, or modifies Blizzard waypoints.
local M={}
ForeverCompanionQuestMap=M

local provider,worldMap,area,areaChecked,guide,guideTitle,guideHint,modeButton,zoomButton,styleButton,terrain,townButton,pickupButton
local pins,servicePins,zoomPoint={},{},nil
local modeNames={focus="Focus",all="All",off="Off"}
local nextMode={all="focus",focus="off",off="all"}
local function finite(n) return not (issecretvalue and issecretvalue(n)) and type(n)=='number' and n==n and math.abs(n)<math.huge end

local function mode()
 local saved=ForeverCompanionDB and ForeverCompanionDB.questMapMode
 return modeNames[saved] and saved or "all"
end

local function mapStyle()
 local db=ForeverCompanionDB
 if db and db.questMapStyle=="clear" then return "clear" end
 if db and db.questMapStyle=='atlas' then return 'atlas' end
 if db and db.questMapOriginalTerrain==true then return "original" end
 return "clear"
end

local function cycleMapStyle()
 ForeverCompanionDB=ForeverCompanionDB or {}
 local current=mapStyle()
 local nextStyle=current=="atlas" and "clear" or (current=="clear" and "original" or "atlas")
 ForeverCompanionDB.questMapStyle=nextStyle
 ForeverCompanionDB.questMapOriginalTerrain=(nextStyle=="original")
 return nextStyle
end

-- Standalone presentation: native Blizzard map tiles remain the only terrain
-- source. Clear mode displays them without tint/grid; no external map addon.
M.MapStyle=mapStyle
M.SetMapStyle=function(value)
 if value~="atlas" and value~="clear" and value~="original" then return false end
 ForeverCompanionDB=ForeverCompanionDB or {}
 ForeverCompanionDB.questMapStyle=value
 ForeverCompanionDB.questMapOriginalTerrain=(value=="original")
 if M.Refresh then M.Refresh() end
 return true
end

local function sharpenOverlay(texture)
 -- Pixel-align thin overlays without modifying Blizzard map tiles or artwork.
 if texture and texture.SetSnapToPixelGrid then texture:SetSnapToPixelGrid(true) end
 if texture and texture.SetTexelSnappingBias then texture:SetTexelSnappingBias(0) end
end

local function showTerrain(canvas)
 if not terrain then
  terrain=CreateFrame("Frame",nil,canvas)
  terrain:SetAllPoints(canvas)
  terrain:SetFrameLevel(canvas:GetFrameLevel()+1)
  terrain:EnableMouse(false)
  local tint=terrain:CreateTexture(nil,"BACKGROUND")
  tint:SetAllPoints(terrain)
  tint:SetColorTexture(.08,.15,.22,.025)
  sharpenOverlay(tint)
  for i=1,9 do
   local vertical=terrain:CreateTexture(nil,"ARTWORK")
   vertical:SetWidth(1)
   vertical:SetColorTexture(.25,.56,.69,i==5 and .075 or .025)
   sharpenOverlay(vertical)
   local horizontal=terrain:CreateTexture(nil,"ARTWORK")
   horizontal:SetHeight(1)
   horizontal:SetColorTexture(.25,.56,.69,i==5 and .075 or .025)
   sharpenOverlay(horizontal)
   terrain[i]={vertical,horizontal}
  end
 end
 local width,height=canvas:GetWidth(),canvas:GetHeight()
 for i,lines in ipairs(terrain) do
  local x,y=width*i/10,-height*i/10
  lines[1]:ClearAllPoints()
  lines[2]:ClearAllPoints()
  lines[1]:SetPoint("TOP",terrain,"TOPLEFT",x,0)
  lines[1]:SetPoint("BOTTOM",terrain,"BOTTOMLEFT",x,0)
  lines[2]:SetPoint("LEFT",terrain,"TOPLEFT",0,y)
  lines[2]:SetPoint("RIGHT",terrain,"TOPRIGHT",0,y)
 end
 terrain:Show()
end

local function hidePins()
 for _,pin in ipairs(pins) do pin:Hide() end
 for _,pin in ipairs(servicePins) do pin:Hide() end
 if area then area:Hide() end
 if guide then guide:Hide() end
 if terrain then terrain:Hide() end
end

local function createPin(canvas)
 local pin=CreateFrame("Button",nil,canvas)
 pin:EnableMouse(true)
 pin:RegisterForClicks("LeftButtonUp","RightButtonUp")
 pin.ring=pin:CreateTexture(nil,"BACKGROUND",nil,-1)
 pin.ring:SetTexture("Interface\\AddOns\\ForeverCompanion\\Media\\QuestLocationRing")
 pin.ring:SetPoint("CENTER")
 pin.ring:SetVertexColor(.22,.91,1,.95)
 sharpenOverlay(pin.ring)
 local outline=pin:CreateTexture(nil,"BACKGROUND")
 pin.outline=outline
 outline:SetAllPoints(pin)
 outline:SetColorTexture(.03,.08,.11,1)
 sharpenOverlay(outline)
 pin.badge=pin:CreateTexture(nil,"ARTWORK")
 sharpenOverlay(pin.badge)
 pin.badge:SetPoint("TOPLEFT",2,-2)
 pin.badge:SetPoint("BOTTOMRIGHT",-2,2)
 pin.symbol=pin:CreateFontString(nil,"OVERLAY","GameFontNormal")
 pin.symbol:SetPoint("CENTER")
 pin.symbol:SetTextColor(.05,.08,.12)
 pin:SetScript("OnEnter",function(self)
  if not GameTooltip then return end
  local entry=self.entry
  GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
  GameTooltip:SetText(entry.quest.title)
  GameTooltip:AddLine(entry.pickup and (entry.reference and "Quest giver - confirm availability in game" or "Quest pickup reported by Blizzard") or (entry.quest.complete and "Turn-in destination" or (entry.target.objective or "Quest objective")),1,1,1,true)
  GameTooltip:AddLine(entry.target.label or entry.target.source,.68,.75,.82,true)
  if not entry.pickup and ForeverCompanionQuestFieldGuide then
   local done,total,known=ForeverCompanionQuestFieldGuide.Progress(entry.quest)
   if total>0 then GameTooltip:AddLine(done..' / '..total..' objectives complete'..(known<total and ' · some progress unknown' or ''),.7,.85,.75,true) end
   GameTooltip:AddLine('Right-click: quest actions and field guide',.82,.74,.55,true)
  end
  if entry.reference then GameTooltip:AddLine("Level, race, class and quest-chain checks passed. Profession, reputation and event requirements may still apply.",.95,.76,.35,true) end
  if self.pickups and #self.pickups>1 then GameTooltip:AddLine("Shift-click to choose another quest at this location",.95,.76,.35,true) end
  if self.samples>1 then GameTooltip:AddLine("Nearby reported locations: "..self.samples,.68,.75,.82) end
  for _,nearby in ipairs(self.nearby or {}) do
   GameTooltip:AddLine(nearby.quest.title,.81,.87,.92,true)
  end
  GameTooltip:AddLine((self.focused or entry.pickup) and "Click to start arrow" or "Click to focus quest",.46,.84,.96)
  GameTooltip:Show()
 end)
 pin:SetScript("OnLeave",function()
  if GameTooltip then GameTooltip:Hide() end
 end)
 pin:SetScript("OnClick",function(self,button)
  local entry=self.entry
  if button=='RightButton' and not entry.pickup and ForeverCompanionInterface then
   ForeverCompanionInterface.Menu(self,'QUEST ACTIONS',{
    {label='Open quest field guide',action=function() if ForeverCompanionOpenQuestGuide then ForeverCompanionOpenQuestGuide(entry.quest.id) end end},
    {label=ForeverCompanionQuestPlanner.IsPinned(entry.quest) and 'Unpin quest' or 'Pin quest',action=function()
     for index,q in ipairs(ForeverCompanionQuestPlanner.GetLive()) do if q.id==entry.quest.id then ForeverCompanionQuestPlanner.TogglePin(index);break end end
    end},
   })
   return
  end
  if entry.pickup and IsShiftKeyDown and IsShiftKeyDown() and self.pickups and #self.pickups>1 then
   self.pickupIndex=(self.pickupIndex or 1)%#self.pickups+1
   self.entry=self.pickups[self.pickupIndex]
   self:GetScript("OnEnter")(self)
   return
  end
  if entry.pickup then
   local map=worldMap:GetMapID()
   local target=ForeverCompanionQuestDiscovery.Resolve(ForeverCompanionQuestWaypoints.MapPickups(map,ForeverCompanionQuestPlanner.GetLive()),entry.quest.id,entry.target)
   if not target then M.Refresh();guideHint:SetText('This quest pickup changed. Choose a current marker.');return end
   guideHint:SetText(ForeverCompanionQuestWaypoints.Navigate(target,false,entry.quest.title))
  elseif self.focused or (IsShiftKeyDown and IsShiftKeyDown()) then
   if not self.focused then ForeverCompanionQuestPlanner.Select(entry.index) end
   guideHint:SetText(ForeverCompanionQuestWaypoints.Navigate(entry.target,false,entry.quest.title))
  else
   ForeverCompanionQuestPlanner.Select(entry.index)
  end
 end)
 return pin
end

local function townsEnabled()
 return not ForeverCompanionDB or ForeverCompanionDB.questMapHideTowns~=true
end

local function showServices(canvas,mapID,scale)
 if not townsEnabled() then return end
 local points,notice=ForeverCompanionTownServices.ForMap(mapID)
 points=ForeverCompanionServiceClusters.Filter(points,ForeverCompanionDB and ForeverCompanionDB.questMapHiddenServices)
 local cfg=ForeverCompanionDB or {}
 local iconSize=(cfg.mapServiceIconSize==20 or cfg.mapServiceIconSize==28) and cfg.mapServiceIconSize or 24
 local width,height=canvas:GetWidth()*scale,canvas:GetHeight()*scale
 -- Pixel-distance clustering crosses service categories, so a banker,
 -- repair vendor and trainer at the same building remain accessible.
 local ordered=ForeverCompanionServiceClusters.Build(points,width,height,cfg.mapServiceTight and iconSize or iconSize+6)
 for _,oldPin in ipairs(servicePins) do oldPin:Hide();oldPin.locations=nil end
 for i,group in ipairs(ordered) do
  local pin=servicePins[i]
  if not pin then
   pin=CreateFrame("Button",nil,canvas)
   pin:RegisterForClicks("LeftButtonUp","RightButtonUp")
   pin:SetSize(25,25)
   local bg=pin:CreateTexture(nil,"BACKGROUND")
   bg:SetPoint('TOPLEFT',1,-1);bg:SetPoint('BOTTOMRIGHT',-1,1)
   bg:SetColorTexture(.015,.025,.04,.94)
   pin.background=bg
   sharpenOverlay(bg)
   local icon=pin:CreateTexture(nil,"ARTWORK")
   icon:SetPoint("TOPLEFT",pin,"TOPLEFT",3,-3)
   icon:SetPoint("BOTTOMRIGHT",pin,"BOTTOMRIGHT",-3,3)
   icon:SetTexCoord(0,1,0,1)
   pin.icon=icon
   pin.count=pin:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
   pin.count:SetPoint("BOTTOMRIGHT",pin,"BOTTOMRIGHT",5,-3)
   pin.count:SetShadowOffset(1,-1)
   local label=ForeverCompanionInterface.Text(pin,10)
   label:SetPoint('TOP',pin,'BOTTOM',0,-3);label:SetWidth(132);label:SetJustifyH('CENTER');label:SetHeight(15);label:Hide();pin.nameLabel=label
   local pip=pin:CreateTexture(nil,'OVERLAY');pip:SetSize(4,4);pip:SetPoint('TOPLEFT',-1,1);pip:SetColorTexture(.25,.90,.92,1);pin.visitPip=pip
   sharpenOverlay(icon)
   local border=pin:CreateTexture(nil,"BACKGROUND",nil,-1)
   border:SetAllPoints(pin)
   border:SetColorTexture(1,1,1,1)
   pin.border=border
   sharpenOverlay(border)
   pin:SetScript("OnEnter",function(self)
    if self.border then self.border:SetVertexColor(1,1,1,1) end
    if self.nameLabel and self.locations then self.nameLabel:SetText(self.locations[self.locationIndex or 1].label);self.nameLabel:Show() end
    if not GameTooltip then return end
    GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
    local active=self.locations[self.locationIndex or 1]
    GameTooltip:SetText(active.service.."  -  "..active.label)
    if active.subtitle then GameTooltip:AddLine(active.subtitle,.85,.9,1,true) end
    local seen,count,displayed={},0,0
    for _,entry in ipairs(self.locations) do
     local key=entry.service..":"..entry.label
     if not seen[key] then
      seen[key]=true
      count=count+1
      if displayed<6 then
       GameTooltip:AddLine(entry.service..": "..entry.label,.8,.9,1,true)
       displayed=displayed+1
      end
     end
    end
    if count>displayed then
     GameTooltip:AddLine("+"..(count-displayed).." more nearby locations",.65,.78,.85)
    end
    GameTooltip:AddLine(active.source or 'Forever QuestieDB reference',.65,.78,.85,true)
    if active.observed then GameTooltip:AddLine('Your position during a merchant visit, not an exact NPC location. Vendors may move.',.95,.76,.35,true) end
    GameTooltip:AddLine('Click: navigate · Right-click: choose service',.65,.78,.85,true)
    if #self.locations>1 then GameTooltip:AddLine('Shift-click: cycle nearby services',.95,.76,.35,true) end
    GameTooltip:Show()
   end)
   pin:SetScript("OnLeave",function(self)
    if self.nameLabel then self.nameLabel:SetShown((ForeverCompanionDB or {}).mapServiceLabels==true and self.labelAllowed) end
    if self.border and self.markerColor then
     self.border:SetVertexColor(self.markerColor[1],self.markerColor[2],self.markerColor[3],1)
    end
    if GameTooltip then GameTooltip:Hide() end
   end)
   pin:SetScript("OnClick",function(self,button)
    if not self.locations then return end
    if button=='RightButton' then
     local choices={}
     for _,point in ipairs(self.locations) do
      local target=point
      choices[#choices+1]={label=point.service..': '..point.label,action=function() guideHint:SetText(ForeverCompanionServiceAtlas.Navigate(target)) end}
      if #choices>=12 then break end
     end
     choices[#choices+1]={label='Open searchable service atlas',action=function() ForeverCompanionServiceAtlas.Toggle(true) end}
     ForeverCompanionInterface.Menu(self,'NEARBY SERVICES',choices);return
    end
    if IsShiftKeyDown and IsShiftKeyDown() and #self.locations>1 then
     self.locationIndex=(self.locationIndex or 1)%#self.locations+1
     local active=self.locations[self.locationIndex]
     ForeverCompanionServiceAtlas.SetIcon(self.icon,active.symbol)
     self.visitPip:SetShown(active.observed==true)
     self:GetScript("OnEnter")(self)
     return
    end
    local target=self.locations[self.locationIndex or 1]
    if not ForeverCompanionTownServices.Resolve(target) then guideHint:SetText('This service changed. Open the atlas and rescan.');return end
    guideHint:SetText(ForeverCompanionQuestWaypoints.Navigate(target,false,target.label..(target.observed and ' · visited nearby' or '')))
   end)
   servicePins[i]=pin
  end
  local point=group[1]
  pin.locations=group
  pin.locationIndex=1
  pin.count:SetText(#group>1 and tostring(#group) or "")
  -- Smaller, less intrusive POI icons at both zoom levels.
  pin:SetSize(iconSize,iconSize)
  pin.visitPip:SetShown(point.observed==true)
  pin.labelAllowed=i<=12
  pin.nameLabel:SetText(point.label)
  pin.nameLabel:SetShown(cfg.mapServiceLabels==true and pin.labelAllowed)
  ForeverCompanionServiceAtlas.SetIcon(pin.icon,point.symbol)
  if point.symbol=="B" or point.symbol=="AH" then
   pin.background:SetColorTexture(.16,.11,.035,.96)
   pin.markerColor={1,.8,.35}
   pin.border:SetVertexColor(1,.8,.35,1)
  elseif point.symbol=="F" or point.symbol=="M" then
   pin.background:SetColorTexture(.025,.12,.16,.96)
   pin.markerColor={.4,.9,1}
   pin.border:SetVertexColor(.4,.9,1,1)
  else
   pin.background:SetColorTexture(.025,.055,.09,.96)
   pin.markerColor={.7,.82,.94}
   pin.border:SetVertexColor(.7,.82,.94,1)
  end
  local priority=(point.symbol=="B" or point.symbol=="AH") and 94 or 90
  pin:SetFrameLevel(canvas:GetFrameLevel()+priority)
  pin:SetScale(1/scale)
  pin:ClearAllPoints()
  pin:SetPoint("CENTER",canvas,"TOPLEFT",point.x*width,-point.y*height)
  pin:Show()
 end
 return notice,#points
end

function M.OpenAppearance(anchor)
 ForeverCompanionDB=ForeverCompanionDB or {}
 local db=ForeverCompanionDB;local entries={}
 for _,preset in ipairs({{'Small service icons',20},{'Standard service icons',24},{'Large service icons',28}}) do
  local name,size=preset[1],preset[2]
  entries[#entries+1]={label=name,selected=(db.mapServiceIconSize or 24)==size,action=function() db.mapServiceIconSize=size;M.Refresh() end}
 end
 entries[#entries+1]={label='Show service names',selected=db.mapServiceLabels==true,action=function() db.mapServiceLabels=not db.mapServiceLabels;M.Refresh() end}
 entries[#entries+1]={label='Tighter service clusters',selected=db.mapServiceTight==true,action=function() db.mapServiceTight=not db.mapServiceTight;M.Refresh() end}
 entries[#entries+1]={label='Show player map coordinates',selected=db.mapShowCoordinates~=false,action=function() db.mapShowCoordinates=db.mapShowCoordinates==false;M.Refresh() end}
 entries[#entries+1]={label='Reset map dock position',action=function() db.mapDockPosition=nil;if guide then guide:ClearAllPoints();guide:SetPoint('BOTTOMLEFT',worldMap,'BOTTOMLEFT',12,12) end end}
 ForeverCompanionInterface.Menu(anchor or guide,'MAP APPEARANCE',entries)
end
local function createGuide(map)
 local U=ForeverCompanionInterface
 local bar=CreateFrame('Frame','ForeverCompanionMapToolbar',map)
 bar:SetSize(520,54);bar:SetPoint('BOTTOMLEFT',map,'BOTTOMLEFT',12,12);bar:SetFrameLevel(map:GetFrameLevel()+200)
 bar:SetClampedToScreen(true);bar:SetMovable(true);bar:EnableMouse(true);U.Surface(bar)
 ForeverCompanionDB=ForeverCompanionDB or {}
 local db=ForeverCompanionDB
 local position=db.mapDockPosition
 if type(position)=='table' and finite(position.x) and finite(position.y) then
  bar:ClearAllPoints();bar:SetPoint('CENTER',map,'CENTER',position.x,position.y)
 end
 local drag=CreateFrame('Frame',nil,bar);drag:SetPoint('TOPLEFT',0,0);drag:SetSize(310,28);drag:EnableMouse(true);drag:RegisterForDrag('LeftButton')
 drag:SetScript('OnDragStart',function() bar:StartMoving() end)
 drag:SetScript('OnDragStop',function()
  bar:StopMovingOrSizing()
  local x,y=bar:GetCenter();local px,py=map:GetCenter()
  local fs=bar.GetEffectiveScale and bar:GetEffectiveScale();local ps=map.GetEffectiveScale and map:GetEffectiveScale()
  if finite(fs) and fs>0 and finite(ps) and ps>0 and finite(px) and finite(py) then px,py=px*ps/fs,py*ps/fs end
  if finite(x) and finite(y) and finite(px) and finite(py) then
   db.mapDockPosition={x=x-px,y=y-py};bar:ClearAllPoints();bar:SetPoint('CENTER',map,'CENTER',x-px,y-py)
  end
 end)
 local function fitToolbar()
  local width=map.GetWidth and map:GetWidth()
  if finite(width) and width>24 then bar:SetScale(math.min(1,math.max(.5,(width-24)/520))) end
 end
 fitToolbar();bar:SetScript('OnShow',fitToolbar);if map.HookScript then map:HookScript('OnSizeChanged',fitToolbar) end
 local accent=bar:CreateTexture(nil,'ARTWORK');accent:SetColorTexture(.20,.72,.78,1);accent:SetPoint('TOPLEFT',0,0);accent:SetPoint('TOPRIGHT',0,0);accent:SetHeight(2)
 local title=U.Text(bar,13);title:SetPoint('TOPLEFT',12,-9);title:SetWidth(300);title:SetHeight(18)
 local hint=U.Text(bar,10,U.palette.muted);hint:SetPoint('TOPLEFT',12,-33);hint:SetWidth(392);hint:SetHeight(14)
 local coordinates=U.Text(bar,10,{.40,.83,.86,1});coordinates:SetPoint('TOPRIGHT',-12,-33);coordinates:SetWidth(94);coordinates:SetHeight(14);coordinates:SetJustifyH('RIGHT')
 local function updateCoordinates()
  coordinates:SetShown(db.mapShowCoordinates~=false);hint:SetWidth(db.mapShowCoordinates==false and 496 or 392)
  if db.mapShowCoordinates==false then return end
  local mapID=map:GetMapID()
  local ok,position=pcall(function() return C_Map and C_Map.GetPlayerMapPosition and C_Map.GetPlayerMapPosition(mapID,'player') end)
  local x,y
  if ok and position and not (issecretvalue and issecretvalue(position)) and type(position.GetXY)=='function' then
   local readable,a,b=pcall(position.GetXY,position);if readable then x,y=a,b end
  end
  coordinates:SetText(finite(x) and finite(y) and x>=0 and x<=1 and y>=0 and y<=1 and string.format('%.1f / %.1f',x*100,y*100) or 'No position')
 end
 local elapsed=0;bar:SetScript('OnUpdate',function(_,dt) elapsed=elapsed+dt;if elapsed>=.25 then elapsed=0;updateCoordinates() end end);updateCoordinates()
 local find=U.Button(bar);find:SetSize(148,26);find:SetPoint('TOPRIGHT',-45,-6);find:SetText('Find services')
 find:SetScript('OnClick',function() ForeverCompanionServiceAtlas.Toggle(true) end)
 local expand=U.Button(bar);expand:SetSize(26,26);expand:SetPoint('TOPRIGHT',-10,-6)
 local drawer=CreateFrame('Frame',nil,bar);drawer:SetSize(520,86);drawer:SetPoint('TOPLEFT',0,-54)
 local function layout()
  local expanded=db.mapDockExpanded==true;drawer:SetShown(expanded);bar:SetHeight(expanded and 140 or 54);expand:SetText(expanded and '-' or '+')
 end
 expand:SetScript('OnClick',function() db.mapDockExpanded=not db.mapDockExpanded;layout() end);layout()
 local function button(x,y,w,value,fn)
  local b=U.Button(drawer);b:SetSize(w,23);b:SetPoint('TOPLEFT',x,y);b:SetText(value);b:SetScript('OnClick',fn);return b
 end
 modeButton=button(12,-4,100,'',function() db.questMapMode=nextMode[mode()];M.Refresh() end)
 zoomButton=button(122,-4,100,'Zoom focus',function() if zoomPoint and type(map.PanAndZoomTo)=='function' then map:PanAndZoomTo(zoomPoint.x,zoomPoint.y) end end)
 styleButton=button(232,-4,112,'',function() cycleMapStyle();M.Refresh() end)
 townButton=button(354,-4,154,'',function() db.questMapHideTowns=townsEnabled();M.Refresh() end)
 pickupButton=button(12,-35,108,'',function() db.questMapHidePickups=not db.questMapHidePickups;M.Refresh() end)
 local services
 services=button(128,-35,126,'Service filters',function()
  if type(db.questMapHiddenServices)~='table' then db.questMapHiddenServices={} end
  local hidden=db.questMapHiddenServices;local entries={}
  for _,entry in ipairs(ForeverCompanionServiceAtlas.Categories) do if entry[1]~='all' then
   local key,label=entry[1],entry[2];entries[#entries+1]={label=label,selected=hidden[key]~=true,action=function() hidden[key]=not hidden[key];M.Refresh() end}
  end end
  entries[#entries+1]={label='Show all service types',action=function() db.questMapHiddenServices={};M.Refresh() end}
  U.Menu(services,'MAP SERVICES',entries)
 end)
 button(262,-35,94,'Overlay map',function() ForeverCompanionMapOverlay.Toggle() end)
 button(364,-35,70,'Stop arrow',function() ForeverCompanionQuestWaypoints.Clear();M.Refresh() end)
 local appearance;appearance=button(442,-35,66,'Style...',function() M.OpenAppearance(appearance) end)
 local legend=U.Text(drawer,10,U.palette.muted);legend:SetPoint('TOPLEFT',12,-65);legend:SetWidth(496);legend:SetText('Right-click service clusters to choose · Drag header to move dock')
 return bar,title,hint
end

local function drawArea(canvas,mapID,quest,width,height)
 if not quest or type(quest.id)~="number" or quest.id<=0 or quest.complete then return end
 if not GetCVarBool or not GetCVarBool("questPOI") then return end
 if not C_Map or not C_Map.GetMapInfo or not MapUtil or not MapUtil.ShouldMapTypeShowQuests then return end
 local info=C_Map.GetMapInfo(mapID)
 if not info or not MapUtil.ShouldMapTypeShowQuests(info.mapType) then return end
 if not areaChecked then
  areaChecked=true
  local ok,frame=pcall(function()
   local kind=worldMap.GetPinTemplateType and worldMap:GetPinTemplateType("QuestBlobPinTemplate") or "QuestPOIFrame"
   local blob=CreateFrame(kind,nil,canvas)
   if not blob.DrawBlob or not blob.DrawNone then blob:Hide();return end
   blob:Hide()
   blob:EnableMouse(false)
   blob:SetPoint("CENTER",canvas,"CENTER")
   blob:SetFillTexture("Interface\\WorldMap\\UI-QuestBlob-Inside")
   blob:SetBorderTexture("Interface\\WorldMap\\UI-QuestBlob-Outside")
   blob:SetFillAlpha(148)
   blob:SetBorderAlpha(255)
   blob:SetBorderScalar(1)
   return blob
  end)
  if ok then area=frame end
 end
 if not area then return end
 area:SetSize(width,height)
 area:SetFrameLevel(canvas:GetFrameLevel()+10)
 area:Show()
 area:SetMapID(mapID)
 area:DrawNone()
 area:DrawBlob(quest.id,true)
end

-- Group only observed points. Rings represent reported destinations, never
-- an objective boundary. Keep each marker anchored on one source coordinate.
local function focusGroups(locations,focus,width,height)
 local groups={}
 local function add(entry)
  local target=entry.target
  for _,group in ipairs(groups) do
   local first=group.entry.target
   local dx,dy=(target.x-first.x)*width,(target.y-first.y)*height
   local gap=math.sqrt(dx*dx+dy*dy)
   if gap<=60 then
    group.samples=group.samples+1
    group.radius=math.max(group.radius,gap+13)
    return
   end
  end
  groups[#groups+1]={entry=entry,focused=true,samples=1,radius=35}
 end
 for _,entry in ipairs(locations) do
  if entry.quest==focus and not entry.target.kind then add(entry) end
 end
 for _,entry in ipairs(locations) do
  if entry.quest==focus and entry.target.kind then add(entry) end
 end
 table.sort(groups,function(a,b)
  local p,q=a.entry.target,b.entry.target
  if (p.kind==nil)~=(q.kind==nil) then return p.kind==nil end
  if a.samples~=b.samples then return a.samples>b.samples end
  if p.x~=q.x then return p.x<q.x end
  return p.y<q.y
 end)
 while #groups>3 do table.remove(groups) end
 return groups
end

-- One destination per background quest, preferring the client POI to a
-- reference spawn. Overlapping quests share a pin, with every title listed.
local function addOtherQuests(groups,locations,focus,width,height)
 local byQuest,ordered={},{}
 for _,entry in ipairs(locations) do
  if entry.quest~=focus then
   local previous=byQuest[entry.quest]
   if not previous then ordered[#ordered+1]=entry.quest end
   if not previous or (previous.target.kind and not entry.target.kind) then byQuest[entry.quest]=entry end
  end
 end
 local background={}
 for _,quest in ipairs(ordered) do
  local entry=byQuest[quest]
  local point=entry.target
  local cluster
  for _,group in ipairs(background) do
   local other=group.entry.target
   if math.abs(point.x-other.x)*width<=16 and math.abs(point.y-other.y)*height<=16 then
    cluster=group
    break
   end
  end
  if cluster then
   cluster.nearby[#cluster.nearby+1]=entry
  else
   local offsetX
   for _,group in ipairs(groups) do
    if group.focused then
     local other=group.entry.target
     if math.abs(point.x-other.x)*width<=18 and math.abs(point.y-other.y)*height<=18 then
      offsetX=point.x<.9 and 22 or -22
      break
     end
    end
   end
   local group={entry=entry,samples=1,nearby={},offsetX=offsetX}
   background[#background+1]=group
   groups[#groups+1]=group
  end
 end
end

function M.Refresh()
 if not worldMap or not worldMap:IsShown() then return end
 if ForeverCompanionQuestDiscovery then ForeverCompanionQuestDiscovery.Refresh() end
 if ForeverCompanionQuestBook then ForeverCompanionQuestBook.Refresh() end
 if ForeverCompanionServiceAtlas then ForeverCompanionServiceAtlas.Refresh() end
 hidePins()
 zoomPoint=nil
 local planner=ForeverCompanionQuestPlanner
 local mapID,canvas=worldMap:GetMapID(),worldMap:GetCanvas()
 if not finite(mapID) or mapID<=0 or not canvas then return end
 local width,height=canvas:GetWidth(),canvas:GetHeight()
 if (issecretvalue and (issecretvalue(width) or issecretvalue(height))) then return end
 if not finite(width) or not finite(height) or width<=0 or height<=0 then return end
 -- Canvas:GetScale() is often the UI scale, not the map zoom level.
 -- Prefer Blizzard's scroll-container zoom when available.
 local scroll=worldMap.ScrollContainer
 local scale=scroll and scroll.GetCanvasScale and scroll:GetCanvasScale()
 if issecretvalue and issecretvalue(scale) then scale=nil end
 if type(scale)~="number" or scale<=0 then
  scale=canvas.GetScale and canvas:GetScale() or 1
 end
 if issecretvalue and issecretvalue(scale) then return end
 if type(scale)~="number" or scale<=0 then scale=1 end
 local focus=planner.IsSupported() and planner.GetSelected()
 local view=mode()
 if not guide then guide,guideTitle,guideHint=createGuide(worldMap) end
 modeButton:SetText("Map: "..modeNames[view])
 local style=mapStyle()
 styleButton:SetText(style=="atlas" and "Style: Atlas" or (style=="clear" and "Style: Clear" or "Style: Original"))
 townButton:SetText(townsEnabled() and "Services: On" or "Services: Off")
 pickupButton:SetText(ForeverCompanionDB and ForeverCompanionDB.questMapHidePickups and "Pickups: Off" or "Pickups: On")
 if style=="atlas" then showTerrain(canvas) end
 local serviceNotice,serviceCount=showServices(canvas,mapID,scale)
 local ok,info=pcall(function() return C_Map and C_Map.GetMapInfo(mapID) end)
 guideTitle:SetText(ok and type(info)=='table' and info.name or 'COMPANION MAP')
 guideHint:SetText(serviceNotice or ((serviceCount or 0)..' service references · '..(view=='off' and 'Quest layer hidden' or 'Choose a quest marker or Find services')))
 zoomButton:SetEnabled(false)
 guide:Show()
 if view=="off" or (view=="focus" and not focus) then return end
 -- All-mode must still display live quest locations when no quest is focused.
 -- A missing focus is not an empty quest log.

 if focus then pcall(drawArea,canvas,mapID,focus,width,height) end
 local quests=planner.IsSupported() and planner.GetLive() or {}
 local locations=ForeverCompanionQuestWaypoints.MapLocations(mapID,view=="focus" and {focus} or quests)
 local groups=focus and focusGroups(locations,focus,width*scale,height*scale) or {}
 if #groups>0 then
  zoomPoint=groups[1].entry.target
  zoomButton:SetEnabled(type(worldMap.PanAndZoomTo)=="function")
  guideHint:SetText(focus.complete and "Turn-in  ·  Click marker for arrow" or "Highlighted destinations  ·  Click marker for arrow")
 elseif view=="all" then
  guideHint:SetText("Click a quest marker to focus it")
 end
 if view=="all" then
  addOtherQuests(groups,locations,focus,width*scale,height*scale)
  local pickupPoints={}
  for _,entry in ipairs(ForeverCompanionQuestWaypoints.MapPickups(mapID,quests)) do
   pickupPoints[#pickupPoints+1]={x=entry.target.x,y=entry.target.y,symbol="!",label=entry.quest.title,entry=entry}
  end
  for _,cluster in ipairs(ForeverCompanionServiceClusters.Build(pickupPoints,width*scale,height*scale,20)) do
   local pickups,nearby={},{}
   for i,point in ipairs(cluster) do pickups[i]=point.entry;if i>1 then nearby[#nearby+1]=point.entry end end
   groups[#groups+1]={entry=pickups[1],pickups=pickups,focused=false,samples=#pickups,nearby=nearby}
  end
 end

 for i,group in ipairs(groups) do
  local pin=pins[i] or createPin(canvas)
  pins[i]=pin
  local entry=group.entry
  local target=entry.target
  pin.entry,pin.focused,pin.samples,pin.nearby=entry,group.focused,group.samples,group.nearby
  pin.pickups,pin.pickupIndex=group.pickups,1
  local shared=group.nearby and #group.nearby>0
  local size=group.focused and 22 or (shared and 17 or 13)
  if group.focused and not focus.complete then
   pin.ring:SetSize(group.radius*2,group.radius*2)
   pin.ring:Show()
  else
   pin.ring:Hide()
  end
  pin:SetSize(size,size)
  pin:SetScale(1/scale)
  pin:SetFrameLevel(canvas:GetFrameLevel()+(group.focused and 102 or 101))
  if group.focused then pin.badge:SetColorTexture(.32,.92,1,1)
  elseif entry.quest.complete then pin.badge:SetColorTexture(.48,.91,.52,.93)
  else pin.badge:SetColorTexture(.93,.76,.40,.86) end
  if entry.pickup then
   pin.outline:Hide()
   pin.badge:SetTexture("Interface\\GossipFrame\\AvailableQuestIcon")
   pin.symbol:SetText(shared and tostring(#group.pickups) or "")
   pin.symbol:SetTextColor(1,1,1)
   pin:SetSize(22,26)
  else
   pin.outline:Show()
   pin.symbol:SetTextColor(.05,.08,.12)
   pin.symbol:SetText(shared and "+" or (entry.quest.complete and "?" or (group.focused and ">" or "")))
  end
  pin:ClearAllPoints()
  pin:SetPoint("CENTER",canvas,"TOPLEFT",target.x*width*scale+(group.offsetX or 0),-target.y*height*scale)
  pin:Show()
 end
end

local refreshMap=M.Refresh
function M.Refresh()
 if not worldMap or not worldMap:IsShown() then return end
 local profiler=ForeverCompanionRefreshQueue
 local started=profiler and profiler.Start('map')
 refreshMap()
 if profiler then profiler.Finish('map',started) end
end
local function attach()
 local map=WorldMapFrame
 if provider or not map or not map.AddDataProvider or not map.GetCanvas
  or not MapCanvasDataProviderMixin or not CreateFromMixins then return end
 worldMap=map
 provider=CreateFromMixins(MapCanvasDataProviderMixin)
 provider.RefreshAllData=M.Refresh
 provider.OnMapChanged=M.Refresh
 provider.OnCanvasSizeChanged=M.Refresh
 provider.OnCanvasScaleChanged=function()
  -- Zoom-dependent service markers must refresh even when timer APIs are absent.
  if provider.zoomTimer and provider.zoomTimer.Cancel then provider.zoomTimer:Cancel() end
  provider.zoomTimer=nil
  if C_Timer and C_Timer.NewTimer then
   provider.zoomTimer=C_Timer.NewTimer(.15,function()
    provider.zoomTimer=nil
    M.Refresh()
   end)
  else M.Refresh() end
 end
 provider.OnHide=hidePins
 provider.RemoveAllData=hidePins
 map:AddDataProvider(provider)
 M.Refresh()
end

local events=CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
pcall(events.RegisterEvent,events,"QUEST_POI_UPDATE")
pcall(events.RegisterEvent,events,"PLAYER_LEVEL_UP")
pcall(events.RegisterEvent,events,"QUEST_TURNED_IN")
events:SetScript("OnEvent",function(_,event,name)
 if event=="ADDON_LOADED" and name~="Blizzard_WorldMap" then return end
 if event=="QUEST_POI_UPDATE" or event=="PLAYER_LEVEL_UP" or event=="QUEST_TURNED_IN" then M.Refresh() else attach() end
end)
