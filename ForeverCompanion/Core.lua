local addonName = ...
local addon = CreateFrame("Frame")
local DATA = ForeverCompanionData
local ADVANCED = ForeverCompanionAdvanced
local ROTATIONS = ForeverCompanionRotations
local rotationModes={"leveling","dungeon","boss","aoe","pvp"}
local rotationMode=1
local rotationButton, rotationIcon, rotationDescription, specButton
local DB, window, titleText, content, currentTab, headerMeta
ForeverCompanionLootUI = ForeverCompanionLootUI or {query="", selectedIndex=1, dungeon="", boss="", savedOnly=false}
local tabs = {"Overview", "Journey", "Leveling", "Legacy", "Alts", "Quests", "Dungeons", "Loot", "Professions", "PvP", "Settings"}
local classNames = {WARRIOR="Warrior", PALADIN="Paladin", HUNTER="Hunter", ROGUE="Rogue", PRIEST="Priest", SHAMAN="Shaman", MAGE="Mage", WARLOCK="Warlock", DRUID="Druid"}
local classRoles = {WARRIOR={"Tank","Damage"}, PALADIN={"Tank","Damage","Healer"}, HUNTER={"Damage"}, ROGUE={"Damage"}, PRIEST={"Healer","Damage"}, SHAMAN={"Healer","Damage"}, MAGE={"Damage"}, WARLOCK={"Damage"}, DRUID={"Tank","Damage","Healer"}}
local tabButtons = {}
ForeverCompanionClassStripButtons={}
local checkButtons = {}
local scrollFrame, scrollChild
ForeverCompanionUIState = ForeverCompanionUIState or {}
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
  Journey="Next quest, navigation and suggested zones",
  Leveling="Class priorities, specialization reference and leveling notes",
  Legacy="Earn points and plan perks",
  Alts="Plan your next character",
  Quests="Track objectives, turn-ins and pinned quests",
  Dungeons="Choose a dungeon, then a boss",
  Loot="Find gear, check its source, and save your targets",
  Professions="Browse recipes and track materials",
  PvP="Prepare for your next match",
  Settings="Adjust your window and check client support"
}
local sectionIcons={
  Journey="Interface\\Icons\\INV_Misc_Map_01",
  Leveling="Interface\\Icons\\INV_Misc_Book_09",
  Legacy="Interface\\Icons\\INV_Misc_Book_11",
  Alts="Interface\\Icons\\INV_Misc_Map_01",
  Quests="Interface\\Icons\\INV_Misc_Note_01",
  Dungeons="Interface\\Icons\\INV_Weapon_ShortBlade_01",
  Loot="Interface\\Icons\\INV_Chest_Chain_04",
  Professions="Interface\\Icons\\Trade_BlackSmithing",
  PvP="Interface\\Icons\\Ability_DualWield",
  Settings="Interface\\Icons\\INV_Gizmo_02"
}
local classOrder = {"WARRIOR","PALADIN","HUNTER","ROGUE","PRIEST","SHAMAN","MAGE","WARLOCK","DRUID"}
local function colorTexture(texture,r,g,b,a)
  if texture.SetColorTexture then texture:SetColorTexture(r,g,b,a)
  else texture:SetTexture(r,g,b,a) end
end
local function say(msg) print("|cffffcc66Brady\'s Forever Companion:|r "..msg) end
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
  if type(DB.checks[section])~="table" then DB.checks[section]={} end
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
local lootMatches
local function render()
  if not window or not DB then return end
  titleText:SetText("Brady\'s Forever Companion")
  if headerMeta then headerMeta:SetText(classLabel().."  |  Level "..tostring(level() or "?").."  |  "..(DB.role or "Choose role")) end
  if ForeverCompanionUIState.questCountText and ForeverCompanionQuestPlanner then
    local planner=ForeverCompanionQuestPlanner
    if planner.IsSupported() then
      ForeverCompanionUIState.questCountText:SetText("Active quests: "..planner.AutoCount())
    elseif planner.IsSnapshotStale() then
      ForeverCompanionUIState.questCountText:SetText("Cached quests: "..planner.AutoCount().." (outdated)")
    else
      ForeverCompanionUIState.questCountText:SetText("Quest API unavailable")
    end
  end
  local isOverview=currentTab=="Overview"
  local isJournal=currentTab=="Dungeons" or currentTab=="Loot" or currentTab=="Journey"
  local notesButton=ForeverCompanionUIState.professionNotesButton
  if notesButton then
    if currentTab=="Professions" then
      notesButton:SetText(ForeverCompanionUIState.showProfessionNotes and "Hide detailed notes" or "Show detailed notes")
      notesButton:Show()
    else notesButton:Hide() end
  end
  if sectionHeader then
    if isOverview or isJournal or currentTab=="Leveling" then sectionHeader:Hide()
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
    scrollFrame:SetPoint("TOPLEFT",216,(currentTab=="Leveling" or isJournal) and -104 or -163)
    scrollFrame:SetPoint("BOTTOMRIGHT",-35,(currentTab=="Leveling" or isJournal) and 57 or (currentTab=="Quests" and 116 or 92))
  end
  if ForeverCompanionClassGuide then
    ForeverCompanionClassGuide.Show(currentTab=="Leveling")
    if currentTab=="Leveling" then ForeverCompanionClassGuide.Render(classToken(),classLabel(),level(),DB.role,rotationModes[rotationMode]) end
  end
  if ForeverCompanionRotationWorkspace then
    local priorities=ROTATIONS and ROTATIONS[classToken()] and ROTATIONS[classToken()][rotationModes[rotationMode]] or {}
    ForeverCompanionRotationWorkspace.Render(ForeverCompanionClassGuide.GetView()=="Rotations" and currentTab or "",classToken(),rotationModes[rotationMode],level(),DB.role,priorities,actualClass())
  end
  if ForeverCompanionLootWorkspace then ForeverCompanionLootWorkspace.Render(currentTab,DB,currentTab=="Loot" and lootMatches() or {}) end
  if ForeverCompanionEncounterBrowser then ForeverCompanionEncounterBrowser.Render(currentTab,DB) end
  if ForeverCompanionResearchNotebook then ForeverCompanionResearchNotebook.Render(currentTab,DB) end
  if ForeverCompanionStudyBoard then
    local studyTab=currentTab
    if currentTab=="Leveling" and ForeverCompanionClassGuide.GetView()~="Rotations" then studyTab="" end
    ForeverCompanionStudyBoard.Render(studyTab,classToken(),DB)
  end
  if ForeverCompanionJourney then ForeverCompanionJourney.Show(currentTab=="Journey",level()) end
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
  -- The class page uses a reference-style class strip and moves redundant
  -- footer controls out of the reading area; every action remains accessible.
  if ForeverCompanionUIState.classButton then
    if currentTab=="Leveling" then ForeverCompanionUIState.classButton:Hide() else ForeverCompanionUIState.classButton:Show() end
  end
  if ForeverCompanionUIState.footer then
    if currentTab=="Leveling" then ForeverCompanionUIState.footer:Hide() else ForeverCompanionUIState.footer:Show() end
  end
  if ForeverCompanionUIState.roleButton then
    local role=ForeverCompanionUIState.roleButton
    role:ClearAllPoints()
    role:SetPoint(currentTab=="Leveling" and "TOPRIGHT" or "BOTTOMRIGHT",window,currentTab=="Leveling" and "TOPRIGHT" or "BOTTOMRIGHT",-25,currentTab=="Leveling" and -62 or 45)
  end
  if resetClassButton then
    resetClassButton:ClearAllPoints()
    if currentTab=="Leveling" then resetClassButton:SetPoint("BOTTOMLEFT",window,"BOTTOMLEFT",20,16)
    else resetClassButton:SetPoint("BOTTOMRIGHT",window,"BOTTOMRIGHT",-125,16) end
  end
  if ForeverCompanionUIState.compactButton then
    local button=ForeverCompanionUIState.compactButton
    button:ClearAllPoints();button:SetSize(currentTab=="Leveling" and 70 or 92,23)
    if currentTab=="Leveling" then button:SetPoint("BOTTOMLEFT",window,"BOTTOMLEFT",117,16)
    else button:SetPoint("BOTTOMRIGHT",window,"BOTTOMRIGHT",-25,16) end
  end
  for _, b in ipairs(tabButtons) do
    if b.section == currentTab then
      colorTexture(b.navBackground,currentTab=="Leveling" and 0.055 or 0.20,currentTab=="Leveling" and 0.15 or 0.145,currentTab=="Leveling" and 0.31 or 0.075,1)
      if b.navGlow then colorTexture(b.navGlow,currentTab=="Leveling" and .08 or .42,currentTab=="Leveling" and .22 or .28,currentTab=="Leveling" and .52 or .10,currentTab=="Leveling" and .48 or .32) end
      colorTexture(b.navAccent,0.98,0.74,0.29,1)
      colorTexture(b.navTop,0.92,0.69,0.29,0.98)
      colorTexture(b.navMarker,0.96,0.76,0.38,1)
      b.navLabel:SetTextColor(1,0.83,0.43)
      if b.navIcon and b.navIcon.SetVertexColor then b.navIcon:SetVertexColor(1,0.84,0.52) end
    else
      colorTexture(b.navBackground,0.050,0.067,0.100,1)
      if b.navGlow then colorTexture(b.navGlow,0.08,0.18,0.36,0) end
      colorTexture(b.navAccent,0.52,0.39,0.19,1)
      colorTexture(b.navTop,0.48,0.36,0.21,0.65)
      colorTexture(b.navMarker,0.85,0.63,0.28,0)
      b.navLabel:SetTextColor(0.88,0.87,0.83)
      if b.navIcon and b.navIcon.SetVertexColor then b.navIcon:SetVertexColor(0.78,0.79,0.80) end
    end
  end
  for _, b in ipairs(checkButtons) do b:Hide() end
  if handbookIcon then handbookIcon:Hide() end
  if rotationIcon then rotationIcon:Hide() end
  if rotationButton then rotationButton:SetText("Rotation: "..rotationModes[rotationMode]);rotationButton:Hide() end
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
    if ForeverCompanionReadiness then lines[#lines+1]=ForeverCompanionReadiness.Format(classToken(),level(),(DB and DB.professions or "")) end
    if ForeverCompanionDiagnostics then lines[#lines+1]=ForeverCompanionDiagnostics.Collect() end
  elseif currentTab == "Loot" then
    lines = {}
  elseif currentTab == "Legacy" then
    lines = {"LEGACY SYSTEM / BLIZZARD LAUNCH REFERENCE",
      "Unlock: Earn a Legacy Point at level 25 or 150 skill in a non-gathering primary profession. Open the Legacy shield or press Y.",
      "Earn points: Class levels 25, 45 and 60. Profession skill 150, 225 and 300. Each eligible milestone awards one account-wide point.",
      "Spend points: Choose perks per character. The launch cap of 16 points is reachable on one character.",
      "REWARDS: Account-wide point totals unlock cosmetics. Check the client for current thresholds and ruleset restrictions.",
      "Source: https://worldofwarcraft.blizzard.com/en-us/news/24307383",
      "Based on Blizzard’s launch guide."}
  elseif currentTab == "Alts" then
    lines = {"ALT LEVELING / PLANNING GUIDE",
      "Legacy perks: Check Well Rested for rested XP and Talented for earlier talents. Choose perks separately on each character.",
      "Milestones: Review class challenges at levels 25, 45 and 60.",
      "Before you start: Check rested XP, bags, class training and dungeon requirements.",
      "Source: https://worldofwarcraft.blizzard.com/en-us/news/24307383",
      "Checklist and notes are saved per character."}
  elseif currentTab == "Leveling" then
    if ForeverCompanionClassGuide.GetView()=="Rotations" and ForeverCompanionRotationWorkspace.ShowReference() then
      lines = {"CLASS GUIDANCE",experienceText(),
        "ALT LEVELING: The Alt Leveling and Legacy pages explain shared points, character-specific perks and practical preparation."}
      -- Put the immediately actionable, spec-specific steps first in the
      -- scrollable guide, before long reference material and rotation notes.
      if type(ForeverCompanionQuickStartLines)=="function" then
        local ok,quick=pcall(ForeverCompanionQuickStartLines,classToken())
        if ok and type(quick)=="table" then
          lines[#lines+1]="START HERE / THREE PRACTICE STEPS"
          for _,note in ipairs(quick) do
            if type(note)=="string" then lines[#lines+1]=note end
          end
        end
      end
      local rotations=ROTATIONS and ROTATIONS[classToken()]
      if rotations then
        local mode=rotationModes[rotationMode]
        lines[#lines+1]="ROTATION / PRIORITY: "..string.upper(mode)
        local presentation=ForeverCompanionRotationPresentation
        local context=presentation and presentation.contexts[mode]
        if context then lines[#lines+1]=context.title.." - "..context.description end
        -- Read-only beginner coaching appears in the visible guide text for every class.
        -- These instructions are conditional, never an automated combat sequence.
        local coach=type(ForeverCompanionGetBeginnerCoach)=="function"
          and ForeverCompanionGetBeginnerCoach(classToken())
        if type(coach)=="table" then
          lines[#lines+1]="BEGINNER COACH (ILLUSTRATIVE - VERIFY IN FOREVER)"
          lines[#lines+1]="RESOURCE: "..coach.resource
          lines[#lines+1]="BEFORE COMBAT: "..coach.first
          lines[#lines+1]="YOUR BASIC LOOP: "..coach.loop
          lines[#lines+1]="IF SOMETHING GOES WRONG: "..coach.recover
          lines[#lines+1]="VERIFY IN CLIENT: "..coach.check
        end
        -- Specialization-aware practice guidance uses the player's selected
        -- planning spec and never assumes that an untrained spell is available.
        if ForeverCompanionPracticeNotes then
          for _,note in ipairs(ForeverCompanionPracticeNotes.Lines(classToken())) do lines[#lines+1]=note end
        end
        if type(ForeverCompanionSpecCoachLines)=="function" then
          for _,note in ipairs(ForeverCompanionSpecCoachLines(classToken())) do
            lines[#lines+1]=note
          end
        end
        if type(ForeverCompanionSpecPriorityNoteLines)=="function" then
          for _,note in ipairs(ForeverCompanionSpecPriorityNoteLines(classToken())) do
            lines[#lines+1]=note
          end
        end
        if type(ForeverCompanionSourcedPriorityLines)=="function" then
          for _,note in ipairs(ForeverCompanionSourcedPriorityLines(classToken())) do
            lines[#lines+1]=note
          end
        end
        if type(ForeverCompanionSpecPlaybookLines)=="function" then
          for _,note in ipairs(ForeverCompanionSpecPlaybookLines(classToken())) do
            lines[#lines+1]=note
          end
        end
        if type(ForeverCompanionGuideEvidenceLines)=="function" then
          for _,note in ipairs(ForeverCompanionGuideEvidenceLines(classToken())) do
            lines[#lines+1]=note
          end
        end
        if type(ForeverCompanionSimResearchLines)=="function" then
          for _,note in ipairs(ForeverCompanionSimResearchLines()) do
            lines[#lines+1]=note
          end
        end
        if type(ForeverCompanionNovemberTuningLines)=="function" then
          for _,note in ipairs(ForeverCompanionNovemberTuningLines(classToken())) do
            lines[#lines+1]=note
          end
        end
        if type(ForeverCompanionForeverLessonLines)=="function" then
          for _,note in ipairs(ForeverCompanionForeverLessonLines(classToken())) do
            lines[#lines+1]=note
          end
        end
        -- Sourced Forever mechanics are displayed separately from generic leveling
        -- priorities; they remain conditional on trained spells and chosen talents.
        local foreverNotes=type(ForeverCompanionForeverMechanics)=="table" and ForeverCompanionForeverMechanics[classToken()]
        if type(foreverNotes)=="table" then
          lines[#lines+1]="FOREVER CLASS CHANGES (CHECK YOUR SPELLBOOK)"
          for _,note in ipairs(foreverNotes) do lines[#lines+1]="- "..note end
          local sources=ForeverCompanionForeverMechanicsSources
          if type(sources)=="table" and type(sources[classToken()])=="string" then
            lines[#lines+1]="Source: "..sources[classToken()]
          end
        end
        local coaching=type(ForeverCompanionForeverDpsCoaching)=="table" and ForeverCompanionForeverDpsCoaching[classToken()]
        if type(coaching)=="table" then
          local selected
          if type(ForeverCompanionSpecPlanner)=="table" and type(ForeverCompanionSpecPlanner.Get)=="function" then
            local ok,result=pcall(ForeverCompanionSpecPlanner.Get,classToken())
            if ok then selected=result end
          end
          local specName=type(selected)=="table" and type(selected[1])=="string" and selected[1] or ""
          local steps=coaching[string.lower(specName)]
          lines[#lines+1]="SPECIALIZATION DPS COACHING: "..(specName~="" and string.upper(specName) or "SELECT A SPEC")
          lines[#lines+1]="Use the Spec button above to change your selected specialization."
          if type(steps)=="table" then
            lines[#lines+1]="PRACTICE IN ORDER — then repeat the priority as conditions change:"
            for step,tip in ipairs(steps) do
              lines[#lines+1]="STEP "..step.."  |  "..tip
            end
            lines[#lines+1]="DPS CHECK: Keep attacking while mechanics allow; avoid wasted resources and unnecessary movement."
            lines[#lines+1]="DPS CHECK: Revisit your spellbook after leveling or changing talents."
            lines[#lines+1]="These priorities are advisory; confirm talents and learned spells in the Forever client."
          else
            lines[#lines+1]="No Forever-specific DPS coaching has been verified for this selection yet."
            lines[#lines+1]="Use the general priority above and check your spellbook for available abilities."
          end
        end
        local previewing=classToken()~=actualClass()
        if previewing then lines[#lines+1]="Class preview: live spellbook checks are available for your own class." end
        if not previewing and type(ForeverCompanionBeginnerAvailability)=="function" then
          lines[#lines+1]="BEGINNER SPELLBOOK CHECK (READ-ONLY)"
          if type(ForeverCompanionBeginnerCoverage)=="function" then
            local ok,covered,total=pcall(ForeverCompanionBeginnerCoverage,classToken())
            if ok and type(covered)=="number" and type(total)=="number" then
              lines[#lines+1]="CURATED UNLOCK DATA: "..covered.."/"..total.." suggested spells cross-referenced."
              if covered<total then
                lines[#lines+1]="Other suggestions are general coaching only; unlock levels are not verified."
              end
            end
          end
          local scan
          if type(ForeverCompanionSpellbook)=="table" and type(ForeverCompanionSpellbook.Scan)=="function" then
            local ok,value=pcall(ForeverCompanionSpellbook.Scan)
            if ok then scan=value end
          end
          if type(scan)~="table" then scan={supported=false,inspected=0,complete=false,known={}} end
          local ok,results=pcall(ForeverCompanionBeginnerAvailability,classToken(),scan)
          if ok and type(results)=="table" then
            for _,line in ipairs(results) do lines[#lines+1]=line end
          else
            lines[#lines+1]="Spell availability could not be checked in this client."
          end
          lines[#lines+1]="Unknown or absent entries do not prove a spell is unavailable; check talents, trainer and ranks."
        end
        if classToken()=="MAGE" and type(ForeverCompanionMageMilestoneLines)=="function" then
          lines[#lines+1]="MAGE LEVELING: WHAT TO PRESS NEXT"
          local ok,milestones=pcall(ForeverCompanionMageMilestoneLines,level())
          if ok and type(milestones)=="table" then
            for _,milestone in ipairs(milestones) do lines[#lines+1]=milestone end
          end
          lines[#lines+1]="Unlock levels come from published Forever client data; spellbook ownership is checked separately."
        end
        if not previewing and ForeverCompanionAvailableAbilitySummary then
          lines[#lines+1]=ForeverCompanionAvailableAbilitySummary(classToken(),level())
        end
        if ForeverCompanionAbilityReferenceLines then
          for _,referenceLine in ipairs(ForeverCompanionAbilityReferenceLines(classToken(),level(),previewing)) do
            lines[#lines+1]=referenceLine
          end
        end
        if ForeverCompanionLevelingCurriculum then lines[#lines+1]=ForeverCompanionLevelingCurriculum.Format(classToken(),level()) end
        if ForeverCompanionWorldGuide then lines[#lines+1]=ForeverCompanionWorldGuide.Format(level()) end
        if ForeverCompanionClassChanges then lines[#lines+1]=ForeverCompanionClassChanges.Format(classToken(),level()) end
        if ForeverCompanionClassChangeIndex then lines[#lines+1]=ForeverCompanionClassChangeIndex.Format(classToken(),level()) end
        if not previewing and ForeverCompanionSkillStudy then lines[#lines+1]=ForeverCompanionSkillStudy.Format(classToken(),level())
          lines[#lines+1]=ForeverCompanionSkillStudy.FormatNextActions(classToken(),level())
          lines[#lines+1]=ForeverCompanionSkillStudy.PracticePlan(classToken(),level()) end
        if not previewing and ForeverCompanionSkillDiscovery then
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
        if ForeverCompanionFormatCooldowns then
          lines[#lines+1]=ForeverCompanionFormatCooldowns(classToken(),mode)
        end
        if ForeverCompanionSpecPlanner then lines[#lines+1]=ForeverCompanionSpecPlanner.Format(classToken(),mode) end
        if not previewing and ForeverCompanionSpellbook then lines[#lines+1]=ForeverCompanionSpellbook.Cooldowns(classToken()) end
        lines[#lines+1]="General reference only; verify abilities and talents on Forever."
      end
      local guide=DATA.classHandbook and DATA.classHandbook[classToken()]
      if guide then
        lines[#lines+1]="LEVELING: "..guide.leveling
        lines[#lines+1]="DUNGEON: "..guide.dungeon
        lines[#lines+1]="PVP: "..guide.pvp
        lines[#lines+1]="PROFESSIONS: "..guide.professions
        if handbookIcon then ForeverCompanionIcons.ApplyClass(handbookIcon,classToken()) end
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
    lines = {"Commands", "/fc help  •  Command list", "/fcdiag  •  Client diagnostics", "/fc position reset  •  Center the window"}
  else
    lines = (currentTab=="Dungeons" or currentTab=="PvP") and {} or {string.upper(currentTab).." CHECKLIST"}
    local entries = DATA.checklist[currentTab] or {}
    for i, item in ipairs(entries) do
      local done = DB.checks and DB.checks[currentTab] and DB.checks[currentTab][i]
      if currentTab~="Dungeons" and currentTab~="PvP" then lines[#lines+1]=(done and "[x] " or "[ ] ")..item end
      if checkButtons[i] then
        checkButtons[i]:SetText(done and "Undo "..i or "Done "..i)
        if currentTab=="Dungeons" or currentTab=="PvP" then checkButtons[i]:Hide() else checkButtons[i]:Show() end
      end
    end
    if currentTab == "Dungeons" then
      if ForeverCompanionDungeonPreparation then
        lines[#lines+1]=ForeverCompanionDungeonPreparation.LaunchReference(level())
        lines[#lines+1]=ForeverCompanionDungeonPreparation.Format(DB.role)
      end
      if DB.role and DATA.roleAdvice and DATA.roleAdvice[DB.role] then
        lines[#lines+1]="YOUR ROLE PREPARATION"
        for _,tip in ipairs(DATA.roleAdvice[DB.role]) do lines[#lines+1]="- "..tip end
      end
      lines[#lines+1]="Boss drops in the journal are source references. Check the live game for current drops and tactics."

    elseif currentTab == "Professions" then
      local showNotes=ForeverCompanionUIState.showProfessionNotes
      if showNotes and ForeverCompanionProfessionProgress and ForeverCompanionProfessionProgress.FormatOverview then
        lines[#lines+1]=ForeverCompanionProfessionProgress.FormatOverview()
      elseif showNotes and ForeverCompanionProfessionScanner then
        lines[#lines+1]=ForeverCompanionProfessionScanner.Format()
      end
      local guide=DATA.professionHandbook and DATA.professionHandbook[professionIndex]
      if guide then
        lines[#lines+1]=guide.name.."  •  Pairs with "..guide.pair
        lines[#lines+1]=guide.summary
        if showNotes and ForeverCompanionProfessionFieldGuide then lines[#lines+1]=ForeverCompanionProfessionFieldGuide.Format(guide.name) end
        if showNotes and ForeverCompanionCampingGuide then lines[#lines+1]=ForeverCompanionCampingGuide.Format(guide.name) end
        if showNotes and ForeverCompanionCampingReadiness then lines[#lines+1]=ForeverCompanionCampingReadiness.ForProfession(guide.name) end
        if showNotes and ForeverCompanionProfessionProgress then
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
          if showNotes then
            lines[#lines+1]=ForeverCompanionCraftingPlanner.Summary()
            lines[#lines+1]=ForeverCompanionCraftingPlanner.ShoppingSummary(5)
            lines[#lines+1]=ForeverCompanionCraftingPlanner.Format(guide.name)
          end
        end
        if showNotes and ForeverCompanionRecipePlans then
          lines[#lines+1]=ForeverCompanionRecipePlans.Format(guide.name)
          lines[#lines+1]=ForeverCompanionRecipePlans.FormatForecast(guide.name)
          if ForeverCompanionCraftCosts then lines[#lines+1]=ForeverCompanionCraftCosts.Format(guide.name) end
          if ForeverCompanionShoppingBudget then lines[#lines+1]=ForeverCompanionShoppingBudget.Format(guide.name) end
          if ForeverCompanionCraftingAdvice then lines[#lines+1]=ForeverCompanionCraftingAdvice.Format(guide.name)
            lines[#lines+1]=ForeverCompanionCraftingAdvice.FormatAllocation(guide.name)
            lines[#lines+1]=ForeverCompanionCraftingAdvice.FormatGatherList(guide.name,8) end
        end
        if showNotes and ForeverCompanionCraftingBridge then
          lines[#lines+1]=ForeverCompanionCraftingBridge.Preview(guide.name)
        end
        for i,step in ipairs(guide.steps) do lines[#lines+1]=i..". "..step end
        local deep=showNotes and ADVANCED and ADVANCED.crafting[guide.name]
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
      if showNotes then lines[#lines+1]="Set your professions with /fc professions <names>." end
    elseif currentTab == "PvP" then
      if ForeverCompanionPvPPreparation then lines[#lines+1]=ForeverCompanionPvPPreparation.Format(classToken()) end
      lines[#lines+1] = "Use game-supported tools and coordinate objectives with your group."
    end
  end
  if pageBack then if currentTab=="Quests" then pageBack:Show(); pageForward:Show(); pageLabel:Show() else pageBack:Hide(); pageForward:Hide(); pageLabel:Hide() end end
  content:SetText(table.concat(lines, "\n\n"))
  content:ClearAllPoints()
  local offsets={Journey=ForeverCompanionJourney.GetHeight(),Loot=5,Quests=650,Professions=445,Leveling=970,Dungeons=953,PvP=325,Overview=215,Settings=282,Legacy=630,Alts=630}
  local offset=offsets[currentTab] or 5
  if currentTab=="Loot" then offset=22+ForeverCompanionLootWorkspace.GetHeight() end
  if currentTab=="Leveling" then offset=584+ForeverCompanionRotationWorkspace.GetHeight() end
  if currentTab=="Leveling" and ForeverCompanionClassGuide.GetView()~="Rotations" then offset=198+ForeverCompanionClassGuide.GetTopicHeight() end
  content:SetPoint("TOPLEFT",scrollChild,"TOPLEFT",5,-offset)
  if scrollChild then scrollChild:SetHeight(math.max(420,(tonumber(content:GetStringHeight()) or 0)+offset+30)) end
  -- Keep the player's current scroll position during refresh.
  if ForeverCompanionUIState.classButton then ForeverCompanionUIState.classButton:SetText("Class: "..classLabel()) end
  if ForeverCompanionUIState.roleButton then ForeverCompanionUIState.roleButton:SetText("Role: "..(DB.role or "Choose")) end
  if ForeverCompanionUIState.nextQuestButton then if currentTab=="Quests" then ForeverCompanionUIState.nextQuestButton:Show() else ForeverCompanionUIState.nextQuestButton:Hide() end end
  if ForeverCompanionUIState.previousQuestButton then if currentTab=="Quests" then ForeverCompanionUIState.previousQuestButton:Show() else ForeverCompanionUIState.previousQuestButton:Hide() end end
  if ForeverCompanionUIState.questFocusText then
    local q=ForeverCompanionQuestPlanner and ForeverCompanionQuestPlanner.GetSelected()
    ForeverCompanionUIState.questFocusText:SetText(currentTab=="Quests" and (q and ((ForeverCompanionQuestPlanner.IsPinned(q) and "[PIN] " or "").."Focused: "..clipText(q.title,37)) or "No quest selected") or "")
  end
end
-- One navigation path for the sidebar, dashboard shortcuts and slash commands.
-- Changes only the addon's current guide page, never the game quest log.
local function openSection(name)
  if type(name)~="string" then return false end
  local aliases={["home"]="Overview",["leveling route"]="Journey",["class guides"]="Leveling",["quest log"]="Quests",["alt leveling"]="Alts",["dungeons & raids"]="Dungeons",["dungeon journal"]="Dungeons",["gear & loot"]="Loot",["loot catalog"]="Loot",["pvp guide"]="PvP"}
  name=aliases[name:lower()] or name
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
lootMatches=function()
  return ForeverCompanionLoot and ForeverCompanionLoot.Filter(
    ForeverCompanionLootUI.query,ForeverCompanionLootUI.dungeon,
    ForeverCompanionLootUI.savedOnly,DB,ForeverCompanionLootUI.boss,ForeverCompanionLootUI.acquisition,ForeverCompanionLootUI.slot) or {}
end
local function resetLootFilters(query)
  ForeverCompanionLootWorkspace.SetScope(nil,nil,nil,query)
end
local function cyclePreviewClass()
  local token=classToken()
  for i,candidate in ipairs(classOrder) do
    if candidate==token then DB.previewClass=classOrder[(i % #classOrder)+1]; break end
  end
  DB.role=nil
  render()
end
local function cyclePreviewRole()
  local roles=classRoles[classToken()] or {"Damage"}
  local nextIndex=1
  for i,role in ipairs(roles) do
    if DB.role==role then nextIndex=(i % #roles)+1 end
  end
  DB.role=roles[nextIndex]
  render()
end
local function resetPreviewClass()
  DB.previewClass=nil
  DB.role=nil
  render()
end
local function toggleCompactMode()
  DB.compact=not DB.compact
  window:SetHeight(DB.compact and 620 or 720)
  fitWindow()
  ForeverCompanionUIState.compactButton:SetText(DB.compact and "Expand" or "Compact")
  render()
end
local function createUI()
  local template = BackdropTemplateMixin and "BackdropTemplate" or nil
  window = CreateFrame("Frame", "ForeverCompanionMainFrame", UIParent, template)
  window:SetSize(1080, DB.compact and 620 or 720)
  if type(DB.position)=="table" and type(DB.position.x)=="number" and type(DB.position.y)=="number" then
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
  if window.SetFrameStrata then window:SetFrameStrata("DIALOG") end
  window:SetClampedToScreen(true)
  fitWindow()
  if window.SetBackdrop then
    window:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", edgeSize=16, insets={left=5,right=5,top=5,bottom=5}})
  end
  -- Reference-inspired outer frame: gilded corner brackets and a recessed
  -- double-line border. Native textures keep the art crisp at UI scales.
  if ForeverCompanionOrnaments then
    ForeverCompanionOrnaments.Corners(window,1080,DB.compact and 620 or 720)
  end
  local frameTopInset=window:CreateTexture(nil,"BORDER")
  frameTopInset:SetPoint("TOPLEFT",window,"TOPLEFT",31,-7)
  frameTopInset:SetPoint("TOPRIGHT",window,"TOPRIGHT",-31,-7)
  frameTopInset:SetHeight(1)
  colorTexture(frameTopInset,0.58,0.39,0.17,0.78)
  local frameBottomInset=window:CreateTexture(nil,"BORDER")
  frameBottomInset:SetPoint("BOTTOMLEFT",window,"BOTTOMLEFT",31,7)
  frameBottomInset:SetPoint("BOTTOMRIGHT",window,"BOTTOMRIGHT",-31,7)
  frameBottomInset:SetHeight(1)
  colorTexture(frameBottomInset,0.58,0.39,0.17,0.78)
  ForeverCompanionUIState.background=window:CreateTexture(nil,"BACKGROUND")
  ForeverCompanionUIState.background:SetAllPoints(window)
  colorTexture(ForeverCompanionUIState.background,0.025,0.031,0.048,0.98)
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
  ForeverCompanionUIState.accentBar=window:CreateTexture(nil,"BORDER")
  ForeverCompanionUIState.accentBar:SetPoint("TOPLEFT",window,"TOPLEFT",12,-8)
  ForeverCompanionUIState.accentBar:SetPoint("TOPRIGHT",window,"TOPRIGHT",-12,-8)
  ForeverCompanionUIState.accentBar:SetHeight(3)
  colorTexture(ForeverCompanionUIState.accentBar,0.94,0.65,0.22,1)
  if ForeverCompanionOrnaments then ForeverCompanionOrnaments.Ribbon(window,1080,-94) end
  titleText = window:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  titleText:SetPoint("TOPLEFT", 86, -22)
  titleText:SetTextColor(1,0.79,0.36)
  if ForeverCompanionVisualTheme then ForeverCompanionVisualTheme.Font(titleText,30,true) end
  ForeverCompanionUIState.subtitleText=window:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
  ForeverCompanionUIState.subtitleText:SetPoint("TOPLEFT",86,-51)
  ForeverCompanionUIState.subtitleText:SetText("Guides  -  Professions  -  Quests  -  Builds  -  More")
  ForeverCompanionUIState.subtitleText:SetTextColor(0.72,0.78,0.84)
  if ForeverCompanionHeraldry then
    ForeverCompanionHeraldry.Create(window,13,-10,72)
  else
    local crest=window:CreateTexture(nil,"OVERLAY")
    crest:SetPoint("TOPLEFT",window,"TOPLEFT",19,-17)
    crest:SetSize(54,54)
    crest:SetTexture("Interface\\Icons\\INV_Misc_Book_09")
  end
  headerMeta=window:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
  headerMeta:SetPoint("TOPRIGHT",window,"TOPRIGHT",-48,-22)
  headerMeta:SetTextColor(0.94,0.78,0.47)
  ForeverCompanionUIState.questCountText=window:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
  ForeverCompanionUIState.questCountText:SetPoint("TOPRIGHT",-48,-43)
  ForeverCompanionUIState.questCountText:SetTextColor(0.70,0.85,0.74)
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
    "Interface\\Icons\\INV_Misc_Map_01",
    "Interface\\Icons\\INV_Misc_Book_09",
    "Interface\\Icons\\INV_Misc_Book_11",
    "Interface\\Icons\\INV_Misc_Map_01",
    "Interface\\Icons\\INV_Misc_Note_01",
    "Interface\\Icons\\INV_Weapon_ShortBlade_01",
    "Interface\\Icons\\INV_Chest_Chain_04",
    "Interface\\Icons\\Trade_BlackSmithing",
    "Interface\\Icons\\Ability_DualWield",
    "Interface\\Icons\\INV_Gizmo_02"
  }
  for i, section in ipairs(tabs) do
    local b = CreateFrame("Button", nil, window)
    b:SetSize(164, 31)
    b:SetPoint("TOPLEFT",window,"TOPLEFT",23,-138-(i-1)*34)
    b.section=section
    if ForeverCompanionOrnaments then ForeverCompanionOrnaments.Panel(b,164,31) end
    b.navBackground=b:CreateTexture(nil,"BACKGROUND")
    b.navBackground:SetAllPoints(b)
    colorTexture(b.navBackground,0.10,0.13,0.17,1)
    b.navAccent=b:CreateTexture(nil,"ARTWORK")
    b.navAccent:SetPoint("TOPLEFT",b,"TOPLEFT",0,0)
    b.navAccent:SetSize(3,31)
    colorTexture(b.navAccent,0.29,0.25,0.18,1)
    local icon=b:CreateTexture(nil,"ARTWORK")
    icon:SetPoint("LEFT",b,"LEFT",11,0)
    icon:SetSize(21,21)
    icon:SetTexture(navIcons[i])
    local underline=b:CreateTexture(nil,"ARTWORK")
    underline:SetPoint("BOTTOMLEFT",b,"BOTTOMLEFT",4,0)
    underline:SetSize(156,1)
    colorTexture(underline,0.42,0.35,0.24,0.7)
    b.navTop=b:CreateTexture(nil,"ARTWORK")
    b.navTop:SetPoint("TOPLEFT",b,"TOPLEFT",5,0)
    b.navTop:SetSize(154,1)
    colorTexture(b.navTop,0.48,0.36,0.21,0.65)
    b.navMarker=b:CreateTexture(nil,"OVERLAY")
    b.navMarker:SetPoint("RIGHT",b,"RIGHT",-8,0)
    b.navMarker:SetSize(5,13)
    colorTexture(b.navMarker,0.85,0.63,0.28,0)
    b.navGlow=b:CreateTexture(nil,"BORDER")
    b.navGlow:SetAllPoints(b)
    colorTexture(b.navGlow,0.08,0.18,0.36,0)
    b.navLabel=b:CreateFontString(nil,"OVERLAY","GameFontHighlight")
    b.navLabel:SetPoint("LEFT",b,"LEFT",40,0)
    local labels={Overview="Home",Journey="Leveling Route",Leveling="Class Guides",Quests="Quest Log",Alts="Alt Leveling",Dungeons="Dungeon Journal",Loot="Loot Catalog",PvP="PvP Guide"}
    b.navLabel:SetText(labels[section] or section)
    b.navLabel:SetWidth(116);b.navLabel:SetJustifyH("LEFT")
    if ForeverCompanionVisualTheme then ForeverCompanionVisualTheme.Font(b.navLabel,12) end
    b.navLabel:SetTextColor(0.88,0.87,0.83)
    b.navIcon=icon
    b:SetScript("OnEnter",function(self)
      if currentTab~=self.section then colorTexture(self.navBackground,0.18,0.17,0.14,1) end
    end)
    b:SetScript("OnLeave",function(self)
      if currentTab~=self.section then colorTexture(self.navBackground,0.050,0.067,0.100,1) end
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
  -- Only the fixed-size section heading receives ornamental framing;
  -- the reading area remains flexible in compact mode.
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
  if ForeverCompanionOrnaments then ForeverCompanionOrnaments.Corners(sectionHeader,846,48) end
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
  local professionNotes=CreateFrame("Button",nil,sectionHeader,"UIPanelButtonTemplate")
  professionNotes:SetSize(150,24)
  professionNotes:SetPoint("RIGHT",sectionHeader,"RIGHT",-12,0)
  professionNotes:SetScript("OnClick",function()
    ForeverCompanionUIState.showProfessionNotes=not ForeverCompanionUIState.showProfessionNotes
    render()
  end)
  ForeverCompanionUIState.professionNotesButton=professionNotes
  professionNotes:Hide()
  sectionHeader:Hide()
  scroll:SetPoint("BOTTOMRIGHT", -35, 92)
  local child = CreateFrame("Frame", nil, scroll)
  child:SetSize(790, 800)
  scrollChild = child
  scroll:SetScrollChild(child)
  if ForeverCompanionClassGuide then ForeverCompanionClassGuide.Create(child,openSection) end
  if ForeverCompanionRotationWorkspace then
    ForeverCompanionRotationWorkspace.Create(child,function(index) rotationMode=index;render() end)
  end
  if ForeverCompanionStudyBoard then ForeverCompanionStudyBoard.Create(child,openSection) end
  if ForeverCompanionEncounterBrowser then ForeverCompanionEncounterBrowser.Create(child,openSection,function() scroll:SetVerticalScroll(420) end) end
  if ForeverCompanionResearchNotebook then ForeverCompanionResearchNotebook.Create(child) end
  if ForeverCompanionJourney then ForeverCompanionJourney.Create(child,openSection) end
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
    ForeverCompanionDashboard.Create(window,openSection,{db=function() return DB end,class=classLabel,classToken=classToken,level=level})
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
        if ForeverCompanionUIState.compactButton then ForeverCompanionUIState.compactButton:SetText(DB.compact and "Expand" or "Compact") end
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
  rotationButton:SetScript("OnClick",function() rotationMode=(rotationMode % #rotationModes)+1; render() end)
  rotationButton:Hide()
  specButton=CreateFrame("Button",nil,window,"UIPanelButtonTemplate")
  specButton:SetSize(195,23)
  specButton:SetPoint("TOPRIGHT",window,"TOPRIGHT",-180,-62)
  specButton:SetScript("OnClick",function() ForeverCompanionSpecPlanner.Next(classToken()); render() end)
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

  ForeverCompanionLootWorkspace.Create(child,openSection,render)
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
  ForeverCompanionUIState.questFocusText=window:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
  ForeverCompanionUIState.questFocusText:SetPoint("BOTTOMLEFT",220,83)
  ForeverCompanionUIState.questFocusText:SetWidth(385)
  ForeverCompanionUIState.questFocusText:SetJustifyH("LEFT")
  ForeverCompanionUIState.nextQuestButton=CreateFrame("Button",nil,window,"UIPanelButtonTemplate")
  ForeverCompanionUIState.nextQuestButton:SetSize(118,25)
  ForeverCompanionUIState.nextQuestButton:SetPoint("BOTTOMRIGHT",-25,81)
  ForeverCompanionUIState.nextQuestButton:SetText("Next Quest")
  ForeverCompanionUIState.nextQuestButton:SetScript("OnClick",function() ForeverCompanionQuestPlanner.Next(); render() end)
  ForeverCompanionUIState.nextQuestButton:Hide()
  ForeverCompanionUIState.previousQuestButton=CreateFrame("Button",nil,window,"UIPanelButtonTemplate")
  ForeverCompanionUIState.previousQuestButton:SetSize(118,25)
  ForeverCompanionUIState.previousQuestButton:SetPoint("RIGHT",ForeverCompanionUIState.nextQuestButton,"LEFT",-5,0)
  ForeverCompanionUIState.previousQuestButton:SetText("Previous")
  ForeverCompanionUIState.previousQuestButton:SetScript("OnClick",function() ForeverCompanionQuestPlanner.Previous(); render() end)
  ForeverCompanionUIState.previousQuestButton:Hide()
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
    button:SetPoint("BOTTOMLEFT",window,"BOTTOMLEFT",214+(i-1)*92,17)
    button.classToken=token
    button.bg=button:CreateTexture(nil,"BACKGROUND")
    button.bg:SetAllPoints(button)
    colorTexture(button.bg,0.045,0.07,0.11,1)
    button.trim=button:CreateTexture(nil,"ARTWORK")
    button.trim:SetPoint("BOTTOMLEFT",button,"BOTTOMLEFT",0,0)
    button.trim:SetSize(89,2)
    colorTexture(button.trim,0.44,0.34,0.18,1)
    local name=button:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    name:SetPoint("LEFT",button,"LEFT",26,0)
    name:SetWidth(60);name:SetJustifyH("LEFT")
    if ForeverCompanionVisualTheme then ForeverCompanionVisualTheme.Font(name,10) end
    name:SetText(classNames[token])
    name:SetTextColor(0.95,0.83,0.60)
    local classIcon=button:CreateTexture(nil,"ARTWORK")
    classIcon:SetPoint("LEFT",button,"LEFT",4,0);classIcon:SetSize(19,19)
    ForeverCompanionIcons.ApplyClass(classIcon,token)
    button:SetScript("OnClick",function()
      DB.previewClass=token
      DB.role=nil
      render()
    end)
    button:Hide()
    ForeverCompanionClassStripButtons[i]=button
  end
  ForeverCompanionUIState.classButton = CreateFrame("Button", nil, window, "UIPanelButtonTemplate")
  ForeverCompanionUIState.classButton:SetSize(150, 26)
  ForeverCompanionUIState.classButton:SetPoint("BOTTOMRIGHT", -180, 45)
  ForeverCompanionUIState.classButton:SetScript("OnClick",cyclePreviewClass)
  resetClassButton=CreateFrame("Button",nil,window,"UIPanelButtonTemplate")
  resetClassButton:SetSize(92,23)
  resetClassButton:SetPoint("BOTTOMRIGHT",-125,16)
  resetClassButton:SetText("Auto Class")
  resetClassButton:SetScript("OnClick",resetPreviewClass)
  ForeverCompanionUIState.roleButton = CreateFrame("Button", nil, window, "UIPanelButtonTemplate")
  ForeverCompanionUIState.roleButton:SetSize(145, 26)
  ForeverCompanionUIState.roleButton:SetPoint("BOTTOMRIGHT", -25, 45)
  ForeverCompanionUIState.roleButton:SetScript("OnClick",cyclePreviewRole)
  ForeverCompanionUIState.compactButton=CreateFrame("Button",nil,window,"UIPanelButtonTemplate")
  ForeverCompanionUIState.compactButton:SetSize(92,23)
  ForeverCompanionUIState.compactButton:SetPoint("BOTTOMRIGHT",-25,16)
  ForeverCompanionUIState.compactButton:SetText(DB.compact and "Expand" or "Compact")
  ForeverCompanionUIState.compactButton:SetScript("OnClick",toggleCompactMode)
  local footer=window:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  ForeverCompanionUIState.footer=footer
  footer:SetPoint("BOTTOMLEFT", 20, 19)
  local versionLabel="v"..ForeverCompanionDiagnostics.Version().."  |  "
  footer:SetText(versionLabel.."/fc help  |  Read-only advisor  |  No gameplay automation")
  currentTab = DB.tab or "Overview"
  local validTab=false
  for _, section in ipairs(tabs) do if section==currentTab then validTab=true end end
  if not validTab then currentTab="Overview" end
  window:Hide()
  render()
end
for _,event in ipairs({"ADDON_LOADED","PLAYER_LEVEL_UP","PLAYER_ENTERING_WORLD","PLAYER_XP_UPDATE","SPELLS_CHANGED","SKILL_LINES_CHANGED","CHAT_MSG_SKILL","UI_SCALE_CHANGED","DISPLAY_SIZE_CHANGED"}) do
  pcall(function() addon:RegisterEvent(event) end)
end
addon:SetScript("OnEvent", function(_, event, arg)
  if event == "ADDON_LOADED" and arg == addonName then
    if type(ForeverCompanionDB)~="table" then ForeverCompanionDB={} end
    DB = ForeverCompanionDB
    if type(DB.checks)~="table" then DB.checks={} end
    for section,checks in pairs(DB.checks) do
      if type(checks)~="table" then DB.checks[section]=nil end
    end
    if type(DB.role)~="string" then DB.role=nil end
    if type(DB.professions)~="string" then DB.professions=nil end
    if type(DB.tab)~="string" then DB.tab="Overview" end
    createUI()
    if not DB.welcomed then DB.welcomed=true; window:Show() end
  elseif DB and (event == "UI_SCALE_CHANGED" or event == "DISPLAY_SIZE_CHANGED") then
    fitWindow()
    render()
  elseif DB and event == "SPELLS_CHANGED" then
    if window and window:IsShown() and currentTab=="Leveling" then render() end
  elseif DB and (event == "PLAYER_LEVEL_UP" or event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_XP_UPDATE" or event == "SKILL_LINES_CHANGED" or event == "CHAT_MSG_SKILL") then
    if window and window:IsShown() then render() end
  end
end)
SLASH_FOREVERCOMPANION1 = "/fc"
SLASH_FOREVERCOMPANION2 = "/forevercompanion"
SlashCmdList.FOREVERCOMPANION = function(msg)
  msg=(msg or ""):match("^%s*(.-)%s*$")
  if not DB then return end
  if msg == "" then if window:IsShown() then window:Hide() else render(); window:Show() end; return end
  if msg == "help" then say("/fc, /fc open <section>, /fc wish <item>, /fc loot <item|boss|dungeon>, /fc status, /fc class <name|auto>, /fc role <role>, /fc professions <names>, /fc check <section> <1-4>, /fc reset, /fc position reset, /fcq sync"); return end
  local wish=msg:match("^wish%s+(.+)$")
  if wish then
    if not ForeverCompanionLoot then say("Loot Atlas unavailable."); return end
    local record=ForeverCompanionLoot.Find(wish)
    if not record then say("Item not found in the sourced loot catalog."); return end
    local added=ForeverCompanionLoot.ToggleWish(DB,record.item)
    say((added and "Wishlisted: " or "Removed from wishlist: ")..record.item)
    resetLootFilters(record.item); openSection("Loot"); window:Show(); return
  end
  local lootQuery=msg:match("^loot%s+(.+)$")
  if lootQuery then
    if not ForeverCompanionLoot then say("Loot Atlas unavailable."); return end
    lootQuery=lootQuery:sub(1,80)
    local matches=ForeverCompanionLoot.Search(lootQuery)
    say("Loot search: "..#matches.." match(es).")
    for i=1,math.min(#matches,8) do
      local item=matches[i]
      say(item.item.." — "..item.boss.." / "..item.dungeon.." ["..item.status.."]")
    end
    resetLootFilters(lootQuery); openSection("Loot"); window:Show(); return
  end
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

ForeverCompanionRefresh = function() if DB and window and window:IsShown() then render() end end


