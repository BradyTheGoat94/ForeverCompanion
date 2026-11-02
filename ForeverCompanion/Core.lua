local addonName = ...
local addon = CreateFrame("Frame")
local DATA = ForeverCompanionData
local ADVANCED = ForeverCompanionAdvanced
local ROTATIONS = ForeverCompanionRotations
local rotationModes={"leveling","dungeon","boss","aoe","pvp"}
local rotationMode=1
local rotationButton, rotationIcon, rotationDescription, specButton
local rotationRows={}
local rotationDetail=1
local DB, window, titleText, content, currentTab, headerMeta
local tabs = {"Overview", "Leveling", "Quests", "Dungeons", "Professions", "PvP", "Settings"}
local classNames = {WARRIOR="Warrior", PALADIN="Paladin", HUNTER="Hunter", ROGUE="Rogue", PRIEST="Priest", SHAMAN="Shaman", MAGE="Mage", WARLOCK="Warlock", DRUID="Druid"}
local classRoles = {WARRIOR={"Tank","Damage"}, PALADIN={"Tank","Damage","Healer"}, HUNTER={"Damage"}, ROGUE={"Damage"}, PRIEST={"Healer","Damage"}, SHAMAN={"Healer","Damage"}, MAGE={"Damage"}, WARLOCK={"Damage"}, DRUID={"Tank","Damage","Healer"}}
local tabButtons = {}
ForeverCompanionClassStripButtons={}
local checkButtons = {}
local scrollFrame, scrollChild, classButton, roleButton, subtitleText, questCountText, compactButton, accentBar, background, nextQuestButton, previousQuestButton, questFocusText, welcomeTip
local handbookIcon, handbookButtons={}, {}
local materialRows={}
local materialPage=1
local materialPageLabel, materialPrevious, materialNext
local professionIndex=1
local questRows = {}
local questPage=1
local pageBack, pageForward, pageLabel, filterButton, sortButton, resetClassButton
local questSectionLabel
local sectionHeader, sectionTitle, sectionMeta, sectionIcon
local sectionDescriptions={
  Leveling="Class priorities, specialization reference and leveling notes",
  Quests="Read-only quest journal, objectives and personal notes",
  Dungeons="Party preparation, role checklists and general guidance",
  Professions="Skill progression, recipes and manual material goals",
  PvP="Preparation, positioning and class reference",
  Settings="Preferences, diagnostics and client compatibility"
}
local sectionIcons={
  Leveling="Interface\\Icons\\INV_Misc_Book_09",
  Quests="Interface\\Icons\\INV_Misc_Note_01",
  Dungeons="Interface\\Icons\\INV_Weapon_ShortBlade_01",
  Professions="Interface\\Icons\\Trade_BlackSmithing",
  PvP="Interface\\Icons\\Ability_DualWield",
  Settings="Interface\\Icons\\INV_Gizmo_02"
}
local classOrder = {"WARRIOR","PALADIN","HUNTER","ROGUE","PRIEST","SHAMAN","MAGE","WARLOCK","DRUID"}
local function colorTexture(texture,r,g,b,a)
  if texture.SetColorTexture then texture:SetColorTexture(r,g,b,a)
  else texture:SetTexture(r,g,b,a) end
end
local function say(msg) print("|cffffcc66Forever Companion:|r "..msg) end
local function clipText(value,limit)
  local text=tostring(value or ""):gsub("[\r\n]"," ")
  if #text>limit then return text:sub(1,limit-3).."..." end
  return text
end
local function actualClass()
  if type(UnitClass)~="function" then return "UNKNOWN" end
  local ok,token=pcall(function()
    local _,class=UnitClass("player")
    if type(class)=="string" and classNames[class] then return class end
  end)
  return ok and token or "UNKNOWN"
end
local function classToken()
  if DB and type(DB.previewClass)=="string" and classNames[DB.previewClass] then return DB.previewClass end
  return actualClass()
end
local function classLabel() return classNames[classToken()] or "Unknown class" end
local function safeNumber(fn,...)
  if type(fn)~="function" then return nil end
  local ok,value=pcall(fn,...)
  if not ok then return nil end
  local converted,number=pcall(tonumber,value)
  if converted and type(number)=="number" then return number end
end
local function level()
  local value=safeNumber(UnitLevel,"player")
  if value and value>=1 and value<=1000 then return value end
end
local function experienceText()
  local value=safeNumber(UnitXP,"player")
  local maximum=safeNumber(UnitXPMax,"player")
  if not value or not maximum or maximum<=0 then return "XP: unavailable on this client or level" end
  local ok,answer=pcall(function()
    return "XP: "..value.." / "..maximum.." ("..math.floor(value*100/maximum+0.5).."%)"
  end)
  return ok and answer or "XP: unavailable on this client or level"
end
local function toggleCheck(section, index)
  if not DATA.checklist[section] then return end
  DB.checks = DB.checks or {}
  DB.checks[section] = DB.checks[section] or {}
  DB.checks[section][index] = not DB.checks[section][index]
end
-- Keep the large render function below Lua 5.1's 60-upvalue limit.
function ForeverCompanionClassStripRender(tab,selectedToken)
  for _,button in ipairs(ForeverCompanionClassStripButtons) do
    if tab=="Leveling" then
      button:Show()
      local active=button.classToken==selectedToken
      colorTexture(button.bg,active and 0.12 or 0.045,active and 0.23 or 0.07,active and 0.38 or 0.11,1)
      colorTexture(button.trim,active and 0.98 or 0.44,active and 0.74 or 0.34,active and 0.31 or 0.18,1)
    else button:Hide() end
  end
end
local function render()
  if not window or not DB then return end
  titleText:SetText("Forever Companion")
  if headerMeta then headerMeta:SetText(classLabel().."  |  Level "..tostring(level() or "?").."  |  "..(DB.role or "Choose role")) end
  if questCountText and ForeverCompanionQuestPlanner then
    local planner=ForeverCompanionQuestPlanner
    if planner.IsSupported() then
      questCountText:SetText("Active quests: "..planner.AutoCount())
    elseif planner.IsSnapshotStale() then
      questCountText:SetText("Cached quests: "..planner.AutoCount().." (outdated)")
    else
      questCountText:SetText("Quest API unavailable")
    end
  end
  local isOverview=currentTab=="Overview"
  if sectionHeader then
    if isOverview then sectionHeader:Hide()
    else
      sectionTitle:SetText(string.upper(currentTab).." GUIDE")
      sectionMeta:SetText(sectionDescriptions[currentTab] or "Reference guide")
      sectionIcon:SetTexture(sectionIcons[currentTab] or "Interface\\Icons\\INV_Misc_Book_09")
      sectionHeader:Show()
    end
  end
  if scrollFrame then
    if isOverview then scrollFrame:Hide() else scrollFrame:Show() end
    scrollFrame:ClearAllPoints()
    scrollFrame:SetPoint("TOPLEFT",216,-163)
    scrollFrame:SetPoint("BOTTOMRIGHT",-35,currentTab=="Leveling" and 125 or 92)
  end
  if ForeverCompanionClassGuide then
    ForeverCompanionClassGuide.Show(currentTab=="Leveling")
    if currentTab=="Leveling" then ForeverCompanionClassGuide.Render(classToken(),classLabel(),level(),DB.role,rotationModes[rotationMode]) end
  end
  if ForeverCompanionQuestBriefing then ForeverCompanionQuestBriefing.Show(currentTab=="Quests") end
  if ForeverCompanionProfessionBriefing then
    ForeverCompanionProfessionBriefing.Show(currentTab=="Professions")
    if currentTab=="Professions" then
      local selected=DATA.professionHandbook and DATA.professionHandbook[professionIndex]
      ForeverCompanionProfessionBriefing.Render(selected and selected.name)
    end
  end
  if ForeverCompanionAdventureBriefing then
    ForeverCompanionAdventureBriefing.Show(currentTab)
  end
  if ForeverCompanionSettingsBriefing then ForeverCompanionSettingsBriefing.Show(currentTab=="Settings") end
  if ForeverCompanionDashboard then
    ForeverCompanionDashboard.SetCompact(DB.compact)
    ForeverCompanionDashboard.Show(isOverview)
  end
  ForeverCompanionClassStripRender(currentTab,classToken())
  for _, b in ipairs(tabButtons) do
    if b.section == currentTab then
      colorTexture(b.navBackground,0.045,0.16,0.37,1)
      if b.navGlow then colorTexture(b.navGlow,0.10,0.29,0.68,0.65) end
      colorTexture(b.navAccent,0.98,0.74,0.29,1)
      b.navLabel:SetTextColor(1,0.83,0.43)
    else
      colorTexture(b.navBackground,0.050,0.067,0.100,1)
      if b.navGlow then colorTexture(b.navGlow,0.08,0.18,0.36,0) end
      colorTexture(b.navAccent,0.52,0.39,0.19,1)
      b.navLabel:SetTextColor(0.88,0.87,0.83)
    end
  end
  for _, b in ipairs(checkButtons) do b:Hide() end
  if handbookIcon then handbookIcon:Hide() end
  if rotationIcon then rotationIcon:Hide() end
  for _,row in ipairs(rotationRows) do row:Hide() end
  if rotationButton then if currentTab=="Leveling" then rotationButton:Show(); rotationButton:SetText("Rotation: "..rotationModes[rotationMode]) else rotationButton:Hide() end end
  if specButton then
    if currentTab=="Leveling" and ForeverCompanionSpecPlanner then
      local selected=ForeverCompanionSpecPlanner.Get(classToken())
      specButton:SetText("Spec: "..(selected and selected[1] or "N/A"))
      specButton:Show()
    else specButton:Hide() end
  end
  for _,b in ipairs(handbookButtons) do b:Hide() end
  for _,entry in ipairs(materialRows) do entry.label:Hide(); entry.minus:Hide(); entry.plus:Hide() end
  if materialPageLabel then materialPageLabel:Hide(); materialPrevious:Hide(); materialNext:Hide() end
  for _, b in ipairs(questRows) do b:Hide() end
  if questSectionLabel then questSectionLabel:Hide() end
  if filterButton then if currentTab=="Quests" then filterButton:Show() else filterButton:Hide() end end
  if questRows.pinControl then
    if currentTab=="Quests" then
      local focused=ForeverCompanionQuestPlanner.GetSelected()
      questRows.pinControl:SetText(focused and (ForeverCompanionQuestPlanner.IsPinned(focused) and "Unpin Focus" or "Pin Focus") or "No Focus")
      questRows.pinControl:SetEnabled(focused~=nil)
      questRows.pinControl:Show()
    else questRows.pinControl:Hide() end
  end
  if sortButton then
    if currentTab=="Quests" then
      sortButton:SetText("Sort: "..ForeverCompanionQuestPlanner.GetSort())
      sortButton:Show()
    else sortButton:Hide() end
  end
  local lines = {}
  if currentTab == "Overview" then
    lines = {"YOUR ADVENTURE AT A GLANCE", "Recommended next steps", "1. Review your current quests in the Quest Planner.", "2. Open Leveling for class-specific ability priorities.", "3. Track crafting materials and profession goals.", "All suggestions are advisory. You remain in control."}
    if ForeverCompanionCraftingPlanner then lines[#lines+1]=ForeverCompanionCraftingPlanner.Summary() end
    if ForeverCompanionDiagnostics then lines[#lines+1]=ForeverCompanionDiagnostics.Collect() end
  elseif currentTab == "Leveling" then
    lines = {"CLASS GUIDANCE",experienceText()}
    local rotations=ROTATIONS and ROTATIONS[classToken()]
    if rotations then
      local mode=rotationModes[rotationMode]
      lines[#lines+1]="ROTATION / PRIORITY: "..string.upper(mode)
      local presentation=ForeverCompanionRotationPresentation
      local context=presentation and presentation.contexts[mode]
      if context then lines[#lines+1]=context.title.." - "..context.description end
      local icons=ForeverCompanionRotationIcons and ForeverCompanionRotationIcons[classToken()]
      if rotationIcon and icons and icons[1] then rotationIcon:SetTexture(icons[1]); rotationIcon:Show() end
      local priorities=rotations[mode] or {}
      if rotationDetail>#priorities then rotationDetail=1 end
      for i,ability in ipairs(priorities) do
        lines[#lines+1]=i..". "..ability
        local row=rotationRows[i]
        if row then
          local short=tostring(ability)
          if #short>38 then short=short:sub(1,35).."..." end
          row.label:SetText(short)
          colorTexture(row.bg,rotationDetail==i and 0.23 or 0.105,rotationDetail==i and 0.19 or 0.13,rotationDetail==i and 0.12 or 0.18,1)
          colorTexture(row.trim,rotationDetail==i and 0.99 or 0.45,rotationDetail==i and 0.76 or 0.36,rotationDetail==i and 0.32 or 0.20,1)
          row.detail=ability
          row:SetScript("OnEnter",function(self)
            if GameTooltip then
              GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
              GameTooltip:SetText("Priority "..i,1,0.8,0.3)
              GameTooltip:AddLine(self.detail or "",1,1,1,true)
              GameTooltip:Show()
            end
          end)
          row:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
          local iconList=ForeverCompanionRotationIcons and ForeverCompanionRotationIcons[classToken()]
          if row.icon and iconList and #iconList>0 then row.icon:SetTexture(iconList[((i-1)%#iconList)+1]) end
          row:SetScript("OnClick",function() rotationDetail=i; render() end)
          row:Show()
        end
      end
      if ForeverCompanionAvailableAbilitySummary then
        lines[#lines+1]=ForeverCompanionAvailableAbilitySummary(classToken(),level())
      end
      if ForeverCompanionAbilityReferenceLines then
        for _,referenceLine in ipairs(ForeverCompanionAbilityReferenceLines(classToken(),level())) do
          lines[#lines+1]=referenceLine
        end
      end
      if ForeverCompanionLevelingCurriculum then lines[#lines+1]=ForeverCompanionLevelingCurriculum.Format(classToken(),level()) end
      if ForeverCompanionWorldGuide then lines[#lines+1]=ForeverCompanionWorldGuide.Format(level()) end
      if ForeverCompanionClassChanges then lines[#lines+1]=ForeverCompanionClassChanges.Format(classToken(),level()) end
      if ForeverCompanionSkillStudy then lines[#lines+1]=ForeverCompanionSkillStudy.Format(classToken(),level())
        lines[#lines+1]=ForeverCompanionSkillStudy.FormatNextActions(classToken(),level())
        lines[#lines+1]=ForeverCompanionSkillStudy.PracticePlan(classToken(),level()) end
      if ForeverCompanionSkillDiscovery then
        lines[#lines+1]=ForeverCompanionSkillDiscovery.FormatSummary(classToken())
        lines[#lines+1]=ForeverCompanionSkillDiscovery.Format(classToken())
        lines[#lines+1]=ForeverCompanionSkillDiscovery.FormatChecklist(classToken()) end
      local specNotes=ForeverCompanionSpecGuidance and ForeverCompanionSpecGuidance[classToken()]
      if specNotes then
        lines[#lines+1]="SPECIALIZATION STUDY NOTES (illustrative, check your talents)"
        for _,note in ipairs(specNotes) do
          lines[#lines+1]=note.name.." | "..note.focus
          lines[#lines+1]="Level / unlock check: "..note.levels
          lines[#lines+1]="Solo: "..note.solo
          lines[#lines+1]="Group: "..note.group
        end
      end
      if priorities[rotationDetail] then
        lines[#lines+1]="FOCUSED PRIORITY "..rotationDetail.." / "..#priorities..": "..priorities[rotationDetail]
        lines[#lines+1]="WHY THIS MATTERS: This is a decision reminder, not a fixed cast sequence. Check your talents, resources, target count, threat, and the live encounter before acting."
        lines[#lines+1]="WHEN TO ADJUST: If the listed ability is unavailable, unsafe, or inappropriate for your role, skip it and continue with the next relevant priority."
        lines[#lines+1]="ROTATION STATUS: Illustrative Classic-era guidance; not yet validated against live WoW Forever combat mechanics."
      end
      if ForeverCompanionFormatCooldowns then
        lines[#lines+1]=ForeverCompanionFormatCooldowns(classToken(),mode)
      end
      if ForeverCompanionSpecPlanner then lines[#lines+1]=ForeverCompanionSpecPlanner.Format(classToken(),mode) end
      if ForeverCompanionSpellbook then lines[#lines+1]=ForeverCompanionSpellbook.Cooldowns(classToken()) end
      lines[#lines+1]="General reference only; verify abilities and talents on Forever."
    end
    local guide=DATA.classHandbook and DATA.classHandbook[classToken()]
    if guide then
      lines[#lines+1]="LEVELING: "..guide.leveling
      lines[#lines+1]="DUNGEON: "..guide.dungeon
      lines[#lines+1]="PVP: "..guide.pvp
      lines[#lines+1]="PROFESSIONS: "..guide.professions
      if handbookIcon then handbookIcon:SetTexture(guide.icon); handbookIcon:Show() end
    end
    for _, tip in ipairs(DATA.classes[classToken()] or {}) do lines[#lines+1] = "- "..tip end
    local deep=ADVANCED and ADVANCED.classes[classToken()]
    if deep then
      lines[#lines+1]="SPECIALIZATION OVERVIEW (GENERAL REFERENCE)"
      lines[#lines+1]=table.concat(deep.specializations," / ")
      lines[#lines+1]="Core: "..deep.core
      lines[#lines+1]="Party: "..deep.party
      for _,tip in ipairs(deep.sections) do lines[#lines+1]="- "..tip end
    end
    if DB.role and DATA.roleAdvice and DATA.roleAdvice[DB.role] then
      lines[#lines+1]="YOUR ROLE: "..string.upper(DB.role)
      for _,tip in ipairs(DATA.roleAdvice[DB.role]) do lines[#lines+1]="- "..tip end
    end
    lines[#lines+1] = "LEVELING"
    for _, band in ipairs(DATA.zones) do
      if (level() or 0) >= band[1] and (level() or 0) <= band[2] then
        lines[#lines+1] = "Level "..band[1].."-"..band[2]..": "..band[3]
        lines[#lines+1] = band[4]
        break
      end
    end
  elseif currentTab == "Quests" then
    local live=ForeverCompanionQuestPlanner.GetLive()
    local visible=ForeverCompanionQuestPlanner.GetVisible()
    local focused,selectedIndex=ForeverCompanionQuestPlanner.GetSelected()
    lines = {ForeverCompanionQuestPlanner.FormatOverview(), "", ForeverCompanionQuestPlanner.FormatFocused(), "", "NEXT STEP", ForeverCompanionQuestPlanner.Recommend(), "", "PERSONAL NOTES", ForeverCompanionQuestPlanner.Format()}
    if not ForeverCompanionQuestPlanner.IsSupported() then
      table.insert(lines,1,"Quest-log API unavailable: automatic tracking needs client verification.")
    end
    if questSectionLabel then
      questSectionLabel:SetText("QUEST LOG  |  "..#live.." active  |  "..ForeverCompanionQuestPlanner.ReadyCount().." ready  |  "..ForeverCompanionQuestPlanner.PinnedCount().." pinned")
      questSectionLabel:Show()
    end
    if filterButton then filterButton:SetText("Show: "..ForeverCompanionQuestPlanner.GetFilter()) end
    local pages=math.max(1,math.ceil(#visible/#questRows))
    if questPage>pages then questPage=pages end
    for i=1,math.min(#questRows,math.max(0,#visible-(questPage-1)*#questRows)) do
      local item=visible[(questPage-1)*#questRows+i]
      local absoluteIndex=item.index
      local q=item.quest
      local btn=questRows[i]
      local selected=selectedIndex==absoluteIndex
      btn.title:SetText((selected and "> " or "  ")..(ForeverCompanionQuestPlanner.IsPinned(q) and "[PIN] " or "")..clipText(q.title,47))
      btn.zone:SetText(clipText(q.zone or "Zone unavailable",23))
      btn.status:SetText(q.complete and "READY" or "ACTIVE")
      btn.status:SetTextColor(q.complete and 0.48 or 0.77,q.complete and 0.88 or 0.76,q.complete and 0.53 or 0.70)
      colorTexture(btn.bg,selected and 0.24 or 0.085,selected and 0.20 or 0.11,selected and 0.13 or 0.15,1)
      colorTexture(btn.trim,selected and 0.98 or 0.30,selected and 0.75 or 0.28,selected and 0.33 or 0.21,1)
      btn.selected=selected
      btn:SetScript("OnClick",function() ForeverCompanionQuestPlanner.Select(absoluteIndex) end)
      btn:SetScript("OnEnter",function(self)
        colorTexture(self.bg,0.20,0.18,0.14,1)
        if GameTooltip then
          GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
          GameTooltip:SetText(q.title or "Quest",1,0.8,0.3)
          if q.zone then GameTooltip:AddLine(q.zone,0.8,0.8,0.8) end
          for j=1,math.min(3,#(q.objectives or {})) do
            GameTooltip:AddLine(q.objectives[j],1,1,1,true)
          end
          GameTooltip:Show()
        end
      end)
      btn:SetScript("OnLeave",function(self)
        colorTexture(self.bg,self.selected and 0.24 or 0.085,self.selected and 0.20 or 0.11,self.selected and 0.13 or 0.15,1)
        if GameTooltip then GameTooltip:Hide() end
      end)
      btn:Show()
    end
    if pageLabel then pageLabel:SetText("Page "..questPage.." / "..pages) end
    if pageBack then pageBack:SetEnabled(questPage>1); pageForward:SetEnabled(questPage<pages) end
  elseif currentTab == "Settings" then
    lines = {"Detected class: "..(classNames[actualClass()] or actualClass()), "Preview: "..classLabel(), "Role: "..(DB.role or "Not selected"), "Professions: "..(DB.professions or "Not selected"), "Commands:", "/fc class Warrior  |  /fc class auto", "/fc role Tank  |  /fc professions Mining + Blacksmithing", "/fc check Dungeons 1  |  /fc reset", "/fc position reset", "Class preview does not change your actual character class."}
    if ForeverCompanionDiagnostics then lines[#lines+1]=ForeverCompanionDiagnostics.Collect() end
  else
    lines = {string.upper(currentTab).." CHECKLIST"}
    local entries = DATA.checklist[currentTab] or {}
    for i, item in ipairs(entries) do
      local done = DB.checks and DB.checks[currentTab] and DB.checks[currentTab][i]
      lines[#lines+1] = (done and "[x] " or "[ ] ")..item
      if checkButtons[i] then
        checkButtons[i]:SetText(done and "Undo "..i or "Done "..i)
        if currentTab=="Dungeons" or currentTab=="PvP" then checkButtons[i]:Hide() else checkButtons[i]:Show() end
      end
    end
    if currentTab == "Dungeons" then
      if ForeverCompanionDungeonPreparation then lines[#lines+1]=ForeverCompanionDungeonPreparation.Format(DB.role) end
      if DB.role and DATA.roleAdvice and DATA.roleAdvice[DB.role] then
        lines[#lines+1]="YOUR ROLE PREPARATION"
        for _,tip in ipairs(DATA.roleAdvice[DB.role]) do lines[#lines+1]="- "..tip end
      end
      lines[#lines+1] = "GENERAL CLASSIC DUNGEON NOTES (NOT VERIFIED FOREVER LOOT DATA)"
      for _, entry in ipairs(DATA.dungeons) do lines[#lines+1] = entry[1]..": "..entry[2] end
    elseif currentTab == "Professions" then
      if ForeverCompanionProfessionProgress and ForeverCompanionProfessionProgress.FormatOverview then
        lines[#lines+1]=ForeverCompanionProfessionProgress.FormatOverview()
      elseif ForeverCompanionProfessionScanner then
        lines[#lines+1]=ForeverCompanionProfessionScanner.Format()
      end
      local guide=DATA.professionHandbook and DATA.professionHandbook[professionIndex]
      if guide then
        lines[#lines+1]="PROFESSION HANDBOOK: "..guide.name
        lines[#lines+1]="Pairs with: "..guide.pair
        if ForeverCompanionProfessionFieldGuide then lines[#lines+1]=ForeverCompanionProfessionFieldGuide.Format(guide.name) end
        if ForeverCompanionCampingGuide then lines[#lines+1]=ForeverCompanionCampingGuide.Format(guide.name) end
        if ForeverCompanionCampingReadiness then lines[#lines+1]=ForeverCompanionCampingReadiness.ForProfession(guide.name) end
        if ForeverCompanionProfessionProgress then
          lines[#lines+1]=ForeverCompanionProfessionProgress.ForProfession(guide.name)
          lines[#lines+1]=ForeverCompanionProfessionProgress.ForProfessionNextSteps(guide.name)
        end
        if ForeverCompanionCraftingPlanner then
          local materials=ForeverCompanionCraftingPlanner.GetEntries(guide.name)
          local pages=math.max(1,math.ceil(#materials/5))
          materialPage=math.min(materialPage,pages)
          materialPageLabel:SetText("Materials "..materialPage.."/"..pages)
          materialPageLabel:Show(); materialPrevious:Show(); materialNext:Show()
          materialPrevious:SetEnabled(materialPage>1)
          materialNext:SetEnabled(materialPage<pages)
          for i,entry in ipairs(materialRows) do
            local index=(materialPage-1)*5+i
            local material=materials[index]
            if material then
              local remaining=math.max(0,(tonumber(material.needed) or 0)-(tonumber(material.owned) or 0))
              entry.label:SetText(material.name.."  "..material.owned.."/"..material.needed.."  (need "..remaining..")")
              entry.label:Show(); entry.minus:Show(); entry.plus:Show()
              entry.minus:SetScript("OnClick",function() ForeverCompanionCraftingPlanner.AdjustOwned(guide.name,index,-1); render() end)
              entry.plus:SetScript("OnClick",function() ForeverCompanionCraftingPlanner.AdjustOwned(guide.name,index,1); render() end)
            end
          end
          lines[#lines+1]=ForeverCompanionCraftingPlanner.Summary()
          lines[#lines+1]=ForeverCompanionCraftingPlanner.ShoppingSummary(5)
          lines[#lines+1]=ForeverCompanionCraftingPlanner.Format(guide.name)
        end
        if ForeverCompanionRecipePlans then
          lines[#lines+1]=ForeverCompanionRecipePlans.Format(guide.name)
          lines[#lines+1]=ForeverCompanionRecipePlans.FormatForecast(guide.name)
          if ForeverCompanionCraftingAdvice then lines[#lines+1]=ForeverCompanionCraftingAdvice.Format(guide.name)
            lines[#lines+1]=ForeverCompanionCraftingAdvice.FormatAllocation(guide.name)
            lines[#lines+1]=ForeverCompanionCraftingAdvice.FormatGatherList(guide.name,8) end
        end
        if ForeverCompanionCraftingBridge then
          lines[#lines+1]=ForeverCompanionCraftingBridge.Preview(guide.name)
        end
        lines[#lines+1]=guide.summary
        for i,step in ipairs(guide.steps) do lines[#lines+1]=i..". "..step end
        local deep=ADVANCED and ADVANCED.crafting[guide.name]
        if deep then
          lines[#lines+1]="CRAFTING PROGRESSION (GENERAL REFERENCE)"
          lines[#lines+1]="Materials: "..deep.materials.."  |  Output: "..deep.output
          for i,step in ipairs(deep.stages) do lines[#lines+1]=i..". "..step end
        end
        if handbookIcon then handbookIcon:SetTexture(guide.icon); handbookIcon:Show() end
        for i,button in ipairs(handbookButtons) do
          local entry=DATA.professionHandbook[i]
          if entry then
            button.label:SetText(clipText(entry.name,18))
            button.icon:SetTexture(entry.icon)
            local selected=professionIndex==i
            colorTexture(button.bg,selected and 0.26 or 0.09,selected and 0.20 or 0.12,selected and 0.12 or 0.16,1)
            colorTexture(button.trim,selected and 0.98 or 0.40,selected and 0.73 or 0.32,selected and 0.31 or 0.19,1)
            button.selected=selected
            button:SetScript("OnClick",function() professionIndex=i; materialPage=1; render() end)
            button:Show()
          end
        end
      end
      lines[#lines+1] = "Selected professions: "..(DB.professions or "Not selected")
      lines[#lines+1] = "Set with /fc professions <names>"
    elseif currentTab == "PvP" then
      if ForeverCompanionPvPPreparation then lines[#lines+1]=ForeverCompanionPvPPreparation.Format(classToken()) end
      lines[#lines+1] = "Use game-supported tools and coordinate objectives with your group."
    end
  end
  if pageBack then if currentTab=="Quests" then pageBack:Show(); pageForward:Show(); pageLabel:Show() else pageBack:Hide(); pageForward:Hide(); pageLabel:Hide() end end
  content:SetText(table.concat(lines, "\n\n"))
  content:ClearAllPoints()
  content:SetPoint("TOPLEFT",scrollChild,"TOPLEFT",5,currentTab=="Quests" and -650 or (currentTab=="Professions" and -445 or (currentTab=="Leveling" and -322 or ((currentTab=="Dungeons" or currentTab=="PvP") and -325 or (currentTab=="Overview" and -215 or (currentTab=="Settings" and -282 or -5))))))
  if scrollChild then scrollChild:SetHeight(math.max(420, (tonumber(content:GetStringHeight()) or 0) + (currentTab=="Quests" and 680 or (currentTab=="Professions" and 475 or (currentTab=="Leveling" and 346 or ((currentTab=="Dungeons" or currentTab=="PvP") and 345 or (currentTab=="Settings" and 310 or 24))))))) end
  -- Keep the player's current scroll position during refresh.
  if classButton then classButton:SetText("Class: "..classLabel()) end
  if roleButton then roleButton:SetText("Role: "..(DB.role or "Choose")) end
  if nextQuestButton then if currentTab=="Quests" then nextQuestButton:Show() else nextQuestButton:Hide() end end
  if previousQuestButton then if currentTab=="Quests" then previousQuestButton:Show() else previousQuestButton:Hide() end end
  if questFocusText then
    local q=ForeverCompanionQuestPlanner and ForeverCompanionQuestPlanner.GetSelected()
    questFocusText:SetText(currentTab=="Quests" and (q and ((ForeverCompanionQuestPlanner.IsPinned(q) and "[PIN] " or "").."Focused: "..clipText(q.title,37)) or "No quest selected") or "")
  end
end
-- One navigation path for the sidebar, dashboard shortcuts and slash commands.
-- Changes only the addon's current guide page, never the game quest log.
local function openSection(name)
  if type(name)~="string" then return false end
  for _,section in ipairs(tabs) do
    if section:lower()==name:lower() then
      currentTab=section
      DB.tab=section
      if scrollFrame and scrollFrame.SetVerticalScroll then scrollFrame:SetVerticalScroll(0) end
      render()
      return true
    end
  end
  return false
end
local function fitWindow()
  if not window or not window.SetScale or not UIParent or not UIParent.GetWidth or not UIParent.GetHeight then return end
  local ok,width,height=pcall(function() return UIParent:GetWidth(),UIParent:GetHeight() end)
  if not ok or type(width)~="number" or type(height)~="number" or width<=0 or height<=0 then return end
  local wantedHeight=DB.compact and 620 or 720
  local scale=math.min(1,(width-32)/1080,(height-32)/wantedHeight)
  if scale>0 then pcall(window.SetScale,window,math.max(0.1,scale)) end
end
local function createUI()
  local template = BackdropTemplateMixin and "BackdropTemplate" or nil
  window = CreateFrame("Frame", "ForeverCompanionMainFrame", UIParent, template)
  window:SetSize(1080, DB.compact and 620 or 720)
  if DB.position and type(DB.position.x)=="number" and type(DB.position.y)=="number" then
    window:SetPoint("CENTER", UIParent, "CENTER", DB.position.x, DB.position.y)
  else
    window:SetPoint("CENTER")
  end
  window:SetMovable(true)
  window:EnableMouse(true)
  window:RegisterForDrag("LeftButton")
  window:SetScript("OnDragStart", function(self) self:StartMoving() end)
  window:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local x, y = self:GetCenter()
    local ux, uy = UIParent:GetCenter()
    if x and y and ux and uy then DB.position = {x=x-ux, y=y-uy} end
  end)
  window:SetClampedToScreen(true)
  fitWindow()
  if window.SetBackdrop then
    window:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", edgeSize=16, insets={left=5,right=5,top=5,bottom=5}})
  end
  background=window:CreateTexture(nil,"BACKGROUND")
  background:SetAllPoints(window)
  colorTexture(background,0.025,0.031,0.048,0.98)
  local headerVelvet=window:CreateTexture(nil,"BORDER")
  headerVelvet:SetPoint("TOPLEFT",window,"TOPLEFT",11,-11)
  headerVelvet:SetPoint("TOPRIGHT",window,"TOPRIGHT",-11,-11)
  headerVelvet:SetHeight(79)
  colorTexture(headerVelvet,0.052,0.059,0.085,0.98)
  local headerGold=window:CreateTexture(nil,"ARTWORK")
  headerGold:SetPoint("TOPLEFT",window,"TOPLEFT",12,-92)
  headerGold:SetPoint("TOPRIGHT",window,"TOPRIGHT",-12,-92)
  headerGold:SetHeight(2)
  colorTexture(headerGold,0.88,0.63,0.24,0.98)
  accentBar=window:CreateTexture(nil,"BORDER")
  accentBar:SetPoint("TOPLEFT",window,"TOPLEFT",12,-8)
  accentBar:SetPoint("TOPRIGHT",window,"TOPRIGHT",-12,-8)
  accentBar:SetHeight(3)
  colorTexture(accentBar,0.94,0.65,0.22,1)
  titleText = window:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  titleText:SetPoint("TOPLEFT", 86, -22)
  titleText:SetTextColor(1,0.79,0.36)
  subtitleText=window:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
  subtitleText:SetPoint("TOPLEFT",86,-51)
  subtitleText:SetText("Guides  -  Professions  -  Quests  -  Builds  -  More")
  subtitleText:SetTextColor(0.72,0.78,0.84)
  if ForeverCompanionHeraldry then
    ForeverCompanionHeraldry.Create(window,19,-17,54)
  else
    local crest=window:CreateTexture(nil,"OVERLAY")
    crest:SetPoint("TOPLEFT",window,"TOPLEFT",19,-17)
    crest:SetSize(54,54)
    crest:SetTexture("Interface\\Icons\\INV_Misc_Book_09")
  end
  headerMeta=window:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
  headerMeta:SetPoint("TOPRIGHT",window,"TOPRIGHT",-48,-22)
  headerMeta:SetTextColor(0.94,0.78,0.47)
  questCountText=window:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
  questCountText:SetPoint("TOPRIGHT",-48,-43)
  questCountText:SetTextColor(0.70,0.85,0.74)
  local close = CreateFrame("Button", nil, window, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", -4, -4)
  local sidebar=window:CreateTexture(nil,"BORDER")
  sidebar:SetPoint("TOPLEFT",window,"TOPLEFT",12,-98)
  sidebar:SetPoint("BOTTOMLEFT",window,"BOTTOMLEFT",12,92)
  sidebar:SetWidth(185)
  colorTexture(sidebar,0.027,0.037,0.057,0.99)
  local sidebarTrim=window:CreateTexture(nil,"ARTWORK")
  sidebarTrim:SetPoint("TOPLEFT",sidebar,"TOPRIGHT",-2,0)
  sidebarTrim:SetPoint("BOTTOMLEFT",sidebar,"BOTTOMRIGHT",-2,0)
  sidebarTrim:SetWidth(2)
  colorTexture(sidebarTrim,0.62,0.44,0.19,0.9)
  local navHeading=window:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
  navHeading:SetPoint("TOPLEFT",window,"TOPLEFT",28,-112)
  navHeading:SetText("NAVIGATION")
  navHeading:SetTextColor(0.95,0.72,0.32)
  local navIcons={
    "Interface\\Icons\\INV_Misc_Map_01",
    "Interface\\Icons\\INV_Misc_Book_09",
    "Interface\\Icons\\INV_Misc_Note_01",
    "Interface\\Icons\\INV_Weapon_ShortBlade_01",
    "Interface\\Icons\\Trade_BlackSmithing",
    "Interface\\Icons\\Ability_DualWield",
    "Interface\\Icons\\INV_Gizmo_02"
  }
  for i, section in ipairs(tabs) do
    local b = CreateFrame("Button", nil, window)
    b:SetSize(164, 37)
    b:SetPoint("TOPLEFT",window,"TOPLEFT",23,-138-(i-1)*43)
    b.section=section
    b.navBackground=b:CreateTexture(nil,"BACKGROUND")
    b.navBackground:SetAllPoints(b)
    colorTexture(b.navBackground,0.10,0.13,0.17,1)
    b.navAccent=b:CreateTexture(nil,"ARTWORK")
    b.navAccent:SetPoint("TOPLEFT",b,"TOPLEFT",0,0)
    b.navAccent:SetSize(3,37)
    colorTexture(b.navAccent,0.29,0.25,0.18,1)
    local icon=b:CreateTexture(nil,"ARTWORK")
    icon:SetPoint("LEFT",b,"LEFT",11,0)
    icon:SetSize(21,21)
    icon:SetTexture(navIcons[i])
    local underline=b:CreateTexture(nil,"ARTWORK")
    underline:SetPoint("BOTTOMLEFT",b,"BOTTOMLEFT",4,0)
    underline:SetSize(156,1)
    colorTexture(underline,0.42,0.35,0.24,0.7)
    b.navGlow=b:CreateTexture(nil,"BORDER")
    b.navGlow:SetAllPoints(b)
    colorTexture(b.navGlow,0.08,0.18,0.36,0)
    b.navLabel=b:CreateFontString(nil,"OVERLAY","GameFontHighlight")
    b.navLabel:SetPoint("LEFT",b,"LEFT",40,0)
    b.navLabel:SetText(section)
    b.navLabel:SetTextColor(0.88,0.87,0.83)
    b:SetScript("OnEnter",function(self)
      if currentTab~=self.section then colorTexture(self.navBackground,0.18,0.17,0.14,1) end
    end)
    b:SetScript("OnLeave",function(self)
      if currentTab~=self.section then colorTexture(self.navBackground,0.10,0.13,0.17,1) end
    end)
    b:SetScript("OnClick", function() openSection(section) end)
    tabButtons[#tabButtons+1]=b
  end
  local panel=CreateFrame("Frame",nil,window)
  panel:SetPoint("TOPLEFT",198,-98)
  panel:SetPoint("BOTTOMRIGHT",-16,88)
  local panelTexture=panel:CreateTexture(nil,"BACKGROUND")
  panelTexture:SetAllPoints(panel)
  colorTexture(panelTexture,0.041,0.051,0.073,0.98)
  local scroll = CreateFrame("ScrollFrame", nil, window, "UIPanelScrollFrameTemplate")
  scrollFrame = scroll
  scroll:SetPoint("TOPLEFT", 216, -163)
  sectionHeader=CreateFrame("Frame",nil,window)
  sectionHeader:SetPoint("TOPLEFT",window,"TOPLEFT",210,-106)
  sectionHeader:SetSize(846,48)
  local sectionBg=sectionHeader:CreateTexture(nil,"BACKGROUND")
  sectionBg:SetAllPoints(sectionHeader)
  colorTexture(sectionBg,0.035,0.044,0.067,0.99)
  local sectionTop=sectionHeader:CreateTexture(nil,"ARTWORK")
  sectionTop:SetPoint("TOPLEFT",sectionHeader,"TOPLEFT",0,0)
  sectionTop:SetSize(846,2)
  colorTexture(sectionTop,0.79,0.55,0.21,0.88)
  local sectionInner=sectionHeader:CreateTexture(nil,"ARTWORK")
  sectionInner:SetPoint("TOPLEFT",sectionHeader,"TOPLEFT",5,-5)
  sectionInner:SetSize(836,1)
  colorTexture(sectionInner,0.48,0.34,0.17,0.65)
  local sectionTrim=sectionHeader:CreateTexture(nil,"ARTWORK")
  sectionTrim:SetPoint("BOTTOMLEFT",sectionHeader,"BOTTOMLEFT",0,0)
  sectionTrim:SetSize(846,2)
  colorTexture(sectionTrim,0.82,0.60,0.25,1)
  sectionIcon=sectionHeader:CreateTexture(nil,"ARTWORK")
  sectionIcon:SetPoint("LEFT",sectionHeader,"LEFT",13,0)
  sectionIcon:SetSize(29,29)
  sectionTitle=sectionHeader:CreateFontString(nil,"OVERLAY","GameFontNormal")
  sectionTitle:SetPoint("TOPLEFT",sectionHeader,"TOPLEFT",54,-6)
  sectionTitle:SetTextColor(0.95,0.76,0.38)
  sectionMeta=sectionHeader:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
  sectionMeta:SetPoint("TOPLEFT",sectionHeader,"TOPLEFT",54,-27)
  sectionMeta:SetWidth(755)
  sectionMeta:SetJustifyH("LEFT")
  sectionMeta:SetTextColor(0.72,0.76,0.81)
  sectionHeader:Hide()
  scroll:SetPoint("BOTTOMRIGHT", -35, 92)
  local child = CreateFrame("Frame", nil, scroll)
  child:SetSize(790, 800)
  scrollChild = child
  scroll:SetScrollChild(child)
  if ForeverCompanionClassGuide then ForeverCompanionClassGuide.Create(child) end
  if ForeverCompanionQuestBriefing then ForeverCompanionQuestBriefing.Create(child) end
  if ForeverCompanionProfessionBriefing then ForeverCompanionProfessionBriefing.Create(child) end
  if ForeverCompanionAdventureBriefing then
    ForeverCompanionAdventureBriefing.Create(child,openSection,{
      db=function() return DB end,
      classToken=classToken,
      classLabel=classLabel,
      role=function() return DB and DB.role end
    })
  end
  if ForeverCompanionDashboard then
    ForeverCompanionDashboard.Create(window,openSection,{db=function() return DB end,class=classLabel,level=level})
  end
  if ForeverCompanionSettingsBriefing then
    ForeverCompanionSettingsBriefing.Create(child,{
      db=function() return DB end,
      actualClass=function() return classNames[actualClass()] or "Unknown class" end,
      displayClass=classLabel,
      autoClass=function() DB.previewClass=nil;DB.role=nil;render() end,
      centerWindow=function() DB.position=nil;window:ClearAllPoints();window:SetPoint("CENTER");render() end,
      toggleCompact=function()
        DB.compact=not DB.compact
        window:SetHeight(DB.compact and 620 or 720)
        fitWindow()
        if compactButton then compactButton:SetText(DB.compact and "Expand" or "Compact") end
        render()
      end
    })
  end
  filterButton=CreateFrame("Button",nil,child,"UIPanelButtonTemplate")
  filterButton:SetSize(140,23)
  filterButton:SetPoint("TOPLEFT",child,"TOPLEFT",306,-182)
  filterButton:SetText("Show: all")
  filterButton:SetScript("OnClick",function() questPage=1; ForeverCompanionQuestPlanner.CycleFilter() end)
  filterButton:Hide()
  sortButton=CreateFrame("Button",nil,child,"UIPanelButtonTemplate")
  sortButton:SetSize(140,23)
  sortButton:SetPoint("TOPLEFT",child,"TOPLEFT",157,-182)
  sortButton:SetText("Sort: log")
  sortButton:SetScript("OnClick",function()
    questPage=1
    ForeverCompanionQuestPlanner.CycleSort()
  end)
  sortButton:Hide()
  questRows.pinControl=CreateFrame("Button",nil,child,"UIPanelButtonTemplate")
  questRows.pinControl:SetSize(140,23)
  questRows.pinControl:SetPoint("TOPLEFT",child,"TOPLEFT",8,-182)
  questRows.pinControl:SetText("Pin Focus")
  questRows.pinControl:SetScript("OnClick",function()
    local _,index=ForeverCompanionQuestPlanner.GetSelected()
    if index then ForeverCompanionQuestPlanner.TogglePin(index) end
  end)
  questRows.pinControl:Hide()
  pageBack=CreateFrame("Button",nil,child,"UIPanelButtonTemplate")
  pageBack:SetSize(90,24)
  pageBack:SetPoint("TOPLEFT",child,"TOPLEFT",8,-600)
  pageBack:SetText("Prev Page")
  pageBack:SetScript("OnClick",function() questPage=math.max(1,questPage-1); render() end)
  pageForward=CreateFrame("Button",nil,child,"UIPanelButtonTemplate")
  pageForward:SetSize(90,24)
  pageForward:SetPoint("LEFT",pageBack,"RIGHT",115,0)
  pageForward:SetText("Next Page")
  pageForward:SetScript("OnClick",function() questPage=math.min(math.max(1,math.ceil(#ForeverCompanionQuestPlanner.GetVisible() / #questRows)),questPage+1); render() end)
  pageLabel=child:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
  pageLabel:SetPoint("LEFT",pageBack,"RIGHT",12,0)
  rotationIcon=child:CreateTexture(nil,"OVERLAY")
  rotationIcon:SetSize(28,28)
  rotationIcon:SetPoint("TOPLEFT",child,"TOPLEFT",410,-165)
  rotationIcon:Hide()
  rotationButton=CreateFrame("Button",nil,child,"UIPanelButtonTemplate")
  rotationButton:SetSize(155,23)
  rotationButton:SetPoint("TOPLEFT",child,"TOPLEFT",8,-166)
  rotationButton:SetScript("OnClick",function() rotationMode=(rotationMode % #rotationModes)+1; rotationDetail=1; render() end)
  rotationButton:Hide()
  specButton=CreateFrame("Button",nil,child,"UIPanelButtonTemplate")
  specButton:SetSize(195,23)
  specButton:SetPoint("LEFT",rotationButton,"RIGHT",14,0)
  specButton:SetScript("OnClick",function() ForeverCompanionSpecPlanner.Next(classToken()); rotationDetail=1; render() end)
  specButton:Hide()
  handbookIcon=child:CreateTexture(nil,"OVERLAY")
  handbookIcon:SetSize(30,30)
  handbookIcon:SetPoint("TOPLEFT",child,"TOPLEFT",745,-165)
  handbookIcon:Hide()
  -- Two-row profession handbook selector with fantasy-themed icons.
  for i=1,9 do
    local b=CreateFrame("Button",nil,child)
    b:SetSize(144,24)
    b:SetPoint("TOPLEFT",child,"TOPLEFT",8+((i-1)%5)*153,-180-math.floor((i-1)/5)*28)
    b.bg=b:CreateTexture(nil,"BACKGROUND")
    b.bg:SetAllPoints(b)
    colorTexture(b.bg,0.09,0.12,0.16,1)
    b.trim=b:CreateTexture(nil,"ARTWORK")
    b.trim:SetPoint("TOPLEFT",b,"TOPLEFT",0,0)
    b.trim:SetSize(144,2)
    colorTexture(b.trim,0.40,0.32,0.19,1)
    b.icon=b:CreateTexture(nil,"ARTWORK")
    b.icon:SetPoint("LEFT",b,"LEFT",7,0)
    b.icon:SetSize(18,18)
    b.label=b:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    b.label:SetPoint("LEFT",b,"LEFT",30,0)
    b.label:SetWidth(108)
    b.label:SetJustifyH("LEFT")
    b.label:SetTextColor(0.94,0.87,0.73)
    b:SetScript("OnEnter",function(self) colorTexture(self.bg,0.20,0.18,0.13,1) end)
    b:SetScript("OnLeave",function(self)
      colorTexture(self.bg,self.selected and 0.26 or 0.09,self.selected and 0.20 or 0.12,self.selected and 0.12 or 0.16,1)
    end)
    b:Hide()
    handbookButtons[i]=b
  end
  materialPrevious=CreateFrame("Button",nil,child,"UIPanelButtonTemplate")
  materialPrevious:SetSize(65,22)
  materialPrevious:SetPoint("TOPLEFT",child,"TOPLEFT",8,-240)
  materialPrevious:SetText("Prev")
  materialPrevious:Hide()
  materialPrevious:SetScript("OnClick",function() materialPage=math.max(1,materialPage-1); render() end)
  materialNext=CreateFrame("Button",nil,child,"UIPanelButtonTemplate")
  materialNext:SetSize(65,22)
  materialNext:SetPoint("TOPLEFT",child,"TOPLEFT",195,-240)
  materialNext:SetText("Next")
  materialNext:Hide()
  materialNext:SetScript("OnClick",function() materialPage=materialPage+1; render() end)
  materialPageLabel=child:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
  materialPageLabel:SetPoint("TOPLEFT",child,"TOPLEFT",80,-245)
  materialPageLabel:Hide()
  for i=1,5 do
    local entry={}
    entry.label=child:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    entry.label:SetWidth(445)
    entry.label:SetJustifyH("LEFT")
    entry.label:SetPoint("TOPLEFT",child,"TOPLEFT",8,-272-(i-1)*29)
    entry.minus=CreateFrame("Button",nil,child,"UIPanelButtonTemplate")
    entry.minus:SetSize(34,24)
    entry.minus:SetPoint("TOPLEFT",child,"TOPLEFT",510,-267-(i-1)*29)
    entry.minus:SetText("-")
    entry.plus=CreateFrame("Button",nil,child,"UIPanelButtonTemplate")
    entry.plus:SetSize(34,24)
    entry.plus:SetPoint("LEFT",entry.minus,"RIGHT",4,0)
    entry.plus:SetText("+")
    entry.label:Hide(); entry.minus:Hide(); entry.plus:Hide()
    materialRows[i]=entry
  end
  for i=1,6 do
    local row=CreateFrame("Button",nil,child)
    row:SetSize(122,78)
    row:SetPoint("TOPLEFT",child,"TOPLEFT",8+(i-1)*127,-222)
    row.bg=row:CreateTexture(nil,"BACKGROUND")
    row.bg:SetAllPoints(row)
    colorTexture(row.bg,0.105,0.13,0.18,1)
    row.trim=row:CreateTexture(nil,"ARTWORK")
    row.trim:SetPoint("TOPLEFT",row,"TOPLEFT",0,0)
    row.trim:SetSize(122,3)
    colorTexture(row.trim,0.45,0.36,0.20,1)
    row.icon=row:CreateTexture(nil,"ARTWORK")
    row.icon:SetSize(38,38)
    row.icon:SetPoint("TOP",row,"TOP",0,-7)
    row.number=row:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    row.number:SetPoint("TOPLEFT",row,"TOPLEFT",5,-5)
    row.number:SetText(tostring(i))
    row.number:SetTextColor(1,0.78,0.34)
    row.label=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    row.label:SetPoint("BOTTOM",row,"BOTTOM",0,7)
    row.label:SetWidth(116)
    row.label:SetJustifyH("CENTER")
    row.label:SetTextColor(0.95,0.88,0.72)
    row:Hide()
    rotationRows[i]=row
  end
  content = child:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  content:SetPoint("TOPLEFT", 5, -5)
  questSectionLabel=child:CreateFontString(nil,"OVERLAY","GameFontNormal")
  questSectionLabel:SetPoint("TOPLEFT",child,"TOPLEFT",8,-160)
  questSectionLabel:SetTextColor(1,0.79,0.36)
  questSectionLabel:Hide()
  -- Native journal rows replace stock gray buttons; all selection is addon-local.
  for i=1,15 do
    local row=CreateFrame("Button",nil,child)
    row:SetSize(754,24)
    row:SetPoint("TOPLEFT",child,"TOPLEFT",8,-210-(i-1)*25)
    row.bg=row:CreateTexture(nil,"BACKGROUND")
    row.bg:SetAllPoints(row)
    colorTexture(row.bg,0.085,0.11,0.15,1)
    row.trim=row:CreateTexture(nil,"ARTWORK")
    row.trim:SetPoint("TOPLEFT",row,"TOPLEFT",0,0)
    row.trim:SetSize(3,24)
    colorTexture(row.trim,0.30,0.28,0.21,1)
    row.title=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    row.title:SetPoint("LEFT",row,"LEFT",13,0)
    row.title:SetWidth(460)
    row.title:SetJustifyH("LEFT")
    row.title:SetTextColor(0.95,0.89,0.78)
    row.zone=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    row.zone:SetPoint("LEFT",row,"LEFT",479,0)
    row.zone:SetWidth(164)
    row.zone:SetJustifyH("LEFT")
    row.zone:SetTextColor(0.68,0.74,0.80)
    row.status=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    row.status:SetPoint("LEFT",row,"LEFT",651,0)
    row.status:SetWidth(93)
    row.status:SetJustifyH("RIGHT")
    row:Hide()
    questRows[i]=row
  end
  content:SetWidth(760)
  if content.SetSpacing then content:SetSpacing(4) end
  content:SetJustifyH("LEFT")
  content:SetJustifyV("TOP")
  questFocusText=window:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
  questFocusText:SetPoint("BOTTOMLEFT",220,83)
  questFocusText:SetWidth(385)
  questFocusText:SetJustifyH("LEFT")
  nextQuestButton=CreateFrame("Button",nil,window,"UIPanelButtonTemplate")
  nextQuestButton:SetSize(118,25)
  nextQuestButton:SetPoint("BOTTOMRIGHT",-25,81)
  nextQuestButton:SetText("Next Quest")
  nextQuestButton:SetScript("OnClick",function() ForeverCompanionQuestPlanner.Next(); render() end)
  nextQuestButton:Hide()
  previousQuestButton=CreateFrame("Button",nil,window,"UIPanelButtonTemplate")
  previousQuestButton:SetSize(118,25)
  previousQuestButton:SetPoint("RIGHT",nextQuestButton,"LEFT",-5,0)
  previousQuestButton:SetText("Previous")
  previousQuestButton:SetScript("OnClick",function() ForeverCompanionQuestPlanner.Previous(); render() end)
  previousQuestButton:Hide()
  for i=1,4 do
    local b=CreateFrame("Button", nil, window, "UIPanelButtonTemplate")
    b:SetSize(90, 25)
    b:SetPoint("BOTTOMLEFT", 220+(i-1)*96, 48)
    b:SetScript("OnClick", function() toggleCheck(currentTab,i); render() end)
    b:Hide()
    checkButtons[i]=b
  end
  -- Class selection is a genuine preview control, never a character/class change.
  -- Placed above footer controls, and visible only on the leveling page.
  for i,token in ipairs(classOrder) do
    local button=CreateFrame("Button",nil,window)
    button:SetSize(89,30)
    button:SetPoint("BOTTOMLEFT",window,"BOTTOMLEFT",214+(i-1)*92,89)
    button.classToken=token
    button.bg=button:CreateTexture(nil,"BACKGROUND")
    button.bg:SetAllPoints(button)
    colorTexture(button.bg,0.045,0.07,0.11,1)
    button.trim=button:CreateTexture(nil,"ARTWORK")
    button.trim:SetPoint("BOTTOMLEFT",button,"BOTTOMLEFT",0,0)
    button.trim:SetSize(89,2)
    colorTexture(button.trim,0.44,0.34,0.18,1)
    local name=button:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    name:SetPoint("CENTER",button,"CENTER",0,0)
    name:SetText(classNames[token])
    name:SetTextColor(0.95,0.83,0.60)
    button:SetScript("OnClick",function()
      DB.previewClass=token
      DB.role=nil
      render()
    end)
    button:Hide()
    ForeverCompanionClassStripButtons[i]=button
  end
  classButton = CreateFrame("Button", nil, window, "UIPanelButtonTemplate")
  classButton:SetSize(150, 26)
  classButton:SetPoint("BOTTOMRIGHT", -180, 45)
  classButton:SetScript("OnClick", function()
    local token=classToken()
    for i, candidate in ipairs(classOrder) do
      if candidate == token then DB.previewClass=classOrder[(i % #classOrder)+1]; break end
    end
    DB.role=nil
    render()
  end)
  resetClassButton=CreateFrame("Button",nil,window,"UIPanelButtonTemplate")
  resetClassButton:SetSize(92,23)
  resetClassButton:SetPoint("BOTTOMRIGHT",-125,16)
  resetClassButton:SetText("Auto Class")
  resetClassButton:SetScript("OnClick",function() DB.previewClass=nil; DB.role=nil; render() end)
  roleButton = CreateFrame("Button", nil, window, "UIPanelButtonTemplate")
  roleButton:SetSize(145, 26)
  roleButton:SetPoint("BOTTOMRIGHT", -25, 45)
  roleButton:SetScript("OnClick", function()
    local roles=classRoles[classToken()] or {"Damage"}
    local nextIndex=1
    for i, role in ipairs(roles) do if DB.role==role then nextIndex=(i % #roles)+1 end end
    DB.role=roles[nextIndex]
    render()
  end)
  compactButton=CreateFrame("Button",nil,window,"UIPanelButtonTemplate")
  compactButton:SetSize(92,23)
  compactButton:SetPoint("BOTTOMRIGHT",-25,16)
  compactButton:SetText(DB.compact and "Expand" or "Compact")
  compactButton:SetScript("OnClick",function()
    DB.compact=not DB.compact
    window:SetHeight(DB.compact and 620 or 720)
    fitWindow()
    compactButton:SetText(DB.compact and "Expand" or "Compact")
    render()
  end)
  local footer=window:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  footer:SetPoint("BOTTOMLEFT", 20, 19)
  footer:SetText("v3.14.0 Beta  |  /fc help  |  Read-only advisor  |  No gameplay automation")
  currentTab = DB.tab or "Overview"
  local validTab=false
  for _, section in ipairs(tabs) do if section==currentTab then validTab=true end end
  if not validTab then currentTab="Overview" end
  window:Hide()
  render()
end
for _,event in ipairs({"ADDON_LOADED","PLAYER_LEVEL_UP","PLAYER_ENTERING_WORLD","PLAYER_XP_UPDATE","SKILL_LINES_CHANGED","CHAT_MSG_SKILL","UI_SCALE_CHANGED","DISPLAY_SIZE_CHANGED"}) do
  pcall(function() addon:RegisterEvent(event) end)
end
addon:SetScript("OnEvent", function(_, event, arg)
  if event == "ADDON_LOADED" and arg == addonName then
    ForeverCompanionDB = ForeverCompanionDB or {}
    DB = ForeverCompanionDB
    if type(DB.checks)~="table" then DB.checks={} end
    if type(DB.tab)~="string" then DB.tab="Overview" end
    createUI()
    if not DB.welcomed then DB.welcomed=true; window:Show() end
  elseif DB and (event == "UI_SCALE_CHANGED" or event == "DISPLAY_SIZE_CHANGED") then
    fitWindow()
    render()
  elseif DB and (event == "PLAYER_LEVEL_UP" or event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_XP_UPDATE" or event == "SKILL_LINES_CHANGED" or event == "CHAT_MSG_SKILL") then
    render()
  end
end)
SLASH_FOREVERCOMPANION1 = "/fc"
SLASH_FOREVERCOMPANION2 = "/forevercompanion"
SlashCmdList.FOREVERCOMPANION = function(msg)
  msg=(msg or ""):match("^%s*(.-)%s*$")
  if not DB then return end
  if msg == "" then if window:IsShown() then window:Hide() else render(); window:Show() end; return end
  if msg == "help" then say("/fc, /fc open <section>, /fc status, /fc class <name|auto>, /fc role <role>, /fc professions <names>, /fc check <section> <1-4>, /fc reset, /fc position reset, /fcq sync"); return end
  local requested=msg:match("^open%s+(.+)$") or msg
  if openSection(requested) then window:Show(); return end
  if msg=="status" then
    local planner=ForeverCompanionQuestPlanner
    local supported=planner and planner.IsSupported and planner.IsSupported()
    local stale=planner and planner.IsSnapshotStale and planner.IsSnapshotStale()
    local count=planner and planner.AutoCount and planner.AutoCount() or 0
    local label=supported and "current snapshot" or (stale and "cached/outdated" or "unavailable")
    local craft=ForeverCompanionCraftingPlanner
    local stats=craft and craft.Stats and craft.Stats()
    say("Quest log: "..label.." ("..tostring(count).." recorded). Material goals: "..tostring(stats and stats.complete or 0).."/"..tostring(stats and stats.materials or 0).." complete, "..tostring(stats and stats.missing or 0).." units missing (manual).")
    return
  end
  local class = msg:match("^class%s+(.+)$")
  if class then
    if class:lower()=="auto" then DB.previewClass=nil
    else
      local found
      for token,name in pairs(classNames) do if name:lower()==class:lower() then found=token end end
      if not found then say("Unknown class."); return end
      DB.previewClass=found
    end
    DB.role=nil; render(); return
  end
  local role=msg:match("^role%s+(.+)$")
  if role then
    local valid=false
    for _, r in ipairs(classRoles[classToken()] or {"Damage"}) do
      if r:lower()==role:lower() then DB.role=r; valid=true end
    end
    if not valid then say("Invalid role for displayed class."); return end
    render(); return
  end
  local prof=msg:match("^professions%s+(.+)$")
  if prof then DB.professions=prof:sub(1,100); render(); return end
  local section,index=msg:match("^check%s+(%a+)%s+(%d+)$")
  if section then
    for name,entries in pairs(DATA.checklist) do
      if name:lower()==section:lower() and tonumber(index)>=1 and tonumber(index)<=#entries then
        toggleCheck(name,tonumber(index)); currentTab=name; DB.tab=name; render(); return
      end
    end
    say("Invalid checklist or step."); return
  end
  if msg=="reset" then DB.checks={}; render(); say("Checklist progress reset."); return end
  if msg=="position reset" then DB.position=nil; window:ClearAllPoints(); window:SetPoint("CENTER"); say("Window centered."); return end
  say("Unknown command; type /fc help")
end

ForeverCompanionRefresh = function() if DB and window then render() end end
