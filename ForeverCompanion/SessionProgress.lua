-- Login-session observations. XP is sampled, never inferred from quest rewards.
local S={limit=10}
ForeverCompanionSessionProgress=S
local state,root,body,pauseButton,historyButton,view
local function finite(n) return not (issecretvalue and issecretvalue(n)) and type(n)=='number' and n==n and n>=0 and n<math.huge end
local function read(fn,...)
 if type(fn)~='function' then return end
 local ok,a=pcall(fn,...);if ok then return a end
end
local function clock() local n=read(GetTime);if finite(n) then return n end end
local function xpSample()
 local level,xp,maximum=read(UnitLevel,'player'),read(UnitXP,'player'),read(UnitXPMax,'player')
 if finite(level) and level>=1 and finite(xp) and finite(maximum) and maximum>0 and xp<=maximum then return {level=level,xp=xp,maximum=maximum} end
end
function S.Delta(before,after)
 for _,sample in ipairs({before or false,after or false}) do
  if type(sample)~='table' or not finite(sample.level) or not finite(sample.xp) or not finite(sample.maximum) or sample.maximum<=0 or sample.xp>sample.maximum then return end
 end
 if after.level==before.level and after.maximum==before.maximum and after.xp>=before.xp then return after.xp-before.xp end
 if after.level==before.level+1 then return before.maximum-before.xp+after.xp end
end
local function tick()
 local now=clock()
 if now and state.lastClock then
  if now>=state.lastClock then if not state.paused then state.seconds=state.seconds+now-state.lastClock end
  else state.clockGap=true end
 elseif not now then state.clockGap=true end
 state.lastClock=now
end
local function archive()
 ForeverCompanionDB=ForeverCompanionDB or {}
 if type(ForeverCompanionDB.sessionArchive)~='table' then ForeverCompanionDB.sessionArchive={} end
 return ForeverCompanionDB.sessionArchive
end
function S.Start()
 state={seconds=0,xp=0,gaps=0,turnins=0,rewardXP=0,rewardXPKnown=0,money=0,moneyKnown=0,recent={},lastClock=clock(),baseline=xpSample()}
 state.clockGap=state.lastClock==nil;view=nil
 if not state.baseline then state.gaps=1 end
end
function S.Sample()
 if not state then S.Start();return end
 tick()
 local sample=xpSample()
 if not state.paused then
  local delta=S.Delta(state.baseline,sample)
  if delta then state.xp=state.xp+delta
  elseif state.baseline or not sample then state.gaps=state.gaps+1 end
 end
 state.baseline=sample
end
function S.Snapshot()
 if not state then S.Start() end
 tick()
 local result={}
 for _,key in ipairs({'seconds','xp','gaps','turnins','rewardXP','rewardXPKnown','money','moneyKnown','paused','clockGap'}) do result[key]=state[key] end
 result.recent={}
 for i,entry in ipairs(state.recent) do result.recent[i]={title=entry.title,xp=entry.xp,money=entry.money} end
 result.rate=not state.clockGap and state.gaps==0 and state.seconds>=60 and state.xp>0 and state.xp*3600/state.seconds or nil
 return result
end
function S.RecordQuest(entry)
 if type(entry)~='table' then return end
 if not state then S.Start() end
 tick()
 if state.paused then return end
 state.turnins=state.turnins+1
 if finite(entry.xp) then state.rewardXP=state.rewardXP+entry.xp;state.rewardXPKnown=state.rewardXPKnown+1 end
 if finite(entry.money) then state.money=state.money+entry.money;state.moneyKnown=state.moneyKnown+1 end
 local title=not (issecretvalue and issecretvalue(entry.title)) and type(entry.title)=='string' and entry.title or 'Quest turn-in'
 table.insert(state.recent,1,{title=title,xp=finite(entry.xp) and entry.xp or nil,money=finite(entry.money) and entry.money or nil})
 while #state.recent>6 do table.remove(state.recent) end
end
function S.SetPaused(value)
 if type(value)~='boolean' then return false end
 S.Sample();state.paused=value;state.baseline=xpSample();state.lastClock=clock();S.Refresh();return true
end
function S.NewSession()
 S.Sample();local snapshot=S.Snapshot()
 if snapshot.seconds>0 or snapshot.turnins>0 or snapshot.xp>0 then
  snapshot.paused=nil;snapshot.at=read(GetServerTime)
  local saved=archive();table.insert(saved,1,snapshot);while #saved>S.limit do table.remove(saved) end
 end
 S.Start();S.Refresh()
end
function S.Duration(seconds)
 if not finite(seconds) then return 'Unknown' end
 return string.format('%d:%02d:%02d',math.floor(seconds/3600),math.floor(seconds/60)%60,math.floor(seconds)%60)
end
function S.Lines(snapshot)
 local p=snapshot or S.Snapshot()
 local lines={'TIME TRACKED   '..S.Duration(p.seconds)..(p.paused and ' · Paused' or ''),
  'OBSERVED XP   '..string.format('%.0f',p.xp or 0),
  'XP PER HOUR   '..(p.rate and string.format('%.0f',p.rate) or 'Unavailable — needs 60 seconds of complete samples'),
  'QUEST TURN-INS   '..(p.turnins or 0),
  'REPORTED QUEST REWARDS   '..(p.rewardXP or 0)..' XP ('..(p.rewardXPKnown or 0)..' reported) · '..ForeverCompanionQuestHistory.Money(p.money or 0)..' ('..(p.moneyKnown or 0)..' reported)'}
 if p.clockGap or (p.gaps or 0)>0 then lines[#lines+1]='Some time or XP samples were unavailable. Observed XP is partial; no rate is inferred.' end
 lines[#lines+1]='RECENT OBSERVED TURN-INS'
 for _,entry in ipairs(p.recent or {}) do lines[#lines+1]='• '..entry.title..' · '..(entry.xp and (entry.xp..' XP') or 'XP not reported') end
 if #(p.recent or {})==0 then lines[#lines+1]='No turn-ins recorded in this session yet.' end
 return lines
end
function S.Refresh()
 if not root or not root:IsShown() then return end
 local snapshot=view or S.Snapshot()
 local lines=S.Lines(snapshot);local details={}
 for i=5,#lines do details[#details+1]=lines[i] end
 if not snapshot.rate and not snapshot.clockGap and snapshot.gaps==0 then details[#details+1]='XP/hour appears after at least 60 seconds with observed XP gains.' end
 body:SetText(table.concat(details,'\n\n'))
 local values={S.Duration(snapshot.seconds),string.format('%.0f',snapshot.xp or 0),snapshot.rate and string.format('%.0f',snapshot.rate) or 'Unavailable',snapshot.turnins or 0}
 for i,value in ipairs(values) do root.metrics[i]:SetText(value) end
 root.heading:SetText(view and 'PREVIOUS LEVELING SESSION' or (snapshot.paused and 'MY LEVELING SESSION · PAUSED' or 'MY LEVELING SESSION'))
 pauseButton:SetEnabled(view==nil);pauseButton:SetText(state and state.paused and 'Resume tracking' or 'Pause tracking')
 historyButton:SetText(view and 'Return to current' or 'Previous sessions')
end
function S.Toggle()
 if not root then
  local U=ForeverCompanionInterface
  root=CreateFrame('Frame','ForeverCompanionSessionPanel',UIParent);root:SetSize(660,590);root:SetPoint('CENTER');root:SetClampedToScreen(true);root:SetFrameStrata('DIALOG');U.Surface(root)
  root:SetMovable(true);root:EnableMouse(true)
  local drag=CreateFrame('Frame',nil,root);drag:SetPoint('TOPLEFT',0,0);drag:SetSize(615,40);drag:EnableMouse(true);drag:RegisterForDrag('LeftButton')
  drag:SetScript('OnDragStart',function() root:StartMoving() end);drag:SetScript('OnDragStop',function() root:StopMovingOrSizing() end)
  local heading=U.Text(root,18);heading:SetPoint('TOPLEFT',18,-14);heading:SetWidth(580);heading:SetText('MY LEVELING SESSION')
  root.heading=heading
  U.CloseButton(root,function() root:Hide() end)
  root.metrics={}
  for i,label in ipairs({'TIME TRACKED','OBSERVED XP','XP / HOUR','QUEST TURN-INS'}) do
   local card=CreateFrame('Frame',nil,root);card:SetSize(147,66);card:SetPoint('TOPLEFT',18+(i-1)*159,-55);U.Surface(card)
   local caption=U.Text(card,10,U.palette.muted);caption:SetPoint('TOPLEFT',10,-9);caption:SetWidth(127);caption:SetText(label)
   local value=U.Text(card,17,U.palette.accent);value:SetPoint('TOPLEFT',10,-32);value:SetWidth(127);value:SetHeight(23);root.metrics[i]=value
  end
  body=U.Text(root,12);body:SetPoint('TOPLEFT',18,-141);body:SetWidth(624);body:SetHeight(350);body:SetWordWrap(true);body:SetJustifyV('TOP')
  local hint=U.Text(root,10);hint:SetPoint('BOTTOMLEFT',18,54);hint:SetWidth(624);hint:SetHeight(28);hint:SetWordWrap(true);hint:SetText('Tracks observed activity since login or reset. Reload starts a new session. Pause excludes time and rewards. Keeps 10 manually ended sessions.')
  pauseButton=U.Button(root);pauseButton:SetSize(190,28);pauseButton:SetPoint('BOTTOMLEFT',18,16);pauseButton:SetScript('OnClick',function() S.SetPaused(not state.paused) end)
  historyButton=U.Button(root);historyButton:SetSize(200,28);historyButton:SetPoint('BOTTOMLEFT',220,16)
  historyButton:SetScript('OnClick',function()
   if view then view=nil;S.Refresh();return end
   local entries={}
   for i,p in ipairs(archive()) do
    if type(p)=='table' and finite(p.seconds) and finite(p.xp) and type(p.recent)=='table' then
     local saved=p;entries[#entries+1]={label=i..'. '..S.Duration(p.seconds)..' · '..p.xp..' XP',action=function() view=saved;S.Refresh() end}
    end
   end
   if #entries==0 then entries[1]={label='No ended sessions yet',enabled=false} end
   U.Menu(historyButton,'PREVIOUS SESSIONS',entries)
  end)
  local reset=U.Button(root);reset:SetSize(210,28);reset:SetPoint('BOTTOMRIGHT',-18,16);reset:SetText('End & start new session')
  reset:SetScript('OnClick',function() U.Menu(reset,'END CURRENT SESSION?',{{label='Save summary and start new',action=S.NewSession},{label='Cancel',action=function() end}}) end)
  local elapsed=0;root:SetScript('OnUpdate',function(_,dt) elapsed=elapsed+dt;if elapsed>=1 then elapsed=0;S.Refresh() end end)
  root:Hide()
 end
 if not state then S.Start() end
 if UIParent.GetWidth and UIParent.GetHeight then
  local w,h=UIParent:GetWidth(),UIParent:GetHeight()
  if finite(w) and finite(h) and w>32 and h>32 then root:SetScale(math.min(1,(w-32)/660,(h-32)/590)) end
 end
 root:SetShown(not root:IsShown());S.Refresh()
end
local events=CreateFrame('Frame')
for _,event in ipairs({'PLAYER_ENTERING_WORLD','PLAYER_XP_UPDATE'}) do pcall(events.RegisterEvent,events,event) end
events:SetScript('OnEvent',function(_,event,unit)
 if event=='PLAYER_ENTERING_WORLD' or unit=='player' then S.Sample();S.Refresh() end
end)
