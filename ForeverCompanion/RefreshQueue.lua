-- Coalesce presentation refreshes over a short frame interval. No gameplay calls.
local Q={requested=0,batches=0,coalesced=0,measured=0,totalMS=0,maxMS=0,failures=0}
ForeverCompanionRefreshQueue=Q
local pending,elapsed={},0
local frame=CreateFrame('Frame')
local profiles={}
local scopes={meter='Meter refresh',map='Map refresh',itinerary='Objective itinerary'}
local function clock()
 if type(debugprofilestop)~='function' then return end
 local ok,value=pcall(debugprofilestop)
 if ok and not (issecretvalue and issecretvalue(value)) and type(value)=='number' and value==value and value>=0 and value<math.huge then return value end
end
function Q.Start(scope)
 if not scopes[scope] then return end
 profiles[scope]=profiles[scope] or {calls=0,measured=0,total=0,maximum=0}
 profiles[scope].calls=profiles[scope].calls+1
 return clock()
end
function Q.Finish(scope,start)
 local profile=profiles[scope]
 local finish=clock()
 if profile and not (issecretvalue and issecretvalue(start)) and type(start)=='number' and start==start and start>=0 and start<math.huge and finish and finish>=start then
  local duration=finish-start
  profile.measured=profile.measured+1;profile.total=profile.total+duration;profile.maximum=math.max(profile.maximum,duration)
 end
end
function Q.Profile(scope)
 local p=profiles[scope]
 if not p then return {calls=0,measured=0} end
 return {calls=p.calls,measured=p.measured,average=p.measured>0 and p.total/p.measured or nil,maximum=p.measured>0 and p.maximum or nil}
end
function Q.Reset()
 Q.Flush()
 Q.requested=0;Q.batches=0;Q.coalesced=0;Q.measured=0;Q.totalMS=0;Q.maxMS=0;Q.failures=0;Q.lastFailedKey=nil;profiles={}
end
function Q.Flush()
 frame:SetScript('OnUpdate',nil)
 local work=pending;pending={};elapsed=0
 if not next(work) then return end
 Q.batches=Q.batches+1
 local start=clock()
 local keys={};for key in pairs(work) do keys[#keys+1]=key end;table.sort(keys)
 for _,key in ipairs(keys) do
  local ok,err=pcall(work[key])
  if not ok then
   Q.failures=Q.failures+1;Q.lastFailedKey=key
   -- Preserve normal client error reporting without allowing an error handler
   -- to prevent unrelated pending panels from refreshing.
   if type(geterrorhandler)=='function' then
    local found,handler=pcall(geterrorhandler)
    if found and type(handler)=='function' then pcall(handler,err) end
   end
  end
 end
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
 local lines={string.format('Page refresh requests: %d / batches: %d / merged requests: %d',Q.requested,Q.batches,Q.coalesced),timing}
 lines[#lines+1]='Refresh failures: '..Q.failures..(Q.lastFailedKey and (' / last panel: '..Q.lastFailedKey) or '')
 for _,scope in ipairs({'meter','map','itinerary'}) do
  local p=Q.Profile(scope)
  lines[#lines+1]=scopes[scope]..': '..p.calls..' calls / '..(p.average and string.format('%d timed / avg %.2f ms / max %.2f ms',p.measured,p.average,p.maximum) or 'timing unavailable')
 end
 lines[#lines+1]='Measures named work scopes only; not total addon CPU or frame rate. Use /fc performance reset for a new sample.'
 return table.concat(lines,'\n')
end
local report,reportText
function Q.RefreshReport()
 if not report or not report:IsShown() then return end
 reportText:SetText(Q.Summary()..'\n\nThese measurements describe this login session since the last reset. Scopes can overlap; do not add them together. Compare the same activity and settings across samples. Missing timings remain unavailable.')
 local height=math.max(170,reportText:GetStringHeight()+8)
 reportText:SetHeight(height);report:SetHeight(height+100)
 if UIParent.GetWidth and UIParent.GetHeight then
  local width,availableHeight=UIParent:GetWidth(),UIParent:GetHeight()
  if type(width)=='number' and type(availableHeight)=='number' and width>32 and availableHeight>32 then
   report:SetScale(math.min(1,(width-32)/620,(availableHeight-32)/(height+100)))
  end
 end
end
function Q.ToggleReport()
 if not report then
  local U=ForeverCompanionInterface
  report=CreateFrame('Frame','ForeverCompanionPerformancePanel',UIParent)
  report:SetSize(620,360);report:SetPoint('CENTER');report:SetClampedToScreen(true);report:SetFrameStrata('DIALOG');report:EnableMouse(true);U.Surface(report)
  local heading=U.Text(report,18);heading:SetPoint('TOPLEFT',18,-15);heading:SetWidth(550);heading:SetText('PERFORMANCE SAMPLE')
  U.CloseButton(report,function() report:Hide() end)
  reportText=U.Text(report,13);reportText:SetPoint('TOPLEFT',18,-53);reportText:SetWidth(584);reportText:SetWordWrap(true);reportText:SetJustifyV('TOP')
  local refresh=U.Button(report);refresh:SetPoint('BOTTOMRIGHT',-18,12);refresh:SetSize(130,26);refresh:SetText('Refresh sample');refresh:SetScript('OnClick',Q.RefreshReport)
  local reset=U.Button(report);reset:SetPoint('BOTTOMLEFT',18,12);reset:SetSize(130,26);reset:SetText('Start new sample');reset:SetScript('OnClick',function() Q.Reset();Q.RefreshReport() end)
  report:Hide()
 end
 report:SetShown(not report:IsShown());Q.RefreshReport()
end
