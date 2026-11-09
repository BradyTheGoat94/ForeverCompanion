local frame={}
function CreateFrame() return frame end
function frame:SetScript(key,fn) self[key]=fn end
local now=0
debugprofilestop=function() now=now+5;return now end
dofile('ForeverCompanion/RefreshQueue.lua')
local q=ForeverCompanionRefreshQueue
local called=0
q.Schedule('page',function() error('replaced callback must not run') end)
q.Schedule('page',function() called=called+1 end)
assert(called==0)
frame.OnUpdate(frame,.02);assert(called==0)
frame.OnUpdate(frame,.04)
assert(called==1 and q.batches==1 and q.coalesced==1 and q.requested==2)
assert(frame.OnUpdate==nil and q.totalMS==5 and q.maxMS==5)
q.Schedule('page',function() q.Schedule('page',function() called=called+1 end) end)
q.Flush();assert(frame.OnUpdate,'refresh queued during a flush must survive')
q.Flush();assert(called==2)
local measured=q.measured
debugprofilestop=nil
q.Schedule('page',function() called=called+1 end);q.Flush()
assert(called==3 and q.measured==measured,'missing profiling clock must not invent timings')
q.Schedule(nil,function() end);q.Schedule('invalid',nil)
assert(frame.OnUpdate==nil)
assert(q.Summary():find('not total addon CPU',1,true))
local unknown=q.Start('meter');q.Finish('meter',unknown)
assert(q.Profile('meter').calls==1 and q.Profile('meter').average==nil,'missing clock cannot create meter timings')
now=100;debugprofilestop=function() now=now+5;return now end
local started=q.Start('map');q.Finish('map',started)
local p=q.Profile('map')
assert(p.calls==1 and p.measured==1 and p.average==5 and p.maximum==5)
p.calls=999;assert(q.Profile('map').calls==1,'diagnostic snapshots must not mutate counters')
q.Reset();assert(q.requested==0 and q.Profile('map').calls==0,'new session sample resets every scope')
local errors=0
geterrorhandler=function() return function() errors=errors+1;error('broken error handler') end end
q.Schedule('a-broken',function() error('panel failure') end)
q.Schedule('b-working',function() called=called+1;q.Schedule('followup',function() called=called+1 end) end)
local before=called
q.Flush()
assert(called==before+1 and errors==1 and q.failures==1 and q.lastFailedKey=='a-broken','one failing panel or error handler cannot lose unrelated refreshes')
q.Flush();assert(called==before+2,'follow-up scheduled after a failed callback remains runnable')
assert(q.Summary():find('Refresh failures: 1',1,true))
q.Reset();assert(q.failures==0 and q.lastFailedKey==nil)
print('PASS: refresh burst coalescing, idle teardown, reentrant scheduling and measured/unknown timing')
