-- Companion-owned map artwork. Never changes Blizzard's watched quests or waypoints.
local M={}
ForeverCompanionQuestMap=M

local provider,worldMap,area,areaChecked,guide,guideTitle,guideHint
local pins={}
local colors={focus={.20,.87,1},ready={.42,1,.51},active={1,.78,.24}}

local function hidePins()
 for _,pin in ipairs(pins) do pin:Hide() end
 if area then area:Hide() end
 if guide then guide:Hide() end
end

local function createPin(canvas)
 local pin=CreateFrame("Button",nil,canvas)
 pin:SetSize(22,22)
 pin:EnableMouse(true)
 pin:RegisterForClicks("LeftButtonUp")
 pin.ring=pin:CreateTexture(nil,"BACKGROUND",nil,-1)
 pin.ring:SetTexture("Interface\\AddOns\\ForeverCompanion\\Media\\QuestLocationRing")
 pin.ring:SetPoint("CENTER",pin,"CENTER")
 pin.ring:SetSize(62,62)
 pin.ring:SetVertexColor(.20,.87,1,.85)
 local outline=pin:CreateTexture(nil,"BACKGROUND")
 outline:SetAllPoints(pin)
 outline:SetColorTexture(.03,.05,.08,.96)
 pin.badge=pin:CreateTexture(nil,"ARTWORK")
 pin.badge:SetPoint("TOPLEFT",2,-2)
 pin.badge:SetPoint("BOTTOMRIGHT",-2,2)
 pin.symbol=pin:CreateFontString(nil,"OVERLAY","GameFontNormal")
 pin.symbol:SetPoint("CENTER")
 pin.symbol:SetTextColor(.05,.08,.12)
 pin:SetScript("OnEnter",function(self)
  if not GameTooltip then return end
  GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
  GameTooltip:SetText(self.entries[1].quest.title)
  for index=1,math.min(#self.entries,6) do
   local entry=self.entries[index]
   local quest=entry.quest
   local action=quest.complete and "Turn in" or "Objective"
   local target=entry.target
   GameTooltip:AddLine(target.objective or (action.." · "..quest.title),1,1,1,true)
   local location=target.label and (target.label.." · ") or ""
   GameTooltip:AddLine(location..target.source,.68,.75,.82,true)
  end
  if #self.entries>6 then GameTooltip:AddLine("+"..(#self.entries-6).." nearby locations",.68,.75,.82) end
  GameTooltip:AddLine("Click to focus  ·  Shift-click for arrow",.46,.84,.96)
  GameTooltip:Show()
 end)
 pin:SetScript("OnLeave",function()
  if GameTooltip then GameTooltip:Hide() end
 end)
 pin:SetScript("OnClick",function(self)
  local entry=self.entries[1]
  for _,candidate in ipairs(self.entries) do
   if candidate.quest==self.focus then entry=candidate;break end
  end
  ForeverCompanionQuestPlanner.Select(entry.index)
  if IsShiftKeyDown and IsShiftKeyDown() then
   local result=ForeverCompanionQuestWaypoints.Navigate(entry.target,false)
   if guideHint then guideHint:SetText(result) end
  end
 end)
 return pin
end

local function createGuide(map)
 local bar=CreateFrame("Frame",nil,map)
 bar:SetSize(310,48)
 bar:SetPoint("TOP",map,"TOP",0,-36)
 bar:SetFrameLevel(map:GetFrameLevel()+200)
 local bg=bar:CreateTexture(nil,"BACKGROUND")
 bg:SetAllPoints(bar)
 bg:SetColorTexture(.035,.057,.088,.94)
 local accent=bar:CreateTexture(nil,"ARTWORK")
 accent:SetPoint("TOPLEFT")
 accent:SetPoint("TOPRIGHT")
 accent:SetHeight(2)
 accent:SetColorTexture(.20,.87,1,.95)
 local title=bar:CreateFontString(nil,"OVERLAY","GameFontHighlight")
 title:SetPoint("TOP",0,-8)
 title:SetWidth(290)
 local hint=bar:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
 hint:SetPoint("TOP",0,-27)
 hint:SetWidth(290)
 hint:SetTextColor(.72,.83,.89)
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

function M.Refresh()
 if not worldMap or not worldMap:IsShown() then return end
 if area then area:Hide() end
 if guide then guide:Hide() end
 local planner=ForeverCompanionQuestPlanner
 if not planner.IsSupported() then hidePins();return end
 local mapID,canvas=worldMap:GetMapID(),worldMap:GetCanvas()
 if not mapID or not canvas then hidePins();return end
 local width,height=canvas:GetWidth(),canvas:GetHeight()
 if not width or not height or width<=0 or height<=0 then hidePins();return end
 local focus=planner.GetSelected()
 -- Draw only client-provided quest boundaries. A point never implies an area.
 pcall(drawArea,canvas,mapID,focus,width,height)

 local groups,byPosition={},{}
 local focusPoints,referencePoints=0,0
 local locations=ForeverCompanionQuestWaypoints.MapLocations(mapID,planner.GetLive())
 -- Keep dense spawn sets readable. A cluster is placed at one reported
 -- location, with the focused quest preferred as its representative.
 local scale=canvas.GetScale and canvas:GetScale() or 1
 local function add(entry)
  local target=entry.target
  local key=math.floor(target.x*width*scale/22+.5)..":"..math.floor(target.y*height*scale/22+.5)
  local group=byPosition[key]
  if not group then
   group={target=target,entries={}}
   byPosition[key]=group
   groups[#groups+1]=group
  end
  group.entries[#group.entries+1]=entry
  if entry.quest==focus then
   group.focus=true
   focusPoints=focusPoints+1
   if target.kind then referencePoints=referencePoints+1 end
  end
  if entry.quest.complete then group.ready=true end
 end
 for _,entry in ipairs(locations) do if entry.quest==focus then add(entry) end end
 for _,entry in ipairs(locations) do if entry.quest~=focus then add(entry) end end

 for i,group in ipairs(groups) do
  local pin=pins[i] or createPin(canvas)
  pins[i]=pin
  pin.focus,pin.entries=focus,group.entries
  local color=group.focus and colors.focus or (group.ready and colors.ready or colors.active)
  local symbol=group.focus and ">" or (group.ready and "?" or "!")
  local size=group.focus and 23 or 18
  if group.focus and not focus.complete then pin.ring:Show() else pin.ring:Hide() end
  pin:SetSize(size,size)
  pin:SetScale(1/scale)
  pin:SetFrameLevel(canvas:GetFrameLevel()+(group.focus and 102 or 101))
  pin.badge:SetColorTexture(color[1],color[2],color[3],1)
  pin.symbol:SetText(#group.entries>1 and tostring(#group.entries) or symbol)
  pin:ClearAllPoints()
  pin:SetPoint("CENTER",canvas,"TOPLEFT",group.target.x*width*scale,-group.target.y*height*scale)
  pin:Show()
 end
 for i=#groups+1,#pins do pins[i]:Hide() end
 if #groups>0 then
  if not guide then guide,guideTitle,guideHint=createGuide(worldMap) end
  guideTitle:SetText(focusPoints>0 and focus.title or "Quest locations")
  local hint="Click a marker to focus  ·  Shift-click for arrow"
  if focusPoints>0 and focus.complete then hint="Ready to turn in  ·  Shift-click for arrow"
  elseif referencePoints>0 then hint="Reported locations  ·  Shift-click for arrow" end
  guideHint:SetText(hint)
  guide:Show()
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
