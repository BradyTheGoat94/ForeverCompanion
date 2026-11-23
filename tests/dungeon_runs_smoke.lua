local frames={}
CreateFrame=function()
 local f={RegisterEvent=function() end,SetScript=function(self,key,cb) self[key]=cb end}
 frames[#frames+1]=f;return f
end
local now,kind,zone=100,"none","World"
local charLevel,charXP,charMax=32,950,1000
local guid,petName,petLevel,petXP,petMax="pet-A","Patches",31,500,1000
GetTime=function() return now end
GetServerTime=function() return 1000+now end
GetInstanceInfo=function() return zone,kind,1,"Normal",5,nil,nil,47 end
UnitLevel=function(unit) return unit=="pet" and petLevel or charLevel end
UnitXP=function() return charXP end
UnitXPMax=function() return charMax end
GetPetExperience=function() return petXP,petMax end
UnitGUID=function() return guid end
UnitName=function() return petName end
YOU_LOOT_MONEY="You loot %s."
LOOT_MONEY_SPLIT="Your share of the loot is %s."
YOU_LOOT_MONEY_GUILD="You loot %1$s. Guild gains %2$s."
GOLD_AMOUNT="%d Gold"
SILVER_AMOUNT="%d |4Silver:Silver pieces;"
COPPER_AMOUNT="%d Copper"
LOOT_ITEM_SELF="You receive loot: %s."
LOOT_ITEM_SELF_MULTIPLE="You receive loot: %1$sx%2$d."
LOOT_ITEM_PUSHED_SELF_MULTIPLE="Received %2$d of %1$s!"
local cloth="|cffffffff|Hitem:2589::::::::|h[Linen Cloth]|h|r"
local other="|cffffffff|Hitem:2592::::::::|h[Wool Cloth]|h|r"
dofile("ForeverCompanion/SessionProgress.lua")
dofile("ForeverCompanion/DungeonRuns.lua")
local R=ForeverCompanionDungeonRuns
assert(R.Coin("You loot 4 Gold, 3 Silver pieces, 5 Copper. Guild gains 9 Gold.")==40305)
assert(R.Coin("Your share of the loot is 8|TInterface\\MoneyFrame\\UI-SilverIcon:0:0|t.")==800)
assert(R.Coin("Another player loots 1 Gold.")==nil)
assert(select(4,R.Loot("Received 3 of "..cloth.."!"))==3)
assert(R.Loot("Another player just received "..cloth..".")==nil)
local function event(name,...) local last=frames[#frames];last.OnEvent(last,name,...) end
event("PLAYER_ENTERING_WORLD",true,false)
assert(not R.View() and not R.Save())
kind,zone="party","Razorfen Kraul"
event("PLAYER_ENTERING_WORLD",false,false)
assert(R.View().name==zone and not R.View().partial)
event("CHAT_MSG_MONEY","You loot 2 Gold, 8 Copper.")
event("CHAT_MSG_MONEY","Your share of the loot is 7 Silver.")
event("CHAT_MSG_MONEY","Another player loots 1 Gold.")
event("CHAT_MSG_LOOT","You receive loot: "..cloth.."x4.")
event("CHAT_MSG_LOOT","You receive loot: "..cloth..".")
event("CHAT_MSG_LOOT","Another player loots "..other..".")
charXP=0;event("PLAYER_XP_UPDATE","player") -- transient same-level rollback during level-up
charLevel,charXP,charMax=33,20,1200;event("PLAYER_LEVEL_UP",33)
petXP=710;event("UNIT_PET_EXPERIENCE","pet")
guid,petName,petXP="pet-B","Scout",13;event("UNIT_PET","player")
petXP=32;event("UNIT_PET_EXPERIENCE","pet")
guid,petName,petXP="pet-A","Patches",710;event("UNIT_PET","player")
petXP=750;event("UNIT_PET_EXPERIENCE","pet")
event("ENCOUNTER_END",120,"A boss",1,5,0)
event("ENCOUNTER_END",120,"A boss",1,5,1)
event("LFG_COMPLETION_REWARD")
now=145
local saved=assert(R.Save())
assert(saved.ongoing and saved.complete and saved.seconds==45 and saved.coins==20708 and not saved.coinUnknown)
assert(saved.xp==70 and #saved.pets==2 and saved.pets[1].xp==250 and saved.pets[2].xp==19)
assert(#saved.items==1 and saved.items[1].count==5 and #saved.bosses==1 and saved.bosses[1].defeated and saved.bosses[1].wipes==1)
event("CHAT_MSG_LOOT","You receive loot: "..other..".")
assert(#R.History()[1].items==1,"saved archive must not mutate as a run continues")
now=203;kind,zone="none","World";event("PLAYER_ENTERING_WORLD",false,false)
event("CHAT_MSG_LOOT","You receive loot: "..other..".");event("CHAT_MSG_MONEY","You loot 7 Gold.")
local last=assert(R.Save("last"))
assert(not last.ongoing and last.coins==20708 and #last.items==2 and last.items[2].count==1)
assert(last.seconds==103 and #R.History()==1 and R.History()[1].id==saved.id)
kind,zone="party","Razorfen Kraul";event("PLAYER_ENTERING_WORLD",false,true)
assert(R.View().partial and #R.View().items==0)
assert(R.Save().id~=saved.id and #R.History()==2)
print("PASS: dungeon results preserve observed loot, coin, player and per-pet XP, bosses and post-exit snapshots without duplicate saves")

