-- Companion-owned map artwork. Never changes Blizzard's watched quests or waypoints.
local M={}
ForeverCompanionQuestMap=M

local provider,worldMap,area,areaChecked,guide,guideTitle,guideHint,modeButton,zoomButton
local pins,zoomPoint={}
local modeNames={focus="Focus",all="All",off="Off"}
local nextMode={focus="all",all="off",off="focus"}

local function mode()
 local saved=ForeverCompanionDB and ForeverCompanionDB.questMapMode
 return modeNames[saved] and saved or "focus"
end

local function hidePins()
 for _,pin in ipairs(pins) do pin:Hide() end
 if area then area:Hide() end
 if guide then guide:Hide() end
end

local function createPin(canvas)
 local pin=CreateFrame("Button",nil,canvas)
 pin:EnableMouse(true)
 pin:RegisterForClicks("LeftButtonUp")
 pin.ring=pin:CreateTexture(nil,"BACKGROUND",nil,-1)
 pin.ring:SetTexture("Interface\\AddOns\\ForeverCompanion\\Media\\QuestLocationRing")
 pin.ring:SetPoint("CENTER")
 pin.ring:SetVertexColor(.22,.91,1,.95)
 local outline=pin:CreateTexture(nil,"BACKGROUND")
 outline:SetAllPoints(pin)
 outline:SetColorTexture(.03,.08,.11,1)
 pin.badge=pin:CreateTexture(nil,"ARTWORK")
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
  GameTooltip:AddLine(entry.quest.complete and "Turn-in destination" or (entry.target.objective or "Quest objective"),1,1,1,true)
  GameTooltip:AddLine(entry.target.label or entry.target.source,.68,.75,.82,true)
  if self.samples>1 then GameTooltip:AddLine("Nearby reported locations: "..self.samples,.68,.75,.82) end
  GameTooltip:AddLine(self.focused and "Click to start arrow" or "Click to focus quest",.46,.84,.96)
  GameTooltip:Show()
 end)
 pin:SetScript("OnLeave",function()
  if GameTooltip then GameTooltip:Hide() end
 end)
 pin:SetScript("OnClick",function(self)
  local entry=self.entry
  if self.focused or (IsShiftKeyDown and IsShiftKeyDown()) then
   if not self.focused then ForeverCompanionQuestPlanner.Select(entry.index) end
   guideHint:SetText(ForeverCompanionQuestWaypoints.Navigate(entry.target,false,entry.quest.title))
  else
   ForeverCompanionQuestPlanner.Select(entry.index)
  end
 end)
 return pin
end

local function createGuide(map)
 local bar=CreateFrame("Frame",nil,map)
 bar:SetSize(338,62)
 bar:SetPoint("TOP",map,"TOP",0,-38)
 bar:SetFrameLevel(map:GetFrameLevel()+200)
 local bg=bar:CreateTexture(nil,"BACKGROUND")
 bg:SetAllPoints(bar)
 bg:SetColorTexture(.035,.057,.088,.95)
 local title=bar:CreateFontString(nil,"OVERLAY","GameFontHighlight")
 title:SetPoint("TOP",0,-5)
 title:SetWidth(319)
 local hint=bar:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
 hint:SetPoint("TOP",0,-22)
 hint:SetWidth(319)
 hint:SetTextColor(.72,.86,.92)
 modeButton=CreateFrame("Button",nil,bar,"UIPanelButtonTemplate")
 modeButton:SetSize(100,22)
 modeButton:SetPoint("BOTTOM",bar,"BOTTOM",-56,3)
 modeButton:SetScript("OnClick",function()
  ForeverCompanionDB=ForeverCompanionDB or {}
  ForeverCompanionDB.questMapMode=nextMode[mode()]
  M.Refresh()
 end)
 zoomButton=CreateFrame("Button",nil,bar,"UIPanelButtonTemplate")
 zoomButton:SetSize(100,22)
 zoomButton:SetPoint("BOTTOM",bar,"BOTTOM",56,3)
 zoomButton:SetText("Zoom focus")
 zoomButton:SetScript("OnClick",function()
  if zoomPoint and type(map.PanAndZoomTo)=="function" then
   map:PanAndZoomTo(zoomPoint.x,zoomPoint.y)
  end
 end)
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

function M.Refresh()
 if not worldMap or not worldMap:IsShown() then return end
 hidePins()
 zoomPoint=nil
 local planner=ForeverCompanionQuestPlanner
 if not planner.IsSupported() then return end
 local mapID,canvas=worldMap:GetMapID(),worldMap:GetCanvas()
 if not mapID or not canvas then return end
 local width,height=canvas:GetWidth(),canvas:GetHeight()
 if not width or not height or width<=0 or height<=0 then return end
 local focus=planner.GetSelected()
 if not focus then return end
 local view=mode()
 if not guide then guide,guideTitle,guideHint=createGuide(worldMap) end
 modeButton:SetText("Map: "..modeNames[view])
 guideTitle:SetText(focus.title)
 guideHint:SetText(view=="off" and "Companion markers hidden" or "No destination on this map")
 zoomButton:SetEnabled(false)
 guide:Show()
 if view=="off" then return end

 pcall(drawArea,canvas,mapID,focus,width,height)
 local quests=planner.GetLive()
 local locations=ForeverCompanionQuestWaypoints.MapLocations(mapID,view=="focus" and {focus} or quests)
 local scale=canvas.GetScale and canvas:GetScale() or 1
 if type(scale)~="number" or scale<=0 then scale=1 end
 local groups=focusGroups(locations,focus,width*scale,height*scale)
 if #groups>0 then
  zoomPoint=groups[1].entry.target
  zoomButton:SetEnabled(type(worldMap.PanAndZoomTo)=="function")
  guideHint:SetText(focus.complete and "Turn-in  ·  Click marker for arrow" or "Highlighted destinations  ·  Click marker for arrow")
 elseif view=="all" then
  guideHint:SetText("Click another quest marker to focus it")
 end
 if view=="all" then
  local seen={[focus]=true}
  for _,entry in ipairs(locations) do
   if #groups>=12 then break end
   if not seen[entry.quest] then
    groups[#groups+1]={entry=entry,samples=1}
    seen[entry.quest]=true
   end
  end
 end

 for i,group in ipairs(groups) do
  local pin=pins[i] or createPin(canvas)
  pins[i]=pin
  local entry=group.entry
  local target=entry.target
  pin.entry,pin.focused,pin.samples=entry,group.focused,group.samples
  local size=group.focused and 22 or 13
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
  pin.symbol:SetText(entry.quest.complete and "?" or (group.focused and ">" or ""))
  pin:ClearAllPoints()
  pin:SetPoint("CENTER",canvas,"TOPLEFT",target.x*width*scale,-target.y*height*scale)
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
  -- Native shapes depend on map zoom. Refresh after the zoom animation settles.
  if provider.zoomTimer then provider.zoomTimer:Cancel() end
  if C_Timer and C_Timer.NewTimer then
   provider.zoomTimer=C_Timer.NewTimer(.15,function()
    provider.zoomTimer=nil
    M.Refresh()
   end)
  end
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
events:SetScript("OnEvent",function(_,event,name)
 if event=="ADDON_LOADED" and name~="Blizzard_WorldMap" then return end
 if event=="QUEST_POI_UPDATE" then M.Refresh() else attach() end
end)
