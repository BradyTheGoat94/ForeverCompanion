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
 GetQuestObjectives=function() return {{text="Collect 3 samples"}} end,
}
dofile("ForeverCompanion/QuestPlanner.lua")
assertEqual(ForeverCompanionQuestPlanner.Sync(),true,"quest scan")
assertEqual(ForeverCompanionQuestPlanner.AutoCount(),1,"quest count")
assertEqual(ForeverCompanionQuestPlanner.ReadyCount(),1,"quest completion")
assertEqual(ForeverCompanionQuestPlanner.Overview().remaining,0,"quest summary remaining")
assertEqual(ForeverCompanionQuestPlanner.Overview().zones[1].zone,"Test Zone","quest zone summary")
assert(ForeverCompanionQuestPlanner.FormatOverview():find("1 active",1,true),"quest overview should show live totals")
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
assert(ForeverCompanionProfessionProgress.FormatOverview():find("100 skill to current cap",1,true),"profession progress summary missing")
GetProfessions=function() error("unavailable") end
local missing,reason=ForeverCompanionProfessionScanner.Read()
assertEqual(missing,nil,"failed profession read")
assert(type(reason)=="string","missing API reason")
assert(ForeverCompanionProfessionProgress.FormatOverview():find("unavailable",1,true),"profession API failure needs honest fallback")
io.write("PASS: offline spellbook, crafting, diagnostics, quests, specs and professions\n")
