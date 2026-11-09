CreateFrame=function() return {RegisterEvent=function() end,SetScript=function() end} end
ForeverCompanionDB={}
dofile('ForeverCompanion/MapHub.lua');local h=ForeverCompanionMapHub
local records={{kind='note',label='Mining loop',detail='Gathering',tags='Copper'},
 {kind='quest',label='Lost scout',detail='Reported point'},{kind='service',label='Repair specialist',detail='Repair · reference'},
 {kind='note',label='[literal] note',detail='Reminder'}}
assert(#h.Query(records,'mining copper','all')==1,'all query terms must match')
assert(#h.Query(records,'[literal]','all')==1,'queries are literal, not patterns')
assert(#h.Query(records,'','note')==2 and #h.Query(records,'missing','all')==0)
local many={};for i=1,400 do many[i]={kind='note',label='Spot '..i} end
local found,total=h.Query(many,'Spot','all');assert(#found==300 and total==400,'bounded results retain the true match count')
local point={map=12,x=.4,y=.5,source='Personal map note',id=7,label='Camp'}
assert(h.Record(point,'Camp'));assert(#h.Recent()==1 and h.Recent()[1].kind=='note')
point.x=.8;assert(h.Recent()[1].target.x==.4,'history stores a snapshot rather than a mutable source table')
h.Record({map=12,x=.4,y=.5,source='Personal map note',id=7},'Camp again');assert(#h.Recent()==1,'repeat navigation refreshes an entry')
for i=1,30 do h.Record({map=12,x=i/100,y=.5},'Spot '..i) end
assert(#h.Recent()==20,'history is bounded')
ForeverCompanionDB.mapHub.remember=false;assert(not h.Record(point,'Paused'));assert(#h.Recent()==20)
assert(not h.Record({map=12,x=2,y=.5},'Invalid'))
local navigated,selected
ForeverCompanionMapTools={Navigate=function(id) if id==7 then navigated=id;return 'Note navigation' end;return 'Note removed' end}
assert(h.Activate({kind='note',noteID=8})=='Note removed' and not navigated)
assert(h.Activate({kind='note',noteID=7})=='Note navigation' and navigated==7)
local q={id=1,title='Live quest'};local active=true
ForeverCompanionQuestPlanner={IsSupported=function() return active end,GetLive=function() return {q} end,Select=function(i) selected=i end}
local target={map=12,x=.3,y=.2}
ForeverCompanionQuestWaypoints={Targets=function() return {target} end,Navigate=function(t,_,_,id) navigated=t;assert(id==1);return 'Quest navigation' end,Show=function() return 'Inspect quest' end}
local r={kind='quest',questID=1,target=target}
assert(h.Activate(r)=='Quest navigation' and navigated==target and selected==1)
navigated=nil;assert(h.Activate({kind='quest',questID=1,target={map=12,x=.9,y=.9}}):find('changed') and not navigated)
assert(h.Activate({kind='quest',questID=99}):find('no longer active'))
active=false;assert(h.Activate(r):find('unavailable'))
local checked=false;ForeverCompanionServiceAtlas={Navigate=function() checked=true;return 'Revalidated service' end}
assert(h.Activate({kind='service',target=target})=='Revalidated service' and checked)
h.ClearRecent();assert(#h.Recent()==0)
print('PASS: unified literal search, result bounds, history snapshots, pause/clear and source revalidation')

-- Search services with a known zone even when player coordinates are unavailable.
C_Map={GetBestMapForUnit=function() return 12 end}
ForeverCompanionMapTools.List=function() return {{id=7,map=13,x=.2,y=.3,label='Old note'}} end
ForeverCompanionMapTools.NoteStyle=function() return {name='General'} end
ForeverCompanionTownServices={ForMap=function(map) assert(map==12);return {{map=12,x=.4,y=.5,label='Repair'}} end}
ForeverCompanionServiceAtlas.Query=function(points) return {{label=points[1].label,target=points[1],roles='Repair'}} end
local snapshot=h.Snapshot();assert(#snapshot==2,'all-zone notes and current-zone services remain searchable without distance data')
-- Only successful navigation enters history.
ForeverCompanionDB.mapHub.remember=true;h.ClearRecent()
local succeeds=true
ForeverCompanionQuestDirection={Stop=function() end,Start=function() return succeeds end}
dofile('ForeverCompanion/QuestWaypoints.lua')
local w=ForeverCompanionQuestWaypoints
assert(w.Navigate({map=12,x=.3,y=.2},false,'Live quest',1)=='On-screen arrow active')
assert(#h.Recent()==1 and h.Recent()[1].questID==1)
succeeds=false;w.Navigate({map=12,x=.9,y=.9},false,'Unavailable')
assert(#h.Recent()==1,'failed navigation cannot create a history entry')
