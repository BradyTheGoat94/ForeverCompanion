
local event
function CreateFrame() return {RegisterEvent=function() end,SetScript=function(_,_,f) event=f end} end
function UnitName() return 'Brady' end
function GetRealmName() return 'Forever' end
function time() return 1000 end
ForeverCompanionDB={bankSnapshot={items={}}}
function GetInboxNumItems() return 1,2 end
function GetInboxHeaderInfo() return nil,nil,'Auction House',nil,nil,nil,nil,1 end
function GetInboxItem(_,slot) if slot==2 then return 'Copper Bar',2840,1,7 end end
function GetInboxItemLink(_,slot) if slot==2 then return 'item:2840' end end
dofile('ForeverCompanion/BankView.lua')
event(nil,'PLAYER_LOGIN');event(nil,'MAIL_SHOW')
local r=ForeverCompanionInventoryDB['Brady - Forever'];assert(r.bank and r.mail.total==2 and r.mail.loaded==1)
assert(r.mail.items[1].id==2840 and r.mail.items[1].count==7)
event(nil,'MAIL_CLOSED');function GetInboxNumItems() return 0,0 end
event(nil,'MAIL_INBOX_UPDATE');assert(#r.mail.items==1)
event(nil,'MAIL_SHOW');event(nil,'MAIL_INBOX_UPDATE');assert(#r.mail.items==0)
function GetInboxNumItems() return 0,2 end
event(nil,'MAIL_INBOX_UPDATE');assert(r.mail.loaded==0 and r.mail.total==0 and r.partialMail.total==2,'retain last complete inbox')
dofile('ForeverCompanion/QuestWaypoints.lua')
ForeverCompanionQuestLocations={ForQuest=function() return {{map=1,x=.4,y=.2,objectiveIndex=2},{map=1,x=.6,y=.2,objectiveIndex=1}} end}
C_Map={GetBestMapForUnit=function() return 1 end}
C_QuestLog={GetQuestsOnMap=function() return {{questID=3,mapID=1,isQuestStart=false,x=.1,y=.1}} end}
local q={id=3,objectiveStates={{done=true},{done=false}}}
assert(ForeverCompanionQuestWaypoints.Location(q).objectiveIndex==2)
C_QuestLog.GetNextWaypoint=function() return 2,.1,.5 end
assert(ForeverCompanionQuestWaypoints.Location(q).map==2)
