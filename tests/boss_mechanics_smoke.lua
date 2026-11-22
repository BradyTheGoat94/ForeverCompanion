dofile('ForeverCompanion/BossMechanics.lua')
local M=ForeverCompanionBossMechanics
local count,withMechanics,dungeons=0,0,0
for dungeon,entries in pairs(M.data) do
 dungeons=dungeons+1
 for boss,record in pairs(entries) do
  count=count+1;assert(record.source:match('^https://') and record.reviewed=='2026-11-11')
  local body=M.Format(dungeon,boss);local _,quotes=body:gsub('"DONT BE LIKE DRYST"','')
  if #record.mechanics>0 then
   withMechanics=withMechanics+1;assert(quotes==1)
   assert(body:find(record.mechanics[#record.mechanics],1,true)<body:find(M.quote,1,true))
  else assert(quotes==0) end
 end
end
assert(dungeons==17 and count>90 and withMechanics>70)
assert(not M.Format('Unknown','Unknown'):find(M.quote,1,true))
assert(M.Format('Unknown','Unknown'):find('research pending',1,true))
assert(M.Get('The Deadmines','Mr Smite')==M.Get('The Deadmines','Mr. Smite'))
assert(not M.Format('Wailing Caverns','Kresh'):find(M.quote,1,true))
print('PASS: '..count..' boss references across '..dungeons..' dungeons; mechanics precede one quoted Easter egg; empty/missing notes never get it')

dofile('ForeverCompanion/BossGuideWorkspace.lua')
local W=ForeverCompanionBossGuideWorkspace
local tactics,record=W.MechanicRows('The Deadmines','Captain Greenskin')
assert(#tactics==2 and tactics[1]==record.mechanics[1] and tactics[2]==record.mechanics[2])
assert(W.MechanicRows('The Deadmines','Missing boss')[1]=='Research pending')
