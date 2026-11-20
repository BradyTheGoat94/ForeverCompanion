CreateFrame=function() return {RegisterEvent=function() end,SetScript=function() end} end
dofile('ForeverCompanion/PartyDistance.lua')
local D=ForeverCompanionPartyDistance
UnitDistanceSquared=function() return 2500,true end
assert(D.Measure('party1')=='50 yd')
UnitDistanceSquared=function() return 0,false end
UnitPosition=function(unit)
 if unit=='player' then return 0,0,0,1 end
 return 3,4,0,1
end
assert(D.Measure('party1')=='~5 yd')
UnitPosition=function(unit) return 10,15,0,unit=='player' and 1 or 2 end
UnitInRange=function() return true,true end
assert(D.Measure('party1')=='In range')
UnitInRange=function() return false,false end
assert(D.Measure('party1')=='Unavailable')
UnitIsConnected=function() return false end
assert(D.Measure('party1')=='Offline')
UnitIsConnected=function() return true end
IsInInstance=function() return false end
C_Map={
 GetBestMapForUnit=function() return 10 end,
 GetPlayerMapPosition=function(_,unit) return unit end,
 GetWorldPosFromMapPos=function(_,unit)
  return 1,{GetXY=function() return unit=='player' and 0 or 30,40 end}
 end,
}
assert(D.Measure('party1')=='Unavailable','different native world IDs cannot fall back to map projection')
UnitPosition=nil
assert(D.Measure('party1')=='~30 yd')
IsInInstance=function() return true end
assert(D.Measure('party1')=='Unavailable','map projection is disabled inside instances')
print('PASS: verified distances, same-world estimates, range fallback and offline members')
