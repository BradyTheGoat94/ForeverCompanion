-- Dungeon, boss and item navigation for the sourced catalog.
local E={dungeon="",boss="",query="",page=1,pageSize=6,dungeonPage=1,dropPage=1}
ForeverCompanionEncounterBrowser=E
local root,subtitle,rows,dungeons,lootRows,bossTitle,pageLabel,previous,nextPage,openLoot
local dungeonBack,dungeonNext,dropBack,dropNext
local theme=ForeverCompanionVisualTheme
function E.Results(dungeon,query)
 local result={}
 if type(dungeon)~="string" or dungeon=="" then return result end
 local term=type(query)=="string" and query:lower():gsub("^%s+",""):gsub("%s+$","") or ""
 for _,name in ipairs(ForeverCompanionLoot.BossNames(dungeon)) do
  local drops=ForeverCompanionLoot.BossDrops(dungeon,name)
  local matches=term=="" or name:lower():find(term,1,true) or dungeon:lower():find(term,1,true)
  for _,drop in ipairs(drops) do if drop.item:lower():find(term,1,true) then matches=true end end
  if matches then result[#result+1]={boss=name,count=#drops} end
 end
 return result
end
function E.SelectDungeon(name)
 E.dungeon=name
 E.boss=ForeverCompanionLoot.BossNames(name)[1] or ""
 E.page=1;E.dropPage=1;E.query=""
 if E.searchBox then E.searchBox:SetText("") end
end
function E.Focus(dungeon,boss)
 E.SelectDungeon(dungeon)
 E.boss=boss
 for i,entry in ipairs(E.Results(dungeon,"")) do
  if entry.boss==boss then E.page=math.floor((i-1)/E.pageSize)+1;break end
 end
 for i,name in ipairs(ForeverCompanionLoot.DungeonNames()) do
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
 local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
 b:SetSize(w,23);b:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
 b:SetText(text);b:SetScript("OnClick",action)
 return b
end
local function entry(parent,y,w,h,action)
 local b=CreateFrame("Button",nil,parent)
 b:SetSize(w,h);b:SetPoint("TOPLEFT",parent,"TOPLEFT",8,y)
 b.bg=theme.Button(b,w,h)
 b.name=label(b,8,-6,w-16,"",11)
 b:SetScript("OnClick",action)
 return b
end
local function tint(row,selected)
 row.bg:SetColorTexture(selected and .20 or .055,selected and .155 or .07,selected and .085 or .10,1)
 row.name:SetTextColor(selected and 1 or .85,selected and .83 or .88,selected and .48 or .93)
end
local function column(x,w,name)
 local p=CreateFrame("Frame",nil,root)
 p:SetSize(w,302);p:SetPoint("TOPLEFT",root,"TOPLEFT",x,-72)
 theme.Panel(p,w,302)
 label(p,10,-10,w-20,name,13,true)
 return p
end
function E.Create(parent,navigate,onPrep)
 root=CreateFrame("Frame","ForeverCompanionDungeonJournal",parent)
 root:SetSize(770,402);root:SetPoint("TOPLEFT",parent,"TOPLEFT",8,-5)
 theme.Panel(root,770,402)
 label(root,16,-13,500,"Dungeon Journal",18,true)
 subtitle=label(root,16,-44,440)
 button(root,614,-10,140,"Prep & notes",onPrep)
 label(root,456,-46,60,"Search")
 E.searchBox=CreateFrame("EditBox",nil,root,"InputBoxTemplate")
 E.searchBox:SetSize(176,22);E.searchBox:SetPoint("TOPLEFT",root,"TOPLEFT",505,-39)
 if E.searchBox.SetAutoFocus then E.searchBox:SetAutoFocus(false) end
 if E.searchBox.SetMaxLetters then E.searchBox:SetMaxLetters(120) end
 E.searchBox:SetScript("OnTextChanged",function(self,userInput)
  if userInput then E.query=self:GetText():sub(1,120);E.page=1;ForeverCompanionRefresh() end
 end)
 E.searchBox:SetScript("OnEscapePressed",function(self) if self.ClearFocus then self:ClearFocus() end end)
 E.searchBox:SetScript("OnEnterPressed",function(self) if self.ClearFocus then self:ClearFocus() end end)
 button(root,690,-39,64,"Clear",function() E.query="";E.page=1;E.searchBox:SetText("");ForeverCompanionRefresh() end)
 local left,center,right=column(12,194,"Dungeons"),column(214,222,"Bosses"),column(444,314,"Drops")
 dungeons={};E.dungeonRows=dungeons
 for i=1,9 do
  dungeons[i]=entry(left,-39-(i-1)*25,178,24,function(self)
   E.SelectDungeon(self.dungeon);ForeverCompanionRefresh()
  end)
 end
 dungeonBack=button(left,8,-272,75,"Previous",function() E.dungeonPage=E.dungeonPage-1;ForeverCompanionRefresh() end)
 dungeonNext=button(left,111,-272,75,"Next",function() E.dungeonPage=E.dungeonPage+1;ForeverCompanionRefresh() end)
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
 E.emptyBosses=label(center,12,-48,198,"No matching bosses or items.",11)
 bossTitle=label(right,10,-41,290,"",13,true)
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
  row:SetScript("OnEnter",function(self) ForeverCompanionLoot.ShowItemTooltip(self,self.record) end)
  row:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
  lootRows[i]=row
 end
 openLoot=button(right,8,-270,188,"Open boss loot",function() open() end)
 dropBack=button(right,205,-270,46,"<",function() E.dropPage=E.dropPage-1;ForeverCompanionRefresh() end)
 dropNext=button(right,258,-270,46,">",function() E.dropPage=E.dropPage+1;ForeverCompanionRefresh() end)
 label(root,16,-383,738,"Catalog is partial. Hover for item stats. Select an item to open its loot details.",10)
 root:Hide()
end
function E.Render(tab,db)
 if not root then return end
 if tab~="Dungeons" then root:Hide();return end
 local loot=ForeverCompanionLoot
 local names=loot.DungeonNames()
 if E.dungeon=="" then E.SelectDungeon(names[1] or "") end
 subtitle:SetText(E.dungeon.."  /  "..#loot.BossNames(E.dungeon).." bosses listed")
 local dungeonPages=math.max(1,math.ceil(#names/#dungeons))
 E.dungeonPage=math.max(1,math.min(dungeonPages,E.dungeonPage))
 for i,row in ipairs(dungeons) do
  row.dungeon=names[(E.dungeonPage-1)*#dungeons+i]
  if row.dungeon then
   row.name:SetText(row.dungeon);tint(row,row.dungeon==E.dungeon);row:Show()
  else row:Hide() end
 end
 if dungeonPages>1 then dungeonBack:Show();dungeonNext:Show() else dungeonBack:Hide();dungeonNext:Hide() end
 dungeonBack:SetEnabled(E.dungeonPage>1);dungeonNext:SetEnabled(E.dungeonPage<dungeonPages)
 local matches=E.Results(E.dungeon,E.query)
 local pages=math.max(1,math.ceil(#matches/E.pageSize))
 E.page=math.max(1,math.min(pages,E.page))
 for i,row in ipairs(rows) do
  local item=matches[(E.page-1)*E.pageSize+i]
  row.boss=item and item.boss
  if item then
   row.name:SetText(item.boss);row.count:SetText(item.count);tint(row,row.boss==E.boss);row:Show()
  else row:Hide() end
 end
 if #matches==0 then E.emptyBosses:Show() else E.emptyBosses:Hide() end
 if pages>1 then previous:Show();nextPage:Show();pageLabel:Show() else previous:Hide();nextPage:Hide();pageLabel:Hide() end
 previous:SetEnabled(E.page>1);nextPage:SetEnabled(E.page<pages);pageLabel:SetText(E.page.." / "..pages)
 local drops=loot.BossDrops(E.dungeon,E.boss)
 local dropPages=math.max(1,math.ceil(#drops/#lootRows))
 E.dropPage=math.max(1,math.min(dropPages,E.dropPage))
 bossTitle:SetText(E.boss~="" and E.boss or "Choose a boss")
 openLoot:SetEnabled(#drops>0)
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
 root:Show()
end
