-- Class-banner and topic navigation. All controls change addon presentation only.
local Guide={}
ForeverCompanionClassGuide=Guide
local root,values,topics,topicPanel,topicTitle,topicBody,topicLink,navigate
local views={"Overview","Talents","Rotations","Leveling","Dungeons","PvP","Gear & Stats","Professions"}
local function text(parent,x,y,w,value,size,gold)
 local f=parent:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
 f:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y);f:SetWidth(w);f:SetJustifyH("LEFT");f:SetText(value or "")
 ForeverCompanionVisualTheme.Font(f,size or 12)
 f:SetTextColor(gold and .97 or .92,gold and .80 or .90,gold and .48 or .84)
 return f
end
function Guide.GetView()
 local wanted=type(ForeverCompanionDB)=="table" and ForeverCompanionDB.classGuideView
 for _,name in ipairs(views) do if name==wanted then return name end end
 return "Rotations"
end
function Guide.SelectView(name)
 for _,valid in ipairs(views) do
  if valid==name and type(ForeverCompanionDB)=="table" then
   ForeverCompanionDB.classGuideView=name
   if navigate then navigate("Leveling") end
   return true
  end
 end
 return false
end
function Guide.Create(parent,openPage)
 navigate=openPage
 root=CreateFrame("Frame",nil,parent);root:SetPoint("TOPLEFT",parent,"TOPLEFT",5,-4);root:SetSize(780,165)
 values={};topics={};Guide.topicButtons=topics
 local hero=CreateFrame("Frame",nil,root);hero:SetSize(780,118);hero:SetPoint("TOPLEFT",root,"TOPLEFT",0,0)
 ForeverCompanionVisualTheme.Panel(hero,780,118)
 values.art=ForeverCompanionVisualTheme.Banner(hero,2,-2,776,114,1)
 values.crumb=text(hero,16,-12,480,"CLASS GUIDES",11,true)
 local iconMat=hero:CreateTexture(nil,"ARTWORK");iconMat:SetPoint("TOPLEFT",hero,"TOPLEFT",14,-39);iconMat:SetSize(60,60);iconMat:SetColorTexture(.76,.62,.36,1)
 values.icon=hero:CreateTexture(nil,"OVERLAY");values.icon:SetPoint("TOPLEFT",hero,"TOPLEFT",17,-42);values.icon:SetSize(54,54)
 values.name=text(hero,89,-37,445,"",30,true)
 values.role=text(hero,91,-75,425,"",12)
 values.focus=text(hero,16,-98,495,"",10)
 values.xp=text(hero,545,-94,218,"",10,true)
 local xpTrack=hero:CreateTexture(nil,"ARTWORK");xpTrack:SetPoint("TOPLEFT",hero,"TOPLEFT",545,-111);xpTrack:SetSize(218,3);xpTrack:SetColorTexture(.08,.10,.14,1)
 values.xpFill=hero:CreateTexture(nil,"OVERLAY");values.xpFill:SetPoint("TOPLEFT",hero,"TOPLEFT",545,-111);values.xpFill:SetSize(1,3);values.xpFill:SetColorTexture(.76,.60,.32,1)
 hero:EnableMouse(true)
 hero:SetScript("OnEnter",function(self)
  if GameTooltip then
   GameTooltip:SetOwner(self,"ANCHOR_RIGHT");GameTooltip:SetText("CLASS PRACTICE / ADVISORY",1,.8,.4)
   GameTooltip:AddLine(values.tip or "Check the class reference below.",.9,.9,.85,true)
   GameTooltip:AddLine(values.band or "Level unavailable",.7,.8,.9,true)
   GameTooltip:AddLine("Illustrative artwork. Spell availability and live-client behavior require verification.",.7,.75,.8,true)
   GameTooltip:Show()
  end
 end)
 hero:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
 for i,name in ipairs(views) do
  local b=CreateFrame("Button",nil,root);b:SetSize(93,32);b:SetPoint("TOPLEFT",root,"TOPLEFT",(i-1)*98,-129)
  b.bg=ForeverCompanionVisualTheme.Button(b,93,32)
  b.label=text(b,3,-10,87,name,11);b.label:SetJustifyH("CENTER");b.view=name
  b.rail=b:CreateTexture(nil,"OVERLAY");b.rail:SetPoint("BOTTOMLEFT",b,"BOTTOMLEFT",0,0);b.rail:SetSize(93,2)
  b:SetScript("OnClick",function() Guide.SelectView(name) end)
  topics[i]=b
 end
 topicPanel=CreateFrame("Frame",nil,parent);topicPanel:SetPoint("TOPLEFT",parent,"TOPLEFT",8,-174);topicPanel:SetSize(770,352)
 ForeverCompanionVisualTheme.Panel(topicPanel,770,352)
 topicTitle=text(topicPanel,16,-13,730,"",18,true)
 topicBody=text(topicPanel,16,-52,730,"",13);topicBody:SetJustifyV("TOP")
 topicLink=CreateFrame("Button",nil,topicPanel,"UIPanelButtonTemplate");topicLink:SetSize(240,25);topicLink:SetPoint("TOPLEFT",topicPanel,"TOPLEFT",16,-309)
 topicLink:SetScript("OnClick",function() if topicLink.target and navigate then navigate(topicLink.target) end end)
 Guide.topicPanel=topicPanel;Guide.topicBody=topicBody
 topicPanel:Hide();root:Hide()
end
local function xp()
 if type(UnitXP)~="function" or type(UnitXPMax)~="function" then return nil end
 local ok,value=pcall(function()
  local a,b=UnitXP("player"),UnitXPMax("player")
  if type(a)=="number" and type(b)=="number" and a==a and b==b and b>0 and b<math.huge then return math.max(0,math.min(1,a/b)) end
 end)
 return ok and value or nil
end
local function clip(value,n)
 value=tostring(value or ""):gsub("[\r\n]"," ")
 return #value>n and value:sub(1,n-3).."..." or value
end
function Guide.TopicLines(class,view,role)
 local data=ForeverCompanionData or {}
 local entry=data.classHandbook and data.classHandbook[class] or {}
 local coach=type(ForeverCompanionGetBeginnerCoach)=="function" and ForeverCompanionGetBeginnerCoach(class) or {}
 local spec=ForeverCompanionSpecPlanner.Get(class)
 local lines={"GENERAL REFERENCE / Live Forever verification pending."}
 if view=="Overview" then
  lines[1]="SELECTED SPEC / "..(spec and spec[1] or "Not available").."  •  "..(spec and spec[2] or "Role unavailable")
  lines[#lines+1]="Resource: "..(coach.resource or "Check the client class panel")
  if spec then lines[#lines+1]="Focus: "..spec[3] end
  lines[#lines+1]=ForeverCompanionSpecPlanner.Evidence(class)
  local sourceLines=ForeverCompanionSourcedPriorityLines(class)
  for _,line in ipairs(ForeverCompanionQuickStartLines(class)) do lines[#lines+1]=line end
  for _,line in ipairs(sourceLines) do lines[#lines+1]=line end
  if #sourceLines==0 then lines[#lines+1]="No published Forever priority is attached to this planner selection." end
  for _,line in ipairs((data.classes and data.classes[class]) or {}) do lines[#lines+1]=line end
 elseif view=="Talents" then
  lines[#lines+1]=ForeverCompanionSpecPlanner.Format(class,"leveling")
  lines[#lines+1]=ForeverCompanionSpecPlanner.Evidence(class)
  lines[#lines+1]="Use the Spec selector to preview another build. The addon does not spend talent points."
 elseif view=="Leveling" then
  lines[#lines+1]=entry.leveling or "Train abilities and review your current class resources."
  lines[#lines+1]=coach.first or "Check trained spells before pulling."
  lines[#lines+1]=coach.loop or "Practice safely before increasing pull size."
  lines[#lines+1]=coach.recover or "Keep a recovery option available."
 elseif view=="Dungeons" then
  lines[#lines+1]=entry.dungeon or "Coordinate target, role and pull size with the group."
  lines[#lines+1]=ForeverCompanionSpecPlanner.Format(class,"dungeon")
 elseif view=="PvP" then
  lines[#lines+1]=entry.pvp or "Plan positioning, control and defensive responses."
  lines[#lines+1]=ForeverCompanionSpecPlanner.Format(class,"pvp")
 elseif view=="Gear & Stats" then
  return ForeverCompanionGearStats.Lines(class)
 elseif view=="Professions" then
  lines[#lines+1]=entry.professions or "Compare gathering income and crafting goals before committing."
  lines[#lines+1]="Profession material goals are manually entered. The addon does not purchase or craft items."
 end
 return lines
end
function Guide.Render(class,label,level,role,mode)
 if not root then return end
 local entry=ForeverCompanionData and ForeverCompanionData.classHandbook and ForeverCompanionData.classHandbook[class] or {}
 local selected=ForeverCompanionSpecPlanner.Get(class)
 values.crumb:SetText("CLASS GUIDES  /  "..string.upper(tostring(label)))
 values.name:SetText(tostring(label))
 values.role:SetText("Level "..tostring(level or "?").."  /  "..(selected and selected[1] or "Choose specialization").."  /  "..tostring(role or "Choose role"))
 ForeverCompanionIcons.ApplyClass(values.icon,class)
 values.art:SetTexture(class=="WARRIOR" and ForeverCompanionVisualTheme.warrior or ForeverCompanionVisualTheme.citadel)
 if values.art.SetTexCoord then values.art:SetTexCoord(0,1,0,.66) end
 values.tip=entry.leveling or "Check trained spells and the reference guide."
 local levelNumber=tonumber(level)
 local curriculum=ForeverCompanionLevelingCurriculum
 local stage=levelNumber and type(curriculum)=="table" and type(curriculum.Stage)=="function" and curriculum.Stage(levelNumber) or nil
 local notes=curriculum and curriculum.classes and curriculum.classes[class]
 if stage and type(notes)=="table" and type(notes[stage])=="string" then values.tip=notes[stage] end
 values.band=levelNumber and ("Leveling phase: "..(levelNumber>=50 and "Endgame preparation (50-60)" or "Check current class training")) or "Level unavailable"
 values.focus:SetText("FOCUS: "..clip(values.tip,81))
 local fraction=xp()
 values.xp:SetText(fraction and ("Experience progress: "..math.floor(fraction*100+.5).."%") or "Experience: unavailable")
 values.xpFill:SetWidth(fraction and math.max(1,218*fraction) or 1)
 local view=Guide.GetView()
 for _,b in ipairs(topics) do
  local active=b.view==view
  b.bg:SetColorTexture(active and .06 or .025,active and .17 or .028,active and .30 or .034,1)
  b.rail:SetColorTexture(active and .95 or .38,active and .76 or .32,active and .38 or .23,1)
 end
 if view=="Rotations" then topicPanel:Hide() else
  topicTitle:SetText(label.." / "..view)
  topicBody:SetText(table.concat(Guide.TopicLines(class,view,role),view=="Overview" and "\n" or "\n\n"))
  local bodyHeight=math.max(242,topicBody:GetStringHeight()+12)
  topicBody:SetHeight(bodyHeight)
  ForeverCompanionVisualTheme.ResizePanel(topicPanel,bodyHeight+110)
  topicLink:ClearAllPoints();topicLink:SetPoint("TOPLEFT",topicPanel,"TOPLEFT",16,-(bodyHeight+67))
  local targets={Dungeons="Dungeons",PvP="PvP",Professions="Professions",["Gear & Stats"]="Loot"}
  topicLink.target=targets[view]
  if topicLink.target then topicLink:SetText("Open "..topicLink.target.." handbook");topicLink:Show() else topicLink:Hide() end
  topicPanel:Show()
 end
end
function Guide.GetTopicHeight()
 return topicPanel and topicPanel:GetHeight() or 352
end
function Guide.Show(visible)
 if not root then return end
 if visible then root:Show() else root:Hide();topicPanel:Hide() end
end

