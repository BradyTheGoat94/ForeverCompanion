-- Standalone party markers on the Blizzard world map.
-- Uses only Blizzard unit/map APIs; never replaces native minimap party blips.
local P={}
ForeverCompanionPartyMap=P
local markers={}
local provider,map
local function validNumber(n)
 return type(n)=="number" and n==n and n>=0 and n<=1
end
local function partyUnits()
 local units={}
 if IsInRaid and IsInRaid() then
  for i=1,40 do
   local unit="raid"..i
   if UnitExists and UnitExists(unit) then units[#units+1]=unit end
  end
 else
  for i=1,4 do
   local unit="party"..i
   if UnitExists and UnitExists(unit) then units[#units+1]=unit end
  end
 end
 return units
end
P.PartyUnits=partyUnits
local function makeMarker(canvas)
 local button=CreateFrame("Button",nil,canvas)
 button:SetSize(24,24)
 button:SetFrameLevel(canvas:GetFrameLevel()+125)
 local halo=button:CreateTexture(nil,"BACKGROUND")
 halo:SetAllPoints(button)
 halo:SetColorTexture(.015,.05,.08,.92)
 local dot=button:CreateTexture(nil,"ARTWORK")
 dot:SetPoint("CENTER")
 dot:SetSize(18,18)
 dot:SetColorTexture(.20,.75,1,.96)
 button.dot=dot
 local arrow=button:CreateTexture(nil,"OVERLAY")
 arrow:SetSize(17,17)
 arrow:SetPoint("CENTER",button,"CENTER",0,0)
 arrow:SetTexture("Interface\\Minimap\\MinimapArrow")
 arrow:SetVertexColor(.25,.95,1,1)
 button.arrow=arrow
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
   if type(facing)=="number" and facing==facing and marker.arrow.SetRotation then
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
