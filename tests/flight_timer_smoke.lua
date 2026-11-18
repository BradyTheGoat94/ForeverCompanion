local now,onTaxi=0,false
local frame,strings,hooked=nil,{},{}
local function noop() end
local function widget()
 return setmetatable({}, {__index=function(_,key)
  if key=='SetScript' then return function(self,name,fn) self[name]=fn or false end end
  if key=='SetText' then return function(self,value) self.caption=value end end
  if key=='CreateTexture' then return widget end
  return noop
 end})
end
CreateFrame=function() local result=widget();frame=frame or result;return result end
ForeverCompanionInterface={
 Surface=noop,CloseButton=noop,palette={},
 Text=function() local t=widget();strings[#strings+1]=t;return t end,
}
GetTime=function() return now end
UnitOnTaxi=function() return onTaxi end
TakeTaxiNode=noop
TaxiRequestEarlyLanding=noop
FlightMap_FlightPointPinMixin={OnMouseEnter=noop}
FlightMapFrame={GetMapID=function() return 947 end}
C_TaxiMap={GetAllTaxiNodes=function(map)
 assert(map==947)
 return {{state=0,nodeID=1,name='Origin'},{state=1,nodeID=2,slotIndex=4,name='Destination'}}
end}
hooksecurefunc=function(target,method,fn)
 if type(target)=='string' then hooked[target]=method else hooked[method]=fn end
end
local hint
GameTooltip={AddLine=function(_,value) hint=value end,Show=noop}
dofile('ForeverCompanion/FlightTimer.lua')
local function open()
 frame.OnEvent(frame,'TAXIMAP_OPENED')
 hooked.OnMouseEnter({taxiNodeData={slotIndex=4}})
end
local function tick(time)
 now=time
 frame.OnUpdate(frame,.25)
end
open();assert(hint:find('first trip',1,true))
hooked.TakeTaxiNode(4)
onTaxi=true;tick(1)
assert(strings[2].caption:find('Learning route',1,true))
onTaxi=false;tick(91)
assert(not frame.OnUpdate)
local key,duration=next(ForeverCompanionFlightDB.routes)
assert(key and duration==90)
open();assert(hint:find('1:30',1,true))
hooked.TakeTaxiNode(4)
onTaxi=true;tick(92);tick(122)
assert(strings[2].caption:find('1:00 remaining',1,true))
hooked.TaxiRequestEarlyLanding()
onTaxi=false;tick(123)
assert(ForeverCompanionFlightDB.routes[key]==90)
open();hooked.TakeTaxiNode(4);tick(140)
assert(not frame.OnUpdate and ForeverCompanionFlightDB.routes[key]==90)
print('PASS: route previews, elapsed time, countdown, landing, early landing and canceled flight')
