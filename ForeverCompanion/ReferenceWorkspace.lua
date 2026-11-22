-- Contextual reference browser. Each topic keeps its complete source text.
local R={}
ForeverCompanionReferenceWorkspace=R
local U=ForeverCompanionInterface
local window,windowTitle,windowBrowser
local maxRows=6

function R.Topic(value)
 if type(value)=='table' then return value.title,value.body end
 local label,body=value:match('^([^\n:]+):%s+(.+)$')
 if label and #label<=46 then return label,body end
 label,body=value:match('^([^:\n/]+) / (.+)$')
 if label and #label<=40 then return label,body end
 local first=value:match('^[^\n]+') or value
 if first~=value and #first<=64 then return first,value:sub(#first+2) end
 return first,value
end

local function label(parent,x,y,width,size,value,color)
 local widget=U.Text(parent,size,color);widget:SetPoint('TOPLEFT',x,y);widget:SetWidth(width);widget:SetText(value or '')
 return widget
end
local function button(parent,x,y,w,h,value,action)
 local widget=U.Button(parent);widget:SetPoint('TOPLEFT',x,y);widget:SetSize(w,h);widget:SetText(value);widget:SetScript('OnClick',action)
 return widget
end

function R.CreateBrowser(parent,width,height)
 local browser={rows={},items={},index=1,page=1}
 local frame=CreateFrame('Frame',nil,parent)
 frame:SetSize(width,height)
 browser.frame=frame
 local leftWidth=206
 local pane=CreateFrame('Frame',nil,frame)
 pane:SetSize(width-leftWidth-10,height);pane:SetPoint('TOPLEFT',leftWidth+10,0);U.Surface(pane)
 local function showContent(reset)
  local item=browser.items[browser.index]
  browser.title:SetText(item and item.title or 'No details available')
  browser.body:SetText(item and item.body or '')
  local size=math.max(browser.scroll:GetHeight(),browser.body:GetStringHeight()+12)
  browser.body:SetHeight(size);browser.child:SetHeight(size)
  if reset then browser.scroll:SetVerticalScroll(0) end
  browser.scrollHint:SetShown(size>browser.scroll:GetHeight())
 end
 local function repaint(reset)
  local pageCount=math.max(1,math.ceil(#browser.items/maxRows))
  browser.page=math.max(1,math.min(browser.page,pageCount))
  for n,row in ipairs(browser.rows) do
   local index=(browser.page-1)*maxRows+n
   local item=browser.items[index]
   row.item=item;row.index=index;row:SetShown(item~=nil)
   if item then
    row:SetText(item.title)
    U.StyleButton(row,nil,index==browser.index)
   end
  end
  browser.previous:SetEnabled(browser.page>1);browser.next:SetEnabled(browser.page<pageCount)
  browser.pageText:SetText(pageCount>1 and (browser.page..' / '..pageCount) or '')
  if reset then showContent(true) end
 end
 for i=1,maxRows do
  local row=button(frame,0,-(i-1)*40,leftWidth,36,'',function(self)
   if not self.item then return end
   browser.index=self.index
   repaint(true)
  end)
  local caption=row:GetFontString()
  caption:SetJustifyH('LEFT');caption:SetWordWrap(true);caption:SetHeight(31)
  row:EnableMouseWheel(true)
  row:SetScript('OnMouseWheel',function(_,delta) browser.page=browser.page+(delta<0 and 1 or -1);repaint(false) end)
  U.SetHoverHelp(row,'Open topic',function() return row.item and row.item.title or '' end)
  browser.rows[i]=row
 end
 browser.previous=button(frame,0,-246,72,25,'Previous',function()
  browser.page=browser.page-1;repaint(false)
 end)
 browser.next=button(frame,134,-246,72,25,'Next',function()
  browser.page=browser.page+1;repaint(false)
 end)
 U.SetHoverHelp(browser.previous,'Previous topics','Go back one page in the topic list.')
 U.SetHoverHelp(browser.next,'More topics','Browse the next page in the topic list.')
 browser.pageText=label(frame,75,-252,56,11,'',U.palette.muted);browser.pageText:SetJustifyH('CENTER')
 browser.title=label(pane,14,-11,width-leftWidth-38,15,'',U.palette.accent)
 browser.title:SetWordWrap(true);browser.title:SetHeight(42);browser.title:SetJustifyV('TOP')
 local scroll=CreateFrame('ScrollFrame',nil,pane)
 scroll:SetSize(width-leftWidth-40,height-81);scroll:SetPoint('TOPLEFT',14,-58);scroll:EnableMouseWheel(true)
 local child=CreateFrame('Frame',nil,scroll)
 child:SetSize(width-leftWidth-40,height-81);scroll:SetScrollChild(child)
 local text=label(child,0,0,width-leftWidth-44,13)
 text:SetWordWrap(true);text:SetJustifyV('TOP')
 if text.SetSpacing then text:SetSpacing(4) end
 scroll:SetScript('OnMouseWheel',function(_,delta)
  scroll:SetVerticalScroll(math.max(0,math.min(child:GetHeight()-scroll:GetHeight(),scroll:GetVerticalScroll()-delta*32)))
 end)
 browser.scroll,browser.child,browser.body=scroll,child,text
 browser.scrollHint=label(pane,14,-height+16,width-leftWidth-40,10,'Mouse wheel for more',U.palette.muted)
 browser.scrollHint:SetJustifyH('RIGHT')
 function browser:SetItems(values,key)
  local items={}
  for _,value in ipairs(values or {}) do
   if type(value)=='table' or (type(value)=='string' and value~='') then
    local title,body=R.Topic(value)
    if title and body then items[#items+1]={title=title,body=body} end
   end
  end
  local previousItem=self.items[self.index]
  local keyChanged=self.key~=key
  if keyChanged or not items[self.index] then self.index,self.page=1,1 end
  self.items,self.key=items,key
  local current=self.items[self.index]
  local changed=not previousItem or not current or previousItem.title~=current.title or previousItem.body~=current.body
  repaint(keyChanged or changed)
 end
 frame:Hide()
 return browser
end

function R.Open(title,values)
 if not window then
  local name='ForeverCompanionReferenceFrame'
  window=CreateFrame('Frame',name,UIParent,'BackdropTemplate')
  window:SetSize(790,445);window:SetPoint('CENTER');window:SetFrameStrata('DIALOG')
  U.Surface(window);U.PreparePanel(window,name,790,445)
  windowTitle=label(window,16,-13,700,20)
  U.CloseButton(window,function() window:Hide() end)
  windowBrowser=R.CreateBrowser(window,754,374);windowBrowser.frame:SetPoint('TOPLEFT',18,-54)
 end
 windowTitle:SetText(title)
 window:Show()
 windowBrowser.frame:Show()
 windowBrowser:SetItems(values,title)
end
