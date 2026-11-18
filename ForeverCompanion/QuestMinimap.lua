-- Selected-quest points only. Requires native minimap radius and world-space
-- conversion; no zoom/radius lookup tables and no guessed coordinates.
local M={};ForeverCompanionQuestMinimap=M
local markers,entries={},{}
local status='Awaiting map data'
local function finite(n) return not (issecretvalue and issecretvalue(n)) and type(n)=='number' and n==n and math.abs(n)<math.huge end
local function read(fn,...)
 if type(fn)~='function' then return end
 local ok,a,b,c=pcall(fn,...);if ok then return a,b,c end
end
local function settings()
 ForeverCompanionDB=ForeverCompanionDB or {}
 if type(ForeverCompanionDB.questMinimap)~='table' then ForeverCompanionDB.questMinimap={} end
 return ForeverCompanionDB.questMinimap
end
function M.IsEnabled() return settings().enabled~=false end
function M.MailEnabled()
 local d=settings()
 if d.mailboxes==nil then
  local hidden=ForeverCompanionDB.questMapHiddenServices
  d.mailboxes=type(hidden)~='table' or hidden.M~=true
 end
 return d.mailboxes
end
function M.SetMailEnabled(value) settings().mailboxes=value==true;M.Refresh() end
function M.Status() return status end
function M.Hide() for _,marker in ipairs(markers) do marker:Hide() end end
function M.SetEnabled(value)
 if type(value)~='boolean' then return false end
 settings().enabled=value
 M.Refresh();return true
end
function M.Project(north,west,radius,width,height,angle)
 if not finite(north) or not finite(west) or not finite(radius) or radius<=0 or not finite(width) or width<=0 or not finite(height) or height<=0 or not finite(angle) then return end
 -- A conservative circular boundary stays inside round and square minimaps.
 if north*north+west*west>(radius*.88)^2 then return end
 local c,s=math.cos(angle),math.sin(angle)
 return (-west*c+north*s)/radius*width/2,(north*c+west*s)/radius*height/2
end
local function world(map,x,y)
 if not C_Map or type(C_Map.GetWorldPosFromMapPos)~='function' or type(CreateVector2D)~='function' then return end
 local vector=read(CreateVector2D,x,y)
 local continent,position=read(C_Map.GetWorldPosFromMapPos,map,vector)
 if not finite(continent) or not position then return end
 local north,west=read(position.GetXY,position)
 if finite(north) and finite(west) then return continent,north,west end
end
local function dimensions()
 local map=Minimap
 if not map or read(map.IsShown,map)~=true or type(map.GetViewRadius)~='function' then return end
 local radius=read(map.GetViewRadius,map)
 local width,height=read(map.GetWidth,map),read(map.GetHeight,map)
 if finite(radius) and radius>0 and finite(width) and width>0 and finite(height) and height>0 then return radius,width,height end
end
local function marker(parent)
 local b=CreateFrame('Button',nil,parent);b:SetSize(16,16);b:SetFrameLevel(parent:GetFrameLevel()+9);b:RegisterForClicks('LeftButtonUp','RightButtonUp')
 local bg=b:CreateTexture(nil,'BACKGROUND');bg:SetAllPoints(b);bg:SetColorTexture(.02,.03,.045,.96)
 b.fill=b:CreateTexture(nil,'ARTWORK');b.fill:SetPoint('TOPLEFT',2,-2);b.fill:SetPoint('BOTTOMRIGHT',-2,2)
 b.symbol=ForeverCompanionInterface.Text(b,10);b.symbol:SetAllPoints(b);b.symbol:SetJustifyH('CENTER');b.symbol:SetTextColor(.025,.04,.055)
 b:SetScript('OnEnter',function(self)
  if not GameTooltip or not self.entry then return end
  local e=self.entry
  GameTooltip:SetOwner(self,'ANCHOR_LEFT');if e.mailbox then
   GameTooltip:SetText('Mailbox');GameTooltip:AddLine(e.target.source or 'Map reference',.85,.85,.85,true);GameTooltip:Show();return
  end
  GameTooltip:SetText(e.quest.title)
  GameTooltip:AddLine(e.target.objective or e.target.label or 'General quest point',.9,.92,.96,true)
  GameTooltip:AddLine(ForeverCompanionQuestWaypoints.Describe(e.target),.85,.74,.5,true)
  GameTooltip:AddLine('Left-click: directions. Right-click: quest guide.',.7,.84,.9,true);GameTooltip:Show()
 end)
 b:SetScript('OnLeave',function() if GameTooltip then GameTooltip:Hide() end end)
 b:SetScript('OnClick',function(self,key)
  local e=self.entry;local planner=ForeverCompanionQuestPlanner
  if e and e.mailbox then
   local target=ForeverCompanionTownServices.Resolve(e.target)
   if target and key=='LeftButton' then ForeverCompanionQuestWaypoints.Navigate(target,false,'Mailbox') end
   return
  end
  if not e or not planner or not planner.IsSupported() then M.Refresh();return end
  local q,index,target=ForeverCompanionQuestWaypoints.ResolveActiveEntry(e,planner.GetLive())
  if not target then M.Refresh();return end
  if key=='RightButton' then if ForeverCompanionOpenQuestGuide then ForeverCompanionOpenQuestGuide(q.id) end
  else
   planner.Select(index)
   local message=ForeverCompanionQuestWaypoints.Navigate(target,false,q.title,q.id)
   if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage(message) end
  end
 end)
 return b
end
function M.UpdatePositions()
 M.Hide()
 if not M.IsEnabled() and #entries==0 then status='Off';return end
 if #entries==0 then return end
 local radius,width,height=dimensions()
 if not radius then status='Native minimap radius unavailable; use the world map';return end
 local map=C_Map and read(C_Map.GetBestMapForUnit,'player')
 local pos=map and read(C_Map.GetPlayerMapPosition,map,'player')
 local x,y
 if pos then x,y=read(pos.GetXY,pos) end
 if not finite(x) or not finite(y) then status='Player position unavailable; use the world map';return end
 local continent,north,west=world(map,x,y)
 if not continent then status='Map conversion unavailable; use the world map';return end
 local rotate=read(GetCVar,'rotateMinimap')=='1'
 local angle=rotate and read(GetPlayerFacing) or 0
 if not finite(angle) then status='Facing unavailable; use the world map';return end
 local count=0
 for _,entry in ipairs(entries) do
  local target=entry.target
  local region,tn,tw=world(target.map,target.x,target.y)
  if region==continent then
   local ox,oy=M.Project(tn-north,tw-west,radius,width,height,angle)
   if ox then
    count=count+1
    local b=markers[count];if not b then b=marker(Minimap);markers[count]=b end
    b.entry=entry;b:ClearAllPoints();b:SetPoint('CENTER',Minimap,'CENTER',ox,oy)
    if entry.mailbox then
     b.fill:SetTexture(ForeverCompanionServiceAtlas.Icon('M'));b.symbol:SetText('');b:Show()
    else
    local ready=entry.quest.complete==true
    b.fill:SetColorTexture(ready and .46 or (target.reference and .95 or .25),ready and .88 or (target.reference and .74 or .77),ready and .59 or (target.reference and .35 or .93),1)
    b.symbol:SetText(ready and '?' or (target.objectiveIndex and tostring(target.objectiveIndex) or 'Q'));b:Show()
    end
   end
  end
 end
 status=count>0 and (count..' nearby map pins') or 'Map pins are outside minimap range'
end
function M.Refresh()
 entries={};M.Hide()
 if not M.IsEnabled() and not M.MailEnabled() then status='Off';return end
 local map=C_Map and read(C_Map.GetBestMapForUnit,'player')
 if M.MailEnabled() and map and ForeverCompanionTownServices then
  for _,target in ipairs(ForeverCompanionTownServices.ForMap(map)) do
   if target.symbol=='M' then entries[#entries+1]={mailbox=true,target=target} end
  end
 end
 local mailboxCount=#entries
 if not M.IsEnabled() then if mailboxCount>0 then M.UpdatePositions() else status='Off' end;return end
 local p=ForeverCompanionQuestPlanner
 if not p or read(p.IsSupported)~=true then if mailboxCount>0 then M.UpdatePositions();return end;status='Quest data unavailable; minimap points hidden';return end
 local q=read(p.GetSelected)
 if type(q)~='table' then if mailboxCount>0 then M.UpdatePositions();return end;status='Select a quest to show nearby points';return end
 local seen={}
 for _,target in ipairs(ForeverCompanionQuestWaypoints.Targets(q)) do
  local state=q.objectiveStates and q.objectiveStates[target.objectiveIndex]
  if not (type(state)=='table' and state.known and state.done) then
   local key=target.map..':'..target.x..':'..target.y
   if not seen[key] then
    seen[key]=true;entries[#entries+1]={quest=q,target=target}
    if #entries-mailboxCount==12 then break end
   end
  end
 end
 if #entries==0 then status='No reported points for this quest; use the quest log';return end
 M.UpdatePositions()
end
local watcher=CreateFrame('Frame')
for _,event in ipairs({'PLAYER_ENTERING_WORLD','ZONE_CHANGED_NEW_AREA','MINIMAP_UPDATE_ZOOM','CVAR_UPDATE'}) do watcher:RegisterEvent(event) end
watcher:SetScript('OnEvent',M.Refresh)
watcher:SetScript('OnUpdate',function(self,dt)
 if #entries==0 then return end
 self.elapsed=(self.elapsed or 0)+dt
 if self.elapsed>=.2 then self.elapsed=0;M.UpdatePositions() end
end)
