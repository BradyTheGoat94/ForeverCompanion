local frame={}
function frame:RegisterEvent() end
function frame:SetScript(key,fn) self[key]=fn end
CreateFrame=function() return frame end
ForeverCompanionDB={}
local now,level,xp,maximum=100,10,100,1000
GetTime=function() return now end
UnitLevel=function() return level end
UnitXP=function() return xp end
UnitXPMax=function() return maximum end
ForeverCompanionQuestHistory={Money=function(n) return tostring(n)..' copper' end}
dofile('ForeverCompanion/SessionProgress.lua')
local s=ForeverCompanionSessionProgress
frame.OnEvent(frame,'PLAYER_ENTERING_WORLD')
now=160;xp=250;s.Sample()
local p=s.Snapshot();assert(p.seconds==60 and p.xp==150 and p.rate==9000)
s.RecordQuest({title='Observed quest',xp=150,money=100})
assert(s.Snapshot().xp==150,'reported quest XP must not double-count sampled XP')
assert(s.Snapshot().turnins==1 and s.Snapshot().rewardXPKnown==1)
level=11;xp=50;maximum=1200;now=170;s.Sample()
assert(s.Snapshot().xp==950,'one observed level transition includes remaining old-level XP')
s.SetPaused(true);now=470;xp=300;s.Sample();s.RecordQuest({title='Paused quest',xp=250})
assert(s.Snapshot().seconds==70 and s.Snapshot().xp==950 and s.Snapshot().turnins==1)
s.SetPaused(false);now=500;xp=350;s.Sample()
assert(s.Snapshot().seconds==100 and s.Snapshot().xp==1000,'resume excludes paused gains and time')
p=s.Snapshot();p.recent[1].title='Mutated';assert(s.Snapshot().recent[1].title=='Observed quest')
xp=10;now=510;s.Sample();assert(s.Snapshot().gaps==1 and s.Snapshot().rate==nil,'backwards XP cannot produce a misleading hourly rate')
level=13;xp=20;now=520;s.Sample();assert(s.Snapshot().xp==1000,'skipped levels do not invent missing thresholds')
now=519;s.Snapshot();assert(s.Snapshot().clockGap and s.Snapshot().rate==nil)
s.NewSession();assert(#ForeverCompanionDB.sessionArchive==1 and s.Snapshot().xp==0)
for i=1,15 do s.RecordQuest({title='Quest '..i});s.NewSession() end
assert(#ForeverCompanionDB.sessionArchive==10,'ended session storage is bounded')
s.Start();s.RecordQuest({title='Unknown rewards'})
assert(s.Snapshot().moneyKnown==0 and s.Snapshot().rewardXPKnown==0)
local secret=setmetatable({secret=true},{__lt=function() error('secret compared') end})
issecretvalue=function(v) return type(v)=='table' and v.secret end
xp=secret;s.Sample();assert(s.Snapshot().rate==nil)
assert(s.Delta({level=10,xp=secret,maximum=1000},{level=10,xp=100,maximum=1000})==nil)
GetTime=nil;s.Start();assert(s.Snapshot().clockGap and s.Snapshot().rate==nil)
assert(not s.SetPaused('yes'))
assert(s.Duration(3661)=='1:01:01')
print('PASS: observed session XP, level transitions, pause, missing samples, reward separation, archive bounds and snapshots')
