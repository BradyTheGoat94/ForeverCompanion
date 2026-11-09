-- Independent read-only training UI; upstream reference attribution is in TrainingData.lua.
local T={page=1};ForeverCompanionTraining=T
local root,search,summary,rows,notice,previous,nextPage,counter,filterButton
local cache,trainerOpen=false,false
local currentObserved={}
local function finite(n) return not(issecretvalue and issecretvalue(n)) and type(n)=='number' and n==n and math.abs(n)<math.huge end
local function textValue(s) return not(issecretvalue and issecretvalue(s)) and type(s)=='string' and s~='' and s or nil end
local function read(fn,...)
 if type(fn)~='function' then return end
 local ok,a,b,c,d,e=pcall(fn,...);if ok then return a,b,c,d,e end
end
local function prefs()
 ForeverCompanionDB=ForeverCompanionDB or {}
 if type(ForeverCompanionDB.trainingGuide)~='table' then ForeverCompanionDB.trainingGuide={} end
 local p=ForeverCompanionDB.trainingGuide
 if type(p.ignored)~='table' then p.ignored={} end
 if type(p.observed)~='table' then p.observed={} end
 return p
end
function T.Reference(class,race,faction)
 local data=ForeverCompanionTrainingData;local source=data and data.classes[class];local result={}
 if not source then return result end
 for level,list in pairs(source.spellsByLevel or {}) do for _,r in ipairs(list) do
  if (not r.race or not race or race==r.race) and (not r.faction or not faction or faction==r.faction) then
   local p={};for k,v in pairs(r) do p[k]=v end;p.level=level
   p.eligibilityUnknown=(r.race and not race or r.faction and not faction) and true or false;result[#result+1]=p
  end
 end end
 for id,choices in pairs(data.quests[class] or {}) do
  if race then for _,r in ipairs(choices) do
   local match=false;for _,v in ipairs(r.races or {}) do if v==race then match=true end end
   if match then result[#result+1]={id=id,level=r.level,cost=0,quest=true,quests=r.quests};break end
  end end
 end
 return result
end
function T.Build(entries,context)
 local result,known,byID={},{},{}
 local function check(id)
  if known[id]==nil then
   local k=context.known(id);if issecretvalue and issecretvalue(k) then k=nil end
   known[id]=k==true and 'yes' or (k==false and 'no' or 'unknown')
  end
  return known[id]
 end
 for _,r in ipairs(entries) do byID[r.id]=r;check(r.id) end
 local covered={}
 local function ancestry(id,seen)
  if seen[id] then return end;seen[id]=true
  local r=byID[id];if not r then return end
  for _,p in ipairs(r.requiredIds or {}) do covered[p]=true;ancestry(p,seen) end
 end
 for _,r in ipairs(entries) do if check(r.id)=='yes' then ancestry(r.id,{}) end end
 for _,group in ipairs(context.overriddenGroups or {}) do
  local learned=0
  for index,id in ipairs(group) do if check(id)=='yes' then learned=index end end
  for index=1,learned-1 do covered[group[index]]=true end
 end
 for _,r in ipairs(entries) do
  local p={};for k,v in pairs(r) do p[k]=v end
  local state=check(r.id)
  if state=='yes' then p.state='known';p.status='Known in spellbook'
  elseif covered[r.id] then p.state='known';p.status='Covered by a learned higher rank'
  elseif context.ignored[r.id] then p.state='ignored';p.status='Ignored by you'
  elseif r.quest then p.state='quest';p.status='Quest reward reference · not trainer training'
  elseif finite(context.level) and r.level>context.level then p.state='upcoming';p.status='Upcoming level reference'
  elseif state=='unknown' or not finite(context.level) or r.eligibilityUnknown then p.state='unknown';p.status='Ownership or eligibility unavailable'
  else
   p.state='ready';p.status='Unlearned training reference'
   local reqs={};for _,id in ipairs(r.requiredIds or {}) do reqs[#reqs+1]=id end
   if r.requiredTalentId then reqs[#reqs+1]=r.requiredTalentId end
   for _,id in ipairs(reqs) do if check(id)~='yes' and not covered[id] then p.state='requirements';p.status='Prerequisite / talent needs checking';break end end
   if r.skills and #r.skills>0 then p.state='requirements';p.status='Skill-rank requirement · verify at trainer' end
  end
  result[#result+1]=p
 end
 table.sort(result,function(a,b) if a.level~=b.level then return a.level<b.level end;return a.id<b.id end)
 return result
end
function T.ScanTrainer()
 if not trainerOpen then return false end
 local count=read(GetNumTrainerServices)
 if not finite(count) or count<0 or count>1000 or type(GetTrainerServiceInfo)~='function' then return false end
 currentObserved={}
 local p=prefs();local _,class=read(UnitClass,'player');local records={}
 for _,r in ipairs(T.Reference(class,select(3,read(UnitRace,'player')),read(UnitFactionGroup,'player'))) do records[r.id]=true end
 local name=textValue(read(UnitName,'npc')) or 'Visited trainer'
 for i=1,count do
  -- Forever uses modern return order: name, type, texture, level, subtext.
  local label,state,texture,level,rank=read(GetTrainerServiceInfo,i)
  local tip=C_TooltipInfo and read(C_TooltipInfo.GetTrainerService,i)
  local id=type(tip)=='table' and tip.id
  local spellType=Enum and Enum.TooltipDataType and Enum.TooltipDataType.Spell
  if spellType and type(tip)=='table' and tip.type==spellType and finite(id) and records[id] and textValue(label) and textValue(state) then
   local cost=read(GetTrainerServiceCost,i)
   p.observed[id]={name=name,state=state,cost=finite(cost) and cost>=0 and cost or nil,level=finite(level) and level or nil,rank=textValue(rank),at=read(GetServerTime)}
   currentObserved[id]=p.observed[id]
  end
 end
 cache=nil;T.Refresh();return true
end
function T.Current()
 if cache then return cache end
 local _,class=read(UnitClass,'player');local _,_,race=read(UnitRace,'player');local faction=read(UnitFactionGroup,'player');local p=prefs()
 cache=T.Build(T.Reference(class,race,faction),{level=read(UnitLevel,'player'),ignored=p.ignored,
 overriddenGroups=ForeverCompanionTrainingData and ForeverCompanionTrainingData.classes[class] and ForeverCompanionTrainingData.classes[class].overriddenGroups,known=function(id)
  return ForeverCompanionKnownSpell and ForeverCompanionKnownSpell(id)
 end})
 for _,r in ipairs(cache) do
  local info=C_Spell and read(C_Spell.GetSpellInfo,r.id)
  r.name=type(info)=='table' and textValue(info.name) or ('Spell #'..r.id)
  r.icon=type(info)=='table' and info.iconID or nil
  local observed=p.observed[r.id]
  if type(observed)=='table' and textValue(observed.name) and textValue(observed.state) then r.observation=observed;r.live=trainerOpen and currentObserved[r.id]==observed end
 end
 return cache
end
function T.Filter(records,query,filter)
 local result={};query=type(query)=='string' and query:lower() or ''
 for _,r in ipairs(records) do
  local include=(filter=='available' and r.live and r.observation.state=='available' and r.state~='known') or (filter=='all') or (filter=='missing' and r.state~='known' and r.state~='ignored') or r.state==filter
  if include and (r.name..' '..tostring(r.id)..' '..r.status):lower():find(query,1,true) then result[#result+1]=r end
 end
 return result
end
function T.Money(cost)
 if not finite(cost) or cost<0 then return 'Price unavailable' end
 return ('%dg %ds %dc'):format(math.floor(cost/10000),math.floor(cost/100)%100,math.floor(cost)%100)
end
local function text(parent,x,y,w,size,value)
 local f=ForeverCompanionInterface.Text(parent,size);f:SetPoint('TOPLEFT',x,y);f:SetWidth(w);f:SetText(value or '');return f
end
function T.Refresh()
 if not root or not root:IsShown() then return end
 local p=prefs();local all=T.Current();local found=T.Filter(all,search:GetText(),p.filter or 'missing')
 local pages=math.max(1,math.ceil(#found/7));T.page=math.max(1,math.min(T.page,pages));filterButton:SetText(p.filter or 'missing')
 local counts={};for _,r in ipairs(all) do counts[r.state]=(counts[r.state] or 0)+1 end
 summary:SetText((counts.ready or 0)..' unlearned references · '..(counts.upcoming or 0)..' upcoming · '..(counts.requirements or 0)..' prerequisite checks · '..#found..' matches\nReference prices precede discounts. A level reference does not confirm that a trainer can teach you.')
 for i,row in ipairs(rows) do
  local r=found[(T.page-1)*7+i];row.record=r;row:SetShown(r~=nil)
  if r then
   row.icon:SetTexture(r.icon or 'Interface\\Icons\\INV_Misc_Book_09');row.title:SetText(r.name..' · level '..r.level..' · #'..r.id)
   row.detail:SetText(r.status..' · '..(r.quest and 'Quest' or ('Base '..T.Money(r.cost))))
   row.observed:SetText(r.observation and ('Observed at '..r.observation.name..' · '..r.observation.state..' · '..T.Money(r.observation.cost)..(r.live and ' (current visit)'  or ' (saved visit; recheck)')) or 'Reference only · visit a trainer to record current offerings')
  end
 end
 root.empty:SetShown(#found==0);root.empty:SetText('No entries match this view. Try All or clear the search.\n\nClass data is a credited Forever reference, not a guarantee of complete trainer coverage.')
 previous:SetEnabled(T.page>1);nextPage:SetEnabled(T.page<pages);counter:SetText(T.page..' / '..pages)
end
function T.Toggle()
 if not root then
  local U=ForeverCompanionInterface
  root=CreateFrame('Frame','ForeverCompanionTrainingPanel',UIParent);root:SetSize(760,700);root:SetPoint('CENTER');root:SetFrameStrata('DIALOG');root:SetMovable(true);root:SetClampedToScreen(true);root:EnableMouse(true);U.Surface(root);U.PreparePanel(root,'ForeverCompanionTrainingPanel',760,700)
  local drag=CreateFrame('Frame',nil,root);drag:SetPoint('TOPLEFT');drag:SetSize(710,40);drag:EnableMouse(true);drag:RegisterForDrag('LeftButton');drag:SetScript('OnDragStart',function() root:StartMoving() end);drag:SetScript('OnDragStop',function() root:StopMovingOrSizing() end)
  text(root,18,-13,650,17,'TRAINING GUIDE');U.CloseButton(root,function() root:Hide() end)
  search=U.EditBox(root,'Search spell name or ID');search:SetSize(470,28);search:SetPoint('TOPLEFT',18,-51);search:SetMaxLetters(100);search:HookScript('OnTextChanged',function() T.page=1;T.Refresh() end);search:SetScript('OnEscapePressed',function() root:Hide() end)
  filterButton=U.Button(root);filterButton:SetSize(150,28);filterButton:SetPoint('TOPLEFT',498,-51);filterButton:SetScript('OnClick',function()
   local choices={};for _,pair in ipairs({{'available','Available at current trainer'},{'missing','Missing / upcoming'},{'ready','Unlearned references'},{'upcoming','Upcoming levels'},{'requirements','Prerequisite checks'},{'quest','Quest rewards'},{'unknown','Unknown ownership'},{'known','Known / superseded'},{'ignored','Ignored'},{'all','All entries'}}) do local key,label=pair[1],pair[2];choices[#choices+1]={label=label,action=function() prefs().filter=key;T.page=1;T.Refresh() end} end;U.Menu(filterButton,'TRAINING VIEW',choices)
  end)
  local refresh=U.Button(root);refresh:SetSize(84,28);refresh:SetPoint('TOPRIGHT',-18,-51);refresh:SetText('Refresh');refresh:SetScript('OnClick',function() cache=nil;if trainerOpen then T.ScanTrainer() end;T.Refresh() end)
  summary=text(root,18,-92,724,11,'');summary:SetHeight(36);summary:SetWordWrap(true);rows={}
  for i=1,7 do
   local row=CreateFrame('Button',nil,root);row:SetSize(724,60);row:SetPoint('TOPLEFT',18,-143-(i-1)*65);row:RegisterForClicks('RightButtonUp');U.Surface(row)
   row.icon=row:CreateTexture(nil,'ARTWORK');row.icon:SetSize(30,30);row.icon:SetPoint('LEFT',8,0)
   row.title=text(row,48,-6,665,12,'');row.detail=text(row,48,-25,665,10,'');row.observed=text(row,48,-43,665,9,'')
   row:SetScript('OnEnter',function(self) if GameTooltip and self.record then GameTooltip:SetOwner(self,'ANCHOR_RIGHT');GameTooltip:SetSpellByID(self.record.id);GameTooltip:AddLine(self.record.status,.8,.85,.9,true);for _,id in ipairs(self.record.requiredIds or {}) do GameTooltip:AddLine('Prerequisite spell #'..id,.8,.85,.9,true) end;for _,req in ipairs(self.record.skills or {}) do GameTooltip:AddLine('Skill #'..req.skill..' rank '..req.level..' required',.9,.8,.5,true) end;if self.record.quest then GameTooltip:AddLine('Quest rewards: '..table.concat(self.record.quests or {},', '),.8,.85,.9,true) end;GameTooltip:AddLine('Right-click to ignore / restore this reference. Training must be purchased manually at a trainer.',.9,.75,.4,true);GameTooltip:Show() end end)
   row:SetScript('OnLeave',function() if GameTooltip then GameTooltip:Hide() end end)
   row:SetScript('OnClick',function(self) if self.record then local id=self.record.id;U.Menu(self,'TRAINING REFERENCE',{{label=prefs().ignored[id] and 'Restore entry' or 'Ignore entry',action=function() prefs().ignored[id]=not prefs().ignored[id];cache=nil;T.Refresh() end}}) end end);rows[i]=row
  end
  root.empty=text(root,36,-180,688,14,'');root.empty:SetHeight(120);root.empty:SetWordWrap(true)
  notice=text(root,18,-613,724,10,"Forever reference data adapted from What's Training? (MIT). Not affiliated; no second addon required.");notice:SetHeight(30);notice:SetWordWrap(true)
  previous=U.Button(root);previous:SetSize(90,26);previous:SetPoint('BOTTOMLEFT',18,16);previous:SetText('Previous');previous:SetScript('OnClick',function() T.page=T.page-1;T.Refresh() end)
  nextPage=U.Button(root);nextPage:SetSize(90,26);nextPage:SetPoint('BOTTOMRIGHT',-18,16);nextPage:SetText('Next');nextPage:SetScript('OnClick',function() T.page=T.page+1;T.Refresh() end)
  local trainers=U.Button(root);trainers:SetSize(174,26);trainers:SetPoint('BOTTOMLEFT',120,16);trainers:SetText('Find reported trainers');trainers:SetScript('OnClick',function() notice:SetText(ForeverCompanionMapTools.Nearest('trainer',trainers)) end)
  counter=text(root,320,-650,120,11,'');counter:ClearAllPoints();counter:SetPoint('BOTTOM',0,22);root:Hide()
 end
 if root:IsShown() then root:Hide() else cache=nil;root:Show();T.Refresh() end
end
local events=CreateFrame('Frame')
for _,event in ipairs({'TRAINER_SHOW','TRAINER_UPDATE','TRAINER_CLOSED','SPELLS_CHANGED','PLAYER_LEVEL_UP','PLAYER_ENTERING_WORLD'}) do events:RegisterEvent(event) end
events:SetScript('OnEvent',function(_,event)
 cache=nil
 if event=='TRAINER_SHOW' then currentObserved={};trainerOpen=true;T.ScanTrainer()
 elseif event=='TRAINER_CLOSED' then trainerOpen=false;currentObserved={}
 elseif event=='TRAINER_UPDATE' and trainerOpen then T.ScanTrainer() end
 T.Refresh()
end)
