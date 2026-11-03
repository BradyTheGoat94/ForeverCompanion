-- Run from repository root: lua5.1 tests/loot_boss_smoke.lua
dofile("ForeverCompanion/LootAtlas.lua")
local loot=ForeverCompanionLoot
local function eq(a,b,msg) assert(a==b,(msg or "mismatch")..": "..tostring(a).." vs "..tostring(b)) end
local bosses=loot.BossNames("The Deadmines")
assert(#bosses>0,"expected sourced beta boss fixtures")
for i=2,#bosses do assert(bosses[i-1]<bosses[i],"bosses sorted") end
eq(#loot.BossDrops("The Deadmines","Not a boss"),0,"unknown boss")
eq(#loot.BossDrops(nil,"Sneed"),0,"missing dungeon")
local drops=loot.BossDrops("The Deadmines","Sneed")
assert(#drops>0,"expected Sneed fixture")
local db={}
local summary=loot.BossSummary("The Deadmines","Sneed",db)
assert(summary:find("Drop chance: unknown",1,true),"unknown rate must be explicit")
assert(summary:find("\n",1,true),"summary needs real line breaks")
assert(not summary:find("\\n",1,true),"summary must not display escaped newline text")
assert(summary:find("Evidence:",1,true),"source confidence label")
assert(summary:find("Source:",1,true),"source attribution")
loot.ToggleWish(db,drops[1].item)
assert(loot.BossSummary("The Deadmines","Sneed",db):find("[WISHLIST]",1,true),"wishlist marker")
assert(loot.BossSummary("The Deadmines","Unknown",db):find("No source-attributed drops",1,true),"empty state")
local filtered=loot.Filter("","The Deadmines",false,db,"Sneed")
eq(#filtered,#drops,"boss filtered result count")
for _,item in ipairs(filtered) do
  eq(item.boss,"Sneed","boss filter isolation")
end
eq(#loot.Filter("","The Deadmines",false,db,"Unknown"),0,"unknown boss filter")
local filterSummary=loot.FilterSummary("","The Deadmines",false,db,"Sneed")
assert(filterSummary:find("Boss: Sneed",1,true),"boss filter must be visible")
print("loot boss smoke: PASS")
