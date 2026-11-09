dofile('ForeverCompanion/QuestDiscovery.lua')
local D=ForeverCompanionQuestDiscovery
local function e(id,title,label,reference,x)
 return {quest={id=id,title=title},target={label=label,map=1,x=x or .2,y=.3},reference=reference}
end
local entries={e(1,'Zebra','Scout',true),e(2,'Apple','Mayor',nil),e(1,'Zebra','Scout',true,.5),e(3,'Alpha','Miner',true)}
local all=D.Filter(entries,'',false)
assert(#all==3 and all[1].quest.id==2 and all[2].quest.id==3)
assert(#all[3].targets==2)
assert(#D.Filter(entries,'SCOUT',false)==1)
assert(#D.Filter(entries,'',true)==1)
assert(#D.Filter(entries,'[',false)==0,'search must be literal')
assert(#D.Filter({},'',false)==0)
C_Map={GetBestMapForUnit=function() return 1429 end}
WorldMapFrame={GetMapID=function() return 1436 end}
assert(D.MapID()==1429 and D.SetZoneMode('viewed') and D.MapID()==1436)
WorldMapFrame=nil;assert(D.MapID()==nil,'missing world map cannot silently reuse another zone')
assert(D.SetZoneMode('player') and D.MapID()==1429 and not D.SetZoneMode('invalid'))
local mixed={e(7,'Mixed','Far reference',true,.9),e(7,'Mixed','Near client',nil,.1),e(7,'Mixed','Duplicate',false,.1)}
local grouped=D.Filter(mixed,'',false)
assert(#grouped==1 and #grouped[1].targets==2 and grouped[1].reference==false)
assert(grouped[1].targets[1].reference==false and grouped[1].targets[2].reference==true,'retain source per location')
assert(mixed[1].target.reference==nil,'never mutate provider locations')
local levels={e(8,'High','A'),e(9,'Low','B'),e(10,'Unknown','C')}
levels[1].quest.level=40;levels[2].quest.level=20
assert(D.Filter(levels,'',false,{sort='level'})[1].quest.id==9)
local nearby=D.Filter(levels,'',false,{nearLevel=true,level=20})
assert(#nearby==2,'unknown quest levels remain visible')
assert(D.Filter({e(11,'Far','A',false,.8),e(12,'Near','B',false,.1)},'',false,{sort='proximity',x=.1,y=.3})[1].quest.id==12)
assert(D.Filter({e(11,'Far','A',false,.8),e(12,'Near','B',true,.1)},'',false,{sort='recommended',x=.1,y=.3})[1].quest.id==11,'recommended pickups prefer client evidence')
local bad=e(50,'Bad','Nowhere');bad.target.x=0/0
assert(#D.Filter({bad},'',false)==0)
bad.target.x=2;assert(#D.Filter({bad},'',false)==0)
local old=e(99,'Old','Giver',false,.2)
assert(D.Resolve({old},99,old.target)==old.target)
assert(D.Resolve({},99,old.target)==nil,'accepted or removed pickup cannot retain navigation')
assert(D.Resolve({e(99,'Moved','Giver',false,.8)},99,old.target)==nil,'changed giver coordinates reject stale navigation')
print('PASS: discovery grouping, per-location sources, deduplication, literal search, levels, proximity and invalid coordinates')
