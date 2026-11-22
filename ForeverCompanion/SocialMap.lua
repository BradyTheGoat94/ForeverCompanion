
-- Optional, session-only sharing of a character's outdoor WoW map position.
local S={}
ForeverCompanionSocialMap=S
local prefix='FCMapLoc1'
local ttl=110
local audience
local registered
local friends,guild={},{}
local rosterTime=-100
local peers={}
local rosterCursor=0
local postedGuild=false
local postedFriends={}
local pins={}
local attached,canvas,mapID
local panel,status,toggle

local function safe(value)
 if not (issecretvalue and issecretvalue(value)) then return value end
end
local function read(fn,...)
 if type(fn)~='function' then return end
 local ok,a,b,c=pcall(fn,...)
 if ok then return safe(a),safe(b),safe(c) end
end
local function time() return read(GetTime) or 0 end
local function coordinate(n) return type(n)=='number' and n>=0 and n<=1 end
local function canonical(name)
 if type(name)~='string' or #name==0 or #name>85 or name:find('[%c%s|]') then return end
 if not name:find('-',1,true) then
  local realm=read(GetNormalizedRealmName)
  if type(realm)~='string' or realm=='' then return end
  name=name..'-'..realm
 end
 return name:lower()
end
local function localPlayer()
 local name,realm=read(UnitFullName,'player')
 if type(name)=='string' and type(realm)=='string' and realm~='' then return canonical(name..'-'..realm) end
 return canonical(name or read(UnitName,'player'))
end
local function updateRoster(now)
 if now-rosterTime<10 then return end
 rosterTime=now
 friends,guild={},{}
 local api=C_FriendList or {}
 local count=read(api.GetNumFriends)
 if type(count)=='number' and count>0 then
  for i=1,math.min(count,100) do
   local entry=read(api.GetFriendInfoByIndex,i)
   if type(entry)=='table' then
    local name=safe(entry.name)
    local key=canonical(name)
    if key and safe(entry.connected)==true then friends[key]=name end
   end
  end
 end
 count=read(IsInGuild)==true and read(GetNumGuildMembers)
 if type(count)=='number' and count>0 then
  for i=1,math.min(count,1500) do
   local key=canonical(read(GetGuildRosterInfo,i))
   if key then guild[key]=true end
  end
 end
end
local function isOutdoorMap(id)
 if type(id)~='number' or id<1 or id>100000 or id%1~=0 then return false end
 local info=read(C_Map and C_Map.GetMapInfo,id)
 local types=Enum and Enum.UIMapType
 local kind=type(info)=='table' and safe(info.mapType)
 return not not (kind and types and (kind==types.Zone or kind==types.City))
end
local function outside()
 local inside,kind=read(IsInInstance)
 return inside==false and kind=='none'
end
local function offline()
 local _,_,account=read(BNGetInfo)
 local info=account and read(C_BattleNet and C_BattleNet.GetAccountInfoByID,account)
 local game=type(info)=='table' and safe(info.gameAccountInfo)
 return type(info)=='table' and (safe(info.appearOffline)==true or type(game)=='table' and safe(game.isAppearOffline)==true)
end
local function send(message,channel,character)
 if registered and C_ChatInfo then read(C_ChatInfo.SendAddonMessage,prefix,message,channel,character) end
end
local function stop()
 if not offline() then
  if postedGuild and read(IsInGuild)==true then send('X','GUILD') end
  for key in pairs(postedFriends) do if friends[key] then send('X','WHISPER',friends[key]) end end
 end
 postedGuild=false;postedFriends={}
end
function S.Broadcast()
 if not audience or not registered then return end
 updateRoster(time())
 if offline() then postedGuild=false;postedFriends={};return end
 if not outside() then stop();return end
 local api=C_Map or {}
 local zone=read(api.GetBestMapForUnit,'player')
 if not isOutdoorMap(zone) then stop();return end
 local point=read(api.GetPlayerMapPosition,zone,'player')
 local x,y
 if point then x,y=read(point.GetXY,point) end
 if not coordinate(x) or not coordinate(y) or x==0 and y==0 then stop();return end
 local packet=('P:%d:%d:%d'):format(zone,math.floor(x*10000+.5),math.floor(y*10000+.5))
 if (audience=='guild' or audience=='both') and read(IsInGuild)==true then send(packet,'GUILD');postedGuild=true end
 if audience=='friends' or audience=='both' then
  local keys={}
  for key in pairs(friends) do keys[#keys+1]=key end
  table.sort(keys)
  for _=1,math.min(#keys,12) do
   rosterCursor=rosterCursor%#keys+1
   local key=keys[rosterCursor]
   send(packet,'WHISPER',friends[key]);postedFriends[key]=true
  end
 end
end

function S.Accept(message,channel,sender)
 sender=safe(sender);channel=safe(channel);message=safe(message)
 if type(message)~='string' or #message>30 then return false end
 local now=time()
 updateRoster(now)
 local key=canonical(sender)
 if not key or key==localPlayer() then return false end
 if not (channel=='GUILD' and read(IsInGuild)==true and guild[key] or channel=='WHISPER' and friends[key]) then return false end
 if message=='X' then
  if peers[key] and peers[key].channel==channel then peers[key]=nil end
  return true
 end
 local zone,x,y=message:match('^P:(%d+):(%d+):(%d+)$')
 zone,x,y=tonumber(zone),tonumber(x),tonumber(y)
 if not (zone and x and y and x<=10000 and y<=10000 and (x>0 or y>0) and isOutdoorMap(zone)) then return false end
 peers[key]={name=sender,map=zone,x=x/10000,y=y/10000,channel=channel,expires=now+ttl}
 return true
end

local function project(peer,target)
 local map=C_Map or {}
 local api=OpenMapAPI
 local stitched=type(api)=='table' and api.major==1 and read(api.IsStitched)==true
 if peer.map==target and not stitched then return peer.x,peer.y end
 local point=read(CreateVector2D,peer.x,peer.y)
 if not point then return end
 local continent,world=read(map.GetWorldPosFromMapPos,peer.map,point)
 if continent==nil or not world then return end
 if stitched then
  local x,y=read(world.GetXY,world)
  if x~=nil and y~=nil then return read(api.CanvasFromWorldPos,continent,x,y) end
  return
 end
 local id,p=read(map.GetMapPosFromWorldPos,continent,world,target)
 if id==target and p then return read(p.GetXY,p) end
end
function S.Hide() for _,pin in ipairs(pins) do pin:Hide() end end
local function createPin(parent)
 local pin=CreateFrame('Button',nil,parent)
 pin:SetSize(15,15);pin:SetFrameLevel(parent:GetFrameLevel()+172)
 local rim=pin:CreateTexture(nil,'BACKGROUND')
 rim:SetSize(12,12);rim:SetPoint('CENTER');rim:SetColorTexture(.10,.07,.03,1)
 local dot=pin:CreateTexture(nil,'ARTWORK')
 dot:SetSize(8,8);dot:SetPoint('CENTER');pin.dot=dot
 if dot.SetRotation then dot:SetRotation(math.pi/4);rim:SetRotation(math.pi/4) end
 pin:SetScript('OnEnter',function(self)
  if not self.peer or not GameTooltip then return end
  GameTooltip:SetOwner(self,'ANCHOR_RIGHT')
  GameTooltip:SetText(self.peer.name)
  GameTooltip:AddLine(self.peer.channel=='WHISPER' and 'Friend sharing location' or 'Guildmate sharing location',.91,.78,.48)
  GameTooltip:Show()
 end)
 pin:SetScript('OnLeave',function() if GameTooltip then GameTooltip:Hide() end end)
 return pin
end
local function dotsHidden() return ForeverCompanionDB and ForeverCompanionDB.hideSharedMapDots==true end
function S.Refresh()
 S.Hide()
 if ForeverCompanionDB and ForeverCompanionDB.hideCompanionWorldMap then
  if panel then panel:Hide() end
  return
 end
 if not attached or not attached:IsShown() or not canvas or dotsHidden() or not outside() then return end
 local kind=read(C_Map and C_Map.GetMapInfo,mapID)
 local types=Enum and Enum.UIMapType
 if type(kind)~='table' or not types or safe(kind.mapType)==types.Dungeon or safe(kind.mapType)==types.Micro then return end
 local width,height=read(canvas.GetWidth,canvas),read(canvas.GetHeight,canvas)
 if type(width)~='number' or type(height)~='number' or width<=0 or height<=0 then return end
 local scroll=attached.ScrollContainer
 local scale=scroll and read(scroll.GetCanvasScale,scroll)
 if type(scale)~='number' or scale<=0 then scale=read(canvas.GetScale,canvas) or 1 end
 local now=time()
 updateRoster(now)
 local index=0
 for key,peer in pairs(peers) do
  if peer.expires<=now or peer.channel=='WHISPER' and not friends[key] or peer.channel=='GUILD' and (read(IsInGuild)~=true or not guild[key]) then
   peers[key]=nil
  elseif index<100 then
   local x,y=project(peer,mapID)
   if coordinate(x) and coordinate(y) then
    index=index+1
    local pin=pins[index] or createPin(canvas)
    pins[index]=pin;pin.peer=peer
    pin:SetScale(1/scale)
    if peer.channel=='WHISPER' then pin.dot:SetColorTexture(.40,.88,.96,1) else pin.dot:SetColorTexture(.96,.73,.29,1) end
    pin:ClearAllPoints();pin:SetPoint('CENTER',canvas,'TOPLEFT',x*width*scale,-y*height*scale);pin:Show()
   end
  end
 end
end
function S.Attach(map,parent,id)
 if canvas~=parent then S.Hide();pins={} end
 attached,canvas,mapID=map,parent,id
 S.Refresh()
end
local function redrawPanel()
 if not status then return end
 local label=({friends='Character friends',guild='Guildmates',both='Character friends and guildmates'})[audience] or 'Off'
 local suffix=audience and (offline() and ' (paused while appearing offline)' or not outside() and ' (paused indoors)' or '') or ''
 status:SetText(registered and ('Sharing this session: '..label..suffix) or 'Location sharing unavailable on this client.')
 toggle:SetText(dotsHidden() and 'Show their dots' or 'Hide their dots')
end
function S.SetAudience(choice)
 if choice==audience then return end
 if choice and choice~='friends' and choice~='guild' and choice~='both' then return end
 stop()
 audience=choice
 if audience then S.Broadcast() end
 redrawPanel()
end
function S.Open(owner)
 if not panel then
  local U=ForeverCompanionInterface
  panel=CreateFrame('Frame',nil,owner)
  panel:SetPoint('CENTER');panel:SetFrameLevel(owner:GetFrameLevel()+300)
  panel:SetSize(508,180);panel:EnableMouse(true);U.Surface(panel)
  local function label(y,size,value,height)
   local text=U.Text(panel,size)
   text:SetPoint('TOPLEFT',14,y);text:SetWidth(480);text:SetText(value)
   if height then text:SetHeight(height);text:SetWordWrap(true) end
   return text
  end
  label(-12,16,'Friends & Guild Map')
  label(-39,12,'Share your outdoor WoW position for this login. Your chosen audience needs Forever Companion. Sharing pauses inside dungeons, raids and battlegrounds.',34)
  status=label(-80,12,'',24)
  local function button(x,y,title,action)
   local control=U.Button(panel);control:SetPoint('TOPLEFT',x,y);control:SetSize(151,24)
   control:SetText(title);control:SetScript('OnClick',action)
   return control
  end
  button(14,-109,'Share with friends',function() S.SetAudience('friends') end)
  button(178,-109,'Share with guild',function() S.SetAudience('guild') end)
  button(342,-109,'Share with both',function() S.SetAudience('both') end)
  button(14,-141,'Stop sharing',function() S.SetAudience(nil) end)
  toggle=button(178,-141,'Hide their dots',function()
   ForeverCompanionDB=ForeverCompanionDB or {}
   ForeverCompanionDB.hideSharedMapDots=not dotsHidden()
   S.Refresh();redrawPanel()
  end)
  button(342,-141,'Close',function() panel:Hide() end)
 end
 redrawPanel();panel:Show()
end

local events=CreateFrame('Frame')
for _,event in ipairs({'PLAYER_ENTERING_WORLD','ZONE_CHANGED_NEW_AREA','CHAT_MSG_ADDON','FRIENDLIST_UPDATE','GUILD_ROSTER_UPDATE','PLAYER_GUILD_UPDATE','PLAYER_LOGOUT'}) do
 pcall(events.RegisterEvent,events,event)
end
events:SetScript('OnEvent',function(_,event,tag,packet,channel,sender)
 if event=='CHAT_MSG_ADDON' then
  if safe(tag)==prefix and S.Accept(packet,channel,sender) then S.Refresh() end
 elseif event=='PLAYER_LOGOUT' then
  S.SetAudience(nil)
 else
  if event=='PLAYER_ENTERING_WORLD' then
   registered=read(C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix,prefix)==true or
    read(C_ChatInfo and C_ChatInfo.IsAddonMessagePrefixRegistered,prefix)==true
  end
  rosterTime=-100
  if audience and (event=='PLAYER_ENTERING_WORLD' or event=='ZONE_CHANGED_NEW_AREA') then S.Broadcast() end
  S.Refresh();redrawPanel()
 end
end)
S.events=events
local render,elapsed=0,0
events:SetScript('OnUpdate',function(_,dt)
 render=render+dt;elapsed=elapsed+dt
 if elapsed>=10 then elapsed=0;if audience then S.Broadcast() end end
 if render>=3 then
  render=0
  if attached and attached:IsShown() then S.Refresh() end
 end
end)
