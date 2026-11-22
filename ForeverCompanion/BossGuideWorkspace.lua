-- Encounter tactics are visible as individual rows; published evidence opens separately.
local W={};ForeverCompanionBossGuideWorkspace=W
local U=ForeverCompanionInterface
local function text(parent,x,y,width,size,height)
 local t=U.Text(parent,size)
 t:SetPoint('TOPLEFT',x,y);t:SetWidth(width);t:SetHeight(height);t:SetWordWrap(true);t:SetJustifyV('TOP')
 return t
end
function W.MechanicRows(dungeon,boss)
 local M=ForeverCompanionBossMechanics
 local record=M.Get(dungeon,boss)
 local rows={}
 if record and record.state~='pending' and record.state~='not-boss' then
  for _,mechanic in ipairs(record.mechanics) do rows[#rows+1]=mechanic end
 end
 if #rows==0 then
  local status=not record and 'Research pending' or record.state=='pending' and 'Mechanics undocumented'
   or record.state=='not-boss' and 'Regular-enemy loot source' or 'No notable abilities documented'
  rows[1]=status
 end
 return rows,record
end
local function create()
 local C=ForeverCompanionDungeonChrome
 local root=CreateFrame('Frame','ForeverCompanionBossGuide',UIParent,'BackdropTemplate')
 root:SetSize(640,422);root:SetPoint('CENTER');root:SetFrameStrata('DIALOG')
 U.Surface(root);U.PreparePanel(root,'ForeverCompanionBossGuide',640,422)
 root:SetScript('OnEvent',function(self) U.FitPanel(self,640,self:GetHeight()) end)
 U.CloseButton(root,function() root:Hide() end)
 C.Seal(root,24,-20,54)
 W.root=root
 W.title=text(root,94,-20,491,20,46);W.title:SetTextColor(unpack(C.cream))
 W.dungeonText=text(root,96,-67,456,12,21);W.dungeonText:SetTextColor(unpack(C.gold))
 local header=text(root,22,-115,590,15,23);header:SetText('Encounter tactics')
 local scroll=CreateFrame('ScrollFrame',nil,root,'UIPanelScrollFrameTemplate')
 scroll:SetPoint('TOPLEFT',23,-143);scroll:SetSize(569,208);scroll:SetClipsChildren(true)
 local child=CreateFrame('Frame',nil,scroll);child:SetSize(567,208);scroll:SetScrollChild(child)
 W.scroll,W.child=scroll,child
 W.rows={}
 W.referenceButton=U.Button(root);W.referenceButton:SetSize(138,26);W.referenceButton:SetPoint('BOTTOMLEFT',22,18)
 W.referenceButton:SetText('Sources & notes')
 U.SetHoverHelp(W.referenceButton,'Sources & notes','Read the published encounter reference and its coverage notes.')
 W.referenceButton:SetScript('OnClick',function()
  local M=ForeverCompanionBossMechanics
  local record=M.Get(W.dungeon,W.boss)
  local topics={{title='Encounter notes',body=M.Format(W.dungeon,W.boss)}}
  if record then topics[#topics+1]={title='Source',body=(record.basis or 'Published encounter reference')..'\n\nReviewed '..record.reviewed..'\n'..record.source} end
  ForeverCompanionReferenceWorkspace.Open(W.boss,topics)
 end)
 W.state=U.Text(root,12,C.gold);W.state:SetPoint('BOTTOMLEFT',175,21);W.state:SetWidth(410)
end
function W.Open(dungeon,boss)
 if type(dungeon)~='string' or type(boss)~='string' or boss=='' then return false end
 local M=ForeverCompanionBossMechanics
 if M.Canonical then boss=M.Canonical(dungeon,boss) end
 if not W.root then create() end
 W.dungeon,W.boss=dungeon,boss
 W.title:SetText(boss);W.dungeonText:SetText(dungeon)
 local tactics,record=W.MechanicRows(dungeon,boss)
 local height=0
 for index,note in ipairs(tactics) do
  local row=W.rows[index]
  if not row then
   row=CreateFrame('Frame',nil,W.child);U.Surface(row,{background=U.palette.surface,flat=true})
   row.icon=row:CreateTexture(nil,'ARTWORK');row.icon:SetSize(20,20);row.icon:SetPoint('TOPLEFT',10,-9)
   row.icon:SetTexture('Interface\\Icons\\INV_Misc_Note_01')
   row.caption=text(row,39,-9,510,13,34)
   row:EnableMouse(true);U.SetHoverHelp(row,'Tactic',function() return row.note end)
   W.rows[index]=row
  end
  row.note=note;row.caption:SetText(note)
  local textHeight=math.max(19,row.caption:GetStringHeight()+2)
  row.caption:SetHeight(textHeight);row:SetSize(560,textHeight+18)
  row:ClearAllPoints();row:SetPoint('TOPLEFT',0,-height)
  row:Show();height=height+textHeight+24
 end
 for i=#tactics+1,#W.rows do W.rows[i]:Hide() end
 local viewport=math.max(72,math.min(208,height))
 W.scroll:SetHeight(viewport);W.child:SetHeight(math.max(viewport,height));W.scroll:SetVerticalScroll(0)
 W.root:SetHeight(214+viewport);U.FitPanel(W.root,640,W.root:GetHeight())
 W.state:SetText(record and (record.state=='pending' and 'Research pending' or 'Published reference') or 'Research pending')
 W.root:Show();return true
end
