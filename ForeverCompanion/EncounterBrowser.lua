-- Dungeon, boss and item navigation for the sourced catalog.
local E={dungeon="",boss="",query="",page=1,pageSize=6,dungeonPage=1,dropPage=1}
ForeverCompanionEncounterBrowser=E
local root,subtitle,rows,dungeons,lootRows,bossTitle,pageLabel,previous,nextPage,openLoot
local dungeonBack,dungeonNext,dropBack,dropNext
local theme=ForeverCompanionVisualTheme
local chrome=ForeverCompanionDungeonChrome
local journalTitle,lootTab,questViewButton,lootPanels
function E.BossNames(dungeon)
 local names,seen={},{}
 for _,name in ipairs(ForeverCompanionLoot.BossNames(dungeon)) do names[#names+1]=name;seen[name]=true end
 if ForeverCompanionBossMechanics then for _,name in ipairs(ForeverCompanionBossMechanics.Names(dungeon)) do
  if not seen[name] then names[#names+1]=name;seen[name]=true end
 end end
 table.sort(names);return names
end
function E.Results(dungeon,query,directoryMatches)
 local result={}
 if type(dungeon)~="string" or dungeon=="" then return result end
 local term=type(query)=="string" and query:lower():gsub("^%s+",""):gsub("%s+$","") or ""
 local originalTerm=term
 if ForeverCompanionBossMechanics and ForeverCompanionBossMechanics.Canonical then term=ForeverCompanionBossMechanics.Canonical(dungeon,term):lower() end
 local directoryMatch=false
 if directoryMatches and term==originalTerm then directoryMatch=not not directoryMatches[dungeon]
 elseif term~='' and ForeverCompanionDungeonCatalog then for _,name in ipairs(ForeverCompanionDungeonCatalog.JournalDirectory(term)) do if name==dungeon then directoryMatch=true;break end end end
 for _,name in ipairs(E.BossNames(dungeon)) do
  local drops=ForeverCompanionLoot.BossDrops(dungeon,name)
  local matches=term=="" or directoryMatch or name:lower():find(term,1,true) or dungeon:lower():find(term,1,true)
  if not matches then for _,drop in ipairs(drops) do if drop.item:lower():find(term,1,true) then matches=true;break end end end
  if matches then result[#result+1]={boss=name,count=#drops} end
 end
 return result
end
function E.SelectDungeon(name,keepSearch)
 name=ForeverCompanionDungeonCatalog and ForeverCompanionDungeonCatalog.JournalName(name) or name
 E.dungeon=name
 E.boss=name~="" and (ForeverCompanionLoot.BossNames(name)[1] or E.BossNames(name)[1]) or ""
 E.page=1;E.dropPage=1
 if not keepSearch then
  E.query=""
  if ForeverCompanionDungeonCatalog then for i,n in ipairs(ForeverCompanionDungeonCatalog.JournalDirectory()) do if n==name then E.dungeonPage=math.floor((i-1)/9)+1;break end end end
  if E.searchBox then E.searchBox:SetText("") end
 end
end
function E.Focus(dungeon,boss)
 E.questView=false
 E.SelectDungeon(dungeon)
 dungeon=E.dungeon
 if ForeverCompanionBossMechanics and ForeverCompanionBossMechanics.Canonical then boss=ForeverCompanionBossMechanics.Canonical(dungeon,boss) end
 E.boss=boss
 for i,entry in ipairs(E.Results(dungeon,"")) do
  if entry.boss==boss then E.page=math.floor((i-1)/E.pageSize)+1;break end
 end
 for i,name in ipairs((ForeverCompanionDungeonCatalog and ForeverCompanionDungeonCatalog.JournalDirectory() or ForeverCompanionLoot.DungeonNames())) do
  if name==dungeon then E.dungeonPage=math.floor((i-1)/9)+1;break end
 end
end
local function label(parent,x,y,w,text,size,gold)
 local t=parent:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
 t:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y);t:SetWidth(w);t:SetJustifyH("LEFT")
 t:SetText(text or "");theme.Font(t,size or 11)
 if gold then t:SetTextColor(.97,.80,.48) end
 return t
end
local function button(parent,x,y,w,text,action)
 local b=ForeverCompanionInterface.Button(parent)
 b:SetSize(w,23);b:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
 b:SetText(text);b:SetScript("OnClick",action)
 return b
end
local function entry(parent,y,w,h,action)
 local b=CreateFrame("Button",nil,parent)
 b:SetSize(w,h);b:SetPoint("TOPLEFT",parent,"TOPLEFT",8,y)
 b.bg=chrome.Row(b,w,h)
 b.name=label(b,8,-6,w-16,"",11)
 b.name:SetWordWrap(false);b.name:SetHeight(17)
 b:SetScript("OnClick",action)
 return b
end
local function tint(row,selected)
 chrome.Select(row,row.bg,selected)
end
local function column(x,w,name)
 local p=CreateFrame("Frame",nil,root,'BackdropTemplate')
 p:SetSize(w,302);p:SetPoint("TOPLEFT",root,"TOPLEFT",x,-72)
 chrome.Skin(p,w,302,30)
 label(p,10,-10,w-20,name,13,true)
 return p
end
function E.Create(parent,navigate,onPrep)
 root=CreateFrame("Frame","ForeverCompanionDungeonJournal",parent,'BackdropTemplate')
 root:SetSize(770,402);root:SetPoint("TOPLEFT",parent,"TOPLEFT",8,-5)
 chrome.Skin(root,770,402,61,true)
 chrome.Seal(root,15,-9,30)
 journalTitle=label(root,54,-13,294,"Dungeon Journal",16,true)
 journalTitle:SetWordWrap(false)
 subtitle=label(root,16,-44,394)
 button(root,614,-10,140,"Prep & notes",onPrep)
 ForeverCompanionInterface.HoverNote(root,422,-38,'Dungeon Journal','Select a dungeon, then a boss to view its loot and encounter guide. Dungeon quests opens the quest list for the selected dungeon.')
 lootTab=button(root,350,-10,124,'Bosses & loot',function() E.questView=false;ForeverCompanionRefresh() end)
 questViewButton=button(root,480,-10,124,'Dungeon quests',function()
  E.questView=true
  if E.questView then ForeverCompanionDungeonQuests.StartScan() end
  ForeverCompanionRefresh()
 end)
 label(root,456,-46,60,"Search")
 E.searchBox=ForeverCompanionInterface.EditBox(root,"Search dungeons, bosses, drops…")
 E.searchBox:SetSize(176,22);E.searchBox:SetPoint("TOPLEFT",root,"TOPLEFT",505,-39)
 if E.searchBox.SetAutoFocus then E.searchBox:SetAutoFocus(false) end
 if E.searchBox.SetMaxLetters then E.searchBox:SetMaxLetters(120) end
 E.searchBox:SetScript("OnTextChanged",function(self,userInput)
  if userInput then E.query=self:GetText():sub(1,120);E.page=1;E.dungeonPage=1;ForeverCompanionRefresh() end
 end)
 E.searchBox:SetScript("OnEscapePressed",function(self) if self.ClearFocus then self:ClearFocus() end end)
 E.searchBox:SetScript("OnEnterPressed",function(self) if self.ClearFocus then self:ClearFocus() end end)
 button(root,690,-39,64,"Clear",function() E.query="";E.page=1;E.searchBox:SetText("");ForeverCompanionRefresh() end)
 local left,center,right=column(12,194,"Dungeons"),column(214,222,"Bosses"),column(444,314,"Encounter loot")
 lootPanels={center,right}
 ForeverCompanionDungeonQuests.Create(root)
 dungeons={};E.dungeonRows=dungeons
 for i=1,9 do
  dungeons[i]=entry(left,-39-(i-1)*25,178,24,function(self)
   E.SelectDungeon(self.dungeon);ForeverCompanionRefresh()
  end)
 end
 dungeonBack=button(left,8,-272,75,"Previous",function() E.dungeonPage=E.dungeonPage-1;ForeverCompanionRefresh() end)
 dungeonNext=button(left,111,-272,75,"Next",function() E.dungeonPage=E.dungeonPage+1;ForeverCompanionRefresh() end)
 local function wheel(_,delta)
  E.dungeonPage=E.dungeonPage+(delta<0 and 1 or -1);ForeverCompanionRefresh()
 end
 left:EnableMouseWheel(true);left:SetScript('OnMouseWheel',wheel)
 for _,row in ipairs(dungeons) do row:EnableMouseWheel(true);row:SetScript('OnMouseWheel',wheel) end
 rows={};E.rows=rows
 for i=1,E.pageSize do
  local row=entry(center,-39-(i-1)*36,206,34,function(self)
   E.boss=self.boss;E.dropPage=1;ForeverCompanionRefresh()
  end)
  row.name:SetWidth(174)
  row.count=label(row,181,-8,20,"",10)
  rows[i]=row
 end
 previous=button(center,8,-270,70,"Previous",function() E.page=E.page-1;ForeverCompanionRefresh() end)
 nextPage=button(center,144,-270,70,"Next",function() E.page=E.page+1;ForeverCompanionRefresh() end)
 E.nextBossPage=nextPage
 pageLabel=label(center,83,-275,60)
 pageLabel:SetJustifyH("CENTER")
 E.emptyBosses=label(center,12,-48,198,'',11)
 E.emptyBosses:SetWordWrap(true);E.emptyBosses:SetHeight(150)
 bossTitle=label(right,10,-41,290,"",13,true)
 E.noDrops=label(right,12,-86,290,'',12);E.noDrops:SetHeight(150);E.noDrops:SetWordWrap(true)
 local function open(record)
  if E.boss=="" then return end
  ForeverCompanionLootWorkspace.SetScope(E.dungeon,E.boss,record)
  navigate("Loot")
 end
 lootRows={};E.lootRows=lootRows
 for i=1,4 do
  local row=entry(right,-76-(i-1)*45,298,42,function(self) open(self.record) end)
  row.name:ClearAllPoints();row.name:SetPoint("TOPLEFT",row,"TOPLEFT",41,-6);row.name:SetWidth(246)
  row.meta=label(row,41,-23,246,"",10)
  row.icon=row:CreateTexture(nil,"ARTWORK")
  row.icon:SetSize(28,28);row.icon:SetPoint("LEFT",row,"LEFT",7,0)
  chrome.Socket(row,row.icon)
  row:SetScript("OnEnter",function(self) ForeverCompanionLoot.ShowItemTooltip(self,self.record) end)
  row:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
  lootRows[i]=row
 end
 E.guideButton=button(right,8,-270,94,"Boss guide",function() ForeverCompanionBossGuideWorkspace.Open(E.dungeon,E.boss) end)
 openLoot=button(right,108,-270,88,"Boss loot",function() open() end)
 dropBack=button(right,205,-270,46,"<",function() E.dropPage=E.dropPage-1;ForeverCompanionRefresh() end)
 dropNext=button(right,258,-270,46,">",function() E.dropPage=E.dropPage+1;ForeverCompanionRefresh() end)
 local routeStatus=label(root,16,-383,454,'',10)
 E.routeStatus=routeStatus
 E.mapButton=button(root,478,-376,132,'Dungeon map',function() ForeverCompanionDungeonMaps.Open(E.dungeon) end)
 ForeverCompanionInterface.SetHoverHelp(E.mapButton,'Dungeon map','Open the interior floor view or follow a landmark route for the selected dungeon.')
 E.routeButton=button(root,620,-376,134,'Find entrance',function()
  routeStatus:SetText(ForeverCompanionDungeonCatalog.Navigate(E.dungeon))
 end)
 E.routeButton:SetScript('OnEnter',function(self)
  local p=ForeverCompanionDungeonCatalog.Approach(E.dungeon)
  if p and GameTooltip then
   GameTooltip:SetOwner(self,'ANCHOR_TOP')
   GameTooltip:SetText(E.dungeon..' outdoor approach')
   GameTooltip:AddLine(string.format('%s %.1f, %.1f',p.zone,p.x*100,p.y*100))
   GameTooltip:AddLine(p.source,1,1,1,true);GameTooltip:Show()
  end
 end)
 E.routeButton:SetScript('OnLeave',function() if GameTooltip then GameTooltip:Hide() end end)
 root:Hide()
end
function E.Render(tab,db)
 if not root then return end
 if tab~="Dungeons" then root:Hide();ForeverCompanionDungeonQuests.Hide();return end
 local loot=ForeverCompanionLoot
 local names=ForeverCompanionDungeonCatalog and ForeverCompanionDungeonCatalog.JournalDirectory() or loot.DungeonNames()
 local selectedMatches
 if E.query~='' and ForeverCompanionDungeonCatalog then
  local filtered,seen=ForeverCompanionDungeonCatalog.JournalDirectory(E.query),{}
  for _,n in ipairs(filtered) do seen[n]=true end
  for _,n in ipairs(names) do
   if not seen[n] then
    local matches=E.Results(n,E.query,seen)
    if n==E.dungeon then selectedMatches=matches end
    if #matches>0 then filtered[#filtered+1]=n end
   end
  end
  table.sort(filtered,function(a,b) return ForeverCompanionDungeonCatalog.DisplayName(a)<ForeverCompanionDungeonCatalog.DisplayName(b) end);names=filtered
  local found=false
  for i,n in ipairs(names) do
   if n==E.dungeon then found=true;break end
  end
  if not found then E.SelectDungeon(names[1] or '',true);E.dungeonPage=1;selectedMatches=nil end
 end
 if E.dungeon=="" and E.query=="" then E.SelectDungeon(names[1] or "") end
 subtitle:SetText(E.dungeon=="" and "Dungeon search" or (ForeverCompanionDungeonCatalog and ForeverCompanionDungeonCatalog.Summary(E.dungeon) or E.dungeon).." · "..#loot.BossNames(E.dungeon).." loot sources")

 local dungeonPages=math.max(1,math.ceil(#names/#dungeons))
 E.dungeonPage=math.max(1,math.min(dungeonPages,E.dungeonPage))
 for i,row in ipairs(dungeons) do
  row.dungeon=names[(E.dungeonPage-1)*#dungeons+i]
  if row.dungeon then
   row.name:SetText(ForeverCompanionDungeonCatalog.DisplayName(row.dungeon));tint(row,row.dungeon==E.dungeon);row:Show()
   row:SetScript('OnEnter',function(self) if GameTooltip then GameTooltip:SetOwner(self,'ANCHOR_RIGHT');GameTooltip:SetText(ForeverCompanionDungeonCatalog.DisplayName(self.dungeon));GameTooltip:AddLine(ForeverCompanionDungeonCatalog.Summary(self.dungeon),.8,.85,.9,true);local info=ForeverCompanionDungeonCatalog.entries[self.dungeon];if info and info.wings then GameTooltip:AddLine(info.wings,.85,.85,.85,true) end;GameTooltip:AddLine(#loot.BossNames(self.dungeon)..' imported loot sources · coverage is partial',.8,.72,.5,true);GameTooltip:Show() end end)
   row:SetScript('OnLeave',function() if GameTooltip then GameTooltip:Hide() end end)
  else row:Hide() end
 end
 if dungeonPages>1 then dungeonBack:Show();dungeonNext:Show() else dungeonBack:Hide();dungeonNext:Hide() end
 dungeonBack:SetEnabled(E.dungeonPage>1);dungeonNext:SetEnabled(E.dungeonPage<dungeonPages)
 local matches=selectedMatches or E.Results(E.dungeon,E.query)
 local pages=math.max(1,math.ceil(#matches/E.pageSize))
 E.page=math.max(1,math.min(pages,E.page))
 for i,row in ipairs(rows) do
  local item=matches[(E.page-1)*E.pageSize+i]
  row.boss=item and item.boss
  if item then
   row.name:SetText(item.boss);row.count:SetText(item.count>0 and item.count or '-');tint(row,row.boss==E.boss);row:Show()
  else row:Hide() end
 end
 if #matches==0 then
  E.emptyBosses:SetText(E.dungeon=='' and 'No dungeons match this search.' or #E.BossNames(E.dungeon)==0 and ('No bosses listed for '..E.dungeon..' yet.') or 'No matches. Clear search to see all bosses.');E.emptyBosses:Show()
 else E.emptyBosses:Hide() end
 if pages>1 then previous:Show();nextPage:Show();pageLabel:Show() else previous:Hide();nextPage:Hide();pageLabel:Hide() end
 previous:SetEnabled(E.page>1);nextPage:SetEnabled(E.page<pages);pageLabel:SetText(E.page.." / "..pages)
 local drops=loot.BossDrops(E.dungeon,E.boss)
 local dropPages=math.max(1,math.ceil(#drops/#lootRows))
 E.dropPage=math.max(1,math.min(dropPages,E.dropPage))
 bossTitle:SetText(E.boss~="" and E.boss or "Choose a boss")
 openLoot:SetEnabled(#drops>0)
 E.guideButton:SetEnabled(E.boss~='')
 E.noDrops:SetText('No drops listed yet. Open Boss guide for encounter notes.')
 E.noDrops:SetShown(E.boss~='' and #drops==0)
 if dropPages>1 then dropBack:Show();dropNext:Show() else dropBack:Hide();dropNext:Hide() end
 dropBack:SetEnabled(E.dropPage>1);dropNext:SetEnabled(E.dropPage<dropPages)
 for i,row in ipairs(lootRows) do
  local record=drops[(E.dropPage-1)*#lootRows+i]
  row.record=record
  if record then
   row.name:SetText(record.item)
   row.meta:SetText((record.slot or "Slot unknown")..(loot.Wishlist(db)[record.item] and "  •  Wishlisted" or ""))
   row.icon:SetTexture(loot.ItemIcon(record));tint(row,false);row:Show()
  else row:Hide() end
 end
 for _,p in ipairs(lootPanels) do p:SetShown(not E.questView) end
 journalTitle:SetText(E.dungeon~='' and ForeverCompanionDungeonCatalog.DisplayName(E.dungeon) or (E.query~='' and 'No matching dungeons' or 'Dungeon Journal'))
 lootTab:SetEnabled(E.questView==true);questViewButton:SetEnabled(not E.questView)
 if E.questView then ForeverCompanionDungeonQuests.Render(E.dungeon) else ForeverCompanionDungeonQuests.Hide() end
 if E.routeDungeon~=E.dungeon then
  E.routeDungeon=E.dungeon
  E.mapButton:SetEnabled(E.dungeon~='')
  local p=ForeverCompanionDungeonCatalog.Approach(E.dungeon)
  E.routeButton:SetEnabled(p~=nil and not p.approximate)
  E.routeStatus:SetText(p and string.format(p.approximate and 'Dungeon area: %s %.1f, %.1f' or 'Outdoor approach: %s %.1f, %.1f',p.zone,p.x*100,p.y*100) or 'No sourced entrance approach for this dungeon.')
 end
 root:Show()
end
