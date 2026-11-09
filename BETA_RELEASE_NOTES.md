# Forever Companion 3.49.1-beta release notes (draft)

Training Guide now has a sidebar entry below Class Guides and a cleaner spell/rank/level/price layout. Main scrolling panels are clipped above the footer to address the reported route overlap. `/fc training` also opens the guide. Live-client verification remains pending.

- Add 1–4× overlay zoom, drag-to-pan inspection, hover details, location actions and native landmarks. Locked mode stays click-through.
- Draw the native explored-terrain layer in outdoor zones, including power-of-two edge cropping. Add Detailed preset and exploration refresh events.
- Correct player-arrow facing direction and compensate for differences between world and artwork proportions; align marker projection with zoom/pan.
- Add a nine-class Training Guide using MIT-licensed What's Training Forever reference data, spellbook checks, rank coverage, search, requirements, quest rewards and read-only current-trainer observations. `/fc training`.
- Give quest rows more room, add literal quest/zone/objective/ID search and a focused details/back flow. Distinguish same-title chain parts by quest ID.
- Require an explicit area choice for cross-map or widely separated objective references. Add reversible per-character bad-location exclusions and copyable local reports.
- For Faire breadcrumbs #7905/#7926, filter destinations to the documented Elwynn opening camp on November 9–15, 2026, using the client calendar and provider map mapping. This rule expires; no permanent faction-based event location is assumed.
- Separate the dungeon directory from loot imports: 34 dungeon/wing entries remain visible even without imported loot. Add Stockades and Sunken Temple search aliases.
- Add 129 source-attributed loot records across Stockades, Gnomeregan, Razorfen Kraul, four Scarlet Monastery wings and Razorfen Downs: 256 total across 17 dungeons/wings. Rare and trash sources stay explicit; no drop rates inferred.
- Automated offline checks cover these changes. In-game location, artwork, training and loot verification remains pending; Worgen coordinates have not been independently verified.


## Minimap launcher

A new minimap crest button opens/closes the addon on left-click. Right-click for options and drag to reposition it. Restore with `/fc minimap`; hide with `/fc minimap hide`; reset with `/fc minimap reset`. Position and visibility persist per character. In-game verification remains pending.

## Reliability and usability pass

Map search now reuses its index while typing and supports Up/Down, Enter and Escape. Failed destination changes keep the previous navigation. Panels fit smaller windows, overlay art clears promptly after zone changes, service actions use current records, and personal notes gain starring plus session-only Undo delete. In-game verification remains pending.

## Map companion search and compact travel

Use `/fc map` or the movable Map button to search notes, active quests and current-zone service references. `/fc recent` revisits successful destination choices. Personal notes now have categories, icons and colors; the arrow options offer a compact travel strip. Optional combat fading is available in overlay options, with `/fc overlay auto` returning to automatic fading after a manual visibility override. In-game verification remains pending.

## Map tools update

Open `/fc notes` for personal map notes and nearby services. `/fc note <name>` saves your current position; `/fc nearest repair` offers current-zone repairs. Other service types include mail, inn, flight, vendor, bank, auction and trainer. `/fc overlay exploring`, `questing` and `town` apply coordinated presets. Location evidence is clearer, and the arrow has a nearby-arrival cue plus a manual Another objective action. In-game acceptance remains pending.

## Transparent map overlay

Use `/fc overlay` to toggle; `/fc overlay options` adjusts opacity, size and markers. Drag with `/fc overlay edit`, then `/fc overlay lock`. This uses translucent native zone art and needs in-game beta verification.

## What the beta includes

- Read-only leveling, class, specialization, dungeon and profession guide surfaces.
- Illustrated ability priorities and class study checklists. These are **not** verified optimal Forever rotations.
- Spellbook-aware skill availability with explicit uncertain states when client APIs are incomplete.
- Manual recipe targets, ingredient requirements, progress, material forecasts, prioritized craft queues, and gathering shortages.
- Character profession skill/cap guidance where the client API supplies values.
- Nine class-specific leveling curricula, level-aware official Forever zone/talent milestones, and selected source-attributed Blizzard class-change previews (not verified live spellbook unlocks).
- Blizzard-published Camping feature reference for 11 professions, including skill requirements and buff conflicts; manual profession readiness remains clearly distinguished from actual item ownership.
- Role-aware dungeon preparation and class PvP checklists; these are practice guidance, not verified optimized builds.
- Dark-fantasy black-and-gold interface with original gilded inlays on quest and profession cards, class focus tooltips, and compact-mode support.

## Known limitations

- The curated spell reference covers only a subset of Warrior abilities. Officially published class changes are a **small preview**, not complete spell or talent tables, and require live client validation.
- Recipes, trainers, skill-up probabilities and unlocks are not claimed to be a complete Forever database.
- Inventory counts and crafting goals are entered manually; the addon does not scan bags for the planner.
- Guides do not cast spells, automate gameplay, buy items or craft for the player.
- The interface version, addon ZIP and visuals require verification in the live client before public release.

## Reporting problems

Include the addon version, Forever client build, class, profession, the tab you opened, reproduction steps and the first Lua error (if any). Never include account credentials.

## Release status

**Candidate under development — not approved for public upload.** See `BETA_RELEASE_GATE.md` for the required acceptance checklist.

## 3.41 update

Spell search, pet-only analysis, route filters, direct objective navigation, movable arrow controls, service filters and refresh resilience. See CHANGELOG.md and docs/SPRINT_3_41.md. This candidate has not been uploaded to CurseForge or verified in the game client.

## 3.42 update

New observed leveling session tracker with pause/resume and bounded saved summaries; temporary itinerary deferrals; persistent discovery preferences; explicit selection menus; stale pickup and catalog navigation checks. See docs/SPRINT_3_42.md.

## 3.43 map update

Compact map dock, searchable Service Atlas, configurable service pins and local merchant-visit records. Current provider references remain distinct from approximate visited positions. See docs/SPRINT_3_43.md for source, setup and acceptance details.
