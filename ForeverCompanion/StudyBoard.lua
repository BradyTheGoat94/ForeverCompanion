-- Player-controlled study and preparation. Ticks are personal notes, never proof
-- of unlocks, skill ownership, combat readiness, or server mechanics.
local B={}
ForeverCompanionStudyBoard=B
local host,root,heading,summary,evidence,fill,navigate,current,rows,links,progressCaption,nextTask
local classAccents={
 WARRIOR={0.78,0.61,0.43},PALADIN={0.96,0.55,0.73},HUNTER={0.67,0.83,0.45},
 ROGUE={1,0.96,0.41},PRIEST={0.90,0.93,1},SHAMAN={0.20,0.55,1},
 MAGE={0.25,0.78,0.92},WARLOCK={0.63,0.55,0.94},DRUID={1,0.49,0.18}
}
function B.Accent(tab,class)
 if tab=="Leveling" then return (type(class)=="string" and classAccents[class]) or {0.94,0.72,0.32} end
 return tab=="Alts" and {0.29,0.77,0.86} or {0.94,0.72,0.32}
end
local definitions={
 Legacy={title="LEGACY RESEARCH DESK",tasks={
  "Locate the Legacy interface and record its unlock requirement.",
  "Check whether progress belongs to this character or the account.",
  "Read reward costs and prerequisites before spending resources.",
  "Confirm reset rules and whether benefits apply to an alt.",
  "Record a source and client version for confirmed observations."},links={{"ALT PREPARATION","Alts"},{"CLASS GUIDE","Leveling"}}},
 Alts={title="ALT PREPARATION DESK",tasks={
  "Choose a class, specialization and preferred group role.",
  "Plan training, equipment, bags and a consumable budget.",
  "Review quest objectives and group travel before starting.",
  "Prepare dungeon roles, quests and equipment targets.",
  "Check Legacy benefits and XP rules in the live client."},links={{"CLASS GUIDE","Leveling"},{"LEGACY RESEARCH","Legacy"}}}
}
local function selection(tab,class)
 if definitions[tab] then return definitions[tab],tab end
 if tab~="Leveling" or type(class)~="string" then return end
 local spec=ForeverCompanionSpecPlanner and ForeverCompanionSpecPlanner.Get(class)
 local name=spec and spec[1]
 local book=ForeverCompanionSpecPlaybooks and ForeverCompanionSpecPlaybooks[class]
 local tasks=book and book[name]
 if not tasks then return end
 return {title=string.upper(name).." / PRACTICE DESK",tasks=tasks,links={{"DUNGEON PREPARATION","Dungeons"},{"BOSS LOOT ATLAS","Loot"}}},"Spec:"..class..":"..name
end
function B.Get(tab,class,db)
 local def,key=selection(tab,class)
 if not def then return end
 local saved=type(db)=="table" and type(db.studyChecks)=="table" and db.studyChecks[key]
 saved=type(saved)=="table" and saved or {}
 local done,nextStep=0,nil
 for i,task in ipairs(def.tasks) do
  if saved[i]==true then done=done+1 elseif not nextStep then nextStep=task end
 end
 return {title=def.title,tasks=def.tasks,links=def.links,key=key,done=done,total=#def.tasks,nextStep=nextStep,checked=saved}
end
function B.Toggle(tab,class,db,index)
 local state=B.Get(tab,class,db)
 if not state or type(db)~="table" or type(index)~="number" or index%1~=0 or not state.tasks[index] then return false end
 if type(db.studyChecks)~="table" then db.studyChecks={} end
 if type(db.studyChecks[state.key])~="table" then db.studyChecks[state.key]={} end
 local ticks=db.studyChecks[state.key]
 ticks[index]=not (ticks[index]==true)
 return true
end
function B.Reset(tab,class,db)
 local state=B.Get(tab,class,db)
 if state and type(db)=="table" and type(db.studyChecks)=="table" then db.studyChecks[state.key]=nil end
end
-- Single-line action preview for the fixed-width native panel.
function B.NextActionLabel(state)
 local step=type(state)=="table" and state.nextStep
 if type(step)~="string" or step=="" then
  return "ALL ITEMS REVIEWED  |  Reset to practice again."
 end
 if #step>94 then step=step:sub(1,91).."..." end
 return "NEXT: "..step
end
local function paint(t,r,g,b,a)
 if t.SetColorTexture then t:SetColorTexture(r,g,b,a or 1) else t:SetTexture(r,g,b,a or 1) end
end
local function text(parent,x,y,w,value,font)
 local t=parent:CreateFontString(nil,"OVERLAY",font or "GameFontHighlightSmall")
 t:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y);t:SetWidth(w);t:SetJustifyH("LEFT");t:SetText(value or "")
 return t
end
local function bar(parent,x,y,w,h,r,g,b)
 local t=parent:CreateTexture(nil,"ARTWORK");t:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y);t:SetSize(w,h);paint(t,r,g,b);return t
end
function B.Create(parent,openPage)
 host=parent
 navigate=openPage
 root=CreateFrame("Frame",nil,parent);root:SetSize(770,375)
 local bg=root:CreateTexture(nil,"BACKGROUND");bg:SetAllPoints(root);paint(bg,0.035,0.047,0.070,0.99)
 bar(root,0,0,770,2,0.90,0.67,0.29);bar(root,0,-374,770,1,0.44,0.33,0.20)
 heading=text(root,16,-15,565,"STUDY DESK","GameFontNormalLarge");heading:SetTextColor(0.97,0.77,0.40)
 summary=text(root,16,-43,730,"")
 evidence=text(root,16,-63,735,"");evidence:SetTextColor(0.70,0.76,0.83)
 nextTask=text(root,16,-78,738,"", "GameFontHighlightSmall")
 nextTask:SetTextColor(0.82,0.85,0.91)
 bar(root,16,-100,738,5,0.16,0.20,0.27);fill=bar(root,16,-100,1,5,0.91,0.68,0.29)
 progressCaption=text(root,540,-43,210,"", "GameFontHighlightSmall");progressCaption:SetJustifyH("RIGHT")
 rows={}
 for i=1,5 do
  local index=i
  local b=CreateFrame("Button",nil,root);b:SetSize(738,40);b:SetPoint("TOPLEFT",root,"TOPLEFT",16,-113-(i-1)*43)
  b.bg=b:CreateTexture(nil,"BACKGROUND");b.bg:SetAllPoints(b)
  b.rail=bar(b,0,0,3,40,0.94,0.72,0.32)
  b.number=text(b,10,-12,60,"");b.caption=text(b,77,-7,647,"");b.caption:SetTextColor(0.94,0.90,0.81)
  b:SetScript("OnClick",function()
   if current and B.Toggle(current.tab,current.class,current.db,index) then
    if ForeverCompanionRefresh then ForeverCompanionRefresh()
    else B.Render(current.tab,current.class,current.db) end
   end
  end)
  b:SetScript("OnEnter",function(self)
   local accent=current and B.Accent(current.tab,current.class) or {0.94,0.72,0.32}
   paint(self.bg,0.08+accent[1]*0.12,0.08+accent[2]*0.12,0.08+accent[3]*0.12)
  end)
  b:SetScript("OnLeave",function() if current then B.Render(current.tab,current.class,current.db) end end)
  rows[i]=b
 end
 links={}
 for i=1,2 do
  local index=i
  local b=CreateFrame("Button",nil,root,"UIPanelButtonTemplate");b:SetSize(245,24);b:SetPoint("TOPLEFT",root,"TOPLEFT",16+(i-1)*255,-338)
  b:SetScript("OnClick",function() if current and navigate and current.state.links[index] then navigate(current.state.links[index][2]) end end)
  links[i]=b
 end
 local reset=CreateFrame("Button",nil,root,"UIPanelButtonTemplate");reset:SetSize(180,24);reset:SetPoint("TOPRIGHT",root,"TOPRIGHT",-16,-338);reset:SetText("Reset practice ticks")
 reset:SetScript("OnClick",function() if current then
   B.Reset(current.tab,current.class,current.db)
   if ForeverCompanionRefresh then ForeverCompanionRefresh()
   else B.Render(current.tab,current.class,current.db) end
  end end)
 root:Hide()
end
function B.Render(tab,class,db)
 if not root then return end
 local state=B.Get(tab,class,db)
 if not state then root:Hide();current=nil;return end
 current={tab=tab,class=class,db=db,state=state}
 root:ClearAllPoints()
 local rotationHeight=0
 if tab=="Leveling" and type(ForeverCompanionRotationWorkspace)=="table" and type(ForeverCompanionRotationWorkspace.GetHeight)=="function" then
  rotationHeight=tonumber(ForeverCompanionRotationWorkspace.GetHeight()) or 0
  if rotationHeight~=rotationHeight or rotationHeight<0 or rotationHeight>2000 then rotationHeight=0 end
 end
 root:SetPoint("TOPLEFT",host,"TOPLEFT",8,tab=="Leveling" and -(194+rotationHeight) or -5)
 local accent=B.Accent(tab,class)
 heading:SetText(state.title)
 heading:SetTextColor(accent[1],accent[2],accent[3])
 paint(fill,accent[1],accent[2],accent[3])
 summary:SetText("Personal checklist  |  No game progress detected")
 progressCaption:SetText(state.done.." / "..state.total.." reviewed")
 progressCaption:SetTextColor(accent[1],accent[2],accent[3])
 nextTask:SetText(B.NextActionLabel(state))
 evidence:SetText(tab=="Leveling" and "ADVISORY practice order. Source-reviewed conditional priorities below take precedence; skip untrained spells." or "FOREVER RULES UNCONFIRMED. These tasks track your research and preparation only.")
 fill:SetWidth(state.total>0 and math.max(1,738*state.done/state.total) or 1)
 for i,row in ipairs(rows) do
  local task=state.tasks[i]
  if task then
   row:Show();row.number:SetText(state.checked[i]==true and "DONE" or string.format("%02d",i));row.number:SetTextColor(state.checked[i]==true and 0.43 or accent[1],state.checked[i]==true and 0.91 or accent[2],state.checked[i]==true and 0.66 or accent[3])
   paint(row.rail,state.checked[i]==true and 0.43 or accent[1],state.checked[i]==true and 0.91 or accent[2],state.checked[i]==true and 0.66 or accent[3])
   row.caption:SetText(task)
   row.caption:SetTextColor(state.checked[i]==true and 0.66 or 0.94,state.checked[i]==true and 0.81 or 0.90,state.checked[i]==true and 0.75 or 0.81)
   paint(row.bg,state.checked[i]==true and 0.10 or 0.065,state.checked[i]==true and 0.19 or 0.085,0.12)
  else row:Hide() end
 end
 for i,link in ipairs(links) do
  local target=state.links[i]
  if target then link:SetText(target[1]);link:Show() else link:Hide() end
 end
 root:Show()
end

