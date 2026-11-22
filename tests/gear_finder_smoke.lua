dofile('ForeverCompanion/GearFinder.lua')
local G=ForeverCompanionGearFinder
local function record(n,name,slot,boss) return {itemID=n,item=name,slot=slot or 'Head',dungeon='Dungeon',boss=boss or 'Boss',status='Fixture',source='https://example.test/'..n} end
ForeverCompanionLoot={records={record(1,'Better'),record(2,'Worse'),record(3,'Uncached'),record(4,'Future'),record(5,'Different armor'),record(6,'Sword','One-Hand'),record(7,'Ring','Finger'),record(1,'Better','Head','Other boss'),record(8,'Empty slot','Feet')}}
ForeverCompanionDB={gearFinder={weights={1,1,1,1,1,1,.5,.02},hunts={['1']=true}}}
UnitLevel=function() return 20 end
local equipped='equipped';local owned={};local requests={}
GetInventoryItemID=function(_,slot) if slot==8 then return nil end;return 999 end
GetInventoryItemLink=function(_,slot) if slot==12 then return 'secondRing' elseif slot==8 then return nil end;return equipped end
local function api()
 C_Item={GetItemInfo=function(n)
  if n==3 then return end
  return tostring(n),n,2,20,n==4 and 30 or 10,'Armor','Cloth',1,n==7 and 'INVTYPE_FINGER' or n==8 and 'INVTYPE_FEET' or n==6 and 'INVTYPE_WEAPON' or 'INVTYPE_HEAD',nil,nil,4,n==5 and 4 or 1
 end,GetItemStats=function(n) return {ITEM_MOD_STRENGTH_SHORT=(n==1 or n==7) and 15 or (n==2 and 5 or (n=='secondRing' and 20 or 10))} end,
 GetItemCount=function(n,bank,uses) assert(bank==false and uses==false);return owned[n] or 0 end,
 RequestLoadItemDataByID=function(n) requests[#requests+1]=n end}
end
api()
local result=G.Build();assert(#result==5 and result[1].record.itemID==1 and result[1].delta==5 and #result[1].sources==2,'deduplicate source records')
assert(#G.Build({upgrades=true})==1)
assert(#G.Build({query='['})==0);assert(#G.Build({query='better other'})==1,'multiword source search')
assert(#G.Build({ready=true})==3,'hide unknown and future requirements')
assert(#G.Build({matchArmor=true})==4,'hide known incompatible armor')
assert(#G.Build({saved=true})==1,'migrate original saved hunts')
assert(G.Toggle(1));assert(#G.Build({saved=true})==0);assert(not G.Toggle(999))
assert(G.Build({slot=10})[1].delta==5);assert(G.Build({slot=11})[1].delta==-5,'exact ring slots')
local all=G.Build({slot=0});local ring;for _,r in ipairs(all) do if r.record.itemID==7 then ring=r end end
assert(ring and ring.slotIndex==10 and ring.delta==5,'all-slot view chooses weaker legal ring slot')
assert(#G.Build({slot=15,upgrades=true})==0,'weapons not falsely ranked')
local feet=G.Build({slot=7});assert(#feet==1 and feet[1].empty and feet[1].delta==nil,'empty equipment is not an assumed zero-score item')
local b=G.Breakdown(result[1]);assert(b[1].candidate==15 and b[1].equipped==10 and b[1].points==5)
owned[1]=1;assert(#G.Build({upgrades=true})==0,'already owned item excluded from positive/unowned filter')
assert(G.Toggle(1));assert(G.Settings().completed['1'].observed);assert(not G.Track(1))
assert(G.Toggle(2));assert(G.Track(2));assert(G.Settings().tracked=='2');assert(G.Track(2));assert(G.Settings().tracked==nil)
assert(#G.ObserveHunts()==0);owned[2]=1;assert(#G.ObserveHunts()==1);assert(#G.ObserveHunts()==0,'acquisition only recorded once')
owned[2]=0;assert(G.Settings().completed['2'].observed,'selling an item does not erase history')
local active,done=G.HuntCounts();assert(active==0 and done==2)
assert(#G.Build({completed=true,slot=0})==2)
assert(G.Toggle(2));assert(#G.Build({completed=true,slot=0})==2,'completed history independent of active hunts')
assert(G.SetWeight(1,2));assert(G.SaveProfile(1,'Strength leveling'));assert(G.Preset('Caster'));assert(G.LoadProfile(1));assert(G.Settings().weights[1]==2 and G.Settings().profile=='Strength leveling')
assert(not G.SetWeight(1,0/0) and not G.SetWeight(1,-1) and not G.SetWeight(1,101));assert(not G.LoadProfile(2))
G.Settings().profiles[2]={name='Bad',weights={}};assert(not G.LoadProfile(2))
-- Known unique-equipped conflicts cannot receive an upgrade estimate.
local oldLink=GetInventoryItemLink
GetInventoryItemLink=function(_,slot) if slot==12 then return 'item:7' end;return 'equipped' end
C_Item.GetItemUniquenessByID=function(n) return n==7,nil,1,nil end
local unique=G.Build({slot=10});assert(unique[1].blocked and unique[1].delta==nil)
C_Item.GetItemUniquenessByID=nil;GetInventoryItemLink=oldLink
UnitClass=function() return 'Mage','MAGE' end
ForeverCompanionSpecPlanner={Get=function() return {'Frost','Damage'} end}
assert(G.SuggestPreset()=='Frost Mage')
UnitClass=function() return 'Paladin','PALADIN' end
ForeverCompanionSpecPlanner.Get=function() return {'Holy','Healer'} end
assert(G.SuggestPreset()=='Holy Paladin')
UnitClass=nil;ForeverCompanionSpecPlanner=nil
local saved=ForeverCompanionDB;dofile('ForeverCompanion/GearFinder.lua');G=ForeverCompanionGearFinder;assert(G.Settings().completed['2'].observed and G.LoadProfile(1),'reload persistence')
G.RetryData();G.Build();G.Build();assert(#G.loadQueue==1,'deduplicate async loads');G.LoadBatch();assert(#requests==1);G.Build();assert(#G.loadQueue==0,'no endless retries')
G.RetryData();G.Build();assert(#G.loadQueue==1,'explicit retry available')
C_Item.GetItemCount=function() error('unavailable') end;assert(#G.ObserveHunts()==0,'failed inventory scan cannot complete a hunt')
C_Item.GetItemStats=function() return {UNSUPPORTED_STAT=500} end;assert(#G.Build({upgrades=true})==0,'unsupported stats are not scored as zero')
C_Item=nil;assert(#G.Build()==5 and #G.Build({upgrades=true})==0)
assert(G.Score({ITEM_MOD_STRENGTH_SHORT=0/0},G.Settings().weights)==nil)
ForeverCompanionDB.gearFinder={weights={-1,math.huge,'bad'},hunts={bad=true,['2']='true',['3']=true},completed={bad=true,['2']={observed=false}},tracked='bad'}
assert(G.Settings().weights[1]==1 and G.Settings().hunts['3']==true and not G.Settings().hunts.bad and not G.Settings().completed['2'] and not G.Settings().tracked)
local counts=0;for i=1,40 do G.Settings().hunts[tostring(i)]=true end;for _ in pairs(G.Settings().hunts) do counts=counts+1 end;assert(counts==40,'legacy saved identities are preserved above the new-add limit');assert(G.Toggle(1));assert(not G.Toggle(1),'new saves respect capacity without deleting legacy hunts')
local oldRecords=ForeverCompanionLoot.records;ForeverCompanionLoot.records={}
local unavailable=G.Build({saved=true,slot=0});assert(#unavailable==39 and unavailable[1].unavailable,'removed catalog sources remain reviewable')
assert(G.Toggle(unavailable[1].record.itemID));ForeverCompanionLoot.records=oldRecords
print('PASS: gear research sources, exact slots, explained scores, profiles, cache batching, hunt migration/acquisition, failed scans and saved-data sanitation')

SlashCmdList={}
dofile('ForeverCompanion/SpecPlanner.lua')
dofile('ForeverCompanion/GearStats.lua')
for class,choices in pairs(ForeverCompanionSpecs) do
 UnitClass=function() return class,class end
 for index,choice in ipairs(choices) do
  ForeverCompanionSpecPlanner.Select(class,index)
  local name,_,specific=G.SuggestPreset()
  assert(specific and G.presets[name] and ForeverCompanionGearStats.Get(class,choice[1]), class..' / '..choice[1])
 end
end
