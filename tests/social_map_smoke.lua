
local now,inInstance,appearingOffline=100,false,false
local linked,visiblePins={},{}
local function noop() end
local function widget(parent)
 local w={shown=true,SetSize=noop,SetPoint=function(self,...)self.point={...} end,SetFrameLevel=noop,SetScale=noop,
  SetColorTexture=noop,SetRotation=noop,RegisterEvent=noop,EnableMouse=noop,SetWidth=noop,SetHeight=noop,
  SetWordWrap=noop,ClearAllPoints=noop,GetFrameLevel=function()return 5 end,
  Show=function(self)self.shown=true end,Hide=function(self)self.shown=false end,
  IsShown=function(self)return self.shown end,
  SetText=function(self,value)self.text=value end,SetScript=function(self,key,fn)self[key]=fn end}
 function w:CreateTexture() return widget() end
 if parent then visiblePins[#visiblePins+1]=w end
 return w
end
CreateFrame=function(_,_,parent)return widget(parent)end
GetTime=function()return now end
GetNormalizedRealmName=function()return 'Realm' end
UnitFullName=function()return 'Me','Realm' end
IsInGuild=function()return true end
GetNumGuildMembers=function()return 1 end
GetGuildRosterInfo=function()return 'Guildie-Realm' end
C_FriendList={GetNumFriends=function()return 2 end,GetFriendInfoByIndex=function(i)
 return i==1 and {name='Buddy',connected=true} or {name='Away',connected=false}
end}
BNGetInfo=function()return nil,nil,7 end
C_BattleNet={GetAccountInfoByID=function()return {appearOffline=appearingOffline} end}
IsInInstance=function()return inInstance,inInstance and 'party' or 'none' end
Enum={UIMapType={Zone=3,Dungeon=4,Micro=5}}
local function point(x,y)return {GetXY=function()return x,y end}end
C_Map={GetBestMapForUnit=function()return 300 end,
 GetMapInfo=function(id)return id==300 and {mapType=3} or {mapType=4} end,
 GetPlayerMapPosition=function()return point(.3141,.5926)end}
C_ChatInfo={RegisterAddonMessagePrefix=function(prefix)assert(prefix=='FCMapLoc1');return true end,
 SendAddonMessage=function(_,msg,channel,target)linked[#linked+1]={msg,channel,target} end}
ForeverCompanionDB={socialMap={sharing=true}}
dofile('ForeverCompanion/SocialMap.lua')
local S=ForeverCompanionSocialMap
S.events.OnEvent(S.events,'PLAYER_ENTERING_WORLD')
S.events.OnUpdate(S.events,30);assert(#linked==0,'startup stays silent even with previous saved settings')
S.SetAudience('friends')
assert(#linked==1 and linked[1][1]=='P:300:3141:5926' and linked[1][2]=='WHISPER' and linked[1][3]=='Buddy')
S.SetAudience('guild')
assert(#linked==3 and linked[2][1]=='X' and linked[3][2]=='GUILD' and linked[3][3]==nil)
inInstance=true;S.events.OnEvent(S.events,'ZONE_CHANGED_NEW_AREA')
assert(#linked==4 and linked[4][1]=='X')
S.Broadcast();assert(#linked==4,'instances never broadcast coordinates')
inInstance=false;appearingOffline=true;S.Broadcast()
assert(#linked==4,'no position is sent while appearing offline')
appearingOffline=false;S.Broadcast();assert(#linked==5)
S.SetAudience(nil);assert(linked[6][1]=='X')
S.Broadcast();assert(#linked==6,'stopping a session halts periodic messages')

local map=widget()
local canvas={GetWidth=function()return 100 end,GetHeight=function()return 100 end,GetFrameLevel=function()return 5 end}
assert(not S.Accept('P:300:1234:5678','WHISPER','Other-Realm'))
assert(not S.Accept('P:300:1234:5678','GUILD','Buddy-AnotherRealm'))
assert(not S.Accept('P:300:12000:0','WHISPER','Buddy-Realm'))
assert(not S.Accept('P:901:1500:3000','WHISPER','Buddy-Realm'),'instance maps rejected')
assert(S.Accept('P:300:2500:7000','WHISPER','Buddy-Realm'))
S.Attach(map,canvas,300)
local pin=visiblePins[1]
assert(pin and pin.shown and pin.point[4]==25 and pin.point[5]==-70)
assert(S.Accept('X','WHISPER','Buddy-Realm'));S.Refresh();assert(not pin.shown)
assert(S.Accept('P:300:2500:7000','GUILD','Guildie-Realm'));S.Refresh();assert(pin.shown)
now=now+112;S.Refresh();assert(not pin.shown,'stale pins expire')
dofile('ForeverCompanion/SocialMap.lua')
local fresh=ForeverCompanionSocialMap
fresh.events.OnEvent(fresh.events,'PLAYER_ENTERING_WORLD');fresh.Broadcast()
assert(#linked==6,'sharing choice does not survive a reload')
print('PASS: social map consent, recipients, offline and instance privacy, packet validation, pins, expiry')

