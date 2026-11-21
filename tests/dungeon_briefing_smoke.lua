dofile('ForeverCompanion/DungeonCatalog.lua')
dofile('ForeverCompanion/DungeonBriefing.lua')
local catalog,briefing=ForeverCompanionDungeonCatalog,ForeverCompanionDungeonBriefing
local controls,navigation,journal={},nil,nil
local function noop() end
local function widget()
 return {SetSize=noop,SetPoint=noop,SetFrameLevel=noop,SetClampedToScreen=noop,EnableMouse=noop,
  GetFrameLevel=function() return 1 end,SetWidth=noop,Show=noop,Hide=noop,
  SetText=function(self,value) self.text=value end,SetShown=function(self,value) self.shown=value end,
  SetEnabled=function(self,value) self.enabled=value end,
  SetScript=function(self,_,action) controls[self.text]=self;self.click=action end}
end
CreateFrame=widget
ForeverCompanionInterface={Text=widget,Button=widget,Surface=noop,palette={},SetHoverHelp=noop,
 CloseButton=function(_,action) controls.close=action end}
ForeverCompanionQuestWaypoints={Navigate=function(target,showMap,name)
 navigation={target=target,showMap=showMap,name=name};return 'Directions set'
end}
ForeverCompanionOpenDungeonJournal=function(name,quests) journal={name=name,quests=quests} end

local function location(map,name)
 for _,p in ipairs(catalog.MapLocations(map)) do
  for _,groupName in ipairs(p.names) do if groupName==name then return p end end
 end
 error('Missing map location: '..name)
end
local owner=widget()
local group=location(1420,'Scarlet Monastery: Armory')
assert(#group.names==4)
local selection={location=group,index=1}
local dismissed=false
local function dismiss() dismissed=true end
briefing.Show(owner,selection,dismiss)
assert(controls['>'].enabled and not controls['<'].enabled)
controls['>'].click()
briefing.Hide()
briefing.Show(owner,selection,dismiss)
controls['Dungeon quests'].click()
assert(journal.name==group.names[2] and journal.quests)
controls['Route to approach'].click()
assert(navigation.target==group and not navigation.showMap and navigation.name==group.names[2]..' approach')
controls.close()
assert(dismissed)

local serviceGate=location(1423,'Stratholme: Service Gate')
briefing.Show(owner,{location=serviceGate,index=1},dismiss)
controls['Bosses & loot'].click()
assert(journal.name=='Stratholme' and journal.quests==false)
controls['Route to approach'].click()
assert(navigation.target==serviceGate and navigation.target.x==.419)
assert(not controls['>'].shown)

local riverglades=catalog.MapLocations(2548)[1]
assert(riverglades.approximate)
briefing.Show(owner,{location=riverglades,index=1},dismiss)
assert(not controls['Route to approach'].enabled)
navigation=nil
controls['Route to approach'].click()
assert(not navigation)
briefing.Hide()
journal=nil
controls['Dungeon quests'].click()
assert(not journal)
print('PASS: shared dungeon entrances, journal views, and approximate routing guards')
