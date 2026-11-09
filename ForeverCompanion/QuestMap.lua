-- Blizzard-native map artwork with a Companion overlay. Never replaces map tiles,
-- changes watched quests, or modifies Blizzard waypoints.
local M={}
ForeverCompanionQuestMap=M

local provider,worldMap,area,areaChecked,guide,guideTitle,guideHint,modeButton,zoomButton,styleButton,terrain,townButton,pickupButton
local pins,servicePins,zoomPoint={},{},nil
local modeNames={focus="Focus",all="All",off="Off"}
local nextMode={all="focus",focus="off",off="all"}

local function mode()
 local saved=ForeverCompanionDB and ForeverCompanionDB.questMapMode
 return modeNames[saved] and saved or "all"
end

local function mapStyle()
 local db=ForeverCompanionDB
 if db and db.questMapStyle=="clear" then return "clear" end
 if db and db.questMapOriginalTerrain==true then return "original" end
 return "atlas"
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
  tint:SetColorTexture(.08,.15,.22,.065)
  sharpenOverlay(tint)
  for i=1,9 do
   local vertical=terrain:CreateTexture(nil,"ARTWORK")
   vertical:SetWidth(1)
   vertical:SetColorTexture(.25,.56,.69,i==5 and .16 or .07)
   sharpenOverlay(vertical)
   local horizontal=terrain:CreateTexture(nil,"ARTWORK")
   horizontal:SetHeight(1)
   horizontal:SetColorTexture(.25,.56,.69,i==5 and .16 or .07)
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
   guideHint:SetText(ForeverCompanionQuestWaypoints.Navigate(entry.target,false,entry.quest.title))
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

-- Built-in Blizzard icon textures; no letter tiles or external assets.
-- All paths use shipped game artwork. Unknown services use a bag icon.
local serviceArtwork={
 B="Interface\\Minimap\\Tracking\\Banker",
 AH="Interface\\Minimap\\Tracking\\Auctioneer",
 F="Interface\\Minimap\\Tracking\\FlightMaster",
 I="Interface\\Minimap\\Tracking\\Innkeeper",
 R="Interface\\Minimap\\Tracking\\Repair",
 V="Interface\\Minimap\\Tracking\\Reagents",
 T="Interface\\Minimap\\Tracking\\Class",
 M="Interface\\Minimap\\Tracking\\Mailbox",
}
local function showServices(canvas,mapID,scale)
 if not townsEnabled() then return end
 local points,notice=ForeverCompanionTownServices.ForMap(mapID)
 local width,height=canvas:GetWidth()*scale,canvas:GetHeight()*scale
 -- Pixel-distance clustering crosses service categories, so a banker,
 -- repair vendor and trainer at the same building remain accessible.
 local detailed=scale>=1.25
 local ordered=ForeverCompanionServiceClusters.Build(points,width,height,detailed and 22 or 26)
 for _,oldPin in ipairs(servicePins) do oldPin:Hide();oldPin.locations=nil end
 for i,group in ipairs(ordered) do
  local pin=servicePins[i]
  if not pin then
   pin=CreateFrame("Button",nil,canvas)
   pin:RegisterForClicks("LeftButtonUp")
   pin:SetSize(25,25)
   local bg=pin:CreateTexture(nil,"BACKGROUND")
   bg:SetAllPoints(pin)
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
   sharpenOverlay(icon)
   local border=pin:CreateTexture(nil,"OVERLAY")
   border:SetPoint("TOPLEFT",pin,"TOPLEFT",-1,1)
   border:SetPoint("BOTTOMRIGHT",pin,"BOTTOMRIGHT",1,-1)
   border:SetTexture("Interface\\Buttons\\UI-Quickslot2")
   pin.border=border
   sharpenOverlay(border)
   pin:SetScript("OnEnter",function(self)
    if self.border then self.border:SetVertexColor(1,1,1,1) end
    if not GameTooltip then return end
    GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
    local active=self.locations[self.locationIndex or 1]
    GameTooltip:SetText(active.service.."  -  "..active.label)
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
    GameTooltip:AddLine("QuestieDB reference  ·  Click for arrow",.65,.78,.85)
    GameTooltip:Show()
   end)
   pin:SetScript("OnLeave",function(self)
    if self.border and self.markerColor then
     self.border:SetVertexColor(self.markerColor[1],self.markerColor[2],self.markerColor[3],1)
    end
    if GameTooltip then GameTooltip:Hide() end
   end)
   pin:SetScript("OnClick",function(self)
    if IsShiftKeyDown and IsShiftKeyDown() and #self.locations>1 then
     self.locationIndex=(self.locationIndex or 1)%#self.locations+1
     local active=self.locations[self.locationIndex]
     self.icon:SetTexture(serviceArtwork[active.symbol] or serviceArtwork.V)
     self:GetScript("OnEnter")(self)
     return
    end
    local target=self.locations[self.locationIndex or 1]
    guideHint:SetText(ForeverCompanionQuestWaypoints.Navigate(target,false,target.label))
   end)
   servicePins[i]=pin
  end
  local point=group[1]
  pin.locations=group
  pin.locationIndex=1
  pin.count:SetText(#group>1 and tostring(#group) or "")
  -- Smaller, less intrusive POI icons at both zoom levels.
  pin:SetSize(detailed and 24 or 22,detailed and 24 or 22)
  pin.icon:SetTexture(serviceArtwork[point.symbol] or serviceArtwork.V)
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
 return notice
end

local function createGuide(map)
 local bar=CreateFrame("Frame","ForeverCompanionMapToolbar",map)
 bar:SetSize(451,94)
 -- Recalculate as the world-map window is resized; no external map addon.
 local function fitToolbar()
  if not map.GetWidth then return end
  local width=map:GetWidth()
  if issecretvalue and issecretvalue(width) then return end
  if type(width)~="number" or width<=0 then return end
  local scale=math.min(1,math.max(.65,(width-24)/451))
  if bar:GetScale()~=scale then bar:SetScale(scale) end
 end
 fitToolbar()
 bar:SetScript("OnShow",fitToolbar)
 if map.HookScript then map:HookScript("OnSizeChanged",fitToolbar) end
 bar:SetPoint("TOP",map,"TOP",0,-38)
 bar:SetFrameLevel(map:GetFrameLevel()+200)
 ForeverCompanionInterface.Surface(bar)
 local accent=bar:CreateTexture(nil,"ARTWORK")
 accent:SetColorTexture(.82,.68,.43,.95)
 accent:SetPoint("TOPLEFT",bar,"TOPLEFT",2,-2)
 accent:SetPoint("TOPRIGHT",bar,"TOPRIGHT",-2,-2)
 accent:SetHeight(2)
 local bottom=bar:CreateTexture(nil,"BORDER")
 bottom:SetColorTexture(.23,.28,.35,1)
 bottom:SetPoint("BOTTOMLEFT",bar,"BOTTOMLEFT",2,2)
 bottom:SetPoint("BOTTOMRIGHT",bar,"BOTTOMRIGHT",-2,2)
 bottom:SetHeight(1)
 local title=bar:CreateFontString(nil,"OVERLAY","GameFontHighlight")
 title:SetPoint("TOP",0,-7)
 title:SetWidth(423)
 local hint=bar:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
 hint:SetPoint("TOP",0,-26)
 hint:SetWidth(423)
 hint:SetTextColor(.66,.72,.80)
 title:SetTextColor(.93,.95,.98)
 ForeverCompanionVisualTheme.Font(title,13)
 ForeverCompanionVisualTheme.Font(hint,11)
 modeButton=ForeverCompanionInterface.Button(bar)
 modeButton:SetSize(100,22)
 modeButton:SetPoint("BOTTOM",bar,"BOTTOM",-165,32)
 modeButton:SetScript("OnClick",function()
  ForeverCompanionDB=ForeverCompanionDB or {}
  ForeverCompanionDB.questMapMode=nextMode[mode()]
  M.Refresh()
 end)
 zoomButton=ForeverCompanionInterface.Button(bar)
 zoomButton:SetSize(100,22)
 zoomButton:SetPoint("BOTTOM",bar,"BOTTOM",-55,32)
 zoomButton:SetText("Zoom focus")
 zoomButton:SetScript("OnClick",function()
  if zoomPoint and type(map.PanAndZoomTo)=="function" then
   map:PanAndZoomTo(zoomPoint.x,zoomPoint.y)
  end
 end)
 styleButton=ForeverCompanionInterface.Button(bar)
 styleButton:SetSize(112,22)
 styleButton:SetPoint("BOTTOM",bar,"BOTTOM",55,32)
 styleButton:SetScript("OnClick",function()
  cycleMapStyle()
  M.Refresh()
 end)
 townButton=ForeverCompanionInterface.Button(bar)
 townButton:SetSize(100,22)
 townButton:SetPoint("BOTTOM",bar,"BOTTOM",165,32)
 townButton:SetScript("OnClick",function()
  ForeverCompanionDB=ForeverCompanionDB or {}
  ForeverCompanionDB.questMapHideTowns=townsEnabled()
  M.Refresh()
 end)
 pickupButton=ForeverCompanionInterface.Button(bar)
 pickupButton:SetSize(108,22);pickupButton:SetPoint("BOTTOMLEFT",bar,"BOTTOMLEFT",12,5)
 pickupButton:SetScript("OnClick",function()
  ForeverCompanionDB=ForeverCompanionDB or {}
  ForeverCompanionDB.questMapHidePickups=not ForeverCompanionDB.questMapHidePickups
  M.Refresh()
 end)
 pickupButton:SetScript("OnEnter",function(self)
  if GameTooltip then
   GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
   GameTooltip:SetText("Unaccepted quests")
   GameTooltip:AddLine("Shown in Map: All. Click ! to navigate; Shift-click cycles shared quest givers.",.8,.9,1,true)
   GameTooltip:AddLine(ForeverCompanionQuestWaypoints.PickupStatus or "Blizzard pickups plus Forever QuestieDB reference locations",.95,.78,.4,true)
   GameTooltip:Show()
  end
 end)
 pickupButton:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
 local legend=ForeverCompanionInterface.Text(bar,10)
 legend:SetPoint("BOTTOMLEFT",bar,"BOTTOMLEFT",132,8);legend:SetWidth(305)
 legend:SetText("! Quest pickups   /   ? Turn-ins   /   Shift-click: cycle")
 title:SetWordWrap(false);title:SetHeight(17)
 hint:SetWordWrap(false);hint:SetHeight(14)
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
 hidePins()
 zoomPoint=nil
 local planner=ForeverCompanionQuestPlanner
 local mapID,canvas=worldMap:GetMapID(),worldMap:GetCanvas()
 if not mapID or not canvas then return end
 local width,height=canvas:GetWidth(),canvas:GetHeight()
 if (issecretvalue and (issecretvalue(width) or issecretvalue(height))) then return end
 if not width or not height or width<=0 or height<=0 then return end
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
 townButton:SetText(townsEnabled() and "Towns: On" or "Towns: Off")
 pickupButton:SetText(ForeverCompanionDB and ForeverCompanionDB.questMapHidePickups and "Pickups: Off" or "Pickups: On")
 if style=="atlas" then showTerrain(canvas) end
 local serviceNotice=showServices(canvas,mapID,scale)
 guideTitle:SetText(focus and focus.title or "Companion map")
 guideHint:SetText(serviceNotice or (view=="off" and "Companion quest markers hidden" or "No quest destination on this map"))
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
