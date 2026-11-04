-- Pure presentation data checks: Blizzard class crops and named spell resolution.
SlashCmdList={}
dofile('ForeverCompanion/GuideData.lua')
dofile('ForeverCompanion/Icons.lua')
dofile('ForeverCompanion/Rotations.lua')
dofile('ForeverCompanion/SpecPlanner.lua')
dofile('ForeverCompanion/GearStats.lua')
ForeverCompanionDB={}
local I,G=ForeverCompanionIcons,ForeverCompanionGearStats
local texture={SetTexture=function(self,v) self.path=v end,SetTexCoord=function(self,...) self.coords={...} end}
local regions={}
local standard=0
for class,choices in pairs(ForeverCompanionSpecs) do
 I.ApplyClass(texture,class)
 assert(texture.path==I.classTexture,'class must use Blizzard class sheet: '..class)
 assert(texture.coords[1]<texture.coords[2] and texture.coords[3]<texture.coords[4])
 local region=table.concat(texture.coords,',');assert(not regions[region],'class regions must be distinct');regions[region]=true
 for index,choice in ipairs(choices) do
  local spec=choice[1];local profile=G.Get(class,spec)
  assert(profile and #profile.order>=4,'missing stat profile '..class..' / '..spec)
  assert(profile.source:match('^https://www%.wowhead%.com/forever/') or profile.source:match('^https://www%.icy%-veins%.com/wow%-forever/'))
  ForeverCompanionDB.specSelections=ForeverCompanionDB.specSelections or {};ForeverCompanionDB.specSelections[class]=index
  local text=table.concat(G.Lines(class),'\n')
  assert(text:find(spec,1,true) and text:find(profile.source,1,true),'selected spec and provenance must be shown')
  assert(text:find('NOT LIVE-TESTED',1,true) and text:find('not a numerical stat weight',1,true),'source review must not become validation')
  if spec~='Guardian / Bear' then standard=standard+1 else assert(text:find('unconfirmed planner label',1,true)) end
 end
end
assert(standard==27,'standard stat profile coverage')
assert(not G.Get('UNKNOWN','Fury') and not G.Get('WARRIOR','Unknown'))
I.ApplyClass(texture,'UNKNOWN');assert(texture.path==I.unknown and texture.coords[2]==1)
local requests={}
C_Spell={GetSpellTexture=function(name) requests[#requests+1]=name;return 12345 end}
for class,contexts in pairs(ForeverCompanionRotations) do
 for mode,priorities in pairs(contexts) do
  for index,instruction in ipairs(priorities) do
   local cue,status=I.ApplyRotation(texture,class,mode,index)
   if cue then
    assert(instruction:lower():find(cue:lower(),1,true),'icon name must be named in actual instruction')
    assert(status=='spell' and texture.path==12345)
    assert(texture.coords[1]==0 and texture.coords[2]==1,'spell icon must reset class sheet crop')
   else
    assert(status=='class' and texture.path==I.classTexture,'general priorities show class emblems')
   end
  end
 end
end
local requested=#requests
I.ApplyRotation(texture,'PALADIN','leveling',1)
assert(#requests==requested,'generic blessing preparation must not invent a named spell')
for _,bad in ipairs({0,-1,math.huge,0/0,1.5,{},'https://example.invalid/icon'}) do
 C_Spell.GetSpellTexture=function() return bad end
 local cue,status=I.ApplyRotation(texture,'MAGE','leveling',2)
 assert(cue=='Frostbolt' and status=='unresolved' and texture.path==I.unknown)
end
C_Spell.GetSpellTexture=function() error('restricted') end
assert(not I.Spell('Frostbolt'))
C_Spell=nil;GetSpellTexture=function(name) assert(name=='Frostbolt');return 54321 end
assert(I.Spell('Frostbolt')==54321,'legacy texture lookup when modern API absent')
GetSpellTexture=nil;assert(not I.Spell('Frostbolt'))
print('PASS: nine distinct Blizzard class crops, named spell icons, crop resets, unavailable APIs and 27 sourced stat profiles plus conditional Bear')
