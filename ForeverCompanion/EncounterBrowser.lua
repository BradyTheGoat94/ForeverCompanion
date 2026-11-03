-- Historical catalog navigation. No boss tactics, rates or unlocks inferred.
local E={dungeon="",boss="",query="",page=1,pageSize=4}
ForeverCompanionEncounterBrowser=E
local root,title,detail,buttons,host,navigate,rows,pageLabel,previous,nextPage
-- Only bosses represented in the attributed loot catalog are included.
function E.Results(dungeon,query)
 local result={}
 local term=type(query)=="string" and query:lower():gsub("^%s+",""):gsub("%s+$","") or ""
 for _,name in ipairs(ForeverCompanionLoot.BossNames(dungeon)) do
  local drops=ForeverCompanionLoot.BossDrops(dungeon,name)
  local matches=term=="" or name:lower():find(term,1,true) or dungeon:lower():find(term,1,true)
  for _,drop in ipairs(drops) do if drop.item:lower():find(term,1,true) then matches=true end end
  if matches then result[#result+1]={boss=name,count=#drops} end
 end
 return result
end
local function cycle(list,value)
 for i,name in ipairs(list) do if name==value then return list[i+1] or list[1] or "" end end
 return list[1] or ""
end
function E.NextDungeon()
 E.dungeon=cycle(ForeverCompanionLoot.DungeonNames(),E.dungeon)
 E.boss=ForeverCompanionLoot.BossNames(E.dungeon)[1] or ""
 E.page=1
 E.query=""
 if E.searchBox then E.searchBox:SetText("") end
end
function E.NextBoss()
 E.boss=cycle(ForeverCompanionLoot.BossNames(E.dungeon),E.boss)
end
local function label(parent,x,y,w,font)
 local t=parent:CreateFontString(nil,"OVERLAY",font or "GameFontHighlightSmall")
 t:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y);t:SetWidth(w);t:SetJustifyH("LEFT");return t
end
function E.Create(parent,openPage)
 host=parent;navigate=openPage
 root=CreateFrame("Frame",nil,parent);root:SetSize(770,356);root:SetPoint("TOPLEFT",parent,"TOPLEFT",8,-330)
 local bg=root:CreateTexture(nil,"BACKGROUND");bg:SetAllPoints(root)
 if bg.SetColorTexture then bg:SetColorTexture(0.045,0.060,0.085,1) else bg:SetTexture(0.045,0.060,0.085,1) end
 local rail=root:CreateTexture(nil,"ARTWORK");rail:SetSize(770,2);rail:SetPoint("TOPLEFT",root,"TOPLEFT",0,0)
 if rail.SetColorTexture then rail:SetColorTexture(0.92,0.70,0.31,1) else rail:SetTexture(0.92,0.70,0.31,1) end
 title=label(root,16,-14,730,"GameFontNormalLarge");title:SetText("BOSS & LOOT REFERENCE");title:SetTextColor(0.96,0.76,0.39)
 local notice=label(root,16,-42,735);notice:SetText("Historical sourced catalog. Forever availability and mechanics unconfirmed; drop chances unknown.")
 buttons={}
 local captions={"Cycle dungeon","Clear search","Open boss loot"}
 for i=1,3 do
  local b=CreateFrame("Button",nil,root,"UIPanelButtonTemplate");b:SetSize(238,24);b:SetPoint("TOPLEFT",root,"TOPLEFT",16+(i-1)*247,-67);b:SetText(captions[i]);buttons[i]=b
 end
 buttons[1]:SetScript("OnClick",function() E.NextDungeon();ForeverCompanionRefresh() end)
 buttons[2]:SetScript("OnClick",function() E.query="";E.page=1;E.searchBox:SetText("");ForeverCompanionRefresh() end)
 buttons[3]:SetScript("OnClick",function()
  if E.dungeon=="" or E.boss=="" then return end
  local ui=ForeverCompanionLootUI
  ui.query="";ui.dungeon=E.dungeon;ui.boss=E.boss;ui.savedOnly=false;ui.selectedIndex=1
  if ui.searchBox then ui.searchBox:SetText("") end
  navigate("Loot")
 end)
 local searchLabel=label(root,16,-105,110);searchLabel:SetText("Boss / item search")
 E.searchBox=CreateFrame("EditBox",nil,root,"InputBoxTemplate");E.searchBox:SetSize(575,24);E.searchBox:SetPoint("TOPLEFT",root,"TOPLEFT",160,-99)
 if E.searchBox.SetAutoFocus then E.searchBox:SetAutoFocus(false) end
 if E.searchBox.SetMaxLetters then E.searchBox:SetMaxLetters(120) end
 E.searchBox:SetScript("OnTextChanged",function(self,userInput)
  if userInput then E.query=self:GetText():sub(1,120);E.page=1;ForeverCompanionRefresh() end
 end)
 E.searchBox:SetScript("OnEscapePressed",function(self) if self.ClearFocus then self:ClearFocus() end end)
 E.searchBox:SetScript("OnEnterPressed",function(self) if self.ClearFocus then self:ClearFocus() end end)
 rows={}
 for i=1,E.pageSize do
  local row=CreateFrame("Button",nil,root,"UIPanelButtonTemplate");row:SetSize(738,29);row:SetPoint("TOPLEFT",root,"TOPLEFT",16,-134-(i-1)*33)
  row:SetScript("OnClick",function(self)
   if self.boss then E.boss=self.boss;ForeverCompanionRefresh() end
  end)
  rows[i]=row
 end
 E.rows=rows
 previous=CreateFrame("Button",nil,root,"UIPanelButtonTemplate");previous:SetSize(125,24);previous:SetPoint("TOPLEFT",root,"TOPLEFT",16,-270);previous:SetText("Previous bosses")
 previous:SetScript("OnClick",function() E.page=math.max(1,E.page-1);ForeverCompanionRefresh() end)
 nextPage=CreateFrame("Button",nil,root,"UIPanelButtonTemplate");nextPage:SetSize(125,24);nextPage:SetPoint("TOPLEFT",root,"TOPLEFT",629,-270);nextPage:SetText("Next bosses")
 nextPage:SetScript("OnClick",function() E.page=E.page+1;ForeverCompanionRefresh() end)
 pageLabel=label(root,160,-277,455)
 detail=label(root,16,-307,735)
 root:Hide()
end
function E.Render(tab,db)
 if not root then return end
 if tab~="Dungeons" then root:Hide();return end
 if E.dungeon=="" then E.NextDungeon() end
 title:SetText(E.dungeon~="" and ("REFERENCE / "..E.dungeon) or "BOSS & LOOT REFERENCE")
 buttons[1]:SetText("Dungeon: "..(E.dungeon~="" and E.dungeon or "None"))
 local matches=E.Results(E.dungeon,E.query)
 local pages=math.max(1,math.ceil(#matches/E.pageSize))
 E.page=math.max(1,math.min(pages,E.page))
 for i,row in ipairs(rows) do
  local entry=matches[(E.page-1)*E.pageSize+i]
  row.boss=entry and entry.boss or nil
  if entry then
   row:SetText((entry.boss==E.boss and "[SELECTED] " or "")..entry.boss.." / "..entry.count..(entry.count==1 and " catalog entry" or " catalog entries"))
   if row.SetEnabled then row:SetEnabled(true) end
   row:Show()
  else row:Hide() end
 end
 pageLabel:SetText(#matches==0 and "No matches. Clear search to browse this dungeon." or (#matches.." catalog bosses / Page "..E.page.." of "..pages))
 if previous.SetEnabled then previous:SetEnabled(E.page>1) end
 if nextPage.SetEnabled then nextPage:SetEnabled(E.page<pages) end
 if buttons[3].SetEnabled then buttons[3]:SetEnabled(E.boss~="") end
 detail:SetText(E.boss~="" and ("Selected: "..E.boss.." / "..#ForeverCompanionLoot.BossDrops(E.dungeon,E.boss).." attributed loot records.\nSearch only filters the list; selection, loot shortcut and research remain on this boss.\nPartial historical catalog; not a complete boss roster or verified Forever encounter guide.") or "No sourced bosses loaded. Role preparation remains available above.")
 root:Show()
end
