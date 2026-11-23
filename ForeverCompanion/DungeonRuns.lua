-- Observed results are scoped to a five-player instance and saved only on request.
local R={limit=40}
ForeverCompanionDungeonRuns=R

local active,previous
local registered={}
local function public(v) return not (issecretvalue and issecretvalue(v)) end
local function finite(v)
 return public(v) and type(v)=="number" and v==v and v>=0 and v<math.huge
end
local function text(v)
 if public(v) and type(v)=="string" and v~="" then return v end
end
local function read(fn,...)
 if type(fn)~="function" then return end
 local ok,a,b,c,d,e,f,g,h=pcall(fn,...)
 if ok then return a,b,c,d,e,f,g,h end
end
local function clock()
 local now=read(GetTime)
 if finite(now) then return now end
end

-- Compile the locale's format strings, including positional substitutions.
local patterns={}
local function formatPattern(fmt)
 local cached=patterns[fmt]
 if cached then return cached.pattern,cached.slots end
 local parts,slots={},{}
 local start=1
 local function literal(s) return (s:gsub("([^%w])","%%%1")) end
 for first,token,after in fmt:gmatch("()%%([%d%$]*[sd%%])()") do
  parts[#parts+1]=literal(fmt:sub(start,first-1))
  start=after
  if token=="%" then parts[#parts+1]="%%"
  else
   slots[#slots+1]=tonumber(token:match("^(%d+)%$")) or (#slots+1)
   parts[#parts+1]=token:sub(-1)=="d" and "(%d+)" or "(.-)"
  end
 end
 parts[#parts+1]=literal(fmt:sub(start))
 local pattern=table.concat(parts)
 patterns[fmt]={pattern=pattern,slots=slots}
 return pattern,slots
end
local function captures(message,fmt)
 if not text(fmt) then return end
 local pattern,slots=formatPattern(fmt)
 if #slots==0 then return end
 local values={message:match("^"..pattern.."$")}
 if not values[1] then return end
 local result={}
 for i,slot in ipairs(slots) do result[slot]=values[i] end
 return result
end
local lootFormats={
 "LOOT_ITEM_SELF_MULTIPLE","LOOT_ITEM_PUSHED_SELF_MULTIPLE","LOOT_ITEM_BONUS_ROLL_SELF_MULTIPLE",
 "LOOT_ITEM_SELF","LOOT_ITEM_PUSHED_SELF","LOOT_ITEM_BONUS_ROLL_SELF",
}
function R.Loot(message)
 if not text(message) then return end
 for _,key in ipairs(lootFormats) do
  local args=captures(message,_G[key])
  local link=args and args[1]
  if link then
   local payload,name=link:match("|H(item:%d+[^|]*)|h%[([^|]+)%]|h")
   local count=args[2] and tonumber(args[2]) or 1
   if payload and #link<=1024 and count and count>0 and count<=100000 then
    local colored=link:match("^|c%x%x%x%x%x%x%x%x|Hitem:.-|h.-|h|r$")
    return payload,colored and link or ("|H"..payload.."|h["..name.."]|h"),name,count
   end
  end
 end
end
local moneyFormats={"YOU_LOOT_MONEY_GUILD","LOOT_MONEY_SPLIT_GUILD","YOU_LOOT_MONEY","LOOT_MONEY_SPLIT"}
local denominations={{"GOLD_AMOUNT","Gold",10000},{"SILVER_AMOUNT","Silver",100},{"COPPER_AMOUNT","Copper",1}}
local function coinPart(amount,template)
 local prefix,choices,suffix=template:match("^(.-)|4([^;]+);(.*)$")
 if prefix then
  for form in choices:gmatch("[^:]+") do
   local value=coinPart(amount,prefix..form..suffix)
   if value then return value end
  end
  return
 end
 local pattern,slots=formatPattern(template)
 if #slots==1 then return tonumber(amount:match(pattern)) end
end
function R.Coin(message)
 if not text(message) then return end
 local amount
 for _,key in ipairs(moneyFormats) do
  local args=captures(message,_G[key])
  if args then amount=args[1];break end
 end
 if not amount then return nil,false end
 amount=amount:gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r","")
 local total,found=0,false
 for _,coin in ipairs(denominations) do
  local template,texture,factor=_G[coin[1]],coin[2],coin[3]
  local n=text(template) and coinPart(amount,template)
  if not n then n=tonumber(amount:match("(%d+)%s*|T[^|]-UI%-"..texture.."Icon[^|]*|t")) end
  if finite(n) then total=total+n*factor;found=true end
 end
 if found and finite(total) then return total,true end
 return nil,true
end

local function xpSample(unit)
 local level=read(UnitLevel,unit)
 local xp,max
 if unit=="pet" then xp,max=read(GetPetExperience)
 else xp,max=read(UnitXP,"player"),read(UnitXPMax,"player") end
 if finite(level) and level>0 and finite(xp) and finite(max) and max>0 and xp<=max then
  return {level=level,xp=xp,maximum=max}
 end
end
local function advance(before,sample)
 local gain=ForeverCompanionSessionProgress.Delta(before,sample)
 -- Level-up and XP events can arrive while one of the two values still
 -- describes the old level. Keep the last baseline until they agree.
 if before and sample and not gain and sample.level==before.level then return 0,before end
 return gain or 0,sample
end
local function trackXP(run,unit)
 local sample=xpSample(unit)
 if unit=="player" then
  local gain,baseline=advance(run.playerSample,sample)
  run.playerSample=baseline
  if sample then run.xp=(run.xp or 0)+gain end
  return
 end
 local guid=sample and text(read(UnitGUID,"pet"))
 if not guid then run.petSample=nil;run.petGUID=nil;return end
 local pet=run.petIndex[guid]
 if not pet and #run.pets<24 then
  pet={name=text(read(UnitName,"pet")) or "Hunter pet",xp=0}
  run.petIndex[guid]=pet
  run.pets[#run.pets+1]=pet
 end
 if pet and run.petGUID==guid then
  local gain,baseline=advance(run.petSample,sample)
  pet.xp=pet.xp+gain
  sample=baseline
 end
 run.petGUID,run.petSample=guid,sample
end
local function identity()
 local name,kind,difficulty,difficultyName,_,_,_,id=read(GetInstanceInfo)
 if not public(kind) or kind~="party" or not text(name) then return end
 return name,finite(id) and id or 0,finite(difficulty) and difficulty or 0,text(difficultyName)
end
local function finish()
 if not active then return end
 active.finished=clock() or active.start
 previous,active=active,nil
end
local function sync(partial)
 local name,id,difficulty,mode=identity()
 if active and (active.name~=name or active.instance~=id or active.difficulty~=difficulty) then finish() end
 if not active and name then
  local stamp=read(GetServerTime)
  active={name=name,instance=id,difficulty=difficulty,mode=mode,start=clock(),stamp=finite(stamp) and stamp or nil,
   partial=partial==true,coins=0,coinUnknown=false,bosses={},bossIndex={},items={},itemIndex={},pets={},petIndex={}}
  trackXP(active,"player")
  trackXP(active,"pet")
 end
 return active
end

local function store()
 ForeverCompanionDB=ForeverCompanionDB or {}
 local db=ForeverCompanionDB
 if type(db.dungeonResults)~="table" then db.dungeonResults={} end
 local saved=db.dungeonResults
 if type(saved.runs)~="table" then saved.runs={} end
 return saved
end
local function snapshot(run)
 local ending=run.finished or clock()
 local out={id=run.id,name=run.name,mode=run.mode,stamp=run.stamp,
  seconds=ending and run.start and math.max(0,math.floor(ending-run.start)) or nil,
  complete=run.complete,partial=run.partial,ongoing=run==active,coins=run.coins,
  coinUnknown=run.coinUnknown or not registered.CHAT_MSG_MONEY,lootAvailable=registered.CHAT_MSG_LOOT,
  itemsCapped=run.itemsCapped,xp=run.xp,bosses={},items={},pets={}}
 for _,key in ipairs({"bosses","items","pets"}) do
  for i,entry in ipairs(run[key]) do
   local copy={}
   for k,v in pairs(entry) do copy[k]=v end
   out[key][i]=copy
  end
 end
 return out
end
function R.View(which)
 local run=which=="last" and previous or (which~="last" and active)
 if run then return snapshot(run) end
end
function R.Save(which)
 local run=which=="last" and previous or (which~="last" and active)
 if not run then return end
 local saved=store()
 if not run.id then
  local n=saved.lastID
  saved.lastID=(finite(n) and n or 0)+1
  run.id=saved.lastID
 end
 local result=snapshot(run)
 for i,entry in ipairs(saved.runs) do
  if type(entry)=="table" and entry.id==run.id then table.remove(saved.runs,i);break end
 end
 table.insert(saved.runs,1,result)
 while #saved.runs>R.limit do table.remove(saved.runs) end
 return result
end
function R.History() return store().runs end

local root,summary,heading,note,status,viewButtons,saveButton
local views={current="Current run",last="Last run",saved="Saved runs"}
local viewsOrder={"current","last","saved"}
local detailButtons,rows,back,nextPage
local view,section,page,selection="current","items",1
local sections={{"items","Items"},{"bosses","Bosses"},{"pets","Pet XP"}}
local function amount(number)
 return finite(number) and (BreakUpLargeNumbers and BreakUpLargeNumbers(number) or tostring(number)) or "Unavailable"
end
local function duration(seconds)
 return finite(seconds) and ForeverCompanionSessionProgress.Duration(seconds) or "Unavailable"
end
local function coin(value)
 if not finite(value) then return "Unavailable" end
 return GetCoinTextureString and GetCoinTextureString(value) or ("%dg %ds %dc"):format(
  math.floor(value/10000),math.floor(value/100)%100,value%100)
end
local function selected()
 if view~="saved" then return R.View(view) end
 local history=R.History()
 for _,run in ipairs(history) do
  if type(run)=="table" and run.id==selection then return run end
 end
 return type(history[1])=="table" and history[1] or nil
end
local function pickHistory(anchor)
 local choices={}
 for _,run in ipairs(R.History()) do
  if type(run)=="table" and text(run.name) then
   local id=run.id
   local day=finite(run.stamp) and read(date,"%b %d %H:%M",run.stamp)
   choices[#choices+1]={label=run.name.."  |  "..(day or "Saved run").."  |  "..duration(run.seconds),
    selected=id==selection,action=function() selection=id;page=1;R.Refresh() end}
  end
 end
 ForeverCompanionInterface.PagedMenu(anchor,"SAVED DUNGEON RUNS",choices,nil,390)
end
function R.Refresh()
 if not root or not root:IsShown() then return end
 local U=ForeverCompanionInterface
 local run=selected()
 if view=="saved" and run then selection=run.id end
 for _,key in ipairs(viewsOrder) do U.StyleButton(viewButtons[key],nil,key==view) end
 for _,pair in ipairs(sections) do U.StyleButton(detailButtons[pair[1]],nil,section==pair[1]) end
 saveButton:SetText(view=="saved" and "Choose saved run" or run and run.id and "Update saved run" or "Save run")
 saveButton:SetEnabled(run~=nil)
 heading:SetText(run and run.name or views[view])
 note:SetText(run and ((run.complete and "Completion reported" or run.ongoing and "In progress" or "Left instance")
   ..(run.mode and "  |  "..run.mode or "")..(run.partial and "  |  Tracking started inside" or ""))
   or (view=="saved" and "No saved dungeon runs." or "No run recorded for this view."))
 local defeats=0
 for _,boss in ipairs(run and run.bosses or {}) do if boss.defeated then defeats=defeats+1 end end
 summary[1].value:SetText(run and duration(run.seconds) or "-")
 summary[2].value:SetText(run and (not run.coinUnknown and coin(run.coins) or run.coins>0 and coin(run.coins).."+" or "Unavailable") or "-")
 summary[3].value:SetText(run and amount(run.xp) or "-")
 summary[4].value:SetText(run and tostring(defeats) or "-")
 local list=run and run[section] or {}
 if type(list)~="table" then list={} end
 local pages=math.max(1,math.ceil(#list/#rows))
 page=math.max(1,math.min(page,pages))
 for i,row in ipairs(rows) do
  local entry=list[(page-1)*#rows+i]
  row.entry=entry
  row:SetShown(type(entry)=="table")
  if type(entry)=="table" then
   row.name:SetText(section=="items" and entry.link or entry.name)
   local wipes=entry.wipes or 0
   row.value:SetText(section=="items" and ("x"..amount(entry.count)) or section=="pets" and (amount(entry.xp).." XP")
    or ((entry.defeated and "Defeated" or "Attempted").."  |  "..wipes.." failed"))
  end
 end
 back:SetEnabled(page>1);nextPage:SetEnabled(page<pages)
 root.page:SetText(page.." / "..pages)
 local empty={items="No items recorded.",bosses="No encounter results reported.",pets="No trackable pet XP recorded."}
 root.empty:SetShown(run~=nil and #list==0)
 root.empty:SetText(section=="items" and run and not run.lootAvailable and "Item tracking was unavailable." or empty[section])
 root.truncated:SetShown(run and section=="items" and run.itemsCapped==true or false)
end

local function create()
 local U=ForeverCompanionInterface
 local name="ForeverCompanionDungeonResults"
 root=CreateFrame("Frame",name,UIParent,"BackdropTemplate")
 root:SetSize(740,460);root:SetPoint("CENTER");root:SetFrameStrata("DIALOG")
 U.Surface(root);U.PreparePanel(root,name,740,460);U.CloseButton(root,function() U.CloseMenu();root:Hide() end)
 local function textLine(x,y,w,size)
  local f=U.Text(root,size);f:SetPoint("TOPLEFT",x,-y);f:SetWidth(w);f:SetJustifyH("LEFT");return f
 end
 local function button(x,y,width,title,action)
  local b=U.Button(root);b:SetPoint("TOPLEFT",x,-y);b:SetSize(width,27)
  b:SetText(title);b:SetScript("OnClick",action);return b
 end
 heading=textLine(16,12,690,20);note=textLine(16,40,694,12)
 viewButtons={}
 for i,key in ipairs(viewsOrder) do
  local choice=key
  viewButtons[key]=button(16+(i-1)*139,63,131,views[key],function()
   view=choice;page=1;status:SetText("");R.Refresh()
  end)
 end
 saveButton=button(548,63,176,"Save run",function(self)
  if view=="saved" then return pickHistory(self) end
  local run=R.Save(view)
  if run then status:SetText("Run saved on this character.");R.Refresh() end
 end)
 summary={
  U.MetricTile(root,16,105,170,"Time in instance","Measured from when tracking began."),
  U.MetricTile(root,195,105,170,"Coin looted","Includes your share of coin loot reported by the game."),
  U.MetricTile(root,374,105,170,"Character XP","Experience observed while inside the dungeon."),
  U.MetricTile(root,553,105,171,"Bosses defeated","Count of unique encounter victories reported by the game."),
 }
 detailButtons={}
 for i,pair in ipairs(sections) do
  local key=pair[1]
  detailButtons[key]=button(16+(i-1)*111,179,104,pair[2],function() section=key;page=1;R.Refresh() end)
 end
 status=textLine(365,186,355,11);status:SetJustifyH("RIGHT")
 rows={}
 for i=1,7 do
  local row=CreateFrame("Button",nil,root)
  row:SetPoint("TOPLEFT",16,-216-(i-1)*26);row:SetSize(708,24);U.Surface(row,{flat=true})
  row.name=U.Text(row,12);row.name:SetPoint("LEFT",8,0);row.name:SetWidth(513);row.name:SetJustifyH("LEFT")
  row.value=U.Text(row,12);row.value:SetPoint("RIGHT",-8,0);row.value:SetWidth(165);row.value:SetJustifyH("RIGHT")
  row:SetScript("OnEnter",function(self)
   if section=="items" and GameTooltip and self.entry and self.entry.link then
    GameTooltip:SetOwner(self,"ANCHOR_RIGHT");GameTooltip:SetHyperlink(self.entry.link);GameTooltip:Show()
   end
  end)
  row:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
  rows[i]=row
 end
 root.empty=textLine(20,240,690,12)
 root.truncated=textLine(20,400,695,10);root.truncated:SetText("This run reached the saved item limit.")
 back=button(16,421,96,"Previous",function() page=page-1;R.Refresh() end)
 nextPage=button(628,421,96,"Next",function() page=page+1;R.Refresh() end)
 root.page=textLine(315,427,110,11);root.page:SetJustifyH("CENTER")
 local elapsed=0
 root:SetScript("OnUpdate",function(_,dt)
  if view~="current" or not active or not active.start then return end
  elapsed=elapsed+dt
  if elapsed<1 then return end
  elapsed=0
  local now=clock()
  if now then summary[1].value:SetText(duration(math.max(0,now-active.start))) end
 end)
end
function R.Open()
 if not root then create() end
 view=active and "current" or previous and "last" or "saved"
 page=1;section="items";status:SetText("")
 root:Show();R.Refresh()
end

local frame=CreateFrame("Frame")
for _,event in ipairs({"PLAYER_ENTERING_WORLD","ZONE_CHANGED_NEW_AREA","CHAT_MSG_MONEY","CHAT_MSG_LOOT",
 "PLAYER_XP_UPDATE","PLAYER_LEVEL_UP","UNIT_PET_EXPERIENCE","UNIT_PET","UNIT_LEVEL","ENCOUNTER_END","LFG_COMPLETION_REWARD"}) do
 registered[event]=pcall(frame.RegisterEvent,frame,event)
end
frame:SetScript("OnEvent",function(_,event,a,b,c,d,e)
 local transition=event=="PLAYER_ENTERING_WORLD" or event=="ZONE_CHANGED_NEW_AREA"
 if not active and not transition then return end
 local run=sync(event=="PLAYER_ENTERING_WORLD" and (a==true or b==true))
 if run then
  if event=="CHAT_MSG_MONEY" then
   local n,personal=R.Coin(a)
   if n then run.coins=run.coins+n elseif personal or not public(a) then run.coinUnknown=true end
  elseif event=="CHAT_MSG_LOOT" then
   local key,link,name,count=R.Loot(a)
   if key then
    local item=run.itemIndex[key]
    if item then item.count=item.count+count
    elseif #run.items<240 then
     item={link=link,name=name,count=count}
     run.itemIndex[key]=item;run.items[#run.items+1]=item
    else run.itemsCapped=true end
   end
  elseif event=="PLAYER_XP_UPDATE" or event=="PLAYER_LEVEL_UP" then trackXP(run,"player")
  elseif event=="UNIT_PET_EXPERIENCE" or event=="UNIT_LEVEL" and a=="pet" or event=="UNIT_PET" and a=="player" then trackXP(run,"pet")
  elseif event=="ENCOUNTER_END" and finite(a) and text(b) and finite(e) and (e==0 or e==1) then
   local boss=run.bossIndex[a]
   if not boss and #run.bosses<80 then
    boss={name=b,wipes=0}
    run.bossIndex[a]=boss;run.bosses[#run.bosses+1]=boss
   end
   if boss then if e==1 then boss.defeated=true else boss.wipes=boss.wipes+1 end end
  elseif event=="LFG_COMPLETION_REWARD" then run.complete=true end
 end
 if view~="saved" then R.Refresh() end
end)
