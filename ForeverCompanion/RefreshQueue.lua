-- Coalesce presentation refreshes over a short frame interval. No gameplay calls.
local Q={requested=0,batches=0,coalesced=0,measured=0,totalMS=0,maxMS=0}
ForeverCompanionRefreshQueue=Q
local pending,elapsed={},0
local frame=CreateFrame('Frame')
local function clock()
 if type(debugprofilestop)~='function' then return end
 local ok,value=pcall(debugprofilestop)
 if ok and not (issecretvalue and issecretvalue(value)) and type(value)=='number' and value==value and value>=0 and value<math.huge then return value end
end
function Q.Flush()
 frame:SetScript('OnUpdate',nil)
 local work=pending;pending={};elapsed=0
 if not next(work) then return end
 Q.batches=Q.batches+1
 local start=clock()
 for _,fn in pairs(work) do fn() end
 local finish=clock()
 if start and finish and finish>=start then
  local duration=finish-start
  Q.measured=Q.measured+1;Q.totalMS=Q.totalMS+duration;Q.maxMS=math.max(Q.maxMS,duration)
 end
end
function Q.Schedule(key,fn)
 if type(key)~='string' or type(fn)~='function' then return end
 Q.requested=Q.requested+1
 if pending[key] then Q.coalesced=Q.coalesced+1 end
 pending[key]=fn
 frame:SetScript('OnUpdate',function(_,dt)
  elapsed=elapsed+dt
  if elapsed>=.05 then Q.Flush() end
 end)
end
function Q.Summary()
 local timing=Q.measured>0 and string.format('Measured batches: %d / average %.2f ms / max %.2f ms',Q.measured,Q.totalMS/Q.measured,Q.maxMS) or 'Timing unavailable: client profiling clock not exposed'
 return string.format('Page refresh requests: %d / batches: %d / merged requests: %d\n%s\nMeasures queued page refresh work only; not total addon CPU or frame rate.',Q.requested,Q.batches,Q.coalesced,timing)
end
