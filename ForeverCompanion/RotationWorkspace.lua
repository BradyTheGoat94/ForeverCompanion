-- Reference-style rotation rail, priority table, quick tips and selected detail.
local W={}
ForeverCompanionRotationWorkspace=W
local root,heading,selectedText,tipText,quickText,buttons,explanations,arrows,sequencePlate
local modes={"leveling","dungeon","boss","aoe","pvp"}
local names={"Leveling Rotation","Dungeon Rotation","Boss Rotation","AoE Rotation","PvP Rotation"}
local captions={"Solo practice","Group preparation","Single target","Multiple enemies","Player combat"}
local icons={"Ability_Warrior_Charge","INV_Shield_04","Ability_Warrior_SavageBlow","Spell_Fire_SelfDestruct","Ability_DualWield"}
local function text(parent,x,y,w,value,size)
 local t=parent:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
 t:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y);t:SetWidth(w);t:SetJustifyH("LEFT");t:SetText(value or "")
 ForeverCompanionVisualTheme.Font(t,size or 12)
 return t
end
local function plate(parent,x,y,w,h,title)
 local p=CreateFrame("Frame",nil,parent);p:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y);p:SetSize(w,h)
 ForeverCompanionVisualTheme.Panel(p,w,h)
 local label=text(p,12,-12,w-24,title,15);label:SetTextColor(.96,.80,.48)
 return p
end
function W.Create(parent,selectMode,selectPriority)
 root=CreateFrame("Frame",nil,parent);root:SetPoint("TOPLEFT",parent,"TOPLEFT",8,-174);root:SetSize(770,386)
 local rail=plate(root,0,0,180,302,"Rotation Type")
 buttons={};explanations={};arrows={}
 for i,mode in ipairs(modes) do
  local b=CreateFrame("Button",nil,rail);b:SetSize(158,44);b:SetPoint("TOPLEFT",rail,"TOPLEFT",11,-44-(i-1)*49)
  b.bg=ForeverCompanionVisualTheme.Button(b,158,44)
  b.icon=b:CreateTexture(nil,"ARTWORK");b.icon:SetPoint("LEFT",b,"LEFT",5,0);b.icon:SetSize(27,27);b.icon:SetTexture("Interface\\Icons\\"..icons[i])
  b.mode=mode;b.name=text(b,39,-8,116,names[i],10);b.note=text(b,39,-26,114,captions[i],9)
  b.note:SetTextColor(.65,.68,.72)
  b:SetScript("OnClick",function() selectMode(i) end);buttons[i]=b
 end
 W.buttons=buttons
 local sequence=plate(root,192,0,578,178,"Ability Priorities")
 sequencePlate=sequence
 heading=text(sequence,14,-44,550,"",14)
 local notice=text(sequence,14,-65,550,"Conditional priorities / click an icon or instruction / skip untrained spells",10)
 notice:SetTextColor(.70,.75,.82)
 for i=1,5 do arrows[i]=text(sequence,0,-113,9,"›",15);arrows[i]:SetTextColor(.94,.75,.38) end
 local explanation=plate(root,192,-190,374,134,"Priority & Explanations")
 for i=1,6 do
  local b=CreateFrame("Button",nil,explanation);b:SetSize(346,12);b:SetPoint("TOPLEFT",explanation,"TOPLEFT",14,-39-(i-1)*16)
  b.bg=ForeverCompanionVisualTheme.Button(b,346,12)
  b.number=text(b,4,-1,18,tostring(i),9);b.number:SetTextColor(.96,.80,.48)
  b.caption=text(b,26,-1,316,"",9);b.caption:SetHeight(12)
  b:SetScript("OnClick",function() selectPriority(i) end)
  explanations[i]=b
 end
 W.explanations=explanations
 local tips=plate(root,578,-190,192,134,"Quick Tips")
 tipText=text(tips,12,-43,168,"",10);tipText:SetHeight(81)
 local quick=plate(root,0,-314,180,71,"Class Quick Info")
 quickText=text(quick,12,-43,156,"",10);quickText:SetHeight(27)
 local summary=plate(root,192,-328,578,58,"Selected Priority")
 selectedText=text(summary,12,-39,554,"",10);selectedText:SetHeight(17)
 W.selectedText=selectedText
 root:Hide()
end
function W.Render(tab,class,mode,index,priorities)
 if not root then return end
 if tab~="Leveling" then root:Hide();return end
 root:Show()
 priorities=type(priorities)=="table" and priorities or {}
 local context=ForeverCompanionRotationPresentation and ForeverCompanionRotationPresentation.contexts[mode]
 heading:SetText(context and context.title or "Conditional class guidance")
 local ability=priorities[index]
 selectedText:SetText(ability and ("PRIORITY "..index..": "..ability) or "No reference priority available for this class and context.")
 local coach=type(ForeverCompanionGetBeginnerCoach)=="function" and ForeverCompanionGetBeginnerCoach(class) or {}
 local caution=coach.check or "Check trained abilities and your assigned role."
 if #caution>100 then caution=caution:sub(1,97).."..." end
 tipText:SetText("• "..caution.."\n\nAdvisory / skip untrained spells.")
 local spec=ForeverCompanionSpecPlanner.Get(class)
 quickText:SetText("Resource: "..(coach.resource or "Check client").."\nSpec: "..(spec and spec[1] or "Not available"))
 for _,b in ipairs(buttons) do
  local active=b.mode==mode
  b.name:SetTextColor(active and 1 or .88,active and .84 or .86,active and .52 or .82)
  b.bg:SetColorTexture(active and .055 or .025,active and .16 or .028,active and .30 or .034,1)
 end
 for i,b in ipairs(explanations) do
  local instruction=priorities[i]
  if instruction then
   b.caption:SetText(#instruction>55 and instruction:sub(1,52).."..." or instruction)
   b.bg:SetColorTexture(index==i and .065 or .025,index==i and .12 or .028,index==i and .20 or .034,1)
   b:Show()
  else b:Hide() end
 end
 local count=math.min(6,#priorities)
 local inset=math.max(0,math.floor((570-(count*95-7))/2))
 for i,arrow in ipairs(arrows) do
  arrow:ClearAllPoints();arrow:SetPoint("TOPLEFT",sequencePlate,"TOPLEFT",8+inset+(i-1)*95+88,-113)
  if i<count then arrow:Show() else arrow:Hide() end
 end
end
