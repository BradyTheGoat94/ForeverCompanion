-- Displays the active Hunter pet's experience from the game client.
local Tracker={}
ForeverCompanionPetXPTracker=Tracker

local H=ForeverCompanionHunterGuide
local width,height=290,77
local windowName='ForeverCompanionPetXPFrame'
local frame,title,details,bar,track

local function isHunter()
 local _,class=H.Read(UnitClass,'player')
 return class=='HUNTER'
end

local function create()
 local U=ForeverCompanionInterface
 frame=CreateFrame('Frame',windowName,UIParent,'BackdropTemplate')
 frame:SetSize(width,height)
 frame:SetPoint('TOP',UIParent,'TOP',0,-245)
 frame:SetFrameStrata('MEDIUM')
 U.Surface(frame)
 local close=U.CloseButton(frame,function()
  ForeverCompanionDB.petXPHidden=true
  frame:Hide()
 end)
 close:SetSize(20,20)
 title=U.Text(frame,13,U.palette.accent)
 title:SetPoint('TOPLEFT',12,-8)
 title:SetWidth(width-54)
 details=U.Text(frame,12)
 details:SetPoint('TOPLEFT',12,-32)
 details:SetWidth(width-24)
 track=frame:CreateTexture(nil,'ARTWORK')
 track:SetPoint('BOTTOMLEFT',12,11)
 track:SetSize(width-24,7)
 track:SetColorTexture(.13,.22,.23,1)
 bar=CreateFrame('StatusBar',nil,frame)
 bar:SetPoint('BOTTOMLEFT',12,11)
 bar:SetSize(width-24,7)
 bar:SetStatusBarTexture('Interface\\Buttons\\WHITE8X8')
 bar:SetStatusBarColor(.47,.78,.49)
end

function Tracker.Refresh()
 if not isHunter() or (ForeverCompanionDB and ForeverCompanionDB.petXPHidden) or H.Read(UnitExists,'pet')~=true then
  if frame then frame:Hide() end
  return
 end
 if not frame then create() end
 local name,level=H.Read(UnitName,'pet'),H.Read(UnitLevel,'pet')
 if type(name)~='string' or name=='' then name='Hunter pet' end
 title:SetText(H.Finite(level) and level>0 and ('Lv. %d  |  %s'):format(level,name) or name)
 local current,required=H.Read(GetPetExperience)
 local known=H.Finite(current) and H.Finite(required) and current>=0 and required>0 and current<=required
 bar:SetShown(known)
 track:SetShown(known)
 if known then
  bar:SetMinMaxValues(0,required)
  bar:SetValue(current)
  local formatNumber=BreakUpLargeNumbers or tostring
  details:SetText(('%s / %s XP  |  %.1f%%'):format(formatNumber(current),formatNumber(required),100*current/required))
 elseif H.Finite(level) and level>=60 then
  details:SetText('Pet at max level')
 else
  details:SetText('Pet XP unavailable')
 end
 frame:Show()
end

function Tracker.Toggle()
 if not isHunter() then return 'Pet XP tracking is available for Hunters.' end
 ForeverCompanionDB=ForeverCompanionDB or {}
 local db=ForeverCompanionDB
 db.petXPHidden=not db.petXPHidden
 Tracker.Refresh()
 if db.petXPHidden then return 'Pet XP tracker hidden. Use /fc petxp to show it.' end
 return 'Pet XP tracker enabled. Summon your pet to see it, then drag the title to move it.'
end

local events=CreateFrame('Frame')
for _,event in ipairs({'PLAYER_ENTERING_WORLD','UNIT_PET','UNIT_PET_EXPERIENCE','UNIT_LEVEL'}) do
 events:RegisterEvent(event)
end
events:SetScript('OnEvent',function(_,event,unit)
 if event=='PLAYER_ENTERING_WORLD' or unit=='player' or unit=='pet' or not unit then
  Tracker.Refresh()
 end
end)
