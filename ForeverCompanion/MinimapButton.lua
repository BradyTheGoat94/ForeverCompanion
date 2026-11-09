-- Standalone launcher; no broker/minimap library or map replacement required.
local M={};ForeverCompanionMinimapButton=M
local button,dragging,suppressClick
local function finite(n) return not(issecretvalue and issecretvalue(n)) and type(n)=='number' and n==n and math.abs(n)<math.huge end
local function prefs()
 ForeverCompanionDB=ForeverCompanionDB or {}
 if type(ForeverCompanionDB.minimapButton)~='table' then ForeverCompanionDB.minimapButton={} end
 local p=ForeverCompanionDB.minimapButton
 if not finite(p.angle) then p.angle=math.rad(225) end
 return p
end
function M.Offset(angle,width,height)
 if not finite(angle) or not finite(width) or not finite(height) or width<=0 or height<=0 then return end
 return math.cos(angle)*(width/2+8),math.sin(angle)*(height/2+8)
end
function M.Refresh()
 if not button then return end
 local p=prefs();local x,y=M.Offset(p.angle,Minimap:GetWidth(),Minimap:GetHeight())
 if not x or p.hidden then button:Hide();return end
 button:ClearAllPoints();button:SetPoint('CENTER',Minimap,'CENTER',x,y);button:Show()
end
local function drag()
 if not dragging or not GetCursorPosition or not math.atan2 then return end
 local x,y=GetCursorPosition();local cx,cy=Minimap:GetCenter();local scale=Minimap:GetEffectiveScale()
 if not finite(x) or not finite(y) or not finite(cx) or not finite(cy) or not finite(scale) or scale<=0 then return end
 -- Cursor coordinates are physical pixels; the center uses minimap units.
 x,y=x/scale-cx,y/scale-cy
 if x==0 and y==0 then return end
 prefs().angle=math.atan2(y,x);M.Refresh()
end
function M.Create()
 if button or not Minimap or not CreateFrame then return end
 button=CreateFrame('Button','ForeverCompanionMinimapLauncher',Minimap)
 button:SetSize(32,32);button:SetFrameStrata('MEDIUM');button:SetFrameLevel(Minimap:GetFrameLevel()+10)
 button:RegisterForClicks('LeftButtonUp','RightButtonUp');button:RegisterForDrag('LeftButton')
 local icon=button:CreateTexture(nil,'ARTWORK');icon:SetSize(24,24);icon:SetPoint('CENTER',0,0);icon:SetTexture('Interface\\AddOns\\ForeverCompanion\\Media\\Crest')
 local border=button:CreateTexture(nil,'OVERLAY');border:SetSize(54,54);border:SetPoint('TOPLEFT',0,0);border:SetTexture('Interface\\Minimap\\MiniMap-TrackingBorder')
 button:SetHighlightTexture('Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight','ADD')
 button:SetScript('OnMouseDown',function() if not dragging then suppressClick=false end end)
 button:SetScript('OnClick',function(_,key)
  if suppressClick then suppressClick=false;return end
  if key=='RightButton' then
   ForeverCompanionInterface.Menu(button,"FOREVER COMPANION",{
    {label='Open / close addon',action=function() SlashCmdList.FOREVERCOMPANION('') end},
    {label='Training Guide',action=function() ForeverCompanionTraining.Toggle() end},
    {label='Map companion',action=function() ForeverCompanionMapHub.Open() end},
    {label='Toggle transparent map',action=function() ForeverCompanionMapOverlay.Toggle() end},
    {label='Hide minimap button',action=function() M.SetHidden(true) end},
    {label='Reset button position',action=M.Reset},
   })
  elseif SlashCmdList and SlashCmdList.FOREVERCOMPANION then SlashCmdList.FOREVERCOMPANION('') end
 end)
 button:SetScript('OnDragStart',function()
  dragging=true;suppressClick=true
  if GameTooltip then GameTooltip:Hide() end
  button:SetScript('OnUpdate',drag);drag()
 end)
 button:SetScript('OnDragStop',function()
  drag();dragging=false;button:SetScript('OnUpdate',nil)
  -- The release click is suppressed; the next mouse press clears the flag.
 end)
 button:SetScript('OnHide',function() dragging=false;suppressClick=false;button:SetScript('OnUpdate',nil) end)
 button:SetScript('OnEnter',function(self)
  if GameTooltip then GameTooltip:SetOwner(self,'ANCHOR_LEFT');GameTooltip:SetText("Brady's Forever Companion");GameTooltip:AddLine('Left-click: open / close addon\nRight-click: options\nDrag: move around the minimap',.85,.88,.92,true);GameTooltip:Show() end
 end)
 button:SetScript('OnLeave',function() if GameTooltip then GameTooltip:Hide() end end)
 if Minimap.HookScript then Minimap:HookScript('OnSizeChanged',M.Refresh) end
 M.Refresh()
end
function M.SetHidden(value) prefs().hidden=value==true;M.Create();M.Refresh() end
function M.Reset() prefs().angle=math.rad(225);M.SetHidden(false) end
local events=CreateFrame('Frame')
for _,event in ipairs({'PLAYER_ENTERING_WORLD','ADDON_LOADED','UI_SCALE_CHANGED'}) do events:RegisterEvent(event) end
events:SetScript('OnEvent',function() M.Create();M.Refresh() end)
