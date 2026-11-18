local root, buttons, events
local noop=function() end
local function widget()
 return setmetatable({}, {__index=function(_,key)
  if key=='Show' then return function(self) self.visible=true;self.shows=(rawget(self,'shows') or 0)+1 end end
  if key=='Hide' then return function(self) self.visible=false end end
  if key=='SetText' then return function(self,value) self.text=value end end
  if key=='SetScript' then return function(self,event,fn) self[event]=fn end end
  return noop
 end})
end
buttons={}
CreateFrame=function() root=widget();return root end
ForeverCompanionInterface={Surface=noop,PreparePanel=noop,CloseButton=noop,Text=widget,
 Button=function() local b=widget();buttons[#buttons+1]=b;return b end}
local opened=0
ForeverCompanionWalkthrough={Open=function() opened=opened+1 end}
dofile('ForeverCompanion/WelcomeTour.lua')
local tour=ForeverCompanionWelcomeTour
tour.FirstLogin();assert(root.visible and root.shows==1 and ForeverCompanionTutorialDB.welcomeTourSeen)
buttons[2].OnClick();assert(not root.visible)
tour.FirstLogin();assert(root.shows==1)
tour.Open();assert(root.shows==2)
for i=1,5 do buttons[3].OnClick() end
assert(opened==1 and not root.visible,'the tutorial finishes at the leveling guide')

CreateFrame=function() events=widget();return events end
UnitName=function() return 'Tester' end
GetRealmName=function() return 'Realm' end
time=function() return 123 end
local loaded,total,count=1,1,1
GetInboxNumItems=function() return loaded,total end
GetInboxHeaderInfo=function() return nil,nil,'Sender',nil,nil,nil,nil,count end
GetInboxItem=function(_,slot) if slot==1 and count==1 then return 'Test item',12,13,2 end end
GetInboxItemLink=function() return nil end
dofile('ForeverCompanion/BankView.lua')
local function fire(event) events.OnEvent(events,event) end
fire('MAIL_SHOW')
local record=ForeverCompanionInventoryDB['Tester - Realm']
local full=record.mail
assert(full.total==1 and full.items[1].id==12)
loaded,total,count=1,4,0;fire('MAIL_INBOX_UPDATE')
assert(record.mail==full and record.partialMail.total==4)
total=nil;fire('MAIL_INBOX_UPDATE');assert(record.mail==full)
loaded,total,count=1,1,2;fire('MAIL_INBOX_UPDATE');assert(record.mail==full)
loaded,total,count=0,0,0;fire('MAIL_INBOX_UPDATE')
assert(record.mail.total==0 and #record.mail.items==0 and record.partialMail==nil)
fire('MAIL_CLOSED');loaded,total,count=1,1,1;fire('MAIL_INBOX_UPDATE')
assert(record.mail.total==0)
print('PASS: first-login tutorial, replay, guide handoff and complete mailbox snapshot preservation')
