# 3.49 beta: beginner quest guidance, detailed maps, training and loot

The priority is accurate quest destinations and a clear next action. Quest Log
now has roomier pages, literal search by title/zone/objective/ID, and a direct
details/back flow. Source IDs and coordinates are optional in quest details.
Conflicting areas require a player choice before navigation. Generic client POIs
remain general quest points and are never assigned to an objective by guesswork.

Wrong reference points can be excluded per character in Location options.
Reports contain the quest ID, objective index, source entity/area, destination
and available player position. They stay local; copying is explicit. Restore
reverses exclusions. Storage is bounded to 100 reports.

## Reported quest cases

- Worgen in the Woods: regression fixtures distinguish #173, #221 and #222 by
  ID and exact live objective text. These use synthetic coordinates. No new
  Worgen coordinates were invented or certified in game. A location report from
  the affected player is still needed to diagnose a particular bad spawn.
- The Darkmoon Faire #7905/#7926: the opening event is documented in Elwynn
  November 9–15, 2026. During that window, client-calendar checks filter both
  reference and native destinations to the provider's Elwynn map mapping.
  Conflicting Kalimdor markers and navigation are rejected. Existing provider
  coordinates are used without further conversion. The rule expires and does
  not assume Alliance always means Goldshire, since the neutral event rotates.
  If the provider mapping is unavailable, conflicting travel is blocked rather
  than inventing a replacement coordinate.

## Overlay

`/fc overlay detailed` combines color, outdoor explored terrain and service
markers. `/fc overlay inspect` enables wheel zoom, panning and hover details.
Zoom is bounded to 1–4×. Locking restores click-through. My pos. recenters the
view. Base artwork and explored detail use separate native tile layouts with
the same viewport transform. Hover-only art is excluded. Exploration events
invalidate the cached art; no extra polling timer was added.

Player facing now uses counterclockwise texture rotation and corrects for world
versus artwork aspect ratios. Unknown facing/position hides the arrow. Zone
changes clear stale art and markers. Artwork remains client-owned; no game
textures are redistributed. Outdoor detail depends on the character's explored
map data, and location marker coverage depends on the native/provider data.

## Training

`/fc training` opens our own read-only Training Guide for all nine classes.
Reference levels/prices are separate from known spells, requirements, quest
rewards and actual observations at the currently open trainer. Higher learned
ranks cover earlier ranks. Unknown eligibility stays unknown. No training is
purchased and no trainer filters are changed. Find trainers lists reported
trainers and cannot guarantee the right trainer for the selected spell.

Static training data is adapted from fusionpit/WhatsTraining, commit
e7cca31746f853025b2429331715da2f7a9b14f4, Classes/Camelot and QuestSpells.lua.
The upstream MIT license and copyright are included in TrainingData.lua.
Upstream runtime/UI code is not bundled; the separate addon is not required.
Reference completeness and in-game API behavior still need client checks.

## Dungeons

The independent directory contains 34 dungeon/wing entries, including Stockades
and entries without imported drops. 129 new sourced loot records bring the
catalog to 256 records across 17 dungeons/wings. Rare/trash sources are explicit.
See LOOT_RESEARCH_2026_11_09.md for research coverage and unresolved tables.

## Validation limits

Offline Lua 5.1 logic/UI tests, source audits and ZIP validation do not certify
gameplay. Live acceptance must check the reported quests, turning in place in
all directions, explored outdoor maps at different zoom levels, trainer visits,
and loot tooltips. Main is unchanged; the work belongs on develop.

## Primary references

- https://github.com/fusionpit/WhatsTraining/tree/e7cca31746f853025b2429331715da2f7a9b14f4
- https://raw.githubusercontent.com/Questie/QuestieDB/master/docs/forever-data.md
- https://raw.githubusercontent.com/Gethe/wow-ui-source/forever/Interface/AddOns/Blizzard_SharedMapDataProviders/MapExplorationDataProvider.lua
- https://raw.githubusercontent.com/Gethe/wow-ui-source/forever/Interface/AddOns/Blizzard_TrainerUI/Mainline/Blizzard_TrainerUI.lua
- https://raw.githubusercontent.com/Gethe/wow-ui-source/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/AreaPoiInfoDocumentation.lua
- https://raw.githubusercontent.com/Gethe/wow-ui-source/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/DateAndTimeDocumentation.lua
- https://www.wowhead.com/forever/guide/darkmoon-faire-event-overview-guide
