-- Draft allocations are stored in addon SavedVariables and never applied in game.
local P={}
ForeverCompanionTalentPlanner=P

-- Editorial milestones. Each name is checked against the matching data tree.
P.milestones={
 WARRIOR={{"Deep Wounds","Sweeping Strikes","Mortal Strike"},{"Cruelty","Death Wish","Bloodthirst"},{"Last Stand","Defiance","Shield Slam"}},
 PALADIN={{"Illumination","Holy Shock","Light's Vigil"},{"Templar's Bulwark","Holy Shield","Shieldsworn"},{"Seal of Command","Sacred Arbiter","Unsealed Wrath"}},
 HUNTER={{"Unleashed Fury","Summon Hawk","Bestial Wrath"},{"Careful Aim","Trueshot Aura","Sniper Shot"},{"Savage Strikes","Expose Prey","Lacerating Strikes"}},
 ROGUE={{"Malice","Cold Blood","Mutilate"},{"Precision","Blade Flurry","Adrenaline Rush"},{"Initiative","Preparation","Death Mark"}},
 PRIEST={{"Improved Power Word: Shield","Penance","Power Infusion"},{"Improved Renew","Holy Binding","Prayer of Mending"},{"Spirit Tap","Mind Flay","Shadowform"}},
 SHAMAN={{"Elemental Focus","Lightning Overload","Lightning Mastery"},{"Thundering Strikes","Stormstrike","Maelstrom Weapon"},{"Tidal Focus","Nature's Swiftness","Riptide"}},
 MAGE={{"Arcane Concentration","Arcane Blast","Arcane Power"},{"Ignite","Heating Up","Combustion"},{"Improved Frostbolt","Ice Lance","Ice Barrier"}},
 WARLOCK={{"Improved Corruption","Siphon Life","Wrack"},{"Demonic Embrace","Demonic Brand","Demonic Pact"},{"Bane","Conflagrate","Incinerate"}},
 DRUID={{"Insect Swarm","Eclipse","Moonkin Form"},{"Feral Swiftness","Leader of the Pack","Shifting Power"},{"Improved Rejuvenation","Swiftmend","Wild Growth"}},
}
local bear={"Thick Hide","Lacerate","Natural Reaction"}

-- Suggested opening investments, in order. These are starting points for
-- leveling and leave later ranks for the player to choose.
local openings={
 WARRIOR={{"Improved Rend","Deflection","Improved Overpower"},{"Cruelty","Unbridled Wrath"},{"Shield Specialization","Anticipation"}},
 PALADIN={{"Spiritual Focus","Healing Light"},{"Redoubt","Precision"},{"Benediction","Conviction"}},
 HUNTER={{"Endurance Training","Focused Fire"},{"Lethal Attacks","Careful Aim"},{"Improved Tracking","Savage Strikes"}},
 ROGUE={{"Malice","Improved Slice and Dice"},{"Efficient Strikes","Coup de Grace","Precision"},{"Opportunity","Improved Ambush"}},
 PRIEST={{"Twin Disciplines","Mental Strength"},{"Improved Renew","Holy Specialization","Divine Fury"},{"Spirit Tap","Improved Shadow Word: Pain"}},
 SHAMAN={{"Concussion","Convection"},{"Thundering Strikes","Mental Dexterity"},{"Tidal Focus","Improved Healing Wave"}},
 MAGE={{"Improved Channeling","Arcane Concentration"},{"Accelerant","Ignite"},{"Improved Frostbolt","Ice Shards"}},
 WARLOCK={{"Improved Corruption","Suppression","Improved Life Tap"},{"Demonic Embrace","Fel Vitality"},{"Bane","Improved Shadow Bolt","Cataclysm"}},
 DRUID={{"Improved Wrath","Improved Moonfire"},{"Ferocity","Feral Swiftness"},{"Nature's Focus","Heart of the Wild","Reflection"}},
}
local bearOpening={"Ferocity","Furor","Thick Hide"}
local index={}
for class,data in pairs(ForeverCompanionTalentData.classes) do
 local nodes={}
 for _,node in ipairs(data.nodes) do nodes[node[1]]=node end
 index[class]=nodes
end

function P.Budget(level)
 local points=0
 for at,count in pairs(ForeverCompanionTalentData.pointsByLevel) do
  if at<=level then points=points+count end
 end
 return points
end

local function ranks()
 local db=ForeverCompanionDB
 if type(db.talentPlans)~="table" then db.talentPlans={} end
 return db.talentPlans
end

function P.Load(class,spec)
 local store=ranks()
 local key=class..":"..spec
 local allocation=type(store[key])=="table" and store[key] or {}
 store[key]=allocation
 return allocation
end

function P.Total(class,allocation,tree,beforeRow)
 local count=0
 for _,node in ipairs(ForeverCompanionTalentData.classes[class].nodes) do
  if (not tree or node[2]==tree) and (not beforeRow or node[3]<beforeRow) then
   count=count+P.Rank(allocation,node)
  end
 end
 return count
end

function P.Rank(allocation,node)
 local value=allocation[node[1]]
 return type(value)=="number" and value>=1 and value<=node[6] and value%1==0 and value or 0
end

local function unlock(class,allocation,node)
 if P.Total(class,allocation,node[2],node[3])<node[5] then
  return false,"Spend "..node[5].." points in earlier rows of this tree."
 end
 for _,id in ipairs(node[10] or {}) do
  local parent=index[class][id]
  if not parent then return false,"Prerequisite is missing from the data snapshot." end
  if P.Rank(allocation,parent)<parent[6] then return false,"Max "..parent[9].." first." end
 end
 return true
end

function P.CanAdd(class,allocation,node,budget)
 if P.Rank(allocation,node)>=node[6] then return false,"Talent is already maxed." end
 if P.Total(class,allocation)>=budget then return false,"No points left at this plan level." end
 return unlock(class,allocation,node)
end

function P.Change(class,allocation,node,delta,budget)
 local id=node[1]
 local rank=P.Rank(allocation,node)
 if delta==1 then
  local ok,why=P.CanAdd(class,allocation,node,budget)
  if not ok then return false,why end
  allocation[id]=rank+1
 elseif delta==-1 and rank>0 then
  allocation[id]=rank>1 and rank-1 or nil
  for _,other in ipairs(ForeverCompanionTalentData.classes[class].nodes) do
   if P.Rank(allocation,other)>0 and not unlock(class,allocation,other) then
    allocation[id]=rank
    return false,"Refund "..other[9].." first."
   end
  end
 else
  return false,"No rank to refund."
 end
 return true
end

local function findNodes(class,tree,names)
 local result={}
 for _,name in ipairs(names) do
  for _,node in ipairs(ForeverCompanionTalentData.classes[class].nodes) do
   if node[2]==tree and node[9]==name then result[#result+1]=node;break end
  end
 end
 return result
end

function P.Goals(class,tree,spec)
 return findNodes(class,tree,spec=="Guardian / Bear" and tree==2 and bear or P.milestones[class][tree])
end

function P.Opening(class,tree,spec)
 return findNodes(class,tree,spec=="Guardian / Bear" and tree==2 and bearOpening or openings[class][tree])
end

function P.LoadOpening(class,tree,spec,allocation,budget)
 if P.Total(class,allocation)>0 then return false,"Reset the current draft before loading an opening." end
 for _,node in ipairs(P.Opening(class,tree,spec)) do
  while P.Change(class,allocation,node,1,budget) do end
 end
 if P.Total(class,allocation)==0 then return false,"Choose a higher level to plan your first point." end
 return true
end

function P.Recommendation(class,spec)
 local choices=ForeverCompanionTalentRecommendations[class]
 return choices and choices[spec]
end

function P.CopyRecommendation(class,spec,allocation)
 local recommendation=P.Recommendation(class,spec)
 if not recommendation then return false,"No recommended build for this specialization." end
 if P.Total(class,allocation)>0 then return false,"Reset your draft before copying this build." end
 for id,rank in pairs(recommendation[3]) do allocation[id]=rank end
 return true
end
