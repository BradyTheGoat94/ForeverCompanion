-- Current-zone guidance built from the same targets used by the quest map.
local B={}
ForeverCompanionZoneBriefing=B
local panel,heading,questText,reasonText,servicesText,start
local zone,choice,reader
local function finite(value)
 return not (issecretvalue and issecretvalue(value)) and type(value)=='number' and math.abs(value)<math.huge
end
local function valid(target,map)
 return type(target)=='table' and target.map==map and finite(target.x) and finite(target.y)
  and target.x>=0 and target.x<=1 and target.y>=0 and target.y<=1
end
function B.Tier(mapType,types,zoom,automatic)
 if not automatic or not types or not finite(mapType) then return 'detail' end
 if mapType==types.World or mapType==types.Continent then return 'overview' end
 if finite(zoom) and zoom<.32 then return 'zone' end
 return 'detail'
end
function B.Choose(map,active,pickups,x,y)
 local best,rank,distance
 local function consider(entry,priority)
  if not entry.quest or not valid(entry.target,map) then return end
  local p=entry.target
  local d=finite(x) and finite(y) and (p.x-x)^2+(p.y-y)^2 or math.huge
  if not best or priority>rank or (priority==rank and d<distance) then best,rank,distance=entry,priority,d end
 end
 for _,entry in ipairs(active) do consider(entry,entry.quest.complete and 4 or 3) end
 for _,entry in ipairs(pickups) do consider(entry,entry.zoneStart and 2 or 1) end
 return best
end
function B.Reason(entry)
 if not entry.pickup then
  return entry.quest.complete and 'Ready to turn in' or 'Active quest objective'
 end
 if entry.reference then
  return entry.zoneStart and 'Suggested zone start. Confirm availability with the giver.' or 'Reference pickup. Confirm availability with the giver.'
 end
 return entry.zoneStart and 'Zone starter reported by the client' or 'Quest pickup reported by the client'
end
local function create(owner)
 local U=ForeverCompanionInterface
 panel=CreateFrame('Frame',nil,owner)
 panel:SetSize(450,151)
 panel:SetPoint('BOTTOMLEFT',owner,'TOPLEFT',0,6)
 panel:SetFrameLevel(owner:GetFrameLevel()+1)
 U.Surface(panel)
 local function text(y,size,color)
  local line=U.Text(panel,size,color)
  line:SetPoint('TOPLEFT',12,-y)
  line:SetWidth(426)
  return line
 end
 heading=text(9,13,U.palette.accent)
 questText=text(32,15,U.palette.text)
 reasonText=text(55,11,U.palette.muted)
 reasonText:SetWordWrap(true)
 reasonText:SetHeight(28)
 servicesText=text(87,11,U.palette.muted)
 servicesText:SetWordWrap(true)
 servicesText:SetHeight(28)
 start=U.Button(panel)
 start:SetSize(116,24)
 start:SetPoint('BOTTOMLEFT',12,9)
 start:SetText('Start route')
 start:SetScript('OnClick',function()
  local current=reader and reader(zone)
  local way=ForeverCompanionQuestWaypoints
  if not current or not choice or current.quest.id~=choice.quest.id
   or not not current.pickup~=not not choice.pickup
   or not not current.quest.complete~=not not choice.quest.complete
   or not way.SameTarget(current.target,choice.target) then
   reasonText:SetText('The recommendation changed. Refresh the map to choose the new stop.')
   return
  end
  local questID=not current.pickup and current.quest.id or nil
  local message=way.Navigate(current.target,false,current.quest.title,questID)
  reasonText:SetText(message or 'Route started.')
 end)
end
function B.Show(owner,displayMap,title,entry,services,lookup)
 if not panel then create(owner) end
 zone,choice,reader=displayMap,entry,lookup
 heading:SetText(title)
 questText:SetText(entry and entry.quest.title or 'No reported quest destination')
 local giver=entry and type(entry.target.label)=='string' and entry.target.label
 reasonText:SetText(entry and (B.Reason(entry)..(giver and ('  |  '..giver) or '')) or 'Pick another zone or accept a quest to see its next stop.')
 servicesText:SetText(services or '')
 start:SetEnabled(entry~=nil)
 panel:Show()
end
function B.Hide()
 if panel then panel:Hide() end
 zone,choice,reader=nil,nil,nil
end
