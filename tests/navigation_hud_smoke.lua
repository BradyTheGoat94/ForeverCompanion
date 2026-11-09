-- Navigation remains a player-selected bearing, with persistent HUD controls.
local objects={}
local methods={}
local function obj()
 local o=setmetatable({},{__index=function(_,key) return methods[key] or function() end end})
 objects[#objects+1]=o;return o
end
function methods:SetScript(key,fn) self[key]=fn end
function methods:SetText(text) self.text=text end
function methods:SetPoint(...) self.point={...} end
function methods:SetScale(scale) self.scale=scale end
function methods:CreateTexture() return obj() end
function methods:CreateFontString() return obj() end
function methods:Show() self.shown=true end
function methods:Hide() self.shown=false end
function methods:GetCenter() return 650,420 end
function methods:StartMoving() self.moving=true end
function methods:StopMovingOrSizing() self.moving=false end
UIParent=obj();UIParent.GetCenter=function() return 500,400 end
CreateFrame=function(_,name) local o=obj();if name then _G[name]=o end;return o end
ForeverCompanionDB={}
local menu
ForeverCompanionInterface={Button=function() return obj() end,Menu=function(_,_,entries) menu=entries end}
ForeverCompanionVisualTheme={Font=function() end}
local position={GetXY=function() return 0,0 end}
C_Map={GetBestMapForUnit=function() return 1 end,GetPlayerMapPosition=function() return position end,
 GetWorldPosFromMapPos=function(_,p) return 1,p end}
CreateVector2D=function(x,y) return {GetXY=function() return x*1000,y*1000 end} end
GetPlayerFacing=function() return 0 end
dofile('ForeverCompanion/QuestDirection.lua')
local d=ForeverCompanionQuestDirection
assert(d.Start({map=1,x=.5,y=.2},'Live destination'))
local frame=ForeverCompanionDirectionFrame
assert(frame and frame.shown and d.IsActive())
frame.dragHandle.OnDragStart();assert(frame.moving)
frame.dragHandle.OnDragStop()
assert(ForeverCompanionDB.questDirection.position.x==150 and ForeverCompanionDB.questDirection.position.y==20)
d.OpenOptions();menu[1].action();assert(ForeverCompanionDB.questDirection.locked)
frame.dragHandle.OnDragStart();assert(not frame.moving,'locked arrow cannot start moving')
d.OpenOptions();menu[4].action();assert(frame.scale==1.2,'large arrow changes HUD scale')
position=nil;frame.OnUpdate(frame,.2)
local unavailable=false
for _,o in ipairs(objects) do if o.text=='Direction unavailable here' then unavailable=true end end
assert(unavailable,'lost player position reports unavailable direction without stale bearing')
assert(d.Stop() and not frame.shown and not d.IsActive())
assert(not d.Start({map=1,x=2,y=.1}),'invalid coordinates cannot start navigation')
d.ResetPosition();assert(ForeverCompanionDB.questDirection.position==nil and frame.point[1]=='TOP')
print('PASS: navigation HUD drag, lock, scale, missing position, stop and reset')
