-- Offline smoke tests with mocked WoW APIs. Run: lua5.1 tests/offline_smoke.lua
local function assertEqual(actual,expected,label)
 if actual~=expected then error(label..": expected "..tostring(expected)..", got "..tostring(actual),2) end
end
local output={}
print=function(message) output[#output+1]=tostring(message) end
SlashCmdList={}
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
io.write("PASS: offline spellbook, crafting, and diagnostic smoke tests\n")
