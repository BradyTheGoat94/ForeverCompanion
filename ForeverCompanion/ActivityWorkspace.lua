-- Alt and Legacy planning panels. Checklist ticks are manual and character-local.
local A={}
ForeverCompanionActivityWorkspace=A
local U=ForeverCompanionInterface
local root,navigate,getDB,heading,subheading,help
local tiles,actions,checks={},{},{}
local current,currentPage
local viewByPage,viewButtons={},{}
local altTasks={
 {'Rested XP','Check the character XP bar before deciding which alt to level.'},
 {'Bags and mail','Review available bag space, mailed gear and bank supplies.'},
 {'Training and gear','Check available spells and equip gear for this character before leaving town.'},
}
local pages={
 Legacy={
  heading='Legacy milestones',desc='Account-wide points  /  Per-character perks',
  milestones={
   {'Class level','25 / 45 / 60','INV_Misc_Book_09','These class milestones award one point each under the launch rules.'},
   {'Profession skill','150 / 225 / 300','Trade_BlackSmithing','Eligible non-gathering primary professions award points at these skill milestones.'},
   {'Launch cap','16 points','INV_Shield_05','The launch rules allow a single character to reach the account point cap. Use the in-game Legacy panel for current rules and earned points.'},
  },
  actions={{'Plan an alt','Alts','INV_Misc_Head_Human_01'},{'Open profession goals','Professions','Trade_BlackSmithing'},{'Find available training','Training','INV_Misc_Book_11'}},
  references={
   {title='Open Legacy',body='Earn a point at level 25 or 150 skill in an eligible primary profession. Open the Legacy shield or press Y.'},
   {title='Spend points',body='Choose perks separately for each character. Account point totals unlock cosmetic rewards. Use the client to check eligibility and current thresholds.'},
   {title='Launch guide',body='Blizzard launch reference\nhttps://worldofwarcraft.blizzard.com/en-us/news/24307383'},
  },
 },
 Alts={
  heading='Alt preparation',desc='Planning checklist for this character',
  milestones={
   {'Rested XP','Well Rested','Spell_Nature_Sleep','Review Well Rested in the in-game Legacy panel and confirm your current rested XP.'},
   {'Talent planning','Talented','Spell_Holy_MagicalSentry','Review Talented and the available talent choices on this character.'},
   {'Class challenges','25 / 45 / 60','INV_Misc_Map_01','Review level milestones and class challenges in your game client.'},
  },
  actions={{'Plan a leveling session','Plan','INV_Misc_Map_01'},{'Check bank and mail','Bank','INV_Misc_Bag_10'},{'Find a dungeon','Dungeons','INV_Weapon_ShortBlade_01'}},
  references={
   {title='Character perks',body='Review Well Rested for rested XP and Talented for earlier talents. Legacy perk selections are per character.'},
   {title='Prepare an alt',body='Check rested XP, bags, class training and dungeon requirements before heading out.'},
   {title='Launch guide',body='Blizzard launch reference\nhttps://worldofwarcraft.blizzard.com/en-us/news/24307383'},
  },
 },
}
local function label(parent,x,y,w,size,color)
 local f=U.Text(parent,size,color);f:SetPoint('TOPLEFT',x,y);f:SetWidth(w);return f
end
local function button(parent,x,y,w,h,action)
 local b=U.Button(parent);b:SetPoint('TOPLEFT',x,y);b:SetSize(w,h);b:SetScript('OnClick',action);return b
end
local function texture(parent,x,y,size)
 local t=parent:CreateTexture(nil,'ARTWORK');t:SetPoint('TOPLEFT',x,y);t:SetSize(size,size);t:SetTexCoord(.07,.93,.07,.93);return t
end
local function openCurrent()
 if current then ForeverCompanionReferenceWorkspace.Open(current.heading,current.references) end
end
function A.Create(parent,openPage,db)
 navigate,getDB=openPage,db
 root=CreateFrame('Frame',nil,parent);root:SetPoint('TOPLEFT',8,-6);root:SetSize(770,306);U.Surface(root)
 heading=label(root,16,-12,495,19,U.palette.accent)
 subheading=label(root,16,-39,495,12,U.palette.muted)
 help=button(root,595,-20,159,26,openCurrent);help:SetText('Planning details')
 U.SetHoverHelp(help,'Planning details','Open the full reference for this page.')
 for i,entry in ipairs({{'practice','Practice'},{'notes','Research notes'}}) do
  local key=entry[1]
  local control=button(root,357+(i-1)*120,-20,112,26,function()
   viewByPage[currentPage]=viewByPage[currentPage]~=key and key or nil
   ForeverCompanionRefresh()
  end)
  control:SetText(entry[2])
  U.SetHoverHelp(control,entry[2],key=='practice' and 'Show the optional practice checklist below this panel.' or 'Open your private research notes and source fields below this panel.')
  viewButtons[key]=control
 end
 for i=1,3 do
  local x=16+(i-1)*248
  local tile=CreateFrame('Frame',nil,root);tile:SetPoint('TOPLEFT',x,-70);tile:SetSize(242,72)
  U.Surface(tile);tile:EnableMouse(true)
  tile.icon=texture(tile,12,-18,35)
  tile.caption=label(tile,56,-13,174,12,U.palette.muted)
  tile.value=label(tile,56,-34,174,17,U.palette.text)
  U.SetHoverHelp(tile,'Milestone',function() return tile.note or '' end)
  tiles[i]=tile
  local action=button(root,x,-156,242,40,function(self) if self.target then navigate(self.target) end end)
  action.icon=texture(action,8,-7,26)
  local text=action:GetFontString();text:ClearAllPoints();text:SetPoint('LEFT',action,'LEFT',42,0);text:SetPoint('RIGHT',action,'RIGHT',-8,0);text:SetJustifyH('LEFT')
  U.SetHoverHelp(action,'Open tool',function() return action:GetText() end)
  actions[i]=action
  local check=button(root,x,-241,242,37,function()
   local saved=getDB()
   if type(saved.checks)~="table" then saved.checks={} end
   if type(saved.checks.Alts)~="table" then saved.checks.Alts={} end
   saved.checks.Alts[i]=not saved.checks.Alts[i]
   A.Render('Alts')
  end)
  U.SetHoverHelp(check,altTasks[i][1],altTasks[i][2])
  checks[i]=check
 end
 A.checklistHeading=label(root,16,-215,520,13,U.palette.muted)
 root:Hide()
end
function A.Render(page)
 if not root then return end
 current=pages[page]
 root:SetShown(current~=nil)
 if not current then return end
 currentPage=page
 heading:SetText(current.heading);subheading:SetText(current.desc)
 for key,control in pairs(viewButtons) do U.StyleButton(control,nil,viewByPage[page]==key) end
 local isAlt=page=='Alts'
 root:SetHeight(isAlt and 298 or 216)
 for i,tile in ipairs(tiles) do
  local data=current.milestones[i]
  tile.caption:SetText(data[1]);tile.value:SetText(data[2]);tile.icon:SetTexture('Interface\\Icons\\'..data[3]);tile.note=data[4]
  local entry=current.actions[i]
  actions[i]:SetText(entry[1]);actions[i].target=entry[2];actions[i].icon:SetTexture('Interface\\Icons\\'..entry[3])
 end
 local db=getDB()
 local saved=type(db.checks)=='table' and db.checks.Alts or nil
 local complete=0
 for i,check in ipairs(checks) do
  local done=type(saved)=='table' and saved[i]==true
  if done then complete=complete+1 end
  check:SetShown(isAlt)
  check:SetText((done and 'Done  /  ' or '')..altTasks[i][1])
  U.StyleButton(check,nil,done)
 end
 A.checklistHeading:SetShown(isAlt)
 A.checklistHeading:SetText('Preparation  /  '..complete..' of '..#checks)
end
function A.View(page) return viewByPage[page] end
function A.GetHeight()
 return current and root:GetHeight() or 0
end
