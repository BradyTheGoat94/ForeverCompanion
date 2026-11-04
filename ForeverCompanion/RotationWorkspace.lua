-- Reference-style rotation rail, priority table, quick tips and selected detail.
local W={}
ForeverCompanionRotationWorkspace=W
local root,heading,selectedText,tipText,quickText,buttons,explanations,arrows,sequencePlate,summaryPlate,quickPlate,explanationPlate,tipsPlate
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
 root=CreateFrame("Frame",nil,parent);root:SetPoint("TOPLEFT",parent,"TOPLEFT",8,-174);root:SetSize(770,500);W.root=root
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
 local notice=text(sequence,14,-65,550,"General class practice / see Overview for your selected spec",10)
 notice:SetTextColor(.70,.75,.82)
 for i=1,5 do arrows[i]=text(sequence,0,-113,9,"›",15);arrows[i]:SetTextColor(.94,.75,.38) end
 local explanation=plate(root,192,-190,374,174,"Priority & Explanations");explanationPlate=explanation
 for i=1,6 do
  local b=CreateFrame("Button",nil,explanation);b:SetSize(346,20);b:SetPoint("TOPLEFT",explanation,"TOPLEFT",14,-39-(i-1)*22)
  b.bg=ForeverCompanionVisualTheme.Button(b,346,20)
  b.number=text(b,4,-4,18,tostring(i),11);b.number:SetTextColor(.96,.80,.48)
  b.caption=text(b,26,-4,316,"",11);b.caption:SetHeight(16)
  b:SetScript("OnClick",function() selectPriority(i) end)
  explanations[i]=b
 end
 W.explanations=explanations
 local tips=plate(root,578,-190,192,174,"Quick Tips");tipsPlate=tips
 tipText=text(tips,12,-43,168,"",11);tipText:SetJustifyV("TOP")
 local quick=plate(root,0,-314,180,186,"Class Quick Info");quickPlate=quick
 quickText=text(quick,12,-43,156,"",11);quickText:SetHeight(132)
 local summary=plate(root,192,-376,578,124,"Selected Priority");summaryPlate=summary
 selectedText=text(summary,12,-39,554,"",12);selectedText:SetJustifyV("TOP")
 W.selectedText=selectedText;W.summaryPlate=summaryPlate;W.quickText=quickText
 root:Hide()
end
function W.GetHeight()
 return root and root:GetHeight() or 500
end
function W.Render(tab,class,mode,index,priorities)
 if not root then return end
 if tab~="Leveling" then root:Hide();return end
 root:Show()
 priorities=type(priorities)=="table" and priorities or {}
 local context=ForeverCompanionRotationPresentation and ForeverCompanionRotationPresentation.contexts[mode]
 heading:SetText(context and context.title or "Conditional class guidance")
 index=type(index)=="number" and math.floor(index) or 1
 if index<1 or index>#priorities then index=1 end
 local ability=priorities[index]
 local _,cue,iconStatus=ForeverCompanionRotationCardIcon(class,mode,index)
 local artwork=cue and ("\nArtwork: "..cue..(iconStatus=="spell" and " / client spell icon" or " / unresolved, showing question mark")) or "\nArtwork: class emblem / general instruction"
 selectedText:SetText(ability and ("PRIORITY "..index..": "..ability..artwork) or "No reference priority available for this class and context.")
 -- Measure after assigning the complete instruction; never clip its conditions.
 local detailHeight=math.max(72,selectedText:GetStringHeight()+8)
 selectedText:SetHeight(detailHeight)
 ForeverCompanionVisualTheme.ResizePanel(summaryPlate,detailHeight+52)
 local coach=type(ForeverCompanionGetBeginnerCoach)=="function" and ForeverCompanionGetBeginnerCoach(class) or {}
 local caution=coach.check or "Check trained abilities and your assigned role."
 tipText:SetText("• "..caution.."\n\nAdvisory / skip untrained spells.")
 local tipsHeight=tipText:GetStringHeight()+8
 local rowHeight=math.max(134,42+math.min(6,#priorities)*22,43+tipsHeight)
 tipText:SetHeight(tipsHeight)
 ForeverCompanionVisualTheme.ResizePanel(explanationPlate,rowHeight)
 ForeverCompanionVisualTheme.ResizePanel(tipsPlate,rowHeight)
 local detailTop=202+rowHeight
 summaryPlate:ClearAllPoints()
 summaryPlate:SetPoint("TOPLEFT",root,"TOPLEFT",192,-detailTop)
 root:SetHeight(detailTop+summaryPlate:GetHeight())
 ForeverCompanionVisualTheme.ResizePanel(quickPlate,root:GetHeight()-314)
 quickText:SetHeight(quickPlate:GetHeight()-52)
 local spec=ForeverCompanionSpecPlanner.Get(class)
 quickText:SetText("RESOURCE\n"..(coach.resource or "Check client").."\n\nSPECIALIZATION\n"..(spec and spec[1] or "Not available"))
 for _,b in ipairs(buttons) do
  local active=b.mode==mode
  b.name:SetTextColor(active and 1 or .88,active and .84 or .86,active and .52 or .82)
  b.bg:SetColorTexture(active and .055 or .025,active and .16 or .028,active and .30 or .034,1)
 end
 for i,b in ipairs(explanations) do
  local instruction=priorities[i]
  if instruction then
   b.caption:SetText(#instruction>45 and instruction:sub(1,42).."..." or instruction)
   b.detail=instruction
   b:SetScript("OnEnter",function(self)
    if GameTooltip then
     GameTooltip:SetOwner(self,"ANCHOR_RIGHT");GameTooltip:SetText("Priority "..i,1,.8,.4)
     GameTooltip:AddLine(self.detail,.92,.92,.88,true);GameTooltip:Show()
    end
   end)
   b:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
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

