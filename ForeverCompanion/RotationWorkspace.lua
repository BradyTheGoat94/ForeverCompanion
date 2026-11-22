-- Read-only rotation priorities. Clicking a row never invokes a game action.
local W={}
ForeverCompanionRotationWorkspace=W
local root,heading,notice,opener,sourceLabel,buttons,prioritiesPanel,showReference
local search,filterButtons,readiness,empty
local lastClass
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
local function prefs()
 ForeverCompanionDB=ForeverCompanionDB or {}
 if type(ForeverCompanionDB.rotationGuide)~='table' then ForeverCompanionDB.rotationGuide={} end
 return ForeverCompanionDB.rotationGuide
end
function W.GetFilter()
 local mode=prefs().filter
 return (mode=='learned' or mode=='training') and mode or 'all'
end
function W.SetFilter(mode)
 if mode~='all' and mode~='learned' and mode~='training' then return false end
 prefs().filter=mode
 if ForeverCompanionRefresh then ForeverCompanionRefresh() end
 return true
end
function W.FilterPlan(plan,query,mode)
 local result={};query=type(query)=='string' and query:lower():gsub('^%s+',''):gsub('%s+$','') or ''
 for _,step in ipairs(plan or {}) do
  local matches=query=='' or (tostring(step.text or '')..' '..tostring(step.spell and step.spell.name or '')..' '..tostring(step.spell and step.spell.spellID or '')):lower():find(query,1,true)
  local state=mode==nil or mode=='all' or mode=='learned' and step.readiness=='learned' or mode=='training' and (step.readiness=='missing' or step.readiness=='unknown')
  if matches and state then result[#result+1]=step end
 end
 return result
end
function W.Readiness(plan)
 local counts={learned=0,missing=0,unknown=0,preview=0,advice=0}
 for _,step in ipairs(plan or {}) do local key=step.readiness or 'advice';counts[key]=(counts[key] or 0)+1 end
 return counts
end
function W.Create(parent,selectMode)
 root=CreateFrame("Frame","ForeverCompanionRotationWorkspacePanel",parent);root:SetPoint("TOPLEFT",parent,"TOPLEFT",8,-174);root:SetSize(770,500);W.root=root
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
  showReference=true
  ForeverCompanionRefresh()
 end)
 ForeverCompanionInterface.SetHoverHelp(W.reference,"Class reference","Browse spell, travel, unlock and training notes in a separate window.")
 prioritiesPanel=plate(root,192,0,578,302,"What to Press")
 heading=text(prioritiesPanel,14,-44,550,"",14)
 notice=text(prioritiesPanel,14,-66,550,"",11)
 notice:SetTextColor(.78,.82,.88)
 opener=text(prioritiesPanel,14,-87,550,"",11)
 opener:SetTextColor(.55,.84,.95)
 sourceLabel=text(prioritiesPanel,14,-105,550,"",10)
 sourceLabel:SetTextColor(.70,.75,.82)
 search=ForeverCompanionInterface.EditBox(prioritiesPanel,'Search advice, spell name or ID');search:SetPoint('TOPLEFT',14,-126);search:SetSize(550,26);search:SetMaxLetters(100)
 search:SetScript('OnTextChanged',function(_,userInput)
  if userInput==false or not ForeverCompanionRefresh then return end
  local queue=ForeverCompanionRefreshQueue
  if queue and queue.Schedule then queue.Schedule('rotation-guide-search',ForeverCompanionRefresh) else ForeverCompanionRefresh() end
 end)
 filterButtons={}
 for i,option in ipairs({{'all','All advice'},{'learned','Learned spells'},{'training','Check training'}}) do
  local key,label=option[1],option[2];local b=ForeverCompanionInterface.Button(prioritiesPanel)
  b:SetPoint('TOPLEFT',14+(i-1)*185,-158);b:SetSize(180,25);b:SetText(label);b:SetScript('OnClick',function() W.SetFilter(key) end);filterButtons[key]=b
 end
 readiness=text(prioritiesPanel,14,-191,550,'',10);readiness:SetWordWrap(true)
 empty=text(prioritiesPanel,14,-225,550,'',12);empty:SetWordWrap(true);empty:SetHeight(62);empty:Hide()
 W.search=search;W.filters=filterButtons;W.readinessLabel=readiness
 W.heading=heading;W.notice=notice;W.rows={};W.panel=prioritiesPanel
 root:Hide()
end

function W.GetHeight()
 return root and root:GetHeight() or 339
end

function W.TakeReferenceRequest()
 local requested=showReference
 showReference=nil
 return requested
end

local function priorityRow(index)
 local row=W.rows[index]
 if row then return row end
 row=CreateFrame("Button",nil,prioritiesPanel)
 row.bg=row:CreateTexture(nil,"BACKGROUND");row.bg:SetAllPoints(row)
 row.bg:SetColorTexture(.065,.082,.108,1)
 row.icon=row:CreateTexture(nil,"ARTWORK")
 row.icon:SetPoint("TOPLEFT",row,"TOPLEFT",33,-6);row.icon:SetSize(22,22)
 row:EnableMouse(true);row:RegisterForClicks('LeftButtonUp')
 row:SetScript('OnClick',function(self)
  if self.trainingEnabled and self.spellName and ForeverCompanionTraining and ForeverCompanionTraining.Open then ForeverCompanionTraining.Open(self.spellName) end
 end)
 row:SetScript("OnEnter",function(self)
  if not GameTooltip then return end
  GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
  local ok=self.spellID and type(GameTooltip.SetSpellByID)=="function" and pcall(GameTooltip.SetSpellByID,GameTooltip,self.spellID)
  if not ok then GameTooltip:SetText(self.spellName or 'Guide advice');GameTooltip:AddLine(self.instruction or '',.9,.9,.85,true) end
  if self.spellID then GameTooltip:AddLine('Spell ID: '..self.spellID,.7,.8,.9) end
  GameTooltip:AddLine(self.readinessText or 'Spell availability unconfirmed',.7,.85,.8,true)
  GameTooltip:AddLine(self.trainingEnabled and "Click to review training. Guide advice is a reference, not a live rotation recommendation." or "Class preview. Training belongs to your current character.",.7,.8,.9,true)
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
  local row={text=instruction:gsub("^%d+%.%s+",""),spell=spell,order=i,readiness="advice"}
  local bucket=available
  if name then
   if not sameClass then
    row.status="Class preview";row.readiness="preview"
   elseif (spell and ForeverCompanionKnownSpell(spell.spellID)==true) or spellbook.HasName(scan,name) then
    row.status="In your spellbook";row.readiness="learned"
    learnedCount=learnedCount+1
   elseif spellbook.CanCheckEnglishNames(scan) then
    row.status="Primary spell not found · check talents or training";row.readiness="missing"
    missing[#missing+1]=row
    if not preserve then bucket=nil end
   else
    row.status="Training unconfirmed";row.readiness="unknown"
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
 W.reference:SetText("Class reference")
 local instructions,title,hint,source,primary,summary=ForeverCompanionVisiblePriority(class,mode,level,role,fallback)
 local plan,learned,missing=W.Plan(instructions,primary,playerClass,class,summary)
 if lastClass~=class then lastClass=class;search:SetText('') end
 local filter=W.GetFilter();local steps=W.FilterPlan(plan,search:GetText(),filter);local counts=W.Readiness(plan)
 for key,b in pairs(filterButtons) do ForeverCompanionInterface.StyleButton(b,nil,key==filter) end
 readiness:SetText(playerClass~=class and 'Class preview: training is checked only for your current character.' or (counts.learned..' learned · '..counts.missing..' not found · '..counts.unknown..' unconfirmed · '..#steps..' / '..#plan..' advice rows shown'))
 empty:SetShown(#steps==0)
 empty:SetText(playerClass~=class and filter~='all' and 'This is another class preview. Choose All advice to read it; learned and training views apply to your character.' or 'No advice matches this view. Clear search or choose All advice. Missing spells may depend on talents, ranks or training; confirm in game.')
 heading:SetText(title)
 if playerClass~=class then
  hint=hint.." Class preview."
 elseif missing>0 and learned==0 and mode~="leveling" then
  hint="No primary spells matched your spellbook. Try Leveling for earlier abilities."
 elseif missing>0 and learned>0 and not (summary and summary.keepOrder) then
  hint=hint.." Learned spells are listed first."
 end
 notice:SetText(hint)
 local searchY=72+notice:GetStringHeight()
 search:ClearAllPoints();search:SetPoint('TOPLEFT',14,-searchY)
 for i,key in ipairs({'all','learned','training'}) do filterButtons[key]:ClearAllPoints();filterButtons[key]:SetPoint('TOPLEFT',14+(i-1)*185,-searchY-32) end
 readiness:ClearAllPoints();readiness:SetPoint('TOPLEFT',14,-searchY-65)
 local y=searchY+65+readiness:GetStringHeight()+12
 local setup=summary and summary.opener
 opener:ClearAllPoints()
 opener:SetPoint("TOPLEFT",prioritiesPanel,"TOPLEFT",14,-y)
 opener:SetText(setup and ("Before the pull  ·  "..setup) or "")
 if setup then y=y+opener:GetStringHeight()+10 end
 empty:ClearAllPoints();empty:SetPoint('TOPLEFT',14,-y)
 if #steps==0 then y=y+74 end
 for i,step in ipairs(steps) do
  local row=priorityRow(i)
  local action,explanation=step.text:match("^(.-) — (.+)$")
  row.instruction=step.text
  row.number:SetText(step.order or i);row.readinessText=step.status
  row.action:SetText(action or "")
  row.caption:SetText(explanation or step.text)
  local captionY=action and 22 or 8
  row.caption:ClearAllPoints()
  row.caption:SetPoint("TOPLEFT",row,"TOPLEFT",65,-captionY)
  local spell=step.spell
  row.spellID=spell and spell.spellID
  row.spellName=spell and spell.name
  row.trainingEnabled=playerClass==class
  if spell then
   row.icon:SetTexture(spell.iconID)
   row.icon:SetTexCoord(0,1,0,1)
  else
   ForeverCompanionIcons.ApplyClass(row.icon,class)
  end
  local captionHeight=row.caption:GetStringHeight()
  row.caption:SetHeight(captionHeight+2)
  local status=step.status
  -- Keep learned and preview evidence visible alongside every spell.
  row.status:SetText(status or "")
  row.status:ClearAllPoints()
  row.status:SetPoint("TOPLEFT",row,"TOPLEFT",65,-(captionY+captionHeight+2))
  row.status:SetTextColor(step.readiness=='learned' and .50 or .85,step.readiness=='learned' and .86 or .77,.70)
  local height=math.max(31,captionHeight+captionY+8+(status and row.status:GetStringHeight()+2 or 0))
  row:SetSize(550,height)
  row:ClearAllPoints()
  row:SetPoint("TOPLEFT",prioritiesPanel,"TOPLEFT",14,-y)
  row:Show()
  y=y+height+4
 end
 for i=#steps+1,#W.rows do W.rows[i]:Hide() end
 sourceLabel:SetText("Advice: "..(source or "General reference; verify for Forever").."\nSpell icons use client data. Trained status is checked separately from guide advice.")
 sourceLabel:SetWordWrap(true)
 sourceLabel:ClearAllPoints()
 sourceLabel:SetPoint("TOPLEFT",prioritiesPanel,"TOPLEFT",14,-(y+4))
 local height=math.max(339,y+sourceLabel:GetStringHeight()+18)
 ForeverCompanionVisualTheme.ResizePanel(prioritiesPanel,height)
 root:SetHeight(height)
 for _,button in ipairs(buttons) do
  local active=button.mode==mode
  button.name:SetTextColor(active and 1 or .88,active and .84 or .86,active and .52 or .82)
  ForeverCompanionVisualTheme.SelectRow(button,button.bg,active)
 end
end
