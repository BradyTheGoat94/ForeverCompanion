local eventFrame
CreateFrame=function()
 eventFrame={RegisterEvent=function() end,SetScript=function(self,key,fn) self[key]=fn end};return eventFrame
end
ForeverCompanionDB={}
local clock=1000
GetServerTime=function() return clock end
UnitLevel=function() return 20 end
C_Map={GetBestMapForUnit=function() return 1429 end,GetMapInfo=function() return {name='Reported forest'} end}
C_QuestLog={GetTitleForQuestID=function(id) return id==1 and 'Reported quest' or nil end,GetAllCompletedQuestIDs=function() error('historical flags must not create dated events') end}
dofile('ForeverCompanion/QuestHistory.lua')
local H=ForeverCompanionQuestHistory
assert(#H.List()==0)
assert(H.Record(1,250,12345))
clock=1001;assert(H.Record(1,0,0))
clock=1002;eventFrame.OnEvent(eventFrame,'QUEST_TURNED_IN',2,nil,nil)
local entries=H.List()
assert(#entries==3 and entries[1].id==2 and entries[1].title=='Quest 2' and entries[1].xp==nil)
assert(entries[2].xp==0 and entries[2].money==0 and entries[2].at==1001 and entries[2].map==1429)
local stats=H.Summary(entries)
assert(stats.turnins==3 and stats.unique==2 and stats.xp==250 and stats.xpKnown==2 and stats.money==12345)
assert(H.Money(12345)=='1g 23s 45c' and H.Money(nil)=='Not reported')
assert(#H.List('REPORTED QUEST')==2 and #H.List('[',1429)==0 and #H.List('',99)==0)
local stable=entries[2].sequence
H.limit=3;clock=1003;assert(H.Record(3,100,5))
entries=H.List();assert(#entries==3 and entries[3].sequence==stable,'retention preserves stable turn-in identities')
ForeverCompanionDB.questHistory.entries[#ForeverCompanionDB.questHistory.entries+1]={id=-1,title={}}
assert(#H.List()==3,'corrupt saved entries are ignored')
GetServerTime=nil;time=nil;C_Map=nil
assert(H.Record(4,-2,0/0));entries=H.List()
assert(entries[1].at==nil and entries[1].map==nil and entries[1].xp==nil and entries[1].money==nil,'missing evidence stays unknown')
assert(not H.Record(0/0,5,5) and not H.Record(-1,5,5))
assert(H.Record(6,nil,nil,{quest={id=6,title=string.rep('a',149)..'\226\130\172'}}))
assert(#H.List()[1].title==149,'saved titles must not split UTF-8 characters at the byte limit')
dofile('ForeverCompanion/QuestBook.lua')
local B=ForeverCompanionQuestBook
local catalog={{id=1,title='Completed',status='completed'},{id=2,title='Available',status='available'},{id=3,title='Active',status='active'},{id=4,title='Blocked',status='locked',dependencies={'Earlier quest'}}}
assert(B.FilterCatalog(catalog,'','all')[1].id==3)
assert(#B.FilterCatalog(catalog,'EARLIER','all')==1)
assert(#B.FilterCatalog(catalog,'','completed')==1 and #B.FilterCatalog(catalog,'[','all')==0)
stats=B.Counts(catalog);assert(stats.total==4 and stats.completed==1 and stats.available==1 and stats.locked==1)
print('PASS: observed history, repeatable turn-ins, rewards, missing evidence, bounded persistence, stable identities and catalog filters')
