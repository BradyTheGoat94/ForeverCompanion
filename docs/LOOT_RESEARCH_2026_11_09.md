# Dungeon loot research — November 9, 2026

129 factual item/source/slot/ID records were added in LootExpansion.lua. Each
record retains an item URL and an encounter URL. These are source references,
not our own observed drops. No drop rates or completeness claims are inferred.
Duplicate item IDs across distinct dungeon sources are intentional; wishlist
and acquisition flags remain keyed to the item.

| Dungeon/wing | New records | Evidence |
| --- | ---: | --- |
| The Stockade | 21 | Forever guide and linked item pages |
| Gnomeregan | 29 | Forever guide, linked item pages, reactor effect linking item #9492 |
| Razorfen Kraul | 32 | Forever guide and linked item pages |
| Scarlet Monastery: Graveyard | 25 | Forever guide and linked item pages |
| Scarlet Monastery: Library | 15 | Guide and Arcanist Doan NPC drop list (#6487) |
| Scarlet Monastery: Armory | 2 | Herod NPC drop list (#3975) |
| Scarlet Monastery: Cathedral | 2 | Whitemane NPC drop list (#3977) |
| Razorfen Downs | 3 | Amnennar NPC drop list (#7358) |

Guide roots: https://www.icy-veins.com/wow-forever/the-stockade-guide,
https://www.icy-veins.com/wow-forever/gnomeregan-guide,
https://www.icy-veins.com/wow-forever/razorfen-kraul-guide,
https://www.icy-veins.com/wow-forever/scarlet-monastery-graveyard-guide,
https://www.icy-veins.com/wow-forever/scarlet-monastery-library-guide.
Individual links are retained beside each imported record.

Important corrections: some guide links resolve to spell effects rather than
items. Those IDs were not imported as items. Electromagnetic Gigaflux Reactivator
was resolved through its effect's Used By Items entry to item #9492. Guide slot
typos are not a reason to change an item's actual equipment slot. The Scarlet
Key from the chest behind Doan is not listed as a Doan boss drop. Workshop Key,
cloth and quest-object drops were not added to the equipment catalog.

## Remaining gaps and research coverage

The dungeon directory is independent of the loot table, so these gaps no longer
make the dungeons disappear. A short NPC drop list does not prove that other
items cannot drop; it establishes only that this checked source is incomplete.

| Area | Research outcome / remaining work |
| --- | --- |
| Stockades, Gnomeregan, Razorfen Kraul, Graveyard, Library | Source guide equipment and trash rows imported; live drop verification remains pending. |
| Armory, Cathedral, Razorfen Downs | Small native database drop lists support the imported rows; full encounter coverage is still missing. |
| Uldaman | Archaedas #2748 page exposed a quest object only; no equipment imported from that response. |
| Zul'Farrak | Gahz'rilla #7273 page exposed a quest object only; other sites warn that many items are absent from current beta data. |
| Maraudon | Princess #12201 page was unavailable in this pass; broad sources carried Classic tables. No unverified table imported. |
| Temple of Atal'Hakkar | Eranikus #5709 page did not establish equipment drops; Classic association warnings remain. |
| Blackrock Depths | Emperor #9019 page listed quest objects/currency; no verified full equipment table obtained. |
| Lower Blackrock Spire | Wyrmthalak #9568 page listed quest objects/currency; full equipment coverage unresolved. |
| Upper Blackrock Spire | Drakkisath #10363 page listed quest objects/currency; external catalogs explicitly use Classic data. |
| Dire Maul East/West/North | Alzzin #11492 and Immol'thar #11496 pages lacked equipment evidence; King Gordok #11501 unavailable. |
| Scholomance | Gandling #1853 page listed quest objects/currency; full equipment table unresolved. |
| Stratholme | Rivendare #10440 response did not establish equipment; other catalogs explicitly mark many missing items. |
| Drowned City, Krol'dok, Alcaz Prison, Shaper's Terrace | Announcement/directory and targeted loot searches did not provide a sufficiently supported item-ID/encounter table for import. |
| Blackmaw Hold | A recent third-party guide reports five new items. We could not establish the complete IDs and encounter associations from primary database pages during this pass, so those claims remain unimported. |

NPC evidence URLs use https://db.icy-veins.com/wow-forever/npcs/ followed by the
ID above. Broad cross-checks included Wowhead's Forever dungeon directory,
GearInsight's Forever tables and wowtbc.gg's Forever tables. The latter explicitly
warns that returning-dungeon associations come from Classic Era and may have
moved. Several other sites republish AtlasLoot/CMaNGOS tables. Those were not
treated as verified Forever drops or copied wholesale.

Directory sources:
- https://www.wowhead.com/forever/guide/dungeons-overview-locations-details
- https://news.blizzard.com/en-us/article/24301455/explore-the-new-dungeons-of-world-of-warcraft-forever

Useful unresolved cross-checks:
- https://wowtbc.gg/warcraftforever/loot-tables/dungeons/scarlet-monastery-armory/
- https://gearinsight.app/wow/en/forever/dungeons/zulfarrak
- https://gearinsight.app/wow/en/forever/dungeons/upper-blackrock-spire
- https://gearinsight.app/wow/en/forever/dungeons/stratholme
- https://conquestcapped.com/guides/wow-forever/wow-forever-blackmaw-hold-guide/

This pass substantially expands coverage but does not establish correct,
complete loot tables for every remaining dungeon. New direct client evidence or
source-reviewed database rows are needed to close the remaining gaps.
