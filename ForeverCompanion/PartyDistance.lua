-- Read only public distance or position data for members of a five-player party.
local D={}
ForeverCompanionPartyDistance=D
local panel
local rows={}
local function public(v)
 if not (issecretvalue and issecretvalue(v)) then return v end
end
local function read(fn,...)
 if type(fn)~='function' then return end
 local ok,a,b,c,d=pcall(fn,...)
 if ok then return public(a),public(b),public(c),public(d) end
end
local function number(n)
 return type(n)=='number' and n==n and math.abs(n)<math.huge
end
local function position(unit)
 local x,y,_,instance=read(UnitPosition,unit)
 if number(x) and number(y) and number(instance) then return x,y,instance end
end
local function mapPosition(map,unit)
 local point=read(C_Map.GetPlayerMapPosition,map,unit)
 if not point then return end
 local continent,world=read(C_Map.GetWorldPosFromMapPos,map,point)
 if not world or not number(continent) then return end
 local x,y=read(world.GetXY,world)
 if number(x) and number(y) then return x,y,continent end
end
local function yards(a,b,c,x,y,z)
 if a and x and c==z then
  local dx,dy=x-a,y-b
  return math.sqrt(dx*dx+dy*dy)
 end
end
function D.Measure(unit)
 if read(UnitIsConnected,unit)==false then return 'Offline' end
 local squared,checked=read(UnitDistanceSquared,unit)
 if checked==true and number(squared) and squared>=0 then return ('%.0f yd'):format(math.sqrt(squared)),true end
 local a,b,c=position('player')
 local x,y,z=position(unit)
 local distance=yards(a,b,c,x,y,z)
 if distance then return ('~%.0f yd'):format(distance),true end
 if C_Map and (not c or not z) and read(IsInInstance)==false then
  local map=read(C_Map.GetBestMapForUnit,'player')
  if number(map) then
   a,b,c=mapPosition(map,'player')
   x,y,z=mapPosition(map,unit)
   distance=yards(a,b,c,x,y,z)
   if distance then return ('~%.0f yd'):format(distance),true end
  end
 end
 local inRange,didCheck=read(UnitInRange,unit)
 if didCheck==true and type(inRange)=='boolean' then return inRange and 'In range' or 'Out of range' end
 return 'Unavailable'
end
local function create()
 local U=ForeverCompanionInterface
 panel=CreateFrame('Frame','ForeverCompanionPartyDistanceFrame',UIParent,'BackdropTemplate')
 panel:SetSize(225,126)
 panel:SetPoint('RIGHT',UIParent,'RIGHT',-40,80)
 panel:SetFrameStrata('MEDIUM')
 U.Surface(panel)
 local close=U.CloseButton(panel,function() D.SetEnabled(false) end)
 close:SetSize(20,20)
 local title=U.Text(panel,13,U.palette.accent)
 title:SetPoint('TOPLEFT',12,-7)
 title:SetText('Party distance')
 for i=1,4 do
  local name=U.Text(panel,12)
  name:SetPoint('TOPLEFT',12,-(30+(i-1)*21))
  name:SetWidth(111)
  local value=U.Text(panel,12)
  value:SetPoint('TOPRIGHT',-12,-(30+(i-1)*21))
  value:SetWidth(87)
  value:SetJustifyH('RIGHT')
  rows[i]={name=name,value=value}
 end
 local elapsed=0
 panel:SetScript('OnUpdate',function(_,dt)
  elapsed=elapsed+dt
  if elapsed>=.5 then elapsed=0;D.Refresh() end
 end)
end
function D.Enabled()
 return ForeverCompanionDB and ForeverCompanionDB.partyDistanceEnabled==true
end
function D.Refresh()
 if not D.Enabled() or read(IsInRaid)==true then
  if panel then panel:Hide() end
  return
 end
 local units=ForeverCompanionPartyMap.PartyUnits()
 if #units==0 then
  if panel then panel:Hide() end
  return
 end
 if not panel then create() end
 for i,row in ipairs(rows) do
  local unit=units[i]
  row.name:SetShown(unit~=nil)
  row.value:SetShown(unit~=nil)
  if unit then
   row.name:SetText(read(UnitName,unit) or ('Party member '..i))
   local text,measured=D.Measure(unit)
   row.value:SetText(text)
   if measured then row.value:SetTextColor(.52,.88,.80)
   else row.value:SetTextColor(.72,.76,.80) end
  end
 end
 panel:SetHeight(38+21*math.min(#units,4))
 panel:Show()
end
function D.SetEnabled(enabled)
 ForeverCompanionDB=ForeverCompanionDB or {}
 ForeverCompanionDB.partyDistanceEnabled=enabled
 D.Refresh()
 return enabled and 'Party distance enabled. Drag its title to move it.' or 'Party distance hidden.'
end
local events=CreateFrame('Frame')
events:RegisterEvent('PLAYER_ENTERING_WORLD')
events:RegisterEvent('GROUP_ROSTER_UPDATE')
events:SetScript('OnEvent',D.Refresh)
