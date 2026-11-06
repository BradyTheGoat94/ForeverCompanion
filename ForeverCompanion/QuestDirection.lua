-- Display a straight-line bearing to a destination chosen by the player.
local D={}
ForeverCompanionQuestDirection=D
local frame,arrow,title,status,target,elapsed,progressFill
local atan2=math.atan2

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
 if continent~=destination.continent then return end
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
  arrow:Hide()
  status:SetText("Direction unavailable here")
  if progressFill then progressFill:SetWidth(0.01) end
 elseif distance<=12 then
  arrow:Hide()
  status:SetText("Near your destination")
  if progressFill then progressFill:SetWidth(221) end
 else
  arrow:SetRotation(angle)
  arrow:Show()
  status:SetText(("%d yd  ·  Straight-line direction"):format(math.floor(distance+.5)))
  -- Decorative proximity cue, not quest completion or route progress.
  if progressFill then progressFill:SetWidth(221*math.max(0,math.min(1,1-distance/500))) end
 end
end

local function create()
 frame=CreateFrame("Frame",nil,UIParent)
 frame:SetSize(245,98)
 frame:SetPoint("TOP",UIParent,"TOP",0,-115)
 frame:SetFrameStrata("HIGH")
 frame:EnableMouse(false)
 local bg=frame:CreateTexture(nil,"BACKGROUND")
 bg:SetPoint("BOTTOMLEFT",0,0)
 bg:SetPoint("BOTTOMRIGHT",0,0)
 bg:SetHeight(48)
 bg:SetColorTexture(.015,.035,.055,.95)
 local top=frame:CreateTexture(nil,"BORDER")
 top:SetColorTexture(.18,.79,.92,.95)
 top:SetPoint("BOTTOMLEFT",bg,"TOPLEFT",0,0)
 top:SetPoint("BOTTOMRIGHT",bg,"TOPRIGHT",0,0)
 top:SetHeight(2)
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
 arrow:SetSize(68,68)
 arrow:SetPoint("TOP",0,10)
 arrow:SetTexture("Interface\\AddOns\\ForeverCompanion\\Media\\QuestDirectionArrow")
 title=frame:CreateFontString(nil,"OVERLAY","GameFontNormal")
 title:SetWidth(207)
 title:SetTextColor(.93,.98,1)
 title:SetPoint("BOTTOM",0,28)
 status=frame:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
 status:SetPoint("BOTTOM",0,13)
 status:SetTextColor(.55,.86,.94)
 local close=CreateFrame("Button",nil,frame,"UIPanelCloseButton")
 close:SetSize(23,23)
 close:SetPoint("BOTTOMRIGHT",0,23)
 close:SetScript("OnClick",function()
  if ForeverCompanionQuestWaypoints and ForeverCompanionQuestWaypoints.Clear then
   ForeverCompanionQuestWaypoints.Clear()
  else
   D.Stop()
  end
  if ForeverCompanionRefresh then ForeverCompanionRefresh() end
 end)
 frame:SetScript("OnUpdate",update)
 frame:Hide()
end

function D.Start(point,label)
 if type(point)~="table" or not finite(point.x) or not finite(point.y)
  or point.x<0 or point.x>1 or point.y<0 or point.y>1
  or not finite(point.map) then return false end
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
 target=destination
 title:SetText(label or point.label or "Quest destination")
 elapsed=.10
 update(frame,0)
 frame:Show()
 return true
end

function D.IsActive() return target~=nil end

function D.Stop()
 if not target then return false end
 target=nil
 if frame then frame:Hide() end
 return true
end
