-- Dungeon-local journal materials. All regions belong to their owning frame;
-- decorative textures never add a covering frame or intercept mouse input.
local C={gold={.90,.73,.43,1},cream={.94,.95,.97,1},muted={.67,.73,.80,1}}
ForeverCompanionDungeonChrome=C
local function strip(parent,x,y,w,h,color,layer)
 local t=parent:CreateTexture(nil,layer or 'BORDER');t:SetPoint('TOPLEFT',parent,'TOPLEFT',x,y);t:SetSize(w,h)
 t:SetColorTexture(unpack(color));return t
end
function C.Skin(parent,w,h,header,outer)
 local inset=outer and 7 or 4
 local bg=strip(parent,inset,-inset,w-inset*2,h-inset*2,{.035,.052,.075,1},'BACKGROUND')
 local grain=parent:CreateTexture(nil,'BACKGROUND');grain:SetAllPoints(bg)
 grain:SetTexture('Interface\\DialogFrame\\UI-DialogBox-Background');grain:SetAlpha(.24)
 if parent.SetBackdrop then
  parent:SetBackdrop({edgeFile=outer and 'Interface\\DialogFrame\\UI-DialogBox-Border' or 'Interface\\Tooltips\\UI-Tooltip-Border',edgeSize=outer and 24 or 12,insets={left=inset,right=inset,top=inset,bottom=inset}})
  parent:SetBackdropBorderColor(1,1,1,1)
 end
 if header then
  strip(parent,8,-8,w-16,header-5,{.074,.101,.136,1})
  strip(parent,8,-header-3,w-16,1,{.50,.30,.64,1})
  if outer then ForeverCompanionVisualTheme.EnvironmentArt(parent,'TOPRIGHT',-8,-8,math.floor(w*.68),header-5,'Dungeons',.86,.11,'BORDER',1) end
 end
 for _,inset in ipairs({4}) do
  local color={.20,.24,.31,1}
  strip(parent,inset,-inset,w-2*inset,1,color)
  strip(parent,inset,-h+inset,w-2*inset,1,color)
  strip(parent,inset,-inset,1,h-2*inset,color)
  strip(parent,w-inset-1,-inset,1,h-2*inset,color)
 end
 parent.fcDungeonMaterial=grain;return bg
end
function C.Seal(parent,x,y,size)
 local seal=parent:CreateTexture(nil,'ARTWORK');seal:SetPoint('TOPLEFT',x,y);seal:SetSize(size,size)
 seal:SetTexture('Interface\\Icons\\INV_Misc_Book_09')
 local rim=parent:CreateTexture(nil,'OVERLAY');rim:SetPoint('TOPLEFT',seal,'TOPLEFT',-size*.16,size*.16);rim:SetPoint('BOTTOMRIGHT',seal,'BOTTOMRIGHT',size*.16,-size*.16)
 rim:SetTexture('Interface\\Buttons\\UI-Quickslot2');return seal
end
function C.Row(parent,w,h)
 local bg=strip(parent,0,0,w,h,{.046,.067,.092,.86},'BACKGROUND')
 strip(parent,4,-h+1,w-8,1,{.32,.25,.15,.32})
 return bg
end
function C.Select(row,bg,selected)
 row.fcSelected=selected and true or false
 local function paint(hover)
  if row.fcSelected then bg:SetColorTexture(.22,.115,.31,1)
  elseif hover then bg:SetColorTexture(.095,.132,.173,1) else bg:SetColorTexture(.046,.067,.092,.86) end
 end
 if not row.fcDungeonHover then
  row.fcDungeonHover=true;row:HookScript('OnEnter',function() paint(true) end);row:HookScript('OnLeave',function() paint(false) end)
 end
 if not row.fcDungeonSelection then
  row.fcDungeonSelection=strip(row,0,0,3,row:GetHeight(),C.gold,'ARTWORK')
 end
 row.fcDungeonSelection:SetShown(row.fcSelected);paint(false)
 row.name:SetTextColor(unpack(selected and C.gold or C.cream))
end
function C.Socket(row,icon)
 local rim=row:CreateTexture(nil,'BORDER');rim:SetPoint('TOPLEFT',icon,'TOPLEFT',-4,4);rim:SetPoint('BOTTOMRIGHT',icon,'BOTTOMRIGHT',4,-4)
 rim:SetTexture('Interface\\Buttons\\UI-Quickslot2');rim:SetAlpha(.9)
 return rim
end
