-- Standalone party markers on the Blizzard world map.
-- Uses only Blizzard unit/map APIs; never replaces native minimap party blips.
local P={}
ForeverCompanionPartyMap=P
local markers={}
local provider,map
local function finite(n)
 return not (issecretvalue and issecretvalue(n)) and type(n)=='number' and n==n and math.abs(n)<math.huge
end
local function validNumber(n)
 if issecretvalue and issecretvalue(n) then return false end
 return type(n)=="number" and n==n and n>=0 and n<=1
end
local function isOtherMember(unit)
 if not UnitExists then return false end
 local ok,exists=pcall(UnitExists,unit)
 if not ok or (issecretvalue and issecretvalue(exists)) or exists~=true then return false end
 if UnitIsUnit then
  local readable,same=pcall(UnitIsUnit,unit,"player")
  if not readable or (issecretvalue and issecretvalue(same)) or same==true then return false end
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

local highlighted
local function public(v) return not (issecretvalue and issecretvalue(v)) end
local function read(fn,...)
 if type(fn)~="function" then return end
 local ok,a,b=pcall(fn,...)
 if ok then return a,b end
end
local function readableText(value)
 if public(value) and type(value)=="string" and value~="" then return value end
end
function P.MemberName(unit)
 local name,realm=read(UnitFullName,unit)
 name=readableText(name) or readableText(read(UnitName,unit))
 realm=readableText(realm)
 return name and (realm and (name.."-"..realm) or name) or unit
end
local function identity(unit)
 local guid=readableText(read(UnitGUID,unit))
 if guid then return guid end
 local name,realm=read(UnitFullName,unit)
 name,realm=readableText(name),readableText(realm)
 if name then
  realm=realm or readableText(read(GetNormalizedRealmName))
  if realm then return name.."-"..realm end
 end
end
function P.IsHighlighted(unit)
 return highlighted~=nil and identity(unit)==highlighted
end
function P.HighlightedUnit()
 if not highlighted then return end
 for _,unit in ipairs(partyUnits()) do if P.IsHighlighted(unit) then return unit end end
end
function P.Highlight(unit)
 local member
 if unit then
  for _,other in ipairs(partyUnits()) do
   if other==unit then member=identity(unit);break end
  end
  if not member then return false end
 end
 if highlighted==member then highlighted=nil else highlighted=member end
 P.Refresh()
 if ForeverCompanionDungeonMaps and ForeverCompanionDungeonMaps.RefreshParty then
  ForeverCompanionDungeonMaps.RefreshParty()
 end
 if ForeverCompanionPartyMinimap then ForeverCompanionPartyMinimap.Refresh() end
 if ForeverCompanionMapOverlay and ForeverCompanionMapOverlay.RefreshParty then ForeverCompanionMapOverlay.RefreshParty() end
 return true
end
function P.Point(mapID,unit)
 if not finite(mapID) or mapID<=0 or not C_Map then return end
 local position=read(C_Map.GetPlayerMapPosition,mapID,unit)
 if not public(position) or (type(position)~="table" and type(position)~="userdata") then return end
 local x,y=read(position.GetXY,position)
 if validNumber(x) and validNumber(y) and (x~=0 or y~=0) then return x,y end
end
function P.Menu(anchor,mapID)
 local entries={}
 if highlighted then entries[#entries+1]={label="Clear highlight",action=function() P.Highlight(nil) end} end
 for _,unit in ipairs(partyUnits()) do
  local member=unit
  local memberKey=identity(member)
  local suffix=mapID and (P.Point(mapID,member) and "" or "  |  Position unavailable on this map") or ""
  entries[#entries+1]={label=P.MemberName(member)..suffix,enabled=memberKey~=nil,selected=memberKey~=nil and memberKey==highlighted,action=function()
   -- Roster slots can be reassigned while the pop-up menu is open.
   if identity(member)==memberKey then P.Highlight(member) end
  end}
 end
 if #entries==0 then entries[1]={label="No party members",enabled=false} end
 ForeverCompanionInterface.PagedMenu(anchor,"HIGHLIGHT A PARTY MEMBER",entries,nil,340)
end

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
 local halo=marker:CreateTexture(nil,"BACKGROUND",nil,1)
 halo:SetSize(33,33)
 halo:SetPoint("CENTER")
 halo:SetColorTexture(1,.65,.15,.95)
 if halo.SetRotation then halo:SetRotation(math.pi/4) end
 halo:Hide();marker.fcPartyHalo=halo
 return marker
end
function P.StyleHighlight(marker,unit)
 local active=P.IsHighlighted(unit)
 marker.fcPartyHalo:SetShown(active)
 marker:SetSize(active and 34 or 28,active and 34 or 28)
 return active
end
function P.CreateMarker(canvas)
 local button=CreateFrame("Button",nil,canvas)
 button.fcCanvas=canvas
 button:SetFrameLevel(canvas:GetFrameLevel()+125)
 P.StyleMarker(button)
 button:SetScript("OnEnter",function(self)
  if GameTooltip and self.unit then
   GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
   GameTooltip:SetText(P.MemberName(self.unit))
   GameTooltip:AddLine("Party member · world map",.65,.87,1)
   GameTooltip:AddLine("Click to toggle highlight",.98,.76,.39)
   GameTooltip:Show()
  end
 end)
 button:SetScript("OnClick",function(self) if self.unit then P.Highlight(self.unit) end end)
 button:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
 return button
end
local function hideMarkers()
 for _,marker in ipairs(markers) do marker:Hide() end
end
function P.Refresh()
 local db=ForeverCompanionDB
 if db and (db.hideCompanionWorldMap or db.hideWorldPartyPins) then hideMarkers();return end
 if not map or not map.IsShown or not map:IsShown() then hideMarkers();return end
 local canvas=map:GetCanvas()
 local mapID=map:GetMapID()
 if not canvas or not finite(mapID) then hideMarkers();return end
 local width,height=canvas:GetWidth(),canvas:GetHeight()
 if not finite(width) or not finite(height) or width<=0 or height<=0 then hideMarkers();return end
 local scale=canvas.GetScale and canvas:GetScale() or 1
 if issecretvalue and issecretvalue(scale) then hideMarkers();return end
 if not finite(scale) or scale<=0 then scale=1 end
 local units=partyUnits()
 for i,unit in ipairs(units) do
  local marker=markers[i]
  if not marker or marker.fcCanvas~=canvas then
   if marker then marker:Hide() end
   marker=P.CreateMarker(canvas);markers[i]=marker
  end
  marker.unit=unit
  local x,y=P.Point(mapID,unit)
  if x then
   local active=P.StyleHighlight(marker,unit)
   marker:SetFrameLevel(canvas:GetFrameLevel()+(active and 135 or 125))
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
 provider.OnHide=hideMarkers
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
 if event=="GROUP_ROSTER_UPDATE" and highlighted and not P.HighlightedUnit() then P.Highlight(nil) end
 attach()
 P.Refresh()
end)
events:SetScript("OnUpdate",function(self,elapsed)
 self.elapsed=(self.elapsed or 0)+elapsed
 if self.elapsed>=.2 then self.elapsed=0;P.Refresh() end
end)
