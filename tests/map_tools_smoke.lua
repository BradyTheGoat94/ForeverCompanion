ForeverCompanionDB={}
local map,x,y=12,.4,.5
C_Map={GetBestMapForUnit=function() return map end,GetPlayerMapPosition=function() return {GetXY=function() return x,y end} end}
local navigated,menu
ForeverCompanionQuestWaypoints={Navigate=function(p) navigated=p;return 'Navigating' end}
ForeverCompanionTownServices={Valid=function(p) return type(p)=='table' and p.map and p.x and p.y and p.label and p.symbol end}
ForeverCompanionServiceAtlas={Key=function(p) return p.label..p.x..p.y end,Navigate=function(p) navigated=p;return 'Navigating' end}
ForeverCompanionInterface={Menu=function(_,_,entries) menu=entries end}
dofile('ForeverCompanion/MapTools.lua');local t=ForeverCompanionMapTools
local a=t.SaveHere('  Farm | spot\n');assert(a.label=='Farm  spot' and a.map==12 and a.x==.4)
local b=t.Add('Another zone',13,.2,.3);assert(#t.List(12)==1 and #t.List()==2)
assert(t.Rename(a.id,'New name') and t.Find(a.id).label=='New name')
assert(t.SetCategory(a.id,'rare') and t.NoteStyle(a).name=='Rare sightings')
assert(#t.List(nil,'rare')==1 and #t.List(nil,'farming')==0)
assert(not t.SetCategory(a.id,'invalid') and t.NoteStyle(b).key=='general','old notes retain a valid default category')
assert(t.Navigate(a.id)=='Navigating' and navigated==a)
assert(t.Remove(a.id));navigated=nil;t.Navigate(a.id);assert(not navigated,'deleted notes cannot start old navigation')
local c=t.SaveHere('New note');assert(c.id>b.id and c.id~=a.id,'deleted IDs are never recycled')
assert(t.ToggleFavorite(c.id) and t.List()[1].id==c.id and #t.List(nil,'starred')==1)
assert(t.Remove(c.id));local ok=t.UndoRemove();assert(ok and t.Find(c.id).favorite,'undo restores stable identity and note organization')
assert(not t.UndoRemove(),'a deletion is restored only once')
x=nil;assert(not t.SaveHere('Unavailable'));x=.4
assert(not t.Add('',12,.1,.1));assert(not t.Add('Invalid',12,0/0,.5))
local unicode=string.rep(string.char(195,169),41);local u=t.SaveHere(unicode);assert(#u.label==80 and u.label:byte(80)==169,'UTF-8 truncation stays on a complete character')
ForeverCompanionDB.mapNotes={false,{id=7,map=12,x=99,y=.1,label='Broken'}};assert(#t.List()==0);assert(not t.Remove(5))
ForeverCompanionDB.mapNotes={};for i=1,100 do assert(t.SaveHere('Spot '..i)) end;assert(not t.SaveHere('Overflow'))
local points={{map=12,x=.41,y=.51,label='Close repair',symbol='R'},{map=12,x=.9,y=.9,label='Far repair',symbol='R'},
 {map=12,x=.4,y=.5,label='Mail',symbol='M'},{map=13,x=.4,y=.5,label='Other zone',symbol='R'}}
local ranked,basis,yards=t.RankServices(points,12,.4,.5,'R');assert(#ranked==2 and ranked[1].target.label=='Close repair' and not yards and basis:find('Approximate'))
assert(#t.RankServices(points,12,nil,.5,'R')==0,'unknown position cannot claim nearest')
CreateVector2D=function(a,b) return {GetXY=function() return a*1000,b*2000 end} end
C_Map.GetWorldPosFromMapPos=function(_,v) return 1,v end
ranked,basis,yards=t.RankServices(points,12,.4,.5,'R');assert(yards and math.abs(ranked[1].distance-math.sqrt(500))<.001)
local convert=C_Map.GetWorldPosFromMapPos
C_Map.GetWorldPosFromMapPos=function(_,v) local a=v:GetXY();if a>800 then return nil end;return 1,v end
local fallback,_,measured=t.RankServices(points,12,.4,.5,'R');assert(not measured and fallback[1].distance<1,'one missing conversion makes all distances approximate rather than mixing units')
C_Map.GetWorldPosFromMapPos=convert
ForeverCompanionTownServices.ForMap=function() return points end
assert(t.Nearest('repair'):find('Straight%-line'))
assert(navigated==nil,'lookup waits for an explicit destination choice');menu[2].action();assert(navigated==points[1])
assert(t.Nearest('unknown'):find('Choose'))
print('PASS: personal note persistence, UTF-8, CRUD, ID stability, limits, stale rejection and nearest-service provenance')

ForeverCompanionQuestLocations={ForQuest=function() return {} end,Provider=function() return nil end}
dofile('ForeverCompanion/QuestWaypoints.lua');local w=ForeverCompanionQuestWaypoints
assert(w.Describe({kind='monster',objectiveIndex=1}):find('search reference'))
assert(w.Describe({source='WoW quest map'}):find('general search area'))
assert(w.Describe({observed=true}):find('player position'))
assert(w.Explain({id=1},12):find('unavailable'))
ForeverCompanionQuestLocations.Provider=function() return {} end
assert(w.Explain({id=1},12):find('no location is guessed'))
ForeverCompanionQuestLocations.ForQuest=function() return {{map=13,x=.4,y=.5,kind='monster',objectiveIndex=1}} end
assert(w.Explain({id=1},12):find('other maps'))
