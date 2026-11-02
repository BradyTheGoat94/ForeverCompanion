-- Offline mock of the WoW widget API; tests construction and render, not pixels.
local frames={}
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
local function widget(kind)
 local w={kind=kind,visible=true,children={},text="",id=#frames+1}
 function w:SetText(v) self.text=tostring(v or "") end
 function w:GetText() return self.text end
 function w:GetStringHeight() return math.max(16,math.ceil(#self.text/75)*16) end
 function w:Show() self.visible=true end
 function w:Hide() self.visible=false end
 function w:IsShown() return self.visible end
 function w:SetScript(name,fn) self[name]=fn end
 function w:RegisterEvent(name) self.events=self.events or {};self.events[name]=true end
 function w:CreateTexture() local child=widget("Texture");child.parent=self.id;return child end
 function w:CreateFontString() local child=widget("FontString");child.parent=self.id;return child end
 function w:SetColorTexture(...) self.color={...} end
 function w:SetTexture(v) self.texture=v end
 function w:SetPoint(...) self.point={...} end
 function w:SetSize(width,height) self.width=width;self.height=height end
 function w:SetHeight(height) self.height=height end
 function w:SetWidth(width) self.width=width end
 function w:GetWidth() return self.width end
 function w:GetHeight() return self.height end
 function w:SetScale(value) self.scale=value end
 function w:SetEnabled(value) self.enabled=value end
 function w:LockHighlight() end
 function w:UnlockHighlight() end
 function w:SetScrollChild(child) self.child=child end
 function w:GetVerticalScroll() return 0 end
 function w:SetVerticalScroll() end
 function w:StartMoving() end
 function w:StopMovingOrSizing() end
 function w:EnableMouse() end
 function w:RegisterForDrag() end
 function w:SetMovable() end
 function w:SetClampedToScreen() end
 function w:SetResizable() end
 function w:SetBackdrop(...) end
 function w:SetBackdropColor(...) end
 function w:SetBackdropBorderColor(...) end
 function w:SetAllPoints() end
 function w:SetJustifyH() end
 function w:SetJustifyV() end
 function w:SetSpacing() end
 function w:SetTextColor() end
 function w:SetFontObject() end
 function w:SetNormalTexture() end
 function w:SetHighlightTexture() end
 function w:SetPushedTexture() end
 function w:ClearAllPoints() end
 frames[#frames+1]=w
 return w
end
CreateFrame=function(kind,_,parent) local child=widget(kind);child.parent=parent and parent.id;return child end
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
 if f.events and f.events.ADDON_LOADED then addonFrame=f;break end
end
assert(addonFrame and addonFrame.OnEvent,"addon loaded handler missing")
addonFrame.OnEvent(addonFrame,"ADDON_LOADED",addon)
assert(#frames>50,"expected substantial UI frame tree")
assert(type(SlashCmdList.FOREVERCOMPANION)=="function","slash command missing")
SlashCmdList.FOREVERCOMPANION("class mage")
SlashCmdList.FOREVERCOMPANION("class auto")
SlashCmdList.FOREVERCOMPANION("role damage")
SlashCmdList.FOREVERCOMPANION("position reset")
SlashCmdList.FOREVERCOMPANION("open quests")
assert(ForeverCompanionDB.tab=="Quests","slash navigation must open quest guide")
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
assert(sourceLabel and sourceLabel.text:find("Professions: detected",1,true),"data source disclosure missing")
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
 if w.text=="JOURNAL AT A GLANCE" then questHeading=w end
 if w.text=="FOCUSED OBJECTIVE" then questFocusHeading=w end
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
for _,w in ipairs(frames) do if w.text=="Sort: zone" then sortControl=w end end
assert(sortControl and sortControl.OnClick,"quest sort selector missing")
sortControl.OnClick(sortControl) -- ready
assert(ForeverCompanionQuestPlanner.GetSort()=="ready","quest sort should persist readiness")
assert(ForeverCompanionQuestPlanner.GetVisible()[1].quest.complete,"ready quests must sort first")
sortControl.OnClick(sortControl) -- pinned
assert(ForeverCompanionQuestPlanner.GetSort()=="pinned","pinned sort mode should be available")
sortControl.OnClick(sortControl) -- log
assert(ForeverCompanionQuestPlanner.GetVisible()[1].quest.title=="Sample: Gather supplies","log order must be preserved")
sortControl.OnClick(sortControl) -- zone
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
assert(readyRow.title.text:find("[PIN]",1,true),"journal row should show pinned badge")
assert(ForeverCompanionQuestPlanner.Overview().pinned==1,"journal overview must count pinned quests")
local knownObjective=false
for _,w in ipairs(frames) do
 if w.text=="Known objectives: 1/1 | addon focus only" then knownObjective=true end
end
assert(knownObjective,"quest focus card should show verified objective progress")
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
local originalQuestCount=C_QuestLog.GetNumQuestLogEntries
C_QuestLog.GetNumQuestLogEntries=function() error("temporary quest API failure") end
assert(ForeverCompanionQuestPlanner.Sync()==false,"failed quest scan must not be reported successful")
local staleWarning=false
for _,w in ipairs(frames) do
 if w.text=="STALE DATA - verify in the game quest log" then staleWarning=true end
end
assert(staleWarning,"quest briefing must warn about cached data")
ForeverCompanionDashboard.Render()
assert(sourceLabel.text:find("CACHED - VERIFY IN GAME",1,true),"dashboard must disclose stale quest data")
C_QuestLog.GetNumQuestLogEntries=originalQuestCount
assert(ForeverCompanionQuestPlanner.Sync(),"quest scanner should recover after transient error")
local bannerText
for _,w in ipairs(frames) do if w.text=="WELCOME TO FOREVER COMPANION" then bannerText=w end end
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
local materialStatus=false
for _,w in ipairs(frames) do if w.text=="0/1 material goals completed" then materialStatus=true end end
assert(materialStatus,"manual material goal status incorrect")
ForeverCompanionProfessionBriefing.Render("Blacksmithing")
local shortageFound=false
for _,w in ipairs(frames) do
 if w.text=="Selected guide shortage: Sample Ore x6" then shortageFound=true end
end
assert(shortageFound,"selected profession should show its largest manual shortage")
ForeverCompanionProfessionBriefing.Render("Alchemy")
exportSnapshot("ui_profession_snapshot.txt")
assert(ForeverCompanionCraftingPlanner.SetOwned("Blacksmithing",1,10),"material goal should update")
ForeverCompanionProfessionBriefing.Render("Blacksmithing")
local completedStatus=false
for _,w in ipairs(frames) do if w.text=="1/1 material goals completed" then completedStatus=true end end
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
 if w.text=="Compact" then compactButton=w end
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
local focusTitle
for _,w in ipairs(frames) do if w.text=="TODAY\'S FOCUS" then focusTitle=w end end
assert(focusTitle and frames[focusTitle.parent].visible==false,"compact mode should hide lower focus panel")
compactButton.OnClick(compactButton)
assert(mainWindow.height==720 and not ForeverCompanionDB.compact,"expand layout failed")
assert(frames[focusTitle.parent].visible==true,"expanded mode should restore lower focus panel")
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
 if f.text=="Forever Companion" then foundTitle=true end
end
assert(foundTitle,"main window title not rendered")
local foundBanner=false
for _,f in ipairs(frames) do if f.text=="WELCOME TO FOREVER COMPANION" then foundBanner=true end end
assert(foundBanner,"premium dashboard welcome banner missing")
local heraldicMarks=0
for _,w in ipairs(frames) do
 if w.kind=="FontString" and w.text=="FC" then heraldicMarks=heraldicMarks+1 end
end
assert(heraldicMarks>=2,"header and dashboard must use the same original heraldic crest")
-- Exercise the native class-guide hero and capture its real mock widget tree.
local levelingButton
for _,w in ipairs(frames) do if w.section=="Leveling" then levelingButton=w end end
assert(levelingButton and levelingButton.OnClick,"leveling sidebar navigation missing")
levelingButton.OnClick(levelingButton)
assert(ForeverCompanionDB.tab=="Leveling","leveling navigation failed")
local classHeading,buildHeading,rotationControl
for _,w in ipairs(frames) do
 if w.text=="CHARACTER & LEVELING" then classHeading=w end
 if w.text=="BUILD & ROTATION REFERENCE" then buildHeading=w end
 if w.text=="Rotation: leveling" then rotationControl=w end
end
assert(classHeading and buildHeading,"native class-guide header cards missing")
local levelBandFound=false
for _,w in ipairs(frames) do
 if w.text=="Leveling phase: Endgame preparation (50-60)" then levelBandFound=true end
end
assert(levelBandFound,"leveling hero should show the current level band")
assert(frames[classHeading.parent].visible,"class-guide header should be visible on Leveling")
assert(rotationControl and rotationControl.point and rotationControl.point[1]=="TOPLEFT","rotation control should be in content area")
local levelingHeading
for _,w in ipairs(frames) do if w.text=="LEVELING GUIDE" then levelingHeading=w end end
assert(levelingHeading and frames[levelingHeading.parent].visible,"section header should appear on Leveling")
local priorityTile, priorityNumber
for _,w in ipairs(frames) do
 if w.kind=="Button" and w.width==122 and w.height==78 and w.label and w.label.text~="" then
   priorityTile=w
   if w.number and w.number.text=="1" then priorityNumber=w.number end
 end
end
assert(priorityTile and priorityNumber,"six-slot rotation strip should display numbered ability tiles")
-- All nine class-preview buttons must be interactive, and must not mutate the player.
local savedPreviewRole=ForeverCompanionDB.role
local classTokens={"WARRIOR","PALADIN","HUNTER","ROGUE","PRIEST","SHAMAN","MAGE","WARLOCK","DRUID"}
assert(ForeverCompanionClassStripButtons and #ForeverCompanionClassStripButtons==9,"class strip must offer all nine classes")
for i,token in ipairs(classTokens) do
 local button=ForeverCompanionClassStripButtons[i]
 assert(button.classToken==token and button.OnClick and button.visible,"class strip button missing or hidden")
 button.OnClick(button)
 assert(ForeverCompanionDB.previewClass==token,"class selector did not update addon preview")
end
ForeverCompanionClassStripButtons[1].OnClick(ForeverCompanionClassStripButtons[1])
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
rotationControl.OnClick(rotationControl)
assert(rotationControl.text=="Rotation: dungeon","rotation context selector failed")
overviewButton.OnClick(overviewButton)
assert(not frames[levelingHeading.parent].visible,"section header should hide on dashboard")
assert(not frames[frames[classHeading.parent].parent].visible,"class guide should hide outside Leveling")
mockXP=2000
addonFrame.OnEvent(addonFrame,"PLAYER_XP_UPDATE")
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
overviewButton.OnClick(overviewButton)
assert(not frames[frames[settingsHeading.parent].parent].visible,"Settings cards must hide on dashboard")
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
