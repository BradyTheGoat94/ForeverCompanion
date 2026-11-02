-- Blizzard's published Forever Camping preview, October 21 2026.
-- Source: https://worldofwarcraft.blizzard.com/en-us/news/24301516/gather-around-the-campfire-in-world-of-warcraft-forever
-- Preview facts are not a live API scan and may change after launch.
-- This module never places camp objects, crafts items, or triggers protected actions.
ForeverCompanionCampingGuide={}
local C=ForeverCompanionCampingGuide
C.source="Blizzard Forever Camping preview (2026-10-21)"
C.features={
 Alchemy={item="Mana Well",skill=20,effect="Resting allies regenerate 10-29 mana per 5 sec (scales with level); conflicts with Blessing of Wisdom."},
 Blacksmithing={item="Sharpening Wheel",skill=20,effect="Grants 6-34 Strength by level; does not stack with Strength of Earth Totem."},
 Enchanting={item="Enchanted Lute",skill=20,effect="Grants scaling armor, attributes and resistances; does not stack with Mark of the Wild."},
 Engineering={item="Reagent Bot",skill=20,effect="Provides a reagent vendor at the campsite."},
 Herbalism={item="Incense Candle",skill=20,effect="Grants 2-25 Intellect by level; does not stack with Arcane Intellect."},
 Leatherworking={item="Camp Tent",skill=20,effect="Adds rested XP worth 5% of a level unless the player already has more rested XP."},
 Skinning={item="Camp Chair",skill=20,effect="Grants 2% spell and attack critical chance; conflicts with Moonkin Aura."},
 Tailoring={item="Faction Banner",skill=20,effect="Grants 14-32 Spirit by level to your faction; conflicts with Divine Spirit."},
 Cooking={item="Basic Campfire",skill=1,effect="Allows cooking and up to three other campsite features."},
 ["First Aid"]={item="First Aid Kit",skill=20,effect="Grants 3-56 Stamina by level; conflicts with Power Word: Fortitude."},
 Fishing={item="Fishing Bowl",skill=20,effect="Grants 8% to attributes; conflicts with Blessing of Kings."},
}
function C.Format(name)
 local feature=C.features[name]
 local lines={"CAMPING - OFFICIAL PUBLISHED PREVIEW",C.source}
 if feature then
  lines[#lines+1]=name..": "..feature.item.." (profession skill "..feature.skill..")"
  lines[#lines+1]=feature.effect
 else
  lines[#lines+1]=name=="Mining" and "Mining: no specific camp feature listed in the published sample; do not assume none exists." or "No published sample camp feature for this profession."
 end
 lines[#lines+1]="Requires a nearby campfire; published features share a 1-hour cooldown."
 lines[#lines+1]="Camp benefits require sitting or crafting nearby for at least one minute."
 lines[#lines+1]="Starter features can be obtained through early quests or profession trainers; verify actual unlocks in-game."
 return table.concat(lines,"\n")
end
function C.FormatOverview()
 return "FOREVER CAMPING: Campfire supports 3 contributed features initially; one per player. Features begin at skill 20 for most professions. Published higher-skill (140+) features may come from dungeons/raids. Check live client for changes."
end
