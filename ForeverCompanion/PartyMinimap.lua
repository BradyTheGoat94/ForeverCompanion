-- Optional standalone minimap party overlay. No replacement of Blizzard blips.
-- Requires a native view-radius API and world-space unit coordinates; if either
-- is unavailable, the Blizzard minimap retains its normal party indicators.
local M={}
ForeverCompanionPartyMinimap=M
local markers={}
local function finite(n)
 return type(n)=="number" and n==n and n~=math.huge and n~=-math.huge
end
local function units()
 local party=ForeverCompanionPartyMap
 return party and party.PartyUnits and party.PartyUnits() or {}
end
local function position(unit)
 if type(UnitPosition)~="function" then return end
 local ok,x,y,z,instance=pcall(UnitPosition,unit)
 if ok and finite(x) and finite(y) then return x,y,instance end
end
local function facing(unit)
 if type(UnitFacing)~="function" then return end
 local ok,value=pcall(UnitFacing,unit)
 if ok and not (issecretvalue and issecretvalue(value)) and finite(value) then return value end
end
local function makeMarker(parent)
 local marker=CreateFrame("Frame",nil,parent)
 marker:SetSize(24,24)
 marker:SetFrameStrata("HIGH")
 marker:SetFrameLevel(parent:GetFrameLevel()+10)
 marker:EnableMouse(false)
 local bg=marker:CreateTexture(nil,"ARTWORK")
 bg:SetAllPoints(marker)
 bg:SetColorTexture(.02,.08,.13,.85)
 local dot=marker:CreateTexture(nil,"OVERLAY")
 dot:SetSize(15,15)
 dot:SetPoint("CENTER")
 dot:SetColorTexture(.20,.75,1,.98)
 local arrow=marker:CreateTexture(nil,"OVERLAY")
 arrow:SetSize(17,17)
 arrow:SetPoint("CENTER")
 arrow:SetTexture("Interface\\Minimap\\MinimapArrow")
 arrow:SetVertexColor(.25,.95,1,1)
 marker.arrow=arrow
 return marker
end
local function hideAll()
 for _,marker in ipairs(markers) do marker:Hide() end
end
M.Hide=hideAll
function M.Refresh()
 local minimap=Minimap
 if not minimap or not minimap.IsShown or not minimap:IsShown()
  or type(minimap.GetViewRadius)~="function" then hideAll();return end
 local ok,radius=pcall(minimap.GetViewRadius,minimap)
 if not ok or not finite(radius) or radius<=0 then hideAll();return end
 local px,py,instance=position("player")
 if not px then hideAll();return end
 local width,height=minimap:GetWidth(),minimap:GetHeight()
 if not finite(width) or not finite(height) or width<=0 or height<=0 then hideAll();return end
 local rotate=GetCVar and GetCVar("rotateMinimap")=="1"
 local playerFacing=rotate and facing("player") or 0
 if rotate and not playerFacing then hideAll();return end
 local shown=0
 for _,unit in ipairs(units()) do
  local x,y,unitInstance=position(unit)
  if x and unitInstance==instance then
   local dx,dy=x-px,y-py
   -- UnitPosition axes are world-space east/north; rotate with the native map.
   if rotate then
    local c,s=math.cos(playerFacing),math.sin(playerFacing)
    dx,dy=dx*c-dy*s,dx*s+dy*c
   end
   local ox,oy=dx/radius*width/2,dy/radius*height/2
   local nx,ny=ox/(width/2),oy/(height/2)
   -- Hide out-of-range markers; never clamp a distant member to a false edge.
   if nx*nx+ny*ny<=.81 then
    shown=shown+1
    local marker=markers[shown]
    if not marker then marker=makeMarker(minimap);markers[shown]=marker end
    marker:ClearAllPoints()
    marker:SetPoint("CENTER",minimap,"CENTER",ox,oy)
    local direction=facing(unit)
    if direction and marker.arrow.SetRotation then
     marker.arrow:SetRotation(-(direction-(rotate and playerFacing or 0)))
     marker.arrow:Show()
    else marker.arrow:Hide() end
    marker:Show()
   end
  end
 end
 for i=shown+1,#markers do markers[i]:Hide() end
end
local watcher=CreateFrame("Frame")
watcher:RegisterEvent("PLAYER_ENTERING_WORLD")
watcher:RegisterEvent("GROUP_ROSTER_UPDATE")
watcher:SetScript("OnEvent",M.Refresh)
watcher:SetScript("OnUpdate",function(self,elapsed)
 self.elapsed=(self.elapsed or 0)+elapsed
 if self.elapsed>=.2 then self.elapsed=0;M.Refresh() end
end)
