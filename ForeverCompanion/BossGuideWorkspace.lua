-- Native movable/resizable encounter notes; sources stay separate from tactics.
local W={};ForeverCompanionBossGuideWorkspace=W
local function text(parent,x,y,width,size,height)
 local t=ForeverCompanionInterface.Text(parent,size);t:SetPoint('TOPLEFT',x,y);t:SetWidth(width)
 t:SetHeight(height);t:SetWordWrap(true);t:SetJustifyV('TOP');return t
end
function W.Open(dungeon,boss)
 if type(dungeon)~='string' or type(boss)~='string' or boss=='' then return false end
 local M=ForeverCompanionBossMechanics
 if M.Canonical then boss=M.Canonical(dungeon,boss) end
 if not W.root then
  local U=ForeverCompanionInterface
  local C=ForeverCompanionDungeonChrome
  local root=CreateFrame('Frame','ForeverCompanionBossGuide',UIParent,'BackdropTemplate');W.root=root
  root:SetSize(640,448);root:SetPoint('CENTER');root:SetFrameStrata('DIALOG')
  U.PreparePanel(root,'ForeverCompanionBossGuide',640,448);C.Skin(root,640,448,104,true);U.CloseButton(root,function() root:Hide() end)
  C.Seal(root,24,-22,58)
  local journal=text(root,96,-18,482,11,18);journal:SetText('DUNGEON JOURNAL');journal:SetTextColor(unpack(C.gold))
  W.title=text(root,96,-39,494,18,46);W.title:SetTextColor(unpack(C.cream))
  W.dungeonText=text(root,25,-87,590,11,20);W.dungeonText:SetTextColor(unpack(C.gold))
  local panel=CreateFrame('Frame',nil,root,'BackdropTemplate');panel:SetSize(600,230);panel:SetPoint('TOPLEFT',20,-118);C.Skin(panel,600,230,30)
  local heading=text(panel,16,-11,566,13,22);heading:SetText('Encounter tactics');heading:SetTextColor(unpack(C.gold))
  W.body=text(panel,16,-46,566,13,170);W.body:SetTextColor(unpack(C.cream))
  W.referenceButton=U.Button(root);W.referenceButton:SetSize(94,26);W.referenceButton:SetPoint('TOPLEFT',22,-362)
  W.referenceButton:SetText('Sources')
  W.source=text(root,24,-398,590,10,38);W.source:SetTextColor(unpack(C.muted))
  W.state=text(root,128,-368,484,11,22);W.state:SetTextColor(unpack(C.gold))
  W.notice=text(root,24,-408,590,10,26);W.notice:SetTextColor(unpack(C.muted))
  W.referenceButton:SetScript('OnClick',function()
   W.showSources=not W.showSources;W.source:SetShown(W.showSources);W.notice:SetShown(not W.showSources)
   W.referenceButton:SetText(W.showSources and 'Hide sources' or 'Sources')
  end)
 end
 W.dungeon,W.boss=dungeon,boss
 W.title:SetText(boss);W.dungeonText:SetText(dungeon)
 W.body:SetText(M.Format(dungeon,boss))
 local record=M.Get(dungeon,boss)
 local state=record and (#record.mechanics>0 and 'Mechanics reference' or record.state=='pending' and 'Mechanics not documented' or record.state=='not-boss' and 'Loot source' or 'No notable abilities listed')
 W.source:SetText(record and (state..' | Reviewed '..record.reviewed..'\n'..record.source) or 'No encounter reference imported for this boss yet.')
 W.state:SetText(state or 'Research pending')
 W.source:SetShown(W.showSources or false);W.notice:SetShown(not W.showSources)
 W.notice:SetText(record and record.basis or 'Published encounter reference. Confirm current behavior in game.')
 W.root:Show();return true
end
