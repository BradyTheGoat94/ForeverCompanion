-- Companion-owned map artwork. Never changes Blizzard's watched quests or waypoints.
local M={}
ForeverCompanionQuestMap=M

local provider,worldMap,area,areaChecked
local pins={}
local colors={focus={.20,.87,1},ready={.42,1,.51},active={1,.78,.24}}

local function hidePins()
 for _,pin in ipairs(pins) do pin:Hide() end
 if area then area:Hide() end
end

local function createPin(canvas)
 local pin=CreateFrame("Frame",nil,canvas)
 pin:SetSize(22,22)
 pin:EnableMouse(true)
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
  GameTooltip:SetText("Forever Companion")
  for _,entry in ipairs(self.entries) do
   local quest=entry.quest
   local action=quest.complete and "Turn in" or "Objective"
   GameTooltip:AddLine((quest==self.focus and "Focus · " or "")..action.." · "..quest.title,1,1,1,true)
   GameTooltip:AddLine(entry.target.source,.68,.75,.82)
  end
  GameTooltip:Show()
 end)
 pin:SetScript("OnLeave",function()
  if GameTooltip then GameTooltip:Hide() end
 end)
 return pin
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
   local blob=CreateFrame("QuestPOIFrame",nil,canvas)
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
 area:SetMapID(mapID)
 area:DrawNone()
 area:DrawBlob(quest.id,true)
 area:Show()
end

function M.Refresh()
 if not worldMap or not worldMap:IsShown() then return end
 if area then area:Hide() end
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
 for _,entry in ipairs(ForeverCompanionQuestWaypoints.MapLocations(mapID,planner.GetLive())) do
  local target=entry.target
  local key=target.x..":"..target.y
  local group=byPosition[key]
  if not group then
   group={target=target,entries={}}
   byPosition[key]=group
   groups[#groups+1]=group
  end
  group.entries[#group.entries+1]=entry
  if entry.quest==focus then group.focus=true end
  if entry.quest.complete then group.ready=true end
 end

 for i,group in ipairs(groups) do
  local pin=pins[i] or createPin(canvas)
  pins[i]=pin
  pin.focus,pin.entries=focus,group.entries
  local color=group.focus and colors.focus or (group.ready and colors.ready or colors.active)
  local symbol=group.focus and ">" or (group.ready and "?" or "!")
  local size=group.focus and 26 or 22
  pin:SetSize(size,size)
  pin:SetFrameLevel(canvas:GetFrameLevel()+(group.focus and 102 or 101))
  pin.badge:SetColorTexture(color[1],color[2],color[3],1)
  pin.symbol:SetText(#group.entries>1 and tostring(#group.entries) or symbol)
  pin:ClearAllPoints()
  pin:SetPoint("CENTER",canvas,"TOPLEFT",group.target.x*width,-group.target.y*height)
  pin:Show()
 end
 for i=#groups+1,#pins do pins[i]:Hide() end
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
