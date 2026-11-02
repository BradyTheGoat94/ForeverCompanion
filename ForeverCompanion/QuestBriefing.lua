-- Native quest journal briefing; strictly reads the addon's cached quest-log snapshot.
-- Does not change quest selection in the game, accept quests, or turn in quests.
local B={}
ForeverCompanionQuestBriefing=B
local root, values, fill
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
  if color then t:SetTextColor(color[1],color[2],color[3]) end
  return t
end
local function card(parent,x,w,heading)
  local frame=CreateFrame("Frame",nil,parent)
  frame:SetSize(w,151)
  frame:SetPoint("TOPLEFT",parent,"TOPLEFT",x,0)
  local bg=frame:CreateTexture(nil,"BACKGROUND")
  bg:SetAllPoints(frame)
  paint(bg,0.058,0.077,0.103,0.99)
  local trim=frame:CreateTexture(nil,"ARTWORK")
  trim:SetPoint("TOPLEFT",frame,"TOPLEFT",0,0)
  trim:SetSize(w,2)
  paint(trim,0.91,0.67,0.28,1)
  label(frame,15,-14,w-30,heading,"GameFontNormal",{0.96,0.76,0.39})
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
  values.zone=label(summary,16,-75,344,"Zone data unavailable","GameFontHighlightSmall",{0.68,0.75,0.82})
  values.status=label(summary,16,-124,344,"Read-only quest information","GameFontHighlightSmall",{0.76,0.70,0.57})
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
  values.hint=label(focus,15,-125,351,"Guidance only; no automated route","GameFontHighlightSmall",{0.62,0.70,0.76})
  root:Hide()
  return root
end
function B.Render()
  if not root then return end
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
  if not report or not report.scanned then
    values.count:SetText("Waiting for first quest-log scan")
    values.status:SetText("Open the in-game quest log to check availability")
  elseif valid then
    values.count:SetText(tostring(count).." active  |  "..tostring(ready).." ready to turn in")
    values.status:SetText("Live quest-log snapshot")
  elseif stale then
    values.count:SetText(tostring(count).." cached quests  |  "..tostring(ready).." last ready")
    values.status:SetText("STALE DATA - verify in the game quest log")
  else
    values.count:SetText("Quest-log API unavailable")
    values.status:SetText("Manual quest notes remain available")
  end
  local top=report and report.zones and report.zones[1]
  values.zone:SetText(top and ("Top zone: "..shorten(top.zone,31).." ("..top.count..")") or "No quest-zone information")
  fill:SetWidth(valid and count>0 and math.max(1,math.floor(BAR_WIDTH*ready/count)) or 1)
  local selected=planner.GetSelected and planner.GetSelected() or nil
  if selected then
    values.title:SetText(shorten(selected.title,46))
    values.location:SetText((selected.complete and "Ready to turn in" or "In progress").."  |  "..shorten(selected.zone or "Unknown zone",27))
    values.objective:SetText(shorten(selected.objectives and selected.objectives[1] or "Objective details not supplied by client",48))
    values.hint:SetText(stale and "Cached objective - verify in game" or "Select another quest below to change focus")
  else
    values.title:SetText("No focused quest")
    values.location:SetText("Select an active quest below")
    values.objective:SetText("Objective details will appear here")
    values.hint:SetText("No route or turn-in automation")
  end
end
function B.Show(show)
  if not root then return end
  if show then root:Show();B.Render() else root:Hide() end
end
