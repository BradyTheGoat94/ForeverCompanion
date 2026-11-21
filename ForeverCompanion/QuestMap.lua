-- Blizzard-native map artwork with a Companion overlay. Never replaces map tiles,
-- changes watched quests, or modifies Blizzard waypoints.
local M={}
ForeverCompanionQuestMap=M

local provider,worldMap,area,areaChecked,guide,guideTitle,guideHint,modeButton,zoomButton,styleButton,terrain,townButton,pickupButton
local pins,servicePins,zoomPoint={},{},nil
local bearingLayer,bearingBeacon,zoneLabelLayer
local stitchedArtLevel
local openMapCallbacks
local bearingDots={}
local briefingButton
local modeNames={focus="Focus",all="All",off="Off"}
local nextMode={all="focus",focus="off",off="all"}
local function finite(n) return not (issecretvalue and issecretvalue(n)) and type(n)=='number' and n==n and math.abs(n)<math.huge end

local function readPublic(fn,...)
 if type(fn)~='function' then return end
 local ok,a,b=pcall(fn,...)
 if ok and not (issecretvalue and (issecretvalue(a) or issecretvalue(b))) then return a,b end
end
local function stitchedMap()
 local api=OpenMapAPI
 if type(api)=='table' and api.major==1 and finite(api.version) and api.version>=2 and readPublic(api.IsStitched)==true then
  return api
 end
end
local function canvasLevel(canvas)
 local native=canvas:GetFrameLevel()
 return finite(stitchedArtLevel) and math.max(native,stitchedArtLevel) or native
end

-- Resolve original normalized positions through OpenMap when it owns the canvas.
-- Keep the original coordinates on the entry for waypoints and tooltips.
function M.CanvasPoint(mapID,x,y,fallbackX,fallbackY)
 fallbackX,fallbackY=fallbackX or x,fallbackY or y
 local api=stitchedMap()
 if not api or not C_Map then return fallbackX,fallbackY end
 local point=readPublic(CreateVector2D,x,y)
 if not point then return fallbackX,fallbackY end
 local continent,world=readPublic(C_Map.GetWorldPosFromMapPos,mapID,point)
 if not finite(continent) or not world then return fallbackX,fallbackY end
 local wx,wy=readPublic(world.GetXY,world)
 if not finite(wx) or not finite(wy) then return fallbackX,fallbackY end
 local cx,cy=readPublic(api.CanvasFromWorldPos,continent,wx,wy)
 if finite(cx) and finite(cy) then return cx,cy end
 return fallbackX,fallbackY
end

local function mode()
 local saved=ForeverCompanionDB and ForeverCompanionDB.questMapMode
 return modeNames[saved] and saved or "all"
end

local function mapStyle()
 local db=ForeverCompanionDB
 if db and db.questMapStyle=="clear" then return "clear" end
 if db and (db.questMapStyle=='atlas' or db.questMapStyle=='diorama') then return db.questMapStyle end
 if db and db.questMapOriginalTerrain==true then return "original" end
 return "clear"
end

local function cycleMapStyle()
 ForeverCompanionDB=ForeverCompanionDB or {}
 local current=mapStyle()
 local nextStyle=({original='clear',clear='atlas',atlas='diorama',diorama='original'})[current]
 ForeverCompanionDB.questMapStyle=nextStyle
 ForeverCompanionDB.questMapOriginalTerrain=(nextStyle=="original")
 return nextStyle
end

-- Standalone presentation: native Blizzard map tiles remain the only terrain
-- source. Clear mode displays them without tint/grid; no external map addon.
M.MapStyle=mapStyle
M.SetMapStyle=function(value)
 if value~="diorama" and value~="atlas" and value~="clear" and value~="original" then return false end
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

local markerArt='Interface\\AddOns\\ForeverCompanion\\Media\\AtlasDiorama'
local function dioramaMarker(texture,sprite)
 texture:SetTexture(markerArt)
 texture:SetTexCoord((64*sprite+.5)/512,(64*sprite+63.5)/512,.5/64,63.5/64)
end

local function showTerrain(canvas,diorama)
 if not terrain then
  terrain=CreateFrame("Frame",nil,canvas)
  terrain:SetAllPoints(canvas)
  terrain:EnableMouse(false)
  local tint=terrain:CreateTexture(nil,"BACKGROUND")
  tint:SetAllPoints(terrain)
  tint:SetColorTexture(.37,.24,.10,.038)
  local shade=terrain:CreateTexture(nil,'BACKGROUND',nil,1)
  shade:SetAllPoints(terrain)
  shade:SetTexture('Interface\\AddOns\\ForeverCompanion\\Media\\WorldMapShade')
  terrain.tint,terrain.shade=tint,shade
  sharpenOverlay(tint)
  for i=1,9 do
   local vertical=terrain:CreateTexture(nil,"ARTWORK")
   vertical:SetWidth(1)
   vertical:SetColorTexture(.88,.76,.52,i==5 and .095 or .04)
   sharpenOverlay(vertical)
   local horizontal=terrain:CreateTexture(nil,"ARTWORK")
   horizontal:SetHeight(1)
   horizontal:SetColorTexture(.88,.76,.52,i==5 and .095 or .04)
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
 terrain:SetFrameLevel(canvas:GetFrameLevel()+(diorama and 21 or 1))
 terrain.tint:SetColorTexture(.37,.24,.10,diorama and .065 or .038)
 terrain.shade:SetAlpha(diorama and .65 or 1)
 terrain:Show()
end

local dungeonPins,zoneLevelLabels={},{}
local dungeonSelection
local function showDungeons(map,canvas,mapID,width,height)
 if ForeverCompanionDB and ForeverCompanionDB.hideDungeonPins then return end
 local catalog=ForeverCompanionDungeonCatalog
 if not catalog then return end
 for i,location in ipairs(catalog.MapLocations(mapID)) do
  local pin=dungeonPins[i]
  if not pin then
   pin=CreateFrame('Button',nil,canvas);pin:SetSize(20,20)
   local icon=pin:CreateTexture(nil,'ARTWORK');icon:SetPoint('CENTER',pin);pin.icon=icon
   icon:SetTexture('Interface\\Icons\\INV_Misc_Key_03')
   icon:SetTexCoord(.08,.92,.08,.92)
   local border=pin:CreateTexture(nil,'BACKGROUND')
   border:SetAllPoints(pin)
   border:SetColorTexture(.10,.06,.17,.95)
   sharpenOverlay(border)
   pin:SetHighlightTexture('Interface\\Buttons\\ButtonHilight-Square','ADD')
   pin.level=ForeverCompanionInterface.Text(pin,10,{.98,.80,.47,1})
   pin.level:SetPoint('TOP',pin,'BOTTOM',0,0)
   pin.level:SetJustifyH('CENTER')
   pin:SetScript('OnEnter',function(self)
    if not GameTooltip then return end
    local p=self.location
    GameTooltip:SetOwner(self,'ANCHOR_RIGHT');GameTooltip:SetText(p.approximate and 'Dungeon area' or 'Dungeon approach')
    for _,name in ipairs(p.names) do
     local range=catalog.LevelRange(name)
     GameTooltip:AddLine(range and (name..'  |  Suggested levels '..range) or name,1,1,1,true)
    end
    GameTooltip:AddLine(string.format('%s %.1f, %.1f',p.zone,p.x*100,p.y*100),.8,.85,.9)
    GameTooltip:AddLine('Click for entrance details, quests and loot',.8,.85,.9,true)
    GameTooltip:Show()
   end)
   pin:SetScript('OnLeave',function() if GameTooltip then GameTooltip:Hide() end end)
   pin:SetScript('OnClick',function(self)
    local location=self.location
    if GameTooltip then GameTooltip:Hide() end
    dungeonSelection={location=location,index=1}
    if location.map~=map:GetMapID() and map.SetMapID then map:SetMapID(location.map) end
    M.Refresh()
   end)
   dungeonPins[i]=pin
  end
  pin.location=location
  local zoneView=mapID==location.map
  local range=zoneView and #location.names==1 and catalog.LevelRange(location.names[1])
  pin.level:SetText(range or '')
  pin.level:SetShown(not not range and (not ForeverCompanionDB or ForeverCompanionDB.mapShowDungeonLevels~=false))
  local hitSize=zoneView and 20 or 14
  local diorama=mapStyle()=='diorama'
  pin:SetSize(hitSize,hitSize)
  local iconSize=diorama and (zoneView and 32 or 22) or (zoneView and 12 or 8)
  pin.icon:SetSize(iconSize,iconSize)
  pin.icon:ClearAllPoints()
  pin.icon:SetPoint("CENTER",pin,"CENTER",0,diorama and iconSize*.21 or 0)
  if diorama then dioramaMarker(pin.icon,6)
  else pin.icon:SetTexture('Interface\\Icons\\INV_Misc_Key_03');pin.icon:SetTexCoord(.08,.92,.08,.92) end
  local cx,cy=M.CanvasPoint(location.map,location.x,location.y,location.displayX,location.displayY)
  pin:SetFrameLevel(canvasLevel(canvas)+85)
  pin:ClearAllPoints();pin:SetPoint('CENTER',canvas,'TOPLEFT',cx*width,-cy*height)
  pin:Show()
 end
end
local function hidePins()
 if ForeverCompanionZoneBriefing then ForeverCompanionZoneBriefing.Hide() end
 if ForeverCompanionDungeonBriefing then ForeverCompanionDungeonBriefing.Hide() end
 if ForeverCompanionWorldMapDetail then ForeverCompanionWorldMapDetail.Hide() end
 if bearingLayer then bearingLayer:Hide() end
 for _,label in ipairs(zoneLevelLabels) do label:Hide() end
 for _,pin in ipairs(dungeonPins) do pin:Hide() end
 if ForeverCompanionMapTools then ForeverCompanionMapTools.HideMap() end
 for _,pin in ipairs(pins) do pin:Hide() end
 for _,pin in ipairs(servicePins) do pin:Hide() end
 if area then area:Hide() end
 if guide then guide:Hide() end
 if terrain then terrain:Hide() end
end

local function mapPickups(map,quests,briefing)
 local entries=ForeverCompanionQuestWaypoints.MapPickups(map,quests,briefing)
 local cfg=ForeverCompanionDB or {}
 local guide=ForeverCompanionWalkthrough
 if (not briefing and (cfg.questMapHidePickups or cfg.mapHideZoneStarts)) or not guide then return entries end
 local curated=guide.MapStarts(map,quests)
 local starts={}
 for _,entry in ipairs(curated) do starts[entry.quest.id]=entry end
 local result,seen={},{}
 for _,entry in ipairs(entries) do
  local id=entry.quest.id
  if starts[id] then
   local marked={quest=entry.quest,target=entry.target,pickup=true,reference=entry.reference,zoneStart=true}
   result[#result+1]=marked
   seen[id]=true
  elseif briefing or not cfg.mapOnlyZoneStarts then result[#result+1]=entry end
 end
 for _,entry in ipairs(curated) do if not seen[entry.quest.id] then result[#result+1]=entry end end
 return result
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
 pin.badge=pin:CreateTexture(nil,"ARTWORK")
 pin.badge:SetAllPoints(pin)
 pin.badge:SetTexture("Interface\\AddOns\\ForeverCompanion\\Media\\WorldMapMarkers")
 sharpenOverlay(pin.badge)
 pin.symbol=pin:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
 pin.symbol:SetPoint("BOTTOMRIGHT",pin,"BOTTOMRIGHT",3,-2)
 pin.symbol:SetShadowColor(0,0,0,1)
 pin.symbol:SetShadowOffset(1,-1)
 pin:SetScript("OnEnter",function(self)
  if not GameTooltip then return end
  local entry=self.entry
  GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
  GameTooltip:SetText(entry.quest.title)
  GameTooltip:AddLine(entry.pickup and (entry.reference and "Quest giver - confirm availability in game" or "Quest pickup reported by Blizzard") or (entry.quest.complete and "Turn-in destination" or (entry.target.objective or "Quest objective")),1,1,1,true)
  GameTooltip:AddLine(entry.target.label or entry.target.source,.68,.75,.82,true)
  GameTooltip:AddLine(ForeverCompanionQuestWaypoints.Describe(entry.target),.75,.85,1,true)
  if not entry.pickup and ForeverCompanionQuestFieldGuide then
   local done,total,known=ForeverCompanionQuestFieldGuide.Progress(entry.quest)
   if total>0 then GameTooltip:AddLine(done..' / '..total..' objectives complete'..(known<total and ' · some progress unknown' or ''),.7,.85,.75,true) end
   GameTooltip:AddLine('Right-click: quest actions and field guide',.82,.74,.55,true)
  end
  if entry.zoneStart then GameTooltip:AddLine('Suggested zone starter',1,.8,.35,true) end
  if entry.reference and not entry.zoneStart then GameTooltip:AddLine("Level, race, class and quest-chain checks passed. Profession, reputation and event requirements may still apply.",.95,.76,.35,true) end
  if self.pickups and #self.pickups>1 then GameTooltip:AddLine("Right-click for every quest here, or Shift-click to cycle",.95,.76,.35,true) end
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
  if button=='RightButton' and entry.pickup and self.pickups and #self.pickups>1 then
   local entries={}
   for _,pickup in ipairs(self.pickups) do
    local candidate=pickup
    entries[#entries+1]={label=candidate.quest.title,action=function()
     local map=worldMap:GetMapID()
     local quests=ForeverCompanionQuestPlanner.GetLive()
     local target=ForeverCompanionQuestDiscovery.Resolve(mapPickups(map,quests),candidate.quest.id,candidate.target)
     if target then guideHint:SetText(ForeverCompanionQuestWaypoints.Navigate(target,false,candidate.quest.title))
     else M.Refresh();guideHint:SetText('This quest pickup changed. Choose a current marker.') end
    end}
   end
   ForeverCompanionInterface.PagedMenu(self,'Quest pickups',entries,nil,320)
   return
  end
  if button=='RightButton' and not entry.pickup and ForeverCompanionInterface then
   ForeverCompanionInterface.Menu(self,'QUEST ACTIONS',{
    {label='Open quest field guide',action=function() if ForeverCompanionOpenQuestGuide then ForeverCompanionOpenQuestGuide(entry.quest.id) end end},
    {label=ForeverCompanionQuestPlanner.IsPinned(entry.quest) and 'Unpin quest' or 'Pin quest',action=function()
     if not ForeverCompanionQuestPlanner.IsSupported() then return end
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
   local target=ForeverCompanionQuestDiscovery.Resolve(mapPickups(map,ForeverCompanionQuestPlanner.GetLive()),entry.quest.id,entry.target)
   if not target then M.Refresh();guideHint:SetText('This quest pickup changed. Choose a current marker.');return end
   guideHint:SetText(ForeverCompanionQuestWaypoints.Navigate(target,false,entry.quest.title))
  else
   local planner=ForeverCompanionQuestPlanner
   if not planner.IsSupported() then M.Refresh();guideHint:SetText('Quest data unavailable. Open your quest log before navigating.');return end
   local q,index,target=ForeverCompanionQuestWaypoints.ResolveActiveEntry(entry,planner.GetLive())
   if not target then M.Refresh();guideHint:SetText('This quest or location changed. Choose a current marker.');return end
   if self.focused or (IsShiftKeyDown and IsShiftKeyDown()) then
    if not self.focused then planner.Select(index) end
    guideHint:SetText(ForeverCompanionQuestWaypoints.Navigate(target,false,q.title,q.id))
   else planner.Select(index) end
  end
 end)
 return pin
end

local function townsEnabled()
 return not ForeverCompanionDB or ForeverCompanionDB.questMapHideTowns~=true
end

local serviceIconSizes={[20]=10,[24]=12,[28]=16}
local function serviceIconSize(config)
 return serviceIconSizes[config.mapServiceIconSize] or 12
end
local function serviceArtwork(pin,point)
 local symbol=point.symbol
 local sprite=symbol=='R' and 5 or (symbol=='V' and not point.vendorProfile and 4)
 local diorama=mapStyle()=='diorama' and sprite
 local size=diorama and 32 or pin.nativeIconSize or 12
 pin.icon:SetSize(size,size)
 pin.icon:ClearAllPoints()
 pin.icon:SetPoint('CENTER',pin,'CENTER',0,diorama and size*.21 or 0)
 if diorama then dioramaMarker(pin.icon,sprite)
 else
  pin.icon:SetTexCoord(0,1,0,1)
  ForeverCompanionServiceAtlas.SetIcon(pin.icon,symbol,point.vendorProfile)
 end
end
local function showServices(canvas,mapID,scale,tier)
 if not townsEnabled() then return end
 local points,notice=ForeverCompanionTownServices.ForMap(mapID)
 local cfg=ForeverCompanionDB or {}
 if cfg.mapVendorsOnly then
  local vendors={}
  for _,point in ipairs(points) do if point.symbol=="V" or point.symbol=="R" then vendors[#vendors+1]=point end end
  points=vendors
 else
  points=ForeverCompanionServiceClusters.Filter(points,cfg.questMapHiddenServices)
 end
 local iconSize=serviceIconSize(cfg)
 local diorama=mapStyle()=="diorama"
 local hitSize=math.max(diorama and 25 or 20,iconSize+4)
 local width,height=canvas:GetWidth()*scale,canvas:GetHeight()*scale
 -- Pixel-distance clustering crosses service categories, so a banker,
 -- repair vendor and trainer at the same building remain accessible.
 local radius=cfg.mapServiceTight and hitSize or hitSize+6
 if tier=='zone' then radius=radius+12 end
 local ordered=ForeverCompanionServiceClusters.Build(points,width,height,radius)
 for _,oldPin in ipairs(servicePins) do oldPin:Hide();oldPin.locations=nil end
 for i,group in ipairs(ordered) do
  local pin=servicePins[i]
  if not pin then
   pin=CreateFrame("Button",nil,canvas)
   pin:RegisterForClicks("LeftButtonUp","RightButtonUp")
   local bg=pin:CreateTexture(nil,"BACKGROUND")
   bg:SetPoint('CENTER',pin)
   bg:SetColorTexture(.015,.025,.04,.94)
   pin.background=bg
   sharpenOverlay(bg)
   local icon=pin:CreateTexture(nil,"ARTWORK")
   icon:SetPoint("CENTER",pin)
   icon:SetTexCoord(0,1,0,1)
   pin.icon=icon
   pin.count=pin:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
   pin.count:SetPoint("BOTTOMRIGHT",bg,"BOTTOMRIGHT",5,-3)
   pin.count:SetShadowOffset(1,-1)
   local label=ForeverCompanionInterface.Text(pin,10)
   label:SetPoint('TOP',pin,'BOTTOM',0,-3);label:SetWidth(132);label:SetJustifyH('CENTER');label:SetHeight(15);label:Hide();pin.nameLabel=label
   local pip=pin:CreateTexture(nil,'OVERLAY');pip:SetSize(4,4);pip:SetPoint('TOPLEFT',bg,'TOPLEFT',-1,1);pip:SetColorTexture(.25,.90,.92,1);pin.visitPip=pip
   sharpenOverlay(icon)
   local border=pin:CreateTexture(nil,"BACKGROUND",nil,-1)
   border:SetPoint("CENTER",pin)
   border:SetColorTexture(1,1,1,1)
   pin.border=border
   sharpenOverlay(border)
   pin:SetScript("OnEnter",function(self)
    if not self.locations then return end
    if self.border then self.border:SetVertexColor(1,1,1,1) end
    if self.nameLabel and self.locations then self.nameLabel:SetText(self.locations[self.locationIndex or 1].label);self.nameLabel:Show() end
    if not GameTooltip then return end
    GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
    local active=self.locations[self.locationIndex or 1]
    local services=ForeverCompanionTownServices
    GameTooltip:SetText(active.label)
    GameTooltip:AddLine(services.ServiceLabel(active)..("  |  %.1f, %.1f"):format(active.x*100,active.y*100),.95,.82,.52,true)
    local detail=services.ServiceDetails(active)
    if detail~='' then GameTooltip:AddLine(detail,.85,.9,1,true) end
    local seen,count,displayed={[active.service..":"..active.label]=true},0,0
    for _,entry in ipairs(self.locations) do
     local key=entry.service..":"..entry.label
     if not seen[key] then
      seen[key]=true
      count=count+1
      if displayed<6 then
       GameTooltip:AddLine(services.ServiceLabel(entry)..": "..entry.label,.8,.9,1,true)
       displayed=displayed+1
      end
     end
    end
    if count>displayed then
     GameTooltip:AddLine("+"..(count-displayed).." more nearby locations",.65,.78,.85)
    end
    GameTooltip:AddLine(active.source or 'Forever QuestieDB reference',.65,.78,.85,true)
    if active.observed then GameTooltip:AddLine('Your position during a merchant visit, not an exact NPC location. Vendors may move.',.95,.76,.35,true) end
    GameTooltip:AddLine(#self.locations>1 and 'Shift-click to switch pins. Right-click to choose a nearby service.' or 'Click for directions.',.65,.78,.85,true)
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
      choices[#choices+1]={label=ForeverCompanionTownServices.ServiceLabel(point)..': '..point.label,action=function() guideHint:SetText(ForeverCompanionServiceAtlas.Navigate(target)) end}
     end
     choices[#choices+1]={label='Open searchable service atlas',action=function() ForeverCompanionServiceAtlas.Toggle(true) end}
     if GameTooltip then GameTooltip:Hide() end
     ForeverCompanionInterface.PagedMenu(self,'Nearby services',choices,nil,300);return
    end
    if IsShiftKeyDown and IsShiftKeyDown() and #self.locations>1 then
     self.locationIndex=(self.locationIndex or 1)%#self.locations+1
     local active=self.locations[self.locationIndex]
     serviceArtwork(self,active)
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
  local anchor=group[1]
  local point,index=anchor,1
  -- A repair-capable shop should still show its specialty icon.
  if anchor.symbol=='R' then
   for n,entry in ipairs(group) do
    if ForeverCompanionTownServices.MatchesRepairVendor(anchor,entry) then point,index=entry,n;break end
   end
  end
  pin.locations=group
  pin.locationIndex=index
  pin.count:SetText(#group>1 and tostring(#group) or "")
  -- Smaller, less intrusive POI icons at both zoom levels.
  pin:SetSize(hitSize,hitSize)
  pin.nativeIconSize=iconSize
  pin.background:SetSize(iconSize+2,iconSize+2)
  pin.border:SetSize(iconSize+4,iconSize+4)
  pin.visitPip:SetShown(point.observed==true)
  pin.labelAllowed=i<=12
  pin.nameLabel:SetText(point.label)
  pin.nameLabel:SetShown(cfg.mapServiceLabels==true and pin.labelAllowed)
  serviceArtwork(pin,point)
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
   pin.markerColor=(point.symbol=='V' or point.symbol=='R') and {.48,.85,.70} or {.7,.82,.94}
   pin.border:SetVertexColor(.7,.82,.94,1)
  end
  local priority=(point.symbol=="B" or point.symbol=="AH") and 94 or 90
  pin:SetFrameLevel(canvasLevel(canvas)+priority)
  pin:SetScale(1/scale)
  pin:ClearAllPoints()
  local cx,cy=M.CanvasPoint(mapID,anchor.x,anchor.y)
  pin:SetPoint("CENTER",canvas,"TOPLEFT",cx*width,-cy*height)
  pin:Show()
 end
 return notice,#points
end

local function validCoordinates(x,y)
 return finite(x) and finite(y) and x>=0 and x<=1 and y>=0 and y<=1
end

-- World map bearing. Both endpoints use the currently viewed map coordinates.
function M.Bearing(canvas,mapID)
 local way=ForeverCompanionQuestWaypoints
 local target=way and readPublic(way.Active)
 if not target or target.map~=mapID or not validCoordinates(target.x,target.y) then return end
 local width,height=readPublic(canvas.GetWidth,canvas),readPublic(canvas.GetHeight,canvas)
 if not finite(width) or not finite(height) or width<=0 or height<=0 then return end
 local pos=C_Map and readPublic(C_Map.GetPlayerMapPosition,mapID,'player')
 if not pos then return end
 local fromX,fromY=readPublic(pos.GetXY,pos)
 if validCoordinates(fromX,fromY) then
  local cx,cy=M.CanvasPoint(mapID,fromX,fromY)
  local tx,ty=M.CanvasPoint(mapID,target.x,target.y)
  return cx*width,cy*height,tx*width,ty*height
 end
end

local function drawBearing(map)
 local canvas=map:GetCanvas()
 local options=ForeverCompanionDB
 local fromX,fromY,toX,toY
 if canvas and (not options or options.mapShowBearing~=false) then
  fromX,fromY,toX,toY=M.Bearing(canvas,map:GetMapID())
 end
 if not fromX then
  if bearingLayer then bearingLayer:Hide() end
  return
 end
 if not bearingLayer or bearingLayer:GetParent()~=canvas then
  if bearingLayer then bearingLayer:Hide() end
  bearingLayer=CreateFrame('Frame',nil,canvas)
  bearingLayer:SetAllPoints(canvas)
  bearingLayer:EnableMouse(false)
  bearingDots={}
  bearingBeacon=bearingLayer:CreateTexture(nil,'OVERLAY')
  bearingBeacon:SetTexture('Interface\\AddOns\\ForeverCompanion\\Media\\AtlasBearingBeacon')
  bearingBeacon:SetSize(34,34)
 end
 bearingLayer:SetFrameLevel(canvasLevel(canvas)+95)
 local dx,dy=toX-fromX,toY-fromY
 local span=math.sqrt(dx*dx+dy*dy)
 local count=math.min(56,math.max(0,math.floor((span-34)/17)))
 for i=1,count do
  local dot=bearingDots[i]
  if not dot then
   dot=bearingLayer:CreateTexture(nil,'ARTWORK')
   dot:SetTexture('Interface\\AddOns\\ForeverCompanion\\Media\\AtlasBearingDot')
   dot:SetSize(8,8)
   bearingDots[i]=dot
  end
  local fraction=(17*i)/span
  dot:ClearAllPoints()
  dot:SetPoint('CENTER',bearingLayer,'TOPLEFT',fromX+dx*fraction,-(fromY+dy*fraction))
  dot:Show()
 end
 for i=count+1,#bearingDots do bearingDots[i]:Hide() end
 bearingBeacon:ClearAllPoints()
 bearingBeacon:SetPoint('CENTER',bearingLayer,'TOPLEFT',toX,-toY)
 bearingLayer:Show()
end

function M.CursorCoordinates(map)
 local scroll=map and map.ScrollContainer
 if scroll and readPublic(scroll.IsMouseOver,scroll)==true then
  local x,y=readPublic(scroll.GetNormalizedCursorPosition,scroll)
  if validCoordinates(x,y) then return x,y end
 end
end

local function zoneRange(mapID)
 local lo,hi=readPublic(C_Map.GetMapLevels,mapID)
 if finite(lo) and finite(hi) and lo>0 and hi>=lo then
  return lo==hi and ('Lv. %d'):format(lo) or ('Lv. %d-%d'):format(lo,hi),lo,hi
 end
 local walkthrough=ForeverCompanionWalkthrough
 for _,chapter in ipairs(walkthrough and walkthrough.chapters or {}) do
  if chapter[1]==mapID then return ('Lv. %d-%d'):format(chapter[2],chapter[3]),chapter[2],chapter[3] end
 end
end

function M.ZoneLevelText(mapID)
 if not finite(mapID) or not C_Map or not Enum or not Enum.UIMapType then return end
 local info=readPublic(C_Map.GetMapInfo,mapID)
 if type(info)=='table' and info.mapType==Enum.UIMapType.Zone then return zoneRange(mapID) end
end

function M.ContinentZoneLevels(mapID,info)
 local result={}
 local types=Enum and Enum.UIMapType
 if not types or not types.Continent or not C_Map or not info or info.mapType~=types.Continent then return result end
 local zones=readPublic(C_Map.GetMapChildrenInfo,mapID,types.Zone,false)
 if type(zones)~='table' or type(C_Map.GetMapRectOnMap)~='function' then return result end
 local seen={}
 for _,zone in ipairs(zones) do
  local id=zone.mapID
  if finite(id) and id>0 and not seen[id] then
   seen[id]=true
   local range,low,high=zoneRange(id)
   if range then
    local ok,left,right,top,bottom=pcall(C_Map.GetMapRectOnMap,id,mapID)
    if ok and validCoordinates(left,top) and validCoordinates(right,bottom) and left<right and top<bottom then
     result[#result+1]={id=id,name=zone.name,text=range,low=low,high=high,x=(left+right)/2,y=(top+bottom)/2}
    end
   end
  end
 end
 return result
end

local function showZoneLevels(canvas,mapID,info,width,height)
 local zones=M.ContinentZoneLevels(mapID,info)
 if #zones==0 then return end
 if not zoneLabelLayer or zoneLabelLayer:GetParent()~=canvas then
  zoneLabelLayer=CreateFrame('Frame',nil,canvas)
  zoneLabelLayer:SetAllPoints(canvas)
  zoneLabelLayer:EnableMouse(false)
  zoneLevelLabels={}
 end
 zoneLabelLayer:SetFrameLevel(canvasLevel(canvas)+79)
 local level=readPublic(UnitLevel,'player')
 for i,zone in ipairs(zones) do
  local label=zoneLevelLabels[i]
  if not label then
   label=zoneLabelLayer:CreateFontString(nil,'OVERLAY','GameFontNormalSmall')
   label:SetTextColor(.98,.86,.58)
   label:SetShadowColor(0,0,0,1)
   label:SetShadowOffset(1,-1)
   zoneLevelLabels[i]=label
  end
  label:SetText(zone.text)
  if finite(level) and level>=zone.low and level<=zone.high then
   label:SetTextColor(.58,1,.66)
  else
   label:SetTextColor(.98,.86,.58)
  end
  label:ClearAllPoints()
  local cx,cy=M.CanvasPoint(mapID,zone.x,zone.y)
  label:SetPoint('CENTER',canvas,'TOPLEFT',cx*width,-cy*height-10)
  label:Show()
 end
end

function M.GoToCoordinates(input)
 local a,b=input:match('^%s*(%d+%.?%d*)%s*,%s*(%d+%.?%d*)%s*$')
 if not a then a,b=input:match('^%s*(%d+%.?%d*)%s+(%d+%.?%d*)%s*$') end
 local x,y=tonumber(a),tonumber(b)
 if not x or not y or not validCoordinates(x/100,y/100) then
  return 'Enter two coordinates from 0 to 100, for example /fc coords 42.5 67.1.'
 end
 local map=worldMap or WorldMapFrame
 local id
 if map and readPublic(map.IsShown,map)==true then id=readPublic(map.GetMapID,map)
 elseif C_Map then id=readPublic(C_Map.GetBestMapForUnit,'player') end
 if not finite(id) or id<1 then return 'Open the world map to the destination zone first.' end
 if not Enum or not Enum.UIMapType then return 'Zone map type unavailable on this client.' end
 local info=C_Map and readPublic(C_Map.GetMapInfo,id)
 if type(info)~='table' or info.mapType~=Enum.UIMapType.Zone then
  return 'Choose a zone map before setting a coordinate waypoint.'
 end
 local label=('%s %.1f, %.1f'):format(info.name or 'Map point',x,y)
 return ForeverCompanionQuestWaypoints.Navigate({map=id,x=x/100,y=y/100,label=label,source='Entered coordinates'},false,label)
end

function M.OpenAppearance(anchor)
 ForeverCompanionDB=ForeverCompanionDB or {}
 local db=ForeverCompanionDB;local entries={}
 for _,preset in ipairs({{'Small service icons',20},{'Standard service icons',24},{'Large service icons',28}}) do
  local name,size=preset[1],preset[2]
  entries[#entries+1]={label=name,selected=serviceIconSize(db)==serviceIconSizes[size],action=function() db.mapServiceIconSize=size;M.Refresh() end}
 end
 entries[#entries+1]={label='Show dungeon entrances',selected=not db.hideDungeonPins,action=function() db.hideDungeonPins=not db.hideDungeonPins;M.Refresh() end}
 entries[#entries+1]={label='Show service names',selected=db.mapServiceLabels==true,action=function() db.mapServiceLabels=not db.mapServiceLabels;M.Refresh() end}
 entries[#entries+1]={label='Tighter service clusters',selected=db.mapServiceTight==true,action=function() db.mapServiceTight=not db.mapServiceTight;M.Refresh() end}
 entries[#entries+1]={label='Show player map coordinates',selected=db.mapShowCoordinates~=false,action=function() db.mapShowCoordinates=db.mapShowCoordinates==false;M.Refresh() end}
 entries[#entries+1]={label='Show cursor coordinates',selected=db.mapShowCursor~=false,action=function() db.mapShowCursor=db.mapShowCursor==false;M.Refresh() end}
 entries[#entries+1]={label='Show dungeon level labels',selected=db.mapShowDungeonLevels~=false,action=function() db.mapShowDungeonLevels=db.mapShowDungeonLevels==false;M.Refresh() end}
 entries[#entries+1]={label='Show waypoint bearing',selected=db.mapShowBearing~=false,action=function()
  db.mapShowBearing=db.mapShowBearing==false;M.Refresh()
 end}
 entries[#entries+1]={label='Adjust markers as you zoom',selected=db.mapAdaptiveMarkers~=false,action=function()
  db.mapAdaptiveMarkers=db.mapAdaptiveMarkers==false;M.Refresh()
 end}
 entries[#entries+1]={label='Show zone levels',selected=db.mapShowLevels~=false,action=function() db.mapShowLevels=db.mapShowLevels==false;M.Refresh() end}
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
  if finite(width) and width>24 then bar:SetScale(math.min(1,math.max(.5,(width-24)/(bar:GetWidth() or 520)))) end
 end
 fitToolbar();bar:SetScript('OnShow',fitToolbar);if map.HookScript then map:HookScript('OnSizeChanged',fitToolbar) end
 local accent=bar:CreateTexture(nil,'ARTWORK');accent:SetColorTexture(.20,.72,.78,1);accent:SetPoint('TOPLEFT',0,0);accent:SetPoint('TOPRIGHT',0,0);accent:SetHeight(2)
 local title=U.Text(bar,13);title:SetPoint('TOPLEFT',12,-9);title:SetWidth(300);title:SetHeight(18)
 local hint=U.Text(bar,10,U.palette.muted);hint:SetPoint('TOPLEFT',12,-33);hint:SetWidth(392);hint:SetHeight(14)
 local coordinates=U.Text(bar,10,{.40,.83,.86,1});coordinates:SetPoint('TOPRIGHT',-12,-33);coordinates:SetWidth(220);coordinates:SetHeight(14);coordinates:SetJustifyH('RIGHT')
 local function updateCoordinates()
  coordinates:SetShown(not db.mapDockMinimized and (db.mapShowCoordinates~=false or db.mapShowCursor~=false));hint:SetWidth(db.mapShowCoordinates==false and db.mapShowCursor==false and 496 or db.mapShowCursor==false and 378 or 265)
  if db.mapDockMinimized or (db.mapShowCoordinates==false and db.mapShowCursor==false) then return end
  local mapID=map:GetMapID()
  local ok,position=pcall(function() return C_Map and C_Map.GetPlayerMapPosition and C_Map.GetPlayerMapPosition(mapID,'player') end)
  local x,y
  if ok and position and not (issecretvalue and issecretvalue(position)) and type(position.GetXY)=='function' then
   local readable,a,b=pcall(position.GetXY,position);if readable then x,y=a,b end
  end
  local playerText=db.mapShowCoordinates~=false and (validCoordinates(x,y) and ('You %.1f, %.1f'):format(x*100,y*100) or 'No position')
  local cx,cy
  if db.mapShowCursor~=false and not readPublic(bar.IsMouseOver,bar) then cx,cy=M.CursorCoordinates(map) end
  local cursorText=cx and ('Cursor %.1f, %.1f'):format(cx*100,cy*100)
  if playerText and cursorText then coordinates:SetText(playerText..'  |  '..cursorText)
  else coordinates:SetText(playerText or cursorText or '') end
 end
 local elapsed=0
 bar:SetScript('OnUpdate',function(_,dt)
  elapsed=elapsed+dt
  if elapsed>=.25 then
   elapsed=0
   updateCoordinates()
   drawBearing(map)
  end
 end)
 updateCoordinates()
 local atlas=U.Button(bar);atlas:SetSize(74,26);atlas:SetPoint('TOPRIGHT',-225,-6);atlas:SetText('Diorama')
 U.SetHoverHelp(atlas,'Atlas Diorama','Toggle original 3D map markers and detailed close-up terrain.')
 atlas:SetScript('OnClick',function() M.SetMapStyle(mapStyle()=='diorama' and 'clear' or 'diorama') end)
 briefingButton=U.Button(bar);briefingButton:SetSize(69,26);briefingButton:SetPoint('TOPRIGHT',-146,-6);briefingButton:SetText('Briefing')
 briefingButton:SetScript('OnClick',function()
  db.mapBriefingHidden=not db.mapBriefingHidden
  M.Refresh()
 end)
 local find=U.Button(bar);find:SetSize(62,26);find:SetPoint('TOPRIGHT',-80,-6);find:SetText('Services')
 find:SetScript('OnClick',function() ForeverCompanionServiceAtlas.Toggle(true) end)
 local minimize=U.Button(bar);minimize:SetSize(26,26)
 local expand=U.Button(bar);expand:SetSize(26,26);expand:SetPoint('TOPRIGHT',-10,-6)
 local drawer=CreateFrame('Frame',nil,bar);drawer:SetSize(520,86);drawer:SetPoint('TOPLEFT',0,-54)
 local function layout()
  local minimized=db.mapDockMinimized==true;local expanded=db.mapDockExpanded==true
  bar:SetSize(minimized and 190 or 520,minimized and 30 or (expanded and 140 or 54))
  drawer:SetShown(not minimized and expanded);atlas:SetShown(not minimized);briefingButton:SetShown(not minimized);find:SetShown(not minimized);expand:SetShown(not minimized);hint:SetShown(not minimized)
  title:SetWidth(minimized and 136 or 192);drag:SetSize(minimized and 144 or 207,28)
  minimize:ClearAllPoints();minimize:SetPoint('TOPRIGHT',minimized and -8 or -45,minimized and -2 or -6);minimize:SetText(minimized and '+' or '-')
  expand:SetText(expanded and '-' or '+');updateCoordinates();fitToolbar()
 end
 minimize:SetScript('OnClick',function() db.mapDockMinimized=not db.mapDockMinimized;dungeonSelection=nil;U.CloseMenu();layout();M.Refresh() end)
 minimize:SetScript('OnEnter',function(self) if GameTooltip then GameTooltip:SetOwner(self,'ANCHOR_RIGHT');GameTooltip:SetText(db.mapDockMinimized and 'Restore Companion map panel' or 'Minimize Companion map panel');GameTooltip:Show() end end)
 minimize:SetScript('OnLeave',function() if GameTooltip then GameTooltip:Hide() end end)
 M.mapDock=bar;M.minimizeMapDock=minimize;M.mapDockFind=find;M.mapDockHint=hint;M.mapDockCoordinates=coordinates
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
  entries[#entries+1]={label='Vendors and repairs only',selected=db.mapVendorsOnly==true,action=function()
   db.mapVendorsOnly=not db.mapVendorsOnly
   if db.mapVendorsOnly then db.questMapHideTowns=false end
   M.Refresh()
  end}
  for _,entry in ipairs(ForeverCompanionServiceAtlas.Categories) do if entry[1]~='all' then
   local key,label=entry[1],entry[2];entries[#entries+1]={label=label,selected=hidden[key]~=true,action=function() db.mapVendorsOnly=nil;hidden[key]=not hidden[key];M.Refresh() end}
  end end
  entries[#entries+1]={label='Show all service types',action=function() db.questMapHiddenServices={};db.mapVendorsOnly=nil;M.Refresh() end}
  U.Menu(services,'MAP SERVICES',entries)
 end)
 button(262,-35,94,'Overlay map',function() ForeverCompanionMapOverlay.Toggle() end)
 button(364,-35,70,'Stop arrow',function() ForeverCompanionQuestWaypoints.Clear();M.Refresh() end)
 local appearance;appearance=button(442,-35,66,'Tools...',function() ForeverCompanionInterface.Menu(appearance,'MAP TOOLS',{
  {label='Only show zone starter pickups',selected=db.mapOnlyZoneStarts==true,action=function()
   db.mapOnlyZoneStarts=not db.mapOnlyZoneStarts
   if db.mapOnlyZoneStarts then db.questMapHidePickups=false;db.mapHideZoneStarts=false;db.questMapMode='all' end
   M.Refresh()
  end},
  {label='Mark zone starters',selected=not db.mapHideZoneStarts,action=function()
   db.mapHideZoneStarts=not db.mapHideZoneStarts
   if db.mapHideZoneStarts then db.mapOnlyZoneStarts=nil end
   M.Refresh()
  end},
  {label='Browse zones by level',action=function()
   local guide=ForeverCompanionWalkthrough
   local choices={}
   for _,chapter in ipairs(guide and guide.chapters or {}) do
    local id,lo,hi,name=chapter[1],chapter[2],chapter[3],chapter[5]
    choices[#choices+1]={low=lo,name=name,label=(M.ZoneLevelText(id) or ('Lv. %d-%d'):format(lo,hi))..'  |  '..name,
     action=function() readPublic(map.SetMapID,map,id) end}
   end
   table.sort(choices,function(a,b) if a.low==b.low then return a.name<b.name end;return a.low<b.low end)
   U.PagedMenu(appearance,'ZONES BY LEVEL',choices,nil,290)
  end},
  {label='Map appearance',action=function() M.OpenAppearance(appearance) end},
  {label='Center on player',action=function()
   local current,x,y=ForeverCompanionMapTools.Position()
   if current and type(map.SetMapID)=='function' and type(map.PanAndZoomTo)=='function' then
    if map:GetMapID()~=current then map:SetMapID(current) end
    if map:GetMapID()==current then map:PanAndZoomTo(x,y) end
   end
  end},
  {label='Reset map zoom',action=function() readPublic(map.ResetZoom,map) end},
  {label='Personal notes',action=function() ForeverCompanionMapTools.Toggle() end},
  {label='Find nearby service',action=function() ForeverCompanionMapTools.NearestMenu(appearance) end},
 }) end)
 local legend=U.Text(drawer,10,U.palette.muted);legend:SetPoint('TOPLEFT',12,-65);legend:SetWidth(496);legend:SetText('Gold star: zone start   ! pickup   ? turn-in · Drag header to move dock')
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
 area:SetFrameLevel(canvas:GetFrameLevel()+30)
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

local function liveQuests()
 local planner=ForeverCompanionQuestPlanner
 return planner.IsSupported() and planner.GetLive() or {}
end

local function briefingChoice(map,quests)
 if not worldMap or not worldMap:IsShown() or worldMap:GetMapID()~=map then return end
 quests=quests or liveQuests()
 local way=ForeverCompanionQuestWaypoints
 local pos=C_Map and readPublic(C_Map.GetPlayerMapPosition,map,'player')
 local x,y
 if pos then x,y=readPublic(pos.GetXY,pos) end
 return ForeverCompanionZoneBriefing.Choose(map,way.MapLocations(map,quests),mapPickups(map,quests,true),x,y)
end
local function briefingServices(map)
 local catalog=ForeverCompanionTownServices
 local sources=catalog and catalog.ForMap(map)
 local tools=ForeverCompanionMapTools
 if not tools or type(sources)~='table' then return end
 local here,x,y=tools.Position()
 local names={}
 for _,kind in ipairs({{'F','Flight'},{'R','Repairs'}}) do
  local target
  if here==map then
   local ranked=tools.RankServices(sources,map,x,y,kind[1])
   target=ranked[1] and ranked[1].target
  else
   for _,service in ipairs(sources) do
    if service.symbol==kind[1] then target=service;break end
   end
  end
  if target then names[#names+1]=kind[2]..': '..target.label end
 end
 return table.concat(names,'  |  ')
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
 local openMap=stitchedMap()
 stitchedArtLevel=openMap and readPublic(openMap.ArtTopLevel) or nil
 if not guide then guide,guideTitle,guideHint=createGuide(worldMap) end
 modeButton:SetText("Map: "..modeNames[view])
 local style=mapStyle()
 styleButton:SetText("Style: "..style:sub(1,1):upper()..style:sub(2))
 townButton:SetText(townsEnabled() and ((ForeverCompanionDB or {}).mapVendorsOnly and "Vendors & repairs" or "Services: On") or "Services: Off")
 pickupButton:SetText(ForeverCompanionDB and ForeverCompanionDB.questMapHidePickups and "Pickups: Off" or "Pickups: On")
 local diorama=style=="diorama"
 if (style=="atlas" or diorama) and not openMap then showTerrain(canvas,diorama) end
 if ForeverCompanionWorldMapDetail then
  ForeverCompanionWorldMapDetail.Refresh(worldMap,canvas,mapID,(style=="atlas" or diorama) and not openMap)
 end
 local info=readPublic(C_Map and C_Map.GetMapInfo,mapID)
 local knownMap=type(info)=='table'
 local name=knownMap and info.name or 'COMPANION MAP'
 local db=ForeverCompanionDB or {}
 local types=Enum and Enum.UIMapType
 local briefing=ForeverCompanionZoneBriefing
 local tier=briefing and briefing.Tier(knownMap and info.mapType,types,readPublic(worldMap.GetCanvasZoomPercent,worldMap),db.mapAdaptiveMarkers~=false) or 'detail'
 showDungeons(worldMap,canvas,mapID,width,height)
 local serviceNotice,serviceCount
 if tier~='overview' then serviceNotice,serviceCount=showServices(canvas,mapID,scale,tier) end
 local levels=not ForeverCompanionDB or ForeverCompanionDB.mapShowLevels~=false
 local levelText=levels and M.ZoneLevelText(mapID)
 if levels and knownMap then showZoneLevels(canvas,mapID,info,width,height) end
 guideTitle:SetText(levelText and (name..'  |  '..levelText) or name)
 guideHint:SetText(serviceNotice or ((serviceCount or 0)..' service references · '..(view=='off' and 'Quest layer hidden' or 'Choose a quest marker or Find services')))
 zoomButton:SetEnabled(false)
 guide:Show()
 local zone=knownMap and types and info.mapType==types.Zone
 briefingButton:SetEnabled(not not zone)
 if dungeonSelection and (dungeonSelection.location.map~=mapID or db.hideDungeonPins) then dungeonSelection=nil end
 if dungeonSelection then
  ForeverCompanionDungeonBriefing.Show(guide,dungeonSelection,function()
   dungeonSelection=nil
   M.Refresh()
  end)
 elseif briefing and zone and not db.mapBriefingHidden and not db.mapDockMinimized then
  local title=levelText and (name..'  |  '..levelText) or name
  briefing.Show(guide,mapID,title,briefingChoice(mapID),briefingServices(mapID),briefingChoice)
 end
 drawBearing(worldMap)
 if ForeverCompanionMapTools then ForeverCompanionMapTools.DrawMap(canvas,mapID,width,height,scale) end
 if tier=="overview" or view=="off" or (view=="focus" and not focus) then return end
 -- All-mode must still display live quest locations when no quest is focused.
 -- A missing focus is not an empty quest log.

 if focus then pcall(drawArea,canvas,mapID,focus,width,height) end
 local quests=liveQuests()
 local locations=ForeverCompanionQuestWaypoints.MapLocations(mapID,view=="focus" and {focus} or quests)
 local groups=focus and focusGroups(locations,focus,width*scale,height*scale) or {}
 if #groups>0 then
  zoomPoint=groups[1].entry.target
  zoomButton:SetEnabled(type(worldMap.PanAndZoomTo)=="function")
  guideHint:SetText(focus.complete and "Turn-in  ·  Click marker for arrow" or ForeverCompanionQuestWaypoints.Describe(groups[1].entry.target))
 elseif focus then
  guideHint:SetText(ForeverCompanionQuestWaypoints.Explain(focus,mapID))
 elseif view=="all" then
  guideHint:SetText("Click a quest marker to focus it")
 end
 if view=="all" then
  addOtherQuests(groups,locations,focus,width*scale,height*scale)
  local pickupPoints={}
  local entries=mapPickups(mapID,quests)
  local showStartersOnly=false
  if tier=="zone" then
   for _,entry in ipairs(entries) do
    if entry.zoneStart then showStartersOnly=true;break end
   end
  end
  for _,entry in ipairs(entries) do
   if not showStartersOnly or entry.zoneStart then
    pickupPoints[#pickupPoints+1]={x=entry.target.x,y=entry.target.y,symbol="!",label=entry.quest.title,entry=entry}
   end
  end
  for _,cluster in ipairs(ForeverCompanionServiceClusters.Build(pickupPoints,width*scale,height*scale,20)) do
   local pickups,nearby={},{}
   for _,point in ipairs(cluster) do
    if point.entry.zoneStart then table.insert(pickups,1,point.entry) else pickups[#pickups+1]=point.entry end
   end
   for i=2,#pickups do nearby[#nearby+1]=pickups[i] end
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
  local size=diorama and (group.focused and 42 or (entry.zoneStart and 40 or 34)) or (group.focused and 28 or (entry.zoneStart and 26 or 22))
  if group.focused and not focus.complete then
   pin.ring:SetSize(group.radius*2,group.radius*2)
   pin.ring:Show()
  else
   pin.ring:Hide()
  end
  pin:SetSize(size,size)
  pin:SetScale(1/scale)
  pin:SetFrameLevel(canvasLevel(canvas)+(group.focused and 102 or 101))
  local sprite=entry.zoneStart and 0 or (entry.pickup and 1 or (entry.quest.complete and 3 or 2))
  -- Sample each glyph independently so filtering never bleeds into its neighbor.
  pin.badge:ClearAllPoints()
  pin.badge:SetSize(size,size)
  pin.badge:SetPoint("CENTER",pin,"CENTER",0,diorama and size*.21 or 0)
  if diorama then dioramaMarker(pin.badge,sprite)
  else
   pin.badge:SetTexture("Interface\\AddOns\\ForeverCompanion\\Media\\WorldMapMarkers")
   pin.badge:SetTexCoord((32*sprite+.5)/128,(32*sprite+31.5)/128,.5/32,31.5/32)
  end
  pin.symbol:SetText(shared and (group.pickups and tostring(#group.pickups) or "+") or "")
  pin:ClearAllPoints()
  local cx,cy=M.CanvasPoint(mapID,target.x,target.y)
  pin:SetPoint("CENTER",canvas,"TOPLEFT",cx*width*scale+(group.offsetX or 0),-cy*height*scale)
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
local function attachOpenMap()
 local api=OpenMapAPI
 if openMapCallbacks or type(api)~='table' or api.major~=1 or type(api.RegisterCallback)~='function' then return end
 openMapCallbacks={}
 local function redraw()
  local queue=ForeverCompanionRefreshQueue
  if queue then queue.Schedule('openmap-companion',M.Refresh) else M.Refresh() end
 end
 api.RegisterCallback(openMapCallbacks,'OpenMap_ViewChanged',redraw)
 api.RegisterCallback(openMapCallbacks,'OpenMap_StitchedChanged',redraw)
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
 provider.OnHide=function() dungeonSelection=nil;hidePins() end
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
 if event=="ADDON_LOADED" and name=="OpenMap" then attachOpenMap();return end
 if event=="ADDON_LOADED" and name~="Blizzard_WorldMap" and name~="ForeverCompanion" then return end
 attachOpenMap()
 if event=="QUEST_POI_UPDATE" or event=="PLAYER_LEVEL_UP" or event=="QUEST_TURNED_IN" then M.Refresh() else attach() end
end)
