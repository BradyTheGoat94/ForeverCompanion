-- Visible context navigation and selected-priority explanations, all advisory.
local W={}
ForeverCompanionRotationWorkspace=W
local root,heading,description,selectedText,tipText,buttons
local modes={"leveling","dungeon","boss","aoe","pvp"}
local names={"Leveling Rotation","Dungeon Rotation","Boss Rotation","AoE Rotation","PvP Rotation"}
local captions={"Solo practice","Group preparation","Single-target priorities","Multiple enemies","Player combat"}
local function text(parent,x,y,w,value,size)
 local t=parent:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
 t:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y);t:SetWidth(w);t:SetJustifyH("LEFT");t:SetText(value or "")
 if ForeverCompanionVisualTheme then ForeverCompanionVisualTheme.Font(t,size or 12) end
 return t
end
local function plate(parent,x,y,w,h,title)
 local p=CreateFrame("Frame",nil,parent);p:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y);p:SetSize(w,h)
 ForeverCompanionVisualTheme.Panel(p,w,h)
 local titleText=text(p,12,-12,w-24,title,15);titleText:SetTextColor(.96,.80,.48)
 return p
end
function W.Create(parent,selectMode)
 root=CreateFrame("Frame",nil,parent);root:SetPoint("TOPLEFT",parent,"TOPLEFT",8,-204);root:SetSize(770,362)
 local rail=plate(root,0,0,180,362,"ROTATION TYPE")
 buttons={}
 for i,mode in ipairs(modes) do
  local b=CreateFrame("Button",nil,rail);b:SetSize(158,52);b:SetPoint("TOPLEFT",rail,"TOPLEFT",11,-46-(i-1)*59)
  b.bg=ForeverCompanionVisualTheme.Button(b,158,52)
  b.mode=mode;b.name=text(b,9,-9,140,names[i],12);b.note=text(b,9,-29,140,captions[i],10)
  b.note:SetTextColor(.65,.68,.72)
  b:SetScript("OnClick",function() selectMode(i) end)
  buttons[i]=b
 end
 W.buttons=buttons
 local sequence=plate(root,192,0,578,178,"ABILITY PRIORITIES")
 heading=text(sequence,14,-45,550,"",13)
 description=text(sequence,14,-65,550,"Advisory priorities. Click a tile for its full instruction.",11)
 description:SetTextColor(.71,.74,.79)
 local explanation=plate(root,192,-190,374,172,"PRIORITY & EXPLANATION")
 selectedText=text(explanation,14,-47,346,"",12)
 selectedText:SetHeight(110)
 W.selectedText=selectedText
 local tips=plate(root,578,-190,192,172,"QUICK TIPS")
 tipText=text(tips,12,-47,168,"",11)
 tipText:SetHeight(110)
 root:Hide()
end
function W.Render(tab,class,mode,index,priorities)
 if not root then return end
 if tab~="Leveling" then root:Hide();return end
 root:Show()
 local presentation=ForeverCompanionRotationPresentation
 local context=presentation and presentation.contexts and presentation.contexts[mode]
 heading:SetText(context and context.title or "Conditional class guidance")
 local ability=type(priorities)=="table" and priorities[index]
 selectedText:SetText(ability and ("PRIORITY "..index.."\n\n"..ability.."\n\nSkip untrained abilities; compare the sourced guide below.") or "No reference priority available for this class and context.")
 local coach=type(ForeverCompanionGetBeginnerCoach)=="function" and ForeverCompanionGetBeginnerCoach(class)
 local resource=type(coach)=="table" and coach.resource or "Check your class resource before spending."
 tipText:SetText("RESOURCE\n"..tostring(resource).."\n\nREFERENCE ONLY\nCheck spell availability and talents in the live client.")
 for _,b in ipairs(buttons) do
  local active=b.mode==mode
  b.name:SetTextColor(active and 1 or .88,active and .84 or .86,active and .52 or .82)
  if b.bg.SetColorTexture then b.bg:SetColorTexture(active and .075 or .025,active and .16 or .028,active and .27 or .034,1) end
 end
end
