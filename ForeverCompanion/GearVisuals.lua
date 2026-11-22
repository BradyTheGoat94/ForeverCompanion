-- Native textures and restrained semantic colors for gear research only.
local V={};ForeverCompanionGearVisuals=V
V.colors={ink={.025,.040,.075,1},panel={.045,.070,.120,1},border={.19,.28,.43,1},text={.94,.96,1,1},muted={.67,.75,.87,1},blue={.32,.73,1,1},amber={1,.73,.30,1},green={.34,.91,.65,1},violet={.76,.59,1,1},coral={1,.55,.47,1}}
local C=V.colors
local accents={discover=C.blue,hunts=C.amber,completed=C.green,weights=C.violet,upgrade=C.green,lower=C.coral,review=C.amber,neutral=C.blue}
local rarity={{.67,.72,.80,1},{.94,.96,1,1},{.40,.91,.49,1},{.38,.70,1,1},{.79,.56,1,1},{1,.65,.27,1},{1,.82,.40,1},{.43,.90,.96,1}}
function V.Palette(kind)
 local a=accents[kind] or C.blue
 return {background=C.ink,surface={.065,.105,.175,1},border=C.border,rail={.055+a[1]*.10,.07+a[2]*.10,.11+a[3]*.10,1},accent=a,text=C.text,muted=C.muted}
end
function V.Quality(value)
 if issecretvalue and issecretvalue(value) then return C.muted end
 if type(value)=='number' and value==math.floor(value) and value>=0 and value<=7 then return rarity[value+1] end
 return C.muted
end
function V.State(row)
 if row.unavailable or row.blocked or row.future then return 'REVIEW','review' end
 if row.completed then return 'ACQUIRED','completed' end
 if row.owned and row.owned>0 then return 'OWNED','completed' end
 if row.tracked then return 'PINNED','hunts' end
 if row.upgradeTier==2 then return 'POSSIBLE','review' end
 if row.upgradeTier==1 then return 'INSPECT','review' end
 if row.partial then return 'PARTIAL','review' end
 if row.delta and row.delta>0 then return 'HIGHER','upgrade' end
 if row.delta and row.delta<0 then return 'LOWER','lower' end
 if row.delta==0 then return 'EQUAL','neutral' end
 return 'UNRANKED','review'
end
function V.Rectangle(parent,x,y,width,height,color,layer)
 local t=parent:CreateTexture(nil,layer or 'BACKGROUND');t:SetPoint('TOPLEFT',x,-y);t:SetSize(width,height);t:SetColorTexture(unpack(color));return t
end
function V.Window(parent,width,height,kind)
 ForeverCompanionInterface.Surface(parent,V.Palette(kind))
 local header=V.Rectangle(parent,1,1,width-2,106,{.065,.095,.175,1})
 ForeverCompanionInterface.Material(parent,header,.65)
 V.Rectangle(parent,1,1,width-2,3,C.blue,'BORDER')
 local segment=(width-2)/4
 for i,key in ipairs({'discover','hunts','completed','weights'}) do V.Rectangle(parent,1+(i-1)*segment,1,segment,3,V.Palette(key).accent,'BORDER') end
end
function V.Card(parent,kind)
 return ForeverCompanionInterface.Surface(parent,{background=C.panel,border=C.border})
end
function V.Style(button,kind,active) ForeverCompanionInterface.StyleButton(button,V.Palette(kind),active) end
function V.Tint(texture,color) texture:SetColorTexture(unpack(color)) end
function V.Compact(parent,width,height,kind)
 local p=V.Palette(kind);ForeverCompanionInterface.Surface(parent,{background=V.colors.panel,border=V.colors.border})
 V.Rectangle(parent,0,0,width,26,{.055+p.accent[1]*.08,.06+p.accent[2]*.08,.09+p.accent[3]*.08,1})
 V.Rectangle(parent,0,0,3,height,p.accent,'BORDER')
 V.Rectangle(parent,0,0,width,2,p.accent,'BORDER')
end
V.slotIcons={'INV_Helmet_03','INV_Jewelry_Necklace_03','INV_Shoulder_05','INV_Chest_Chain_07','INV_Belt_06','INV_Pants_03','INV_Boots_05','INV_Bracer_07','INV_Gauntlets_05','INV_Jewelry_Ring_02','INV_Jewelry_Ring_02','INV_Jewelry_Talisman_07','INV_Jewelry_Talisman_07','INV_Misc_Cape_02','INV_Sword_04','INV_Shield_06','INV_Weapon_Bow_07'}
