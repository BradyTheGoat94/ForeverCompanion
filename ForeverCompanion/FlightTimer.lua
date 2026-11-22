-- Observe flight selection and status. All travel stays under Blizzard's controls.
local F={}
ForeverCompanionFlightTimer=F
local origin,nodes,pending,flight
local panel,title,detail,bar
local elapsed=0
local installed={}
local interrupted=false
local function read(fn,...)
 if type(fn)~='function' then return end
 local ok,value=pcall(fn,...)
 if ok and not (issecretvalue and issecretvalue(value)) then return value end
end
local function settings()
 if type(ForeverCompanionFlightDB)~='table' then ForeverCompanionFlightDB={} end
 local db=ForeverCompanionFlightDB
 if type(db.routes)~='table' then db.routes={} end
 return db
end
local function keyFor(node)
 if type(node.nodeID)=='number' and node.nodeID>0 then return 'id:'..node.nodeID end
 if type(node.name)=='string' and node.name~='' then return 'name:'..node.name end
end
local function routeKey(from,to)
 local a,b=from and keyFor(from),to and keyFor(to)
 if a and b and a~=b then return #a..':'..a..b end
end
local function estimate(key)
 local t=key and settings().routes[key]
 if type(t)=='number' and t>=5 and t<=3600 then return t end
end
local function clock(seconds)
 local rounded=math.max(0,math.ceil(seconds))
 return ('%d:%02d'):format(math.floor(rounded/60),rounded%60)
end
local function readMap(mapID)
 local current,reachable=0,1
 local state=Enum and Enum.FlightPathState
 if state then current,reachable=state.Current,state.Reachable end
 local list=type(mapID)=='number' and C_TaxiMap and read(C_TaxiMap.GetAllTaxiNodes,mapID)
 local source,found
 if type(list)=='table' then
  found={}
  for _,node in ipairs(list) do
   if node.state==current then source=node end
   if node.state==reachable and type(node.slotIndex)=='number' then found[node.slotIndex]=node end
  end
  if source and next(found) then return source,found end
 end
 found={}
 local count=read(NumTaxiNodes)
 if type(count)~='number' then return nil,found end
 source=nil
 for slot=1,count do
  local kind,name=read(TaxiNodeGetType,slot),read(TaxiNodeName,slot)
  if type(name)=='string' and name~='' then
   if kind=='CURRENT' then source={name=name}
   elseif kind=='REACHABLE' then found[slot]={name=name} end
  end
 end
 return source,found
end
local function refreshMap()
 local mapID=FlightMapFrame and read(FlightMapFrame.GetMapID,FlightMapFrame)
 origin,nodes=readMap(mapID)
end
local function tooltip(slot)
 if settings().hidden or not GameTooltip or not nodes then return end
 local key=routeKey(origin,nodes[slot])
 if not key then return end
 local duration=estimate(key)
 GameTooltip:AddLine(duration and ('Flight time  ~'..clock(duration)) or 'Flight time  Learns after your first trip',.53,.88,.81)
 GameTooltip:Show()
end
local function showTimer()
 if panel then return end
 local U=ForeverCompanionInterface
 panel=CreateFrame('Frame','ForeverCompanionFlightTimerFrame',UIParent,'BackdropTemplate')
 panel:SetSize(278,82);panel:SetPoint('TOP',UIParent,'TOP',0,-154)
 panel:SetFrameStrata('MEDIUM');U.Surface(panel)
 U.CloseButton(panel,function() settings().hidden=true;panel:Hide() end)
 title=U.Text(panel,13,U.palette.accent);title:SetPoint('TOPLEFT',12,-7);title:SetWidth(226)
 detail=U.Text(panel,14);detail:SetPoint('TOPLEFT',12,-31);detail:SetWidth(254)
 local track=panel:CreateTexture(nil,'ARTWORK')
 track:SetPoint('BOTTOMLEFT',12,10);track:SetSize(254,5);track:SetColorTexture(.18,.25,.27,1)
 bar=CreateFrame('StatusBar',nil,panel)
 bar:SetPoint('BOTTOMLEFT',12,10);bar:SetSize(254,5)
 bar:SetStatusBarTexture('Interface\\Buttons\\WHITE8X8');bar:SetStatusBarColor(.43,.85,.75)
 bar:SetMinMaxValues(0,1)
end
local function render(now)
 if not flight or settings().hidden then if panel then panel:Hide() end;return end
 showTimer()
 title:SetText(flight.name and ('To '..flight.name) or 'Flight path')
 local time=now-flight.start
 local duration=flight.estimate
 if duration and duration>time then
  detail:SetText('~'..clock(duration-time)..' remaining  |  ~'..clock(duration)..' total')
 elseif duration then
  detail:SetText(clock(time)..' elapsed  |  Past estimate')
 else
  detail:SetText(clock(time)..' elapsed  |  '..(flight.key and 'Learning route' or 'Flight in progress'))
 end
 bar:SetShown(duration~=nil)
 if duration then bar:SetValue(math.min(1,time/duration)) end
 panel:Show()
end
local events=CreateFrame('Frame')
local function update()
 local now=GetTime()
 local onTaxi=read(UnitOnTaxi,'player')
 if onTaxi==true and not flight then
  local trip=pending
  if trip and now>trip.expires then trip=nil end
  flight={start=now,name=trip and trip.name,key=trip and trip.key,estimate=trip and estimate(trip.key)}
  pending=nil
 elseif onTaxi==false and flight then
  local duration=now-flight.start
  if not interrupted and flight.key and duration>=5 and duration<=3600 then
   local previous=estimate(flight.key)
   settings().routes[flight.key]=previous and (previous*2+duration)/3 or duration
  end
  flight=nil;interrupted=false
 end
 if pending and now>pending.expires then pending=nil;interrupted=false end
 render(now)
 if not flight and not pending then events:SetScript('OnUpdate',nil) end
end
local function watch()
 elapsed=0
 events:SetScript('OnUpdate',function(_,delta)
  elapsed=elapsed+delta
  if elapsed>=.25 then elapsed=0;update() end
 end)
 update()
end
local function selected(slot)
 if flight then return end
 local node=nodes and nodes[slot]
 local now=GetTime()
 pending={name=node and node.name,key=routeKey(origin,node),expires=now+12}
 interrupted=false
 origin,nodes=nil,nil
 watch()
end
local function installHooks()
 if type(hooksecurefunc)~='function' then return end
 if not installed.take and type(TakeTaxiNode)=='function' then
  hooksecurefunc('TakeTaxiNode',selected);installed.take=true
 end
 if not installed.early and type(TaxiRequestEarlyLanding)=='function' then
  hooksecurefunc('TaxiRequestEarlyLanding',function() if flight or pending then interrupted=true end end)
  installed.early=true
 end
 if not installed.pin and FlightMap_FlightPointPinMixin and type(FlightMap_FlightPointPinMixin.OnMouseEnter)=='function' then
  hooksecurefunc(FlightMap_FlightPointPinMixin,'OnMouseEnter',function(pin)
   local node=pin.taxiNodeData
   if node and node.slotIndex then refreshMap();tooltip(node.slotIndex) end
  end)
  installed.pin=true
 end
end
for _,event in ipairs({'ADDON_LOADED','TAXIMAP_OPENED','PLAYER_ENTERING_WORLD','PLAYER_LEAVING_WORLD','PLAYER_CONTROL_LOST','PLAYER_DEAD'}) do
 pcall(events.RegisterEvent,events,event)
end
events:SetScript('OnEvent',function(_,event)
 if event=='ADDON_LOADED' then installHooks()
 elseif event=='TAXIMAP_OPENED' then
  installHooks();refreshMap()
  if C_Timer and C_Timer.After then C_Timer.After(0,function() if not pending and not flight then refreshMap() end end) end
 elseif event=='PLAYER_LEAVING_WORLD' or event=='PLAYER_DEAD' then
  origin,nodes,pending=nil,nil,nil
  if flight then interrupted=true end
 elseif event=='PLAYER_ENTERING_WORLD' or event=='PLAYER_CONTROL_LOST' then
  if pending or flight or read(UnitOnTaxi,'player')==true then watch() end
 end
end)
function F.Enabled() return settings().hidden~=true end
function F.SetEnabled(value)
 settings().hidden=not value
 render(GetTime())
end
function F.Toggle()
 F.SetEnabled(not F.Enabled())
 return not F.Enabled() and 'Flight timer hidden.' or 'Flight timer enabled. Hover a flight destination for learned times.'
end
