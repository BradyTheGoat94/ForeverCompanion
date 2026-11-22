-- Login-session observations. XP is sampled, never inferred from quest rewards.
local S={limit=10}
ForeverCompanionSessionProgress=S
local state,root,pauseButton,historyButton,view
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
function S.Refresh()
 if not root or not root:IsShown() then return end
 local snapshot=view or S.Snapshot()
 root.snapshot=snapshot
 local value={S.Duration(snapshot.seconds),string.format('%.0f',snapshot.xp or 0),
  snapshot.rate and string.format('%.0f',snapshot.rate) or 'Unavailable',snapshot.turnins or 0,
  (snapshot.rewardXPKnown or 0)>0 and (snapshot.rewardXP or 0)..' XP' or 'Not reported',
  (snapshot.moneyKnown or 0)>0 and ForeverCompanionQuestHistory.Money(snapshot.money) or 'Not reported'}
 for i,v in ipairs(value) do root.metrics[i].value:SetText(v) end
 for i,row in ipairs(root.rows) do
  local entry=(snapshot.recent or {})[i]
  row:SetShown(type(entry)=='table')
  if type(entry)=='table' then
   row.title:SetText(type(entry.title)=='string' and entry.title or 'Quest turn-in')
   row.xp:SetText(finite(entry.xp) and entry.xp..' XP' or '-')
   row.money:SetText(finite(entry.money) and ForeverCompanionQuestHistory.Money(entry.money) or '-')
  end
 end
 local count=math.min(#root.rows,#(snapshot.recent or {}))
 root.empty:SetShown(count==0)
 root.qualityFrame:SetShown(snapshot.clockGap==true or (snapshot.gaps or 0)>0)
 local height=286+math.max(2,count)*28
 if root:GetHeight()~=height then root:SetHeight(height);ForeverCompanionInterface.FitPanel(root,660,height) end
 root.heading:SetText(view and 'Previous leveling session' or 'Leveling session')
 root.headingState:SetText(view and 'Saved' or snapshot.paused and 'Paused' or 'Tracking')
 pauseButton:SetEnabled(view==nil);pauseButton:SetText(state and state.paused and 'Resume tracking' or 'Pause tracking')
 historyButton:SetText(view and 'Return to current' or 'Previous sessions')
end
function S.Toggle()
 if not root then
  local U=ForeverCompanionInterface
  local name='ForeverCompanionSessionPanel'
  root=CreateFrame('Frame',name,UIParent,'BackdropTemplate');root:SetSize(660,454);root:SetPoint('CENTER');root:SetFrameStrata('DIALOG')
  U.Surface(root);U.PreparePanel(root,name,660,454);U.CloseButton(root,function() root:Hide() end)
  root:SetScript('OnEvent',function(self) U.FitPanel(self,660,self:GetHeight()) end)
  local function label(parent,x,y,w,size)
   local t=U.Text(parent,size);t:SetPoint('TOPLEFT',x,y);t:SetWidth(w);return t
  end
  root.heading=label(root,18,-13,450,20)
  root.headingState=label(root,500,-16,102,12);root.headingState:SetTextColor(unpack(U.palette.accent));root.headingState:SetJustifyH('RIGHT')
  root.metrics={}
  local captions={'Time tracked','Observed XP','XP per hour','Turn-ins'}
  local explanations={'Active tracking time since login or reset.',
   'XP observed from character progress. Reported quest rewards are tracked separately.',
   'Requires 60 seconds of complete samples with positive XP gains.',
   'Quest completions observed through turn-in events.'}
  for i,caption in ipairs(captions) do root.metrics[i]=U.MetricTile(root,18+(i-1)*159,-53,147,caption,explanations[i]) end
  root.metrics[5]=U.MetricTile(root,18,-125,306,'Reported quest XP',function()
   return (root.snapshot and root.snapshot.rewardXPKnown or 0)..' turn-ins reported XP rewards.'
  end)
  root.metrics[6]=U.MetricTile(root,336,-125,306,'Reported quest money',function()
   return (root.snapshot and root.snapshot.moneyKnown or 0)..' turn-ins reported money rewards.'
  end)
  label(root,18,-202,390,13):SetText('Recent quest turn-ins')
  label(root,457,-204,78,11):SetText('Reward XP')
  label(root,550,-204,92,11):SetText('Money')
  root.rows={}
  for i=1,6 do
   local row=CreateFrame('Frame',nil,root);row:SetPoint('TOPLEFT',18,-225-(i-1)*28);row:SetSize(624,25)
   U.Surface(row,{background=U.palette.surface,flat=true})
   row.title=label(row,8,-4,420,12)
   row.xp=label(row,439,-4,83,12)
   row.money=label(row,532,-4,85,12)
   row:EnableMouse(true);U.SetHoverHelp(row,'Turn-in',function() return row.title:GetText() end)
   root.rows[i]=row
  end
  root.empty=label(root,28,-236,608,13);root.empty:SetText('No turn-ins recorded')
  local indicator=CreateFrame('Frame',nil,root)
  indicator:SetPoint('BOTTOMLEFT',18,40);indicator:SetSize(155,22);indicator:EnableMouse(true)
  root.qualityFrame=indicator
  local quality=label(indicator,0,0,150,11);quality:SetText('Partial samples');quality:SetTextColor(unpack(U.palette.accent))
  U.SetHoverHelp(indicator,'Sample quality','Some time or XP samples are unavailable. Observed XP is partial and the rate is suppressed.')
  local function action(x,w,text,tip,callback)
   local b=U.Button(root);b:SetSize(w,28);b:SetPoint('BOTTOMLEFT',x,12);b:SetText(text)
   U.SetHoverHelp(b,text,tip);b:SetScript('OnClick',callback)
   return b
  end
  pauseButton=action(18,190,'Pause / resume','Exclude time and rewards while tracking is paused.',function() S.SetPaused(not state.paused) end)
  historyButton=action(220,200,'Previous sessions','Review a manually ended session. Up to 10 are saved.',function()
   if view then view=nil;S.Refresh();return end
   local entries={}
   for _,p in ipairs(archive()) do
    if type(p)=='table' and finite(p.seconds) and finite(p.xp) and type(p.recent)=='table' then
     local saved=p;entries[#entries+1]={label=S.Duration(p.seconds)..'  /  '..p.xp..' XP',action=function() view=saved;S.Refresh() end}
    end
   end
   if #entries==0 then entries[1]={label='No ended sessions yet',enabled=false} end
   U.PagedMenu(historyButton,'Previous sessions',entries,nil,260)
  end)
  action(432,210,'End & start new session','Save this session and start a fresh one.',function(self)
   U.Menu(self,'End current session?',{{label='Save summary and start new',action=S.NewSession},{label='Cancel',action=function() end}})
  end)
  local elapsed=0
  root:SetScript('OnUpdate',function(_,dt) elapsed=elapsed+dt;if elapsed>=1 then elapsed=0;S.Refresh() end end)
  root:Hide()
 end
 if not state then S.Start() end
 root:SetShown(not root:IsShown());S.Refresh()
end
local events=CreateFrame('Frame')
for _,event in ipairs({'PLAYER_ENTERING_WORLD','PLAYER_XP_UPDATE'}) do pcall(events.RegisterEvent,events,event) end
events:SetScript('OnEvent',function(_,event,unit)
 if event=='PLAYER_ENTERING_WORLD' or unit=='player' then S.Sample();S.Refresh() end
end)
