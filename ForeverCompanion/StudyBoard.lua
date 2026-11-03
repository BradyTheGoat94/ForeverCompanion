-- Player-controlled study and preparation. Ticks are personal notes, never proof
-- of unlocks, skill ownership, combat readiness, or server mechanics.
local B={}
ForeverCompanionStudyBoard=B
local host,root,heading,summary,evidence,fill,navigate,current,rows,links
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
 if tab~="Leveling" then return end
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
 if state and type(db.studyChecks)=="table" then db.studyChecks[state.key]=nil end
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
 bar(root,16,-85,738,5,0.16,0.20,0.27);fill=bar(root,16,-85,1,5,0.91,0.68,0.29)
 rows={}
 for i=1,5 do
  local index=i
  local b=CreateFrame("Button",nil,root);b:SetSize(738,43);b:SetPoint("TOPLEFT",root,"TOPLEFT",16,-100-(i-1)*46)
  b.bg=b:CreateTexture(nil,"BACKGROUND");b.bg:SetAllPoints(b)
  b.number=text(b,10,-12,60,"");b.caption=text(b,77,-7,647,"");b.caption:SetTextColor(0.94,0.90,0.81)
  b:SetScript("OnClick",function()
   if current and B.Toggle(current.tab,current.class,current.db,index) and ForeverCompanionRefresh then ForeverCompanionRefresh() end
  end)
  b:SetScript("OnEnter",function(self) paint(self.bg,0.20,0.18,0.13) end)
  b:SetScript("OnLeave",function() if current then B.Render(current.tab,current.class,current.db) end end)
  rows[i]=b
 end
 links={}
 for i=1,2 do
  local index=i
  local b=CreateFrame("Button",nil,root,"UIPanelButtonTemplate");b:SetSize(245,24);b:SetPoint("TOPLEFT",root,"TOPLEFT",16+(i-1)*255,-338)
  b:SetScript("OnClick",function() if current and navigate then navigate(current.state.links[index][2]) end end)
  links[i]=b
 end
 local reset=CreateFrame("Button",nil,root,"UIPanelButtonTemplate");reset:SetSize(180,24);reset:SetPoint("TOPRIGHT",root,"TOPRIGHT",-16,-338);reset:SetText("Reset practice ticks")
 reset:SetScript("OnClick",function() if current then B.Reset(current.tab,current.class,current.db);if ForeverCompanionRefresh then ForeverCompanionRefresh() end end end)
 root:Hide()
end
function B.Render(tab,class,db)
 if not root then return end
 local state=B.Get(tab,class,db)
 if not state then root:Hide();current=nil;return end
 current={tab=tab,class=class,db=db,state=state}
 root:ClearAllPoints();root:SetPoint("TOPLEFT",host,"TOPLEFT",8,tab=="Leveling" and -330 or -5)
 heading:SetText(state.title)
 summary:SetText(state.done.." / "..state.total.." reviewed  |  Personal checklist; no game progress is detected")
 evidence:SetText(tab=="Leveling" and "ADVISORY practice order. Source-reviewed conditional priorities below take precedence; skip untrained spells." or "FOREVER RULES UNCONFIRMED. These tasks track your research and preparation only.")
 fill:SetWidth(math.max(1,738*state.done/state.total))
 for i,row in ipairs(rows) do
  local task=state.tasks[i]
  if task then
   row:Show();row.number:SetText(state.checked[i]==true and "DONE" or string.format("%02d",i));row.number:SetTextColor(0.94,0.74,0.38)
   row.caption:SetText(task);paint(row.bg,state.checked[i]==true and 0.10 or 0.065,state.checked[i]==true and 0.19 or 0.085,0.12)
  else row:Hide() end
 end
 for i,link in ipairs(links) do link:SetText(state.links[i][1]) end
 root:Show()
end
