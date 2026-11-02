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
C_SpellBook.GetSpellBookItemName=function(i) if i==1 then return "Shield Wall" end return nil end
local unnamed=ForeverCompanionSpellbook.Scan()
assertEqual(unnamed.complete,false,"unnamed spellbook entry must make scan partial")
assertEqual(ForeverCompanionSpellbook.Status("Unknown",unnamed),"unverified (partial scan)","unnamed slot cannot prove absence")
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
-- Malformed SavedVariables must not crash manual quest tracking.
ForeverCompanionDB.quests={{name="Valid Quest",zone="Westfall",done=false},{name=false,zone=12}}
assertEqual(ForeverCompanionQuestPlanner.Add("Another Quest","Westfall"),true,"add with malformed saved row")
assertEqual(ForeverCompanionQuestPlanner.Toggle(2),false,"reject invalid saved quest toggle")
assert(ForeverCompanionQuestPlanner.Format():find("invalid saved quest entry",1,true),"show invalid saved row")
assertEqual(ForeverCompanionQuestPlanner.Remove(2),true,"remove malformed saved quest")
assertEqual(ForeverCompanionQuestPlanner.Summary(),0,"valid entries remain unfinished")
ForeverCompanionDB.quests={}
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
-- Sixth profession slot must be retained, even when earlier slots are nil.
GetProfessions=function() return nil,nil,nil,nil,nil,6 end
GetProfessionInfo=function(index)
 if index==6 then return "Fishing",nil,100,150 end
end
local sixth=ForeverCompanionProfessionScanner.Read()
assertEqual(#sixth,1,"sixth modern profession slot")
assertEqual(sixth[1].name,"Fishing","sixth profession slot name")
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
assert(table.concat(ForeverCompanionAbilityReferenceLines("PRIEST",40)," "):find("pending",1,true),"unaudited classes must not claim verification")

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
assert(audit.total==14,"reference audit should count the current curated spell entries")
assert(audit.classes.WARRIOR==12 and audit.classes.MAGE==2 and audit.classes.PRIEST==0,"coverage must distinguish curated and unaudited classes")
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
assert(ForeverCompanionAbilityState("PRIEST",1,40)=="UNAUDITED","pending class must not be verified")
assert(ForeverCompanionAvailableAbilitySummary("WARRIOR",40):find("1 known",1,true),"summary must count known spells")
IsSpellKnown=oldKnown

-- Crafting forecast merges repeated ingredients across recipes and subtracts
-- only manually recorded owned quantities, never imaginary bag contents.
local recipe=ForeverCompanionRecipePlans
local material=ForeverCompanionCraftingPlanner
assert(recipe.Add("ForecastTest","Potion",3))
assert(recipe.Ingredient("ForecastTest",1,"Silverleaf",2))
assert(recipe.Add("ForecastTest","Elixir",2))
assert(recipe.Ingredient("ForecastTest",2,"Silverleaf",3))
assert(recipe.Ingredient("ForecastTest",2,"Peacebloom",1))
assert(material.Add("ForecastTest","Silverleaf",12,4))
local forecast=recipe.MaterialForecast("ForecastTest")
assert(forecast[1].name=="Silverleaf" and forecast[1].required==12 and forecast[1].owned==4 and forecast[1].shortage==8,"merged ingredient shortage incorrect")
assert(recipe.Done("ForecastTest",1,2))
local revised=recipe.MaterialForecast("ForecastTest")
assert(revised[1].required==8 and revised[1].shortage==4,"completed crafts must reduce future demand")
assert(recipe.FormatForecast("ForecastTest"):find("MANUAL INVENTORY",1,true),"forecast must disclose manual quantities")

-- Profession and skill guides must remain deterministic and read-only.
dofile("ForeverCompanion/CraftingAdvice.lua")
local advice=ForeverCompanionCraftingAdvice.Plan("ForecastTest")
assert(advice.ready==1 and advice.blocked==1,"recipe readiness must distinguish craftable and missing materials")
assert(ForeverCompanionCraftingAdvice.Format("ForecastTest"):find("shared materials",1,true),"shared materials caveat required")
dofile("ForeverCompanion/SkillStudy.lua")
local priorKnown=IsSpellKnown
IsSpellKnown=function(id) return id==23881 end
local skillLines=ForeverCompanionSkillStudy.Format("WARRIOR",20)
assert(skillLines:find("UPCOMING UNLOCKS",1,true),"skill guide must show upcoming abilities")
assert(skillLines:find("CHECK TRAINER",1,true),"skill guide must show missing spells")
assert(ForeverCompanionSkillStudy.Format("PRIEST",20):find("No audited",1,true),"unaudited classes must not imply verified abilities")
IsSpellKnown=priorKnown

-- Shared material allocation is conservative across multiple recipes.
local allocation=ForeverCompanionCraftingAdvice.Allocation("ForecastTest")
assert(allocation[1].craftable==1 and allocation[2].craftable==0,"recipe queue must not double-spend Silverleaf")
assert(ForeverCompanionCraftingAdvice.FormatAllocation("ForecastTest"):find("SHARED MATERIALS",1,true),"queue must explain reservation")
local savedKnown=IsSpellKnown
IsSpellKnown=function() return false end
local nextSkills=ForeverCompanionSkillStudy.NextActions("WARRIOR",40,3)
assert(#nextSkills<=3 and #nextSkills>0,"next skill checklist must be bounded")
assert(ForeverCompanionSkillStudy.FormatNextActions("PRIEST",40):find("pending class",1,true),"unverified classes need honest fallback")
IsSpellKnown=savedKnown

-- Recipe ordering changes how scarce shared materials are allocated.
assert(ForeverCompanionCraftingPlanner.Add("ForecastTest","Peacebloom",2,1),"add the second ingredient required by Elixir")
local before=ForeverCompanionCraftingAdvice.Allocation("ForecastTest")
assert(before[1].craftable==1 and before[2].craftable==0,"initial recipe priority incorrect")
assert(ForeverCompanionRecipePlans.Move("ForecastTest",2,1),"recipe priority change should succeed")
local after=ForeverCompanionCraftingAdvice.Allocation("ForecastTest")
assert(after[1].name=="Elixir" and after[1].craftable==1 and after[2].craftable==0,"priority reorder must reserve inventory for first recipe")
assert(not ForeverCompanionRecipePlans.Move("ForecastTest",1,99),"out-of-range recipe move must fail")
local gather=ForeverCompanionCraftingAdvice.GatherList("ForecastTest")
assert(#gather>0 and gather[1].shortage>0,"gather list must include shortages")
assert(ForeverCompanionCraftingAdvice.FormatGatherList("ForecastTest",1):find("GATHER NEXT",1,true),"gather summary missing")

local professionAdvice=ForeverCompanionProfessionProgress
assert(professionAdvice.FormatNextSteps(75,75):find("cap reached",1,true),"profession cap should trigger trainer check")
assert(professionAdvice.FormatNextSteps(50,75):find("skill-up color",1,true),"profession progression should require live recipe color")
local previousSpellKnown=IsSpellKnown
IsSpellKnown=function(id) return id==23881 end
assert(ForeverCompanionSkillStudy.PracticePlan("WARRIOR",40):find("Bloodthirst",1,true),"practice plan must include known audited spells")
assert(ForeverCompanionSkillStudy.PracticePlan("PRIEST",40):find("No audited",1,true),"unaudited class must be disclosed")
IsSpellKnown=previousSpellKnown

-- Editing goals must immediately propagate to material forecasts.
assert(ForeverCompanionRecipePlans.SetQuantity("ForecastTest",1,4),"recipe target should be editable")
assert(ForeverCompanionRecipePlans.SetIngredient("ForecastTest",1,1,2),"ingredient amounts should be editable")
assert(ForeverCompanionRecipePlans.MaterialForecast("ForecastTest")[1].shortage>=0,"forecast should remain valid after edits")
assert(not ForeverCompanionRecipePlans.SetQuantity("ForecastTest",1,0),"zero target must be rejected")
assert(not ForeverCompanionRecipePlans.SetIngredient("ForecastTest",1,99,2),"missing ingredient must be rejected")
assert(ForeverCompanionRecipePlans.RemoveIngredient("ForecastTest",1,2),"ingredient should be removable")
assert(ForeverCompanionRecipePlans.Format("ForecastTest"):find("setingredient",1,true),"guide should document editing")

dofile("ForeverCompanion/SkillDiscovery.lua")
local discovery=ForeverCompanionSkillDiscovery
local found=discovery.Find({"Frostbolt","Fireball","Blink"},{supported=true,complete=true,inspected=2,known={frostbolt=true,fireball=true}})
assert(found[1].state=="IN SPELLBOOK" and found[3].state=="NOT IN SCANNED SPELLBOOK","complete spellbook scan should distinguish present and absent")
local partial=discovery.Find({"Blink"},{supported=true,complete=false,inspected=1,known={}})
assert(partial[1].state=="UNCONFIRMED","partial scan cannot prove absence")
assert(discovery.Find({"Blink"},{supported=false,complete=false,inspected=0,known={}})[1].state=="UNCONFIRMED","unsupported scan cannot prove absence")

local ready=ForeverCompanionSkillDiscovery.Summary("WARRIOR",{supported=false,complete=false,inspected=0,known={}})
assert(ready.known==0 and ready.notScanned==0,"unsupported spellbook must not imply missing skills")
local checklist=ForeverCompanionSkillDiscovery.Checklist("WARRIOR",{supported=false,complete=false,inspected=0,known={}})
assert(table.concat(checklist," "):find("unavailable",1,true) or table.concat(checklist," "):find("pending",1,true),"unsupported skill checklist must be cautious")
assert(ForeverCompanionSkillDiscovery.FormatSummary("MAGE"):find("Not a class-completion score",1,true),"readiness must not imply full class coverage")

dofile("ForeverCompanion/LevelingCurriculum.lua")
dofile("ForeverCompanion/ProfessionFieldGuide.lua")
for _,class in ipairs({"WARRIOR","PALADIN","HUNTER","ROGUE","PRIEST","SHAMAN","MAGE","WARLOCK","DRUID"}) do
 for _,lvl in ipairs({1,15,25,40,55}) do
  local guide=ForeverCompanionLevelingCurriculum.Format(class,lvl)
  assert(guide:find("LEVELING PRACTICE",1,true) and guide:find("NEXT STAGE",1,true),"missing class leveling stage")
 end
end
for _,profession in ipairs({"Alchemy","Blacksmithing","Enchanting","Engineering","Leatherworking","Tailoring","Herbalism","Mining","Skinning"}) do
 assert(ForeverCompanionProfessionFieldGuide.Format(profession):find("Exact recipes",1,true),"missing profession field guidance")
end

dofile("ForeverCompanion/DungeonPreparation.lua")
for _,role in ipairs({"Tank","Healer","Damage"}) do
 local guidance=ForeverCompanionDungeonPreparation.Format(role)
 assert(guidance:find("DUNGEON READY CHECK",1,true) and guidance:find("not verified",1,true),"missing role readiness guidance")
end

dofile("ForeverCompanion/PvPPreparation.lua")
for _,class in ipairs({"WARRIOR","PALADIN","HUNTER","ROGUE","PRIEST","SHAMAN","MAGE","WARLOCK","DRUID"}) do
 local guide=ForeverCompanionPvPPreparation.Format(class)
 assert(guide:find("PVP FIELD NOTES",1,true) and guide:find("General practice only",1,true),"missing class PvP guidance")
end

-- Blizzard-published Forever Camping facts must remain source-attributed and
-- distinguish a missing sample (Mining) from a confirmed absence.
dofile("ForeverCompanion/CampingGuide.lua")
local camp=ForeverCompanionCampingGuide
assert(camp.source:find("2026-10-21",1,true),"camp guide must expose source date")
for _,name in ipairs({"Alchemy","Blacksmithing","Enchanting","Engineering","Herbalism","Leatherworking","Skinning","Tailoring","Cooking","First Aid","Fishing"}) do
 local entry=camp.features[name]
 assert(entry and entry.skill and entry.item and entry.effect,"missing official camp preview: "..name)
 assert(camp.Format(name):find(entry.item,1,true),"camp guide must display published feature: "..name)
end
assert(camp.features.Mining==nil and camp.Format("Mining"):find("no specific camp feature listed",1,true),"mining must not receive an invented camp item")
assert(camp.Format("Alchemy"):find("Blessing of Wisdom",1,true),"published stacking restriction missing")

dofile("ForeverCompanion/ForeverWorldGuide.lua")
local world=ForeverCompanionWorldGuide
assert(world.Format(1):find("Zephras Isle",1,true),"official Skyborne starter-zone context missing")
assert(world.Format(35):find("Riverglades",1,true),"official mid-level Riverglades context missing")
assert(not world.Format(15):find("Riverglades",1,true),"Riverglades must not be misrepresented as a low-level route")
assert(world.Format(39):find("level 40",1,true),"dual spec upcoming milestone missing")
assert(world.Format(40):find("starting at level 40",1,true),"dual spec milestone missing")
assert(world.Format(60):find("level cap",1,true),"official level cap missing")

dofile("ForeverCompanion/CampingGuide.lua")
dofile("ForeverCompanion/CampingReadiness.lua")
assert(ForeverCompanionCampingReadiness.Check("Alchemy",19).status=="BELOW PREVIEW GATE")
assert(ForeverCompanionCampingReadiness.Check("Alchemy",20).status=="MEETS PREVIEW GATE")
assert(ForeverCompanionCampingReadiness.Check("Alchemy",nil).status=="CHECK SKILL")
assert(ForeverCompanionCampingReadiness.Check("Mining",300).status=="UNCONFIRMED")

dofile("ForeverCompanion/ForeverClassChanges.lua")
local changes=ForeverCompanionClassChanges
for _,class in ipairs({"WARRIOR","PALADIN","HUNTER","ROGUE","PRIEST","SHAMAN","MAGE","WARLOCK","DRUID"}) do
 local entry=changes.classes[class]
 assert(entry and #entry.notes>=3 and entry.source:find("worldofwarcraft.blizzard.com",1,true),"missing sourced class preview: "..class)
 assert(changes.Format(class,30):find("published beta mechanics may change",1,true),"missing class-preview caution")
end
assert(changes.Format("WARRIOR",13):find("Announced for level 14",1,true),"Warrior level 14 preview gate missing")
assert(changes.Format("MAGE",39):find("Announced for level 40",1,true),"Mage level 40 preview gate missing")
assert(changes.Format("PALADIN",6):find("Published level 6",1,true),"Paladin level 6 preview gate missing")

dofile("ForeverCompanion/ForeverClassChanges.lua")
dofile("ForeverCompanion/ClassChangeIndex.lua")
local classRows=ForeverCompanionClassChangeIndex.Build("WARRIOR",10)
assert(#classRows>=3 and classRows[1].status=="UPCOMING","warrior level 10 must show upcoming level 14 preview")
assert(ForeverCompanionClassChangeIndex.Build("WARRIOR",20)[1].status=="LEVEL REACHED","level reached preview status")
assert(ForeverCompanionClassChangeIndex.Build("MAGE",1)[1].source:find("blizzard.com",1,true),"class changes must retain source")
assert(ForeverCompanionClassChangeIndex.Format("UNKNOWN",1):find("No sourced",1,true),"unknown class fallback")

dofile("ForeverCompanion/CraftCosts.lua")
assert(ForeverCompanionRecipePlans.Add("CostTest","Potion",3))
assert(ForeverCompanionRecipePlans.Ingredient("CostTest",1,"Herb",2))
assert(ForeverCompanionCraftCosts.Estimate("CostTest")[1].unknown==1)
assert(ForeverCompanionCraftCosts.Set("CostTest","Herb",125))
local estimate=ForeverCompanionCraftCosts.Estimate("CostTest")[1]
assert(estimate.complete and estimate.copper==750,"3 crafts * 2 herbs * 125 copper")
assert(ForeverCompanionRecipePlans.Done("CostTest",1,1))
assert(ForeverCompanionCraftCosts.Estimate("CostTest")[1].copper==500,"completed crafts must reduce estimated cost")
assert(not ForeverCompanionCraftCosts.Set("CostTest","Herb",-1),"negative prices must be rejected")

dofile("ForeverCompanion/ShoppingBudget.lua")
local budget=ForeverCompanionShoppingBudget.Build("CostTest")
assert(budget.complete and budget.knownCopper==500,"remaining two crafts require four herbs at 125 copper")
assert(ForeverCompanionCraftCosts.Set("CostTest","Herb",nil)==false,"nil unit prices invalid")
assert(ForeverCompanionRecipePlans.Ingredient("CostTest",1,"Vial",1))
budget=ForeverCompanionShoppingBudget.Build("CostTest")
assert(not budget.complete and budget.unknown==1 and budget.knownCopper==500,"unknown prices must remain incomplete")

dofile("ForeverCompanion/Readiness.lua")
local readiness=ForeverCompanionReadiness.Build("WARRIOR",20,"CostTest")
assert(#readiness==5 and readiness[1].state=="PUBLISHED","readiness should include sourced class preview")
assert(readiness[4].state=="PARTIAL","missing material price should remain partial")
assert(readiness[5].state=="UNTESTED","offline build must not claim in-game verification")
assert(ForeverCompanionReadiness.Format("WARRIOR",20,"CostTest"):find("No gameplay automation",1,true))

dofile("ForeverCompanion/Ornaments.lua")
assert(type(ForeverCompanionOrnaments.Hero)=="function","hero filigree must load")
assert(type(ForeverCompanionOrnaments.Corners)=="function","corner filigree must load")
assert(type(ForeverCompanionOrnaments.Ribbon)=="function","ribbon separator must load")
assert(type(ForeverCompanionOrnaments.Panel)=="function","secondary panel ornament must load")

-- Compatibility diagnostics must distinguish API presence from actual client proof.
local previousBuildInfo=GetBuildInfo
GetBuildInfo=function() return "1.60.1","12345","",16001 end
dofile("ForeverCompanion/Diagnostics.lua")
local diagnostic=ForeverCompanionDiagnostics.Collect()
assert(diagnostic:find("Interface match: yes",1,true),"matching interface diagnostics")
assert(diagnostic:find("Curated ability records:",1,true),"ability audit diagnostics")
assert(diagnostic:find("These checks show API presence only",1,true),"diagnostics verification disclaimer")
GetBuildInfo=function() return "1.60.1","12345","",99999 end
assert(ForeverCompanionDiagnostics.Collect():find("Interface match: NO",1,true),"interface mismatch warning")
GetBuildInfo=previousBuildInfo

dofile("ForeverCompanion/Rotations.lua")
-- Every beginner class guide must name concrete actions, not only generic advice.
local beginnerActions={
 WARRIOR="Heroic Strike",PALADIN="Judgement",HUNTER="Serpent Sting",
 ROGUE="Sinister Strike",PRIEST="Shadow Word: Pain",SHAMAN="Lightning Bolt",
 MAGE="Frostbolt",WARLOCK="Corruption",DRUID="Claw"
}
for class,spell in pairs(beginnerActions) do
 local steps=ForeverCompanionRotations[class] and ForeverCompanionRotations[class].leveling
 assert(type(steps)=="table" and #steps>=4,"missing beginner steps: "..class)
 assert(table.concat(steps," "):find(spell,1,true),"missing concrete spell priority: "..class)
end

-- Forever-specific mechanics must retain a traceable source and conditional coaching.
for _,class in ipairs({"HUNTER","WARRIOR","ROGUE","SHAMAN"}) do
 local notes=ForeverCompanionForeverMechanics[class]
 assert(type(notes)=="table" and #notes>=3,"missing Forever mechanics: "..class)
 local source=ForeverCompanionForeverMechanicsSources[class]
 assert(type(source)=="string" and source:find("wowhead.com",1,true),"missing Wowhead attribution: "..class)
end
for _,class in ipairs({"SHAMAN","ROGUE","WARRIOR","WARLOCK"}) do
 local specs=ForeverCompanionForeverDpsCoaching[class]
 assert(type(specs)=="table" and next(specs)~=nil,"missing specialization coaching: "..class)
 for _,steps in pairs(specs) do
  assert(type(steps)=="table" and #steps>=3,"incomplete specialization coaching: "..class)
 end
end

-- Beginner availability must remain conservative when the spellbook is incomplete.
local missingScan={supported=false,inspected=0,complete=false,known={}}
for _,class in ipairs({"WARRIOR","PALADIN","HUNTER","ROGUE","PRIEST","SHAMAN","MAGE","WARLOCK","DRUID"}) do
 local hints=ForeverCompanionBeginnerAvailability(class,missingScan)
 assert(type(hints)=="table" and #hints>=4,"missing beginner spellbook hints: "..class)
 assert(hints[1]:find("unverified",1,true),"unsupported scan must not claim availability: "..class)
end

-- Availability labels should be readable and avoid generic category lookups.
local categoryHints=ForeverCompanionBeginnerSpellHints
for _,name in ipairs(categoryHints.PALADIN) do
 assert(name~="Blessing" and name~="Seal","generic paladin spell category is not a spellbook entry")
end
for _,name in ipairs(categoryHints.WARLOCK) do
 assert(name~="Curse","generic warlock spell category is not a spellbook entry")
end
local unknownHints=ForeverCompanionBeginnerAvailability("MAGE",{supported=false,inspected=0,complete=false,known={}})
assert(unknownHints[1]:find("[UNKNOWN]",1,true),"unknown spells need a visible status")

-- Curated unlock metadata is additive; unknown classes remain conservative.
local warriorHints=ForeverCompanionBeginnerAvailability("WARRIOR",{supported=false,inspected=0,complete=false,known={}})
local sawHeroic=false
for _,line in ipairs(warriorHints) do
 if line:find("Heroic Strike",1,true) then
  assert(line:find("curated client-data level",1,true),"curated spell level missing")
  sawHeroic=true
 end
end
assert(sawHeroic,"warrior curated spell not displayed")

-- Level-gated curated spells should be distinguished from unknown scan results.
local originalUnitLevel=UnitLevel
UnitLevel=function() return 10 end
local gated=ForeverCompanionBeginnerAvailability("WARRIOR",{supported=false,inspected=0,complete=false,known={}})
local foundExecute=false
for _,line in ipairs(gated) do
 if line:find("Execute",1,true) then
  assert(line:find("[LEVEL 24+]",1,true),"Execute should show its curated level gate")
  foundExecute=true
 end
end
assert(foundExecute,"missing Execute beginner hint")
UnitLevel=originalUnitLevel

-- A live spellbook match takes precedence over stale curated level gates.
local oldLevel=UnitLevel
local oldBook=ForeverCompanionSpellbook
UnitLevel=function() return 10 end
ForeverCompanionSpellbook={Status=function(name) return name=="Execute" and "found in spellbook" or "unverified (test)" end}
local live=ForeverCompanionBeginnerAvailability("WARRIOR",{supported=true,inspected=1,complete=false,known={}})
local matched=false
for _,line in ipairs(live) do
 if line:find("Execute",1,true) then
  assert(line:find("[FOUND]",1,true),"known spell must override stale level gate")
  assert(line:find("recheck source/build",1,true),"source discrepancy must be visible")
  matched=true
 end
end
assert(matched,"Execute missing from live check")
UnitLevel=oldLevel
ForeverCompanionSpellbook=oldBook

-- Coverage counts only cross-referenced curated records, not guessed unlocks.
local warriorCovered,warriorTotal=ForeverCompanionBeginnerCoverage("WARRIOR")
assert(warriorTotal==4 and warriorCovered>=2 and warriorCovered<=warriorTotal,"unexpected Warrior curated coverage")
local mageCovered,mageTotal=ForeverCompanionBeginnerCoverage("MAGE")
assert(mageTotal==4 and mageCovered==1,"Mage coverage must count only its curated Arcane Intellect hint")

-- Mage curated entries must be sourced and counted without assuming spell ownership.
local mageData=ForeverCompanionVerifiedAbilities
assert(type(mageData.entries.MAGE)=="table" and #mageData.entries.MAGE>=2,"Mage curated entries missing")
assert(mageData.sources.MAGE=="https://foreverdb.net/spells?cls=8","Mage source missing")
local mageCount,mageHints=ForeverCompanionBeginnerCoverage("MAGE")
assert(mageHints==4 and mageCount>=1,"Mage coverage must include Arcane Intellect")
local mageLines=ForeverCompanionBeginnerAvailability("MAGE",{supported=false,inspected=0,complete=false,known={}})
local foundIntellect=false
for _,line in ipairs(mageLines) do
 if line:find("Arcane Intellect",1,true) then
  assert(line:find("curated client-data level 1",1,true),"Mage unlock level missing")
  assert(line:find("[UNKNOWN]",1,true),"offline spellbook status must remain unknown")
  foundIntellect=true
 end
end
assert(foundIntellect,"Arcane Intellect missing from Mage hints")

-- Mage milestones are level-aware coaching, not audited spell-ID entries.
local earlyMage=table.concat(ForeverCompanionMageMilestoneLines(4),"\n")
assert(earlyMage:find("[LEVEL REACHED] Lv 4 Frostbolt",1,true),"Frostbolt milestone missing")
assert(earlyMage:find("[UPCOMING] Lv 10 Frost Nova",1,true),"Frost Nova should be upcoming at level 4")
local lateMage=table.concat(ForeverCompanionMageMilestoneLines(10),"\n")
assert(lateMage:find("[LEVEL REACHED] Lv 10 Frost Nova",1,true),"Frost Nova milestone should unlock at level 10")

-- Release gate: every advertised specialization must have actionable guidance.
dofile("ForeverCompanion/SpecPlanner.lua")
dofile("ForeverCompanion/SpecPlaybooks.lua")
local specCount=0
for class,choices in pairs(ForeverCompanionSpecs) do
 local playbooks=ForeverCompanionSpecPlaybooks[class]
 local priorities=ForeverCompanionSpecPriorityNotes[class]
 assert(type(playbooks)=="table" and type(priorities)=="table","missing class playbooks: "..class)
 for _,choice in ipairs(choices) do
  local name=choice[1]
  local steps=playbooks[name]
  local notes=priorities[name]
  assert(type(steps)=="table" and #steps>=5,"missing five-step playbook: "..class.." "..name)
  assert(type(notes)=="table" and #notes>=2,"missing priority explanation: "..class.." "..name)
  for _,step in ipairs(steps) do
   assert(type(step)=="string" and #step>=24,"too-short step: "..class.." "..name)
  end
  specCount=specCount+1
 end
end
assertEqual(specCount,28,"all published spec choices including Bear alternate")

-- The UI helper must follow the selected spec, including the optional Bear entry.
for class,choices in pairs(ForeverCompanionSpecs) do
 for index,choice in ipairs(choices) do
  ForeverCompanionDB.specSelections[class]=index
  local name=choice[1]
  local lines=ForeverCompanionSpecPlaybookLines(class)
  local notes=ForeverCompanionSpecPriorityNoteLines(class)
  assert(type(lines)=="table" and #lines>=7,"rendered playbook missing: "..class.." "..name)
  assert(lines[1]:find(name,1,true),"rendered playbook selected wrong spec: "..class.." "..name)
  assert(type(notes)=="table" and #notes>=4,"rendered priority notes missing: "..class.." "..name)
  assert(notes[1]:find(name,1,true),"rendered notes selected wrong spec: "..class.." "..name)
 end
end
ForeverCompanionDB.specSelections={}

-- Sourced rotation references must render for the correct selected build.
for _,case in ipairs({
 {"HUNTER","Survival","Mongoose Bite"},
 {"DRUID","Restoration","Wild Growth"},
 {"PALADIN","Protection","Templar's Bulwark"},
 {"WARLOCK","Destruction","Bane of Havoc"},
 {"PRIEST","Holy","Prayer of Mending"},
 {"PALADIN","Holy","Flash of Light"},
 {"PRIEST","Discipline","Weakened Soul"},
 {"SHAMAN","Restoration","Chain Heal"},
 {"ROGUE","Assassination","Mutilate"},
 {"ROGUE","Subtlety","Hemorrhage"},
 {"WARRIOR","Fury","Bloodthirst"},
 {"WARRIOR","Protection","Shield Block"},
 {"DRUID","Feral","Shifting Power"},
 {"MAGE","Fire","Heating Up"},
 {"HUNTER","Marksmanship","Sniper Shot"},
 {"SHAMAN","Elemental","Lava Burst"},
 {"DRUID","Balance","Eclipse"},
 {"WARLOCK","Demonology","Demonic Brand"},
 {"PRIEST","Shadow","Mind Flay"},
 {"WARRIOR","Arms","Overpower"},
 {"SHAMAN","Enhancement","Maelstrom Weapon"},
 {"WARLOCK","Affliction","Corruption"},
 {"PALADIN","Retribution","Seal of Command"},
 {"MAGE","Arcane","Heating Up"},
 {"MAGE","Frost","Fingers of Frost"},
 {"ROGUE","Combat","Slice and Dice"},
 {"HUNTER","Beast Mastery","Serpent Sting"},
}) do
 local class,name,expected=case[1],case[2],case[3]
 local found=false
 for index,choice in ipairs(ForeverCompanionSpecs[class]) do
  if choice[1]==name then ForeverCompanionDB.specSelections[class]=index found=true break end
 end
 assert(found,"missing sourced spec in planner: "..class.." "..name)
 local lines=ForeverCompanionSourcedPriorityLines(class)
 assert(type(lines)=="table" and #lines>=8,"missing sourced priority: "..class.." "..name)
 assert(table.concat(lines," "):find(expected,1,true),"wrong sourced rotation: "..class.." "..name)
 assert(table.concat(lines," "):find("https://",1,true),"missing source URL: "..class.." "..name)
end
ForeverCompanionDB.specSelections={}

-- November Forever hotfix: Feral Berserk was removed; guide must not recommend it.
for index,choice in ipairs(ForeverCompanionSpecs.DRUID) do
 if choice[1]=="Feral" then ForeverCompanionDB.specSelections.DRUID=index break end
end
local feralSourced=table.concat(ForeverCompanionSourcedPriorityLines("DRUID")," ")
assert(feralSourced:find("Berserk is no longer a Feral talent",1,true),"Feral hotfix warning missing")
assert(not feralSourced:find("during Berserk, prioritize",1,true),"obsolete Feral Berserk rotation")
ForeverCompanionDB.specSelections={}

-- Late-October client changes must not regress into unsafe guide instructions.
local function selectSpec(class,name)
 for i,choice in ipairs(ForeverCompanionSpecs[class]) do
  if choice[1]==name then ForeverCompanionDB.specSelections[class]=i return end
 end
 error("missing spec "..class.." "..name)
end
selectSpec("PRIEST","Shadow")
assert(table.concat(ForeverCompanionSourcedPriorityLines("PRIEST")," "):find("30% of maximum health",1,true),"Shadow Word: Death backlash caution missing")
selectSpec("PRIEST","Holy")
assert(table.concat(ForeverCompanionSourcedPriorityLines("PRIEST")," "):find("Holy Binding",1,true),"Holy Binding hotfix missing")
selectSpec("DRUID","Restoration")
assert(table.concat(ForeverCompanionSourcedPriorityLines("DRUID")," "):find("consumes the HoT",1,true),"Swiftmend HoT-consumption missing")
ForeverCompanionDB.specSelections={}

-- Prelaunch talent-diff advisory checks (not claims of live verification).
selectSpec("MAGE","Frost")
assert(table.concat(ForeverCompanionSourcedPriorityLines("MAGE")," "):find("8-second cooldown",1,true),"Frost Ice Lance hotfix cooldown missing")
selectSpec("PALADIN","Protection")
assert(table.concat(ForeverCompanionSourcedPriorityLines("PALADIN")," "):find("reduces Holy Shield damage",1,true),"Holy Shield tuning note missing")
selectSpec("DRUID","Restoration")
assert(table.concat(ForeverCompanionSourcedPriorityLines("DRUID")," "):find("your own Regrowth or Rejuvenation",1,true),"Swiftmend HoT requirement missing")
ForeverCompanionDB.specSelections={}

-- Every standard spec must retain a source URL, decision rules and a
-- specialization-matched addendum after future class tuning edits.
local standardSpecs=0
for class,choices in pairs(ForeverCompanionSpecs) do
 for index,choice in ipairs(choices) do
  if choice[1]~="Guardian / Bear" then
   ForeverCompanionDB.specSelections[class]=index
   local lines=ForeverCompanionSourcedPriorityLines(class)
   local joined=table.concat(lines," ")
   assert(#lines>=7,"source-reviewed guide too short: "..class.." "..choice[1])
   assert(lines[1]:find(choice[1],1,true),"source-reviewed spec mismatch: "..class.." "..choice[1])
   assert(joined:find("https://",1,true),"source-reviewed URL missing: "..class.." "..choice[1])
   assert(joined:find("Re-check after each action",1,true),"decision safety reminder missing: "..class.." "..choice[1])
   assert(joined:find("not a DPS benchmark",1,true),"unverified benchmark disclaimer missing: "..class.." "..choice[1])
   standardSpecs=standardSpecs+1
  end
 end
end
assertEqual(standardSpecs,27,"all standard specs must have source-reviewed guidance")
ForeverCompanionDB.specSelections={}

-- Source-review completeness is separate from hotfix evidence status.
for _,class in ipairs({"DRUID","PALADIN","MAGE","HUNTER","PRIEST"}) do
 local lines=ForeverCompanionSourcedPriorityLines(class)
 assert(table.concat(lines," "):find("unconfirmed in official notes",1,true),"missing hotfix evidence warning: "..class)
end
for _,class in ipairs({"WARRIOR","ROGUE","SHAMAN","WARLOCK"}) do
 local lines=ForeverCompanionSourcedPriorityLines(class)
 assert(not table.concat(lines," "):find("unconfirmed in official notes",1,true),"unrelated hotfix warning: "..class)
end
