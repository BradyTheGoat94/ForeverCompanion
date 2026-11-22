-- Slot overview, searchable candidates, persistent hunt log and explainable comparisons.
local W={offset=0,view='discover',selected=nil,statPage=1}
ForeverCompanionGearFinderWorkspace=W
local G=ForeverCompanionGearFinder
local V=ForeverCompanionGearVisuals
local detailState,statRows,statHeader,weightLabels,weightSaveButtons
statRows={};weightLabels={};weightSaveButtons={}
local root,summary,counter,search,scrollBar,listArea,revealButton,dungeonButton,readyButton,armorButton,upgradeButton,profileButton,notice,empty
local rows,slots,tabs,weightBoxes={},{},{},{}
local detail,detailTitle,detailMeta,detailScore,equippedText,sourceText,statText,saveButton,trackButton,bossButton,sourceButton,statButton,weightPanel,weightName
local sourceIndex=1
local worker,currentForAction
local cachedKey,cachedResults,cachedStats,cachedScope
local loadElapsed=0
local filtersButton
local function text(parent,x,y,width,size,value,height)
 local f=ForeverCompanionInterface.Text(parent,size);f:SetPoint('TOPLEFT',x,y);f:SetWidth(width);f:SetText(value or '')
 if height then f:SetHeight(height);f:SetWordWrap(true);f:SetJustifyV('TOP') end;return f
end
local function button(parent,x,y,width,label,action,height)
 local b=ForeverCompanionInterface.Button(parent,V.Palette('discover'));b:SetPoint('TOPLEFT',x,y);b:SetSize(width,height or 28);b:SetText(label);b:SetScript('OnClick',action);return b
end
local function tell(message) if notice then notice:SetText(message or '') end end
local function showGearTooltip(owner,row)
 if not row or W.searchPending then return end
 local lines={}
 for _,stat in ipairs(G.Breakdown(row)) do
  if stat.candidate>0 then lines[#lines+1]='+'..stat.candidate..' '..stat.name end
 end
 ForeverCompanionLoot.ShowItemTooltip(owner,row.record,row.info,lines)
end
local function hideGearTooltip(owner)
 if GameTooltip and (not GameTooltip.IsOwned or GameTooltip:IsOwned(owner)) then GameTooltip:Hide() end
end
local function hover(frame,heading,body)
 frame:EnableMouse(true);frame:SetScript('OnEnter',function(self)
  if GameTooltip then GameTooltip:SetOwner(self,'ANCHOR_RIGHT');GameTooltip:SetText(type(heading)=='function' and heading() or heading);GameTooltip:AddLine(type(body)=='function' and body() or body,.8,.85,.9,true);GameTooltip:Show() end
 end);frame:SetScript('OnLeave',function() if GameTooltip then GameTooltip:Hide() end end)
end
local sourceChoice
local function source(row)
 if not row then return nil end
 local choice=sourceChoice and sourceChoice.itemID==row.record.itemID and sourceChoice or row.record
 for i,r in ipairs(row.sources) do if r.dungeon==choice.dungeon and r.boss==choice.boss then sourceIndex=i;return r end end
 sourceIndex=math.max(1,math.min(sourceIndex,#row.sources));return row.sources[sourceIndex]
end
local function refreshTracker() if ForeverCompanionGearHunts then ForeverCompanionGearHunts.Refresh() end end
local function handoff()
 local old=source(W.current);local current=currentForAction();local s=source(current)
 if not s or s.unavailable or (s.reference and not s.questID) or not old then return end
 if s.dungeon~=old.dungeon or s.boss~=old.boss then tell('Source changed. Select it again before opening the journal.');return end
 if s.questID then if ForeverCompanionOpenQuestGuide(s.questID) then root:Hide() else tell('Quest is not in your live log. Review this reward source in game.') end;return end
 local guide=ForeverCompanionBossGuideWorkspace
 if not guide or not guide.Open(s.dungeon,s.boss) then
  tell('Boss guide unavailable for this source.')
 elseif guide.root.Raise then
  guide.root:Raise()
 end
end
function W.Select(itemID)
 W.selected=itemID;W.statPage=1;sourceIndex=1;sourceChoice=nil;W.Refresh()
end
local function renderDetail(row)
 W.current=row;detail:SetShown(row~=nil)
 if not row then return end
 local s=source(row);local info=row.info
 detailTitle:SetText((row.rank and ('#'..row.rank..'  ') or '')..row.record.item);detailTitle:SetTextColor(unpack(V.Quality(info and info.quality)))
 V.Tint(detail.iconBorder,V.Quality(info and info.quality))
 local state,kind=V.State(row);detailState:SetText(row.rank and ('RANK #'..row.rank..' / '..row.rankCount..' · '..state) or state);detailState:SetTextColor(unpack(V.Palette(kind).accent))
 V.Tint(detail.scoreBand,{V.Palette(kind).accent[1]*.12+.03,V.Palette(kind).accent[2]*.12+.04,V.Palette(kind).accent[3]*.12+.07,1})
 detailMeta:SetText(row.slot[1]..' · slot '..row.slot[2]..' · Item #'..row.record.itemID..'\n'..(info and ((info.subkind or 'Type unknown')..' · Level '..tostring(info.required or '?')..' · Use: '..(row.usable==true and 'yes' or row.usable==false and 'no' or 'unchecked')) or 'Waiting for client item data'))
 detailScore:SetText(row.reason)
 detailScore:SetTextColor(unpack(V.Palette(kind).accent))
 equippedText:SetText('EQUIPPED IN THIS SLOT\n'..(row.baseline and row.baseline.name or 'Empty / data unavailable')..'\n'..(row.baseline and row.baseline.score and ('Score '..G.Points(row.baseline.score)) or 'Score unavailable')..(info and info.score and ('   →   Candidate '..G.Points(info.score)) or ''))
 sourceText:SetText('Where to get it · '..s.dungeon..'\n'..s.boss..'\n'..s.status..'\n'..(row.owned==nil and 'Inventory scan unavailable' or row.owned>0 and 'Currently owned: '..row.owned or row.completed and 'Previously acquired (observed)' or 'Not observed in carried inventory'))
 local breakdown=G.Breakdown(row);local pages=math.max(1,math.ceil(#breakdown/7));W.statPage=math.min(W.statPage,pages)
 for i,fields in ipairs(statRows) do
  local stat=breakdown[(W.statPage-1)*7+i]
  for _,field in ipairs(fields) do field:SetShown(stat~=nil) end
  if stat then
   fields[1]:SetText(stat.name);fields[2]:SetText((stat.equipped and string.format('%g',stat.equipped) or '?')..' > '..string.format('%g',stat.candidate))
   fields[3]:SetText(stat.points and G.Points(stat.points,true) or '?')
   fields[3]:SetTextColor(unpack(stat.points and stat.points>0 and V.colors.green or stat.points and stat.points<0 and V.colors.coral or V.colors.muted))
  end
 end
 statText:SetText(#breakdown==0 and 'No supported stats reported yet.' or '')
 statButton:SetText('More stats ('..W.statPage..'/'..pages..')');statButton:SetEnabled(pages>1)
 V.Style(saveButton,row.saved and 'hunts' or 'upgrade',not row.saved);V.Style(trackButton,'hunts',row.tracked);V.Style(bossButton,'discover',false)
 sourceButton:SetText('Source '..sourceIndex..' / '..#row.sources);sourceButton:SetEnabled(#row.sources>1)
 saveButton:SetText(row.saved and 'Remove hunt' or 'Save hunt');trackButton:SetText(row.tracked and (G.Settings().trackerHidden and 'Show tracker' or 'Unpin hunt') or 'Pin hunt');trackButton:SetEnabled(row.saved and not row.completed and not row.unavailable)
 bossButton:SetText(s.questID and 'Open quest details' or s.reference and 'Crafting source shown' or 'View source boss');bossButton:SetEnabled(not s.unavailable and (not s.reference or s.questID~=nil))
 detail.icon:SetTexture(ForeverCompanionLoot.ItemIcon(row.record))
end
-- Preserve the first surviving visible identity when a background scan reorders
-- or removes rows. Explicit filter/view resets still start at the top.
function W.AnchorOffset(before,after,offset)
 local maximum=math.max(0,#after-6);offset=math.max(0,math.floor(offset or 0))
 local positions={};for i,r in ipairs(after) do positions[r.record.itemID]=i end
 for i=offset+1,#before do local found=positions[before[i].record.itemID];if found then return math.min(maximum,found-1) end end
 for i=math.min(offset,#before),1,-1 do local found=positions[before[i].record.itemID];if found then return math.min(maximum,found-1) end end
 return math.min(maximum,offset)
end
function W.Refresh()
 if not root or not root:IsShown() then return end
 W.searchPending=false;W.dirty=false
 local cfg=G.Settings();local isWeights=W.view=='weights';weightPanel:SetShown(isWeights)
 W.listHeading:SetShown(not isWeights);W.listHeading:SetText(W.view=='hunts' and 'SAVED HUNTS' or W.view=='completed' and 'ACQUIRED GEAR' or 'UPGRADE CANDIDATES')
 for view,b in pairs(tabs) do V.Style(b,view,W.view==view) end
 local active,done=G.HuntCounts();tabs.hunts:SetText('My hunts ('..active..')');tabs.completed:SetText('Acquired ('..done..')')
 profileButton:SetShown(isWeights);profileButton:SetText('Weights: '..cfg.profile);V.Style(profileButton,'weights',W.view=='weights')
 V.Style(readyButton,'discover',cfg.ready);V.Style(armorButton,'discover',cfg.matchArmor);V.Style(upgradeButton,'upgrade',cfg.bestNow~=false)
 for _,b in ipairs(weightSaveButtons) do V.Style(b,'weights',false) end
 for _,box in ipairs(weightBoxes) do if not box:HasFocus() then box:SetText(tostring(cfg.weights[box.statIndex])) end end
 local browse=W.view=='discover'
 search:SetShown(not isWeights);dungeonButton:SetShown(not isWeights);readyButton:Hide();armorButton:Hide();upgradeButton:SetShown(browse);filtersButton:SetShown(browse)
 if isWeights then
  summary:SetText('Set your own priorities. Each item score is the sum of reported stat amounts × these weights. Enter applies a value (0–100).')
  detail:Hide();empty:Hide();scrollBar:Hide();listArea:Hide();revealButton:Hide();counter:Hide();for _,row in ipairs(rows) do row:Hide() end
  return
 end
 local options={slot=cfg.slot,query=search:GetText(),dungeon=cfg.dungeon,saved=W.view=='hunts',active=W.view=='hunts',completed=W.view=='completed',ready=browse and cfg.ready,matchArmor=browse and cfg.matchArmor,bestNow=browse and cfg.bestNow~=false}
 local scope=table.concat({W.view,tostring(cfg.slot),search:GetText(),cfg.dungeon,tostring(options.ready),tostring(options.matchArmor),tostring(options.bestNow)},'\031')
 local key,context=G.SnapshotKey(options)
 if key~=cachedKey then
  local results,_,_,stats=G.Build(options,context)
  if cachedResults and scope==cachedScope and (W.offset or 0)>0 then W.offset=W.AnchorOffset(cachedResults,results,W.offset) end
  if GameTooltip then GameTooltip:Hide() end
  cachedKey=key;cachedResults=results;cachedStats=stats;cachedScope=scope
 end
 local results,stats=cachedResults,cachedStats
 W.results=results;W.stats=stats
 local maximum=math.max(0,#results-6);W.offset=math.max(0,math.min(maximum,W.offset or 0))
 summary:SetText(#results..' items · '..(options.bestNow and 'Biggest estimated upgrades first' or browse and 'Ranked by equipment slot' or W.view=='hunts' and 'Saved gear hunts' or 'Acquired gear')..(stats.loading>0 and (' · '..stats.loading..' loading') or ''))
 dungeonButton:SetText(cfg.dungeon~='' and cfg.dungeon or 'All dungeons');readyButton:SetText(cfg.ready and 'Within my level' or 'Include future levels')
 armorButton:SetText(cfg.matchArmor and 'Match worn armor' or 'All armor types');upgradeButton:SetText(cfg.bestNow~=false and 'Switch to Browse' or 'Switch to Best Now')
 for index,b in pairs(slots) do
  local label=index==0 and 'All equipment' or (G.slots[index][1]..((index==10 or index==12) and ' 1' or (index==11 or index==13) and ' 2' or ''))
  b:SetText(label);V.Style(b,'discover',index==cfg.slot)
  if index>0 then b:GetFontString():ClearAllPoints();b:GetFontString():SetPoint('BOTTOM',b,'BOTTOM',0,4);b:GetFontString():SetJustifyH('CENTER');b.slotIcon:SetTexture(G.Call(GetInventoryItemTexture,'player',G.slots[index][2]) or ('Interface\\Icons\\'..V.slotIcons[index])) end
 end
 listArea:Show();scrollBar:SetShown(maximum>0);counter:Show();W.syncScroll=true;scrollBar:SetMinMaxValues(0,maximum);scrollBar:SetValue(W.offset);W.syncScroll=false;counter:SetText(#results==0 and 'No results' or ('Items '..(W.offset+1)..'–'..math.min(#results,W.offset+6)..' of '..#results))
 local selected,selectedIndex
 for i,r in ipairs(results) do if r.record.itemID==W.selected then selected=r;selectedIndex=i end end
 if not selected then selectedIndex=W.offset+1;selected=results[selectedIndex];W.selected=selected and selected.record.itemID;sourceIndex=1;sourceChoice=nil;W.statPage=1 end
 local selectionVisible=selectedIndex and selectedIndex>W.offset and selectedIndex<=W.offset+6
 revealButton:Show();revealButton:SetText(not selected and 'Select an item' or selectionVisible and 'Selected visible' or 'Find selected');revealButton:SetEnabled(selected~=nil and not selectionVisible)
 for i,row in ipairs(rows) do
  local r=results[W.offset+i];row.record=r;row:SetShown(r~=nil);row:SetEnabled(true)
  if r then
   row.icon:SetTexture(ForeverCompanionLoot.ItemIcon(r.record));row.title:SetText((r.rank and ('#'..r.rank..'  ') or '')..r.record.item);row.title:SetTextColor(unpack(V.Quality(r.info and r.info.quality)));V.Tint(row.iconBorder,V.Quality(r.info and r.info.quality))
   row.meta:SetText(r.slot[1]..' · '..r.record.dungeon..(#r.sources>1 and (' + '..(#r.sources-1)..' sources') or ''))
   local state,kind=V.State(r);row.state:SetText(r.rank and ('#'..r.rank..' · '..(state=='UNRANKED' and 'COMPARE ?' or state)) or (state=='UNRANKED' and 'MANUAL REVIEW' or state));row.state:SetTextColor(unpack(V.Palette(kind).accent))
   row.score:SetText(r.rank and ('Score '..G.Points(r.rankScore)..(r.delta and (' · '..G.Points(r.delta,true)..' vs worn') or ' · worn score unknown')) or (r.delta and (G.Points(r.delta,true)..' estimated points') or r.reason));row.score:SetTextColor(unpack(V.colors.muted))
   V.Style(row,kind,r.record.itemID==W.selected);V.Tint(row.rail,V.Palette(kind).accent)
  end
 end
 empty:SetShown(#results==0);empty:SetText(W.view=='hunts' and 'Your hunt log is clear. Save an item in Find upgrades, then pin the one you want next.' or W.view=='completed' and 'Acquired items appear when a saved hunt is observed in your carried inventory or equipped gear.' or options.bestNow and 'No confirmed upgrades found. Switch to Browse to inspect weapons, trinkets, future gear and items with incomplete data.' or 'No items match these filters. Try Include future levels, All armor types or Reset filters. Missing item data loads in the background while this window is open.')
 renderDetail(selected)
 if #G.loadQueue>0 then W.Wake() end
end
-- Reuse the six visible rows and current scan while scrolling any size catalog.
function W.ScrollTo(value)
 if not root or not root:IsShown() or W.view=='weights' or W.searchPending or type(value)~='number' or value~=value then return end
 local offset=math.max(0,math.min(math.max(0,#(W.results or {})-6),math.floor(value+.5)))
 if offset==W.offset then return end
 W.offset=offset;if GameTooltip then GameTooltip:Hide() end;W.Refresh()
end
function W.RevealSelection()
 if W.searchPending then return end
 for i,r in ipairs(W.results or {}) do if r.record.itemID==W.selected then W.ScrollTo(i-1);return end end
end
function W.Wake()
 if root and root:IsShown() then root:SetScript('OnUpdate',worker) end
end
function W.QueueRefresh()
 W.dirty=true;W.Wake()
end
function W.QueueSearch()
 W.searchPending=true;W.searchWait=.08;W.dirty=true
 if summary then summary:SetText('Searching…') end
 for _,row in ipairs(rows) do row:SetEnabled(false) end
 for _,b in ipairs({saveButton,trackButton,bossButton,sourceButton,statButton}) do b:SetEnabled(false) end
 W.Wake()
end
currentForAction=function()
 local itemID=W.current and W.current.record.itemID
 W.Refresh()
 if not itemID or not W.current or W.current.record.itemID~=itemID then tell('Results changed. Select the item again.');return nil end
 return W.current
end
worker=function(self,dt)
 if not root:IsShown() then self:SetScript('OnUpdate',nil);return end
 if W.searchPending then W.searchWait=W.searchWait-dt;if W.searchWait<=0 then W.searchPending=false end end
 if #G.loadQueue>0 then loadElapsed=loadElapsed+dt;if loadElapsed>=.1 then loadElapsed=0;G.LoadBatch() end end
 if W.dirty and not W.searchPending then W.Refresh() end
 if not W.dirty and not W.searchPending and #G.loadQueue==0 then self:SetScript('OnUpdate',nil) end
end
local function profileMenu(anchor)
 local suggested,context,specProfile=G.SuggestPreset()
 local entries={{label='For my class guide: '..suggested,action=function() G.Preset(suggested);tell(context..(specProfile and ': applied a guide-informed starting profile. Review the weights for your build.' or ': applied a broad starting profile. Review the weights for your build.'));W.Refresh() end}}
 for _,name in ipairs({'Balanced','Strength','Agility','Caster','Survival','Healer'}) do local key=name;entries[#entries+1]={label=key..' (starting preference)',action=function() G.Preset(key);W.Refresh() end} end
 local cfg=G.Settings()
 for i=1,3 do local index=i;local p=cfg.profiles[i];if type(p)=='table' then entries[#entries+1]={label='Load '..tostring(p.name),action=function() if not G.LoadProfile(index) then tell('This saved profile is invalid. Save it again from Weights.') end;W.Refresh() end} end end
 ForeverCompanionInterface.PagedMenu(anchor,'Choose stat weights',entries,V.Palette('weights'),285)
end
function W.ApplyScale()
 if not root then return end
 local U=ForeverCompanionInterface
 root.fcScaleBase=G.Settings().largeWindow and 1 or .84;root.fcApplyScale=W.ApplyScale
 local fit=1
 if UIParent and UIParent.GetWidth and UIParent.GetHeight then fit=math.min((UIParent:GetWidth()-32)/1080,(UIParent:GetHeight()-32)/760) end
 root:SetScale(math.min((G.Settings().largeWindow and 1 or .84)*U.SizePreference(root),fit))
end
function W.Open(itemID)
 if not root then
  root=CreateFrame('Frame','ForeverCompanionGearFinderPanel',UIParent);W.root=root;root:SetSize(1080,760);root:SetPoint('CENTER');root:SetFrameStrata('DIALOG');V.Window(root,1080,760,'discover')
  V.Rectangle(root,12,112,196,640,{.040,.065,.115,1})
  V.Rectangle(root,220,188,840,43,{.055,.10,.17,1})
  ForeverCompanionInterface.PreparePanel(root,'ForeverCompanionGearFinderPanel',1080,760)
  root:SetScript('OnEvent',W.ApplyScale)
  local sizing=button(root,910,-18,120,'Window size',function(self) local cfg=G.Settings();cfg.largeWindow=not cfg.largeWindow;W.ApplyScale();self:SetText(cfg.largeWindow and 'Compact size' or 'Larger size') end);sizing:SetText(G.Settings().largeWindow and 'Compact size' or 'Larger size')
  root:SetMovable(true);root:SetClampedToScreen(true);root:EnableMouse(true);root:RegisterForDrag('LeftButton')
  root:SetScript('OnDragStart',function(self) self:StartMoving() end);root:SetScript('OnDragStop',function(self) self:StopMovingOrSizing() end)
  ForeverCompanionInterface.CloseButton(root,function() root:Hide() end)
  local crest=root:CreateTexture(nil,'ARTWORK');crest:SetSize(38,38);crest:SetPoint('TOPLEFT',20,-18);crest:SetTexture('Interface\\AddOns\\ForeverCompanion\\Media\\Crest.tga')
  text(root,70,-17,730,24,'Gear Upgrade Finder'):SetTextColor(unpack(V.colors.text));text(root,70,-47,970,11,'Dungeon gear research · Alt + right-click a character slot to open it here · Source coverage: bundled catalog')
  for i,entry in ipairs({{'discover','Find upgrades'},{'hunts','My hunts'},{'completed','Acquired'},{'weights','Weights'}}) do
   local view=entry[1];tabs[view]=button(root,20+(i-1)*168,-73,158,entry[2],function() tell('');W.view=view;W.offset=0;W.selected=nil;W.Refresh() end)
  end
  profileButton=button(root,710,-73,350,'Weights',function(self) profileMenu(self) end)
  text(root,20,-119,180,12,'EQUIPMENT SLOTS'):SetTextColor(unpack(V.colors.blue))
  slots[0]=button(root,20,-147,180,'All equipment',function() W.view='discover';G.Settings().slot=0;W.offset=0;W.selected=nil;W.Refresh() end)
  for i,slot in ipairs(G.slots) do
   local index=i;slots[i]=button(root,20+((i-1)%2)*92,-180-math.floor((i-1)/2)*54,88,slot[1],function() W.view='discover';G.Settings().slot=index;W.offset=0;W.selected=nil;W.Refresh() end,50)
   local icon=slots[i]:CreateTexture(nil,'ARTWORK');slots[i].slotIcon=icon;icon:SetSize(25,25);icon:SetPoint('TOP',0,-3);icon:SetTexture('Interface\\Icons\\'..V.slotIcons[i])
   hover(slots[i],slot[1]..' · slot '..slot[2],function() local info=G.Read(G.Call(GetInventoryItemLink,'player',slot[2]));return 'Equipped: '..(info and info.name or 'empty / unavailable') end)
  end
  button(root,20,-678,180,'Reset filters',function() local cfg=G.Settings();cfg.slot=0;cfg.ready=true;cfg.matchArmor=true;cfg.upgrades=false;cfg.bestNow=true;cfg.dungeon='';search:SetText('');W.offset=0;W.selected=nil;W.Refresh();tell('Filters reset. Saved hunts and weights are unchanged.') end)
  local tooltipButton
  tooltipButton=button(root,20,-714,180,G.Settings().tooltips==false and 'Tooltip estimates: Off' or 'Tooltip estimates: On',function()
   local cfg=G.Settings();cfg.tooltips=cfg.tooltips==false;tooltipButton:SetText(cfg.tooltips and 'Tooltip estimates: On' or 'Tooltip estimates: Off');if ForeverCompanionGearTooltips then ForeverCompanionGearTooltips.Refresh() end
  end)
  search=ForeverCompanionInterface.EditBox(root,'Search item, boss, dungeon or ID');search:SetSize(420,28);search:SetPoint('TOPLEFT',220,-115);search:SetAutoFocus(false);search:SetMaxLetters(100)
  search:SetScript('OnTextChanged',function(_,user) if user then W.offset=0;W.QueueSearch() end end);search:SetScript('OnEnterPressed',function(self) W.Refresh();self:ClearFocus() end);search:SetScript('OnEscapePressed',function(self) self:ClearFocus() end)
  dungeonButton=button(root,650,-115,410,'All dungeons',function(self)
   local entries={{label='All dungeons',action=function() G.Settings().dungeon='';W.offset=0;W.Refresh() end}}
   for _,name in ipairs(ForeverCompanionLoot.DungeonNames()) do local dungeon=name;entries[#entries+1]={label=dungeon,action=function() G.Settings().dungeon=dungeon;W.offset=0;W.Refresh() end} end
   ForeverCompanionInterface.PagedMenu(self,'Dungeon source',entries,V.Palette('discover'),300)
  end)
  readyButton=button(root,220,-151,170,'Within my level',function() local cfg=G.Settings();cfg.ready=not cfg.ready;W.offset=0;W.Refresh() end)
  armorButton=button(root,400,-151,170,'Match worn armor',function() local cfg=G.Settings();cfg.matchArmor=not cfg.matchArmor;W.offset=0;W.Refresh() end)
  upgradeButton=button(root,580,-151,180,'Best upgrades now',function() local cfg=G.Settings();cfg.bestNow=cfg.bestNow==false;W.offset=0;W.Refresh() end)
  filtersButton=button(root,770,-151,290,'More gear options',function(self)
   local cfg=G.Settings();local entries={}
   if cfg.bestNow==false then
    entries[#entries+1]={label=readyButton:GetText(),action=function() cfg.ready=not cfg.ready;W.offset=0;W.Refresh() end}
    entries[#entries+1]={label=armorButton:GetText(),action=function() cfg.matchArmor=not cfg.matchArmor;W.offset=0;W.Refresh() end}
   end
   entries[#entries+1]={label='Retry loading item data',action=function() G.RetryData();G.ObserveHunts();refreshTracker();W.Refresh();tell('Requested updated item data.') end}
   ForeverCompanionInterface.Menu(self,'Gear options',entries)
  end)
  U.SetHoverHelp(dungeonButton,'Dungeon source','Limit the gear list to one dungeon or browse every source.')
  U.SetHoverHelp(readyButton,'Level filter','Limit Browse to gear within your current character level.')
  U.SetHoverHelp(armorButton,'Armor filter','Compare gear of the armor type you wear or show all armor types.')
  U.SetHoverHelp(upgradeButton,'Ranking mode','Best Now ranks gains over equipped gear. Browse shows candidates ranked within their slot.')
  U.SetHoverHelp(filtersButton,'Gear options','Adjust filters or retry loading item data.')
  W.filtersButton=filtersButton
  ForeverCompanionInterface.HoverNote(root,1037,-198,'Gear rankings','Best Now ranks estimated gains over equipped gear. Browse ranks within each slot. Hover a selected item’s rank for details on its comparison.')
  W.listHeading=text(root,220,-218,420,12,'');W.listHeading:SetTextColor(unpack(V.colors.blue))
  summary=text(root,220,-191,780,11,'',24);summary:SetTextColor(unpack(V.colors.muted))
  listArea=CreateFrame('Frame',nil,root);listArea:SetSize(420,416);listArea:SetPoint('TOPLEFT',220,-240);listArea:EnableMouseWheel(true)
  local function wheel(_,delta) W.ScrollTo((W.offset or 0)-(delta>0 and 1 or delta<0 and -1 or 0)) end
  listArea:SetScript('OnMouseWheel',wheel)
  for i=1,6 do
   local row=ForeverCompanionInterface.Button(root);row:SetSize(420,66);row:SetPoint('TOPLEFT',220,-240-(i-1)*70);row:SetText('')
   row.icon=row:CreateTexture(nil,'ARTWORK');row.icon:SetSize(32,32);row.icon:SetPoint('TOPLEFT',10,-10);row.iconBorder=V.Rectangle(row,8,8,36,36,V.colors.muted,'BORDER');row.rail=V.Rectangle(row,0,0,3,66,V.colors.blue,'BORDER')
   row.title=text(row,52,-7,355,13,'');row.meta=text(row,52,-27,355,10,'');row.score=text(row,52,-44,232,11,'');row.state=text(row,288,-45,120,10,'');row.state:SetJustifyH('RIGHT')
   row:EnableMouse(true);row:EnableMouseWheel(true);row:SetScript('OnMouseWheel',wheel)
   row:SetScript('OnClick',function(self) if self.record then W.Select(self.record.record.itemID) end end)
   row:SetScript('OnEnter',function(self) showGearTooltip(self,self.record) end)
   row:SetScript('OnLeave',hideGearTooltip);row:SetScript('OnHide',hideGearTooltip);rows[i]=row
  end;W.rows=rows
  empty=text(root,240,-285,380,14,'',180)
  scrollBar=CreateFrame('Slider',nil,root);scrollBar:SetSize(16,416);scrollBar:SetPoint('TOPLEFT',642,-240);scrollBar:SetOrientation('VERTICAL');scrollBar:SetValueStep(1)
  if scrollBar.SetObeyStepOnDrag then scrollBar:SetObeyStepOnDrag(true) end
  V.Rectangle(scrollBar,5,0,6,416,V.colors.muted,'BACKGROUND')
  local thumb=scrollBar:CreateTexture(nil,'ARTWORK');thumb:SetSize(16,34);thumb:SetTexture('Interface\\Buttons\\UI-ScrollBar-Knob');scrollBar:SetThumbTexture(thumb)
  scrollBar:SetScript('OnValueChanged',function(_,value) if not W.syncScroll then W.ScrollTo(value) end end)
  scrollBar:EnableMouseWheel(true);scrollBar:SetScript('OnMouseWheel',wheel);W.scrollBar=scrollBar;W.listArea=listArea
  counter=text(root,220,-680,270,11,'')
  revealButton=button(root,500,-671,140,'Find selected',W.RevealSelection);W.revealButton=revealButton
  hover(revealButton,'Your selected item','Return the selected item to the visible list without changing its source or your filters.')
  detail=CreateFrame('Frame',nil,root);detail:SetSize(400,460);detail:SetPoint('TOPLEFT',660,-240);V.Card(detail,'discover');W.detail=detail
  detail.scoreBand=V.Rectangle(detail,8,99,384,40,{.06,.16,.15,1})
  V.Rectangle(detail,8,143,384,61,{.065,.10,.16,1})
  V.Rectangle(detail,8,207,384,67,{.075,.085,.15,1})
  V.Rectangle(detail,12,310,376,1,V.colors.border,'BORDER')
  detail.icon=detail:CreateTexture(nil,'ARTWORK');detail.icon:SetSize(36,36);detail.icon:SetPoint('TOPLEFT',12,-12);detail.iconBorder=V.Rectangle(detail,10,10,40,40,V.colors.muted,'BORDER')
  detailTitle=text(detail,58,-12,328,15,'',39);detailMeta=text(detail,12,-60,376,11,'',34)
  local itemHover=CreateFrame('Frame',nil,detail);itemHover:SetSize(376,84);itemHover:SetPoint('TOPLEFT',12,-10)
  itemHover:EnableMouse(true);W.itemHover=itemHover
  itemHover:SetScript('OnEnter',function(self) showGearTooltip(self,W.current) end)
  itemHover:SetScript('OnLeave',hideGearTooltip);itemHover:SetScript('OnHide',hideGearTooltip)
  local rankHover=CreateFrame('Frame',nil,detail);rankHover:SetSize(376,40);rankHover:SetPoint('TOPLEFT',12,-99);W.rankHover=rankHover
  hover(rankHover,'How this rank works',function()
   local r=W.current;if not r then return 'Select an item first.' end
   if r.recommended then return '#'..r.rank..' by estimated gain over '..(r.empty and 'an empty ' or 'your worn ')..r.slot[1]..' using '..G.Settings().profile..' weights. Review effects and set bonuses on the item tooltip.' end
   if not r.rank then return 'Manual review: '..(r.reason or 'Supported comparison unavailable')..'. Weapons, missing stats and uncertain restrictions do not receive a fabricated rank.' end
   return '#'..r.rank..' of '..r.rankCount..' scored candidates in the filtered '..r.slot[1]..' list. Score '..G.Points(r.rankScore)..' uses profile '..G.Settings().profile..'. Higher weighted stat scores rank first; equal scores share a rank. Other slots have their own ranks. A #1 stat rank is not a universal BiS or DPS claim; inspect procs and set bonuses separately.'
  end)
  detailState=text(detail,16,-103,360,10,'')
  detailScore=text(detail,16,-119,360,11,'',18);equippedText=text(detail,12,-148,376,11,'',55)
  V.Rectangle(detail,12,202,376,1,V.colors.border,'BORDER')
  local equippedHover=CreateFrame('Frame',nil,detail);equippedHover:SetSize(376,55);equippedHover:SetPoint('TOPLEFT',12,-148);equippedHover:EnableMouse(true)
  equippedHover:SetScript('OnEnter',function(self) if GameTooltip and W.current and W.current.baseline and W.current.baseline.link then GameTooltip:SetOwner(self,'ANCHOR_RIGHT');pcall(GameTooltip.SetHyperlink,GameTooltip,W.current.baseline.link);GameTooltip:Show() end end)
  equippedHover:SetScript('OnLeave',function() if GameTooltip then GameTooltip:Hide() end end)
  sourceText=text(detail,12,-211,376,11,'',66)
  sourceButton=button(detail,12,-281,140,'Source',function() local current=currentForAction();if current then sourceIndex=sourceIndex%#current.sources+1;local chosen=current.sources[sourceIndex];sourceChoice={itemID=current.record.itemID,dungeon=chosen.dungeon,boss=chosen.boss};renderDetail(current) end end,24)
  bossButton=button(detail,164,-281,224,'View source boss',handoff,24)
  statHeader=text(detail,12,-317,130,10,'STAT');statHeader:SetTextColor(unpack(V.colors.violet))
  text(detail,150,-317,126,10,'WORN > ITEM'):SetTextColor(unpack(V.colors.violet))
  text(detail,286,-317,100,10,'POINTS'):SetTextColor(unpack(V.colors.violet))
  statText=text(detail,12,-337,376,11,'',80)
  for i=1,7 do statRows[i]={text(detail,12,-334-(i-1)*12.5,132,10,''),text(detail,150,-334-(i-1)*12.5,126,10,''),text(detail,286,-334-(i-1)*12.5,100,10,'')} end
  statButton=button(detail,12,-428,120,'More stats',function() local current=currentForAction();if current then W.statPage=W.statPage%math.max(1,math.ceil(#G.Breakdown(current)/7))+1;renderDetail(current) end end,24)
  saveButton=button(detail,140,-428,120,'Save hunt',function() local current=currentForAction();if current then local chosen=source(current);G.RememberSource(current.record.itemID,chosen.dungeon,chosen.boss);local _,message=G.Toggle(current.record.itemID);tell(message);W.Refresh();refreshTracker() end end,24)
  trackButton=button(detail,268,-428,120,'Pin hunt',function() local current=currentForAction();if current then local chosen=source(current);G.RememberSource(current.record.itemID,chosen.dungeon,chosen.boss);if not (current.tracked and G.Settings().trackerHidden) then G.Track(current.record.itemID) end;G.Settings().trackerHidden=false;W.Refresh();refreshTracker() end end,24)
  W.dungeonButton=dungeonButton;W.readyButton=readyButton;W.armorButton=armorButton;W.upgradeButton=upgradeButton;W.saveButton=saveButton;W.trackButton=trackButton;W.bossButton=bossButton;W.slots=slots;W.tabs=tabs;W.search=search;W.sourceButton=sourceButton
  notice=text(root,220,-715,840,11,'',32)
  weightPanel=CreateFrame('Frame',nil,root);weightPanel:SetSize(840,465);weightPanel:SetPoint('TOPLEFT',220,-235);V.Card(weightPanel,'weights');V.Rectangle(weightPanel,0,0,840,3,V.colors.violet,'BORDER')
  text(weightPanel,16,-16,808,13,'YOUR STAT PREFERENCES'):SetTextColor(unpack(V.colors.violet))
  text(weightPanel,16,-44,808,11,'Presets are editable starting points. Caps, weapon damage, proc effects and set bonuses need separate review.\nRating weights apply to the raw rating amounts returned by the client. Missing stat keys are never converted to percentages.',42)
  for i,stat in ipairs(G.stats) do
   local index=i;local col=(i-1)%2;local line=math.floor((i-1)/2);local x,y=16+col*412,-94-line*32
   local color=(i==1 or i==7) and V.colors.coral or (i==2 or i==4 or i==8 or i>=14) and V.colors.green or V.colors.blue
   weightLabels[i]=text(weightPanel,x,y+2,205,12,stat[1]);weightLabels[i]:SetTextColor(unpack(color));local box=ForeverCompanionInterface.EditBox(weightPanel,'0–100');box:SetSize(180,26);box:SetPoint('TOPLEFT',x+210,y+6);box:SetAutoFocus(false);box:SetMaxLetters(7);box.statIndex=i
   box:SetScript('OnEnterPressed',function(self) if not G.SetWeight(index,tonumber(self:GetText())) then tell('Enter a number between 0 and 100. Your previous weight was kept.') else tell('Weight applied. Comparisons updated.') end;self:ClearFocus();W.Refresh() end)
   box:SetScript('OnEscapePressed',function(self) self:SetText(tostring(G.Settings().weights[index]));self:ClearFocus() end);weightBoxes[i]=box
  end
  weightName=ForeverCompanionInterface.EditBox(weightPanel,'Name this profile');weightName:SetSize(808,28);weightName:SetPoint('TOPLEFT',16,-380);weightName:SetAutoFocus(false);weightName:SetMaxLetters(32)
  for i=1,3 do local index=i;weightSaveButtons[i]=button(weightPanel,16+(i-1)*274,-425,260,'Save to custom slot '..i,function() G.SaveProfile(index,weightName:GetText());tell('Saved profile in slot '..index..'. Use the Weights menu above to load it.');W.Refresh() end) end
  weightPanel:Hide();W.weightBoxes=weightBoxes;W.weightName=weightName
  root:HookScript('OnHide',function() root:SetScript('OnUpdate',nil);W.searchPending=false;W.dirty=false;loadElapsed=0 end)
  root:Hide()
 end
 if type(itemID)=='number' then W.view='discover';G.Settings().slot=0;G.Settings().dungeon='';G.Settings().ready=false;G.Settings().upgrades=false;G.Settings().bestNow=false;G.Settings().matchArmor=false;search:SetText('');W.selected=itemID;W.offset=0;local savedSource=G.SavedSource(itemID);sourceChoice=savedSource and {itemID=itemID,dungeon=savedSource.dungeon,boss=savedSource.boss} or nil end
 root:Show();W.ApplyScale();G.Invalidate();G.ObserveHunts();refreshTracker();W.Refresh()
 if itemID then for i,r in ipairs(W.results or {}) do if r.record.itemID==itemID then W.offset=math.max(0,math.min(i-1,#W.results-6));W.Refresh();break end end end
end
