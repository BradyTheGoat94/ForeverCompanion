local marker,active,allowArrow,allowPin=nil,nil,true,false
local clears,stops,starts=0,0,0
ForeverCompanionQuestDirection={Start=function(p) starts=starts+1;if allowArrow then active=p;return true end;return false end,
 Stop=function() stops=stops+1;active=nil end,IsActive=function() return active~=nil end}
UiMapPoint={CreateFromCoordinates=function(map,x,y) return {uiMapID=map,position={GetXY=function() return x,y end}} end}
C_Map={CanSetUserWaypointOnMap=function() return allowPin end,SetUserWaypoint=function(p) marker=p end,
 GetUserWaypoint=function() return marker end,ClearUserWaypoint=function() clears=clears+1;marker=nil end}
dofile('ForeverCompanion/QuestWaypoints.lua');local w=ForeverCompanionQuestWaypoints
local a={map=12,x=.2,y=.3};local b={map=12,x=.4,y=.5};local c={map=12,x=.6,y=.7}
assert(w.Navigate(a,false)=='On-screen arrow active' and active==a)
local before=starts;assert(w.Navigate({map=12,x=0/0,y=.3},false):find('valid'));assert(starts==before and active==a,'invalid input cannot replace or stop navigation')
allowArrow=false;assert(w.Navigate(b,false):find('previous navigation') and active==a and stops==0,'failed handoff preserves the old arrow')
allowPin=true;w.Navigate(b,false);assert(not active and marker.uiMapID==12 and stops==1,'successful native-only navigation stops the obsolete custom arrow')
allowPin=false;allowArrow=true;w.Navigate(c,false);assert(active==c and not marker and clears==1,'successful custom-only navigation clears only its obsolete owned pin')
marker=UiMapPoint.CreateFromCoordinates(12,.9,.9);local foreign=marker
w.Navigate(a,false);assert(marker==foreign and clears==1,'a waypoint placed by the player is never cleared')
allowArrow=false;w.Navigate(b,false);assert(marker==foreign and active==a,'failed navigation preserves both existing destinations')
local secret={};issecretvalue=function(v) return v==secret end
before=starts;w.Navigate({map=secret,x=.5,y=.5},false);assert(starts==before,'private-like values fail validation before API access')
issecretvalue=nil
dofile('ForeverCompanion/InterfaceKit.lua');local u=ForeverCompanionInterface
assert(u.PanelScale(700,650,1000,700)==1)
assert(math.abs(u.PanelScale(700,650,500,400)-368/650)<.00001,'panels fit smaller viewports without changing their logical layout')
assert(u.PanelScale(700,650,0/0,400)==1 and u.PanelScale(0,650,500,400)==1,'invalid dimensions leave scale unchanged')
print('PASS: navigation handoff, failed replacement preservation, waypoint ownership, private-like inputs and responsive panel sizing')
