-- Standalone party markers on the Blizzard world map.
-- Uses only Blizzard unit/map APIs; never replaces native minimap party blips.
local P={}
ForeverCompanionPartyMap=P
local markers={}
local provider,map
local function validNumber(n)
 if issecretvalue and issecretvalue(n) then return false end
 return type(n)=="number" and n==n and n>=0 and n<=1
end
local function isOtherMember(unit)
 if not UnitExists or not UnitExists(unit) then return false end
 if UnitIsUnit then
  local ok,same=pcall(UnitIsUnit,unit,"player")
  if not ok or same then return false end
 end
 return true
end
local function partyUnits()
 local units={}
 if IsInRaid and IsInRaid() then
  for i=1,40 do
   local unit="raid"..i
   if isOtherMember(unit) then units[#units+1]=unit end
  end
 else
  for i=1,4 do
   local unit="party"..i
   if isOtherMember(unit) then units[#units+1]=unit end
  end
 end
 return units
end
P.PartyUnits=partyUnits
-- Shared art factory keeps world-map and minimap markers visually identical.
-- Only built-in textures and color primitives; no redistributed game artwork.
function P.StyleMarker(marker)
 marker:SetSize(28,28)
 local shadow=marker:CreateTexture(nil,"BACKGROUND")
 shadow:SetSize(27,27)
 shadow:SetPoint("CENTER",1,-1)
 shadow:SetColorTexture(.005,.025,.045,.84)
 if shadow.SetRotation then shadow:SetRotation(math.pi/4) end
 local rim=marker:CreateTexture(nil,"ARTWORK")
 rim:SetSize(23,23)
 rim:SetPoint("CENTER")
 rim:SetColorTexture(.10,.67,.87,.96)
 if rim.SetRotation then rim:SetRotation(math.pi/4) end
 local core=marker:CreateTexture(nil,"OVERLAY")
 core:SetSize(16,16)
 core:SetPoint("CENTER")
 core:SetColorTexture(.035,.13,.21,1)
 if core.SetRotation then core:SetRotation(math.pi/4) end
 local center=marker:CreateTexture(nil,"OVERLAY")
 center:SetSize(8,8)
 center:SetPoint("CENTER")
 center:SetColorTexture(.70,.96,1,1)
 if center.SetRotation then center:SetRotation(math.pi/4) end
 local arrow=marker:CreateTexture(nil,"OVERLAY")
 arrow:SetSize(16,16)
 arrow:SetPoint("CENTER",marker,"CENTER",0,0)
 arrow:SetTexture("Interface\\\\Minimap\\\\MinimapArrow")
 arrow:SetVertexColor(.95,.81,.43,1)
 marker.arrow=arrow
 return marker
end
local function makeMarker(canvas)
 local button=CreateFrame("Button",nil,canvas)
 button:SetFrameLevel(canvas:GetFrameLevel()+125)
 P.StyleMarker(button)
 button:SetScript("OnEnter",function(self)
  if GameTooltip and self.unit then
   GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
   GameTooltip:SetText((UnitName and UnitName(self.unit)) or self.unit)
   GameTooltip:AddLine("Party member · world map",.65,.87,1)
   GameTooltip:Show()
  end
 end)
 button:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
 return button
end
function P.Refresh()
 if not map or not map.IsShown or not map:IsShown() then return end
 local canvas=map:GetCanvas()
 local mapID=map:GetMapID()
 if not canvas or not mapID then return end
 local width,height=canvas:GetWidth(),canvas:GetHeight()
 if not width or not height or width<=0 or height<=0 then return end
 local scale=canvas.GetScale and canvas:GetScale() or 1
 if issecretvalue and issecretvalue(scale) then return end
 if type(scale)~="number" or scale<=0 then scale=1 end
 local units=partyUnits()
 for i,unit in ipairs(units) do
  local marker=markers[i]
  if not marker then marker=makeMarker(canvas);markers[i]=marker end
  marker.unit=unit
  local pos
  if C_Map and type(C_Map.GetPlayerMapPosition)=="function" then
   local ok,result=pcall(C_Map.GetPlayerMapPosition,mapID,unit)
   if ok then pos=result end
  end
  local x,y
  if pos and pos.GetXY then
   local ok,a,b=pcall(pos.GetXY,pos)
   if ok then x,y=a,b end
  end
  if validNumber(x) and validNumber(y) then
   marker:SetScale(1/scale)
   marker:ClearAllPoints()
   marker:SetPoint("CENTER",canvas,"TOPLEFT",x*width*scale,-y*height*scale)
   local facing
   if UnitFacing then
    local ok,result=pcall(UnitFacing,unit)
    if ok and not (issecretvalue and issecretvalue(result)) then facing=result end
   end
   if not (issecretvalue and issecretvalue(facing)) and type(facing)=="number" and facing==facing and marker.arrow.SetRotation then
    marker.arrow:SetRotation(-facing)
    marker.arrow:Show()
   else
    marker.arrow:Hide()
   end
   marker:Show()
  else marker:Hide() end
 end
 for i=#units+1,#markers do markers[i]:Hide() end
end
local function attach()
 local world=WorldMapFrame
 if provider or not world or not world.AddDataProvider or not world.GetCanvas
  or not MapCanvasDataProviderMixin or not CreateFromMixins then return end
 map=world
 provider=CreateFromMixins(MapCanvasDataProviderMixin)
 provider.RefreshAllData=P.Refresh
 provider.OnMapChanged=P.Refresh
 provider.OnCanvasSizeChanged=P.Refresh
 provider.OnCanvasScaleChanged=P.Refresh
 provider.OnHide=function() for _,marker in ipairs(markers) do marker:Hide() end end
 provider.RemoveAllData=provider.OnHide
 world:AddDataProvider(provider)
 P.Refresh()
end
local events=CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("GROUP_ROSTER_UPDATE")
events:SetScript("OnEvent",function(_,event,name)
 if event=="ADDON_LOADED" and name~="Blizzard_WorldMap" then return end
 attach()
 P.Refresh()
end)
events:SetScript("OnUpdate",function(self,elapsed)
 self.elapsed=(self.elapsed or 0)+elapsed
 if self.elapsed>=.2 then self.elapsed=0;P.Refresh() end
end)
