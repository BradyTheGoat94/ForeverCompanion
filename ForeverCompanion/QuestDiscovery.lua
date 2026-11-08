-- Browse real quest-giver locations without changing map marker preferences.
local D={page=1}
ForeverCompanionQuestDiscovery=D
local root,search,summary,empty,counter,back,forward,rows,modeButton
local nativeOnly=false
local function read(fn,...)
 if type(fn)~='function' then return end
 local ok,a=pcall(fn,...);if ok then return a end
end
function D.Filter(entries,query,native)
 local grouped,result={},{}
 query=string.lower(query or '')
 for _,entry in ipairs(entries or {}) do
  local q,t=entry.quest,entry.target
  if q and t and (not native or not entry.reference) and (string.find(string.lower(q.title or ''),query,1,true) or string.find(string.lower(t.label or ''),query,1,true)) then
   local item=grouped[q.id]
   if not item then item={quest=q,targets={},reference=entry.reference};grouped[q.id]=item;result[#result+1]=item end
   item.targets[#item.targets+1]=t
   if not entry.reference then item.reference=false end
  end
 end
 table.sort(result,function(a,b)
  if a.reference~=b.reference then return not a.reference end
  local x,y=string.lower(a.quest.title),string.lower(b.quest.title)
  if x~=y then return x<y end
  return a.quest.id<b.quest.id
 end)
 return result
end
local function text(parent,x,y,width,value,size)
 local f=ForeverCompanionInterface.Text(parent,size or 12)
 f:SetPoint('TOPLEFT',parent,'TOPLEFT',x,y);f:SetWidth(width);f:SetText(value or '');return f
end
function D.Create(parent)
 local U=ForeverCompanionInterface
 root=CreateFrame('Frame',nil,parent);root:SetSize(770,360);U.Surface(root);root:Hide()
 text(root,16,-13,730,'DISCOVER QUESTS',16)
 text(root,16,-39,730,'Unaccepted quests in your current zone · select a giver, then navigate.',12)
 search=U.EditBox(root,'Search quest or quest giver');search:SetPoint('TOPLEFT',16,-66);search:SetSize(470,27)
 search:SetScript('OnTextChanged',function() D.page=1;D.Refresh() end)
 search:SetScript('OnEscapePressed',function(self) self:ClearFocus() end)
 modeButton=U.Button(root);modeButton:SetPoint('TOPLEFT',500,-66);modeButton:SetSize(254,27)
 modeButton:SetScript('OnClick',function() nativeOnly=not nativeOnly;D.page=1;D.Refresh() end)
 summary=text(root,16,-103,738,'',11)
 rows={}
 for i=1,4 do
  local row=CreateFrame('Frame',nil,root);row:SetSize(738,43);row:SetPoint('TOPLEFT',16,-125-(i-1)*47);U.Surface(row)
  row.title=text(row,9,-4,475,'',13);row.detail=text(row,9,-24,475,'',11)
  row.cycle=U.Button(row);row.cycle:SetSize(108,29);row.cycle:SetPoint('TOPRIGHT',-119,-7)
  row.cycle:SetScript('OnClick',function() row.choice=row.choice%#row.item.targets+1;D.Paint(row) end)
  row.go=U.Button(row);row.go:SetSize(103,29);row.go:SetPoint('TOPRIGHT',-7,-7);row.go:SetText('Navigate')
  row.go:SetScript('OnClick',function() local t=row.item and row.item.targets[row.choice];if t then ForeverCompanionQuestWaypoints.Navigate(t,true,row.item.quest.title) end end)
  rows[i]=row
 end
 empty=text(root,28,-150,714,'',13);empty:SetHeight(120);empty:SetWordWrap(true);empty:SetJustifyH('CENTER')
 back=U.Button(root);back:SetPoint('BOTTOMLEFT',16,14);back:SetSize(100,26);back:SetText('Previous')
 forward=U.Button(root);forward:SetPoint('BOTTOMRIGHT',-16,14);forward:SetSize(100,26);forward:SetText('Next')
 counter=text(root,133,-323,500,'',11);counter:SetJustifyH('CENTER')
 back:SetScript('OnClick',function() D.page=math.max(1,D.page-1);D.Refresh() end)
 forward:SetScript('OnClick',function() D.page=D.page+1;D.Refresh() end)
 local events=CreateFrame('Frame',nil,root)
 for _,event in ipairs({'QUEST_LOG_UPDATE','PLAYER_LEVEL_UP','ZONE_CHANGED_NEW_AREA'}) do events:RegisterEvent(event) end
 events:SetScript('OnEvent',function() D.Refresh() end)
end
function D.Paint(row)
 local item=row.item;local t=item.targets[row.choice]
 row.title:SetText((type(item.quest.level)=='number' and item.quest.level>0 and ('['..item.quest.level..'] ') or '')..item.quest.title)
 row.detail:SetText((item.reference and 'Database reference · ' or 'Client reported · ')..(t.label or 'Quest giver')..(' · %.1f, %.1f'):format(t.x*100,t.y*100))
 row.cycle:SetText('Giver '..row.choice..' / '..#item.targets);row.cycle:SetEnabled(#item.targets>1)
end
function D.Refresh()
 if not root or not root:IsShown() then return end
 local map=C_Map and read(C_Map.GetBestMapForUnit,'player')
 local info=map and read(C_Map.GetMapInfo,map)
 local entries=map and ForeverCompanionQuestWaypoints.MapPickups(map,ForeverCompanionQuestPlanner.GetLive(),true) or {}
 local found=D.Filter(entries,search:GetText(),nativeOnly)
 local pages=math.max(1,math.ceil(#found/4));D.page=math.max(1,math.min(D.page,pages))
 modeButton:SetText(nativeOnly and 'Source: client reported' or 'Source: client + database')
 summary:SetText((info and info.name or 'Current zone unavailable')..' · '..#found..' quests · Database references may have additional requirements.')
 for i,row in ipairs(rows) do
  local item=found[(D.page-1)*4+i]
  local previous=row.item
  row.item=item;row:SetShown(item~=nil)
  if item then row.choice=previous and previous.quest.id==item.quest.id and math.min(row.choice or 1,#item.targets) or 1;D.Paint(row) end
 end
 empty:SetShown(#found==0)
 empty:SetText((search:GetText()~='' and 'No quests match this search. Try a quest giver name or clear the search.' or 'No unaccepted quests reported here. Try another zone or speak to nearby quest givers.')..'\n\n'..(ForeverCompanionQuestWaypoints.PickupStatus or 'Native quest markers depend on information available to your client.'))
 counter:SetText('Page '..D.page..' / '..pages);back:SetEnabled(D.page>1);forward:SetEnabled(D.page<pages)
end
function D.Show(show,parent,offset)
 if not root then return end
 root:SetShown(show)
 if show then root:ClearAllPoints();root:SetPoint('TOPLEFT',parent,'TOPLEFT',8,-offset);D.Refresh() end
end
function D.GetHeight() return 374 end
