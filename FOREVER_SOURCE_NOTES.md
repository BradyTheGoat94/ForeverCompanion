# Verified Forever facts versus provisional guide advice

Updated: 2026-11-02. These notes document **published information**, not successful verification in a running game client.

## Blizzard-published information

- Blizzard's [Forever Camping preview (October 21, 2026)](https://worldofwarcraft.blizzard.com/en-us/news/24301516/gather-around-the-campfire-in-world-of-warcraft-forever) describes the Basic Campfire, its three starting feature slots, one contribution per player, one-minute rest/crafting requirement, one-hour shared cooldown, starter profession skill 20, and published camp-feature examples. The addon now shows **11 named examples** with their skill requirements and buff-stacking limitations. Mining is **not listed in the published sample table**; this does not prove Mining has no camp feature.
- Blizzard's [Forever What's Next recap (September 2026)](https://worldofwarcraft.blizzard.com/en-us/news/24303862/world-of-warcraft-forever-whats-next) describes the level 1–60 journey, revised classes, new quests, Legacy progression, Camping, and a November 4, 2026 launch. The article does not establish complete quest IDs, NPC coordinates, spell ranks, or trainer tables.
- Blizzard's [Forever new-player starter guide](https://worldofwarcraft.blizzard.com/en-us/news/24315280/einsteigerleitfaden-f%C3%BCr-neue-spieler-willkommen-bei-world-of-warcraft) explains two primary and three secondary professions and the professions interface.

## Published class deep dives (selected facts only)

The addon includes a small, explicitly provisional set of level-aware class changes for all nine classes, paraphrased from Blizzard's published beta articles. These are **not** comprehensive spell lists or claims that an ability is learned in the current character's spellbook.

- [Hunter and Druid — September 30, 2026](https://worldofwarcraft.blizzard.com/en-us/news/24301515/world-of-warcraft-forever-class-deep-dives-hunter-and-druid)
- [Priest and Warrior — September 30, 2026](https://worldofwarcraft.blizzard.com/en-us/news/24301514)
- [Mage and Shaman — October 7, 2026](https://worldofwarcraft.blizzard.com/en-us/news/24302097)
- [Rogue and Warlock — October 7, 2026](https://worldofwarcraft.blizzard.com/en-us/news/24310968/world-of-warcraft-forever-class-deep-dives-rogue-and-warlock)
- [Paladin — October 15, 2026](https://worldofwarcraft.blizzard.com/en-us/news/24302099)

## What is not yet verified

- All class rotations, talent optimizations, spell unlock levels, exact zone paths and encounter mechanics need checking against the actual Forever client.
- The 45 class leveling stages and dungeon/PvP readiness checklists are general practice guidance, not purportedly Blizzard-prescribed builds.
- The crafting planner uses manual material counts and does not claim complete recipe or auction-house data.
- The native mock-client snapshots are **illustrations**, not actual in-game screenshots.
- Client interface number in `ForeverCompanion.toc` remains unverified until someone reads the live client build.

## Content update rules

1. Include a source URL, date and a status label for any new Forever-specific fact.
2. Prefer Blizzard's official posts for feature rules, and client-verified records for spell/quest IDs.
3. Never turn a missing source row or unavailable API into a claim that content does not exist.
4. Recheck changed mechanics after the launch client is available.
5. Keep all guide controls read-only with respect to gameplay actions.

### Quest map and objective locations

The Blizzard world map can expose a next waypoint, quest POIs and native objective
boundaries independently. Companion draws the client boundary when available and
uses a ring to distinguish a reported destination point. A ring does not encode
an objective radius, NPC path or official quest boundary.

The optional [Forever QuestieDB](https://www.curseforge.com/wow/addons/questiedb)
is read at runtime through its [documented API](https://github.com/Questie/QuestieDB/blob/master/docs/api.md).
Only active quest records with matching titles are joined. Unfinished NPC,
object and item objectives must match the live objective type and text. Item
locations are from the provider's NPC and object drop relationships, without
drop rates. Unconfirmed phases, unsupported instance maps and unknown coordinates
are skipped. Forever-only quests missing provider locations rely on Blizzard
data. Neither QuestieDB nor its data is redistributed with Companion.

For developer reference, compare the Forever client
[quest API](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/QuestLogDocumentation.lua),
[native map boundary renderer](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_SharedMapDataProviders/QuestBlobDataProvider.lua)
and [QuestieDB Forever coverage notes](https://github.com/Questie/QuestieDB/blob/master/docs/forever-data.md).

### Rotation refresh

The spec-specific Dungeon and Boss cards retain their individual published
references in the guide notes. Leveling, AoE and PvP use practical conditional
instructions rather than claiming a single optimal build or fixed PvP sequence.
The game client supplies spell names, artwork and tooltips when available.

For Paladin, cross-check [Blizzard's Forever class overview](https://worldofwarcraft.blizzard.com/en-us/news/24303313),
[Wowhead Retribution](https://www.wowhead.com/forever/guide/classes/paladin/retribution/rotation-cooldowns-pve-dps)
and [Icy Veins Protection](https://www.icy-veins.com/wow-forever/protection-paladin-tank-pve-rotation-cooldowns-abilities).
The Protection card separates the long Righteous Fury threat buff from the
short Seal of Fury and explicitly identifies Judgement with that seal as a
taunt. The Retribution card labels the Unsealed Wrath swap as talent and
weapon dependent.

### Leveling route and direction display

The route is a list of suggested zones and level bands, independent of live quest
eligibility. Blizzard confirms the Zephras Isle and Riverglades ranges. The
remaining route choices were compared with Forever leveling references.
The live next step comes from the character's own quest log and known map
locations. A zone recommendation never sets a waypoint automatically.

- [Blizzard's Forever starter guide](https://worldofwarcraft.blizzard.com/en-us/news/24315280/)
- [Blizzard's Forever zone recap](https://worldofwarcraft.blizzard.com/en-us/news/24303862/)
- [The Forever Era leveling zones](https://theforeverera.com/en/guides/leveling/)
- [TopBuilds Forever leveling routes](https://topbuilds.gg/wow-forever/leveling/)
- [ForeverDB leveling guide](https://foreverdb.net/guide/leveling)
- [Forever map IDs in QuestieDB](https://github.com/Questie/QuestieDB/blob/master/support/Forever/Zones/areaIdToUiMapId.lua)

Navigation uses the Forever client map-position conversion and player-facing
APIs to draw a straight-line bearing. The overlay pauses when those values
cannot be read, and native map zoom preserves the original terrain artwork.
See Blizzard's [UI Add-On Development Policy](https://eu.forums.blizzard.com/en/wow/t/wow-user-interface-add-on-development-policy/1642).
