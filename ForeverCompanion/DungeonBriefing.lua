-- Entrance briefing anchored to the Companion dock on Blizzard's world map.
local B={}
ForeverCompanionDungeonBriefing=B
local panel,title,details,status,previous,nextWing,route,quests,loot
local current,dismiss

local function selectedName()
 return current.location.names[current.index]
end

local function render()
 local p=current.location
 local name=selectedName()
 local range=ForeverCompanionDungeonCatalog.LevelRange(name)
 title:SetText(ForeverCompanionDungeonCatalog.DisplayName(name))
 details:SetText(('%s  |  %.1f, %.1f%s'):format(p.zone,p.x*100,p.y*100,range and ('  |  Levels '..range) or ''))
 local note=p.approximate and 'Dungeon area reference. Entrance coordinates are unconfirmed.' or 'Outdoor approach reference.'
 if #p.names>1 then note=('Shared approach (%d of %d).'):format(current.index,#p.names) end
 status:SetText(note)
 route:SetEnabled(not p.approximate)
 previous:SetShown(#p.names>1)
 nextWing:SetShown(#p.names>1)
 previous:SetEnabled(current.index>1)
 nextWing:SetEnabled(current.index<#p.names)
end

local function turn(step)
 if not current then return end
 current.index=math.max(1,math.min(#current.location.names,current.index+step))
 render()
end
local function openJournal(showQuests)
 if not current or not ForeverCompanionOpenDungeonJournal then return end
 local name=ForeverCompanionDungeonCatalog.JournalName(selectedName())
 if HideUIPanel and WorldMapFrame and (not InCombatLockdown or not InCombatLockdown()) then
  HideUIPanel(WorldMapFrame)
 end
 ForeverCompanionOpenDungeonJournal(name,showQuests)
end
local function create(owner)
 local U=ForeverCompanionInterface
 panel=CreateFrame('Frame',nil,owner)
 panel:SetSize(450,124)
 panel:SetPoint('BOTTOMLEFT',owner,'TOPLEFT',0,6)
 panel:SetFrameLevel(owner:GetFrameLevel()+1)
 panel:SetClampedToScreen(true)
 U.Surface(panel)
 panel:EnableMouse(true)
 local function text(y,size,color,width)
  local line=U.Text(panel,size,color)
  line:SetPoint('TOPLEFT',12,-y)
  line:SetWidth(width)
  return line
 end
 local function button(x,y,width,label,action)
  local control=U.Button(panel)
  control:SetSize(width,24)
  control:SetPoint('TOPLEFT',x,-y)
  control:SetText(label)
  control:SetScript('OnClick',action)
  return control
 end
 text(9,11,U.palette.accent,315):SetText('DUNGEON BRIEFING')
 title=text(29,15,U.palette.text,404)
 details=text(51,11,U.palette.text,426)
 status=text(70,11,U.palette.muted,426)
 U.CloseButton(panel,function() if dismiss then dismiss() end end)
 previous=button(334,8,32,'<',function() turn(-1) end)
 nextWing=button(372,8,32,'>',function() turn(1) end)
 U.SetHoverHelp(previous,'Previous wing','View the previous dungeon that shares this approach.')
 U.SetHoverHelp(nextWing,'Next wing','View the next dungeon that shares this approach.')
 route=button(12,91,132,'Route to approach',function()
  if not current or current.location.approximate then return end
  status:SetText(ForeverCompanionQuestWaypoints.Navigate(current.location,false,ForeverCompanionDungeonCatalog.DisplayName(selectedName())..' approach'))
 end)
 quests=button(154,91,132,'Dungeon quests',function() openJournal(true) end)
 loot=button(296,91,142,'Bosses & loot',function() openJournal(false) end)
end

function B.Show(owner,selection,onDismiss)
 if not panel then create(owner) end
 current,dismiss=selection,onDismiss
 local available=type(ForeverCompanionOpenDungeonJournal)=='function'
 quests:SetEnabled(available)
 loot:SetEnabled(available)
 render()
 panel:Show()
end
function B.Hide()
 if panel then panel:Hide() end
 current,dismiss=nil,nil
end
