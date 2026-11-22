-- Class-banner and topic navigation. All controls change addon presentation only.
local Guide={}
ForeverCompanionClassGuide=Guide
local root,values,topics,topicPanel,topicTitle,topicBody,topicLink,navigate
local views={"Overview","Talents","Rotations","Macros","Leveling","Dungeons","PvP","Gear & Stats","Professions"}
local browser
local function text(parent,x,y,w,value,size,gold)
 local f=parent:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
 f:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y);f:SetWidth(w);f:SetJustifyH("LEFT");f:SetText(value or "")
 ForeverCompanionVisualTheme.Font(f,size or 12)
 f:SetTextColor(gold and .97 or .92,gold and .80 or .90,gold and .48 or .84)
 return f
end
local topicCaptions={
 Overview={'Selected specialization','Class resource','Specialization focus','Guide evidence'},
 Leveling={'Leveling approach','First action','Combat loop','Recovery'},
 Dungeons={'Dungeon approach','Role priorities'},
 PvP={'PvP approach','Role priorities'},
 Professions={'Profession pairing','Material goals'},
}
local function topicsFor(view,lines)
 local items={}
 if view=='Gear & Stats' then
  if lines[4] then
   items[1]={title='Stat priority',body=lines[4]}
   items[2]={title='Scope and evidence',body=table.concat({lines[1],lines[2],lines[3]},'\n\n')}
   for i=5,#lines do items[#items+1]=lines[i] end
  else items[1]={title='Stat priority',body=lines[1]} end
  return items
 end
 local captions=topicCaptions[view] or {}
 for i,line in ipairs(lines) do
  if line~='GENERAL REFERENCE' then
   local title=captions[view=='Overview' and i or i-1]
   items[#items+1]=title and {title=title,body=line} or line
  end
 end
 return items
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
 local iconMat=hero:CreateTexture(nil,"ARTWORK");values.iconMat=iconMat;iconMat:SetPoint("TOPLEFT",hero,"TOPLEFT",14,-39);iconMat:SetSize(60,60);iconMat:SetColorTexture(.76,.62,.36,1)
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
 local viewIcons={'INV_Misc_Book_09','Spell_Holy_BlessingOfStrength','Ability_Warrior_SavageBlow','INV_Scroll_03','INV_Misc_Map_01','INV_Misc_Key_03','Ability_DualWield','INV_Chest_Plate02','Trade_BlackSmithing'}
 for i,name in ipairs(views) do
  local b=CreateFrame("Button",nil,root);b:SetSize(81,32);b:SetPoint("TOPLEFT",root,"TOPLEFT",(i-1)*87,-129)
  b.bg=ForeverCompanionVisualTheme.Button(b,81,32)
  local icon=b:CreateTexture(nil,'ARTWORK');icon:SetPoint('LEFT',b,'LEFT',5,0);icon:SetSize(14,14)
  icon:SetTexture('Interface\\Icons\\'..viewIcons[i])
  b.label=text(b,22,-10,58,name,10);b.view=name
  b.rail=b:CreateTexture(nil,"OVERLAY");b.rail:SetPoint("BOTTOMLEFT",b,"BOTTOMLEFT",0,0);b.rail:SetSize(81,2)
  b:SetScript("OnClick",function() Guide.SelectView(name) end)
  ForeverCompanionInterface.SetHoverHelp(b,name,"Open the "..name:lower().." tools for the selected class.")
  topics[i]=b
 end
 topicPanel=CreateFrame("Frame",nil,parent);topicPanel:SetPoint("TOPLEFT",parent,"TOPLEFT",8,-174);topicPanel:SetSize(770,352)
 ForeverCompanionVisualTheme.Panel(topicPanel,770,352)
 topicTitle=text(topicPanel,16,-13,370,"",18,true)
 topicBody=text(topicPanel,16,-52,730,"",13);topicBody:SetJustifyV("TOP")
 browser=ForeverCompanionReferenceWorkspace.CreateBrowser(topicPanel,738,282)
 browser.frame:SetPoint('TOPLEFT',16,-50)
 Guide.browser=browser
 topicLink=ForeverCompanionInterface.Button(topicPanel);topicLink:SetSize(180,24);topicLink:SetPoint("TOPRIGHT",topicPanel,"TOPRIGHT",-12,-4)
 topicLink:SetScript("OnClick",function() if topicLink.target and navigate then navigate(topicLink.target) end end)
 ForeverCompanionInterface.SetHoverHelp(topicLink,"Related tool",function() return topicLink:GetText() end)
 ForeverCompanionTalentWorkspace.Create(topicPanel)
 ForeverCompanionClassMacros.Create(topicPanel)
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
function Guide.TopicLines(class,view,role)
 local data=ForeverCompanionData or {}
 local entry=data.classHandbook and data.classHandbook[class] or {}
 local coach=type(ForeverCompanionGetBeginnerCoach)=="function" and ForeverCompanionGetBeginnerCoach(class) or {}
 local spec=ForeverCompanionSpecPlanner.Get(class)
 local lines={"GENERAL REFERENCE"}
 if view=="Overview" then
  lines[1]="SELECTED SPEC / "..(spec and spec[1] or "Not available").."  •  "..(spec and spec[2] or "Role unavailable")
  lines[#lines+1]="Resource: "..(coach.resource or "Check the client class panel")
  if spec then lines[#lines+1]="Focus: "..spec[3] end
  lines[#lines+1]=ForeverCompanionSpecPlanner.Evidence(class)
  local sourceLines=ForeverCompanionSourcedPriorityLines(class)
  for _,line in ipairs(ForeverCompanionQuickStartLines(class)) do lines[#lines+1]=line end
  for _,line in ipairs(sourceLines) do lines[#lines+1]=line end
  if #sourceLines==0 then lines[#lines+1]="No published Forever priority is attached to this planner selection." end
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
 browser.frame:Hide()
 local entry=ForeverCompanionData and ForeverCompanionData.classHandbook and ForeverCompanionData.classHandbook[class] or {}
 local selected=ForeverCompanionSpecPlanner.Get(class)
 values.crumb:SetText("CLASS GUIDES  /  "..string.upper(tostring(label)))
 values.name:SetText(tostring(label))
 values.role:SetText("Level "..tostring(level or "?").."  /  "..(selected and selected[1] or "Choose specialization").."  /  "..tostring(role or "Choose role"))
 ForeverCompanionIcons.ApplyClass(values.icon,class)
 local theme=ForeverCompanionVisualTheme
 local r,g,blue=unpack(theme.ClassAccent(class))
 values.iconMat:SetColorTexture(r,g,blue,1);values.name:SetTextColor(r,g,blue)
 values.xpFill:SetColorTexture(r,g,blue,1)
 if class=="WARRIOR" then
  values.art:SetTexture(theme.warrior);values.art:SetTexCoord(0,1,0,.66);values.art:SetAlpha(1)
 else
  local landscape=({HUNTER='Journey',DRUID='Journey',ROGUE='Dungeons',WARLOCK='Dungeons',PALADIN='PvP',PRIEST='Bank',SHAMAN='Bank'})[class] or 'Leveling'
  theme.PaintEnvironment(values.art,landscape,.63,.117)
 end
 values.tip=entry.leveling or "Check trained spells and the reference guide."
 local levelNumber=tonumber(level)
 local curriculum=ForeverCompanionLevelingCurriculum
 local stage=levelNumber and type(curriculum)=="table" and type(curriculum.Stage)=="function" and curriculum.Stage(levelNumber) or nil
 local notes=curriculum and curriculum.classes and curriculum.classes[class]
 if stage and type(notes)=="table" and type(notes[stage])=="string" then values.tip=notes[stage] end
 values.band=levelNumber and ("Leveling phase: "..(levelNumber>=50 and "Endgame preparation (50-60)" or "Check current class training")) or "Level unavailable"
 values.focus:SetText(values.band)
 local fraction=xp()
 values.xp:SetText(fraction and ("Experience progress: "..math.floor(fraction*100+.5).."%") or "Experience: unavailable")
 values.xpFill:SetWidth(fraction and math.max(1,218*fraction) or 1)
 local view=Guide.GetView()
 for _,b in ipairs(topics) do
  local active=b.view==view
  ForeverCompanionVisualTheme.SelectRow(b,b.bg,active)
  b.rail:SetColorTexture(r,g,blue,active and 1 or .31)
 end
 if view=="Macros" then
  ForeverCompanionTalentWorkspace.Hide()
  topicTitle:SetText(label.." / Macros");topicTitle:Show()
  topicBody:Hide();topicLink:Hide()
  ForeverCompanionClassMacros.Render(class)
  ForeverCompanionVisualTheme.ResizePanel(topicPanel,345)
  topicPanel:Show()
  return
 end
 ForeverCompanionClassMacros.Hide()
 if view=="Talents" then
  topicTitle:Hide();topicBody:Hide();topicLink:Hide()
  ForeverCompanionTalentWorkspace.Render(class,selected)
  if ForeverCompanionTalentWorkspace.root:IsShown() then
   ForeverCompanionVisualTheme.ResizePanel(topicPanel,ForeverCompanionTalentWorkspace.root:GetHeight()+8)
  else
   topicTitle:SetText("Talent planner")
   topicBody:SetText("Choose a supported class to view its talent trees.")
   topicTitle:Show();topicBody:Show()
   ForeverCompanionVisualTheme.ResizePanel(topicPanel,352)
  end
  topicPanel:Show()
  return
 end
 ForeverCompanionTalentWorkspace.Hide()
 if view=="Rotations" then topicPanel:Hide() else
  topicTitle:Show();topicBody:Hide()
  topicTitle:SetText(label.." / "..view)
  local lines=Guide.TopicLines(class,view,role)
  local items=topicsFor(view,lines)
  browser:SetItems(items,class..':'..view..':'..(selected and selected[1] or ''))
  browser.frame:Show()
  local targets={Dungeons="Dungeons",PvP="PvP",Professions="Professions",["Gear & Stats"]="Gear"}
  local linkLabels={Dungeons="Open Dungeon Journal",Gear="Open gear finder",PvP="Open PvP preparation",Professions="Open profession tools"}
  topicLink.target=targets[view]
  topicLink:SetShown(topicLink.target~=nil)
  if topicLink.target then topicLink:SetText(linkLabels[topicLink.target]) end
  ForeverCompanionVisualTheme.ResizePanel(topicPanel,350)
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

