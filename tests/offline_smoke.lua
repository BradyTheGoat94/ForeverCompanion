-- Offline smoke tests with mocked WoW APIs. Run: lua5.1 tests/offline_smoke.lua
local function assertEqual(actual,expected,label)
 if actual~=expected then error(label..": expected "..tostring(expected)..", got "..tostring(actual),2) end
end
local output={}
print=function(message) output[#output+1]=tostring(message) end
SlashCmdList={}
CreateFrame=function() return {RegisterEvent=function() end,SetScript=function() end} end
ForeverCompanionDB={}
C_SpellBook={
 GetNumSpellBookSkillLines=function() return 1 end,
 GetSpellBookSkillLineInfo=function(index) return {itemIndexOffset=0,numSpellBookItems=2} end,
 GetSpellBookItemName=function(index,bank) if index==1 then return "Shield Wall" elseif index==2 then return "Charge" end end,
}
Enum={SpellBookSpellBank={Player=1}}
dofile("ForeverCompanion/Spellbook.lua")
local scan=ForeverCompanionSpellbook.Scan()
assertEqual(scan.supported,true,"spellbook supported")
assertEqual(scan.inspected,2,"spell count")
assertEqual(ForeverCompanionSpellbook.Status("Shield Wall",scan),"found in spellbook","known spell")
assertEqual(ForeverCompanionSpellbook.Status("Unknown",scan),"not found in scanned spellbook (not proof of unavailable)","unknown spell")
C_SpellBook.GetSpellBookItemName=function(i) if i==1 then return "Shield Wall" end error("simulated API failure") end
local partial=ForeverCompanionSpellbook.Scan()
assertEqual(partial.complete,false,"partial spellbook scan")
assertEqual(ForeverCompanionSpellbook.Status("Unknown",partial),"unverified (partial scan)","unknown in partial scan")
C_SpellBook.GetNumSpellBookSkillLines=function() return 100000 end
assertEqual(ForeverCompanionSpellbook.Scan().supported,false,"reject invalid spellbook tab count")
C_SpellBook=nil
assertEqual(ForeverCompanionSpellbook.Scan().supported,false,"missing API")
dofile("ForeverCompanion/CraftingPlanner.lua")
dofile("ForeverCompanion/RecipePlans.lua")
dofile("ForeverCompanion/CraftingBridge.lua")
local recipes=ForeverCompanionRecipePlans
local mats=ForeverCompanionCraftingPlanner
local bridge=ForeverCompanionCraftingBridge
assert(recipes.Add("Alchemy","Potion A",3))
assert(recipes.Ingredient("Alchemy",1,"Herb",2))
assert(recipes.Add("Alchemy","Potion B",2))
assert(recipes.Ingredient("Alchemy",2,"herb",3))
assert(recipes.Done("Alchemy",1,1))
assertEqual(bridge.Demand("Alchemy").herb.needed,10,"aggregate demand")
assert(mats.Add("Alchemy","HERB",1,4))
assert(mats.Add("Alchemy","Unrelated",5,2))
local before=bridge.Preview("Alchemy")
assertEqual(mats.GetEntries("Alchemy")[1].needed,1,"preview is read only")
assert(before:find("6 missing",1,true),"shortage should be six")
assert(bridge.Sync("Alchemy"))
assertEqual(mats.GetEntries("Alchemy")[1].needed,10,"sync demand")
assertEqual(mats.GetEntries("Alchemy")[1].owned,4,"preserve owned")
assertEqual(mats.GetEntries("Alchemy")[2].needed,5,"preserve unrelated")
assert(recipes.Add("Alchemy","Potion C",1))
assert(recipes.Ingredient("Alchemy",3,"Crystal",2))
assert(bridge.Sync("Alchemy"))
assertEqual(#mats.GetEntries("Alchemy"),3,"add new ingredient")
assertEqual(mats.GetEntries("Alchemy")[3].owned,0,"new ingredient owned")
local shortages=mats.TopShortages(2)
assertEqual(#shortages,2,"top shortage limit")
assertEqual(shortages[1].name,"HERB","largest manual shortage first")
assertEqual(shortages[1].missing,6,"manual shortage quantity")
assertEqual(shortages[2].name,"Unrelated","second largest manual shortage")
assert(mats.ShoppingSummary(2):find("Alchemy: HERB x6",1,true),"manual shopping summary must name the material")
local originalMaterials=ForeverCompanionDB.materials
ForeverCompanionDB.materials={Broken={{name="Bad",needed="oops",owned=0}}}
assertEqual(#mats.TopShortages(),0,"invalid saved material counts must be ignored")
ForeverCompanionDB.materials=originalMaterials
dofile("ForeverCompanion/Diagnostics.lua")
local report=ForeverCompanionDiagnostics.Collect()
assert(report:find("Client: unknown",1,true),"diagnostics should tolerate missing client APIs")

-- Modern quest log compatibility and transient failure preservation.
C_QuestLog={
 GetNumQuestLogEntries=function() return 2 end,
 GetInfo=function(i)
  if i==1 then return {isHeader=true,title="Test Zone"} end
  return {questID=42,title="Sample Quest",isComplete=false}
 end,
 IsComplete=function() return true end,
 GetQuestObjectives=function() return {{text="Collect 3 samples",finished=true}} end,
}
dofile("ForeverCompanion/QuestPlanner.lua")
assertEqual(ForeverCompanionQuestPlanner.Sync(),true,"quest scan")
assertEqual(ForeverCompanionQuestPlanner.AutoCount(),1,"quest count")
assertEqual(ForeverCompanionQuestPlanner.ReadyCount(),1,"quest completion")
local objectiveDone,objectiveKnown=ForeverCompanionQuestPlanner.ObjectiveProgress()
assertEqual(objectiveDone,1,"modern objective completion")
assertEqual(objectiveKnown,1,"modern objective known count")
assertEqual(ForeverCompanionQuestPlanner.Overview().remaining,0,"quest summary remaining")
assertEqual(ForeverCompanionQuestPlanner.Overview().zones[1].zone,"Test Zone","quest zone summary")
assert(ForeverCompanionQuestPlanner.FormatOverview():find("1 active",1,true),"quest overview should show live totals")
assertEqual(ForeverCompanionQuestPlanner.GetSort(),"zone","default quest sort")
local planner=ForeverCompanionQuestPlanner
assertEqual(planner.PinnedCount(),0,"initial pinned count")
local pinnedOK=planner.TogglePin(1)
assertEqual(pinnedOK,true,"pin first live quest")
assertEqual(planner.IsPinned(planner.GetLive()[1]),true,"pin saved by quest ID")
assertEqual(planner.PinnedCount(),1,"active pin count")
assertEqual(planner.Overview().pinned,1,"overview pin count")
assertEqual(planner.Sync(),true,"rescan while pinned")
assertEqual(planner.IsPinned(planner.GetLive()[1]),true,"pin survives rescan")
assertEqual(planner.TogglePin(0),false,"invalid pin index")
assertEqual(planner.TogglePin(1),true,"unpin first quest")
assertEqual(planner.PinnedCount(),0,"unpin clears active priority")
assertEqual(planner.TogglePin(1),true,"re-pin before cleanup")
SlashCmdList.FOREVERCOMPANIONQUEST("clearpins")
assertEqual(planner.PinnedCount(),0,"clearpins must remove stored addon priorities")
SlashCmdList.FOREVERCOMPANIONQUEST("sort")
assertEqual(ForeverCompanionQuestPlanner.GetSort(),"ready","slash quest sort")
C_QuestLog.GetNumQuestLogEntries=function() error("simulated temporary failure") end
assertEqual(ForeverCompanionQuestPlanner.Sync(),false,"failed quest scan")
assertEqual(ForeverCompanionQuestPlanner.AutoCount(),1,"last successful snapshot retained")
assertEqual(ForeverCompanionQuestPlanner.IsSnapshotStale(),true,"stale state")
assert(ForeverCompanionQuestPlanner.FormatOverview():find("outdated",1,true),"stale quest overview warning missing")
C_QuestLog=nil
assertEqual(ForeverCompanionQuestPlanner.Sync(),false,"unsupported quest API")
assertEqual(ForeverCompanionQuestPlanner.AutoCount(),1,"unsupported API snapshot retained")
-- Legacy Classic quest log: headings, completion and objectives are read-only.
GetNumQuestLogEntries=function() return 2,1 end
GetQuestLogTitle=function(index)
 if index==1 then return "Westfall",nil,nil,true end
 return "Collect 5 apples",10,0,false,false,1,nil,77
end
GetNumQuestLeaderBoards=function(index) return index==2 and 1 or 0 end
GetQuestLogLeaderBoard=function() return "Apples: 5/5","item",true end
assertEqual(ForeverCompanionQuestPlanner.Sync(),true,"legacy quest scan")
assertEqual(ForeverCompanionQuestPlanner.AutoCount(),1,"legacy quest count")
assertEqual(ForeverCompanionQuestPlanner.ReadyCount(),1,"legacy ready status")
assertEqual(ForeverCompanionQuestPlanner.GetLive()[1].zone,"Westfall","legacy zone heading")
assertEqual(ForeverCompanionQuestPlanner.GetLive()[1].objectives[1],"Apples: 5/5","legacy objectives")
local classicDone,classicKnown=ForeverCompanionQuestPlanner.ObjectiveProgress()
assertEqual(classicDone,1,"legacy objective completion")
assertEqual(classicKnown,1,"legacy objective known count")
GetRealZoneText=function() error("restricted zone API") end
GetZoneText=function() return "Westfall" end
ForeverCompanionQuestPlanner.CycleFilter() -- ready
ForeverCompanionQuestPlanner.CycleFilter() -- current zone
assertEqual(ForeverCompanionQuestPlanner.GetFilter(),"zone","zone filter selected")
local zoneOk,visible=pcall(ForeverCompanionQuestPlanner.GetVisible)
assert(zoneOk and #visible==1,"zone filter must survive restricted primary zone API")
ForeverCompanionQuestPlanner.CycleFilter() -- all
GetRealZoneText=nil
GetZoneText=nil
GetNumQuestLogEntries=function() error("simulated legacy API outage") end
assertEqual(ForeverCompanionQuestPlanner.Sync(),false,"legacy scan outage")
assertEqual(ForeverCompanionQuestPlanner.IsSnapshotStale(),true,"legacy cached snapshot stale")
-- Zone-less modern quests must not be mislabeled as the placeholder "Quest log".
-- The current-zone filter should preserve unknown-zone quests rather than hide them.
C_QuestLog={
 GetNumQuestLogEntries=function() return 2 end,
 GetInfo=function(i)
  if i==1 then return {questID=91,title="Quest with unknown zone"} end
  return {questID=92,title="Westfall quest",zoneName="Westfall"}
 end,
}
GetZoneText=function() return "Westfall" end
assertEqual(ForeverCompanionQuestPlanner.Sync(),true,"mixed-zone quest scan")
assertEqual(ForeverCompanionQuestPlanner.HasZoneMetadata(),true,"mixed zone metadata")
local pinnedOK2=ForeverCompanionQuestPlanner.TogglePin(2)
assertEqual(pinnedOK2,true,"pin second quest in mixed-zone fixture")
ForeverCompanionDB.questSort="pinned"
assertEqual(ForeverCompanionQuestPlanner.GetVisible()[1].index,2,"pinned sort must prioritize pinned quest")
assert(ForeverCompanionQuestPlanner.Recommend():find("Pinned priority:",1,true),"pinned quest should be recommended when nothing ready")
assertEqual(ForeverCompanionQuestPlanner.TogglePin(2),true,"unpin mixed-zone fixture")
ForeverCompanionDB.questSort="zone"
assertEqual(ForeverCompanionQuestPlanner.GetLive()[1].zone,"Unspecified zone","missing zone must not be fabricated")
ForeverCompanionQuestPlanner.CycleFilter() -- all -> ready
ForeverCompanionQuestPlanner.CycleFilter() -- ready -> zone
assertEqual(ForeverCompanionQuestPlanner.GetFilter(),"zone","mixed-zone filter")
assertEqual(#ForeverCompanionQuestPlanner.GetVisible(),2,"unknown-zone quest should stay visible")
C_QuestLog.GetNumQuestLogEntries=function() return 1 end
assertEqual(ForeverCompanionQuestPlanner.Sync(),true,"zone-less quest scan")
assertEqual(ForeverCompanionQuestPlanner.HasZoneMetadata(),false,"zone-less quest should not report metadata")
assertEqual(#ForeverCompanionQuestPlanner.GetVisible(),1,"active zone filter should not hide zone-less quests")
assertEqual(ForeverCompanionQuestPlanner.Overview().zones[1].zone,"Unspecified zone","zone overview must be honest")
ForeverCompanionQuestPlanner.CycleFilter() -- zone -> all
ForeverCompanionQuestPlanner.CycleFilter() -- all -> ready
ForeverCompanionQuestPlanner.CycleFilter() -- ready -> all (skip zone without metadata)
assertEqual(ForeverCompanionQuestPlanner.GetFilter(),"all","zone filter skipped when no metadata")
C_QuestLog=nil
GetZoneText=nil
-- Class planning references should be substantial and distinct, not duplicated filler.
dofile("ForeverCompanion/AdvancedGuides.lua")
local distinct={}
local classCount=0
for class,guide in pairs(ForeverCompanionAdvanced.classes) do
  classCount=classCount+1
  assert(#guide.sections>=7,"class guide needs actionable reference details: "..class)
  assert(not distinct[guide.sections[1]],"duplicated first class guide tip")
  distinct[guide.sections[1]]=true
end
assertEqual(classCount,9,"original class guide coverage")
local craftCount=0
local craftFirst={}
for name,guide in pairs(ForeverCompanionAdvanced.crafting) do
  craftCount=craftCount+1
  assert(#guide.stages>=6,"profession reference needs detailed planning steps: "..name)
  assert(not craftFirst[guide.stages[1]],"duplicated profession advice")
  craftFirst[guide.stages[1]]=true
end
assertEqual(craftCount,9,"profession handbook coverage")
-- Adventure preparation progress is manual, deterministic, and never a claim
-- about actual dungeon/PvP readiness.
dofile("ForeverCompanion/AdventureBriefing.lua")
local adventure=ForeverCompanionAdventureBriefing
local tasks={"Confirm group","Review objectives","Plan cooldowns"}
local summary=adventure.Summary(tasks,{[1]=true,[3]=true})
assertEqual(summary.total,3,"adventure checklist total")
assertEqual(summary.done,2,"adventure checklist completed")
assertEqual(summary.nextTask,"Review objectives","adventure next unfinished task")
local finished=adventure.Summary(tasks,{true,true,true})
assertEqual(finished.nextTask,nil,"finished checklist has no next task")
local missing=adventure.Summary(nil,"corrupted saved checks")
assertEqual(missing.total,0,"missing checklist should not invent progress")
assertEqual(missing.done,0,"invalid checks must not create completion")

-- Settings compatibility report must distinguish exposed APIs from verified support.
dofile("ForeverCompanion/SettingsBriefing.lua")
local settings=ForeverCompanionSettingsBriefing
local noApis=settings.Capabilities(nil)
assertEqual(noApis.quests,false,"settings nil quest API")
assertEqual(noApis.professions,false,"settings nil profession API")
assertEqual(noApis.xp,false,"settings nil XP API")
assertEqual(noApis.spellbook,false,"settings nil spellbook API")
local mixed=settings.Capabilities({legacyQuests=true,modernProfessions=true,xp=true,legacySpellbook=true})
assertEqual(mixed.quests,true,"settings legacy quest detection")
assertEqual(mixed.professions,true,"settings modern profession detection")
assertEqual(mixed.xp,true,"settings XP API detection")
assertEqual(mixed.spellbook,true,"settings legacy spellbook detection")
assertEqual(settings.Capabilities({modernQuests=1}).quests,false,"nonboolean API flag must not be treated as verified")

-- Spec selection remains a manual preview; it must never query or change talents.
dofile("ForeverCompanion/SpecPlanner.lua")
local first=ForeverCompanionSpecPlanner.Get("WARRIOR")
assertEqual(first[1],"Arms","default spec preview")
ForeverCompanionSpecPlanner.Next("WARRIOR")
local second=ForeverCompanionSpecPlanner.Get("WARRIOR")
assertEqual(second[1],"Fury","next spec preview")

-- Profession scanner returns guarded, read-only skill information.
GetProfessions=function() return 1,nil,nil,nil,nil end
GetProfessionInfo=function(index) return "Alchemy",nil,125,225 end
dofile("ForeverCompanion/ProfessionScanner.lua")
local professions=ForeverCompanionProfessionScanner.Read()
assertEqual(professions[1].name,"Alchemy","profession name")
assertEqual(professions[1].skill,125,"profession skill")
dofile("ForeverCompanion/ProfessionProgress.lua")
local professionOverview=ForeverCompanionProfessionProgress.Overview()
assertEqual(professionOverview[1].remaining,100,"profession skill to cap")
assertEqual(professionOverview[1].percent,56,"profession progress percentage rounds correctly")
assert(ForeverCompanionProfessionProgress.FormatOverview():find("100 skill to current cap",1,true),"profession progress summary missing")
-- Invalid and partial profession records must not produce fabricated progress.
local originalRead=ForeverCompanionProfessionScanner.Read
ForeverCompanionProfessionScanner.Read=function()
 return {{name="Broken",skill=-4,maxSkill=0},{name="Partial",skill=40,maxSkill=0},{name="NaN",skill=0/0,maxSkill=200},{name="Valid",skill=25,maxSkill=75}}
end
local guarded=ForeverCompanionProfessionProgress.Overview()
assertEqual(guarded[1].skill,nil,"negative skill should be unknown")
assertEqual(guarded[1].remaining,nil,"invalid skill and cap cannot have remaining")
assertEqual(guarded[2].maximum,nil,"zero cap should be unknown")
assertEqual(guarded[2].remaining,nil,"missing cap cannot have remaining")
assertEqual(guarded[3].skill,nil,"NaN skill should be unknown")
assertEqual(guarded[4].remaining,50,"valid skill progress remains accurate")
assertEqual(guarded[4].percent,33,"valid profession percentage")
assertEqual(guarded[1].percent,nil,"unknown skill percentage must remain unavailable")
assertEqual(guarded[1].name,"Broken","valid profession names preserved")
ForeverCompanionProfessionScanner.Read=function() return {{skill=20,maxSkill=75}} end
local unnamed=ForeverCompanionProfessionProgress.Overview()
assertEqual(unnamed[1].name,"Unknown profession","missing profession name uses safe label")
ForeverCompanionProfessionScanner.Read=function() error("Client API exception") end
local failed,why=ForeverCompanionProfessionProgress.Overview()
assertEqual(failed,nil,"exceptional profession API must not crash overview")
assert(type(why)=="string","exceptional profession API must explain unavailable state")
assert(ForeverCompanionProfessionProgress.ForProfession("Alchemy"):find("unavailable",1,true),"profession guide handles API exception")
ForeverCompanionProfessionScanner.Read=function() return {{name="Alchemy",skill=0/0,maxSkill=225}} end
assert(ForeverCompanionProfessionProgress.ForProfession("Alchemy"):find("skill level unavailable",1,true),"invalid skill should not be shown as valid")
ForeverCompanionProfessionScanner.Read=originalRead
-- Sparse modern profession slots must not disappear after the first nil.
GetProfessions=function() return 1,nil,3,nil,5 end
GetProfessionInfo=function(index)
 if index==1 then return "Alchemy",nil,125,225 end
 if index==3 then return "Mining",nil,175,225 end
 if index==5 then return "Cooking",nil,75,150 end
end
local sparse=ForeverCompanionProfessionScanner.Read()
assertEqual(#sparse,3,"sparse modern profession slots")
assertEqual(sparse[3].name,"Cooking","fifth profession slot")
-- Classic-era fallback reads the general skill lines without changing selection.
GetProfessions=nil
GetProfessionInfo=nil
GetNumSkillLines=function() return 4 end
GetSkillLineInfo=function(index)
 if index==1 then return "Professions",true,false,0,0,0,0 end
 if index==2 then return "Mining",false,false,175,0,0,225 end
 if index==3 then return "Swords",false,false,200,0,0,300 end
 return "Cooking",false,false,95,0,0,150
end
local classic=ForeverCompanionProfessionScanner.Read()
assertEqual(#classic,2,"Classic profession detection excludes weapon skills")
assertEqual(classic[1].name,"Mining","Classic first trade skill")
assertEqual(classic[1].skill,175,"Classic skill rank")
assertEqual(classic[1].maxSkill,225,"Classic skill cap")
assert(ForeverCompanionProfessionScanner.Format():find("Classic skill-line fallback",1,true),"Classic fallback disclosure")
GetNumSkillLines=function() error("restricted skill-line API") end
local restricted,restrictedReason=ForeverCompanionProfessionScanner.Read()
assertEqual(restricted,nil,"restricted legacy profession read")
assert(type(restrictedReason)=="string","legacy error must have reason")
GetNumSkillLines=nil
GetSkillLineInfo=nil
GetProfessions=function() error("unavailable") end
local missing,reason=ForeverCompanionProfessionScanner.Read()
assertEqual(missing,nil,"failed profession read")
assert(type(reason)=="string","missing API reason")
assert(ForeverCompanionProfessionProgress.FormatOverview():find("unavailable",1,true),"profession API failure needs honest fallback")
io.write("PASS: offline spellbook, crafting, diagnostics, quests, specs and professions\n")

-- Client-data spell reference: level gates, talent and quest caveats, and
-- explicit pending coverage for classes not yet individually audited.
dofile("ForeverCompanion/VerifiedAbilities.lua")
local warriorLow=table.concat(ForeverCompanionAbilityReferenceLines("WARRIOR",10),"\n")
local warriorHigh=table.concat(ForeverCompanionAbilityReferenceLines("WARRIOR",40),"\n")
assert(warriorLow:find("Bloodthirst",1,true) and warriorLow:find("LOCKED BY LEVEL",1,true),"level-10 reference should gate late abilities")
assert(warriorHigh:find("Talent investment required",1,true),"talent abilities must not be presented as automatically learned")
assert(warriorHigh:find("Quest completion required",1,true),"quest abilities must retain quest requirement")
assert(table.concat(ForeverCompanionAbilityReferenceLines("MAGE",40)," "):find("pending",1,true),"unaudited classes must not claim verification")

-- Ownership must never be inferred from level, and API restrictions must be safe.
local previousIsSpellKnown=IsSpellKnown
IsSpellKnown=function(id) return id==23881 end
local known=table.concat(ForeverCompanionAbilityReferenceLines("WARRIOR",40),"\n")
assert(known:find("KNOWN IN SPELLBOOK",1,true),"known spell should be labeled")
assert(known:find("NOT KNOWN",1,true),"missing spell should be labeled")
IsSpellKnown=function() error("restricted client API") end
assert(table.concat(ForeverCompanionAbilityReferenceLines("WARRIOR",40),"\n"):find("SPELLBOOK STATUS UNKNOWN",1,true),"restricted API must not invent spell ownership")
IsSpellKnown=previousIsSpellKnown

local audit=ForeverCompanionAbilityAudit()
assert(audit.total==12,"reference audit should count the current curated spell entries")
assert(audit.classes.WARRIOR==12 and audit.classes.MAGE==0,"coverage must distinguish audited and unaudited classes")
assert(#audit.issues==0,"curated spell records must pass integrity validation")

-- Spell availability is a distinct state machine, never inferred from level.
local oldKnown=IsSpellKnown
IsSpellKnown=function(id) return id==23881 end
assert(ForeverCompanionAbilityState("WARRIOR",23881,20)=="LEVEL LOCKED","talent cannot bypass level gate")
assert(ForeverCompanionAbilityState("WARRIOR",23881,40)=="KNOWN","trained talent should resolve as known")
assert(ForeverCompanionAbilityState("WARRIOR",2458,40)=="QUEST UNLEARNED","quest ability needs its unlock")
assert(ForeverCompanionAbilityState("WARRIOR",12296,40)=="TALENT UNLEARNED","talent is not automatically awarded")
assert(ForeverCompanionAbilityState("WARRIOR",676,40)=="NOT LEARNED","trainer ability must be known")
assert(ForeverCompanionAbilityState("WARRIOR",999999,40)=="NOT AUDITED","unknown spell is not audited")
assert(ForeverCompanionAbilityState("MAGE",1,40)=="UNAUDITED","pending class must not be verified")
assert(ForeverCompanionAvailableAbilitySummary("WARRIOR",40):find("1 known",1,true),"summary must count known spells")
IsSpellKnown=oldKnown
