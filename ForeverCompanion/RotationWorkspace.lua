-- Read-only rotation priorities. Clicking a row never invokes a game action.
local W={}
ForeverCompanionRotationWorkspace=W
local root,heading,notice,opener,sourceLabel,buttons,prioritiesPanel,showReference
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
function W.Create(parent,selectMode)
 root=CreateFrame("Frame",nil,parent);root:SetPoint("TOPLEFT",parent,"TOPLEFT",8,-174);root:SetSize(770,500);W.root=root
 local rail=plate(root,0,0,180,339,"Rotation Type")
 buttons={}
 for i,mode in ipairs(modes) do
  local b=CreateFrame("Button",nil,rail);b:SetSize(158,44);b:SetPoint("TOPLEFT",rail,"TOPLEFT",11,-44-(i-1)*49)
  b.bg=ForeverCompanionVisualTheme.Button(b,158,44)
  b.icon=b:CreateTexture(nil,"ARTWORK");b.icon:SetPoint("LEFT",b,"LEFT",5,0);b.icon:SetSize(27,27);b.icon:SetTexture("Interface\\Icons\\"..icons[i])
  b.mode=mode;b.name=text(b,39,-8,116,names[i],10);b.note=text(b,39,-26,114,captions[i],9)
  b.note:SetTextColor(.65,.68,.72)
  b:SetScript("OnClick",function() selectMode(i) end);buttons[i]=b
 end
 W.buttons=buttons
 W.reference=ForeverCompanionInterface.Button(rail)
 W.reference:SetSize(158,25);W.reference:SetPoint("TOPLEFT",rail,"TOPLEFT",11,-299)
 W.reference:SetScript("OnClick",function()
  showReference=not showReference
  ForeverCompanionRefresh()
 end)
 prioritiesPanel=plate(root,192,0,578,302,"What to Press")
 heading=text(prioritiesPanel,14,-44,550,"",14)
 notice=text(prioritiesPanel,14,-66,550,"",11)
 notice:SetTextColor(.78,.82,.88)
 opener=text(prioritiesPanel,14,-87,550,"",11)
 opener:SetTextColor(.55,.84,.95)
 sourceLabel=text(prioritiesPanel,14,-105,550,"",10)
 sourceLabel:SetTextColor(.70,.75,.82)
 W.heading=heading;W.notice=notice;W.rows={};W.panel=prioritiesPanel
 root:Hide()
end

function W.GetHeight()
 return root and root:GetHeight() or 339
end

function W.ShowReference() return showReference end

local function priorityRow(index)
 local row=W.rows[index]
 if row then return row end
 row=CreateFrame("Frame",nil,prioritiesPanel)
 row.bg=row:CreateTexture(nil,"BACKGROUND");row.bg:SetAllPoints(row)
 row.bg:SetColorTexture(.065,.082,.108,1)
 row.icon=row:CreateTexture(nil,"ARTWORK")
 row.icon:SetPoint("TOPLEFT",row,"TOPLEFT",33,-6);row.icon:SetSize(22,22)
 row:EnableMouse(true)
 row:SetScript("OnEnter",function(self)
  if not self.spellID or not GameTooltip then return end
  GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
  local ok=type(GameTooltip.SetSpellByID)=="function" and pcall(GameTooltip.SetSpellByID,GameTooltip,self.spellID)
  if not ok then GameTooltip:SetText(self.spellName) end
  GameTooltip:AddLine("Spell ID: "..self.spellID,.7,.8,.9)
  GameTooltip:Show()
 end)
 row:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
 row.number=text(row,9,-8,26,tostring(index),12)
 row.number:SetTextColor(.96,.80,.48)
 row.caption=text(row,65,-8,473,"",12)
 row.caption:SetJustifyV("TOP")
 row.action=text(row,65,-7,473,"",12)
 row.action:SetTextColor(.96,.82,.52)
 row.status=text(row,65,-26,473,"",10)
 W.rows[index]=row
 return row
end

-- Preserve source order within each group. Use name matches from the
-- spellbook so a different trained rank does not look unavailable.
function W.Plan(instructions,primary,playerClass,shownClass,summary)
 local available,uncertain,missing={},{},{}
 local sameClass=playerClass==shownClass
 local spellbook=ForeverCompanionSpellbook
 local scan=sameClass and spellbook.Scan()
 local preserve=summary and summary.keepOrder
 local ids=summary and summary.spellIDs
 local learnedCount=0
 for i,instruction in ipairs(instructions) do
  local name=primary and primary[i]
  local spell=ForeverCompanionIcons.SpellDetails(name,ids and ids[i])
  local row={text=instruction:gsub("^%d+%.%s+",""),spell=spell}
  local bucket=available
  if name then
   if not sameClass then
    row.status="Class preview"
   elseif (spell and ForeverCompanionKnownSpell(spell.spellID)==true) or spellbook.HasName(scan,name) then
    row.status="In your spellbook"
    learnedCount=learnedCount+1
   elseif spellbook.CanCheckEnglishNames(scan) then
    row.status="Primary spell not found · check talents or training"
    missing[#missing+1]=row
    if not preserve then bucket=nil end
   else
    row.status="Training unconfirmed"
    uncertain[#uncertain+1]=row
    if not preserve then bucket=nil end
   end
  end
  if bucket then bucket[#bucket+1]=row end
 end
 if not preserve then
  for _,row in ipairs(uncertain) do available[#available+1]=row end
  for _,row in ipairs(missing) do available[#available+1]=row end
 end
 return available,learnedCount,#missing
end

function W.Render(tab,class,mode,level,role,fallback,playerClass)
 if not root then return end
 if tab~="Leveling" then root:Hide();return end
 root:Show()
 W.reference:SetText(showReference and "Hide guide notes" or "More guide notes")
 local instructions,title,hint,source,primary,summary=ForeverCompanionVisiblePriority(class,mode,level,role,fallback)
 local steps,learned,missing=W.Plan(instructions,primary,playerClass,class,summary)
 heading:SetText(title)
 if playerClass~=class then
  hint=hint.." Class preview."
 elseif missing>0 and learned==0 and mode~="leveling" then
  hint="No primary spells matched your spellbook. Try Leveling for earlier abilities."
 elseif missing>0 and learned>0 and not (summary and summary.keepOrder) then
  hint=hint.." Learned spells are listed first."
 end
 notice:SetText(hint)
 local y=72+notice:GetStringHeight()
 local setup=summary and summary.opener
 opener:ClearAllPoints()
 opener:SetPoint("TOPLEFT",prioritiesPanel,"TOPLEFT",14,-y)
 opener:SetText(setup and ("Before the pull  ·  "..setup) or "")
 if setup then y=y+opener:GetStringHeight()+10 end
 for i,step in ipairs(steps) do
  local row=priorityRow(i)
  local action,explanation=step.text:match("^(.-) — (.+)$")
  row.instruction=step.text
  row.action:SetText(action or "")
  row.caption:SetText(explanation or step.text)
  local captionY=action and 22 or 8
  row.caption:ClearAllPoints()
  row.caption:SetPoint("TOPLEFT",row,"TOPLEFT",65,-captionY)
  local spell=step.spell
  row.spellID=spell and spell.spellID
  row.spellName=spell and spell.name
  if spell then
   row.icon:SetTexture(spell.iconID)
   row.icon:SetTexCoord(0,1,0,1)
  else
   ForeverCompanionIcons.ApplyClass(row.icon,class)
  end
  local captionHeight=row.caption:GetStringHeight()
  row.caption:SetHeight(captionHeight+2)
  local status=step.status
  if status=="In your spellbook" or status=="Class preview" then status=nil end
  row.status:SetText(status or "")
  row.status:ClearAllPoints()
  row.status:SetPoint("TOPLEFT",row,"TOPLEFT",65,-(captionY+captionHeight+2))
  row.status:SetTextColor(.72,.77,.83)
  local height=math.max(31,captionHeight+captionY+8+(status and row.status:GetStringHeight()+2 or 0))
  row:SetSize(550,height)
  row:ClearAllPoints()
  row:SetPoint("TOPLEFT",prioritiesPanel,"TOPLEFT",14,-y)
  row:Show()
  y=y+height+4
 end
 for i=#steps+1,#W.rows do W.rows[i]:Hide() end
 sourceLabel:SetText(source and ("Source: "..source) or "")
 sourceLabel:ClearAllPoints()
 sourceLabel:SetPoint("TOPLEFT",prioritiesPanel,"TOPLEFT",14,-(y+4))
 local height=math.max(339,y+(source and sourceLabel:GetStringHeight()+18 or 8))
 ForeverCompanionVisualTheme.ResizePanel(prioritiesPanel,height)
 root:SetHeight(height)
 for _,button in ipairs(buttons) do
  local active=button.mode==mode
  button.name:SetTextColor(active and 1 or .88,active and .84 or .86,active and .52 or .82)
  button.bg:SetColorTexture(active and .055 or .025,active and .16 or .028,active and .30 or .034,1)
 end
end
