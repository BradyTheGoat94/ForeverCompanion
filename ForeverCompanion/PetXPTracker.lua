-- Displays the active Hunter pet's experience from the game client.
local Tracker={}
ForeverCompanionPetXPTracker=Tracker

local H=ForeverCompanionHunterGuide
local width,height=290,110
local windowName='ForeverCompanionPetXPFrame'
local frame,title,details,killEstimate,killCount,bar,track
local progress,kills
local sampleLimit=10
local killEventRegistered

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
 killEstimate=U.Text(frame,12)
 killEstimate:SetPoint('TOPLEFT',12,-52)
 killEstimate:SetWidth(width-24)
 killCount=U.Text(frame,12)
 killCount:SetPoint('TOPLEFT',12,-70)
 killCount:SetWidth(width-24)
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

local function record(guid,level,current,required)
 if type(guid)~='string' or guid=='' or not H.Finite(level) or level<=0 then
  progress=nil
  return
 end
 if not progress or progress.guid~=guid or progress.level~=level or progress.required~=required or current<progress.xp then
  progress={guid=guid,level=level,required=required,xp=current,samples={},total=0}
  return
 end
 local gained=current-progress.xp
 if gained<=0 then return end
 progress.xp=current
 local samples=progress.samples
 if #samples==sampleLimit then progress.total=progress.total-table.remove(samples,1) end
 samples[#samples+1]=gained
 progress.total=progress.total+gained
end

local function killRecord(guid,level)
 if type(guid)~='string' or guid=='' or not H.Finite(level) or level<=0 then return end
 if not kills or kills.guid~=guid or kills.level~=level then
  kills={guid=guid,level=level,count=0}
 end
 return kills
end

function Tracker.Refresh()
 if not isHunter() or H.Read(UnitExists,'pet')~=true then
  progress=nil
  if frame then frame:Hide() end
  return
 end
 local name,level=H.Read(UnitName,'pet'),H.Read(UnitLevel,'pet')
 local current,required=H.Read(GetPetExperience)
 local known=H.Finite(current) and H.Finite(required) and current>=0 and required>0 and current<=required
 local guid=H.Read(UnitGUID,'pet')
 if known then record(guid,level,current,required) else progress=nil end
 local confirmed=killRecord(guid,level)
 if ForeverCompanionDB and ForeverCompanionDB.petXPHidden then
  if frame then frame:Hide() end
  return
 end
 if not frame then create() end
 if type(name)~='string' or name=='' then name='Hunter pet' end
 title:SetText(H.Finite(level) and level>0 and ('Lv. %d  |  %s'):format(level,name) or name)
 killCount:SetText(killEventRegistered and confirmed and ('Confirmed kills this level: %d'):format(confirmed.count) or 'Kill count unavailable')
 killEstimate:SetShown(known)
 if known and progress and progress.total>0 then
  local remaining=math.ceil((required-current)*#progress.samples/progress.total)
  killEstimate:SetText(('~%d %s to level'):format(remaining,remaining==1 and 'kill' or 'kills'))
 else
  killEstimate:SetText('Kills to level: waiting for pet XP')
 end
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
killEventRegistered=pcall(events.RegisterEvent,events,'PARTY_KILL')
events:SetScript('OnEvent',function(_,event,unit,victim)
 if event=='PARTY_KILL' then
  if (issecretvalue and (issecretvalue(unit) or issecretvalue(victim))) or type(unit)~='string' or type(victim)~='string' then return end
  if not victim:match('^Creature%-') and not victim:match('^Vehicle%-') then return end
  if not isHunter() or H.Read(UnitExists,'pet')~=true then return end
  local pet=H.Read(UnitGUID,'pet')
  if unit~=pet and unit~=H.Read(UnitGUID,'player') then return end
  local confirmed=killRecord(pet,H.Read(UnitLevel,'pet'))
  if confirmed then
   confirmed.count=confirmed.count+1
   Tracker.Refresh()
  end
  return
 end
 if event=='PLAYER_ENTERING_WORLD' or unit=='player' or unit=='pet' or not unit then
  Tracker.Refresh()
 end
end)
