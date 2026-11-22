dofile('ForeverCompanion/DungeonCatalog.lua')
dofile('ForeverCompanion/DungeonRoutes.lua')
dofile('ForeverCompanion/DungeonMaps.lua')
local D=ForeverCompanionDungeonMaps
local map,group,instanceName,kind=512,8,"The Deadmines","party"
local maps={[512]={name="The Deadmines",mapType=4},[513]={name="The Deadmines",mapType=4},[23]={name="Westfall",mapType=3},[811]={name="Other dungeon",mapType=4}}
GetInstanceInfo=function() return instanceName,kind,nil,nil,nil,nil,nil,36 end
local secret={}
issecretvalue=function(n) return n==secret end
Enum={UIMapType={Zone=3,Dungeon=4,Micro=5}}
C_Map={
 GetBestMapForUnit=function(unit) assert(unit=="player");return map end,
 GetMapInfo=function(id) return maps[id] end,
 GetMapGroupID=function(id) return id==811 and 9 or group end,
 GetMapGroupMembersInfo=function(id)
  assert(id==8)
  return {{mapID=513,name="The Deadmines",relativeHeightIndex=2},{mapID=512,name="The Deadmines",relativeHeightIndex=1},
   {mapID=23},{mapID=811},{mapID=512},{mapID=secret},secret}
 end,
 GetPlayerMapPosition=function(id,unit)
  assert(id==map and unit=="player")
  return {GetXY=function() return .4,.65 end}
 end,
}
local name,current,instance=D.Current()
assert(name=="The Deadmines" and current==512 and instance==36)
local floors=D.Floors(map)
assert(#floors==2 and floors[1].map==512 and floors[2].map==513 and floors[1].name=="Floor 1" and floors[2].name=="Floor 2")
local x,y=D.PlayerPoint(512);assert(x==.4 and y==.65 and D.PlayerPoint(513)==nil)
EJ_GetMapEncounter=function(id,i)
 assert(id==512)
 if i==1 then return .33,.51,nil,"Sneed",nil,6 end
 if i==2 then return secret,.5,nil,"Unreadable",nil,7 end
 if i==3 then return 0,0,nil,"Placeholder",nil,8 end
 if i==4 then return .9,.3,nil,"Gilnid",nil,9 end
end
local pins=D.BossPins(map)
assert(#pins==2 and pins[1].name=="Sneed" and pins[2].name=="Gilnid")
group=secret;assert(#D.Floors(map)==1)
map=23;assert(select(2,D.Current())==nil and #D.Floors(map)==0 and #D.BossPins(map)==0)
kind="none";assert(D.Current()==nil and D.Open():find("Dungeon Journal",1,true))
local count=0
for dungeon,paths in pairs(ForeverCompanionDungeonRoutes) do
 assert(ForeverCompanionDungeonCatalog.entries[dungeon] and paths.source and #paths>0)
 for _,path in ipairs(paths) do assert(path.name and #path>=2 and #path<=8) end
 count=count+1
end
assert(count==10)
print("PASS: interior map guards, grouped floors, same-floor player coordinates, confirmed boss pins and ten dungeon route sets")

