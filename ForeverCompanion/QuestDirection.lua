-- Display a straight-line bearing to a destination chosen by the player.
local D={}
ForeverCompanionQuestDirection=D
local frame,arrow,title,status,target,elapsed,progressFill
local currentPoint,arrivalDistance,near,confidence
local atan2=math.atan2
local function settings()
 ForeverCompanionDB=ForeverCompanionDB or {}
 if type(ForeverCompanionDB.questDirection)~='table' then ForeverCompanionDB.questDirection={} end
 return ForeverCompanionDB.questDirection
end

local function finite(n)
 if issecretvalue and issecretvalue(n) then return false end
 return type(n)=="number" and n==n and math.abs(n)<math.huge
end

local function worldPosition(map,position)
 if not map or not position then return end
 local continent,vector=C_Map.GetWorldPosFromMapPos(map,position)
 if not vector or not finite(continent) then return end
 local north,west=vector:GetXY()
 if finite(north) and finite(west) then return continent,north,west end
end

local function bearing(destination)
 if not destination then return end
 local map=C_Map.GetBestMapForUnit("player")
 if not map then return end
 local continent,north,west=worldPosition(map,C_Map.GetPlayerMapPosition(map,"player"))
 if not finite(north) or not finite(west) or continent~=destination.continent then return end
 local facing=GetPlayerFacing()
 if not finite(facing) then return end
 local deltaNorth,deltaWest=destination.north-north,destination.west-west
 local distance=math.sqrt(deltaNorth*deltaNorth+deltaWest*deltaWest)
 if not finite(distance) then return end
 return atan2(deltaWest,deltaNorth)-facing,distance
end

local function update(_,dt)
 elapsed=elapsed+dt
 if elapsed<.10 then return end
 elapsed=0
 local ok,angle,distance=pcall(bearing,target)
 if not ok or not distance then
  arrivalDistance=nil;near=false
  arrow:Hide()
  status:SetText("Direction unavailable here")
  if progressFill then progressFill:SetWidth(0.01) end
 elseif distance<=12 then
  arrivalDistance=distance;near=true
  arrow:Hide()
  status:SetText("Arrived nearby · inspect destination")
  if progressFill then progressFill:SetWidth(221) end
 else
  arrivalDistance=distance;near=false
  arrow:SetRotation(angle)
  if settings().compact then arrow:Hide() else arrow:Show() end
  status:SetText(("%d yd  ·  Straight-line direction"):format(math.floor(distance+.5)))
  -- Decorative proximity cue, not quest completion or route progress.
  if progressFill then progressFill:SetWidth(221*math.max(0,math.min(1,1-distance/500))) end
 end
end

local function create()
 frame=CreateFrame("Frame",'ForeverCompanionDirectionFrame',UIParent)
 frame:SetSize(245,146)
 frame:SetPoint("TOP",UIParent,"TOP",0,-115)
 frame:SetFrameStrata("HIGH")
 frame:EnableMouse(true);frame:SetMovable(true);frame:SetClampedToScreen(true)
 local cfg=settings()
 if type(cfg.position)=='table' and finite(cfg.position.x) and finite(cfg.position.y) then
  frame:ClearAllPoints();frame:SetPoint('CENTER',UIParent,'CENTER',cfg.position.x,cfg.position.y)
 end
 local drag=CreateFrame('Frame',nil,frame);drag:SetPoint('BOTTOMLEFT',frame,'BOTTOMLEFT',0,24);drag:SetSize(219,24)
 drag:EnableMouse(true);drag:RegisterForDrag('LeftButton')
 drag:SetScript('OnDragStart',function() if not settings().locked then frame:StartMoving() end end)
 drag:SetScript('OnDragStop',function()
  frame:StopMovingOrSizing()
  local x,y=frame:GetCenter();local px,py=UIParent:GetCenter()
  local fs=frame.GetEffectiveScale and frame:GetEffectiveScale()
  local ps=UIParent.GetEffectiveScale and UIParent:GetEffectiveScale()
  if finite(fs) and fs>0 and finite(ps) and ps>0 and finite(px) and finite(py) then px,py=px*ps/fs,py*ps/fs end
  if finite(x) and finite(y) and finite(px) and finite(py) then
   settings().position={x=x-px,y=y-py};frame:ClearAllPoints();frame:SetPoint('CENTER',UIParent,'CENTER',x-px,y-py)
  end
 end)
 frame.dragHandle=drag
 local options=ForeverCompanionInterface.Button(frame);options:SetText('...');options:SetSize(20,20);options:SetPoint('BOTTOMLEFT',3,24)
 options:SetScript('OnClick',function() D.OpenOptions(options) end);frame.options=options
 D.ApplyScale()
 local bg=frame:CreateTexture(nil,"BACKGROUND")
 bg:SetPoint("BOTTOMLEFT",0,0)
 bg:SetPoint("BOTTOMRIGHT",0,0)
 bg:SetHeight(68);frame.bg=bg
 bg:SetColorTexture(.022,.028,.038,.98)
 local top=frame:CreateTexture(nil,"BORDER")
 top:SetColorTexture(.18,.79,.92,.95)
 top:SetPoint("BOTTOMLEFT",bg,"TOPLEFT",0,0)
 top:SetPoint("BOTTOMRIGHT",bg,"TOPRIGHT",0,0)
 top:SetHeight(1)
 local footer=frame:CreateTexture(nil,"BORDER")
 footer:SetColorTexture(.11,.38,.50,.9)
 footer:SetPoint("BOTTOMLEFT",bg,"BOTTOMLEFT",0,0)
 footer:SetPoint("BOTTOMRIGHT",bg,"BOTTOMRIGHT",0,0)
 footer:SetHeight(1)
 local progressTrack=frame:CreateTexture(nil,"BORDER")
 progressTrack:SetPoint("BOTTOM",frame,"BOTTOM",0,5)
 progressTrack:SetSize(221,3)
 progressTrack:SetColorTexture(.08,.20,.28,.9)
 progressFill=frame:CreateTexture(nil,"ARTWORK")
 progressFill:SetPoint("LEFT",progressTrack,"LEFT",0,0)
 progressFill:SetSize(.01,3)
 progressFill:SetColorTexture(.18,.83,.96,.95)
 arrow=frame:CreateTexture(nil,"ARTWORK")
 arrow:SetSize(48,48)
 arrow:SetPoint("TOP",0,-3)
 arrow:SetTexture("Interface\\AddOns\\ForeverCompanion\\Media\\QuestDirectionArrow")
 title=frame:CreateFontString(nil,"OVERLAY","GameFontNormal")
 title:SetWidth(183)
 title:SetHeight(17);title:SetWordWrap(false)
 ForeverCompanionVisualTheme.Font(title,12)
 title:SetTextColor(.93,.98,1)
 title:SetPoint("BOTTOM",0,28)
 status=frame:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
 status:SetPoint("BOTTOM",0,13)
 status:SetTextColor(.68,.77,.84)
 status:SetWidth(221);status:SetHeight(15);status:SetWordWrap(false)
 ForeverCompanionVisualTheme.Font(status,10)
 local close=ForeverCompanionInterface.Button(frame)
 close:SetText("x")
 close:SetSize(20,20)
 close:SetPoint("BOTTOMRIGHT",-3,24)
 frame.close=close
 close:SetScript("OnClick",function()
  if ForeverCompanionQuestWaypoints and ForeverCompanionQuestWaypoints.Clear then
   ForeverCompanionQuestWaypoints.Clear()
  else
   D.Stop()
  end
  if ForeverCompanionRefresh then ForeverCompanionRefresh() end
 end)
 local nextObjective=ForeverCompanionInterface.Button(frame);nextObjective:SetSize(154,22);nextObjective:SetPoint('TOP',0,-54);nextObjective:SetText('Another objective >')
 nextObjective:SetScript('OnClick',function()
  local result=ForeverCompanionObjectiveRoute.NavigateNext(nil,currentPoint)
  if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage(result) end
 end)
 frame.nextObjective=nextObjective
 confidence=frame:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall');ForeverCompanionVisualTheme.Font(confidence,9);confidence:SetTextColor(.7,.82,.88);confidence:SetHeight(14);confidence:SetWordWrap(false)
 D.ApplyLayout()
 frame:SetScript("OnUpdate",update)
 frame:Hide()
end

function D.Start(point,label)
 if type(point)~="table" or not finite(point.x) or not finite(point.y)
  or point.x<0 or point.x>1 or point.y<0 or point.y>1
  or not finite(point.map) or point.map<=0 or point.map%1~=0 then return false end
 if not C_Map or not C_Map.GetWorldPosFromMapPos or not C_Map.GetPlayerMapPosition
  or not C_Map.GetBestMapForUnit or not CreateVector2D or not GetPlayerFacing or not atan2 then return false end
 local ok,continent,north,west=pcall(function()
  return worldPosition(point.map,CreateVector2D(point.x,point.y))
 end)
 if not ok or not continent then return false end
 local destination={continent=continent,north=north,west=west}
 local readable,angle=pcall(bearing,destination)
 if not readable or not angle then return false end
 if not frame then create() end
 if not arrow.SetRotation then return false end
 currentPoint={map=point.map,x=point.x,y=point.y};arrivalDistance=nil;near=false
 target=destination
 title:SetText(label or point.label or "Quest destination")
 local source=point.source=='Personal map note' and 'Personal saved position' or (point.observed and 'Visited nearby position' or (point.service and 'Service reference · confirm availability' or (point.objectiveIndex and 'Objective reference · exactness unverified' or 'Reported point · precision unverified')))
 confidence:SetText(source)
 elapsed=.10
 update(frame,0)
 frame:Show()
 return true
end

function D.ApplyLayout()
 if not frame then return end
 local compact=settings().compact==true
 frame:SetSize(compact and 420 or 245,compact and 76 or 146);frame.bg:SetHeight(compact and 76 or 68)
 title:ClearAllPoints();status:ClearAllPoints();confidence:ClearAllPoints()
 frame.options:ClearAllPoints();frame.close:ClearAllPoints();frame.nextObjective:ClearAllPoints();frame.dragHandle:ClearAllPoints()
 if compact then
  title:SetPoint('TOPLEFT',10,-7);title:SetWidth(330);status:SetPoint('TOPLEFT',10,-28);status:SetWidth(360)
  confidence:SetPoint('TOPLEFT',10,-49);confidence:SetWidth(245)
  frame.options:SetPoint('TOPRIGHT',-30,-5);frame.close:SetPoint('TOPRIGHT',-4,-5)
  frame.nextObjective:SetPoint('BOTTOMRIGHT',-8,5);frame.dragHandle:SetPoint('TOPLEFT',0,0);frame.dragHandle:SetSize(360,25)
  arrow:Hide()
 else
  title:SetPoint('BOTTOM',0,46);title:SetWidth(183);status:SetPoint('BOTTOM',0,31);status:SetWidth(221)
  confidence:SetPoint('BOTTOM',0,14);confidence:SetWidth(221)
  frame.options:SetPoint('BOTTOMLEFT',3,44);frame.close:SetPoint('BOTTOMRIGHT',-3,44)
  frame.nextObjective:SetPoint('TOP',0,-54);frame.dragHandle:SetPoint('BOTTOMLEFT',0,44);frame.dragHandle:SetSize(219,24)
 end
 elapsed=.1;if target then update(frame,0) end
end
function D.Arrival() return near==true,arrivalDistance end
function D.Current() return currentPoint and {map=currentPoint.map,x=currentPoint.x,y=currentPoint.y} end
function D.IsActive() return target~=nil end
function D.ApplyScale()
 if frame then local size=settings().scale;frame:SetScale((size==.85 or size==1.2) and size or 1) end
end
function D.ResetPosition()
 settings().position=nil
 if frame then frame:ClearAllPoints();frame:SetPoint('TOP',UIParent,'TOP',0,-115) end
end
function D.OpenOptions(anchor)
 local cfg=settings();local entries={}
 entries[#entries+1]={label=cfg.locked and 'Unlock arrow position' or 'Lock arrow position',selected=cfg.locked==true,action=function() cfg.locked=not cfg.locked end}
 for _,preset in ipairs({{'Small',.85},{'Standard',1},{'Large',1.2}}) do
  local label,size=preset[1],preset[2]
  entries[#entries+1]={label=label..' arrow',selected=(cfg.scale or 1)==size,action=function() cfg.scale=size;D.ApplyScale() end}
 end
 entries[#entries+1]={label=cfg.compact and 'Use arrow display' or 'Use compact travel strip',action=function() cfg.compact=not cfg.compact;D.ApplyLayout() end}
 entries[#entries+1]={label='Recent destinations',action=function() ForeverCompanionMapHub.Open('',true) end}
 entries[#entries+1]={label='Reset arrow position',action=D.ResetPosition}
 ForeverCompanionInterface.Menu(anchor or frame,'NAVIGATION ARROW',entries)
end

function D.Stop()
 if not target then return false end
 target=nil;currentPoint=nil;arrivalDistance=nil;near=false
 if frame then frame:Hide() end
 return true
end
