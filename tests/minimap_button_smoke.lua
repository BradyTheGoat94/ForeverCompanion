local named,events={},{}
local methods={}
local function obj() return setmetatable({shown=true},{__index=methods}) end
function methods:SetScript(k,f) self[k]=f end
function methods:Show() self.shown=true end;function methods:Hide() self.shown=false;if self.OnHide then self.OnHide() end end
function methods:SetPoint(...) self.point={...} end
function methods:CreateTexture() return obj() end
function methods:GetWidth() return 140 end;function methods:GetHeight() return 140 end
function methods:GetCenter() return 100,100 end;function methods:GetEffectiveScale() return 2 end
function methods:GetFrameLevel() return 1 end
function methods:HookScript(k,f) self[k]=f end
for _,k in ipairs({'SetSize','SetFrameStrata','SetFrameLevel','RegisterForClicks','RegisterForDrag','SetTexture','SetHighlightTexture','RegisterEvent','ClearAllPoints'}) do methods[k]=function() end end
CreateFrame=function(_,name) local o=obj();events[#events+1]=o;if name then named[name]=o end;return o end
ForeverCompanionDB={};Minimap=obj()
local toggles,menu=0,nil
SlashCmdList={FOREVERCOMPANION=function(s) assert(s=='');toggles=toggles+1 end}
ForeverCompanionInterface={Menu=function(_,_,entries) menu=entries end}
GetCursorPosition=function() return 400,200 end
dofile('ForeverCompanion/MinimapButton.lua');local m=ForeverCompanionMinimapButton
m.Create();local b=named.ForeverCompanionMinimapLauncher;assert(b and b.shown)
local x,y=m.Offset(0,140,140);assert(x==78 and y==0)
assert(not m.Offset(0/0,140,140) and not m.Offset(0,0,140))
b.OnClick(b,'LeftButton');assert(toggles==1,'left click opens the main addon')
b.OnClick(b,'RightButton');assert(menu and menu[1].label=='Open / close addon')
b.OnDragStart();assert(b.OnUpdate and ForeverCompanionDB.minimapButton.angle==0,'drag converts physical cursor coordinates using the minimap scale')
b.OnDragStop();assert(not b.OnUpdate,'drag updates stop on release')
b.OnClick(b,'LeftButton');assert(toggles==1,'the drag release cannot toggle the addon')
b.OnMouseDown()
b.OnClick(b,'LeftButton');assert(toggles==2,'normal clicking resumes after the drag')
m.SetHidden(true);assert(not b.shown and ForeverCompanionDB.minimapButton.hidden)
m.SetHidden(false);assert(b.shown and not ForeverCompanionDB.minimapButton.hidden)
m.Reset();assert(math.abs(ForeverCompanionDB.minimapButton.angle-math.rad(225))<.00001)
local count=#events;m.Create();assert(#events==count,'events do not duplicate the launcher')
print('PASS: minimap launcher toggles, menu, geometry, scaled dragging, visibility persistence and idle teardown')
