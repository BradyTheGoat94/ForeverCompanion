SlashCmdList={}
dofile('ForeverCompanion/HunterReference.lua');dofile('ForeverCompanion/HunterGuide.lua')
local H,D=ForeverCompanionHunterGuide,ForeverCompanionHunterData
C_Map={GetMapInfo=function(id) return {name='Map '..id,mapType=3} end,GetAreaInfo=function(id) return 'Area '..id end}
UnitLevel=function(unit) return unit=='pet' and 20 or 15 end;UnitFactionGroup=function() return 'Alliance' end
assert(#H.Build('beasts',{})==768 and #H.Build('families',{})==18 and #H.Build('abilities',{})>5)
local mapped,unknownSpeed,unknownLevel,points=0,0,0,0
for _,entry in ipairs(H.Build('beasts',{})) do
 assert(entry.name~='' and D.TameableFamilies[entry.record.family] and not D.TameableHidden[entry.id])
 if not entry.record.speed then unknownSpeed=unknownSpeed+1 end;if not entry.record.min then unknownLevel=unknownLevel+1 end
 for _,packed in pairs(entry.record.maps or {}) do local _,valid=H.Decode(packed);assert(valid,'invalid packed source for '..entry.id) end
 local found=H.Points(entry.id);if #found>0 then mapped=mapped+1;points=points+#found end
 for _,p in ipairs(found) do assert(p.x>=0 and p.x<=1 and p.y>=0 and p.y<=1 and p.reference and p.entityID==entry.id) end
end
assert(#H.Decode('???')==0 and select(2,H.Decode('AAA!'))==false and #H.Decode('///')==0)
local decoded=H.Decode('AAA');assert(decoded[1].x==0 and decoded[1].y==0)
assert(#H.Build('beasts',{family='Cat',level=true})>0)
for _,e in ipairs(H.Build('beasts',{family='Cat',level=true})) do assert(e.record.family=='Cat' and e.record.min<=15) end
for _,e in ipairs(H.Build('beasts',{ability='bite',rank=2,family='Wolf'})) do assert(e.record.family=='Wolf') end
local routeCalls=0;ForeverCompanionQuestWaypoints={Navigate=function(p) routeCalls=routeCalls+1;return 'Reference direction' end}
local target=H.Points(119)[1];assert(target and H.Navigate(119,target));assert(routeCalls==1)
local forged={map=target.map,x=target.x+.001,y=target.y,entityID=119};assert(not H.Navigate(119,forged) and routeCalls==1)
assert(not H.Navigate(5807,target) and routeCalls==1,'a different creature cannot reuse the marker')
UnitExists=function() return true end;UnitName=function() return 'My companion' end;UnitCreatureFamily=function() return 'Cat' end
UnitDamage=function() return 20,40 end;UnitAttackSpeed=function() return 2 end;UnitArmor=function() return 100,120 end;UnitHealth=function() return 200 end;UnitHealthMax=function() return 250 end
GetPetActionInfo=function(i) if i==1 then return 'Bite' end end
local pet=H.LivePet();assert(pet.dps==15 and pet.armor==120 and #pet.actions==1)
for i=1,15 do assert(H.SavePet()) end;assert(#H.Settings().snapshots==12)
issecretvalue=function(v) return v=='protected' end
UnitAttackSpeed=function() return 'protected' end;assert(H.LivePet().speed==nil and H.LivePet().dps==nil)
UnitDamage=function() error('restricted') end;assert(H.LivePet().low==nil)
UnitExists=function() return false end;assert(not H.SavePet())
print('PASS: Hunter '..#H.Build('beasts',{})..' beasts, '..mapped..' mapped, '..points..' normalized points, '..unknownSpeed..' unknown speeds, '..unknownLevel..' unknown levels; filters, source identity, protected live values and snapshot limits')
local known=H.Build('beasts',{})[1]
UnitGUID=function() return 'Creature-0-1-2-3-'..known.id..'-ABC' end
C_Map.GetBestMapForUnit=function() return 123 end
C_Map.GetPlayerMapPosition=function() return {GetXY=function() return .25,.75 end} end
local recorded,_,id=H.RecordTarget()
assert(recorded and id==known.id and #H.Build('beasts',{seen=true})==1)
local point=H.Points(id)[1]
assert(point.observed and point.map==123 and point.x==.25 and point.y==.75)
UnitGUID=function() return 'Player-1-123' end
assert(not H.RecordTarget())

local family=H.Build('families',{})
for i=2,#family do assert((family[i-1].min or math.huge)<=(family[i].min or math.huge)) end
assert(H.FamilyPreview('Bird of Prey').id==1995 and not H.FamilyPreview('Core Hound'))
for _,skill in ipairs(H.Build('abilities',{})) do
 assert(not skill.record.passive and not skill.key:find('interval',1,true))
 for _,rank in ipairs(skill.record.ranks) do assert(#H.TameSources(rank)>0) end
end
local compare=H.Comparison(1995)
assert(compare and compare.name=='Strigid Owl' and compare.speed and compare.family=='Bird of Prey')
