SlashCmdList={}
ForeverCompanionDB={}
dofile('ForeverCompanion/CraftingPlanner.lua')
local p=ForeverCompanionCraftingPlanner
assert(p.Add('Alchemy','First herb',10,2))
assert(p.Add('Alchemy','Second herb',20,3))
local original=p.GetEntries('Alchemy')[1]
assert(not p.Update('Alchemy',1,'Second herb',10,2),'duplicate edits must fail')
assert(p.GetEntries('Alchemy')[1]==original,'failed edits are atomic')
assert(not p.Update('Alchemy',1,'Renamed',0/0,2))
assert(not p.Update('Alchemy',1,'Renamed',math.huge,2))
assert(not p.Update('Alchemy',1,'Renamed',10,-1))
assert(not p.Update('Alchemy',1,'Renamed',10,2.5))
assert(not p.Update('Alchemy',99,'Renamed',10,2))
assert(p.GetEntries('Alchemy')[1]==original)
assert(p.Update('Alchemy',1,'Renamed herb',12,6))
local saved=p.GetEntries('Alchemy')[1]
assert(saved.name=='Renamed herb' and saved.needed==12 and saved.owned==6)
assert(p.GetEntries('Alchemy')[2].name=='Second herb','other goals remain intact')
print('PASS: atomic manual-goal edits reject duplicates, malformed quantities and invalid indices')
