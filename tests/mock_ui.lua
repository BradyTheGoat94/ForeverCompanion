-- Offline mock of the WoW widget API; tests construction and render, not pixels.
local frames={}
date=os.date
local snapshot={}
local function clean(v) return (tostring(v or ""):gsub("[\r\n|]"," ")) end
local function exportSnapshot(path)
 local lines={"id|kind|parent|visible|width|height|anchor|x|y|text|texture"}
 for _,f in ipairs(frames) do
  local anchor=f.point and clean(f.point[1]) or ""
  local x,y="",""
  if f.point then
   for _,v in ipairs(f.point) do
    if type(v)=="number" then if x=="" then x=v else y=v end end
   end
  end
  lines[#lines+1]=table.concat({f.id,f.kind,f.parent or "",f.visible and "1" or "0",f.width or "",f.height or "",anchor,x,y,clean(f.text),clean(f.texture)},"|")
 end
 local out=assert(io.open(path,"w"))
 out:write(table.concat(lines,string.char(10)))
 out:close()
end
local function exportNative(path)
 local function quote(value)
  local s=tostring(value or ""):gsub("\\","\\\\"):gsub('"','\\"'):gsub("\n","\\n"):gsub("\r","\\r"):gsub("\t","\\t")
  return '"'..s..'"'
 end
 local function encode(v)
  if type(v)=="string" then return quote(v) end
  if type(v)=="number" or type(v)=="boolean" then return tostring(v) end
  if type(v)~="table" then return "null" end
  local result={}
  for i,value in ipairs(v) do result[i]=encode(value) end
  return "["..table.concat(result,",").."]"
 end
 local records={}
 for _,f in ipairs(frames) do
  local values={id=f.id,kind=f.kind,parent=f.parent,name=f.name,visible=f.visible,width=f.width,height=f.height,
   text=f.text,texture=type(f.texture)=="string" and f.texture or nil,textureId=type(f.texture)=="number" and f.texture or nil,color=f.color,textColor=f.textColor,
   layer=f.layer,font=f.font,alpha=f.alpha,crop=f.texCoord,all=f.all,template=f.template,justify=f.justify,backdrop=f.backdropColor,backdropBorder=f.backdropBorder,wordWrap=f.wordWrap}
  local points={}
  for _,p in ipairs(f.points or {}) do
   local point,relative,relativePoint,x,y=p[1],f.parent,p[1],0,0
   if type(p[2])=="table" then relative=p[2].id;relativePoint=p[3];x=p[4] or 0;y=p[5] or 0
   elseif type(p[2])=="number" then x=p[2];y=p[3] or 0 end
   points[#points+1]={point,relative or 1,relativePoint,x,y}
  end
  values.points=points
  local record={}
  for key,value in pairs(values) do record[#record+1]=quote(key)..":"..encode(value) end
  records[#records+1]="{"..table.concat(record,",").."}"
 end
 local out=assert(io.open(path,"w"));out:write("["..table.concat(records,",").."]");out:close()
end
local function widget(kind)
 local w={kind=kind,visible=true,children={},text="",id=#frames+1}
 function w:SetText(v) self.text=tostring(v or "");if self.fontString then self.fontString:SetText(v) end;for _,hook in ipairs(self.hooks and self.hooks.OnTextChanged or {}) do hook(self,false) end end
 function w:GetText() return self.text end
 function w:GetStringHeight()
  local size=self.font and self.font[2] or 12
  local chars=math.max(1,math.floor((self.width or 525)/(size*.56)))
  local lines=0
  for paragraph in (self.text.."\n"):gmatch("(.-)\n") do lines=lines+math.max(1,math.ceil(#paragraph/chars)) end
  return math.max(16,lines*(size+2))
 end
 function w:Show() self.visible=true end
 function w:Hide() self.visible=false end
 function w:IsShown() return self.visible end
 function w:SetShown(value) self.visible=value end
 function w:SetScript(name,fn) self[name]=fn end
 function w:HookScript(name,fn) self.hooks=self.hooks or {};self.hooks[name]=self.hooks[name] or {};table.insert(self.hooks[name],fn) end
 function w:HasFocus() return self.focused==true end
 function w:GetScript(name) return self[name] end
 function w:RegisterEvent(name) self.events=self.events or {};self.events[name]=true end
 function w:CreateTexture(_,layer) local child=widget("Texture");child.parent=self.id;child.layer=layer;return child end
 function w:CreateFontString(_,layer,template) local child=widget("FontString");child.parent=self.id;child.layer=layer;child.template=template;return child end
 function w:SetColorTexture(...) self.color={...} end
 function w:SetTexture(v) self.texture=v end
 function w:SetPoint(...) self.point={...};self.points=self.points or {};for i,p in ipairs(self.points) do if p[1]==self.point[1] then self.points[i]=self.point;return end end;self.points[#self.points+1]=self.point end
 function w:SetSize(width,height) self.width=width;self.height=height end
 function w:SetHeight(height) self.height=height end
 function w:SetWidth(width) self.width=width end
 function w:GetWidth() return self.width end
 function w:GetHeight() return self.height end
 function w:SetScale(value) self.scale=value end
 function w:GetScale() return self.scale or 1 end
 function w:SetFrameStrata(value) self.strata=value end
 function w:GetFrameLevel() return self.frameLevel or (self.parent and frames[self.parent]:GetFrameLevel()+1) or 1 end
 function w:SetFrameLevel(v) self.frameLevel=v end
 function w:SetOrientation(v) self.orientation=v end
 function w:SetValueStep(v) self.step=v end
 function w:SetObeyStepOnDrag(v) self.obeyStep=v end
 function w:SetThumbTexture(v) self.thumb=v end
 function w:SetMinMaxValues(a,b) self.minimum,self.maximum=a,b end
 function w:SetValue(v) self.value=v end
 function w:SetStatusBarColor(...) self.barColor={...} end
 function w:SetStatusBarTexture(v) self.barTexture=v end
 function w:EnableMouseWheel() end
 function w:SetResizeBounds() end
 function w:SetRotation(value) self.rotation=value end
 function w:SetEnabled(value) self.enabled=value end
 function w:IsEnabled() return self.enabled~=false end
 function w:LockHighlight() end
 function w:UnlockHighlight() end
 function w:SetScrollChild(child) self.child=child end
 function w:GetVerticalScroll() return self.verticalScroll or 0 end
 function w:SetVerticalScroll(offset) self.verticalScroll=offset end
 function w:StartMoving() end
 function w:StopMovingOrSizing() end
 function w:EnableMouse(v) self.mouse=v end
 function w:SetDesaturated(v) self.desaturated=v end
 function w:RegisterForClicks() end
 function w:SetVertexColor(...) self.vertexColor={...} end
 function w:SetDrawLayer(value) self.layer=value end
 function w:RegisterForDrag() end
 function w:SetMovable() end
 function w:SetClampedToScreen() end
 function w:SetClipsChildren(value) self.clipsChildren=value end
 function w:SetResizable() end
 function w:SetBackdrop(...) end
 function w:SetBackdropColor(...) self.backdropColor={...} end
 function w:SetBackdropBorderColor(...) self.backdropBorder={...} end
 function w:SetAllPoints(target) self.all=target and target.id or self.parent end
 function w:SetJustifyH(value) self.justify=value end
 function w:SetJustifyV() end
 function w:SetWordWrap(v) self.wordWrap=v end
 function w:SetShadowOffset() end
 function w:SetShadowColor() end
 function w:SetSpacing() end
 function w:SetTextColor(...) self.textColor={...} end
 function w:SetFontObject() end
 function w:SetTextInsets(...) self.textInsets={...} end
 function w:SetAutoFocus(v) self.autoFocus=v end
 function w:SetFocus() self.focused=true;if self.OnEditFocusGained then self.OnEditFocusGained(self) end end
 function w:ClearFocus() self.focused=false;if self.OnEditFocusLost then self.OnEditFocusLost(self) end end
 function w:HasFocus() return self.focused==true end
 function w:HighlightText() self.highlighted=true end
 function w:SetMaxLetters(v) self.maxLetters=v end
 function w:SetMultiLine(value) self.multiLine=value end
 function w:SetCursorPosition(value) self.cursor=value end
 function w:SetDisabledFontObject() end
 function w:SetFont(path,size,flags) self.font={path,size,flags} end
 function w:SetTexCoord(...) self.texCoord={...} end
 function w:SetAlpha(value) self.alpha=value end
 function w:SetNormalTexture() end
 function w:SetFontString(value) self.fontString=value end
 function w:GetFontString() return self.fontString or self end
 function w:SetHighlightTexture() end
 function w:SetPushedTexture() end
 function w:ClearAllPoints() self.point=nil;self.points={} end
 frames[#frames+1]=w
 return w
end
CreateFrame=function(kind,name,parent,template) local child=widget(kind);child.parent=parent and parent.id;child.name=name;child.template=template;return child end
UIParent=widget("UIParent")
UIParent:SetSize(1000,700)
SlashCmdList={}
ForeverCompanionDB={welcomed=false}
UnitClass=function() return "Warrior","WARRIOR" end
UnitLevel=function() return 60 end
local mockXP=1500
UnitXP=function() return mockXP end
UnitXPMax=function() return 3000 end
UnitName=function() return "PreviewCharacter" end
GetProfessions=function() return 1,2 end
GetProfessionInfo=function(index)
 if index==1 then return "Blacksmithing",nil,300,300 end
 return "Mining",nil,275,300
end
C_QuestLog={
 GetNumQuestLogEntries=function() return 3 end,
 GetInfo=function(i)
  local examples={{title="Sample: Gather supplies",questID=101,zoneName="Training Camp"},
   {title="Sample: Speak with trainer",questID=102,zoneName="Training Camp",isComplete=true},
   {title="Sample: Explore the outpost",questID=103,zoneName="Frontier"}}
  return examples[i]
 end,
 IsComplete=function(id) return id==102 end,
 GetQuestObjectives=function(id) return {{text="Illustrative objective for test "..tostring(id),finished=id==102}} end
}
GetBuildInfo=function() return "OfflineMock","0","0",16001 end
print=function() end
local toc=assert(io.open("ForeverCompanion/ForeverCompanion.toc","r"))
local addon="ForeverCompanion"
for line in toc:lines() do
 if line:match("%.lua%s*$") then
  local chunk=assert(loadfile("ForeverCompanion/"..line))
  chunk(addon)
 end
end
toc:close()
local addonFrame
for _,f in ipairs(frames) do
 if f.events and f.events.ADDON_LOADED and f.events.PLAYER_XP_UPDATE and f.events.DISPLAY_SIZE_CHANGED then addonFrame=f;break end
end
assert(addonFrame and addonFrame.OnEvent,"addon loaded handler missing")
ForeverCompanionDB={role={},professions=false,position=true,checks={Dungeons=3,Legacy={true}}}
addonFrame.OnEvent(addonFrame,"ADDON_LOADED",addon)
assert(ForeverCompanionDB.role==nil and ForeverCompanionDB.professions==nil)
assert(ForeverCompanionDB.checks.Dungeons==nil and ForeverCompanionDB.checks.Legacy[1]==true)
local lootUI=ForeverCompanionLootUI
lootUI.dungeon="invalid filter";lootUI.savedOnly=true
local firstLoot=ForeverCompanionLoot.records[1]
SlashCmdList.FOREVERCOMPANION("loot "..firstLoot.item)
assert(ForeverCompanionDB.tab=="Loot" and lootUI.searchBox:GetText()==firstLoot.item)
assert(lootUI.itemTitle:GetText()==firstLoot.item and lootUI.dungeon=="" and not lootUI.savedOnly)
SlashCmdList.FOREVERCOMPANION("loot no such loot")
assert(lootUI.selectedIndex==1 and lootUI.itemTitle:GetText()=="No matching loot")
SlashCmdList.FOREVERCOMPANION("overview")
lootUI.resetButton.OnClick()

assert(#frames>50,"expected substantial UI frame tree")
assert(type(SlashCmdList.FOREVERCOMPANION)=="function","slash command missing")
SlashCmdList.FOREVERCOMPANION("class mage")
SlashCmdList.FOREVERCOMPANION("class auto")
SlashCmdList.FOREVERCOMPANION("role damage")
SlashCmdList.FOREVERCOMPANION("position reset")
SlashCmdList.FOREVERCOMPANION("open quests")
assert(ForeverCompanionDB.tab=="Quests","slash navigation must open quest guide")
local questNav=ForeverCompanionUIState.nextQuestButton
local viewport
for _,widget in ipairs(frames) do
 if widget.kind=="ScrollFrame" then viewport=widget;break end
end
assert(viewport.point[3]>questNav.point[3]+questNav.height,"quest scroll viewport must clear both footer buttons")
do
 local originalHeight=viewport.GetHeight
 local childHeight=viewport.child.height
 viewport.GetHeight=function() return 200 end
 viewport.child:SetHeight(500);viewport:SetVerticalScroll(0)
 ForeverCompanionUIState.updateScrollHint()
 local hint
 for _,f in ipairs(frames) do if f.text=='More below  ·  Scroll to continue' then hint=f end end
 assert(hint and hint.visible,'long pages need a visible continuation cue')
 viewport:SetVerticalScroll(800);ForeverCompanionUIState.updateScrollHint()
 assert(viewport:GetVerticalScroll()==300 and hint.text=='End of page','shortened pages clamp stale scroll offsets')
 viewport.child:SetHeight(100);ForeverCompanionUIState.updateScrollHint()
 assert(not hint.visible and viewport:GetVerticalScroll()==0,'short pages hide continuation cues and return to the top')
 viewport.GetHeight=originalHeight;viewport.child:SetHeight(childHeight)
end
SlashCmdList.FOREVERCOMPANION("overview")
assert(ForeverCompanionDB.tab=="Overview","direct slash navigation must return to dashboard")
assert(pcall(SlashCmdList.FOREVERCOMPANION,"status"),"read-only status command must not crash")
SlashCmdList.FOREVERCOMPANION("open nonexistent")
assert(ForeverCompanionDB.tab=="Overview","invalid navigation must not change selected tab")
assert(ForeverCompanionQuestPlanner.Sync(),"fixture quest API should sync")
assert(ForeverCompanionQuestPlanner.AutoCount()==3,"three test quests expected")
assert(ForeverCompanionCraftingPlanner.Add("Blacksmithing","Sample Ore",10,4),"material fixture should be accepted")
local stats=ForeverCompanionCraftingPlanner.Stats()
assert(stats.materials==1 and stats.missing==6 and stats.complete==0,"material dashboard stats wrong")
ForeverCompanionDashboard.Render()
local readyRecommendation=false
for _,w in ipairs(frames) do
 if w.text=="1. Ready to turn in: Sample: Speak with trainer" then readyRecommendation=true end
end
assert(readyRecommendation,"dashboard should prioritize confirmed ready-to-turn-in quests")
local step1,step3,sourceLabel
for _,w in ipairs(frames) do
 if w.caption and w.caption.text:find("1. Ready to turn in:",1,true) then step1=w end
 if w.caption and w.caption.text:find("3. Gather",1,true) then step3=w end
 if w.kind=="FontString" and w.text:find("Quest data: current snapshot",1,true) then sourceLabel=w end
end
assert(step1 and step1.caption.text=="1. Ready to turn in: Sample: Speak with trainer","recommended quest must use visible caption")
assert(step3 and step3.caption.text=="3. Gather 6 Sample Ore for Blacksmithing (manual).","material recommendation must be visible")
assert(step1.extraDetail and step1.extraDetail:find("Training Camp",1,true),"quest action should expose observed zone")
assert(step1.extraDetail:find("Illustrative objective for test 102",1,true),"quest action should expose observed objective")
assert(step3.extraDetail and step3.extraDetail:find("manual",1,true),"material action should disclose manual data")
local oldTooltip=GameTooltip
local tooltip={lines={}}
function tooltip:SetOwner() end
function tooltip:SetText(value) self.title=value end
function tooltip:AddLine(value) self.lines[#self.lines+1]=value end
function tooltip:Show() self.visible=true end
function tooltip:Hide() self.visible=false end
GameTooltip=tooltip
step1.OnEnter(step1)
assert(tooltip.title:find("Ready to turn in",1,true),"quest tooltip should describe action")
assert(tooltip.lines[1]:find("Training Camp",1,true),"quest tooltip should include zone and objective")
step1.OnLeave(step1)
GameTooltip=oldTooltip
assert(sourceLabel and sourceLabel.text:find("Professions: detected",1,true),"data source disclosure missing")
-- Every dashboard progress metric must navigate to the matching read-only guide.
local metricButtons={}
for _,w in ipairs(frames) do
 if w.dashboardTarget then metricButtons[w.dashboardTarget]=w end
end
for _,target in ipairs({"Leveling","Quests","Professions"}) do
 local metric=metricButtons[target]
 assert(metric and metric.OnClick and metric.OnEnter and metric.OnLeave,"missing navigable dashboard metric: "..target)
 assert(type(metric.detail)=="string" and metric.detail~="","metric needs a readable value")
 assert(pcall(metric.OnEnter,metric) and pcall(metric.OnLeave,metric),"metric hover should be safe without tooltip APIs")
 metric.OnClick(metric)
 assert(ForeverCompanionDB.tab==target,"dashboard metric did not open "..target)
 SlashCmdList.FOREVERCOMPANION("overview")
end
local bannerStatus,focusCount
for _,w in ipairs(frames) do
 if w.kind=="FontString" and w.text:find("ready of 3 quests",1,true) then bannerStatus=w end
 if w.kind=="FontString" and w.text=="0/4 done" then focusCount=w end
end
assert(bannerStatus and bannerStatus.text:find("6 material units needed",1,true),"live dashboard briefing missing")
assert(focusCount,"dashboard focus completion counter missing")
local originalCount=C_QuestLog.GetNumQuestLogEntries
C_QuestLog.GetNumQuestLogEntries=function() return 0 end
assert(ForeverCompanionQuestPlanner.Sync(),"empty quest log scan should succeed")
ForeverCompanionDashboard.Render()
assert(step1.caption.text=="1. Review your quest log for a new objective.","empty-log recommendation should replace prior caption")
C_QuestLog.GetNumQuestLogEntries=originalCount
assert(ForeverCompanionQuestPlanner.Sync(),"quest log should recover after empty scan")
assert(ForeverCompanionCraftingPlanner.SetOwned("Blacksmithing",1,10),"finish manual material goal")
ForeverCompanionDashboard.Render()
assert(step3.caption.text=="3. Add or review your manual profession goals.","completed goals should replace shortage caption")
assert(ForeverCompanionCraftingPlanner.SetOwned("Blacksmithing",1,4),"restore shortage fixture")
ForeverCompanionDashboard.Render()
local focusButton
for _,w in ipairs(frames) do
 if w.caption and w.caption.text and w.caption.text:find("Review active quests",1,true) then focusButton=w end
end
assert(focusButton and focusButton.OnClick,"focus checklist button missing")
focusButton.OnClick(focusButton)
assert(ForeverCompanionDB.dashboardFocus[1]==true,"focus state did not persist")
assert(focusCount.text=="1/4 done","focus completion meter should update after click")
focusButton.OnClick(focusButton)
assert(ForeverCompanionDB.dashboardFocus[1]==false,"focus toggle did not reverse")
-- Today's Focus persists within the same day, then resets on the next day.
local originalDate=date
date=function() return "2026-11-02" end
focusButton.OnClick(focusButton)
assert(ForeverCompanionDB.dashboardFocus[1]==true,"daily focus should save")
ForeverCompanionDashboard.Render()
assert(ForeverCompanionDB.dashboardFocus[1]==true,"same-day focus must persist")
date=function() return "2026-11-03" end
ForeverCompanionDashboard.Render()
assert(not ForeverCompanionDB.dashboardFocus[1],"new day must reset the focus checklist")
assert(focusCount.text=="0/4 done","daily focus completion counter must reset")
date=function() error("restricted date API") end
assert(pcall(ForeverCompanionDashboard.Render),"restricted date API must not crash")
date=originalDate
local questAction
for _,w in ipairs(frames) do if w.caption and w.caption.text=="Quests" then questAction=w end end
assert(questAction and questAction.OnClick,"quest shortcut missing")
questAction.OnClick(questAction)
assert(ForeverCompanionDB.tab=="Quests","quest shortcut failed")
local questHeading,questFocusHeading,questBriefingRoot
for _,w in ipairs(frames) do
 if w.text=="YOUR QUEST LOG" then questHeading=w end
 if w.text=="WHAT TO DO NEXT" then questFocusHeading=w end
end
assert(questHeading and questFocusHeading,"quest briefing panels missing")
questBriefingRoot=frames[questHeading.parent].parent
assert(frames[questBriefingRoot].visible,"quest briefing must be visible on quest page")
local questCountCard=false
for _,w in ipairs(frames) do
 if w.text=="3 active  |  1 ready  |  0 pinned" then questCountCard=true end
end
assert(questCountCard,"live quest briefing count incorrect")
local sortControl
for _,w in ipairs(frames) do if w.OnClick and w.text=="By zone" then sortControl=w end end
assert(sortControl and sortControl.OnClick,"quest sort selector missing")
local function chooseSort(label)
 local menu=ForeverCompanionInterface.Menu
 local chosen
 ForeverCompanionInterface.Menu=function(_,_,entries)
  for _,entry in ipairs(entries) do if entry.label==label then chosen=entry.action end end
 end
 sortControl.OnClick(sortControl)
 ForeverCompanionInterface.Menu=menu
 assert(chosen,"missing sort option: "..label)
 chosen()
end
chooseSort("Ready first")
assert(ForeverCompanionQuestPlanner.GetSort()=="ready")
assert(ForeverCompanionQuestPlanner.GetVisible()[1].quest.complete)
chooseSort("Pinned first")
assert(ForeverCompanionQuestPlanner.GetSort()=="pinned")
chooseSort("Quest log order")
assert(ForeverCompanionQuestPlanner.GetVisible()[1].quest.title=="Sample: Gather supplies")
chooseSort("By zone")
assert(ForeverCompanionQuestPlanner.GetVisible()[1].quest.zone=="Frontier","zone sort should group alphabetically")
-- Styled journal rows expose readable title, zone, and status without touching
-- the game's selected quest. Clicking only changes the addon's focused entry.
local readyRow
for _,w in ipairs(frames) do
 if w.title and w.zone and w.status and w.title.text:find("Speak with trainer",1,true) then readyRow=w end
end
assert(readyRow and readyRow.OnClick,"native quest journal row missing")
assert(readyRow.zone.text=="Training Camp","quest row zone label incorrect")
assert(readyRow.status.text=="READY","quest row completion badge incorrect")
readyRow.OnClick(readyRow)
assert(ForeverCompanionQuestPlanner.GetSelected().title=="Sample: Speak with trainer","journal row focus failed")
assert(readyRow.selected,"selected quest row must be highlighted")
local pinControl
for _,w in ipairs(frames) do if w.text=="Pin Focus" and w.OnClick then pinControl=w end end
assert(pinControl and pinControl.visible,"quest pin button must be visible")
pinControl.OnClick(pinControl)
assert(ForeverCompanionQuestPlanner.PinnedCount()==1,"pin button must persist quest priority")
assert(pinControl.text=="Unpin Focus","pin control must reflect focused quest state")
assert(readyRow.icon.texture:find("INV_Misc_Map_01",1,true),"journal row should show a pinned icon")
assert(ForeverCompanionQuestPlanner.Overview().pinned==1,"journal overview must count pinned quests")
local knownObjective=false
for _,w in ipairs(frames) do
 if w.text=="1 / 1 objectives complete" then knownObjective=true end
end
assert(knownObjective,"quest focus card should show verified objective progress")
do
 local priorMap,priorPoint,priorTrack,priorDb,priorAddons=C_Map,UiMapPoint,C_SuperTrack,LibQuestieDB,C_AddOns
 local marker,writes,opens,tracked=nil,0,0,false
 local selected=ForeverCompanionQuestPlanner.GetSelected()
 C_QuestLog.GetNextWaypoint=function(id)
  assert(id==selected.id)
  return 1429,.43,.61
 end
 C_Map={
  CanSetUserWaypointOnMap=function(map) return map==1429 end,
  GetMapInfo=function(map) if map==1429 then return {name="Elwynn Forest",mapType=3} end end,
  SetUserWaypoint=function(p) marker=p;writes=writes+1 end,
  GetUserWaypoint=function() return marker end,
  ClearUserWaypoint=function() marker=nil end,
  OpenWorldMap=function(map) assert(map==1429);opens=opens+1 end,
 }
 UiMapPoint={CreateFromCoordinates=function(map,x,y)
  return {uiMapID=map,position={GetXY=function() return x,y end}}
 end}
 C_SuperTrack={
  SetSuperTrackedUserWaypoint=function(value) tracked=value end,
  IsSuperTrackingUserWaypoint=function() return tracked end,
 }
 local briefing=ForeverCompanionQuestBriefing
 local navigation=ForeverCompanionQuestWaypoints
 briefing.Render()
 assert(briefing.mapButton.enabled and writes==0 and opens==0,"render never changes the user's map")
 briefing.mapButton:OnClick()
 assert(writes==0 and opens==0,"Quest details opens the field guide without navigating a general quest point")
 navigation.Show(selected);briefing.Render()
 assert(writes==1 and opens==1 and tracked and briefing.clearPin.enabled,"explicit quest map action starts navigation")
 marker=UiMapPoint.CreateFromCoordinates(1429,.18,.37)
 assert(not navigation.Clear() and marker,"must preserve a waypoint the player set afterward")
 navigation.Show(selected);briefing.Render()
 briefing.clearPin:OnClick()
 assert(not marker and not briefing.clearPin.enabled,"clear removes the addon waypoint")
 C_QuestLog.GetNextWaypoint=nil
 C_Map.GetBestMapForUnit=function() return 1429 end
 C_QuestLog.GetQuestsOnMap=function()
  return {{questID=selected.id,mapID=1429,isQuestStart=true,x=.1,y=.3},
          {questID=selected.id,mapID=1429,isQuestStart=false,x=.4,y=.6}}
 end
 assert(navigation.Location(selected).x==.4,"map POIs must ignore quest-start locations")
 C_QuestLog.GetQuestsOnMap=nil
 assert(navigation.Location(selected)==nil,"missing data must not invent a marker")
 LibQuestieDB={
  ModeIndicator={GetStatus=function() return {expansion="Forever"} end},
  RequireContract=function(v) return v==1 end,
  Quest={name=function() return selected.title end,finishedBy=function() return {{42}} end},
  Npc={spawns=function() return {[12]={{47,68}}} end},
  Support={Get=function() return {private={areaIdToUiMapId="return {[12] = 1429,}"}} end},
 }
 local candidate=navigation.Location(selected)
 assert(candidate and candidate.source=="QuestieDB turn-in" and candidate.y==.68,"optional provider uses known turn-in spawn")
 LibQuestieDB.ModeIndicator.GetStatus=function() return {mode="baked"} end
 C_AddOns={GetAddOnMetadata=function(addon,key)
  assert(addon=="QuestieDB" and key=="X-Flavor")
  return "Forever"
 end}
 assert(navigation.Location(selected).source=="QuestieDB turn-in","baked provider reads the TOC flavor")
 C_AddOns.GetAddOnMetadata=function() return "Vanilla" end
 assert(navigation.Location(selected)==nil,"other flavors cannot provide markers")
 C_AddOns.GetAddOnMetadata=function() return "Forever" end
 LibQuestieDB.Npc.spawns=function() return {[12]={{47,68},{49,63}}} end
 assert(navigation.Location(selected)==nil,"ambiguous optional coordinates must be skipped")
 C_Map,UiMapPoint,C_SuperTrack,LibQuestieDB,C_AddOns=priorMap,priorPoint,priorTrack,priorDb,priorAddons
end
do
 local planner=ForeverCompanionQuestPlanner
 local briefing=ForeverCompanionQuestBriefing
 local originalInfo,originalCount=C_QuestLog.GetInfo,C_QuestLog.GetNumQuestLogEntries
 local originalMap,originalUtil,originalCVar=C_Map,MapUtil,GetCVarBool
 local canvas=CreateFrame("Frame")
 canvas:SetSize(800,500)
 function canvas:GetFrameLevel() return 1 end
 local mapID,provider,area=1429
 local create=CreateFrame
 CreateFrame=function(kind,...)
  local frame=create(kind,...)
  function frame:SetFrameLevel(level) self.frameLevel=level end
  if kind=="QuestPOIFrame" then
   area=frame
   function frame:SetMapID(map) self.map=map end
   function frame:DrawNone() self.quest=nil end
   function frame:DrawBlob(id) self.quest=id end
   for _,method in ipairs({"SetFillTexture","SetBorderTexture","SetFillAlpha","SetBorderAlpha","SetBorderScalar"}) do
    frame[method]=function() end
   end
  end
  return frame
 end
 WorldMapFrame={IsShown=function() return true end,GetMapID=function() return mapID end,GetFrameLevel=function() return 1 end,
  GetCanvas=function() return canvas end,AddDataProvider=function(_,value) provider=value end}
 MapCanvasDataProviderMixin={}
 CreateFromMixins=function() return {} end
 MapUtil={ShouldMapTypeShowQuests=function(kind) return kind==3 end}
 GetCVarBool=function() return true end
 C_Map={GetMapInfo=function() return {mapType=3} end}
 C_QuestLog.GetQuestsOnMap=function()
  return {{questID=101,mapID=1429,isQuestStart=false,x=.21,y=.42},
          {questID=102,mapID=1429,isQuestStart=false,x=.28,y=.4},
          {questID=104,mapID=1429,isQuestStart=false,x=.5,y=.6},
          {questID=104,mapID=1429,isQuestStart=false,x=.5,y=.6},
          {questID=104,mapID=1429,isQuestStart=false,x=.7,y=.7},
          {questID=104,mapID=1429,isQuestStart=true,x=.1,y=.1},
          {questID=999,mapID=1429,isQuestStart=false,x=.8,y=.8},
          {questID=101,mapID=1415,isQuestStart=false,x=.2,y=.2}}
 end
 C_QuestLog.GetNumQuestLogEntries=function() return 4 end
 C_QuestLog.GetInfo=function(i)
  return i==4 and {title="New quest",questID=104,zoneName="Elwynn Forest"} or originalInfo(i)
 end
 planner.Select(1)
 assert(not planner.IsAutoFocus() and briefing.autoFocusButton.text=="Auto focus: Off")
 briefing.autoFocusButton:OnClick()
 assert(planner.IsAutoFocus() and planner.Sync() and planner.GetSelected().id==104,"new quest should gain automatic focus")
 for _,frame in ipairs(frames) do
  if frame.events and frame.events.QUEST_POI_UPDATE and frame.events.ADDON_LOADED then
   frame:OnEvent("ADDON_LOADED","Blizzard_WorldMap")
   break
  end
 end
 assert(provider and area.visible and area.map==1429 and area.quest==104,"world map draws the focused quest's native boundary")
 local function visiblePins()
  local count,focused,ready,active=0,0,0,0
  for _,frame in ipairs(frames) do
   if frame.parent==canvas.id and frame.symbol and frame.visible then
    count=count+1
    if frame.symbol.text==">" then focused=focused+1 end
    if frame.symbol.text=="?" then ready=ready+1 end
    if frame.symbol.text=="" then active=active+1 end
   end
  end
  return count,focused,ready,active
 end
 local count,focused,ready,active=visiblePins()
 assert(count==4 and focused==2 and ready==1 and active==1,"All should be the default map view")
 local dock,expandDock
 for _,f in ipairs(frames) do if f.name=='ForeverCompanionMapToolbar' then dock=f end end
 assert(dock and dock.height==54,'map dock starts compact to preserve terrain')
 for _,f in ipairs(frames) do if f.parent==dock.id and f.text=='+' and f.OnClick then expandDock=f end end
 assert(expandDock);expandDock.OnClick();assert(dock.height==140)
 exportNative('ui_map_dock_expanded_native.json')
 expandDock.OnClick();assert(dock.height==54)
 local oldPosition=C_Map.GetPlayerMapPosition
 C_Map.GetPlayerMapPosition=function() return {GetXY=function() return .123,.456 end} end
 dock.OnUpdate(dock,.3)
 local coordinates
 for _,f in ipairs(frames) do if f.parent==dock.id and f.text=='You 12.3, 45.6' then coordinates=f end end
 assert(coordinates,'map dock coordinates use the viewed map position')
 C_Map.GetPlayerMapPosition=function() return nil end;dock.OnUpdate(dock,.3)
 assert(coordinates.text=='No position','unavailable map position cannot retain old coordinates')
 C_Map.GetPlayerMapPosition=oldPosition
 local function mapModeButton(text)
  for _,frame in ipairs(frames) do if frame.OnClick and frame.text==text then return frame end end
 end
 assert(ForeverCompanionQuestMap.MapStyle()=='clear','new map defaults preserve unobstructed native terrain')
 ForeverCompanionQuestMap.SetMapStyle('atlas')
 local styleButton=assert(mapModeButton("Style: Atlas"))
 local terrain
 for _,frame in ipairs(frames) do
  if frame.parent==canvas.id and frame[9] then terrain=frame end
 end
 assert(terrain and terrain.visible,"atlas style draws an independent terrain overlay")
 styleButton:OnClick()
 assert(not terrain.visible and visiblePins()==4,"original terrain keeps all quest markers")
 styleButton:OnClick()
 assert(not terrain.visible,"original style keeps native artwork unobstructed")
 styleButton:OnClick()
 assert(terrain.visible,"atlas style can be restored")
 local modeButton=assert(mapModeButton("Map: All"))
 modeButton:OnClick()
 count,focused,ready,active=visiblePins()
 assert(count==2 and focused==2 and ready==0 and active==0,"Focus should hide markers for other quests")
 modeButton:OnClick()
 assert(visiblePins()==0 and not area.visible,"Off hides Companion quest markers and area")
 modeButton:OnClick()
 assert(visiblePins()==4)
 planner.SetAutoFocus(false)
 local normalPOIs,normalInfo,normalCount=C_QuestLog.GetQuestsOnMap,C_QuestLog.GetInfo,C_QuestLog.GetNumQuestLogEntries
 C_QuestLog.GetNumQuestLogEntries=function() return 20 end
 C_QuestLog.GetInfo=function(i)
  if i<=4 then return normalInfo(i) end
  return {title="Extra quest "..i,questID=200+i,zoneName="Elwynn Forest"}
 end
 C_QuestLog.GetQuestsOnMap=function()
  local points=normalPOIs()
  for i=5,20 do
   local x=i<=6 and .10 or .14+(i-7)*.045
   points[#points+1]={questID=200+i,mapID=1429,isQuestStart=false,x=x,y=.12}
  end
  return points
 end
 assert(planner.Sync())
 local represented,shared=0,false
 for _,frame in ipairs(frames) do
  if frame.parent==canvas.id and frame.symbol and frame.visible and not frame.focused then
   represented=represented+1+#frame.nearby
   if frame.symbol.text=="+" and #frame.nearby==1 then shared=true end
  end
 end
 assert(represented==18 and shared,"All must retain quests beyond the former cap, including shared destinations")
 C_QuestLog.GetQuestsOnMap,C_QuestLog.GetInfo,C_QuestLog.GetNumQuestLogEntries=normalPOIs,normalInfo,normalCount
 planner.Select(4)
 assert(planner.Sync())
 local oldProvider,oldFaction,oldTimer=LibQuestieDB,UnitFactionGroup,C_Timer
 UnitFactionGroup=function() return "Alliance" end
 local scheduled
 C_Timer={After=function(_,callback) scheduled=callback end}
 LibQuestieDB={
  Quest={},RequireContract=function() return true end,
  ModeIndicator={GetStatus=function() return {expansion="Forever"} end},
  Support={Get=function() return {private={areaIdToUiMapId="return {[12] = 1429,}"}} end},
  Enum={npcFlags={BANKER=256,VENDOR=4}},
  Npc={GetAllIds=function() return {1,2,3} end,npcFlags=function(id) return id==1 and 256 or 4 end,
   friendlyToFaction=function(id) return id==3 and "H" or "A" end,
   name=function(id) return id==1 and "Test banker" or "Test vendor" end,
   spawns=function(id) return {[12]={{44+id,70}}} end},
 }
 provider:OnMapChanged()
 assert(scheduled,"town services are indexed asynchronously")
 scheduled()
 local function townPins()
  local count=0
  for _,frame in ipairs(frames) do
   if frame.parent==canvas.id and frame.locations and frame.visible then count=count+1 end
  end
  return count
 end
 assert(townPins()==1,"nearby friendly service types should cluster together")
 local townsButton=assert(mapModeButton("Services: On"))
 townsButton:OnClick()
 assert(townPins()==0 and visiblePins()==4,"town services toggle independently of quests")
 townsButton:OnClick()
 assert(townPins()==1)
 local servicePin
 for _,f in ipairs(frames) do if f.parent==canvas.id and f.locations and f.visible then servicePin=f end end
 assert(servicePin and #servicePin.locations==2 and servicePin.count.text=="2")
 local oldShift,oldNavigate=IsShiftKeyDown,ForeverCompanionQuestWaypoints.Navigate
 IsShiftKeyDown=function() return true end
 servicePin:OnClick()
 assert(servicePin.locationIndex==2,"shift click selects another clustered service")
 local chosen
 IsShiftKeyDown=function() return false end
 ForeverCompanionQuestWaypoints.Navigate=function(target) chosen=target;return "Selected service" end
 servicePin:OnClick()
 assert(chosen==servicePin.locations[2],"navigation retains real selected service coordinates")
 servicePin:OnClick('RightButton')
 local serviceChoice
 for _,f in ipairs(frames) do if f.kind=='Button' and f.text=='Vendor: Test vendor' then serviceChoice=f end end
 assert(serviceChoice);serviceChoice.OnClick()
 assert(chosen.label=='Test vendor','cluster menu keeps every real service reachable')
 IsShiftKeyDown,ForeverCompanionQuestWaypoints.Navigate=oldShift,oldNavigate
 mapID=1430;provider:OnMapChanged()
 assert(townPins()==0,"old service pins disappear on map change")
 mapID=1429;provider:OnMapChanged()
 LibQuestieDB,UnitFactionGroup,C_Timer=oldProvider,oldFaction,oldTimer
 provider:OnMapChanged()
 local activePin
 for _,frame in ipairs(frames) do
  if frame.parent==canvas.id and frame.symbol and frame.visible and frame.symbol.text=="" then activePin=frame end
 end
 assert(activePin and activePin.OnClick and activePin.ring and not activePin.ring.visible)
 activePin:OnClick()
 for _,frame in ipairs(frames) do
  if frame.parent==canvas.id and frame.symbol and frame.visible and frame.symbol.text==">" then activePin=frame end
 end
 assert(planner.GetSelected().id==101 and activePin.ring.visible,"map click focuses the quest and highlights its destination")
 local originalWaypoint,originalShift=UiMapPoint,IsShiftKeyDown
 local originalVector,originalFacing=CreateVector2D,GetPlayerFacing
 local destination
 UiMapPoint={CreateFromCoordinates=function(map,x,y) return {uiMapID=map,position={x=x,y=y}} end}
 C_Map.SetUserWaypoint=function(value) destination=value end
 C_Map.GetUserWaypoint=function() return destination end
 CreateVector2D=function(x,y) return {GetXY=function() return x,y end} end
 C_Map.GetBestMapForUnit=function() return 1429 end
 C_Map.GetPlayerMapPosition=function() return CreateVector2D(0,0) end
 C_Map.GetWorldPosFromMapPos=function(_,pos)
  local x,y=pos:GetXY()
  return 1,CreateVector2D(-y*100,-x*100)
 end
 GetPlayerFacing=function() return 0 end
 activePin:OnClick()
 assert(ForeverCompanionQuestDirection.IsActive(),"a focused marker starts the companion HUD arrow")
 local arrow,hud
 for _,f in ipairs(frames) do
  if f.texture and type(f.texture)=="string" and f.texture:find("QuestDirectionArrow",1,true) then arrow=f;hud=frames[f.parent] end
 end
 assert(arrow and arrow.visible and arrow.rotation<0,"HUD arrow points southwest from the fixture position")
 GetPlayerFacing=function() return nil end
 hud:OnUpdate(.11)
 assert(not arrow.visible,"HUD hides the bearing if facing is unavailable")
 assert(ForeverCompanionQuestWaypoints.Clear(),"active HUD can be cleared")
 assert(not ForeverCompanionQuestDirection.IsActive() and not hud.visible)
 CreateVector2D,GetPlayerFacing=originalVector,originalFacing
 assert(destination and destination.uiMapID==1429 and destination.position.x==.21,"clicking the focused marker sets the native waypoint")
 UiMapPoint,IsShiftKeyDown=originalWaypoint,originalShift

 planner.Select(1)
 assert(not planner.IsAutoFocus() and area.quest==101,"manual selection updates the area and pauses auto focus")
 C_QuestLog.GetNumQuestLogEntries=function() return 5 end
 local four=C_QuestLog.GetInfo
 C_QuestLog.GetInfo=function(i)
  return i==5 and {title="Other new quest",questID=105} or four(i)
 end
 assert(planner.Sync() and planner.GetSelected().id==101,"new quests must not steal manual focus")
 mapID=1429+1
 provider:OnMapChanged()
 assert(visiblePins()==0 and area.map==mapID,"changing map clears old markers and uses new map for area geometry")
 mapID=1429
 provider:OnMapChanged()
 assert(visiblePins()==3,"returning to a map restores a single marker per other quest")
 C_QuestLog.GetNumQuestLogEntries=function() error("quest log unavailable") end
 assert(not planner.Sync() and visiblePins()==0 and not area.visible,"stale quest data must hide map markers and area")
 C_QuestLog.GetInfo,C_QuestLog.GetNumQuestLogEntries=originalInfo,originalCount
 C_QuestLog.GetQuestsOnMap=nil
 assert(planner.Sync())
 local oldPOIs,oldTitle=C_QuestLog.GetQuestsOnMap,C_QuestLog.GetTitleForQuestID
 C_QuestLog.GetTitleForQuestID=function(id) return "Available quest "..id end
 C_QuestLog.GetQuestsOnMap=function()
  return {{questID=777,mapID=1429,isQuestStart=true,x=.3,y=.3},{questID=888,mapID=1429,isQuestStart=true,x=.3,y=.3}}
 end
 provider:OnMapChanged()
 local pickupPin
 for _,f in ipairs(frames) do if f.parent==canvas.id and f.visible and f.entry and f.entry.pickup then pickupPin=f end end
 assert(pickupPin and #pickupPin.pickups==2 and pickupPin.badge.texture=="Interface\\GossipFrame\\AvailableQuestIcon","unaccepted quests use native exclamation artwork and cluster")
 local oldPickupShift,oldPickupNav=IsShiftKeyDown,ForeverCompanionQuestWaypoints.Navigate
 IsShiftKeyDown=function() return true end
 pickupPin:OnClick()
 assert(pickupPin.entry.quest.id==888,"shift click chooses the second unaccepted quest")
 local chosenPickup
 IsShiftKeyDown=function() return false end
 ForeverCompanionQuestWaypoints.Navigate=function(target) chosenPickup=target;return "Quest pickup selected" end
 pickupPin:OnClick()
 assert(chosenPickup and chosenPickup.map==pickupPin.entry.target.map and chosenPickup.x==pickupPin.entry.target.x and chosenPickup.y==pickupPin.entry.target.y,"click navigates to revalidated quest-giver coordinates")
 IsShiftKeyDown,ForeverCompanionQuestWaypoints.Navigate=oldPickupShift,oldPickupNav
 mapModeButton("Pickups: On"):OnClick()
 assert(not pickupPin.visible,"pickup toggle hides unaccepted quests")
 mapModeButton("Pickups: Off"):OnClick()
 C_QuestLog.GetQuestsOnMap,C_QuestLog.GetTitleForQuestID=oldPOIs,oldTitle
 local dockAPI=ForeverCompanionQuestMap;local beforeMinimize=visiblePins();local expandedBefore=ForeverCompanionDB.mapDockExpanded
 dockAPI.minimizeMapDock.OnClick();assert(ForeverCompanionDB.mapDockMinimized and dockAPI.mapDock:GetWidth()==190 and dockAPI.mapDock:GetHeight()==30,'map dock minimizes to compact restore strip')
 assert(not dockAPI.mapDockFind:IsShown() and not dockAPI.mapDockHint:IsShown() and not dockAPI.mapDockCoordinates:IsShown(),'minimized panel hides map-obscuring content')
 assert(visiblePins()==beforeMinimize,'minimizing does not hide or navigate map pins')
 provider:OnMapChanged();assert(dockAPI.mapDock:GetWidth()==190 and not dockAPI.mapDockHint:IsShown(),'map refresh preserves minimized preference')
 exportNative('ui_map_minimized_369_native.json')
 dockAPI.minimizeMapDock.OnClick();assert(not ForeverCompanionDB.mapDockMinimized and dockAPI.mapDock:GetWidth()==520 and dockAPI.mapDockFind:IsShown() and ForeverCompanionDB.mapDockExpanded==expandedBefore,'restoring preserves drawer preference')
 exportNative('ui_map_toolbar_native.json')
 provider:OnHide()
 assert(visiblePins()==0 and not area.visible)
 WorldMapFrame.IsShown=function() return false end
 WorldMapFrame,MapCanvasDataProviderMixin,CreateFromMixins=nil,nil,nil
 C_Map,MapUtil,GetCVarBool,CreateFrame=originalMap,originalUtil,originalCVar,create
end
do
 local journey=ForeverCompanionJourney
 assert(journey.Route(2,15,"Alliance","Human")[1][2]==1436)
 assert(journey.Route(2,11,"Horde","Skyborne")[1][2]==2521)
 assert(journey.Route(2,15,"Horde","Scourge")[1][2]==1421)
 assert(#journey.Route(2,15,nil,nil)==0)
 local a,b={complete=true},{}
 assert(journey.Recommend({a,b},{{quest=b}},a)==b,"prefer a nearby objective over a remote turn-in")
 assert(journey.Recommend({a,b},{{quest=b},{quest=a}},b)==a,"turn in a nearby ready quest before a nearby objective")
 SlashCmdList.FOREVERCOMPANION("open leveling route")
 assert(ForeverCompanionDB.tab=="Journey","the leveling route is reachable from normal navigation")
 local found
 for _,frame in ipairs(frames) do
  if frame.OnClick and frame.text=="Find on map" and frame.enabled then found=true end
 end
 assert(found,"leveling route shows map action for a live quest")
 exportNative("ui_journey_native.json")
 SlashCmdList.FOREVERCOMPANION("open quests")
end
do
 local originalBank,originalContainer,originalEnum,originalTime,originalDate=C_Bank,C_Container,Enum,GetServerTime,date
 Enum={BankType={Character=0}}
 GetServerTime=function() return 100 end
 date=os.date
 C_Bank={CanViewBank=function(kind) return kind==0 end,FetchPurchasedBankTabData=function()
  return {{ID=6,name="Supplies"},{ID=7,name="Gear"}}
 end}
 local stacks=4
 C_Container={GetContainerNumSlots=function() return 2 end,GetContainerItemInfo=function(id,slot)
  if id==7 and slot==1 then return {itemID=1234,stackCount=stacks,hyperlink="|Hitem:1234|h[Sample ore]|h"} end
 end}
 local bankEvent
 for _,frame in ipairs(frames) do if frame.events and frame.events.BANKFRAME_OPENED then bankEvent=frame;break end end
 assert(bankEvent)
 bankEvent:OnEvent("BANKFRAME_OPENED")
 local snapshot=assert(ForeverCompanionDB.bankSnapshot)
 assert(#snapshot.items==1 and snapshot.slots==4 and snapshot.items[1].count==4 and snapshot.items[1].tab=="Gear")
 stacks=6
 bankEvent:OnEvent("PLAYERBANKSLOTS_CHANGED")
 assert(ForeverCompanionDB.bankSnapshot.items[1].count==6)
 C_Container.GetContainerNumSlots=function() return 0 end
 bankEvent:OnEvent("BAG_UPDATE_DELAYED")
 assert(ForeverCompanionDB.bankSnapshot.items[1].count==6,"incomplete reads preserve the last good snapshot")
 bankEvent:OnEvent("BANKFRAME_CLOSED")
 C_Container.GetContainerNumSlots=function() error("must not read the bank remotely") end
 bankEvent:OnEvent("BAG_UPDATE_DELAYED")
 SlashCmdList.FOREVERCOMPANION("bank")
 local found
 for _,frame in ipairs(frames) do if frame.text=="Sample ore" then found=true end end
 assert(ForeverCompanionDB.tab=="Bank" and found,"bank items remain viewable after leaving the banker")
 assert(ForeverCompanionBankView.GetHeight()<250,'short bank lists should use a compact panel')
 exportNative('ui_bank_native.json')
 SlashCmdList.FOREVERCOMPANION("open quests")
 C_Bank,C_Container,Enum,GetServerTime,date=originalBank,originalContainer,originalEnum,originalTime,originalDate
end
local originalComplete=C_QuestLog.IsComplete
C_QuestLog.IsComplete=function() return false end
assert(ForeverCompanionQuestPlanner.Sync(),"non-ready quest fixture should sync")
ForeverCompanionQuestPlanner.Select(1)
ForeverCompanionDashboard.Render()
assert(step1.detail:find("Pinned priority: Sample: Speak with trainer",1,true),"dashboard must prefer unfinished pinned quest")
step1.OnClick(step1)
assert(ForeverCompanionQuestPlanner.GetSelected().title=="Sample: Speak with trainer","dashboard pin recommendation must focus selected priority")
C_QuestLog.IsComplete=originalComplete
assert(ForeverCompanionQuestPlanner.Sync(),"ready quest fixture should recover")
exportSnapshot("ui_quest_snapshot.txt")
exportNative("ui_quest_native.json")
do
 local originalPickups=ForeverCompanionQuestWaypoints.MapPickups
 local originalNavigate=ForeverCompanionQuestWaypoints.Navigate
 local originalMap=C_Map
 local map=1429
 C_Map={GetBestMapForUnit=function() return map end,GetMapInfo=function() return {name='Sample forest'} end}
 local sample={quest={id=900001,title='Sample: Help the outpost',level=60},target={map=map,x=.23,y=.46,label='Sample quartermaster'},reference=true}
 local client={quest={id=900001,title='Sample: Help the outpost',level=60},target={map=map,x=.21,y=.43,label='Sample scout'}}
 local fixture={sample,client}
 ForeverCompanionQuestWaypoints.MapPickups=function() return fixture end
 local navigated
 ForeverCompanionQuestWaypoints.Navigate=function(target,showMap,title) navigated=target;return 'Test waypoint selected' end
 SlashCmdList.FOREVERCOMPANION('discover')
 ForeverCompanionQuestDiscovery.Refresh()
 local row
 for _,frame in ipairs(frames) do if frame.kind=='Button' and frame.item and frame.item.quest.id==900001 then row=frame;break end end
 assert(row and #row.item.targets==2)
 row.OnClick(row)
 row.cycle.OnClick(row.cycle)
 row.go.OnClick(row.go)
 assert(navigated and navigated.x==.23,'selected reference giver must be navigated instead of first giver')
 assert(ForeverCompanionQuestDiscovery.GetHeight()<500,'one quest should not leave four rows of empty list space')
 exportNative('ui_discovery_native.json')
 -- Provider refreshes may reorder locations; selection follows coordinates.
 fixture={client,sample};ForeverCompanionQuestDiscovery.Refresh()
 row.go.OnClick(row.go);assert(navigated.x==.23,'giver identity survives provider reordering')
 fixture={};navigated=nil;ForeverCompanionQuestDiscovery.Navigate()
 assert(navigated==nil,'pickup click must revalidate removal before the next UI refresh')
 ForeverCompanionQuestDiscovery.Refresh()
 local detailGo
 for _,frame in ipairs(frames) do if frame.kind=='Button' and frame.text=='Navigate to giver' then detailGo=frame end end
 assert(detailGo and detailGo.enabled==false,'stale quest disappears and disables navigation')
 assert(ForeverCompanionQuestDiscovery.GetHeight()>500,'empty discovery must reserve readable explanation space')
 exportNative('ui_discovery_empty_native.json')
 ForeverCompanionQuestWaypoints.MapPickups=originalPickups
 ForeverCompanionQuestWaypoints.Navigate=originalNavigate
 C_Map=originalMap
 ForeverCompanionQuestDiscovery.Refresh()
end
local originalQuestCount=C_QuestLog.GetNumQuestLogEntries
C_QuestLog.GetNumQuestLogEntries=function() error("temporary quest API failure") end
assert(ForeverCompanionQuestPlanner.Sync()==false,"failed quest scan must not be reported successful")
local staleWarning=false
for _,w in ipairs(frames) do
 if w.text=="Cached. Check your quest log." then staleWarning=true end
end
assert(staleWarning,"quest briefing must warn about cached data")
ForeverCompanionDashboard.Render()
assert(sourceLabel.text:find("CACHED - VERIFY IN GAME",1,true),"dashboard must disclose stale quest data")
assert(bannerStatus.text:find("Quest snapshot stale",1,true),"welcome briefing must not report stale quests as live")
assert(step1.detail:find("Quest API unavailable",1,true),"stale quest snapshot must not generate a live recommendation")
assert(metricButtons.Quests.detail=="N/A","stale quest progress must not display an old readiness ratio")
C_QuestLog.GetNumQuestLogEntries=originalQuestCount
assert(ForeverCompanionQuestPlanner.Sync(),"quest scanner should recover after transient error")
local bannerText
for _,w in ipairs(frames) do if w.text=="ADVENTURE JOURNAL" then bannerText=w end end
assert(bannerText and frames[frames[bannerText.parent].parent].visible==false,"dashboard should hide outside Overview")
local overviewButton
for _,w in ipairs(frames) do if w.section=="Overview" then overviewButton=w end end
assert(overviewButton and overviewButton.OnClick,"sidebar overview navigation missing")
overviewButton.OnClick(overviewButton)
assert(ForeverCompanionDB.tab=="Overview","overview navigation failed")
assert(not frames[questBriefingRoot].visible,"quest briefing must hide on overview")
local recommendedStep
for _,w in ipairs(frames) do
 if w.caption and w.caption.text:find("Review Warrior leveling",1,true) then recommendedStep=w end
end
assert(recommendedStep and recommendedStep.OnClick,"recommended step should be clickable")
recommendedStep.OnClick(recommendedStep)
assert(ForeverCompanionDB.tab=="Leveling","recommended step did not open Leveling")
overviewButton.OnClick(overviewButton)
local professionButton
for _,w in ipairs(frames) do if w.section=="Professions" then professionButton=w end end
assert(professionButton and professionButton.OnClick,"profession sidebar navigation missing")
professionButton.OnClick(professionButton)
local skillHeading,materialsHeading
for _,w in ipairs(frames) do
 if w.text=="PROFESSION SKILLS" then skillHeading=w end
 if w.text=="MATERIAL GOALS" then materialsHeading=w end
end
assert(skillHeading and materialsHeading,"profession briefing panels missing")
assert(frames[frames[skillHeading.parent].parent].visible,"profession briefing must be visible")
local alchemyTab
for _,w in ipairs(frames) do
 if w.label and w.icon and w.bg and w.trim and w.label.text=="Alchemy" then alchemyTab=w end
end
assert(alchemyTab and alchemyTab.OnClick,"styled profession handbook selector missing")
alchemyTab.OnClick(alchemyTab)
assert(alchemyTab.selected,"selected profession handbook tab should highlight")
for _,name in ipairs({'Cooking','First Aid','Fishing'}) do
 local found
 for _,w in ipairs(frames) do if w.label and w.icon and w.bg and w.trim and w.label.text==name then found=w end end
 assert(found and found:IsShown() and found.width==120,'secondary profession selector must be directly visible')
 found.OnClick(found);assert(found.selected)
end
alchemyTab.OnClick(alchemyTab)

local notesToggle=ForeverCompanionUIState.professionNotesButton
assert(notesToggle.visible and notesToggle.text=="Profession reference","profession reference is discoverable")
notesToggle:OnClick()
local professionReference
for _,w in ipairs(frames) do if w.name=="ForeverCompanionReferenceFrame" then professionReference=w end end
assert(professionReference and professionReference:IsShown(),"details open in a separate window")
professionReference:Hide()
local materialStatus=false
for _,w in ipairs(frames) do if w.text=="0/1 material goals done" then materialStatus=true end end
assert(materialStatus,"manual material goal status incorrect")
ForeverCompanionProfessionBriefing.Render("Blacksmithing")
local shortageFound=false
for _,w in ipairs(frames) do
 if w.text=="Selected guide shortage: Sample Ore x6" then shortageFound=true end
end
assert(shortageFound,"selected profession should show its largest manual shortage")
ForeverCompanionProfessionBriefing.Render("Alchemy")
exportSnapshot("ui_profession_snapshot.txt")
exportNative("ui_profession_native.json")
-- Full manual-goal workflow stays in the UI and preserves failed edits.
local materialsUI=ForeverCompanionMaterialWorkspace
local planner=ForeverCompanionCraftingPlanner
materialsUI.fields.name:SetText("Review herb")
materialsUI.fields.needed:SetText("12");materialsUI.fields.owned:SetText("3")
materialsUI.save:OnClick()
assert(planner.GetEntries("Alchemy")[1].name=="Review herb")
materialsUI.rows[1].edit:OnClick()
materialsUI.fields.name:SetText("Renamed review herb")
materialsUI.fields.needed:SetText("15");materialsUI.fields.owned:SetText("5")
materialsUI.save:OnClick()
assert(planner.GetEntries("Alchemy")[1].needed==15 and planner.GetEntries("Alchemy")[1].owned==5)
materialsUI.rows[1].edit:OnClick()
materialsUI.fields.needed:SetText("-1")
materialsUI.save:OnClick()
assert(planner.GetEntries("Alchemy")[1].needed==15,"invalid form edits must not overwrite a saved goal")
materialsUI.cancel:OnClick()
materialsUI.rows[1].edit:OnClick()
assert(planner.Update("Alchemy",1,"Changed externally",20,7))
materialsUI.save:OnClick()
assert(planner.GetEntries("Alchemy")[1].name=="Changed externally","stale form edits must not replace a changed goal")
materialsUI.cancel:OnClick()
materialsUI.rows[1].remove:OnClick()
assert(#planner.GetEntries("Alchemy")==0,"remove only changes manual planning data")

assert(ForeverCompanionCraftingPlanner.SetOwned("Blacksmithing",1,10),"material goal should update")
ForeverCompanionProfessionBriefing.Render("Blacksmithing")
local completedStatus=false
for _,w in ipairs(frames) do if w.text=="1/1 material goals done" then completedStatus=true end end
assert(completedStatus,"material briefing must refresh after manual update")
assert(ForeverCompanionCraftingPlanner.SetOwned("Blacksmithing",1,4))
local originalGetProfessions=GetProfessions
GetProfessions=nil
ForeverCompanionProfessionBriefing.Render("Blacksmithing")
local unavailableStatus=false
for _,w in ipairs(frames) do if w.text=="Profession API unavailable on this client." then unavailableStatus=true end end
assert(unavailableStatus,"profession briefing must show unavailable API")
GetProfessions=originalGetProfessions
ForeverCompanionProfessionBriefing.Render("Blacksmithing")
overviewButton.OnClick(overviewButton)
local compactButton,mainWindow
for _,w in ipairs(frames) do
 if w.OnClick and w.text=="Compact" then compactButton=w end
 if w.width==1080 and w.height==720 then mainWindow=w end
end
assert(mainWindow and mainWindow.scale and mainWindow.scale<1,"responsive scale not applied")
UIParent:SetSize(680,480)
addonFrame.OnEvent(addonFrame,"DISPLAY_SIZE_CHANGED")
assert(mainWindow.scale<0.61,"window should shrink when display becomes smaller")
UIParent:SetSize(1000,700)
addonFrame.OnEvent(addonFrame,"UI_SCALE_CHANGED")
assert(mainWindow.scale>0.8,"window should recover scale after display restores")
local originalWidth=UIParent.GetWidth
UIParent.GetWidth=function() error("restricted parent geometry") end
assert(pcall(addonFrame.OnEvent,addonFrame,"UI_SCALE_CHANGED"),"restricted geometry must not crash resize")
UIParent.GetWidth=originalWidth
assert(compactButton and compactButton.OnClick,"compact toggle missing")
compactButton.OnClick(compactButton)
assert(mainWindow.height==620 and ForeverCompanionDB.compact,"compact layout failed")
for _,nav in ipairs(frames) do
 if nav.section then assert(-nav.point[5]+nav.height<=528,"compact navigation must stay above the footer") end
end
local focusTitle
for _,w in ipairs(frames) do if w.text=="TODAY\'S FOCUS" then focusTitle=w end end
assert(focusTitle and frames[focusTitle.parent].visible==false,"compact mode should hide lower focus panel")
compactButton.OnClick(compactButton)
assert(mainWindow.height==720 and not ForeverCompanionDB.compact,"expand layout failed")
assert(frames[focusTitle.parent].visible==(ForeverCompanionDB.beginnerMode==false),"expanded mode respects beginner view")
local savedXP=UnitXP
UnitXP=function() error("simulated restricted XP API") end
assert(pcall(ForeverCompanionDashboard.Render),"dashboard should tolerate restricted XP reads")
local xpUnavailable=false
for _,w in ipairs(frames) do if w.kind=="FontString" and w.text=="N/A" then xpUnavailable=true end end
assert(xpUnavailable,"unavailable XP should be labeled N/A")
UnitXP=savedXP
ForeverCompanionDashboard.Render()
SlashCmdList.FOREVERCOMPANION("")
SlashCmdList.FOREVERCOMPANION("")
local foundTitle=false
for _,f in ipairs(frames) do
 if f.text=="Brady\'s Forever Companion" then foundTitle=true end
end
assert(foundTitle,"main window title not rendered")
local foundBanner=false
for _,f in ipairs(frames) do if f.text=="ADVENTURE JOURNAL" then foundBanner=true end end
assert(foundBanner,"premium dashboard welcome banner missing")
local heraldicMarks=0
for _,w in ipairs(frames) do
 if w.kind=="Texture" and w.texture=="Interface\\AddOns\\ForeverCompanion\\Media\\Crest.tga" then heraldicMarks=heraldicMarks+1 end
end
assert(heraldicMarks>=2,"header and dashboard must use the same original heraldic crest")
-- Exercise the native class-guide hero and capture its real mock widget tree.
local levelingButton
for _,w in ipairs(frames) do if w.section=="Leveling" then levelingButton=w end end
assert(levelingButton and levelingButton.OnClick,"leveling sidebar navigation missing")
levelingButton.OnClick(levelingButton)
assert(ForeverCompanionDB.tab=="Leveling","leveling navigation failed")
local classHeading,rotationControl
for _,w in ipairs(frames) do
 if w.text=="CLASS GUIDES  /  WARRIOR" then classHeading=w end
 if w.OnClick and w.text=="Rotation: leveling" then rotationControl=w end
end
assert(classHeading,"wide class banner breadcrumb missing")
SlashCmdList.FOREVERCOMPANION("open class guides")
assert(ForeverCompanionDB.tab=="Leveling","visible Class Guides label must work in slash navigation")
local specControl
for _,w in ipairs(frames) do if w.OnClick and w.text=="Spec: Arms" then specControl=w end end
assert(specControl and specControl.parent==mainWindow.id,"header specialization selector must avoid scroll-child clipping")
do
 local saved=ForeverCompanionDB.specSelections.WARRIOR
 specControl.OnClick()
 local fury
 for _,f in ipairs(frames) do if f.kind=='Button' and f.text=='Fury' and f.OnClick then fury=f end end
 assert(fury,'specialization control must expose direct choices');fury.OnClick()
 assert(ForeverCompanionDB.specSelections.WARRIOR==2,'menu choice must persist the selected specialization')
 ForeverCompanionDB.specSelections.WARRIOR=saved;ForeverCompanionRefresh()
 local role=ForeverCompanionDB.role
 ForeverCompanionUIState.roleButton.OnClick()
 local tank
 for _,f in ipairs(frames) do if f.kind=='Button' and f.text=='Tank' and f.OnClick then tank=f end end
 assert(tank);tank.OnClick();assert(ForeverCompanionDB.role=='Tank')
 ForeverCompanionDB.role=role;ForeverCompanionRefresh()
end
do
 local previousCompact=ForeverCompanionDB.compact
 for _,compact in ipairs({false,true}) do
  ForeverCompanionDB.compact=compact;ForeverCompanionRefresh()
  local meter=ForeverCompanionUIState.meterButton
  local role=ForeverCompanionUIState.roleButton
  assert(meter.point[4]<=specControl.point[4]-specControl.width-8,'meter must clear the specialization selector')
  assert(specControl.point[4]<=role.point[4]-role.width-8,'specialization must clear the role selector')
  assert(meter.point[5]==role.point[5] and meter.height==role.height and specControl.height==role.height,'header controls must share a baseline and height')
 end
 ForeverCompanionDB.compact=previousCompact;ForeverCompanionRefresh()
end
assert(#ForeverCompanionClassGuide.topicButtons==8,"class guide requires eight functional topic tabs")
local classScroll
for _,w in ipairs(frames) do
 if w.kind=="ScrollFrame" and w.parent==mainWindow.id then classScroll=w end
end
assert(classScroll,"class guide requires a scroll viewport")
for _,button in ipairs(ForeverCompanionClassGuide.topicButtons) do
 classScroll:SetVerticalScroll(350)
 button.OnClick()
 assert(ForeverCompanionClassGuide.GetView()==button.view,"topic selection must persist")
 assert(classScroll:GetVerticalScroll()==0,"switching guide topics returns to the heading")
 assert(ForeverCompanionClassGuide.topicPanel.visible==(button.view~="Rotations"),"topic panel visibility")
 if button.view=="Talents" then
  assert(ForeverCompanionTalentWorkspace.root:IsShown(),"talent planner visibility")
 elseif button.view~="Rotations" and button.view~="Macros" then
  local browser=ForeverCompanionClassGuide.browser
  assert(browser.frame:IsShown() and #browser.items>0 and browser.body.text~="","topic browser opens a specific topic")
 end
end
ForeverCompanionClassGuide.SelectView("Gear & Stats")
exportNative("ui_gear_native.json")
ForeverCompanionClassGuide.SelectView("Talents")
do
 local model=ForeverCompanionTalentPlanner
 local talents=ForeverCompanionTalentData
 local planner=ForeverCompanionTalentWorkspace
 local count,trees=0,0
 assert(model.Budget(9)==0 and model.Budget(10)==1 and model.Budget(60)==51)
 for class,data in pairs(talents.classes) do
  local positions={}
  for _,node in ipairs(data.nodes) do
   local position=table.concat({node[2],node[3],node[4]},":")
   assert(not positions[position] and node[7]>0 and node[8]>0,node[9])
   positions[position]=true
   count=count+1
  end
  for _,specEntry in ipairs(ForeverCompanionSpecs[class]) do
   local name=specEntry[1]
   local recommendation=assert(model.Recommendation(class,name),class.." / "..name)
   local draft={}
   assert(model.CopyRecommendation(class,name,draft))
   assert(model.Total(class,draft)==51 and not model.CopyRecommendation(class,name,draft))
   local replay={}
   local count=0
   while count<51 do
    local before=count
    for _,node in ipairs(data.nodes) do
     local target=draft[node[1]] or 0
     assert(target<=node[6],node[9])
     while model.Rank(replay,node)<target and model.Change(class,replay,node,1,51) do
      count=count+1
     end
    end
    assert(count>before,class.." / "..name.." has an unreachable recommendation")
   end
   for id,rank in pairs(recommendation[3]) do assert(replay[id]==rank) end
  end
  for tree=1,3 do
   local spec=ForeverCompanionSpecs[class][tree][1]
   local opening=model.Opening(class,tree,spec)
   assert(#opening>=2 and #model.Goals(class,tree,spec)==3,spec)
   local draft={}
   assert(model.LoadOpening(class,tree,spec,draft,11),spec)
   assert(model.Rank(draft,opening[1])==opening[1][6],opening[1][9])
   assert(not model.LoadOpening(class,tree,spec,draft,51),"opening must preserve existing drafts")
   local full={}
   assert(model.LoadOpening(class,tree,spec,full,51),spec)
   for _,node in ipairs(opening) do assert(model.Rank(full,node)==node[6],spec.." / "..node[9]) end
   local first={}
   assert(model.LoadOpening(class,tree,spec,first,1) and model.Total(class,first)==1,spec)
   trees=trees+1
  end
 end
 assert(count==467 and trees==27)
 local bear={}
 assert(model.LoadOpening("DRUID",2,"Guardian / Bear",bear,51))
 for _,node in ipairs(model.Opening("DRUID",2,"Guardian / Bear")) do assert(model.Rank(bear,node)==node[6]) end
 local warrior=talents.classes.WARRIOR.nodes
 local arms={}
 assert(not model.Change("WARRIOR",arms,warrior[4],1,51),"tier gate")
 for _=1,5 do assert(model.Change("WARRIOR",arms,warrior[2],1,51)) end
 assert(not model.Change("WARRIOR",arms,warrior[2],1,51),"rank cap")
 assert(model.Change("WARRIOR",arms,warrior[4],1,51))
 assert(not model.Change("WARRIOR",arms,warrior[2],-1,51),"refund cannot break tier")
 assert(model.Rank(arms,warrior[2])==5)
 local second={}
 for _,index in ipairs({2,3,5}) do
  for _=1,warrior[index][6] do assert(model.Change("WARRIOR",second,warrior[index],1,51)) end
 end
 assert(model.Change("WARRIOR",second,warrior[8],1,51))
 assert(not model.Change("WARRIOR",second,warrior[3],-1,51),"refund cannot break direct prerequisite")
 local allocation=model.Load("WARRIOR","Arms")
 local other=model.Load("WARRIOR","Fury")
 planner.buttons[1]:OnClick("LeftButton")
 assert(model.Rank(allocation,planner.buttons[1].node)==1 and model.Total("WARRIOR",other)==0)
 planner.buttons[1]:OnClick("RightButton")
 assert(model.Total("WARRIOR",allocation)==0)
 planner.buildButton:OnClick()
 assert(model.Total("WARRIOR",allocation)>0 and model.Load("WARRIOR","Arms")==allocation)
 local openingTotal=model.Total("WARRIOR",allocation)
 planner.recommendationButton:OnClick()
 assert(planner.recommendationButton.text=="Back to My Draft")
 assert(planner.buildButton.text=="Copy to empty draft" and not planner.lowerLevel.enabled)
 exportNative("ui_topic_native.json")
 planner.buttons[1]:OnClick("LeftButton")
 planner.buttons[1]:OnClick("RightButton")
 planner.buildButton:OnClick()
 assert(model.Total("WARRIOR",allocation)==openingTotal,"preview and copy guard preserve the draft")
 planner.recommendationButton:OnClick()
 assert(planner.buildButton.text=="Load opening ranks" and planner.lowerLevel.enabled)
 planner.tabs[2]:OnClick()
 assert(planner.buttons[1].node[2]==2)
 planner.tabs[1]:OnClick()
 planner.lowerLevel:OnClick()
 assert(model.Level(allocation)==59 and model.Level(other)==60)
 ForeverCompanionSpecPlanner.Next("WARRIOR")
 ForeverCompanionRefresh()
 planner.lowerLevel:OnClick()
 planner.lowerLevel:OnClick()
 assert(model.Level(other)==58 and model.Level(allocation)==59,"level belongs to the active spec draft")
 ForeverCompanionDB.specSelections.WARRIOR=1
 ForeverCompanionRefresh()
 assert(model.Level(model.Load("WARRIOR","Arms"))==59,"switching specs preserves the saved level")
 planner.resetButton:OnClick()
 assert(model.Total("WARRIOR",allocation)>0,"reset needs confirmation")
 planner.resetButton:OnClick()
 assert(model.Total("WARRIOR",allocation)==0 and model.Level(allocation)==59,"confirmed reset clears ranks and preserves the plan level")
 planner.lowerLevel:OnClick()
 planner.recommendationButton:OnClick()
 planner.buildButton:OnClick()
 assert(model.Total("WARRIOR",allocation)==51 and model.Level(allocation)==60 and planner.recommendationButton.text=="Recommended Build")
 planner.resetButton:OnClick()
 planner.resetButton:OnClick()
end
assert(not ForeverCompanionClassGuide.SelectView("Not a topic"),"invalid topic must be rejected")
ForeverCompanionDB.classGuideView="malformed saved view"
assert(ForeverCompanionClassGuide.GetView()=="Rotations","invalid saved topic must recover to rotation view")
ForeverCompanionClassGuide.SelectView("Rotations")
local currentFocus=false
for _,w in ipairs(frames) do
 if w.text:find("FOCUS: At higher levels",1,true)==1 then currentFocus=true end
end
assert(currentFocus,"leveling hero must display class-specific current stage focus")
local unifiedCards=0
for _,w in ipairs(frames) do
 if w.fcPanelEdges and w.fcPanelBackground then
  unifiedCards=unifiedCards+1
  assert(w.fcPanelBackground.color[1]<.06,"shared cards retain a dark reading surface")
 end
end
assert(unifiedCards>=12,"guide and utility cards share the same surface system")
assert(frames[classHeading.parent].visible,"class-guide header should be visible on Leveling")
assert(rotationControl and rotationControl.point and rotationControl.point[1]=="TOPLEFT","rotation control should be in content area")
local workspace=ForeverCompanionRotationWorkspace
assert(workspace.rows[1].visible and workspace.rows[1].number.text=="1","first priority is visible inside its panel")
-- All nine class-preview buttons must be interactive, and must not mutate the player.
local savedPreviewRole=ForeverCompanionDB.role
local classTokens={"WARRIOR","PALADIN","HUNTER","ROGUE","PRIEST","SHAMAN","MAGE","WARLOCK","DRUID"}
assert(ForeverCompanionClassStripButtons and #ForeverCompanionClassStripButtons==9,"class strip must offer all nine classes")
for i,token in ipairs(classTokens) do
 local button=ForeverCompanionClassStripButtons[i]
 assert(button.classToken==token and button.OnClick and button.visible,"class strip button missing or hidden")
 button.OnClick(button)
 assert(ForeverCompanionDB.previewClass==token,"class selector did not update addon preview")
 for _,topicButton in ipairs(ForeverCompanionClassGuide.topicButtons) do
  topicButton.OnClick()
  assert(ForeverCompanionClassGuide.GetView()==topicButton.view,"topic navigation must work for every class")
 end
 ForeverCompanionClassGuide.SelectView("Rotations")
 for _,contextButton in ipairs(ForeverCompanionRotationWorkspace.buttons) do
  contextButton.OnClick()
  local reference,_,_,_,primary,summary=ForeverCompanionVisiblePriority(token,contextButton.mode,60,nil,ForeverCompanionRotations[token][contextButton.mode])
  for index,step in ipairs(workspace.Plan(reference,primary,"WARRIOR",token,summary)) do
   local row=workspace.rows[index]
   assert(row and row.visible and row.parent==workspace.panel.id,"all steps must be shown inside the priority panel")
   assert(row.instruction==step.text,"row must show the complete instruction")
  end
  for index=#reference+1,#workspace.rows do assert(not workspace.rows[index].visible,"stale priority row") end
 end
end
ForeverCompanionClassStripButtons[1].OnClick(ForeverCompanionClassStripButtons[1])
ForeverCompanionRotationWorkspace.buttons[1].OnClick()
-- Clear preview before testing unavailable live class APIs.
ForeverCompanionDB.previewClass=nil
ForeverCompanionDB.role=savedPreviewRole
ForeverCompanionRefresh()

local classSnapshot={}
for _,f in ipairs(frames) do
 local anchor=f.point and clean(f.point[1]) or ""
 local x,y="",""
 if f.point then
  for _,v in ipairs(f.point) do if type(v)=="number" then if x=="" then x=v else y=v end end end
 end
 classSnapshot[#classSnapshot+1]=table.concat({f.id,f.kind,f.parent or "",f.visible and "1" or "0",f.width or "",f.height or "",anchor,x,y,clean(f.text),clean(f.texture)},"|")
end
local classOut=assert(io.open("ui_leveling_snapshot.txt","w"))
classOut:write("id|kind|parent|visible|width|height|anchor|x|y|text|texture",string.char(10))
classOut:write(table.concat(classSnapshot,string.char(10)))
classOut:close()
exportNative("ui_class_native.json")
assert(#workspace.buttons==5,"direct context navigation must expose every context")
for i,button in ipairs(workspace.buttons) do
 button.OnClick()
 assert(rotationControl.text=="Rotation: "..({"leveling","dungeon","boss","aoe","pvp"})[i])
 assert(workspace.rows[1].visible,"selected context must show its first priority")
end
workspace.buttons[1].OnClick()
assert(not workspace.TakeReferenceRequest(),"long notes must open on demand")
workspace.reference.OnClick()
local referenceFrame
for _,f in ipairs(frames) do if f.name=="ForeverCompanionReferenceFrame" then referenceFrame=f end end
assert(referenceFrame and referenceFrame:IsShown() and not workspace.TakeReferenceRequest(),"reference request opens its own window once")
referenceFrame:Hide()
local shortWorkspaceHeight=workspace.GetHeight()
local row=workspace.rows[1]
local originalMeasure=row.caption.GetStringHeight
row.caption.GetStringHeight=function() return 350 end
workspace.buttons[1].OnClick()
assert(row.height>=366 and workspace.GetHeight()>shortWorkspaceHeight,"long steps expand the card and panel")
local edges=workspace.panel.fcPanelEdges
assert(edges.left.height==workspace.panel.height,"resized left border follows panel")
exportNative("ui_long_priority_native.json")
row.caption.GetStringHeight=originalMeasure
workspace.buttons[1].OnClick()
assert(workspace.GetHeight()==shortWorkspaceHeight,"short content shrinks after expansion")
local savedPaladinSpec=ForeverCompanionDB.specSelections.PALADIN
ForeverCompanionDB.specSelections.PALADIN=2
local early,_,_,_,earlyPrimary=ForeverCompanionVisiblePriority("PALADIN","boss",11,"Tank",{})
assert(#early==3 and earlyPrimary[1]=="Seal of Fury" and earlyPrimary[3]=="Holy Strike")
assert(not table.concat(early):find("Consecration",1,true))
ForeverCompanionDB.specSelections.PALADIN=3
local ret=ForeverCompanionVisiblePriority("PALADIN","boss",11,"Damage",{})
assert(table.concat(ret):find("Seal of Righteousness",1,true) and not table.concat(ret):find("Seal of Fury",1,true))
ForeverCompanionDB.specSelections.PALADIN=savedPaladinSpec
local savedSpell=C_Spell
C_Spell={GetSpellInfo=function(name)
 if name=="Holy Strike" then return {name="Holy Strike",spellID=680,iconID=12345} end
end}
assert(ForeverCompanionIcons.SpellDetails(earlyPrimary[3]).spellID==680)
assert(not ForeverCompanionIcons.SpellDetails("Holy Strikeout"),"do not match partial spell names")
local scanSpellbook=ForeverCompanionSpellbook.Scan
local scans=0
ForeverCompanionSpellbook.Scan=function()
 scans=scans+1
 return {supported=true,complete=true,inspected=1,known={["holy strike"]=true}}
end
local plan=workspace.Plan(early,earlyPrimary,"PALADIN","PALADIN")
assert(plan[1].spell.spellID==680 and plan[1].status=="In your spellbook")
assert(plan[2].status:find("not found",1,true))
local preview=workspace.Plan(early,earlyPrimary,"WARRIOR","PALADIN")
assert(scans==1 and preview[1].status=="Class preview","other-class previews do not use the character's spellbook")
ForeverCompanionSpellbook.Scan=function() return {supported=true,complete=false,inspected=1,known={}} end
assert(workspace.Plan(early,earlyPrimary,"PALADIN","PALADIN")[1].status=="Training unconfirmed")
ForeverCompanionSpellbook.Scan=function() return {supported=true,complete=true,inspected=1,known={},englishNames=false} end
local localized,_,missing=workspace.Plan(early,earlyPrimary,"PALADIN","PALADIN")
assert(localized[1].status=="Training unconfirmed" and missing==0,"localized name mismatch is not a missing spell")
local refreshes=0
ForeverCompanionSpellbook.Scan=function()
 refreshes=refreshes+1
 return {supported=true,complete=true,inspected=1,known={}}
end
assert(addonFrame.events.SPELLS_CHANGED,"guide must subscribe to spellbook changes")
mainWindow:Show()
addonFrame.OnEvent(addonFrame,"SPELLS_CHANGED")
addonFrame.OnEvent(addonFrame,"SPELLS_CHANGED")
assert(refreshes==0,"event bursts should wait for one queued refresh")
ForeverCompanionRefreshQueue.Flush()
assert(refreshes>0,"visible class guide refreshes when the spellbook changes")
mainWindow:Hide()
refreshes=0
addonFrame.OnEvent(addonFrame,"SPELLS_CHANGED")
assert(refreshes==0,"hidden addon does not scan on spellbook changes")
addonFrame.OnEvent(addonFrame,"PLAYER_XP_UPDATE")
addonFrame.OnEvent(addonFrame,"PLAYER_ENTERING_WORLD")
ForeverCompanionQuestPlanner.Sync()
assert(refreshes==0,"hidden addon does not rebuild guidance on XP, zone or quest events")
mainWindow:Show()
ForeverCompanionSpellbook.Scan=scanSpellbook
C_Spell=savedSpell
local guide=ForeverCompanionClassGuide
local priorSelections=ForeverCompanionDB.specSelections
ForeverCompanionDB.specSelections={}
local specCount=0
for class,choices in pairs(ForeverCompanionSpecs) do
 for i,choice in ipairs(choices) do
  ForeverCompanionDB.specSelections[class]=i
  local overview=table.concat(guide.TopicLines(class,"Overview")," ")
  local previousView=ForeverCompanionDB.classGuideView
  ForeverCompanionDB.classGuideView='Gear & Stats'
  guide.Render(class,class,60,choice[2])
  local profile=ForeverCompanionGearStats.Get(class,choice[1])
  if profile then
   local browser=guide.browser
   assert(browser.items[1].title=='Stat priority' and browser.items[1].body:find(profile.order[1],1,true),'priority topic must use this specialization profile')
   local hasComparison=false
   for _,item in ipairs(browser.items) do if item.body==profile.note then hasComparison=true end end
   assert(hasComparison,'comparison topic must retain the full source note')
  end
  ForeverCompanionDB.classGuideView=previousView
  for _,mode in ipairs({"leveling","dungeon","boss","aoe","pvp"}) do
   local steps,title,_,_,_,summary=ForeverCompanionVisiblePriority(class,mode,60,nil,{})
   assert(#steps>=3 and title:find(choice[1],1,true) and summary and summary.opener,choice[1]..": missing "..mode.." instructions")
  end
  assert(overview:find(choice[1],1,true) and overview:find("3 BEGINNER ACTIONS",1,true))
  if choice[1]=="Guardian / Bear" then
   assert(overview:find("No published Forever priority",1,true))
  else
   specCount=specCount+1
   assert(overview:find("PUBLISHED FOREVER GUIDE",1,true))
   local boss,title,_,_,primary=ForeverCompanionVisiblePriority(class,"boss",60,nil,{})
   assert(#boss>=3 and title==choice[1].." / Boss","every standard spec has a boss priority in the rotation window")
   assert(#boss==#primary,"every row has a deliberate spell or non-spell cue")
   for index,name in ipairs(primary) do
    if name then assert(boss[index]:lower():find(name:lower(),1,true) or (name=="Power Word: Shield" and boss[index]:find("Shield",1,true)),title..": cue must match step "..index) end
   end
   if choice[1]=="Combat" then assert(overview:find("Blade Flurry",1,true)) end
   if choice[1]=="Beast Mastery" then assert(overview:find("Bestial Wrath",1,true)) end
   assert(overview:find("Reference: https://",1,true))
  end
 end
end
assert(specCount==27)
ForeverCompanionDB.specSelections=priorSelections
ForeverCompanionClassGuide.SelectView("Leveling")
local classBrowser=ForeverCompanionClassGuide.browser
local originalTopicMeasure=classBrowser.body.GetStringHeight
local originalHeight=ForeverCompanionClassGuide.GetTopicHeight()
classBrowser.body.GetStringHeight=function() return 480 end
classBrowser.rows[2].OnClick(classBrowser.rows[2])
assert(classBrowser.child:GetHeight()>=484,"long topics must scroll inside their own pane")
assert(ForeverCompanionClassGuide.GetTopicHeight()==originalHeight,"long topics must preserve panel size")
assert(classBrowser.rows[3].visible,'the next guide topic must remain available')
classBrowser.body.GetStringHeight=originalTopicMeasure
ForeverCompanionClassGuide.SelectView("Rotations")
workspace.buttons[1].OnClick()
rotationControl.OnClick(rotationControl)
assert(rotationControl.text=="Rotation: dungeon","rotation context selector failed")
overviewButton.OnClick(overviewButton)
assert(not frames[frames[classHeading.parent].parent].visible,"class guide should hide outside Leveling")
mockXP=2000
addonFrame.OnEvent(addonFrame,"PLAYER_XP_UPDATE")
ForeverCompanionRefreshQueue.Flush()
local xpUpdated=false
for _,w in ipairs(frames) do if w.kind=="FontString" and w.text=="67%" then xpUpdated=true end end
assert(xpUpdated,"XP event should refresh live progress")
mockXP=1500
addonFrame.OnEvent(addonFrame,"PLAYER_XP_UPDATE")
local savedClass,savedLevel=UnitClass,UnitLevel
UnitClass=function() error("class API restricted") end
UnitLevel=function() error("level API restricted") end
assert(pcall(ForeverCompanionRefresh),"restricted class and level must not crash the dashboard")
local unknownClass=false
for _,w in ipairs(frames) do
 if w.kind=="FontString" and w.text:find("Unknown class",1,true) then unknownClass=true end
end
assert(unknownClass,"missing class API must not impersonate Warrior")
UnitClass,UnitLevel=savedClass,savedLevel
ForeverCompanionRefresh()
-- The native Dungeon and PvP cards must be real widgets, reflect only manual
-- checklist state, and provide functional guide navigation without game actions.
local dungeonButton,pvpButton
for _,w in ipairs(frames) do
 if w.section=="Dungeons" then dungeonButton=w end
 if w.section=="PvP" then pvpButton=w end
end
assert(dungeonButton and pvpButton,"Dungeon/PvP sidebar entries missing")
dungeonButton.OnClick(dungeonButton)
assert(ForeverCompanionDB.tab=="Dungeons","Dungeon navigation failed")
local dungeonHeading,progressLabel
for _,w in ipairs(frames) do
 if w.text=="DUNGEON PREPARATION" then dungeonHeading=w end
 if w.text=="0/4 preparation tasks marked complete" then progressLabel=w end
end
assert(dungeonHeading and progressLabel,"native Dungeon briefing missing or miscounted")
local dungeonRoot=frames[dungeonHeading.parent].parent
assert(frames[dungeonRoot].visible,"Dungeon cards must be visible on Dungeon page")
local manualDone
for _,w in ipairs(frames) do
 if w.caption and w.caption.text=="Collect dungeon quests" and w.OnClick then manualDone=w end
end
assert(manualDone and manualDone.visible,"native Dungeon checklist tile missing")
manualDone.OnClick(manualDone)
assert(ForeverCompanionDB.checks.Dungeons[1]==true,"manual Dungeon task was not saved")
assert(manualDone.checked and manualDone.status.text=="DONE","Dungeon tile did not show completion")
assert(progressLabel.text=="1/4 preparation tasks marked complete","Dungeon card did not refresh manual progress")
exportSnapshot("ui_dungeon_snapshot.txt")
manualDone.OnClick(manualDone)
assert(ForeverCompanionDB.checks.Dungeons[1]==false,"Dungeon task undo failed")
local guideLink
for _,w in ipairs(frames) do
 if w.text=="OPEN CLASS GUIDE" and w.parent then guideLink=frames[w.parent] end
end
assert(guideLink and guideLink.OnClick,"native class-guide shortcut missing")
guideLink.OnClick(guideLink)
assert(ForeverCompanionDB.tab=="Leveling","native class-guide shortcut did not navigate")
pvpButton.OnClick(pvpButton)
assert(ForeverCompanionDB.tab=="PvP","PvP navigation failed")
local pvpHeading
for _,w in ipairs(frames) do if w.text=="PVP PREPARATION" then pvpHeading=w end end
assert(pvpHeading,"PvP preparation title did not update")
local pvpRoleAdvice=false
for _,w in ipairs(frames) do
 if w.kind=="FontString" and w.text:find("Coordinate target focus and avoid overextending",1,true) then pvpRoleAdvice=true end
end
assert(pvpRoleAdvice,"PvP role guidance must not reuse dungeon-only tank-target instructions")
assert(frames[dungeonRoot].visible,"PvP must reuse the same native briefing cards")
assert(progressLabel.text=="0/4 preparation tasks marked complete","PvP must have separate manual checklist progress")
local pvpDone
for _,w in ipairs(frames) do
 if w.caption and w.caption.text=="Check equipment" and w.OnClick then pvpDone=w end
end
assert(pvpDone and pvpDone.visible,"native PvP checklist tile missing")
pvpDone.OnClick(pvpDone)
assert(ForeverCompanionDB.checks.PvP[1]==true,"PvP task state was not saved")
assert(pvpDone.checked and pvpDone.status.text=="DONE","PvP tile did not show completion")
assert(progressLabel.text=="1/4 preparation tasks marked complete","PvP manual progress did not update")
assert(ForeverCompanionDB.checks.Dungeons[1]==false,"PvP state must not change Dungeon tasks")
exportSnapshot("ui_pvp_snapshot.txt")
exportNative("ui_pvp_native.json")
pvpDone.OnClick(pvpDone)
local questLink
for _,w in ipairs(frames) do
 if w.text=="OPEN QUEST JOURNAL" and w.parent then questLink=frames[w.parent] end
end
assert(questLink and questLink.OnClick,"native quest-journal shortcut missing")
questLink.OnClick(questLink)
assert(ForeverCompanionDB.tab=="Quests","native quest-journal shortcut failed")
assert(not frames[dungeonRoot].visible,"Adventure cards must hide on Quest page")
-- Settings is a real native interface, not merely a text-only command list.
local settingsNav
for _,w in ipairs(frames) do if w.section=="Settings" then settingsNav=w end end
assert(settingsNav and settingsNav.OnClick,"Settings navigation missing")
settingsNav.OnClick(settingsNav)
assert(ForeverCompanionDB.tab=="Settings","Settings navigation failed")
local settingsHeading,apiHeading,clientLabel
local autoButton,centerButton,compactSettingsButton
for _,w in ipairs(frames) do
 if w.text=="PREFERENCES & CHARACTER" then settingsHeading=w end
 if w.text=="CLIENT API VISIBILITY" then apiHeading=w end
 if w.text:find("Client: OfflineMock",1,true) then clientLabel=w end
 if w.caption and w.caption.text=="AUTO-DETECT CLASS" then autoButton=w end
 if w.caption and w.caption.text=="CENTER WINDOW" then centerButton=w end
 if w.caption and w.caption.text=="TOGGLE COMPACT" then compactSettingsButton=w end
end
assert(settingsHeading and apiHeading and clientLabel,"native Settings cards or client metadata missing")
local questApiDisclosure=false
local professionApiDisclosure=false
for _,w in ipairs(frames) do
 if w.text=="Quest log: API exposed; compatibility unverified" then questApiDisclosure=true end
 if w.text=="Professions: API exposed; compatibility unverified" then professionApiDisclosure=true end
end
assert(questApiDisclosure and professionApiDisclosure,"Settings must distinguish API exposure from live compatibility")
assert(frames[frames[settingsHeading.parent].parent].visible,"Settings cards should be visible")
assert(autoButton and centerButton and compactSettingsButton,"Settings preference actions missing")
SlashCmdList.FOREVERCOMPANION("class mage")
assert(ForeverCompanionDB.previewClass=="MAGE","fixture preview class selection failed")
autoButton.OnClick(autoButton)
assert(ForeverCompanionDB.previewClass==nil,"Settings auto class must reset only addon preview")
ForeverCompanionDB.position={x=20,y=30}
centerButton.OnClick(centerButton)
assert(ForeverCompanionDB.position==nil,"Settings center button should clear saved position")
local wasCompact=ForeverCompanionDB.compact
compactSettingsButton.OnClick(compactSettingsButton)
assert(ForeverCompanionDB.compact~=wasCompact,"Settings compact toggle did not persist")
local layoutTextFound=false
for _,w in ipairs(frames) do
 if w.text:find("Layout: ",1,true) and w.text:find(ForeverCompanionDB.compact and "Compact" or "Expanded",1,true) then layoutTextFound=true end
end
assert(layoutTextFound,"Settings layout summary did not refresh")
local originalBuildInfo=GetBuildInfo
GetBuildInfo=nil
assert(pcall(ForeverCompanionRefresh),"Settings must survive absent client build API")
local missingBuild=false
for _,w in ipairs(frames) do if w.text=="Client: Unknown  |  Interface: ?" then missingBuild=true end end
assert(missingBuild,"Settings must not invent a missing client Interface number")
GetBuildInfo=originalBuildInfo
ForeverCompanionRefresh()
exportSnapshot("ui_settings_snapshot.txt")
exportNative("ui_settings_native.json")
overviewButton.OnClick(overviewButton)
assert(not frames[frames[settingsHeading.parent].parent].visible,"Settings cards must hide on dashboard")
-- Notebook edits persist only when explicitly saved and are context-isolated.
SlashCmdList.FOREVERCOMPANION("open legacy")
local saveNote,clearNote
for _,w in ipairs(frames) do
 if w.OnClick and w.text=="Save research note" then saveNote=w end
 if w.OnClick and w.text=="Clear research note" then clearNote=w end
end
assert(saveNote and clearNote,"notebook controls missing")
local noteFields={}
for _,w in ipairs(frames) do
 if w.kind=="EditBox" and w.parent==saveNote.parent then noteFields[#noteFields+1]=w end
end
assert(#noteFields==3,"note/source/build inputs required")
noteFields[1]:SetText("Check exact unlock requirement")
noteFields[1].OnTextChanged(noteFields[1],true)
ForeverCompanionRefresh()
assert(noteFields[1]:GetText()=="Check exact unlock requirement","ordinary refresh must preserve unsaved input")
assert(ForeverCompanionResearchNotebook.Read(ForeverCompanionDB,"Legacy").note=="")
noteFields[2]:SetText("https://example.test/observation")
noteFields[3]:SetText("offline test build")
saveNote.OnClick()
assert(ForeverCompanionResearchNotebook.Read(ForeverCompanionDB,"Legacy").note=="Check exact unlock requirement")
SlashCmdList.FOREVERCOMPANION("open alts")
assert(noteFields[1]:GetText()=="","Alt notes must not show Legacy text")
noteFields[1]:SetText("Unsaved alt route")
noteFields[1].OnTextChanged(noteFields[1],true)
overviewButton.OnClick(overviewButton)
SlashCmdList.FOREVERCOMPANION("open alts")
assert(noteFields[1]:GetText()=="Unsaved alt route","session draft survives leaving research pages")
assert(ForeverCompanionResearchNotebook.Read(ForeverCompanionDB,"Alts").note=="","draft must not be saved implicitly")
noteFields[1].OnEscapePressed(noteFields[1])
assert(noteFields[1]:GetText()=="","Escape discards restored draft")
SlashCmdList.FOREVERCOMPANION("open legacy")
assert(noteFields[1]:GetText()=="Check exact unlock requirement")
noteFields[1]:SetText("Unsaved replacement")
noteFields[1].OnEscapePressed(noteFields[1])
assert(noteFields[1]:GetText()=="Check exact unlock requirement","Escape restores saved research")
clearNote.OnClick()
assert(ForeverCompanionResearchNotebook.Read(ForeverCompanionDB,"Legacy").note=="")
overviewButton.OnClick(overviewButton)
-- Exercise newly integrated pages through the actual manifest and native buttons.
local function buttonWithText(value)
 for _,w in ipairs(frames) do if w.OnClick and w.text==value then return w end end
end
SlashCmdList.FOREVERCOMPANION("open legacy")
local legacyState=ForeverCompanionStudyBoard.Get("Legacy","WARRIOR",ForeverCompanionDB)
assert(legacyState.total==5 and legacyState.done==0)
local legacyReference
for _,w in ipairs(frames) do
 if w.text:find("BLIZZARD LAUNCH REFERENCE",1,true) and w.text:find("launch cap of 16",1,true) then legacyReference=true end
end
assert(legacyReference,"Legacy handbook must show the published launch rules")
local studyRow
for _,w in ipairs(frames) do
 if w.kind=="FontString" and w.text==legacyState.tasks[1] then studyRow=frames[w.parent] end
end
assert(studyRow and studyRow.OnClick,"visible Legacy task must be clickable")
studyRow.OnClick(studyRow)
assert(ForeverCompanionStudyBoard.Get("Legacy","WARRIOR",ForeverCompanionDB).done==1)
exportSnapshot("ui_legacy_snapshot.txt")
exportNative("ui_legacy_native.json")
buttonWithText("ALT PREPARATION").OnClick()
assert(ForeverCompanionDB.tab=="Alts","Legacy shortcut should open alt desk")
assert(ForeverCompanionStudyBoard.Get("Alts","WARRIOR",ForeverCompanionDB).done==0)
exportSnapshot("ui_alts_snapshot.txt")
exportNative("ui_alts_native.json")
SlashCmdList.FOREVERCOMPANION("open dungeons")
assert(ForeverCompanionEncounterBrowser.dungeon~="")
local browser=ForeverCompanionEncounterBrowser
browser.dungeon="The Deadmines";browser.boss="Captain Greenskin";browser.page=1
ForeverCompanionRefresh()
local firstBoss=browser.boss
local itemButton=browser.lootRows[1]
assert(itemButton.visible and itemButton.record.itemID,"dungeon items have a native tooltip ID")
function tooltip:SetHyperlink(link) self.link=link end
GameTooltip=tooltip
itemButton.OnEnter(itemButton)
assert(tooltip.link=="item:"..itemButton.record.itemID)
itemButton.OnLeave()
GameTooltip=oldTooltip
noteFields[1]:SetText("Unsaved boss observation")
noteFields[1].OnTextChanged(noteFields[1],true)
assert(browser.rows[2].boss and browser.rows[2].boss~=firstBoss)
browser.rows[2].OnClick(browser.rows[2])
assert(noteFields[1]:GetText()=="","boss notes must follow actual selected encounter")
browser.rows[1].OnClick(browser.rows[1])
assert(noteFields[1]:GetText()=="Unsaved boss observation","boss draft restored after selection changes")
saveNote.OnClick()
assert(ForeverCompanionResearchNotebook.Read(ForeverCompanionDB,"Boss:"..browser.dungeon..":"..firstBoss).note=="Unsaved boss observation")
browser.nextBossPage.OnClick()
assert(browser.page==2 and browser.rows[1].boss,"catalog pagination")
browser.searchBox:SetText("Dull Sawblade")
browser.searchBox.OnTextChanged(browser.searchBox,true)
assert(browser.page==1 and browser.rows[1].boss=="Sneed","search by item must find its source boss")
assert(browser.boss==firstBoss,"filtering must preserve explicit encounter selection")
browser.rows[1].OnClick(browser.rows[1])
assert(browser.boss=="Sneed" and noteFields[1]:GetText()=="","direct search-result selection changes research context")
browser.searchBox:SetText("no known boss")
browser.searchBox.OnTextChanged(browser.searchBox,true)
assert(not browser.rows[1].visible and browser.boss=="Sneed","empty filter must not lose selection")
buttonWithText("Clear").OnClick()
assert(browser.query=="" and browser.searchBox:GetText()=="")
local function pickDungeon(name)
 browser.Focus(name,ForeverCompanionLoot.BossNames(name)[1]);ForeverCompanionRefresh()
 for _,row in ipairs(browser.dungeonRows) do
  if row.dungeon==name then row:OnClick();return end
 end
 error("Missing dungeon choice: "..name)
end
pickDungeon("Wailing Caverns")
assert(browser.dungeon=="Wailing Caverns" and browser.boss==ForeverCompanionLoot.BossNames("Wailing Caverns")[1] and browser.page==1)
pickDungeon("Blackfathom Deeps")
assert(browser.dungeon=="Blackfathom Deeps" and browser.boss=="Aku'mai" and #ForeverCompanionLoot.BossDrops(browser.dungeon,browser.boss)>=3)
assert(#browser.dungeonRows==9 and browser.dungeonRows[9]:IsShown(),"directory pages remain populated")
exportSnapshot("ui_encounter_snapshot.txt")
exportNative("ui_encounter_native.json")
local secondDrop=browser.lootRows[2].record
browser.lootRows[2]:OnClick()
assert(ForeverCompanionDB.tab=="Loot" and lootUI.itemTitle.text==secondDrop.item,"drop clicks focus that exact item")
SlashCmdList.FOREVERCOMPANION("open dungeon journal")
assert(ForeverCompanionDB.tab=="Dungeons" and browser.boss=="Aku'mai","journal navigation preserves the selected boss")
local openLoot=buttonWithText("Boss loot")
assert(openLoot and openLoot.OnClick,"boss loot shortcut missing")
openLoot.OnClick()
assert(ForeverCompanionDB.tab=="Loot")
assert(ForeverCompanionLootUI.dungeon==ForeverCompanionEncounterBrowser.dungeon)
assert(ForeverCompanionLootUI.boss==ForeverCompanionEncounterBrowser.boss)
assert(ForeverCompanionLootUI.itemCard.visible,"loot card must render after navigation")
local selected=ForeverCompanionLoot.Filter("",ForeverCompanionLootUI.dungeon,false,ForeverCompanionDB,ForeverCompanionLootUI.boss)[1]
assert(selected and ForeverCompanionLootUI.itemTitle.text==selected.item)
assert(ForeverCompanionLootUI.obtainedButton.visible)
ForeverCompanionLootUI.obtainedButton.OnClick()
assert(ForeverCompanionLoot.Obtained(ForeverCompanionDB,selected.item))
assert(not ForeverCompanionLoot.Wishlist(ForeverCompanionDB)[selected.item],"obtained toggle must not add wishes")
ForeverCompanionLootUI.obtainedButton.OnClick()
assert(not ForeverCompanionLoot.Obtained(ForeverCompanionDB,selected.item))
ForeverCompanionLootUI.wishButton.OnClick()
assert(ForeverCompanionLoot.Wishlist(ForeverCompanionDB)[selected.item]==true)
ForeverCompanionLootUI.savedButton.OnClick()
assert(ForeverCompanionLootUI.savedOnly)
ForeverCompanionLootUI.resetButton.OnClick()
assert(ForeverCompanionLootUI.dungeon=="" and ForeverCompanionLootUI.boss=="" and not ForeverCompanionLootUI.savedOnly)
assert(ForeverCompanionLootUI.selectedIndex==1)
-- Browse directly, including the second page, then combine filters.
local catalog=ForeverCompanionLootWorkspace
assert(catalog.root.visible and #catalog.rows==6)
assert(catalog.rows[2].record)
catalog.rows[2].OnClick(catalog.rows[2])
assert(ForeverCompanionLootUI.selectedIndex==2 and ForeverCompanionLootUI.itemTitle.text==catalog.rows[2].record.item)
catalog.nextPage.OnClick()
assert(ForeverCompanionLootUI.selectedIndex==7 and catalog.rows[1].resultIndex==7)
assert(catalog.nextPage.enabled and catalog.previous.enabled)
catalog.nextPage.OnClick()
assert(ForeverCompanionLootUI.selectedIndex==13 and catalog.nextPage.enabled)
catalog.previous.OnClick()
catalog.previous.OnClick()
assert(ForeverCompanionLootUI.selectedIndex==1)
local desired=catalog.rows[1].record
catalog.statusButton.OnClick()
assert(ForeverCompanionLootUI.acquisition=="outstanding")
ForeverCompanionLootUI.obtainedButton.OnClick()
assert(ForeverCompanionLootUI.itemTitle.text~=desired.item,'marking acquired must update outstanding results')
catalog.statusButton.OnClick()
assert(ForeverCompanionLootUI.acquisition=="obtained" and catalog.rows[1].record.item==desired.item)
assert(not catalog.rows[2].visible,'stale result rows must hide')
catalog.researchButton.OnClick()
assert(ForeverCompanionDB.tab=="Dungeons" and browser.boss==desired.boss and browser.dungeon==desired.dungeon)
assert(ForeverCompanionResearchNotebook.Context("Dungeons")=="Boss:"..desired.dungeon..":"..desired.boss)
openLoot.OnClick()
assert(ForeverCompanionLootUI.acquisition=="" and ForeverCompanionLootUI.slot=="",'boss shortcut clears unrelated filters')
ForeverCompanionLootUI.resetButton.OnClick()
catalog.slotButton.OnClick()
local selectedSlot=ForeverCompanionLootUI.slot
for _,row in ipairs(catalog.rows) do if row.record then assert(row.record.slot==selectedSlot) end end
ForeverCompanionLootUI.query="no such loot";ForeverCompanionRefresh()
assert(not catalog.rows[1].visible and not catalog.researchButton.enabled)
assert(not ForeverCompanionLootUI.wishButton.enabled and not ForeverCompanionLootUI.obtainedButton.enabled)
ForeverCompanionLootUI.resetButton.OnClick()
assert(ForeverCompanionLootUI.slot=="" and ForeverCompanionLootUI.acquisition=="")
local measure=catalog.detail.GetStringHeight
catalog.detail.GetStringHeight=function() return 700 end
ForeverCompanionRefresh()
assert(catalog.detail.height>=707 and catalog.root.height>=1050,'long source descriptions expand beyond fixed row area')
assert(catalog.detailPanel.fcPanelEdges.left.height==catalog.detailPanel.height,'detail panel edges follow expansion')
for _,w in ipairs(frames) do
 if w.parent==catalog.root.id and w.text:find("Hover an item for stats",1,true)==1 then
  assert(-w.point[5]>=149+catalog.detailPanel.height+14,"long item details must not cover the catalog disclosure")
 end
end
catalog.detail.GetStringHeight=measure
ForeverCompanionRefresh()
exportNative("ui_loot_native.json")
local searchField=ForeverCompanionLootUI.searchBox
local priorSearch=searchField:GetText()
searchField:SetText("")
assert(searchField.fcPlaceholder.visible,"empty search shows its placeholder")
searchField:SetText("test")
assert(not searchField.fcPlaceholder.visible,"typing hides the placeholder")
searchField:SetText(priorSearch)

exportSnapshot("ui_loot_snapshot.txt")
SlashCmdList.FOREVERCOMPANION("open leveling")
assert(not catalog.root.visible,"catalog must hide outside Loot")
assert(not ForeverCompanionLootUI.itemCard.visible,"loot widgets hide outside Loot")
assert(not ForeverCompanionLootUI.obtainedButton.visible,"manual acquisition button hides outside Loot")
local practice=ForeverCompanionStudyBoard.Get("Leveling","WARRIOR",ForeverCompanionDB)
assert(practice and practice.total>=3)
exportSnapshot("ui_practice_snapshot.txt")
exportNative("ui_practice_native.json")
for _,w in ipairs(frames) do
 if type(w.texture)=="string" then assert(not w.texture:find("\\\\",1,true),"over-escaped texture path: "..w.texture) end
end
overviewButton.OnClick(overviewButton)
if ForeverCompanionDB.compact then ForeverCompanionUIState.compactButton.OnClick() end
exportNative("ui_dashboard_native.json")
for _,f in ipairs(frames) do
 local anchor=f.point and clean(f.point[1]) or ""
 local x,y="",""
 if f.point then
  for _,v in ipairs(f.point) do if type(v)=="number" then if x=="" then x=v else y=v end end end
 end
 snapshot[#snapshot+1]=table.concat({f.id,f.kind,f.parent or "",f.visible and "1" or "0",f.width or "",f.height or "",anchor,x,y,clean(f.text),clean(f.texture)}, "|")
end
local out=assert(io.open("ui_snapshot.txt","w"))
out:write("id|kind|parent|visible|width|height|anchor|x|y|text|texture",string.char(10))
out:write(table.concat(snapshot,string.char(10)))
out:close()
io.write("PASS: actual addon manifest loaded and core UI rendered in offline mock ("..#frames.." widgets)\n")



C_DamageMeter=nil
ForeverCompanionCombatMeter.Show()
ForeverCompanionCombatMeter.SetLayout("standard")
exportNative("ui_meter_native.json")
ForeverCompanionCombatMeter.SetLayout('compact')
exportNative('ui_meter_compact_native.json')
ForeverCompanionCombatMeter.SetLayout('expanded')
exportNative('ui_meter_expanded_native.json')
ForeverCompanionCombatMeter.SetLayout('standard')
ForeverCompanionCombatMeter.SetSkin('recount')
exportNative('ui_meter_recount_native.json')
ForeverCompanionCombatMeter.SetSkin('details')
local meterFrame
for _,f in ipairs(frames) do if f.name=='ForeverCompanionCombatMeterWindow' then meterFrame=f end end
assert(meterFrame)
ForeverCompanionCombatMeter.OpenOptions(meterFrame.optionsButton)
for _,f in ipairs(frames) do
 if f.kind=='FontString' and f.text=='METER OPTIONS' then
  -- Preview identity only; the control geometry and labels are the real UI.
  frames[f.parent].name='ForeverCompanionMeterOptionsPreview'
 end
end
exportNative('ui_meter_options_native.json')
ForeverCompanionCombatMeter.Hide()
do
 SlashCmdList.FOREVERCOMPANION('open quests')
 local planner=ForeverCompanionQuestPlanner
 local originalSelected,originalTargets,originalNavigate=planner.GetSelected,ForeverCompanionQuestWaypoints.Targets,ForeverCompanionQuestWaypoints.Navigate
 local originalLive,originalSelect=planner.GetLive,planner.Select
 local q={id=900002,title='Sample: Supplies for the camp',complete=false,objectives={'Sample: Gather camp supplies'},objectiveStates={{known=true,done=false,current=2,required=5,kind='item'}}}
 planner.GetSelected=function() return q,1 end
 planner.GetLive=function() return {q} end
 planner.Select=function(index) assert(index==1) end
 local locations={{map=1429,x=.2,y=.3,label='Sample supply source',source='QuestieDB drop',objectiveIndex=1,reference=true},{map=1429,x=.6,y=.4,label='Sample alternative source',source='QuestieDB drop',objectiveIndex=1,reference=true}}
 ForeverCompanionQuestWaypoints.Targets=function() return locations end
 local navigated
 ForeverCompanionQuestWaypoints.Navigate=function(target) navigated=target;return 'Test objective selected' end
 ForeverCompanionQuestFieldGuide.Refresh()
 local guide,go,cycle
 for _,f in ipairs(frames) do if f.name=='ForeverCompanionQuestFieldGuidePanel' then guide=f end end
 assert(guide)
 for _,f in ipairs(frames) do
  if f.kind=='Button' and f.parent and frames[f.parent].parent==guide.id then
   if f.text=='Show direction' then go=f elseif f.text=='Choose area' then cycle=f end
  end
 end
 assert(go and not go.enabled and cycle and cycle.enabled,'conflicting areas cannot start navigation before a choice')
 go.OnClick(go);assert(navigated==nil,'guard is enforced by the handler too')
 cycle.OnClick(cycle)
 local areaChoice;for _,f in ipairs(frames) do if f.kind=='Button' and f.visible and f.text and f.text:find('60.0, 40.0',1,true) then areaChoice=f end end
 assert(areaChoice);areaChoice.OnClick(areaChoice);assert(go.enabled)
 go.OnClick(go);assert(navigated.x==.6)
 locations={locations[2],locations[1]};ForeverCompanionQuestFieldGuide.Refresh();go.OnClick(go)
 assert(navigated.x==.6,'field guide keeps the selected objective location after reordering')
 exportNative('ui_fieldguide_native.json')
 q.objectiveStates[1].done=true;navigated=nil;go.OnClick(go)
 assert(navigated==nil,'field guide revalidates completion even before the next UI refresh')
 ForeverCompanionQuestFieldGuide.Refresh()
 assert(go.enabled==false,'completed objective cannot retain stale navigation')
 planner.GetSelected=originalSelected;ForeverCompanionQuestWaypoints.Targets=originalTargets;ForeverCompanionQuestWaypoints.Navigate=originalNavigate
 planner.GetLive,planner.Select=originalLive,originalSelect
 ForeverCompanionQuestFieldGuide.Refresh()
 ForeverCompanionQuestTracker.Show()
 exportNative('ui_tracker_native.json')
 local tracker,first
 for _,f in ipairs(frames) do if f.name=='ForeverCompanionQuestTrackerFrame' then tracker=f end end
 assert(tracker and tracker.visible and ForeverCompanionQuestTracker.IsShown())
 for _,f in ipairs(frames) do if f.parent==tracker.id and f.item then first=f;break end end
 assert(first and first.item.quest)
 first.OnClick(first,'LeftButton')
 assert(planner.GetSelected()==first.item.quest and ForeverCompanionDB.tab=='Quests','tracker opens the actual quest field guide')
 ForeverCompanionDB.questTracker.collapsed=true;ForeverCompanionQuestTracker.Refresh()
 assert(tracker.height==30 and not first.visible)
 ForeverCompanionDB.questTracker.collapsed=false
 local main
 for _,f in ipairs(frames) do if f.name=='ForeverCompanionMainFrame' then main=f end end
 assert(main);main:Hide()
 local supported=planner.IsSupported;planner.IsSupported=function() return false end
 ForeverCompanionRefresh();assert(first.map.text=='Guide' and not first.actionable and not first.pin.enabled,'cached tracker offers review but no directions or pin mutation')
 planner.IsSupported=supported
 main:Show();ForeverCompanionRefresh()
 ForeverCompanionQuestTracker.Hide();assert(not tracker.visible and not ForeverCompanionQuestTracker.IsShown())
 assert(ForeverCompanionOpenQuestGuide(-1)==false)
end
do
 local originalCatalog=ForeverCompanionAvailableQuests.Catalog
 local originalHistory=ForeverCompanionDB.questHistory
 local originalMap=C_Map
 local originalDate=date
 date=function(pattern,at) return os.date(pattern,at) end
 C_Map={GetBestMapForUnit=function() return 1429 end,GetMapInfo=function() return {name='Sample forest'} end}
 local q=ForeverCompanionQuestPlanner.GetLive()[1]
 local targets={{map=1429,x=.2,y=.3,label='Sample quest giver',source='Forever QuestieDB quest giver'}}
 local catalog={
  {id=q.id,title=q.title,status='active',ready=q.complete,minimum=1,reason='Currently in the live quest log',dependencies={},targets=targets},
  {id=900101,title='Sample: Camp patrol',status='available',minimum=10,reason='Basic checks passed; confirm special requirements with the giver',dependencies={},targets=targets},
  {id=900102,title='Sample: Supply chain',status='locked',minimum=10,reason='Complete one prerequisite quest',dependencies={'Sample: First supplies'},targets=targets},
  {id=900103,title='Sample: A completed quest',status='completed',minimum=10,reason='Completion flag reported by the client',dependencies={},targets=targets},
  {id=900104,title='Sample: Unknown completion',status='unknown',minimum=10,reason='Completion state is unavailable',dependencies={},targets=targets},
 }
 local calls=0
 ForeverCompanionAvailableQuests.Catalog=function() calls=calls+1;return catalog end
 ForeverCompanionOpenQuestBook('catalog')
 local book,selected,searchBox
 for _,f in ipairs(frames) do if f.name=='ForeverCompanionQuestBookPanel' then book=f end end
 assert(book and book.visible)
 assert(viewport.child.height>=-book.point[5]+book.height,'catalog must retain its full scroll extent after discovery shrinks')
 for _,f in ipairs(frames) do
  if f.parent==book.id and f.entry and f.entry.id==900102 then selected=f end
  if f.parent==book.id and f.kind=='EditBox' then searchBox=f end
 end
 assert(selected and searchBox);selected.OnClick(selected)
 exportNative('ui_catalog_native.json')
 local before=calls
 searchBox:SetText('SUPPLY');searchBox.OnTextChanged(searchBox,true)
 assert(calls==before,'typing a catalog search must not rescan completion APIs')
 searchBox:SetText('');searchBox.OnTextChanged(searchBox,true)
 local oldNavigate=ForeverCompanionQuestWaypoints.Navigate
 local staleNavigation=false
 ForeverCompanionQuestWaypoints.Navigate=function() staleNavigation=true end
 local giverButton
 for _,f in ipairs(frames) do if f.text=='Show giver map' and f.OnClick then giverButton=f end end
 assert(giverButton)
 local savedCatalog=catalog;catalog={};giverButton.OnClick()
 assert(not staleNavigation,'atlas navigation must revalidate current giver coordinates')
 catalog=savedCatalog;ForeverCompanionQuestWaypoints.Navigate=oldNavigate
 ForeverCompanionQuestBook.Refresh()
 ForeverCompanionDB.questHistory={entries={}}
 ForeverCompanionQuestHistory.Record(900201,500,12345,{quest={id=900201,title='Sample: Report to camp',zoneKnown=true,zone='Sample forest'},map=1429,at=1400000000})
 ForeverCompanionQuestHistory.Record(900202,750,nil,{quest={id=900202,title='Sample: Deliver supplies',zoneKnown=true,zone='Sample forest'},map=1429,at=1400000100})
 ForeverCompanionOpenQuestBook('history')
 for _,f in ipairs(frames) do if f.parent==book.id and f.entry and f.entry.id==900201 then selected=f end end
 selected.OnClick(selected)
 local key=selected.key
 ForeverCompanionQuestHistory.Record(900203,nil,nil,{quest={id=900203,title='Sample: Another turn-in'},map=1429,at=1400000200})
 local retained=false
 for _,f in ipairs(frames) do if f.parent==book.id and f.key==key and f.entry and f.entry.id==900201 then retained=true end end
 assert(retained,'history selection must retain its event identity when new turn-ins arrive')
 exportNative('ui_history_native.json')
 local giverMap
 for _,f in ipairs(frames) do if f.kind=='Button' and f.text=='Show giver map' then giverMap=f end end
 assert(giverMap and giverMap.enabled==false and not giverMap.visible,'turn-in history cannot invent a historical coordinate')
 ForeverCompanionAvailableQuests.Catalog=originalCatalog;ForeverCompanionDB.questHistory=originalHistory;C_Map=originalMap;date=originalDate
 SlashCmdList.FOREVERCOMPANION('discover')
 assert(not book.visible,'discovery tab must replace the book view')
end

-- The setup panel must be reachable, readable and reversible without map writes.
SlashCmdList.FOREVERCOMPANION('setup')
local setupPanel
for _,f in ipairs(frames) do if f.name=='ForeverCompanionQuestSetupPanel' then setupPanel=f end end
assert(setupPanel and setupPanel.visible)
exportNative('ui_setup_native.json')
SlashCmdList.FOREVERCOMPANION('setup')
assert(not setupPanel.visible)

do
 local originalTargets=ForeverCompanionQuestWaypoints.Targets
 local originalNavigate=ForeverCompanionQuestWaypoints.Navigate
 local originalLive=ForeverCompanionQuestPlanner.GetLive
 local originalMap=C_Map
 local q={id=999100,title='Sample: Outpost preparations',objectives={'Sample: Collect supplies','Sample: Speak to scout'},objectiveStates={{known=true,done=false},{known=true,done=false}}}
 ForeverCompanionQuestPlanner.GetLive=function() return {q} end
 C_Map={GetBestMapForUnit=function() return 1429 end,GetPlayerMapPosition=function() return {GetXY=function() return .1,.1 end} end,GetMapInfo=function() return {name='Sample forest'} end}
 ForeverCompanionQuestWaypoints.Targets=function() return {
  {map=1429,x=.2,y=.3,objectiveIndex=1,source='Fixture reference',reference=true},
  {map=1429,x=.4,y=.3,objectiveIndex=2,source='Fixture reference',reference=true}} end
 local navigations=0
 ForeverCompanionQuestWaypoints.Navigate=function() navigations=navigations+1;return 'Fixture navigation' end
 SlashCmdList.FOREVERCOMPANION('open journey')
 ForeverCompanionObjectiveRoute.Refresh()
 local route,go
 for _,f in ipairs(frames) do if f.name=='ForeverCompanionObjectiveRoutePanel' then route=f end end
 assert(route and route.visible)
 for _,f in ipairs(frames) do if f.stop and f.stop.quest==q and f.stop.objectiveIndex==1 then go=f.go end end
 assert(go,'matched itinerary step must have an action')
 exportNative('ui_itinerary_native.json')
 q.objectiveStates[1].done=true
 go.OnClick()
 assert(navigations==0,'route action must revalidate completion before navigation')
 ForeverCompanionQuestPlanner.GetLive=originalLive
 ForeverCompanionQuestWaypoints.Targets=originalTargets;ForeverCompanionQuestWaypoints.Navigate=originalNavigate;C_Map=originalMap
 ForeverCompanionRefresh()
end

SlashCmdList.FOREVERCOMPANION('performance window')
local performancePanel
for _,f in ipairs(frames) do if f.name=='ForeverCompanionPerformancePanel' then performancePanel=f end end
assert(performancePanel and performancePanel.visible)
exportNative('ui_performance_native.json')
SlashCmdList.FOREVERCOMPANION('performance window');assert(not performancePanel.visible)

-- Synthetic layout fixtures are test-only and never ship in the addon.
do
 local oldMeter,oldSpell,oldEnum=C_DamageMeter,C_Spell,Enum
 Enum={DamageMeterType={Dps=1,DamageDone=0,HealingDone=2,Hps=3},DamageMeterSessionType={Current=1,Expired=2,Overall=0}}
 local sources={}
 for i=1,12 do sources[i]={name='SAMPLE Player '..i,sourceGUID='Sample-'..i,classFilename=i%2==0 and 'HUNTER' or 'MAGE',totalAmount=1200000-i*45000,amountPerSecond=20000-i*750} end
 sources[1].name='SAMPLE Long Character Name'
 local spells={}
 for i=1,19 do spells[i]={spellID=i,totalAmount=90000-i*1500,creatureName=i%3==0 and 'Sample Wolf' or nil} end
 C_DamageMeter={GetCombatSessionFromType=function() return {combatSources=sources,maxAmount=sources[1].totalAmount,durationSeconds=90} end,
  GetCombatSessionSourceFromType=function() return {combatSpells=spells} end}
 C_Spell={GetSpellInfo=function(id) return {name=id%3==0 and 'Attack' or ('Sample spell '..id),iconID=136048} end}
 local m=ForeverCompanionCombatMeter
 m.Show();m.SetMode('DPS');m.SetSession('Current');m.SetLayout('standard');m.Refresh()
 local first
 for _,f in ipairs(frames) do if f.sourceGUID=='Sample-1' and f.OnMouseDown then first=f end end
 assert(first)
 first.OnMouseDown(first,'LeftButton')
 exportNative('ui_breakdown_sample_native.json')
 exportNative('ui_populated_meter_sample_native.json')
 local detail
 for _,f in ipairs(frames) do if f.name=='ForeverCompanionBreakdownWindow' then detail=f end end
 assert(detail and detail.spellSearch.width==230 and detail.spellFilter.width==132)
 assert(detail.spellSearch.point[2]+detail.spellSearch.width<detail.spellFilter.point[2],'search and filter controls must not collide')
 detail.spellSearch:SetText('sample wolf')
 exportNative('ui_pet_search_sample_native.json')
 detail.spellSearch:SetText('');m.Hide()
 C_DamageMeter,C_Spell,Enum=oldMeter,oldSpell,oldEnum
end

do
 local oldTime,oldXP,oldMax,oldLevel=GetTime,UnitXP,UnitXPMax,UnitLevel
 local now,xp=100,500
 GetTime=function() return now end;UnitXP=function() return xp end;UnitXPMax=function() return 5000 end;UnitLevel=function() return 20 end
 local s=ForeverCompanionSessionProgress
 s.Start();now=400;xp=1700;s.Sample()
 for i=1,6 do s.RecordQuest({title='SAMPLE observed quest '..i..': Supplies and preparations for the long journey through the forest',xp=i*75,money=i*100}) end
 SlashCmdList.FOREVERCOMPANION('session')
 local panel,body,history
 for _,f in ipairs(frames) do if f.name=='ForeverCompanionSessionPanel' then panel=f end end
 assert(panel and panel.visible)
 for _,f in ipairs(frames) do
  if f.parent==panel.id and f.kind=='FontString' and f.text:find('REPORTED QUEST REWARDS',1,true) then body=f end
  if f.parent==panel.id and f.text=='Previous sessions' then history=f end
 end
 assert(body and history and body:GetStringHeight()<=body.height,'six recent quest titles must fit the session reading area')
 exportNative('ui_session_sample_native.json')
 s.NewSession();history.OnClick()
 local saved
 for _,f in ipairs(frames) do if f.kind=='Button' and f.text:find('1. 0:05:00',1,true) then saved=f end end
 assert(saved);saved.OnClick()
 assert(panel.heading.text=='PREVIOUS LEVELING SESSION')
 history.OnClick();assert(panel.heading.text=='MY LEVELING SESSION')
 s.Toggle();assert(not panel.visible)
 GetTime,UnitXP,UnitXPMax,UnitLevel=oldTime,oldXP,oldMax,oldLevel
end

do
 local oldMap,oldServices,oldNavigate=C_Map,ForeverCompanionTownServices.ForMap,ForeverCompanionQuestWaypoints.Navigate
 local fixture={
  {map=1429,x=.2,y=.3,npcID=9901,label='SAMPLE Trading Post',subtitle='Reagents and supplies',service='Vendor',symbol='V',source='Forever QuestieDB reference'},
  {map=1429,x=.2,y=.3,npcID=9901,label='SAMPLE Trading Post',subtitle='Reagents and supplies',service='Repairs',symbol='R',source='Forever QuestieDB reference'},
  {map=1429,x=.4,y=.4,npcID=9902,label='SAMPLE City Banker',service='Bank',symbol='B',source='Forever QuestieDB reference'},
  {map=1429,x=.5,y=.6,npcID=9903,label='SAMPLE Flight Master',service='Flight master',symbol='F',source='Forever QuestieDB reference'},
  {map=1429,x=.3,y=.5,npcID=9904,label='SAMPLE Innkeeper',service='Inn',symbol='I',source='Forever QuestieDB reference'},
  {map=1429,x=.1,y=.2,npcID=9905,label='SAMPLE Visited Merchant',service='Vendor',symbol='V',observed=true,source='Visited nearby · player position at merchant visit'},
  {map=1429,x=.7,y=.8,npcID=9906,label='SAMPLE Profession Trainer',subtitle='Alchemy',service='Trainer',symbol='T',source='Forever QuestieDB reference'},
  {map=1429,x=.6,y=.7,npcID=9907,label='SAMPLE Auctioneer',service='Auction house',symbol='AH',source='Forever QuestieDB reference'},
 }
 C_Map={GetBestMapForUnit=function() return 1429 end,GetMapInfo=function() return {name='SAMPLE Forest Services'} end,GetPlayerMapPosition=function() return {GetXY=function() return .1,.1 end} end}
 ForeverCompanionTownServices.ForMap=function() return fixture end
 local navigated
 ForeverCompanionQuestWaypoints.Navigate=function(t) navigated=t;return 'Sample navigation' end
 SlashCmdList.FOREVERCOMPANION('services')
 local panel,first,source
 for _,f in ipairs(frames) do if f.name=='ForeverCompanionServiceAtlasPanel' then panel=f end end
 assert(panel and panel.visible)
 for _,f in ipairs(frames) do
  if f.parent==panel.id and f.item and not first then first=f end
  if f.parent==panel.id and f.text=='All sources' then source=f end
 end
 assert(first and first.item.target.observed and source,'atlas sorts by real position and exposes source controls')
 first.favorite.OnClick();assert(ForeverCompanionDB.serviceFavorites[first.item.key])
 exportNative('ui_service_atlas_sample_native.json')
 first.go.OnClick();assert(navigated and navigated.observed)
 local saved=fixture;fixture={};navigated=nil;first.go.OnClick();assert(navigated==nil,'atlas rejects stale location even before UI refresh')
 fixture=saved;source.OnClick()
 local referenceOnly
 for _,f in ipairs(frames) do if f.kind=='Button' and f.text=='Provider only' then referenceOnly=f end end
 assert(referenceOnly);referenceOnly.OnClick();assert(ForeverCompanionDB.serviceAtlas.source=='reference')
 for _,f in ipairs(frames) do if f.parent==panel.id and f.item and f.visible then assert(not f.item.target.observed) end end
 ForeverCompanionDB.serviceAtlas.source='all';ForeverCompanionServiceAtlas.Refresh()
 ForeverCompanionServiceAtlas.Toggle();assert(not panel.visible)
 C_Map,ForeverCompanionTownServices.ForMap,ForeverCompanionQuestWaypoints.Navigate=oldMap,oldServices,oldNavigate
end

-- Native artwork API fixture; file IDs do not simulate real client terrain.
do
 C_Map={GetBestMapForUnit=function() return 1429 end,GetMapArtID=function() return 1 end,
 GetMapArtLayers=function() return {{layerWidth=1002,layerHeight=668,tileWidth=256,tileHeight=256}} end,
 GetMapArtLayerTextures=function() local f={};for i=1,12 do f[i]=i end;return f end,
 GetMapInfo=function() return {name='SAMPLE overlay zone'} end,
 GetPlayerMapPosition=function() return {GetXY=function() return .4,.6 end} end}
 GetPlayerFacing=function() return .5 end
 ForeverCompanionQuestPlanner.IsSupported=function() return false end
 SlashCmdList.FOREVERCOMPANION('overlay show')
 local panel;for _,f in ipairs(frames) do if f.name=='ForeverCompanionMapOverlayFrame' then panel=f end end
 assert(panel and panel.visible and panel.mouse==false and panel.width==600)
 SlashCmdList.FOREVERCOMPANION('overlay edit');assert(panel.mouse==true)
 SlashCmdList.FOREVERCOMPANION('overlay lock');assert(panel.mouse==false)
 ForeverCompanionMapOverlay.Options()
 exportNative('ui_overlay_sample_native.json')
 SlashCmdList.FOREVERCOMPANION('overlay hide');assert(not panel.visible)
end

-- All six map update entry points load through the real addon manifest.
do
 local t=ForeverCompanionMapTools
 ForeverCompanionDB.mapNotes={}
 SlashCmdList.FOREVERCOMPANION('note SAMPLE - rare sighting')
 assert(#t.List()==1 and t.List()[1].label=='SAMPLE - rare sighting')
 t.SaveHere('SAMPLE - farming loop');t.SaveHere('SAMPLE - revisit this cave')
 SlashCmdList.FOREVERCOMPANION('notes')
 local panel;for _,f in ipairs(frames) do if f.name=='ForeverCompanionMapToolsPanel' then panel=f end end
 assert(panel and panel.visible)
 t.Refresh();exportNative('ui_map_tools_sample_native.json')
 local canvas=CreateFrame('Frame');canvas:SetSize(1000,668)
 t.DrawMap(canvas,1429,1000,668,1)
 local before=#frames;t.DrawMap(canvas,1429,1000,668,1);assert(#frames==before,'map note buttons reuse the current canvas pool')
 t.HideMap()
 SlashCmdList.FOREVERCOMPANION('overlay town');assert(ForeverCompanionDB.mapOverlay.preset=='town')
 ForeverCompanionMapOverlay.Refresh();exportNative('ui_overlay_town_sample_native.json')
 SlashCmdList.FOREVERCOMPANION('overlay hide');t.Toggle()
end

do
 local old=ForeverCompanionTownServices.ForMap
 ForeverCompanionTownServices.ForMap=function() return {{map=1429,x=.42,y=.61,label='SAMPLE repair specialist',service='Repair',symbol='R',source='Sample provider reference'}} end
 ForeverCompanionMapTools.Nearest('repair')
 local menu;for _,f in ipairs(frames) do if f.width==380 and f.visible then menu=f end end
 assert(menu,'nearby service menu uses a readable width');menu.name='SampleNearbyServicesMenu';exportNative('ui_nearby_services_sample_native.json')
 ForeverCompanionInterface.CloseMenu();ForeverCompanionTownServices.ForMap=old
 C_Map.GetWorldPosFromMapPos=function(_,p) local x,y=p:GetXY();return 1,{GetXY=function() return x*1000,y*1000 end} end
 CreateVector2D=function(x,y) return {GetXY=function() return x,y end} end
 assert(ForeverCompanionQuestDirection.Start({map=1429,x=.4001,y=.6001},'SAMPLE destination'))
 assert(ForeverCompanionQuestDirection.Arrival())
 exportNative('ui_navigation_arrival_sample_native.json');ForeverCompanionQuestDirection.Stop()
end

-- Unified map search, organized notes, quick access and compact travel layout.
do
 local h,t=ForeverCompanionMapHub,ForeverCompanionMapTools
 local notes=t.List();assert(#notes>=3);t.SetCategory(notes[1].id,'farming');t.SetCategory(notes[2].id,'rare');t.SetCategory(notes[3].id,'reminder')
 local oldServices=ForeverCompanionTownServices.ForMap
 ForeverCompanionTownServices.ForMap=function() return {{map=1429,x=.42,y=.61,label='SAMPLE repair specialist',service='Repair',symbol='R',source='Sample provider reference'}} end
 local oldSupported,oldLive,oldTargets=ForeverCompanionQuestPlanner.IsSupported,ForeverCompanionQuestPlanner.GetLive,ForeverCompanionQuestWaypoints.Targets
 local q={id=987,title='SAMPLE - missing scout',objectives={'Search the clearing'}}
 ForeverCompanionQuestPlanner.IsSupported=function() return true end;ForeverCompanionQuestPlanner.GetLive=function() return {q} end
 ForeverCompanionQuestWaypoints.Targets=function() return {{map=1429,x=.6,y=.4,source='WoW quest map'}} end
 SlashCmdList.FOREVERCOMPANION('map')
 local panel;for _,f in ipairs(frames) do if f.name=='ForeverCompanionMapHubPanel' then panel=f end end
 assert(panel and panel.visible);h.Refresh();exportNative('ui_map_hub_sample_native.json')
 SlashCmdList.FOREVERCOMPANION('search missing scout')
 local count=0;for _,f in ipairs(frames) do if f.result and f.visible then count=count+1;assert(f.result.kind=='quest') end end;assert(count==1)
 h.ShowButton(true)
 h.Record(notes[1],notes[1].label);SlashCmdList.FOREVERCOMPANION('recent');exportNative('ui_travel_recent_sample_native.json')
 ForeverCompanionDB.questDirection.compact=true
 assert(ForeverCompanionQuestDirection.Start({map=1429,x=.6,y=.4,source='WoW quest map'},'SAMPLE - missing scout'))
 ForeverCompanionQuestDirection.ApplyLayout();exportNative('ui_travel_strip_sample_native.json');ForeverCompanionQuestDirection.Stop()
 ForeverCompanionDB.questDirection.compact=false
 ForeverCompanionTownServices.ForMap=oldServices
 ForeverCompanionQuestPlanner.IsSupported,ForeverCompanionQuestPlanner.GetLive,ForeverCompanionQuestWaypoints.Targets=oldSupported,oldLive,oldTargets
end

do
 ForeverCompanionMapTools.Toggle();exportNative('ui_organized_notes_sample_native.json');ForeverCompanionMapTools.Toggle()
end

do
 local h=ForeverCompanionMapHub
 local original=h.Snapshot;local builds=0
 h.Snapshot=function() builds=builds+1;return original() end
 h.Open('');assert(builds==1)
 local panel,edit;for _,f in ipairs(frames) do if f.name=='ForeverCompanionMapHubPanel' then panel=f end end
 for _,f in ipairs(frames) do if f.kind=='EditBox' and f.parent==panel.id then edit=f end end
 assert(edit and edit.OnKeyDown and edit.OnEnterPressed)
 edit:SetText('SAMPLE');assert(builds==1,'typing reuses the index')
 edit.OnKeyDown(edit,'DOWN');assert(builds==1,'keyboard selection reuses the index')
 exportNative('ui_map_hub_refined_sample_native.json')
 edit.OnEnterPressed();assert(ForeverCompanionQuestDirection.IsActive(),'Enter starts navigation only after keyboard selection');ForeverCompanionQuestDirection.Stop()
 edit.OnEscapePressed(edit);assert(not panel.visible,'Escape closes the search panel')
 h.Snapshot=original
 local t=ForeverCompanionMapTools;local note=t.List()[1];t.ToggleFavorite(note.id);t.Remove(note.id);assert(t.UndoRemove())
 t.Toggle();exportNative('ui_notes_refined_sample_native.json');t.Toggle()
end

do
 Minimap=CreateFrame('Frame','SampleMinimap',UIParent);Minimap:SetSize(140,140);Minimap:SetPoint('TOPRIGHT',-20,-20)
 SlashCmdList.FOREVERCOMPANION('minimap')
 local launcher;for _,f in ipairs(frames) do if f.name=='ForeverCompanionMinimapLauncher' then launcher=f end end
 assert(launcher and launcher.visible)
 local main;for _,f in ipairs(frames) do if f.name=='ForeverCompanionMainFrame' then main=f end end
 local before=main.visible;launcher.OnClick(launcher,'LeftButton');assert(main.visible~=before,'minimap button toggles the actual main addon')
 launcher.OnClick(launcher,'RightButton')
 exportNative('ui_minimap_launcher_sample_native.json')
 SlashCmdList.FOREVERCOMPANION('minimap hide');assert(not launcher.visible)
 SlashCmdList.FOREVERCOMPANION('minimap reset');assert(launcher.visible)
 ForeverCompanionInterface.CloseMenu()
end

do
 local o=ForeverCompanionMapOverlay
 C_AreaPoiInfo={GetAreaPOIForMap=function() return {1} end,GetAreaPOIInfo=function() return {name='SAMPLE - ruined tower',description='Client-reported landmark description',position={GetXY=function() return .5,.5 end}} end}
 o.Toggle(true);o.SetZoom(2);o.Inspect(true);o.Refresh()
 local panel;for _,f in ipairs(frames) do if f.name=='ForeverCompanionMapOverlayFrame' then panel=f end end
 assert(panel and panel.mouse)
 local hit;for _,f in ipairs(frames) do if f.group and f.parent==panel.id and f.visible then hit=f end end
 assert(hit and hit.OnEnter and hit.OnClick,'inspect mode creates interactive location details')
 exportNative('ui_overlay_zoom_sample_native.json');o.Inspect(false);assert(not panel.mouse);o.Toggle(false)
 local oldKnown=ForeverCompanionKnownSpell;ForeverCompanionKnownSpell=function(id) return id==6673 end
 C_Spell={GetSpellInfo=function(id) return {name=({[100]='Charge',[772]='Rend',[6673]='Battle Shout'})[id] or ('SAMPLE spell '..id),iconID=136048} end}
 SlashCmdList.FOREVERCOMPANION('training')
 local training;for _,f in ipairs(frames) do if f.name=='ForeverCompanionTrainingPanel' then training=f end end
 assert(training and training.visible);exportNative('ui_training_sample_native.json')
 ForeverCompanionTraining.Toggle();ForeverCompanionKnownSpell=oldKnown
end

-- Explicit samples of the new quest and Stockades layouts; not in-game captures.
do
 SlashCmdList.FOREVERCOMPANION('open dungeon journal')
 local b=ForeverCompanionEncounterBrowser;b.Focus('The Stockade','Bazil Thredd');ForeverCompanionRefresh();exportNative('ui_stockades_sample_native.json')
 b.searchBox:SetText('Stockades');b.searchBox.OnTextChanged(b.searchBox,true)
 assert(b.dungeonRows[1].dungeon=='The Stockade' and not b.dungeonRows[2].visible,'Stockades alias finds the dungeon')
 b.query='';b.searchBox:SetText('')
 local p=ForeverCompanionQuestPlanner;local oldSelected,oldLive,oldSupported,oldTargets=p.GetSelected,p.GetLive,p.IsSupported,ForeverCompanionQuestWaypoints.Targets
 local q={id=173,title='SAMPLE - Worgen in the Woods',zone='Duskwood',objectives={'Nightbane Shadow Weaver slain: 2/6'},objectiveStates={{known=true,kind='monster',current=2,required=6}}}
 p.GetSelected=function() return q end;p.GetLive=function() return {q} end;p.IsSupported=function() return true end
 ForeverCompanionQuestWaypoints.Targets=function() return {{map=1429,x=.42,y=.69,reference=true,objectiveIndex=1,label='SAMPLE - search point',source='Synthetic fixture'}} end
 for _,f in ipairs(frames) do if f.name=='ForeverCompanionQuestFieldGuidePanel' then f:Show() end end
 ForeverCompanionQuestFieldGuide.Refresh();exportNative('ui_quest_details_sample_native.json')
 ForeverCompanionQuestTracker.Show();exportNative('ui_tracker_refined_sample_native.json');ForeverCompanionQuestTracker.Hide()
 local target=ForeverCompanionQuestWaypoints.Targets(q)[1];ForeverCompanionQuestLocations.Report(q,target);ForeverCompanionQuestFieldGuide.CopyReport(q)
 local copied;for _,f in ipairs(frames) do if f.name=='ForeverCompanionQuestLocationReport' then copied=f end end
 assert(copied and copied.visible,'saved local reports have a copyable panel');copied:Hide();ForeverCompanionQuestLocations.Restore(q)
 p.GetSelected,p.GetLive,p.IsSupported=oldSelected,oldLive,oldSupported;ForeverCompanionQuestWaypoints.Targets=oldTargets
end

do
 local launcher;for _,f in ipairs(frames) do if f.section=='Training' then launcher=f end end
 assert(launcher,'Training Guide is discoverable in main navigation')
 local prior=ForeverCompanionDB.tab
 launcher.OnClick(launcher)
 local training;for _,f in ipairs(frames) do if f.name=='ForeverCompanionTrainingPanel' then training=f end end
 assert(training and training.visible and ForeverCompanionDB.tab==prior,'navigation opens training without selecting an unsupported main page')
 exportNative('ui_training_refined_sample_native.json');ForeverCompanionTraining.Toggle()
 local viewport=ForeverCompanionUIState.scrollFrame
 local clipped=false;for _,f in ipairs(frames) do if f.kind=='ScrollFrame' and f.clipsChildren then clipped=true end end
 assert(clipped,'main scroll viewport explicitly clips child panels above the footer')
end

-- Milestone integration: menus, tracker visibility, stale routing and guide transitions.
do
 local state=ForeverCompanionUIState
 ForeverCompanionDB.beginnerMode=true;ForeverCompanionRefresh()
 assert(#state.goalButtons==6)
 for _,b in ipairs(state.goalButtons) do assert(b.visible) end
 for _,f in ipairs(frames) do if f.section then assert(not f.visible,'advanced navigation is preserved but hidden in Beginner Mode') end end
 state.goalButtons[2].OnClick()
 local classChoice
 for _,f in ipairs(frames) do if f.kind=='Button' and f.text=='Class guide' and f.visible then classChoice=f end end
 assert(classChoice);classChoice.OnClick();assert(ForeverCompanionDB.tab=='Leveling')
 ForeverCompanionDB.beginnerMode=false;ForeverCompanionRefresh()
 for _,b in ipairs(state.goalButtons) do assert(not b.visible) end
 ForeverCompanionDB.beginnerMode=true;ForeverCompanionRefresh()
 local p=ForeverCompanionQuestPlanner
 local oldLive,oldSelected,oldSupported=p.GetLive,p.GetSelected,p.IsSupported
 local oldTargets=ForeverCompanionQuestWaypoints.Targets
 local oldRoute=ForeverCompanionObjectiveRoute.NavigateNext
 local oldMap=C_Map.GetBestMapForUnit
 local q={id=980001,title='SAMPLE: A long quest title that should wrap naturally across two lines',zone='Sample camp',zoneKnown=true,level=18,objectives={'Sample: Collect supplies: 2/5','Sample: Visit the scout'},objectiveStates={{known=true,current=2,required=5,kind='item'},{known=true,done=false}}}
 p.GetLive=function() return {q} end;p.GetSelected=function() return q,1 end;p.IsSupported=function() return true end
 C_Map.GetBestMapForUnit=function() return 1429 end
 local locations={{map=9999,x=.2,y=.3,reference=true,objectiveIndex=1,label='SAMPLE: remote camp'}}
 ForeverCompanionQuestWaypoints.Targets=function() return locations end
 local routes=0;ForeverCompanionObjectiveRoute.NavigateNext=function() routes=routes+1;return 'Synthetic route' end
 ForeverCompanionQuestTracker.Show()
 local tracker,row
 for _,f in ipairs(frames) do if f.name=='ForeverCompanionQuestTrackerFrame' then tracker=f end end
 for _,f in ipairs(frames) do if f.parent==tracker.id and f.item then row=f;break end end
 assert(row and row.map.text=='Guide' and not row.actionable,'other-map destinations cannot promise a local route')
 locations[1].map=1429;ForeverCompanionQuestTracker.Refresh()
 assert(row.actionable and row.map.text=='Directions');row.map.OnClick();assert(routes==1)
 local pinCalls=0;local oldPin=p.TogglePin;p.TogglePin=function() pinCalls=pinCalls+1 end
 row.pin.OnClick();assert(pinCalls==1)
 local search
 for _,f in ipairs(frames) do if f.kind=='EditBox' and f.parent==tracker.id then search=f end end
 search:SetText('no-match');search.OnTextChanged(search,true);assert(not row.visible)
 search:SetText('');search.OnTextChanged(search,true);assert(row.visible)
 p.IsSupported=function() return false end;ForeverCompanionQuestTracker.Refresh()
 row.map.OnClick();row.pin.OnClick();assert(routes==1 and pinCalls==1,'cached data never triggers route or pin mutation')
 p.IsSupported=function() return true end
 ForeverCompanionDB.questTracker.scale=1.3;ForeverCompanionQuestTracker.Refresh()
 assert(tracker.scale<=1.3 and tracker.scale>0)
 UIParent:SetSize(380,260);tracker.OnEvent();assert(tracker.scale<1,'large tracker fits a small display')
 UIParent:SetSize(1000,700);ForeverCompanionDB.questTracker.scale=1;ForeverCompanionQuestTracker.Refresh()
 exportNative('ui_questing_milestone_tracker_native.json')
 ForeverCompanionQuestTracker.Hide()
 SlashCmdList.FOREVERCOMPANION('open quests')
 local guidePanel
 for _,f in ipairs(frames) do if f.name=='ForeverCompanionQuestFieldGuidePanel' then guidePanel=f end end
 ForeverCompanionQuestFieldGuide.Refresh()
 q.objectiveStates[1].done=true;ForeverCompanionQuestFieldGuide.Refresh()
 local selectedStep
 for _,f in ipairs(frames) do if f.parent==guidePanel.id and f.step and f.selected then selectedStep=f.step end end
 assert(selectedStep and selectedStep.index==2,'completion advances the visible guide to the next unfinished objective')
 local context
 for _,f in ipairs(frames) do if f.parent==guidePanel.id and f.text=='Giver and chain' then context=f end end
 assert(context);context.OnClick();exportNative('ui_questing_milestone_guide_native.json');context.OnClick()
 p.GetLive,p.GetSelected,p.IsSupported,p.TogglePin=oldLive,oldSelected,oldSupported,oldPin
 C_Map.GetBestMapForUnit=oldMap;ForeverCompanionQuestWaypoints.Targets=oldTargets;ForeverCompanionObjectiveRoute.NavigateNext=oldRoute
 ForeverCompanionRefresh()
 SlashCmdList.FOREVERCOMPANION('open dungeon journal')
 local journal=ForeverCompanionEncounterBrowser
 journal.SelectDungeon('The Deadmines')
 p.GetLive=function() return {{id=980002,title='SAMPLE: Supplies for Deadmines',zone='The Deadmines',zoneKnown=true,objectives={'SAMPLE: Inspect supplies'},objectiveStates={{known=true,done=false}}}} end
 local questsButton
 for _,f in ipairs(frames) do if f.kind=='Button' and f.text=='Dungeon quests' then questsButton=f end end
 assert(questsButton);questsButton.OnClick()
 local questPanel,questRow
 for _,f in ipairs(frames) do if f.name=='ForeverCompanionDungeonQuestsPanel' then questPanel=f end end
 assert(questPanel and questPanel.visible)
 for _,f in ipairs(frames) do if f.parent==questPanel.id and f.entry then questRow=f;break end end
 assert(questRow and questRow.entry.id==980002,'journal contains a live zone-matched dungeon quest')
 local journalSearch,planControl
 for _,f in ipairs(frames) do if f.parent==questPanel.id and f.kind=='EditBox' then journalSearch=f end end
 assert(journalSearch);journalSearch:SetText('no such synthetic quest');journalSearch.OnTextChanged(journalSearch);assert(not questRow.visible,'journal search hides non-matching quests')
 journalSearch:SetText('Supplies');journalSearch.OnTextChanged(journalSearch);assert(questRow.visible,'journal search returns literal matching quests')
 exportNative('ui_dungeon_quests_milestone_native.json');questRow.OnClick()
 for _,f in ipairs(frames) do if f.parent==questPanel.id and f.text=='Plan this run' then planControl=f end end
 assert(planControl);planControl.OnClick();assert(ForeverCompanionDungeonQuests.IsPlanned(980002),'journal plan button saves checklist state')
 exportNative('ui_dungeon_quest_detail_milestone_native.json')
 planControl.OnClick();assert(not ForeverCompanionDungeonQuests.IsPlanned(980002))
 journalSearch:SetText('');journalSearch.OnTextChanged(journalSearch)
 questsButton.OnClick();assert(not questPanel.visible,'boss and loot view remains available')
 p.GetLive=oldLive
 ForeverCompanionTraining.Open('Charge');ForeverCompanionTraining.Open('Rend')
 local training;for _,f in ipairs(frames) do if f.name=='ForeverCompanionTrainingPanel' then training=f end end
 assert(training.visible,'opening a second spell must keep training open')
 local trainingSearch;for _,f in ipairs(frames) do if f.parent==training.id and f.kind=='EditBox' then trainingSearch=f end end
 assert(trainingSearch:GetText()=='Rend')
 ForeverCompanionTraining.Toggle()
 local oldMeter,oldMeterEnums=C_DamageMeter,Enum
 Enum={DamageMeterType={Dps=1,DamageDone=0,HealingDone=2,Hps=3},DamageMeterSessionType={Current=1,Expired=2,Overall=0}}
 local sampleSources={
  {name='SAMPLE: Warrior',classFilename='WARRIOR',totalAmount=125000,amountPerSecond=1389,sourceGUID='sample-warrior'},
  {name='SAMPLE: Mage',classFilename='MAGE',totalAmount=106000,amountPerSecond=1178,sourceGUID='sample-mage'},
  {name='SAMPLE: Hunter',classFilename='HUNTER',totalAmount=92000,amountPerSecond=1022,sourceGUID='sample-hunter'},
 }
 C_DamageMeter={GetCombatSessionFromType=function() return {combatSources=sampleSources,maxAmount=125000,durationSeconds=90} end}
 ForeverCompanionCombatMeter.Show();ForeverCompanionCombatMeter.SetMode('DPS');ForeverCompanionCombatMeter.SetSession('Current');ForeverCompanionCombatMeter.SetTextSize(13)
 exportNative('ui_readable_meter_milestone_native.json');ForeverCompanionCombatMeter.SetTextSize(11);ForeverCompanionCombatMeter.Hide();C_DamageMeter=oldMeter;Enum=oldMeterEnums
 SlashCmdList.FOREVERCOMPANION('open home');exportNative('ui_home_milestone_native.json')
 io.write('PASS: beginner goal navigation, tracker filters/scaling/cache guards, objective advancement, inline dungeon quests and spell training handoff\n')
end

-- 3.54 workflow fixtures are synthetic and remain outside the shipped addon.
do
 SlashCmdList.FOREVERCOMPANION('open professions')
 local profession='Alchemy'
 for _,f in ipairs(frames) do if f.label and f.label.text=='Alchemy' and f.OnClick then f.OnClick();break end end
 local recipes=ForeverCompanionRecipePlans
 recipes.Add(profession,'SAMPLE: Travel supply kit',3)
 recipes.Ingredient(profession,#recipes.Get(profession),'SAMPLE: Frost Cloth',2)
 recipes.Ingredient(profession,#recipes.Get(profession),'SAMPLE: Binding Thread',1)
 local toggle
 for _,f in ipairs(frames) do if f.kind=='Button' and f.text=='Recipe plans' then toggle=f end end
 assert(toggle);toggle.OnClick()
 local editor=ForeverCompanionRecipeWorkspace
 assert(editor.root.visible and ForeverCompanionDB.professionWorkspace=='recipes')
 editor.nameInput:SetText('SAMPLE: Second supply kit');editor.amountInput:SetText('2')
 local add,import
 for _,f in ipairs(frames) do
  if f.parent==editor.root.id and f.text=='Add recipe' then add=f end
  if f.parent==editor.root.id and f.text=='Add missing material goals' then import=f end
 end
 assert(add and import);local before=#recipes.Get(profession);add.OnClick();assert(#recipes.Get(profession)==before+1)
 local selectedRow
 for _,row in ipairs(editor.recipeRows) do if row.record and row.record.name=='SAMPLE: Second supply kit' then selectedRow=row end end
 assert(selectedRow);selectedRow.OnClick()
 editor.ingredientInput:SetText('SAMPLE: Frost Cloth');editor.countInput:SetText('4')
 local addIngredient;for _,f in ipairs(frames) do if f.parent==editor.root.id and f.text=='Add' then addIngredient=f end end
 assert(addIngredient);addIngredient.OnClick();assert(#selectedRow.record.ingredients==1)
 import.OnClick()
 local cloth
 for _,goal in ipairs(ForeverCompanionCraftingPlanner.GetEntries(profession)) do if goal.name=='SAMPLE: Frost Cloth' then cloth=goal end end
 assert(cloth and cloth.needed==14 and cloth.owned==0,'UI import aggregates both manual recipes')
 exportNative('ui_recipe_workflow_354_native.json')
 toggle.OnClick();assert(not editor.root.visible,'material goals remain one click away')
 ForeverCompanionDB.professionWorkspace='materials'
 local oldProvider,oldTimer,oldMapInfo=LibQuestieDB,C_Timer,C_Map.GetMapInfo
 local queue={};C_Timer={After=function(_,fn) queue[#queue+1]=fn end}
 LibQuestieDB={RequireContract=function(v) return v==1 end,ModeIndicator={GetStatus=function() return {expansion='Forever'} end},Quest={},
  Item={GetAllIds=function() return {990001} end,name=function(id) if id==990001 then return 'SAMPLE: Frost Cloth' end end,npcDrops=function() return {990002} end,vendors=function() return {990003} end},
  Npc={name=function(id) return id==990002 and 'SAMPLE: Frostweaver' or 'SAMPLE: Supply vendor' end,spawns=function() return {[12]={{42,51},{45,54}}} end},
  Support={Get=function() return {private={areaIdToUiMapId='{[12]=1429,}'}} end}}
 C_Map.GetMapInfo=function(map) if map==1429 then return {name='SAMPLE: Research zone',mapType=3} end;return oldMapInfo and oldMapInfo(map) end
 ForeverCompanionMaterialFinder.Open('SAMPLE: Frost Cloth')
 local finder,searchButton
 for _,f in ipairs(frames) do if f.name=='ForeverCompanionMaterialFinderPanel' then finder=f end end
 for _,f in ipairs(frames) do if f.parent==finder.id and f.text=='Search database' then searchButton=f end end
 assert(searchButton);searchButton.OnClick();while #queue>0 do table.remove(queue,1)() end
 local sourceButton
 for _,f in ipairs(frames) do if f.parent==finder.id and f.record and f.record.id==990001 then
  for _,child in ipairs(frames) do if child.parent==f.id and child.text=='Sources' then sourceButton=child end end
 end end
 assert(sourceButton);sourceButton.OnClick()
 exportNative('ui_material_sources_354_native.json')
 local choose
 for _,f in ipairs(frames) do if f.parent==finder.id and f.record and f.record.id==990002 then
  for _,child in ipairs(frames) do if child.parent==f.id and child.text=='Choose area' then choose=child end end
 end end
 assert(choose and choose.enabled)
 choose.OnClick(choose)
 local location
 for _,f in ipairs(frames) do if f.kind=='Button' and f.text and f.text:find('42.0, 51.0',1,true) then location=f end end
 assert(location)
 local navigate=ForeverCompanionQuestWaypoints.Navigate;local selected
 ForeverCompanionQuestWaypoints.Navigate=function(p) selected=p;return 'Synthetic source selected' end
 location.OnClick();assert(selected and selected.reference and selected.x==.42)
 ForeverCompanionQuestWaypoints.Navigate=navigate;ForeverCompanionInterface.CloseMenu();finder:Hide()
 LibQuestieDB,C_Timer,C_Map.GetMapInfo=oldProvider,oldTimer,oldMapInfo
 local oldMinimap=Minimap
 local oldVector,oldFacing,oldBest,oldPos,oldWorld=CreateVector2D,GetPlayerFacing,C_Map.GetBestMapForUnit,C_Map.GetPlayerMapPosition,C_Map.GetWorldPosFromMapPos
 local p=ForeverCompanionQuestPlanner;local oldLive,oldSelected,oldSupported,oldTargets=p.GetLive,p.GetSelected,p.IsSupported,ForeverCompanionQuestWaypoints.Targets
 local q={id=990009,title='SAMPLE: Nearby quest',complete=false,objectiveStates={{known=true,done=false}}}
 p.GetLive=function() return {q} end;p.GetSelected=function() return q end;p.IsSupported=function() return true end
 ForeverCompanionQuestWaypoints.Targets=function() return {{map=1429,x=.51,y=.52,source='Synthetic fixture',objectiveIndex=1,reference=true}} end
 Minimap=CreateFrame('Frame','ForeverCompanionQuestMinimapSample',UIParent);Minimap:SetSize(180,180);Minimap:SetPoint('CENTER')
 Minimap.GetViewRadius=function() return 100 end
 CreateVector2D=function(x,y) return {GetXY=function() return x,y end} end
 C_Map.GetBestMapForUnit=function() return 1429 end;C_Map.GetPlayerMapPosition=function() return CreateVector2D(.5,.5) end
 C_Map.GetWorldPosFromMapPos=function(map,v) local x,y=v:GetXY();return 1,CreateVector2D(y*1000,x*1000) end
 GetPlayerFacing=function() return 0 end
 ForeverCompanionQuestMinimap.Refresh();assert(ForeverCompanionQuestMinimap.Status():find('1 nearby',1,true))
 exportNative('ui_quest_minimap_354_native.json');ForeverCompanionQuestMinimap.Hide()
 Minimap=oldMinimap;CreateVector2D,GetPlayerFacing=oldVector,oldFacing;C_Map.GetBestMapForUnit,C_Map.GetPlayerMapPosition,C_Map.GetWorldPosFromMapPos=oldBest,oldPos,oldWorld
 p.GetLive,p.GetSelected,p.IsSupported=oldLive,oldSelected,oldSupported;ForeverCompanionQuestWaypoints.Targets=oldTargets
 ForeverCompanionRefresh()
 io.write('PASS: recipe editor/import, database item search, source area selection and selected-quest minimap integration\n')
end

-- 3.56 actual UI exercises: static guide filtering and native roster navigation.
do
 local W=ForeverCompanionRotationWorkspace
 local oldPriority,oldKnown,oldSpell,oldScan=ForeverCompanionVisiblePriority,ForeverCompanionKnownSpell,C_Spell,ForeverCompanionSpellbook.Scan
 local oldRefresh=ForeverCompanionRefresh
 ForeverCompanionVisiblePriority=function() return {'1. SAMPLE: Learned ability — Practice safely before larger pulls.','2. SAMPLE: Training check — Confirm availability at a class trainer.','3. SAMPLE: Positioning — Stay aware of the group.'},'SAMPLE: Beginner priorities','Reference advice; not combat recommendations.','Synthetic UI fixture',{'Sample learned','Sample missing'}, {spellIDs={996001,996002},keepOrder=true,opener='Review your spellbook and recovery options.'} end
 ForeverCompanionKnownSpell=function(id) return id==996001 end
 C_Spell={GetSpellInfo=function(query)
  if query=='Sample learned' or query==996001 then return {name='Sample learned',spellID=996001,iconID=123} end
  if query=='Sample missing' or query==996002 then return {name='Sample missing',spellID=996002,iconID=124} end
 end}
 ForeverCompanionSpellbook.Scan=function() return {supported=true,complete=true,inspected=2,englishNames=true,known={}} end
 ForeverCompanionRefresh=function() W.Render('Leveling','WARRIOR','leveling',20,'Damage',{},'WARRIOR') end
 W.SetFilter('all');ForeverCompanionRefresh()
 assert(W.rows[1].status.text=='In your spellbook' and W.rows[2].status.text:find('not found',1,true))
 exportNative('ui_rotation_readiness_356_native.json')
 W.filters.learned.OnClick();assert(W.rows[1].number.text=='1')
 assert(W.rows[1].spellID==996001 and not W.rows[2].visible,'learned tab filters the actual guide')
 W.search:SetText('no synthetic match');W.search.OnTextChanged();ForeverCompanionRefreshQueue.Flush();assert(not W.rows[1].visible,'literal search shows the empty view')
 exportNative('ui_rotation_empty_356_native.json')
 W.search:SetText('');W.SetFilter('training');assert(W.rows[1].spellID==996002 and W.rows[1].number.text=='2','training tab keeps original priority')
 W.SetFilter('all');ForeverCompanionRefresh=oldRefresh
 ForeverCompanionVisiblePriority,ForeverCompanionKnownSpell,C_Spell,ForeverCompanionSpellbook.Scan=oldPriority,oldKnown,oldSpell,oldScan
 local oldAPI,oldEnum=C_DamageMeter,Enum
 local roster={}
 for i=1,18 do roster[i]={name='SAMPLE: Player '..i..'-Realm',sourceGUID='sample-'..i,isLocalPlayer=i==15,totalAmount=12345678-i*12345,amountPerSecond=12345-i*123,classFilename=i%2==0 and 'MAGE' or 'WARRIOR'} end
 C_DamageMeter={GetCombatSessionFromType=function() return {combatSources=roster,maxAmount=12345678,durationSeconds=123} end}
 Enum={DamageMeterType={Dps=1,DamageDone=0},DamageMeterSessionType={Current=1,Overall=0,Expired=2}}
 local meter=ForeverCompanionCombatMeter
 meter.Show();meter.SetMode('DPS');meter.SetSession('Current');meter.SetLayout('expanded');meter.SetRows(6);meter.SetNumberFormat('exact');meter.SetHideRealm(true)
 assert(meter.FocusLocalPlayer() and meter.SelectedRow()==15,'native local-player identity drives find me')
 exportNative('ui_meter_personal_356_native.json')
 meter.SetNumberFormat('compact');meter.SetHideRealm(false);meter.SetLayout('standard');meter.Hide();C_DamageMeter,Enum=oldAPI,oldEnum
 ForeverCompanionRefresh()
 ForeverCompanionTraining.Open('')
 local costButton
 for _,f in ipairs(frames) do if f.text=='Review training costs' and f.OnClick then costButton=f end end
 assert(costButton);costButton.OnClick();exportNative('ui_training_costs_356_native.json');ForeverCompanionInterface.CloseMenu();ForeverCompanionTraining.Toggle()
 io.write('PASS: rotation search/readiness tabs, original priority labels and meter personal navigation UI\n')
end

-- 3.57 actual quest -> item -> source -> quest integration (synthetic records).
do
 local p=ForeverCompanionQuestPlanner
 local oldLive,oldSelected,oldSupported=p.GetLive,p.GetSelected,p.IsSupported
 local oldProvider,oldNavigate,oldOpen=LibQuestieDB,ForeverCompanionQuestWaypoints.Navigate,ForeverCompanionOpenQuestGuide
 local oldMapInfo=C_Map.GetMapInfo
 local q={id=997001,title='SAMPLE: Camp supplies',zone='Synthetic camp',objectives={'SAMPLE: Camp Supply: 1/5'},objectiveStates={{known=true,kind='item',done=false,current=1,required=5}}}
 p.GetLive=function() return {q} end;p.GetSelected=function() return q end;p.IsSupported=function() return true end
 LibQuestieDB={RequireContract=function() return true end,ModeIndicator={GetStatus=function() return {expansion='Forever'} end},Quest={name=function() return q.title end,objectives=function() return {[3]={{997002,nil,5}}} end},Item={name=function() return 'SAMPLE: Camp Supply' end,npcDrops=function() return {997003} end},Npc={name=function() return 'SAMPLE: Supply carrier' end,spawns=function() return {[12]={{42,51}}} end},Support={Get=function() return {private={areaIdToUiMapId='{[12]=1429,}'}} end}}
 C_Map.GetMapInfo=function() return {name='SAMPLE: Camp area',mapType=3} end
 SlashCmdList.FOREVERCOMPANION('open quests');ForeverCompanionRefresh()
 local itemButton
 for _,f in ipairs(frames) do if f.text=='Item sources' and f.OnClick and f.visible then itemButton=f end end
 assert(itemButton and itemButton.enabled,'matched item objective exposes source handoff')
 exportNative('ui_quest_item_357_native.json');itemButton.OnClick()
 local finder,returnButton,sourceButton
 for _,f in ipairs(frames) do
  if f.name=='ForeverCompanionMaterialFinderPanel' then finder=f end
  if f.text=='Back to quest' and f.OnClick then returnButton=f end
 end
 assert(finder.visible and returnButton.visible)
 for _,f in ipairs(frames) do if f.parent==finder.id and f.record and f.record.id==997003 then for _,child in ipairs(frames) do if child.parent==f.id and child.text=='Choose area' then sourceButton=child end end end end
 assert(sourceButton and sourceButton.enabled)
 exportNative('ui_quest_item_sources_357_native.json');sourceButton.OnClick()
 local area
 for _,f in ipairs(frames) do if f.kind=='Button' and f.text and f.text:find('42.0, 51.0',1,true) and f.visible and f.OnClick then area=f end end
 assert(area)
 local navigated
 ForeverCompanionQuestWaypoints.Navigate=function(t,show,title,id) navigated={target=t,id=id};return 'Synthetic item source selected.' end
 area.OnClick();assert(navigated and navigated.id==q.id and navigated.target.questItemID==997002)
 q.objectiveStates[1].done=true;ForeverCompanionRefresh();assert(not sourceButton.enabled,'source browser disables old directions after item completion')
 navigated=nil;area.OnClick();assert(not navigated,'old area menu cannot bypass objective completion')
 local returned;ForeverCompanionOpenQuestGuide=function(id) returned=id end
 returnButton.OnClick();assert(returned==q.id and not finder.visible,'return path remains available after completion')
 ForeverCompanionQuestWaypoints.Navigate,ForeverCompanionOpenQuestGuide=oldNavigate,oldOpen
 p.GetLive,p.GetSelected,p.IsSupported=oldLive,oldSelected,oldSupported;LibQuestieDB=oldProvider;C_Map.GetMapInfo=oldMapInfo
 ForeverCompanionRefresh()
 io.write('PASS: quest item source button, direct ID lookup, context navigation, completion guards and return-to-quest UI\n')
end

do
 local entries,selected={},nil
 for i=1,25 do local index=i;entries[i]={label='SAMPLE location '..i,action=function() selected=index end} end
 ForeverCompanionInterface.PagedMenu(UIParent,'SAMPLE PAGED REFERENCES',entries,nil,360)
 local function menuButton(caption)
  local latest
  for _,f in ipairs(frames) do if f.text==caption and f.OnClick then latest=f end end
  return assert(latest)
 end
 local disabled=menuButton('Previous locations');assert(not disabled.enabled);disabled.OnClick();assert(selected==nil)
 for i=1,3 do menuButton('More locations').OnClick() end
 local final=menuButton('SAMPLE location 25');assert(final.visible);final.OnClick();assert(selected==25)
 io.write('PASS: actual paged reference menu reaches the final location and blocks disabled actions\n')
end

-- 3.58: exercise every entry in all six navigation groups at both heights.
do
 local state=ForeverCompanionUIState
 local main=frames[state.scrollFrame.parent]
 local bg=assert(state.contentBackground)
 assert(bg.kind=='Texture' and bg.parent==main.id and bg.layer=='BORDER',
  'opaque content decoration must not be an independently raised sibling frame')
 assert(state.scrollFrame:GetFrameLevel()>main:GetFrameLevel())
 assert(state.scrollFrame.child:GetFrameLevel()>state.scrollFrame:GetFrameLevel())
 local function visible(f)
  return f.visible and (not f.parent or visible(frames[f.parent]))
 end
 local function bounds(f)
  local p=f.point
  if not p or not f.width or not f.height then return end
  local x,y
  if type(p[2])=='table' then
   if p[2]~=main or p[1]~=p[3] then return end
   x,y=p[4] or 0,p[5] or 0
  else x,y=p[2] or 0,p[3] or 0 end
  if p[1]:find('RIGHT') then x=main.width+x-f.width end
  if p[1]:find('BOTTOM') then y=main.height-y-f.height else y=-y end
  return {x,y,x+f.width,y+f.height}
 end
 local function checkControls()
  local controls={}
  for _,f in ipairs(frames) do
   if f.kind=='Button' and f.parent==main.id and visible(f) then
    local r=bounds(f)
    if r then
     assert(r[1]>=0 and r[2]>=0 and r[3]<=main.width and r[4]<=main.height,'control outside main window: '..f.text)
     for _,other in ipairs(controls) do
      local s=other.rect
      assert(r[3]<=s[1] or r[1]>=s[3] or r[4]<=s[2] or r[2]>=s[4],
       'overlapping controls on '..ForeverCompanionDB.tab..': '..f.text..' / '..other.frame.text)
     end
     controls[#controls+1]={frame=f,rect=r}
    end
   end
  end
  local bottom=state.scrollFrame.points[2]
  assert(bottom[1]=='BOTTOMRIGHT' and bottom[3]>=92,'viewport overlaps fixed footer/hint')
 end
 local calls={}
 local originals={}
 local endpoints={HunterPets={ForeverCompanionHunterWorkspace,'Open'},Gear={ForeverCompanionGearFinderWorkspace,'Open'},Plan={ForeverCompanionLevelingWorkspace,'Open'},Map={ForeverCompanionMapHub,'Open'},Meter={ForeverCompanionCombatMeter,'Toggle'},
  Materials={ForeverCompanionMaterialFinder,'Open'},Training={ForeverCompanionTraining,'Toggle'}}
 for target,endpoint in pairs(endpoints) do
  local key,object,method=target,endpoint[1],endpoint[2]
  originals[key]=object[method]
  object[method]=function(...) calls[key]=(calls[key] or 0)+1;return originals[key](...) end
 end
 for _,compact in ipairs({false,true}) do
  if (ForeverCompanionDB.compact==true)~=compact then state.compactButton.OnClick() end
  ForeverCompanionDB.beginnerMode=true;ForeverCompanionRefresh()
  for i,group in ipairs(ForeverCompanionGoalNavigation) do
   for j,entry in ipairs(group.items) do
    if entry[2]=='Meter' then ForeverCompanionCombatMeter.Hide() end
    local before=calls[entry[2]] or 0
    if entry[2]=='Meter' then
     state.goalButtons[i].OnClick();assert(calls.Meter==before+1,'combat meter opens directly')
    else
    state.goalButtons[i].OnClick()
    local choice
    for _,f in ipairs(frames) do if f.kind=='Button' and f.text==entry[1] and visible(f) then choice=f end end
    assert(choice,'missing menu item '..entry[1])
    choice.OnClick()
    if endpoints[entry[2]] then assert(calls[entry[2]]==before+1,'dead navigation action: '..entry[1])
    else assert(ForeverCompanionDB.tab==entry[2],'wrong page: '..entry[1]) end
    end
    checkControls()
    if entry[2]=='Overview' then
     for _,f in ipairs(frames) do
      if f.text=='JOURNAL SHORTCUTS' then
       assert(visible(f)==not compact,'duplicate Home steps must clear compact data status')
      end
     end
    elseif entry[2]=='Meter' then
     for _,f in ipairs(frames) do
      if f.name=='ForeverCompanionCombatMeterWindow' then assert(visible(f),'meter action must open the window') end
     end
    end
    if j==1 then exportNative('ui_group_'..i..'_'..(compact and 'compact' or 'expanded')..'_native.json') end
   end
  end
  ForeverCompanionDB.beginnerMode=false;ForeverCompanionRefresh()
  for _,f in ipairs(frames) do
   if f.section and f.section~='Training' then f.OnClick();checkControls() end
  end
 end
 for target,endpoint in pairs(endpoints) do endpoint[1][endpoint[2]]=originals[target] end
 ForeverCompanionDB.beginnerMode=true;ForeverCompanionRefresh()
 io.write('PASS: all six navigation groups, every menu action, advanced tabs, stacking and non-overlapping main controls at both heights\n')
end

-- 3.59: Home controls and visibility survive both layout and mode changes.
do
 local state=ForeverCompanionUIState
 local function visible(f)
  return f.visible and (not f.parent or visible(frames[f.parent]))
 end
 local function label(value)
  for _,f in ipairs(frames) do if f.kind=='FontString' and f.text==value then return f end end
  error('missing Home label: '..value)
 end
 local function action(value)
  for _,f in ipairs(frames) do
   if f.OnClick and f.caption and f.caption.text==value and visible(f) then return f end
  end
  error('missing visible Home action: '..value)
 end
 local calls=0
 local originalOpen=ForeverCompanionMapHub.Open
 ForeverCompanionMapHub.Open=function(...) calls=calls+1;return originalOpen(...) end
 SlashCmdList.FOREVERCOMPANION('overview')
 ForeverCompanionDB.beginnerMode=true;ForeverCompanionRefresh()
 for _,compact in ipairs({false,true,false}) do
  if (ForeverCompanionDB.compact==true)~=compact then state.compactButton.OnClick() end
  local beforeHero=calls
  action('VIEW WORLD MAP').OnClick()
  assert(calls==beforeHero+1 and ForeverCompanionDB.tab=='Overview','hero map action opens the hub and preserves Home')
  if not compact then
   local before=calls
   action('SEE WHERE TO GO ON THE MAP').OnClick()
   assert(calls==before+1,'beginner step map action opens the map hub')
  end
  local before=calls
  SlashCmdList.FOREVERCOMPANION('open map')
  assert(calls==before+1 and ForeverCompanionDB.tab=='Overview','slash map destination shares Home dispatch')
  action('Show advanced view').OnClick()
  for i=1,2 do
   ForeverCompanionRefresh()
   assert(visible(label('RECOMMENDED NEXT STEPS'))==not compact,'refresh must preserve compact recommendations visibility')
   assert(visible(label("TODAY'S FOCUS"))==not compact,'refresh must preserve compact focus visibility')
   assert(visible(label('CHARACTER OVERVIEW')) and visible(label('DATA STATUS')),'compact advanced Home retains main cards and status')
  end
  exportNative('ui_home_advanced_'..(compact and 'compact' or 'expanded')..'_359_native.json')
  action('Show beginner view').OnClick()
  assert(not visible(label('RECOMMENDED NEXT STEPS')) and not visible(label("TODAY'S FOCUS")))
  assert(visible(label('JOURNAL SHORTCUTS'))==not compact)
  exportNative('ui_home_beginner_'..(compact and 'compact' or 'expanded')..'_359_native.json')
 end
 ForeverCompanionMapHub.Open=originalOpen
 local scroll=state.scrollFrame
 local originalHeight=scroll.GetHeight
 scroll.GetHeight=function() return 200 end
 SlashCmdList.FOREVERCOMPANION('quests')
 scroll.child:SetHeight(800);scroll:SetVerticalScroll(0);state.updateScrollHint()
 local hint=label('More below  ·  Scroll to continue')
 assert(visible(hint),'long visible page offers scrolling guidance')
 SlashCmdList.FOREVERCOMPANION('overview')
 scroll.child:SetHeight(800);state.updateScrollHint()
 assert(not visible(hint),'Home cannot show a hint for a hidden viewport')
 SlashCmdList.FOREVERCOMPANION('quests')
 scroll.child:SetHeight(800);state.updateScrollHint()
 assert(visible(hint),'returning to a long page restores its hint')
 scroll.GetHeight=originalHeight
 SlashCmdList.FOREVERCOMPANION('overview')
 io.write('PASS: Home map actions, compact/expanded mode transitions, repeated refresh and visible-page scroll hints\n')
end

-- 3.60: actual planner controls with synthetic live quests, including stale clicks.
do
 local p,P,W=ForeverCompanionQuestPlanner,ForeverCompanionLevelingPlan,ForeverCompanionLevelingWorkspace
 local oldLive,oldSupported,oldPin,oldSelect=p.GetLive,p.IsSupported,p.IsPinned,p.Select
 local oldLocations,oldShow=ForeverCompanionQuestWaypoints.MapLocations,ForeverCompanionQuestWaypoints.Show
 local oldGuide,oldMap,oldSaved=ForeverCompanionOpenQuestGuide,C_Map,ForeverCompanionDB.levelingPlan
 local live={};for i=1,9 do live[i]={id=996000+i,title='SAMPLE: Leveling quest '..i,zone=i<=5 and 'Sample camp' or 'Sample forest',complete=i==7,objectives={'Collect sample supplies: 1/5'},objectiveStates={{known=true,current=1,required=5}}} end
 local supported,scans,maps,guides=true,0,0,0
 p.GetLive=function() return live end;p.IsSupported=function() return supported end;p.IsPinned=function(q) return q.id==996009 end;p.Select=function() end
 C_Map={GetBestMapForUnit=function() return 10 end,GetPlayerMapPosition=function() return {GetXY=function() return .1,.1 end} end}
 ForeverCompanionQuestWaypoints.MapLocations=function()
  scans=scans+1;local list={};for i=1,3 do if live[i] then list[#list+1]={quest=live[i],target={map=10,x=.1+i*.1,y=.2}} end end;return list
 end
 ForeverCompanionQuestWaypoints.Show=function() maps=maps+1;return 'Synthetic map action' end
 ForeverCompanionOpenQuestGuide=function() guides=guides+1;return true end
 ForeverCompanionDB.levelingPlan={}
 SlashCmdList.FOREVERCOMPANION('plan')
 local panel;for _,f in ipairs(frames) do if f.name=='ForeverCompanionLevelingPlanner' then panel=f end end
 assert(panel and panel.visible and panel.scale<=1,'planner fits the screen')
 panel:Hide()
 local homeAction
 for _,f in ipairs(frames) do if f.OnClick and f.caption and f.caption.text=='PLAN MY SESSION' then homeAction=f end end
 assert(homeAction);homeAction.OnClick();assert(panel.visible,'Home opens the real planner')
 local function visible(f) return f.visible and (not f.parent or visible(frames[f.parent])) end
 local function control(caption,parent)
  local found;for _,f in ipairs(frames) do if f.OnClick and f.text==caption and visible(f) and (not parent or f.parent==parent.id) then found=f end end
  return assert(found,'missing control '..caption)
 end
 local function row(id)
  for _,f in ipairs(frames) do if f.parent==panel.id and f.record and f.record.id==id and visible(f) then return f end end
  error('missing planner row '..id)
 end
 local function geometry(parent)
  local bounds={}
  for _,f in ipairs(frames) do
   if f.kind=='Button' and f.parent==parent.id and visible(f) then
    local p=f.point;local x,y
    if type(p[2])=='table' then assert(p[2]==parent);x,y=p[4] or 0,p[5] or 0 else x,y=p[2] or 0,p[3] or 0 end
    if p[1]:find('RIGHT') then x=parent.width+x-f.width end
    if p[1]:find('BOTTOM') then y=parent.height-y-f.height else y=-y end
    local r={x,y,x+f.width,y+f.height}
    assert(x>=0 and y>=0 and r[3]<=parent.width and r[4]<=parent.height,'planner control must fit its parent: '..f.text)
    for _,b in ipairs(bounds) do assert(r[3]<=b[1] or r[1]>=b[3] or r[4]<=b[2] or r[2]>=b[4],'planner controls overlap: '..f.text) end
    bounds[#bounds+1]=r
   end
  end
 end
 geometry(panel);geometry(row(996001))
 row(996001).add.OnClick();row(996002).add.OnClick()
 assert(#P.Settings().quests==2 and not row(996001).add.enabled)
 control('My saved plan',panel).OnClick();row(996002).up.OnClick()
 geometry(panel);geometry(row(996002))
 assert(P.Settings().quests[1].id==996002)
 exportNative('ui_leveling_plan_saved_360_native.json')
 row(996002).down.OnClick();assert(P.Settings().quests[1].id==996001)
 -- The tracker menu also adds exact live identities and rejects stale menu actions.
 local oldTracker=ForeverCompanionDB.questTracker
 ForeverCompanionDB.questTracker={mode='all'}
 ForeverCompanionQuestTracker.Show();ForeverCompanionQuestTracker.page=1
 for _,f in ipairs(frames) do
  if f.kind=='EditBox' and frames[f.parent] and frames[f.parent].name=='ForeverCompanionQuestTrackerFrame' then f:SetText('') end
 end
 ForeverCompanionQuestTracker.Refresh()
 local trackerRow
 for _,f in ipairs(frames) do if f.item and f.item.quest and f.item.quest.title:find('SAMPLE: Leveling quest',1,true) and f.OnClick and visible(f) and not P.Contains(f.item.quest) then trackerRow=f end end
 assert(trackerRow,'tracker displays the synthetic quest')
 trackerRow.OnClick(trackerRow,'RightButton')
 local trackerIdentity=trackerRow.item.quest
 control('Add to leveling plan').OnClick();assert(P.Contains(trackerIdentity))
 P.Remove(trackerIdentity)
 trackerRow.OnClick(trackerRow,'RightButton')
 local staleAdd=control('Add to leveling plan')
 local replacedIndex;for i,q in ipairs(live) do if q==trackerIdentity then replacedIndex=i end end
 live[replacedIndex]={id=trackerIdentity.id,title='SAMPLE: Changed identity'}
 staleAdd.OnClick();assert(not P.Contains(trackerIdentity),'old tracker menu cannot save a changed quest identity')
 live[replacedIndex]=trackerIdentity;ForeverCompanionInterface.CloseMenu()
 ForeverCompanionDB.questTracker=oldTracker
 control('Suggestions',panel).OnClick()
 control('Next',panel).OnClick();assert(W.page==2)
 control('Previous',panel).OnClick();assert(W.page==1)
 local mode=control('Nearby first',panel);mode.OnClick(mode)
 control('Turn-ins first').OnClick();assert(P.Settings().mode=='turnins' and row(996007))
 local filter=control('All quest locations',panel);filter.OnClick();assert(P.Settings().localOnly)
 local search;for _,f in ipairs(frames) do if f.parent==panel.id and f.kind=='EditBox' then search=f end end
 search:SetText('[');assert(not control('Next',panel).enabled)
 control('Clear filters',panel).OnClick();assert(search:GetText()=='' and not P.Settings().localOnly)
 control('Zone overview',panel).OnClick()
 local camp;for _,f in ipairs(frames) do if f.parent==panel.id and f.record and f.record.name=='Sample camp' then camp=f end end
 assert(camp and camp.record.total==5);exportNative('ui_leveling_plan_zones_360_native.json')
 camp.add.OnClick();assert(W.view=='suggestions')
 for _,f in ipairs(frames) do if f.parent==panel.id and f.record and visible(f) then assert(f.record.zone=='Sample camp') end end
 control('Clear filters',panel).OnClick();exportNative('ui_leveling_plan_suggestions_360_native.json')
 row(996001).map.OnClick();assert(maps==1)
 local stale=row(996001);table.remove(live,1);stale.guide.OnClick();assert(guides==0,'stale row must not open another quest')
 control('My saved plan',panel).OnClick();assert(not row(996001).guide.enabled and not row(996001).map.enabled)
 assert(#P.Settings().quests==2,'removed quests stay in the saved plan until explicitly removed')
 supported=false;W.Refresh();assert(not row(996002).guide.enabled)
 row(996002).map.OnClick();assert(maps==1,'unavailable scan cannot start directions')
 exportNative('ui_leveling_plan_unavailable_360_native.json')
 row(996001).add.OnClick();assert(#P.Settings().quests==1,'unavailable entries can still be removed manually')
 supported=true;W.Refresh();row(996002).guide.OnClick();assert(guides==1 and not panel.visible,'details opens without planner covering it')
 local before=scans;W.Refresh();assert(scans==before,'hidden planner does not rescan quest locations')
 p.GetLive,p.IsSupported,p.IsPinned,p.Select=oldLive,oldSupported,oldPin,oldSelect
 ForeverCompanionQuestWaypoints.MapLocations,ForeverCompanionQuestWaypoints.Show=oldLocations,oldShow
 ForeverCompanionOpenQuestGuide,C_Map,ForeverCompanionDB.levelingPlan=oldGuide,oldMap,oldSaved
 io.write('PASS: planner UI paging, filters, saved order, zone handoff, stale actions, unavailable data and hidden-window idle behavior\n')
end

-- Gear research end-to-end controls, async loading, acquisition and layout.
;(function()
 local G,W,H=ForeverCompanionGearFinder,ForeverCompanionGearFinderWorkspace,ForeverCompanionGearHunts
 local oldAPI,oldInventory,oldRecords,oldSaved,oldPlayerInfo=C_Item,GetInventoryItemLink,ForeverCompanionLoot.records,ForeverCompanionDB.gearFinder,C_PlayerInfo
 ForeverCompanionLoot.testGearSources=ForeverCompanionLoot.gearSources;ForeverCompanionLoot.gearSources=nil
 local records={};local owned={};local scanCount,loadCount=0,0
 local function pump(dt) if W.root and W.root.OnUpdate then W.root.OnUpdate(W.root,dt or .2) end end
 for i=1,14 do records[#records+1]={itemID=997000+i,item=string.format('SAMPLE: Research item %02d',i),slot='Head',dungeon='Sample dungeon',boss='Sample boss',status='Synthetic UI fixture',source='https://example.test/'..i} end
 records[#records+1]={itemID=997001,item=records[1].item,slot='Head',dungeon='Alternative dungeon',boss='Alternative boss',status='Synthetic source',source='https://example.test/alternative'}
 ForeverCompanionLoot.records=records;ForeverCompanionDB.gearFinder={bestNow=false};G.RetryData()
 C_Item={GetItemInfo=function(id) scanCount=scanCount+1;if id==997014 then return end;return type(id)=='number' and records[id-997000].item or 'SAMPLE: Equipped',id,type(id)=='number' and (1+id%4) or 2,20,1,'Armor','Cloth',1,'INVTYPE_HEAD',nil,nil,4,1 end,
 GetItemStats=function(link) return {ITEM_MOD_STRENGTH_SHORT=link=='equipped' and 5 or 15,ITEM_MOD_STAMINA_SHORT=4} end,
 GetItemCount=function(id) return owned[id] or 0 end,GetItemUniquenessByID=function() return false end,RequestLoadItemDataByID=function() loadCount=loadCount+1 end}
 C_PlayerInfo={CanUseItem=function() return true end}
 GetInventoryItemLink=function() return 'equipped' end
 H.events.OnEvent(H.events,'PLAYER_ENTERING_WORLD');H.events.OnUpdate(H.events,.2);assert(not H.events.OnUpdate)
 SlashCmdList.FOREVERCOMPANION('gear');assert(W.root:IsShown() and #W.results==13 and W.root.scale<=1)
 W.root.OnEvent(W.root,'UI_SCALE_CHANGED');assert(W.root.scale<=1,'scaling handler preserved')
 local readsBefore=scanCount;local buildsBefore=G.metrics.builds
 local chosen=W.current.record.itemID
 W.rows[1].OnMouseWheel(W.rows[1],-1);assert(W.offset==1 and W.rows[1].record==W.results[2])
 assert(W.current.record.itemID==chosen,'scrolling preserves detail selection')
 W.scrollBar.OnValueChanged(W.scrollBar,999);assert(W.offset==7 and W.rows[6].record==W.results[13],'scrollbar reaches last result and clamps')
 assert(W.revealButton:IsEnabled() and W.revealButton:GetText()=='Find selected','off-screen selection has a return action')
 W.revealButton.OnClick();assert(W.offset==0 and W.current.record.itemID==chosen and not W.revealButton:IsEnabled(),'return action restores visible selection without changing it')
 W.scrollBar.OnValueChanged(W.scrollBar,0);assert(W.offset==0)
 W.rows[1].OnMouseWheel(W.rows[1],1);assert(W.offset==0,'wheel clamps at start')
 assert(scanCount==readsBefore and G.metrics.builds==buildsBefore,'scrolling reuses the current data snapshot')
 W.Select(997001);assert(W.current.record.itemID==997001 and #W.current.sources==2)
 assert(scanCount==readsBefore and G.metrics.builds==buildsBefore,'selection does not rescan item metadata')
 local function fake(ids) local t={};for _,id in ipairs(ids) do t[#t+1]={record={itemID=id}} end;return t end
 local before=fake({1,2,3,4,5,6,7,8,9,10})
 assert(W.AnchorOffset(before,fake({11,1,2,3,4,5,6,7,8,9,10}),2)==3,'new higher rows preserve the existing first visible identity')
 assert(W.AnchorOffset(before,fake({1,2,4,5,6,7,8,9,10}),2)==2,'removed anchor uses next surviving result')
 assert(W.AnchorOffset(before,{},7)==0,'empty refreshed list resets safely')
 W.ScrollTo(3);local anchor=W.rows[1].record.record.itemID
 local reorderStats=C_Item.GetItemStats
 C_Item.GetItemStats=function(link) if link==997013 then return {ITEM_MOD_STRENGTH_SHORT=100} end;return reorderStats(link) end
 G.Invalidate();W.Refresh();assert(W.offset==4 and W.rows[1].record.record.itemID==anchor,'background re-ranking retains scroll anchor')
 C_Item.GetItemStats=reorderStats;G.Invalidate();W.Refresh();assert(W.offset==3 and W.rows[1].record.record.itemID==anchor)
 W.ScrollTo(0)

 W.sourceButton.OnClick();assert(W.current.record.itemID==997001)
 W.saveButton.OnClick();assert(W.current.saved);assert(G.SavedSource(997001).dungeon=='Alternative dungeon','selected hunt source is retained');W.trackButton.OnClick();assert(G.Settings().tracked=='997001' and H.tracker:IsShown())
 G.Settings().trackerHidden=true;H.Refresh();W.Refresh();assert(not H.tracker:IsShown() and W.trackButton:GetText()=='Show tracker')
 W.trackButton.OnClick();assert(H.tracker:IsShown() and G.Settings().tracked=='997001','restore hidden tracker without unpinning')
 W.tabs.hunts.OnClick();assert(#W.results==1 and W.current.tracked)
 exportNative('ui_gear_hunts_364_native.json')
 W.tabs.discover.OnClick();local searchBuilds=G.metrics.builds
 for _,query in ipairs({'R','Research','Research 02'}) do W.search:SetText(query);W.search.OnTextChanged(W.search,true) end
 assert(G.metrics.builds==searchBuilds and W.searchPending and W.rows[1].enabled==false,'typing queues work and blocks stale row actions');W.ScrollTo(4);assert(W.offset==0,'pending search blocks stale scrolling')
 pump(.03);assert(G.metrics.builds==searchBuilds);pump(.06)
 assert(G.metrics.builds==searchBuilds+1 and #W.results==1 and W.offset==0 and not W.scrollBar:IsShown() and W.current.record.itemID==997002,'typing burst becomes one scan after the debounce')
 pump(.02);assert(not W.root.OnUpdate,'worker detaches after queued loads and searches complete')
 -- Even a callback captured before the search must not save the newly selected result.
 W.search:SetText('Research 03');W.search.OnTextChanged(W.search,true);W.saveButton.OnClick()
 assert(not G.Settings().hunts['997003'],'stale action cannot save a different filtered item')
 W.search:SetText('Research 02');W.search.OnTextChanged(W.search,true);pump(.1)
 W.search:SetText('[');W.search.OnTextChanged(W.search,true);pump(.1);assert(#W.results==0)
 W.search:SetText('');W.search.OnTextChanged(W.search,true);pump(.1)
 W.slots[2].OnClick();assert(#W.results==0 and G.Settings().slot==2)
 W.slots[0].OnClick();W.readyButton.OnClick();assert(#W.results==14,'including unknown requirements reveals loading row')
 pump(.2);assert(loadCount==1);W.Refresh();pump(.2);assert(loadCount==1,'failed load not retried every frame')
 W.upgradeButton.OnClick();assert(#W.results==13 and W.results[1].recommended and W.results[1].rank==1)
 W.Select(997002);exportNative('ui_gear_discover_364_native.json')
 do
 local savedTooltip=GameTooltip
 local itemTip={lines={}}
 function itemTip:SetOwner(owner) self.owner=owner end
 function itemTip:IsOwned(owner) return self.owner==owner end
 function itemTip:ClearLines() self.lines={} end
 function itemTip:NumLines() return #self.lines end
 function itemTip:SetHyperlink() end
 function itemTip:SetText(value) self:AddLine(value) end
 function itemTip:AddLine(value) self.lines[#self.lines+1]=value end
 function itemTip:Show() self.visible=true end
 function itemTip:Hide() self.visible=false end
 GameTooltip=itemTip
 W.itemHover.OnEnter(W.itemHover)
 assert(itemTip.visible and itemTip.lines[1]==W.current.record.item and itemTip.lines[2]=='+15 Strength')
 W.itemHover.OnLeave(W.itemHover);assert(not itemTip.visible)
 function itemTip:SetItemByID(id) self:AddLine('Client item '..id) end
 W.rows[1].OnEnter(W.rows[1])
 assert(itemTip.visible and itemTip.lines[1]=='Client item '..W.rows[1].record.record.itemID)
 W.rows[1].OnLeave(W.rows[1]);assert(not itemTip.visible)
 GameTooltip=savedTooltip
 end
 W.bossButton.OnClick()
 assert(W.root:IsShown() and ForeverCompanionBossGuideWorkspace.root:IsShown() and ForeverCompanionBossGuideWorkspace.boss==W.current.record.boss,'gear source opens the selected boss guide and keeps Gear Finder open')
 ForeverCompanionBossGuideWorkspace.root:Hide()

 local before=W.current.delta
 W.tabs.weights.OnClick();W.weightBoxes[1]:SetText('3');W.weightBoxes[1].OnEnterPressed(W.weightBoxes[1]);assert(G.Settings().weights[1]==3)
 W.weightBoxes[1]:SetText('nan');W.weightBoxes[1].OnEnterPressed(W.weightBoxes[1]);assert(G.Settings().weights[1]==3,'invalid input preserves prior weight')
 W.weightName:SetText('Sample melee');G.SaveProfile(1,W.weightName:GetText());G.Preset('Caster');assert(G.LoadProfile(1))
 W.Refresh();exportNative('ui_gear_weights_364_native.json')
 W.tabs.discover.OnClick();W.Select(997002);assert(W.current.delta>before,'stat edit changes real comparison')
 owned[997001]=1;H.events.OnEvent(H.events,'BAG_UPDATE_DELAYED');H.events.OnUpdate(H.events,.2);assert(G.Settings().completed['997001'].observed and H.toast:IsShown() and not H.tracker:IsShown())
 pump(.2);W.tabs.completed.OnClick();assert(#W.results==1 and W.current.record.itemID==997001)
 exportNative('ui_gear_acquired_364_native.json');exportNative('ui_gear_toast_364_native.json')
 H.toast.OnUpdate(H.toast,7.75);assert(H.toast.alpha and H.toast.alpha>0 and H.toast.alpha<1,'acquisition notice fades near dismissal')
 H.toast.OnUpdate(H.toast,9);assert(not H.toast:IsShown() and H.toast.alpha==1,'notice alpha reset for reuse');assert(#G.ObserveHunts()==0)
 local oldHead,oldAlt=CharacterHeadSlot,IsAltKeyDown
 CharacterHeadSlot=widget('Button');IsAltKeyDown=function() return true end;H.InstallHooks();H.InstallHooks()
 assert(#CharacterHeadSlot.hooks.OnMouseUp==1,'character shortcut hooks installed once')
 CharacterHeadSlot.hooks.OnMouseUp[1](CharacterHeadSlot,'RightButton');assert(G.Settings().slot==1 and W.view=='discover')
 CharacterHeadSlot,IsAltKeyDown=oldHead,oldAlt
 -- Every direct child button and row stays inside the window; sibling controls do not overlap.
 local function visible(f) if not f.visible then return false end;return not f.parent or visible(frames[f.parent]) end
 local function bounds(f)
  local p=f.point;if not p or p[1]~='TOPLEFT' or type(p[2])~='number' then return end
  return {x=p[2],y=-p[3],w=f.width,h=f.height}
 end
 for _,view in ipairs({'discover','hunts','completed','weights'}) do
  W.view=view;W.Refresh();local controls={}
  for _,f in ipairs(frames) do if f.parent==W.root.id and f.kind=='Button' and visible(f) then local r=bounds(f);if r then assert(r.x>=0 and r.y>=0 and r.x+r.w<=1080 and r.y+r.h<=760,'gear control outside root');controls[#controls+1]=r end end end
  for i,a in ipairs(controls) do for j=i+1,#controls do local b=controls[j];assert(not(a.x<b.x+b.w and b.x<a.x+a.w and a.y<b.y+b.h and b.y<a.y+a.h),'overlapping root controls') end end
 end
 local originalStats=C_Item.GetItemStats
 local subset={};for i=1,6 do subset[i]=records[i] end;ForeverCompanionLoot.records=subset
 C_Item.GetItemStats=function(link)
  if link==997006 then return {} end
  return {ITEM_MOD_STRENGTH_SHORT=link=='equipped' and 5 or link==997004 and 5 or link==997005 and 2 or 15}
 end
 G.Settings().slot=0;G.Settings().bestNow=false;G.Settings().ready=false;G.Settings().dungeon=''
 owned[997003]=1;W.view='discover';W.search:SetText('');W.offset=0;W.selected=997005;W.Refresh()
 local states={};for _,r in ipairs(W.rows) do if r.record then states[r.state:GetText():match(' · (.+)$') or r.state:GetText()]=true end end
 assert(states.ACQUIRED and states.OWNED and states.HIGHER and states.LOWER and states.EQUAL and states['MANUAL REVIEW'],'color states retain explicit readable labels')
 exportNative('ui_gear_states_364_native.json')
 W.tabs.weights.OnClick();W.root:Hide();W.Open();W.view='discover';W.Refresh()
 C_Item.GetItemStats=originalStats;ForeverCompanionLoot.records=records
 local beforeEvents=G.metrics.builds
 for i=1,10 do H.events.OnEvent(H.events,'PLAYER_EQUIPMENT_CHANGED') end
 H.events.OnUpdate(H.events,.05);pump(.02);assert(G.metrics.builds==beforeEvents+1,'equipment burst coalesces to one scan')
 pump(.1);assert(not H.events.OnUpdate and not W.root.OnUpdate,'no idle worker after an event burst and queued loads finish')
 W.root:Hide();local calls=scanCount;W.Refresh();assert(scanCount==calls,'hidden gear window does not scan items')
 C_Item=nil;H.events.OnEvent(H.events,'BAG_UPDATE_DELAYED');H.events.OnUpdate(H.events,.2);assert(#G.ObserveHunts()==0)
 C_Item,GetInventoryItemLink,ForeverCompanionLoot.records,ForeverCompanionDB.gearFinder,C_PlayerInfo=oldAPI,oldInventory,oldRecords,oldSaved,oldPlayerInfo
 ForeverCompanionLoot.gearSources=ForeverCompanionLoot.testGearSources;ForeverCompanionLoot.testGearSources=nil
 io.write('PASS: gear UI all-slot browsing, sources, filters, profiles, batched loads, acquisition toast, shortcuts, preserved scaling, bounds and hidden idle behavior\n')
end)()

-- Native face state transitions use the client's known panel-button sheets.
do
 local button=ForeverCompanionInterface.Button(UIParent)
 local function fire(event) for _,hook in ipairs(button.hooks[event] or {}) do hook(button) end end
 local face
 for _,widget in ipairs(frames) do
  if widget.parent==button.id and widget.texture=='Interface\\Buttons\\UI-Panel-Button-Up' then face=widget end
 end
 assert(face,'native button face missing')
 fire('OnMouseDown');assert(face.texture:find('Button-Down',1,true),'pressed face missing')
 fire('OnMouseUp');assert(face.texture:find('Button-Up',1,true),'released face missing')
 button:SetEnabled(false);fire('OnDisable')
 assert(face.texture:find('Button-Disabled',1,true),'disabled face missing')
 fire('OnMouseDown');assert(face.texture:find('Button-Disabled',1,true),'disabled press changed face')
 button:SetEnabled(true);fire('OnEnable')
 assert(face.texture:find('Button-Up',1,true),'reenabled face missing')
 button:Hide()
 print('PASS: Blizzard panel-button pressed, released, disabled and reenabled artwork states')
end

-- Quest, Hunter, gathering and common pop-out controls use the actual manifest UI.
do
 local W,H=ForeverCompanionHunterWorkspace,ForeverCompanionHunterGuide
 local oldArea=C_Map.GetAreaInfo;C_Map.GetAreaInfo=function(id) return ({[215]='Mulgore',[12]='Elwynn Forest',[3]='Badlands'})[id] or ('Area '..id) end
 W.view='beasts';W.options={query='The Rake',family='',role=''};W.Open()
 assert(#W.results==1 and W.selected.id==5807 and W.root.fcResizeGrip and W.root.fcTitleDrag)
 assert(W.detailTitle.parent==W.detail.id and W.detailBody.parent==W.detail.id,'Hunter detail text must belong to its backing frame, never sit behind an opaque child')
 exportNative('ui_hunter_beast_367_native.json')
 W.actions[2].OnClick(W.actions[2]);assert(H.Settings().favorites['5807'])
 W.tabs.families.OnClick();W.options.query='Cat';W.Refresh();assert(#W.results==1 and not W.familyButton:IsEnabled() and not W.roleButton:IsEnabled() and not W.nextPage:IsEnabled(),'irrelevant filters and exhausted pagination are disabled')
 exportNative('ui_hunter_family_367_native.json')
 W.actions[1].OnClick(W.actions[1]);assert(W.view=='beasts' and W.options.family=='Cat')
 W.options={query='Bite',family='',role=''};W.tabs.abilities.OnClick();assert(#W.results==1)
 W.actions[3].OnClick(W.actions[3]);assert(W.rank==2)
 exportNative('ui_hunter_skill_367_native.json')
 W.actions[1].OnClick(W.actions[1]);assert(W.view=='beasts' and W.options.ability=='bite' and W.options.rank==2)
 for _,entry in ipairs(W.results) do local found=false;for _,a in ipairs(H.Abilities(entry.id)) do if a.key=='bite' and a.rank.rank==2 then found=true end end;assert(found) end
 local oldPetRead=H.LivePet;H.LivePet=function() return {name='SAMPLE: My companion',family='Cat',level=20,health=400,maximum=500,armor=800,low=30,high=50,speed=1.2,dps=33.33,actions={'Bite','Growl'}} end
 W.tabs.pet.OnClick();W.actions[1].OnClick(W.actions[1]);W.actions[2].OnClick(W.actions[2]);assert(W.showSnapshot and H.Settings().snapshots[1].name=='SAMPLE: My companion')
 assert(#W.results==2 and W.rows[1]:IsShown() and W.rows[2]:IsShown(),'companion journal shows live and saved entries')
 W.rows[1].OnClick(W.rows[1]);assert(not W.showSnapshot,'live companion selected from list')
 W.rows[2].OnClick(W.rows[2]);assert(W.showSnapshot and W.snapshotIndex==1,'saved companion selected from list')
 exportNative('ui_hunter_pet_367_native.json')
 local snapshot=H.Settings().snapshots[1]
 for i=2,10 do local copy={};for k,v in pairs(snapshot) do copy[k]=v end;copy.name='SAMPLE: Snapshot '..i;H.Settings().snapshots[i]=copy end
 W.Refresh();assert(W.nextPage:IsEnabled());W.nextPage.OnClick();assert(W.page==2 and not W.nextPage:IsEnabled() and W.previous:IsEnabled())
 W.rows[1].OnClick(W.rows[1]);assert(W.showSnapshot and W.snapshotIndex==8,'later snapshots can be selected without cycling every pet')
 H.Settings().snapshots={};W.Refresh();assert(W.detailInfo:GetText():find('No saved pet snapshot',1,true),'an empty snapshot view must not show live stats as saved');W.showSnapshot=false;H.LivePet=oldPetRead
 local oldCursor,oldWidth,oldHeight=GetCursorPosition,UIParent:GetWidth(),UIParent:GetHeight();local cx,cy=100,100
 GetCursorPosition=function() return cx,cy end;UIParent:SetSize(1600,1000)
 W.root.fcResizeGrip.OnMouseDown(W.root.fcResizeGrip,'LeftButton');assert(W.root.fcResizeGrip.OnUpdate)
 cx,cy=220,40;W.root.fcResizeGrip.OnUpdate();assert(W.root.scale>1 and ForeverCompanionDB.windowLayouts.ForeverCompanionHunterFieldGuide.scale>1)
 W.root.fcResizeGrip.OnMouseUp();assert(not W.root.fcResizeGrip.OnUpdate)
 W.root.fcResizeGrip.OnClick(W.root.fcResizeGrip,'RightButton');assert(W.root.scale==1)
 W.root:Hide();UIParent:SetSize(oldWidth,oldHeight);GetCursorPosition=oldCursor;C_Map.GetAreaInfo=oldArea
 local p=ForeverCompanionQuestPlanner;local oldLive,oldSelected,oldSupported=p.GetLive,p.GetSelected,p.IsSupported
 local a={id=998501,title='SAMPLE: Gather the supplies',zone='Sample valley',zoneKnown=true,level=15,objectives={'Gather supplies: 2/5'},objectiveStates={{known=true,current=2,required=5}}}
 local b={id=998502,title='SAMPLE: Return to camp',zone='Sample camp',zoneKnown=true,level=15,complete=true,objectives={}}
 p.GetLive=function() return {a,b} end;p.GetSelected=function() return a,1 end;p.IsSupported=function() return true end
 local oldTracker=ForeverCompanionDB.questTracker;ForeverCompanionDB.questTracker={grouped=true,mode='all'}
 ForeverCompanionQuestJourney.Settings().collapsedZones={};ForeverCompanionQuestTracker.Show()
 local tracker;for _,f in ipairs(frames) do if f.name=='ForeverCompanionQuestTrackerFrame' then tracker=f end end
 local header;for _,f in ipairs(frames) do if f.parent==tracker.id and f.zoneGroup and f.zoneGroup.zone=='Sample valley' then header=f end end
 assert(header and header.height==30 and not header.map.visible)
 exportNative('ui_quest_zones_367_native.json')
 header.OnClick(header,'LeftButton');assert(ForeverCompanionQuestJourney.Settings().collapsedZones['Sample valley'])
 ForeverCompanionQuestJourney.Show(a);exportNative('ui_quest_intelligence_367_native.json')
 local trackerConfig=ForeverCompanionDB.questTracker
 ForeverCompanionQuestJourney.Settings().focus={id=a.id,title=a.title};trackerConfig.focusOnly=true;ForeverCompanionQuestTracker.Refresh();assert(trackerConfig.focusOnly)
 p.GetLive=function() return {b} end;ForeverCompanionQuestTracker.Refresh();assert(not trackerConfig.focusOnly,'stale focus no longer hides the entire quest log')
 trackerConfig.focusOnly=true;p.IsSupported=function() return false end;ForeverCompanionQuestTracker.Refresh();assert(trackerConfig.focusOnly,'cached scans cannot clear focus')
 ForeverCompanionQuestTracker.Hide();ForeverCompanionDB.questTracker=oldTracker;p.GetLive,p.GetSelected,p.IsSupported=oldLive,oldSelected,oldSupported
 local prof='Synthetic craft';local oldMaterials=ForeverCompanionDB.materials;local oldRecipes=ForeverCompanionDB.recipePlans
 ForeverCompanionCraftingPlanner.Add(prof,'SAMPLE: Ore',8,2);ForeverCompanionGatheringPlan.Open(prof)
 local A,S,L=ForeverCompanionGatheringPlan,ForeverCompanionMaterialSources,ForeverCompanionQuestLocations
 local oldProvider,oldForItem=L.Provider,S.ForItem;local syntheticProvider={Item={name=function(id) if id==998600 then return 'SAMPLE: Ore' end end}};L.Provider=function() return syntheticProvider end
 A.provider=syntheticProvider;A.signature=A.Signature(A.items);A.items[1].itemID=998600;A.message='SAMPLE: source references for layout verification'
 S.ForItem=function() return {{field='objectDrops',id=1,name='SAMPLE: Ore vein',kind='Gather / open object',points={{map=1429,x=.4,y=.5,zone='SAMPLE: Valley'}}},{field='vendors',id=2,name='SAMPLE: Trade supplier',kind='Vendor reference',points={{map=1453,x=.3,y=.7,zone='SAMPLE: Town'}}}} end
 A.Refresh();assert(not A.notice:GetText():find('Goals or provider changed',1,true),'successful reference refresh clears stale warnings')
 assert(A.OpenSelected(),'exact material handoff succeeds')
 local finder=ForeverCompanionMaterialFinder
 assert(not finder.OpenItem(998600,'Different ore') and not finder.OpenItem(998601,'SAMPLE: Ore'),'changed and missing identities cannot open sources')
 local sourceID;local existingForItem=S.ForItem;S.ForItem=function(id) sourceID=id;return existingForItem(id) end
 finder.Refresh();assert(sourceID==998600,'Material Finder preserves exact selected item ID')
 S.ForItem=existingForItem
 A.provider={};assert(not A.OpenSelected(),'stale gathering provider blocks exact source handoff');A.Refresh();assert(A.notice:GetText():find('Goals or provider changed',1,true))
 A.provider=syntheticProvider;A.Refresh();assert(not A.notice:GetText():find('Goals or provider changed',1,true))
 exportNative('ui_gathering_journal_367_native.json');L.Provider,S.ForItem=oldProvider,oldForItem

 ForeverCompanionDB.materials=oldMaterials;ForeverCompanionDB.recipePlans=oldRecipes
 local gear=ForeverCompanionGearFinderWorkspace;gear.Open();assert(gear.root.scale<=.84 and gear.root.fcResizeGrip)
 for _,r in ipairs(gear.results or {}) do if r.rank then assert(r.rank>=1 and r.rankCount>=r.rank) end end
 exportNative('ui_gear_ranked_367_native.json');gear.root:Hide()
 print('PASS: Hunter browsing/ability-source filters, favorites, native model fallback, persisted resize grip, quest zone collapse, intelligence and gathering UI')
end

-- Every profession guide is an actual native window over the extracted facts.
do
 local W,P=ForeverCompanionProfessionGuideWorkspace,ForeverCompanionProfessionLeveling
 local oldPlans,oldMaterials=ForeverCompanionDB.recipes,ForeverCompanionDB.materials
 ForeverCompanionDB.recipes={};ForeverCompanionDB.materials={}
 W.Open('Alchemy');assert(W.root:IsShown() and #W.plan.steps>0 and W.root.fcResizeGrip and W.root.fcTitleDrag)
 local selected=W.selected;W.ScrollTo(99999);assert(W.offset==#W.results-6 and W.selected==selected,'guide scrolling retains selected details')
 W.ScrollTo(0);W.addButton.OnClick();assert(#ForeverCompanionRecipePlans.Get('Alchemy')==1)
 W.tabs.shopping.OnClick();assert(#W.results==#W.plan.materials)
 local priorItemAPI=C_Item;C_Item={GetItemCount=function() return 5 end};W.stockButton.OnClick();assert(W.plan.stockBasis=='carried bags' and W.detailText:GetText():find('carried in bags',1,true),'bag snapshot basis is visible')
 exportNative('ui_profession_carried_371_native.json')
 C_Item=priorItemAPI;assert(W.Rebuild() and W.plan.stockBasis==nil,'guide rebuild deliberately restores manual stock')
exportNative('ui_profession_shopping_370_native.json')
 W.importButton.OnClick();assert(#ForeverCompanionCraftingPlanner.GetEntries('Alchemy')==#W.plan.materials)
 W.Open('Alchemy','recipes')
 assert(W.view=='recipes' and #W.results==#P.Catalog('Alchemy'),'recipe entry point opens the full catalog without a learned-recipe filter')
 W.search:SetText('Minor');W.search.OnTextChanged(W.search);assert(#W.results>0 and #W.results<#P.Catalog('Alchemy'))
 W.search:SetText('');W.search.OnTextChanged(W.search);W.tabs.route.OnClick()
 W.currentInput:SetText('150');W.targetInput:SetText('75');local previous=W.plan;assert(not W.Rebuild() and W.plan==previous,'invalid ranges preserve the current applied guide')
 W.currentInput:SetText('75');W.targetInput:SetText('150');assert(W.Rebuild() and W.plan.steps[1].from==75)
 exportNative('ui_profession_route_370_native.json')
 for _,name in ipairs(P.names) do W.Open(name);assert(W.profession==name and #W.plan.gaps==0 and W.plan.target==300 or name=='Alchemy' and W.plan.target==150) end
 W.Open('Fishing');assert(W.plan.gather and #W.plan.materials==0 and not W.importButton:IsEnabled());exportNative('ui_profession_fishing_370_native.json')
 W.root:Hide();ForeverCompanionDB.recipes=oldPlans;ForeverCompanionDB.materials=oldMaterials
 io.write('PASS: all twelve native profession guides, scrolling, recipe/shopping imports, recipe search, invalid-range retention and gathering quota disclosure\n')
end

-- Encounter detail uses native rows and published notes open deliberately.
do
 local E,W=ForeverCompanionEncounterBrowser,ForeverCompanionBossGuideWorkspace
 SlashCmdList.FOREVERCOMPANION('open dungeon journal');E.query='';E.questView=false
 local count=0
 for _,d in ipairs(ForeverCompanionDungeonCatalog.Names()) do
  E.SelectDungeon(d);ForeverCompanionRefresh();assert(#E.Results(d,'')>0 and E.guideButton:IsEnabled())
  E.guideButton.OnClick()
  local first=W.MechanicRows(d,E.boss)[1]
  assert(W.root:IsShown() and W.dungeon==d and W.rows[1].caption:GetText()==first)
  count=count+1
 end
 assert(count==34)
 W.Open('The Deadmines','Captain Greenskin')
 assert(W.root.fcResizeGrip and W.root.fcTitleDrag and W.rows[1].caption:GetText():find('Cleave',1,true))
 W.referenceButton.OnClick()
 local reference
 for _,frame in ipairs(frames) do if frame.name=='ForeverCompanionReferenceFrame' then reference=frame end end
 assert(reference and reference:IsShown())
 reference:Hide();exportNative('ui_boss_guide_372_native.json')
 W.Open('The Deadmines','Unknown boss');assert(W.rows[1].caption:GetText()=='Research pending' and not W.rows[2]:IsShown())
 W.root:Hide()
 E.Focus('Blackrock Depths','Emperor Dagran Thaurissan');ForeverCompanionRefresh();exportNative('ui_dungeon_catalog_373_native.json')
end

-- The shared frame keeps short encounter panels compact.
do
 local W,E=ForeverCompanionBossGuideWorkspace,ForeverCompanionEncounterBrowser
 W.Open('The Deadmines','Captain Greenskin')
 assert(W.root:GetHeight()<422 and W.root.fcResizeGrip)
 exportNative('ui_boss_guide_374_native.json');W.root:Hide()
 E.Focus('Blackrock Depths','Emperor Dagran Thaurissan')
 SlashCmdList.FOREVERCOMPANION('open dungeon journal');ForeverCompanionRefresh()
 exportNative('ui_dungeon_journal_374_native.json')
