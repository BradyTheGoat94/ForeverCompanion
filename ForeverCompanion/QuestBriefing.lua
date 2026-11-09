-- Native quest journal briefing; strictly reads the addon's cached quest-log snapshot.
-- Navigation changes only the user waypoint when the player clicks.
local B={}
ForeverCompanionQuestBriefing=B
local root, values, fill, mapButton, clearPin, autoFocusButton,trackerButton
local shownQuest, shownComplete, mapMessage
local BAR_WIDTH=320
local function paint(t,r,g,b,a)
  if t.SetColorTexture then t:SetColorTexture(r,g,b,a or 1)
  else t:SetTexture(r,g,b,a or 1) end
end
local function label(parent,x,y,w,initial,style,color)
  local t=parent:CreateFontString(nil,"OVERLAY",style or "GameFontHighlightSmall")
  t:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
  t:SetWidth(w)
  t:SetJustifyH("LEFT")
  t:SetText(initial or "")
  ForeverCompanionVisualTheme.Font(t,12)
  if color then t:SetTextColor(color[1],color[2],color[3]) end
  return t
end
local function card(parent,x,w,heading)
  local frame=CreateFrame("Frame",nil,parent)
  frame:SetSize(w,151)
  frame:SetPoint("TOPLEFT",parent,"TOPLEFT",x,0)
  ForeverCompanionVisualTheme.Panel(frame,w,151)
  local title=label(frame,15,-12,w-146,heading,"GameFontNormal",{.82,.71,.50})
  ForeverCompanionVisualTheme.Font(title,12)
  title:SetWordWrap(false);title:SetHeight(18)
  return frame
end
local function shorten(v,n)
  v=tostring(v or "Unavailable"):gsub("[\r\n|]"," ")
  if #v>n then return v:sub(1,n-3).."..." end
  return v
end
function B.Create(parent)
  root=CreateFrame("Frame",nil,parent)
  root:SetSize(770,151)
  root:SetPoint("TOPLEFT",parent,"TOPLEFT",8,-5)
  values={}
  local summary=card(root,0,376,"JOURNAL AT A GLANCE")
  values.count=label(summary,16,-49,344,"Waiting for quest scan","GameFontHighlight",{0.93,0.90,0.82})
  values.zone=ForeverCompanionInterface.Button(summary)
  values.zone:SetPoint('TOPLEFT',16,-72);values.zone:SetSize(344,24)
  values.zone:SetScript('OnClick',function() ForeverCompanionQuestSetup.Toggle() end)
  values.status=label(summary,16,-124,215,"Quest log","GameFontHighlightSmall",{0.76,0.70,0.57})
  trackerButton=ForeverCompanionInterface.Button(summary)
  trackerButton:SetSize(112,22);trackerButton:SetPoint('TOPRIGHT',summary,'TOPRIGHT',-12,-119)
  trackerButton:SetScript('OnClick',function() ForeverCompanionQuestTracker.Toggle();B.Render() end)
  autoFocusButton=ForeverCompanionInterface.Button(summary)
  autoFocusButton:SetSize(106,22);autoFocusButton:SetPoint("TOPRIGHT",summary,"TOPRIGHT",-12,-9)
  autoFocusButton:SetScript("OnClick",function()
    local planner=ForeverCompanionQuestPlanner
    planner.SetAutoFocus(not planner.IsAutoFocus())
    B.Render()
  end)
  local track=summary:CreateTexture(nil,"ARTWORK")
  track:SetPoint("TOPLEFT",summary,"TOPLEFT",16,-103)
  track:SetSize(BAR_WIDTH,9)
  paint(track,0.17,0.22,0.28,1)
  fill=summary:CreateTexture(nil,"OVERLAY")
  fill:SetPoint("TOPLEFT",summary,"TOPLEFT",16,-103)
  fill:SetSize(1,9)
  paint(fill,0.92,0.68,0.29,1)
  local focus=card(root,389,381,"FOCUSED OBJECTIVE")
  values.title=label(focus,15,-47,351,"No quest selected","GameFontHighlight",{0.93,0.90,0.82})
  values.location=label(focus,15,-74,351,"Choose a quest below","GameFontHighlightSmall",{0.72,0.78,0.84})
  values.objective=label(focus,15,-101,351,"Objective information will appear here","GameFontHighlightSmall",{0.89,0.74,0.48})
  values.hint=label(focus,15,-125,282,"","GameFontHighlightSmall",{0.77,0.76,0.66})
  mapButton=ForeverCompanionInterface.Button(focus)
  mapButton:SetSize(119,22);mapButton:SetPoint("TOPRIGHT",focus,"TOPRIGHT",-12,-9)
  mapButton:SetText("Quest details")
  mapButton:SetScript("OnClick",function()
    local planner=ForeverCompanionQuestPlanner
    if planner.IsSupported() then
      local q=planner.GetSelected()
      mapMessage=nil
      if q and ForeverCompanionOpenQuestGuide then ForeverCompanionOpenQuestGuide(q.id) end
      B.Render()
    end
  end)
  clearPin=ForeverCompanionInterface.Button(focus)
  clearPin:SetSize(66,20);clearPin:SetPoint("TOPRIGHT",focus,"TOPRIGHT",-12,-118)
  clearPin:SetText("Clear pin")
  clearPin:SetScript("OnClick",function()
    if ForeverCompanionQuestWaypoints.Clear() then mapMessage="Map pin cleared." end
    B.Render()
  end)
  B.mapButton=mapButton;B.clearPin=clearPin;B.autoFocusButton=autoFocusButton
  root:Hide()
  return root
end
function B.Render()
  if not root then return end
  trackerButton:SetText(ForeverCompanionQuestTracker.IsShown() and 'Hide tracker' or 'Show tracker')
  local planner=ForeverCompanionQuestPlanner
  if not planner then
    values.count:SetText("Quest planner unavailable")
    values.status:SetText("No quest data")
    fill:SetWidth(1)
    return
  end
  local report=planner.Overview and planner.Overview() or nil
  local count=report and report.total or 0
  local ready=report and report.ready or 0
  local valid=report and report.supported
  local stale=report and report.stale
  autoFocusButton:SetText(planner.IsAutoFocus() and "Auto focus: On" or "Auto focus: Off")
  if not report or not report.scanned then
    values.count:SetText("Waiting for first quest-log scan")
    values.status:SetText("Open the in-game quest log to check availability")
  elseif valid then
    values.count:SetText(tostring(count).." active  |  "..tostring(ready).." ready  |  "..tostring(report.pinned or 0).." pinned")
    values.status:SetText("Map: active quest locations")
  elseif stale then
    values.count:SetText(tostring(count).." cached quests  |  "..tostring(ready).." last ready")
    values.status:SetText("Cached. Check your quest log.")
  else
    values.count:SetText("Quest-log API unavailable")
    values.status:SetText("Manual quest notes remain available")
  end
  local reference=ForeverCompanionQuestLocations.IsAvailable()
  values.zone:SetText(reference and "Quest data: Native + references / Setup" or "Quest data: Native only / Setup")
  fill:SetWidth(valid and count>0 and math.max(1,math.floor(BAR_WIDTH*ready/count)) or 1)
  local selected=planner.GetSelected and planner.GetSelected() or nil
  local questKey=selected and (selected.id or selected.title)
  local complete=selected and selected.complete
  if shownQuest~=questKey or shownComplete~=complete or not valid then mapMessage=nil end
  shownQuest=questKey;shownComplete=complete
  mapButton:SetEnabled(valid and selected~=nil)
  clearPin:SetEnabled(ForeverCompanionQuestWaypoints.HasNavigation())
  if selected then
    values.title:SetText((planner.IsPinned and planner.IsPinned(selected) and "[PINNED] " or "")..shorten(selected.title,38))
    values.location:SetText((selected.complete and "Ready to turn in" or "In progress").."  |  "..shorten(selected.zone or "Unknown zone",27))
    local objective
    if not selected.complete then
      for i,step in ipairs(selected.objectives or {}) do
        local state=selected.objectiveStates and selected.objectiveStates[i]
        if not state or not state.done then objective=step;break end
      end
    end
    values.objective:SetText(shorten(objective or (selected.complete and "Next: turn in this quest." or "Check the quest log for details."),48))
    local done,known
    if type(planner.ObjectiveProgress)=="function" then done,known=planner.ObjectiveProgress(selected) end
    if stale then
      values.hint:SetText("Cached objective. Check your quest log.")
    elseif mapMessage then
      values.hint:SetText(mapMessage)
    elseif known then
      values.hint:SetText(done.." / "..known.." objectives complete")
    else
      values.hint:SetText("")
    end
  else
    values.title:SetText("No focused quest")
    values.location:SetText("Select an active quest below")
    values.objective:SetText("Objective details will appear here")
    values.hint:SetText("")
  end
end
function B.Show(show)
  if not root then return end
  if show then root:Show();B.Render() else root:Hide() end
end
