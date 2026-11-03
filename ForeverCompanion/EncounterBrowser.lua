-- Historical catalog navigation. No boss tactics, rates or unlocks inferred.
local E={dungeon="",boss=""}
ForeverCompanionEncounterBrowser=E
local root,title,detail,buttons,host,navigate
local function cycle(list,value)
 for i,name in ipairs(list) do if name==value then return list[i+1] or list[1] or "" end end
 return list[1] or ""
end
function E.NextDungeon()
 E.dungeon=cycle(ForeverCompanionLoot.DungeonNames(),E.dungeon)
 E.boss=ForeverCompanionLoot.BossNames(E.dungeon)[1] or ""
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
 root=CreateFrame("Frame",nil,parent);root:SetSize(770,202);root:SetPoint("TOPLEFT",parent,"TOPLEFT",8,-330)
 local bg=root:CreateTexture(nil,"BACKGROUND");bg:SetAllPoints(root)
 if bg.SetColorTexture then bg:SetColorTexture(0.045,0.060,0.085,1) else bg:SetTexture(0.045,0.060,0.085,1) end
 local rail=root:CreateTexture(nil,"ARTWORK");rail:SetSize(770,2);rail:SetPoint("TOPLEFT",root,"TOPLEFT",0,0)
 if rail.SetColorTexture then rail:SetColorTexture(0.92,0.70,0.31,1) else rail:SetTexture(0.92,0.70,0.31,1) end
 title=label(root,16,-14,730,"GameFontNormalLarge");title:SetText("BOSS & LOOT REFERENCE");title:SetTextColor(0.96,0.76,0.39)
 local notice=label(root,16,-42,735);notice:SetText("Historical sourced catalog. Forever availability and mechanics unconfirmed; drop chances unknown.")
 buttons={}
 local captions={"Cycle dungeon","Cycle boss","Open boss loot"}
 for i=1,3 do
  local b=CreateFrame("Button",nil,root,"UIPanelButtonTemplate");b:SetSize(238,24);b:SetPoint("TOPLEFT",root,"TOPLEFT",16+(i-1)*247,-67);b:SetText(captions[i]);buttons[i]=b
 end
 buttons[1]:SetScript("OnClick",function() E.NextDungeon();ForeverCompanionRefresh() end)
 buttons[2]:SetScript("OnClick",function() E.NextBoss();ForeverCompanionRefresh() end)
 buttons[3]:SetScript("OnClick",function()
  if E.dungeon=="" or E.boss=="" then return end
  local ui=ForeverCompanionLootUI
  ui.query="";ui.dungeon=E.dungeon;ui.boss=E.boss;ui.savedOnly=false;ui.selectedIndex=1
  if ui.searchBox then ui.searchBox:SetText("") end
  navigate("Loot")
 end)
 detail=label(root,16,-105,735)
 root:Hide()
end
function E.Render(tab,db)
 if not root then return end
 if tab~="Dungeons" then root:Hide();return end
 if E.dungeon=="" then E.NextDungeon() end
 title:SetText(E.dungeon~="" and ("REFERENCE / "..E.dungeon) or "BOSS & LOOT REFERENCE")
 buttons[1]:SetText("Dungeon: "..(E.dungeon~="" and E.dungeon or "None"))
 buttons[2]:SetText("Boss: "..(E.boss~="" and E.boss or "None"))
 if buttons[3].SetEnabled then buttons[3]:SetEnabled(E.boss~="") end
 detail:SetText(E.boss~="" and ("Selected boss: "..E.boss.."\n"..ForeverCompanionLoot.ProgressSummary(db,E.dungeon,E.boss).."\nPreparation: review your role checklist above; consult verified encounter instructions before pulling.") or "No sourced bosses loaded. Role preparation remains available above.")
 root:Show()
end
