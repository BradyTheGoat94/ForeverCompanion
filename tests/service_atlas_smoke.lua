local events={}
CreateFrame=function() local f={};function f:RegisterEvent() end;function f:SetScript(key,fn) self[key]=fn end;events[#events+1]=f;return f end
ForeverCompanionDB={}
local queue={}
C_Timer={After=function(_,fn) queue[#queue+1]=fn end}
UnitFactionGroup=function() return 'Alliance' end
local names={[1]='Reference smith',[2]='Neutral banker',[3]='Hostile merchant'}
local spawns={[1]={[12]={{50,50},{50,50},false}},[2]={[12]={{30,40}}},[3]={[12]={{60,60}}}}
local db={Enum={npcFlags={VENDOR=4,REPAIR=4096,BANKER=256}},RequireContract=function() return true end,
 Npc={GetAllIds=function() return {1,2,3} end,npcFlags=function(id) return id==1 and 4100 or (id==2 and 256 or 4) end,
  friendlyToFaction=function(id) return id==3 and 'H' or 'AH' end,name=function(id) return names[id] end,
  subName=function(id) return id==1 and 'Weapons and armor' end,spawns=function(id) return spawns[id] end}}
ForeverCompanionQuestLocations={Provider=function() return db end,AreaMaps=function() return {[12]=1429} end}
dofile('ForeverCompanion/TownServices.lua')
local s=ForeverCompanionTownServices
local first,notice=s.ForMap(1429);assert(#first==0 and notice:find('Loading',1,true))
while #queue>0 do table.remove(queue,1)() end
local points=s.ForMap(1429);assert(#points==3,'reference service duplicates collapse; hostile services stay excluded')
assert(points[1].npcID==1 and points[1].subtitle=='Weapons and armor')
assert(s.Status(1429).locations==2 and s.Status(1429).counts.R==1)
assert(s.RecordVisit({map=1429,x=.7,y=.8,label='Visited merchant',npcID=77,repair=true}))
points=s.ForMap(1429);assert(#points==5 and points[4].observed and points[4].source:find('player position',1,true))
assert(s.RecordVisit({map=1429,x=.71,y=.81,label='Visited merchant',npcID=77,repair=true}))
assert(#ForeverCompanionDB.visitedMerchants==1,'revisiting an NPC updates its observation instead of duplicating it')
local stale=points[4];assert(s.Resolve(stale)==nil,'moved visit positions invalidate old navigation')
names[1]='Updated smith';spawns[1]={[12]={{51,52}}};s.RefreshData();s.ForMap(1429)
while #queue>0 do table.remove(queue,1)() end
assert(s.ForMap(1429)[1].label=='Updated smith' and s.ForMap(1429)[1].x==.51,'rescan reads current provider corrections')
dofile('ForeverCompanion/ServiceAtlas.lua')
local a=ForeverCompanionServiceAtlas
local results=a.Query(s.ForMap(1429),'armor',{})
assert(#results==1 and #results[1].services==2,'search combines service roles and specialty text')
assert(#a.Query(s.ForMap(1429),'[',{})==0,'service search uses literal matching')
assert(#a.Query(s.ForMap(1429),'',{category='R'})==2)
assert(#a.Query(s.ForMap(1429),'',{source='visited'})==1,'visited repair/vendor entries group as one location')
local favorites={[a.Key(s.ForMap(1429)[1])]=true}
assert(#a.Query(s.ForMap(1429),'',{favorites=favorites,favoritesOnly=true})==1)
assert(s.RecordVisit({map=1429,x=.9,y=.9,label='Updated smith',npcID=1,repair=true}))
assert(#a.Query(s.ForMap(1429),'Updated smith',{})==2,'a distinct actual visit cannot be erased by an older provider location')
local navigated
ForeverCompanionQuestWaypoints={Navigate=function(t) navigated=t;return 'Navigating' end}
a.Navigate(stale);assert(navigated==nil,'atlas cannot navigate a stale location')
UnitGUID=function() return 'Creature-0-1-2-3-88-00001' end;UnitName=function() return 'New merchant' end
C_Map={GetBestMapForUnit=function() return 1429 end,GetPlayerMapPosition=function() return {GetXY=function() return .2,.3 end} end}
CanMerchantRepair=function() return true end
events[1].OnEvent();assert(ForeverCompanionDB.visitedMerchants[1].npcID==88 and ForeverCompanionDB.visitedMerchants[1].repair)
ForeverCompanionDB.recordMerchantVisits=false;UnitGUID=function() return 'Creature-0-1-2-3-89-00001' end
events[1].OnEvent();assert(ForeverCompanionDB.visitedMerchants[1].npcID==88,'recording is optional')
for i=1,110 do s.RecordVisit({map=1429,x=.5,y=.5,label='Merchant '..i,npcID=1000+i}) end
assert(#ForeverCompanionDB.visitedMerchants==100,'local observations are bounded')
s.ClearVisits();assert(#ForeverCompanionDB.visitedMerchants==0 and #s.ForMap(1429)==3,'clearing visits preserves provider references')
print('PASS: service indexing, faction gates, duplicates, corrected provider rescan, visited provenance, literal atlas search, grouping, favorites and stale navigation')

local old=s.ForMap(1429)[1];names[1]='Renamed current smith';s.RefreshData();s.ForMap(1429)
while #queue>0 do table.remove(queue,1)() end
local fresh=s.Resolve(old);assert(fresh and fresh~=old and fresh.label=='Renamed current smith','revalidation returns the current record rather than an old label/source')
local observed={};for k,v in pairs(fresh) do observed[k]=v end;observed.observed=true
assert(not s.Resolve(observed),'a cleared observed visit cannot impersonate an identical provider reference')

local weapons=s.VendorProfile('Weapons and armor')
local provisions=s.VendorProfile('Food & Drink')
local formulas=s.VendorProfile('Enchanting Formulas')
assert(weapons.label=='Weapons & armor' and provisions.label=='Food & drink')
assert(formulas.label=='Patterns & recipes, Enchanting supplies')
assert(not s.VendorProfile('Waterworks Supervisor'),'match whole words in the reported specialty')
assert(a.Icon('V',provisions)~=a.Icon('V',weapons) and a.Icon('V')~=a.Icon('V',provisions))
assert(a.Icon('R')~=a.Icon('V',weapons))
assert(s.ServiceDetails({symbol='V'}):find('No item examples recorded',1,true))

ForeverCompanionDB.recordMerchantVisits=true
local vendorGUID='Creature-0-1-2-3-1-00001'
UnitGUID=function() return vendorGUID end
UnitName=function() return 'Renamed current smith' end
local stockReady=false
local stockNames={'Heavy Stock','Heavy Stock','Forge Hammer','Basic Shield','Practice Sword','Coarse Stone','Seventh item'}
GetMerchantNumItems=function() return stockReady and #stockNames or 0 end
C_MerchantFrame={GetItemInfo=function(i) return {name=stockNames[i]} end}
events[1].OnEvent(nil,'MERCHANT_SHOW')
assert(not ForeverCompanionDB.visitedMerchants[1].stock)
stockReady=true
events[1].OnEvent(nil,'MERCHANT_UPDATE')
local matches=a.Query(s.ForMap(1429),'Forge Hammer',{source='reference',category='V'})
assert(#matches==1 and matches[1].vendor.npcID==1,'actual visit stock enriches matching reference NPCs')
local vendor=matches[1].vendor
assert(#vendor.stock==5 and vendor.stock[1]=='Heavy Stock' and vendor.stock[2]=='Forge Hammer')
assert(s.ServiceDetails(vendor):find('Also repairs equipment',1,true))
assert(s.ServiceDetails(vendor):find('Previously seen stock: Heavy Stock',1,true))
stockReady=false
events[1].OnEvent(nil,'MERCHANT_SHOW')
events[1].OnEvent(nil,'MERCHANT_CLOSED')
assert(#ForeverCompanionDB.visitedMerchants[1].stock==5,'an unloaded merchant window must not erase recorded examples')
vendorGUID='Creature-0-1-2-3-88-00001'
stockReady=true
events[1].OnEvent(nil,'MERCHANT_UPDATE')
assert(ForeverCompanionDB.visitedMerchants[1].npcID==1,'unmatched updates cannot attach another merchant stock')
C_MerchantFrame=nil
GetMerchantItemInfo=function(i) return stockNames[i] end
assert(s.ReadMerchantStock()[2]=='Forge Hammer','fall back to the legacy merchant API when available')
print('PASS: vendor specialties, distinct icons, repair detail, bounded, searchable and correctly attributed stock samples')
