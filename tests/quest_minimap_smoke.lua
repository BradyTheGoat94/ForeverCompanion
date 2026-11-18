local objects={};local methods={}
local function object() local o=setmetatable({elapsed=0},{__index=function(_,key) return methods[key] or function() end end});objects[#objects+1]=o;return o end
function methods:SetScript(k,v) self[k]=v end
function methods:CreateTexture() return object() end
function methods:Show() self.shown=true end
function methods:Hide() self.shown=false end
function methods:IsShown() return self.shown==true end
function methods:GetFrameLevel() return 1 end
function methods:SetPoint(...) self.point={...} end
function methods:GetWidth() return 100 end
function methods:GetHeight() return 100 end
function methods:GetViewRadius() return 100 end
CreateFrame=function(_,name,parent) local o=object();o.parent=parent;return o end
ForeverCompanionInterface={Text=function() return object() end}
Minimap=object();Minimap.shown=true
local rotating=false;GetCVar=function() return rotating and '1' or '0' end;GetPlayerFacing=function() return math.pi/2 end
CreateVector2D=function(x,y) return {GetXY=function() return x,y end} end
local playerMap=1
C_Map={GetBestMapForUnit=function() return playerMap end,GetPlayerMapPosition=function() return CreateVector2D(.5,.5) end,
 GetWorldPosFromMapPos=function(map,v) local x,y=v:GetXY();return map,CreateVector2D(y*1000,x*1000) end}
local q={id=10,title='Synthetic quest',objectiveStates={{known=true,done=false}}}
local supported=true;local targets={{map=1,x=.51,y=.52,objectiveIndex=1,reference=true}}
ForeverCompanionQuestPlanner={IsSupported=function() return supported end,GetSelected=function() return q end,GetLive=function() return {q} end,Select=function() end}
local navigated=0;local resolved=true
ForeverCompanionQuestWaypoints={Targets=function() return targets end,ResolveActiveEntry=function() if resolved then return q,1,targets[1] end end,Navigate=function() navigated=navigated+1;return 'Synthetic directions' end}
dofile('ForeverCompanion/QuestMinimap.lua')
local M=ForeverCompanionQuestMinimap
assert(M.Project(100,0,100,100,100,0)==nil,'off-range points are hidden, not pinned to a false edge')
local x,y=M.Project(20,10,100,100,100,0);assert(x==-5 and y==10)
x,y=M.Project(20,10,100,100,100,math.pi/2);assert(math.abs(x-10)<.00001 and math.abs(y-5)<.00001)
assert(not M.Project(0/0,0,100,100,100,0))
M.Refresh();local pin
for _,o in ipairs(objects) do if type(rawget(o,'entry'))=='table' then pin=o end end
assert(pin and pin.shown and pin.point[4]==-5 and pin.point[5]==10)
pin.OnClick(pin,'LeftButton');assert(navigated==1)
resolved=false;pin.OnClick(pin,'LeftButton');assert(navigated==1,'stale marker action cannot start directions')
rotating=true;M.UpdatePositions();assert(math.abs(pin.point[4]-10)<.00001)
supported=false;M.Refresh();assert(not pin.shown and M.Status():find('unavailable',1,true))
supported=true;playerMap=2;M.Refresh();assert(not pin.shown,'different world-space regions cannot project onto the minimap')
playerMap=1;local radius=Minimap.GetViewRadius;Minimap.GetViewRadius=false;M.Refresh();assert(not pin.shown and M.Status():find('radius unavailable',1,true))
Minimap.GetViewRadius=radius;q.objectiveStates[1].done=true;M.Refresh();assert(not pin.shown,'completed objective points disappear')
q.objectiveStates[1].done=false;M.SetEnabled(false);assert(M.Status()=='Off' and not pin.shown)
print('PASS: native minimap projection, rotation, bounds, unavailable APIs, completed objectives and stale action guards')

ForeverCompanionServiceAtlas={Icon=function() return 'Mailbox' end}
ForeverCompanionTownServices={ForMap=function() return {{symbol='M',map=1,x=.51,y=.52,label='Mailbox'}} end}
supported=false;M.SetEnabled(true);M.Refresh()
assert(pin.shown and pin.entry.mailbox and pin.entry.target.label=='Mailbox')
ForeverCompanionDB.questMapHiddenServices={M=true};M.Refresh();assert(pin.shown,'world map filter is independent of minimap')

ForeverCompanionDB.questMapHiddenServices={}
M.SetEnabled(false);assert(pin.shown and pin.entry.mailbox)
M.SetMailEnabled(false);assert(not pin.shown and M.Status()=='Off')
M.SetMailEnabled(true);assert(pin.shown and pin.entry.mailbox)
