-- Offline mock of the WoW widget API; tests construction and render, not pixels.
local frames={}
local function widget(kind)
 local w={kind=kind,visible=true,children={},text=""}
 function w:SetText(v) self.text=tostring(v or "") end
 function w:GetText() return self.text end
 function w:Show() self.visible=true end
 function w:Hide() self.visible=false end
 function w:IsShown() return self.visible end
 function w:SetScript(name,fn) self[name]=fn end
 function w:RegisterEvent(name) self.events=self.events or {};self.events[name]=true end
 function w:CreateTexture() return widget("Texture") end
 function w:CreateFontString() return widget("FontString") end
 function w:SetColorTexture(...) self.color={...} end
 function w:SetTexture(v) self.texture=v end
 function w:SetPoint(...) self.point={...} end
 function w:SetSize(width,height) self.width=width;self.height=height end
 function w:SetHeight(height) self.height=height end
 function w:SetWidth(width) self.width=width end
 function w:LockHighlight() end
 function w:UnlockHighlight() end
 function w:SetScrollChild(child) self.child=child end
 function w:GetVerticalScroll() return 0 end
 function w:SetVerticalScroll() end
 function w:StartMoving() end
 function w:StopMovingOrSizing() end
 function w:EnableMouse() end
 function w:RegisterForDrag() end
 function w:SetMovable() end
 function w:SetClampedToScreen() end
 function w:SetResizable() end
 function w:SetBackdrop(...) end
 function w:SetBackdropColor(...) end
 function w:SetBackdropBorderColor(...) end
 function w:SetAllPoints() end
 function w:SetJustifyH() end
 function w:SetJustifyV() end
 function w:SetSpacing() end
 function w:SetTextColor() end
 function w:SetFontObject() end
 function w:SetNormalTexture() end
 function w:SetHighlightTexture() end
 function w:SetPushedTexture() end
 function w:ClearAllPoints() end
 frames[#frames+1]=w
 return w
end
CreateFrame=function(kind) return widget(kind) end
UIParent=widget("UIParent")
SlashCmdList={}
ForeverCompanionDB={welcomed=false}
UnitClass=function() return "Warrior","WARRIOR" end
UnitLevel=function() return 60 end
UnitXP=function() return 1500 end
UnitXPMax=function() return 3000 end
UnitName=function() return "PreviewCharacter" end
GetBuildInfo=function() return "OfflineMock","0","0",16001 end
print=function() end
local toc=assert(io.open("ForeverCompanion/ForeverCompanion.toc","r"))
local addon="ForeverCompanion"
for line in toc:lines() do
 if line:match("%.lua%s*$") then
  local chunk=assert(loadfile("ForeverCompanion/"..line))
  chunk(addon)
 end
end
toc:close()
local addonFrame
for _,f in ipairs(frames) do
 if f.events and f.events.ADDON_LOADED then addonFrame=f;break end
end
assert(addonFrame and addonFrame.OnEvent,"addon loaded handler missing")
addonFrame.OnEvent(addonFrame,"ADDON_LOADED",addon)
assert(#frames>50,"expected substantial UI frame tree")
assert(type(SlashCmdList.FOREVERCOMPANION)=="function","slash command missing")
SlashCmdList.FOREVERCOMPANION("class mage")
SlashCmdList.FOREVERCOMPANION("class auto")
SlashCmdList.FOREVERCOMPANION("role damage")
SlashCmdList.FOREVERCOMPANION("position reset")
SlashCmdList.FOREVERCOMPANION("")
local foundTitle=false
for _,f in ipairs(frames) do
 if f.text=="FOREVER COMPANION" then foundTitle=true end
end
assert(foundTitle,"main window title not rendered")
io.write("PASS: actual addon manifest loaded and core UI rendered in offline mock ("..#frames.." widgets)\n")
