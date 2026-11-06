-- Interactive read-only talent planner. Left click adds a draft rank.
local W={}
ForeverCompanionTalentWorkspace=W
local planner=ForeverCompanionTalentPlanner
local state,root,tabs,buttons,budgetLabel,summary,details,selectionTitle,status,levelLabel,openingLabel,buildButton,resetButton
local recommendationButton,openingTitle,summaryTitle,guideField
local planLevel=60
local function text(parent,x,y,width,label,size,gold)
 local f=parent:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
 f:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y);f:SetWidth(width);f:SetJustifyH("LEFT")
 f:SetText(label or "")
 f:SetTextColor(gold and .97 or .87,gold and .80 or .89,gold and .48 or .92)
 ForeverCompanionVisualTheme.Font(f,size or 11)
 return f
end

local function control(parent,x,y,w,caption,action)
 local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
 b:SetSize(w,24);b:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y);b:SetText(caption)
 b:SetScript("OnClick",action)
 return b
end

local function refresh()
 W.Render(state.class,state.spec)
end

function W.Create(parent)
 root=CreateFrame("Frame","ForeverCompanionTalentPlannerFrame",parent)
 root:SetPoint("TOPLEFT",parent,"TOPLEFT",0,0);root:SetSize(770,602)
 W.root=root
 text(root,16,-13,730,"Talent Tree & Build Planner",18,true)
 text(root,16,-42,530,"Plan here, then spend points in the game’s talent window.",11)
 recommendationButton=control(root,556,-36,196,"Recommended Build",function()
  state.preview=not state.preview;state.selected=nil;state.message=nil;state.confirmReset=nil
  refresh()
 end)
 W.recommendationButton=recommendationButton
 tabs={}
 for i=1,3 do
  tabs[i]=control(root,16+(i-1)*156,-70,150,"",function()
   state.tree=i;state.selected=nil;state.message=nil;state.confirmReset=nil;refresh()
  end)
 end
 local function adjustLevel(direction)
  local step=type(IsShiftKeyDown)=="function" and IsShiftKeyDown() and 10 or 1
  planLevel=math.max(1,math.min(60,planLevel+direction*step))
  state.message=nil;state.confirmReset=nil;refresh()
 end
 W.lowerLevel=control(root,490,-70,25,"-",function() adjustLevel(-1) end)
 levelLabel=text(root,520,-76,70,"",11,true)
 levelLabel:SetJustifyH("CENTER")
 W.raiseLevel=control(root,592,-70,25,"+",function() adjustLevel(1) end)
 resetButton=control(root,628,-70,124,"Reset draft",function()
  if state.confirmReset then
   for key in pairs(state.allocation) do state.allocation[key]=nil end
   state.confirmReset=nil;state.message="Draft reset."
  else
   state.confirmReset=true;state.message="Confirm reset to clear all three trees in this draft."
  end
  refresh()
 end)
 W.resetButton=resetButton
 budgetLabel=text(root,16,-105,730,"",12,true)
 buttons={}
 for i=1,28 do
  local b=CreateFrame("Button",nil,root)
  b:SetSize(113,52)
  b.bg=ForeverCompanionVisualTheme.Button(b,113,52)
  b.icon=b:CreateTexture(nil,"ARTWORK");b.icon:SetSize(20,20)
  b.icon:SetPoint("TOPLEFT",b,"TOPLEFT",5,-6)
  b.label=text(b,30,-5,80,"",9)
  if b.label.SetMaxLines then b.label:SetMaxLines(3) end
  b.ranks=text(b,6,-38,101,"",10,true)
  if b.RegisterForClicks then b:RegisterForClicks("LeftButtonUp","RightButtonUp") end
  b:SetScript("OnClick",function(self,mouseButton)
   local node=self.node
   if not node then return end
   state.selected=node;state.confirmReset=nil
   if state.preview then refresh();return end
   local ok,why=planner.Change(state.class,state.allocation,node,mouseButton=="RightButton" and -1 or 1,planner.Budget(planLevel))
   state.message=not ok and why or nil;refresh()
  end)
  b:SetScript("OnEnter",function(self)
   if not self.node or not GameTooltip then return end
   local node=self.node
   GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
   local ok=node[7]>0 and type(GameTooltip.SetSpellByID)=="function" and pcall(GameTooltip.SetSpellByID,GameTooltip,node[7])
   if not ok then GameTooltip:SetText(node[9]) end
   local recommended=state.preview and planner.Recommendation(state.class,state.spec[1])
   local allocation=recommended and recommended[3] or state.allocation
   GameTooltip:AddLine((recommended and "Recommended: " or "Draft: ")..planner.Rank(allocation,node).." / "..node[6])
   if not recommended then GameTooltip:AddLine("Left click adds a rank. Right click refunds.",.75,.8,.9,true) end
   GameTooltip:Show()
  end)
  b:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
  buttons[i]=b
 end
 W.buttons=buttons;W.tabs=tabs
 local side=CreateFrame("Frame",nil,root)
 side:SetSize(246,392);side:SetPoint("TOPLEFT",root,"TOPLEFT",507,-130)
 ForeverCompanionVisualTheme.Panel(side,246,392)
 openingTitle=text(side,12,-12,221,"",15,true)
 openingLabel=text(side,12,-38,222,"",11)
 buildButton=control(side,12,-91,220,"Load opening ranks",function()
  state.confirmReset=nil
  if state.preview then
   local ok,message=planner.CopyRecommendation(state.class,state.spec[1],state.allocation)
   if ok then state.preview=false;planLevel=60 end
   state.message=ok and "Recommended build copied into your draft." or message
   refresh()
   return
  end
  local ok,message=planner.LoadOpening(state.class,state.tree,state.spec[1],state.allocation,planner.Budget(planLevel))
  state.message=ok and "Opening loaded into your draft." or message
  refresh()
 end)
 W.buildButton=buildButton
 summaryTitle=text(side,12,-130,221,"",15,true)
 summary=text(side,12,-155,222,"",11)
 selectionTitle=text(side,12,-242,222,"",13,true)
 details=text(side,12,-273,222,"",11)
 status=text(side,12,-341,222,"",11,true)
 text(root,16,-530,736,"Draft controls: left click adds a rank, right click refunds. Shift-click + or - changes level by 10.",11)
 text(root,16,-551,736,"Grid adapted from Zephras (CC BY 4.0). Names and icon references belong to Blizzard.",10)
 local function reference(x,width,url)
  local field=CreateFrame("EditBox",nil,root,"InputBoxTemplate")
  field:SetSize(width,22);field:SetPoint("TOPLEFT",root,"TOPLEFT",x,-570)
  if field.SetAutoFocus then field:SetAutoFocus(false) end
  field.url=url
  field:SetText(url)
  field:SetScript("OnEditFocusGained",function(self) self:HighlightText() end)
  field:SetScript("OnEditFocusLost",function(self) self:SetText(self.url) end)
  field:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
  return field
 end
 reference(18,209,"https://zephras.com/data/")
 guideField=reference(245,507,"")
 root:Hide()
end

function W.Render(class,spec)
 if not root then return end
 local data=ForeverCompanionTalentData.classes[class]
 if not data or not spec then root:Hide();return end
 local name=spec[1]
 if not state or state.class~=class or state.spec[1]~=name then
  local _,specIndex=ForeverCompanionSpecPlanner.Get(class)
  state={class=class,spec=spec,tree=math.min(3,specIndex),allocation=planner.Load(class,name)}
  if name=="Guardian / Bear" then state.tree=2 end
 end
 local recommended=planner.Recommendation(class,name)
 local preview=state.preview and recommended
 local allocation=preview and recommended[3] or state.allocation
 local budget=planner.Budget(preview and 60 or planLevel)
 local total=planner.Total(class,allocation)
 recommendationButton:SetEnabled(recommended~=nil)
 recommendationButton:SetText(preview and "Back to My Draft" or "Recommended Build")
 W.lowerLevel:SetEnabled(not preview);W.raiseLevel:SetEnabled(not preview);resetButton:SetEnabled(not preview)
 levelLabel:SetText(preview and "Level 60" or ("Plan Lv. "..planLevel))
 local guideURL="https://www.icy-veins.com/wow-forever/"..(recommended and recommended[2] or "class-guides")
 if guideField.url~=guideURL then guideField.url=guideURL;guideField:SetText(guideURL) end
 resetButton:SetText(state.confirmReset and "Confirm reset" or "Reset draft")
 local totals={}
 for i,tab in ipairs(tabs) do
  local points=planner.Total(class,allocation,i)
  tab:SetText((i==state.tree and "› " or "")..data.trees[i].." ("..points..")")
  totals[i]=points
 end
 if preview then
  openingTitle:SetText("Recommended Build")
  openingLabel:SetText(recommended[1].."\nLevel 60 PvE • Icy Veins")
  buildButton:SetText("Copy to empty draft")
 else
  local opening={}
  for _,node in ipairs(planner.Opening(class,state.tree,name)) do opening[#opening+1]=node[9] end
  openingTitle:SetText("Suggested opening")
  openingLabel:SetText(table.concat(opening,"  →  "))
  buildButton:SetText("Load opening ranks")
 end
 local left=budget-total
 budgetLabel:SetText(string.format("%s   •   %s   •   %s   •   %d / %d points",
  name,spec[2],table.concat(totals," / "),total,budget))
 local names={}
 local goals={}
 if preview then
  summaryTitle:SetText("Points by tree")
  for i,tree in ipairs(data.trees) do names[i]=tree.."  ·  "..totals[i] end
 else
  summaryTitle:SetText("Build milestones")
  for _,node in ipairs(planner.Goals(class,state.tree,name)) do
   goals[node[1]]=true
   names[#names+1]=node[9].."  ·  "..node[5].." points in tree"
  end
 end
 summary:SetText(table.concat(names,"\n"))
 local prereqs={}
 for _,id in ipairs(state.selected and state.selected[10] or {}) do prereqs[id]=true end
 local i=0
 for _,node in ipairs(data.nodes) do
  if node[2]==state.tree then
   i=i+1
   local b=buttons[i]
   b.node=node
   b:ClearAllPoints()
   b:SetPoint("TOPLEFT",root,"TOPLEFT",16+(node[4]-1)*122,-130-(node[3]-1)*56)
   b.icon:SetTexture(node[8]>0 and node[8] or ForeverCompanionIcons.unknown)
   b.label:SetText(node[9])
   local rank=planner.Rank(allocation,node)
   b.ranks:SetText(rank.."/"..node[6]..(not preview and goals[node[1]] and "  ·  Goal" or ""))
   local eligible=not preview and planner.CanAdd(class,allocation,node,budget)
   if state.selected==node then b.bg:SetColorTexture(.16,.24,.34,1)
   elseif prereqs[node[1]] then b.bg:SetColorTexture(.26,.15,.31,1)
   elseif rank>0 then b.bg:SetColorTexture(.19,.14,.07,1)
   elseif eligible then b.bg:SetColorTexture(.09,.12,.17,1)
   else b.bg:SetColorTexture(.04,.05,.07,1) end
   b:Show()
  end
 end
 for j=i+1,#buttons do buttons[j].node=nil;buttons[j]:Hide() end
 local selected=state.selected
 selectionTitle:SetText(selected and selected[9] or (preview and "Build details" or "Draft details"))
 if selected then
  local parents={}
  for _,node in ipairs(data.nodes) do
   if prereqs[node[1]] then parents[#parents+1]=node[9] end
  end
  local needs=#parents>0 and ("\nRequires max "..table.concat(parents,", ")) or ""
  local rank=planner.Rank(allocation,selected).." / "..selected[6]
  local instruction="Recommended rank "..rank
  if not preview then
   local ok,reason=planner.CanAdd(class,allocation,selected,budget)
   instruction="Rank "..rank.."\n"..(ok and "Next rank available." or reason)
  end
  details:SetText(instruction..needs)
 elseif preview then
  details:SetText("Select a talent or switch trees to inspect the full build. Your draft is saved separately.")
 else
  details:SetText("Choose a talent to see its requirements. The opening is a leveling suggestion.")
 end
 status:SetText(state.message or (preview and "Read-only preview\nData build "..ForeverCompanionTalentData.build) or (left<0 and ("Draft exceeds this level by "..(-left).." points.") or (left.." points available\nData build "..ForeverCompanionTalentData.build)))
 root:Show()
end

function W.Hide()
 if root then root:Hide() end
end
