# Forever Companion 3.41.0-beta: review and update

Reviewed November 8, 2026 (America/New_York). Baseline: develop 815bfa4, followed by local 3.40.2 commit c66d607. Work remains on develop; main is outside this update.

## Review scope

Source and existing regression coverage for native meter data, map markers and services, objective matching, route planning, quest discovery/history, class and profession guidance, crafting, UI construction, refresh scheduling and release packaging. All shipped Lua modules receive syntax and manifest validation. Focused manual code review and new behavior changes concentrate on navigation, meter analysis, map lifecycle and refresh resilience. This is not an exhaustive proof of every branch of every module or a live gameplay audit.

## Research and implementation decisions

1. [Blizzard Forever meter API definitions](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/DamageMeterDocumentation.lua) declare session/source reads secret in combat and support GUID and creature-ID source parameters. Retain deferred spell inspection and public-only derived analysis. Added public creature identity fallback when rankings change. Presence in source does not establish target-client runtime success.
2. [Blizzard meter spell presentation](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_DamageMeter/DamageMeterEntry.lua) uses creatureName for pet spell labeling and exposes isPet metadata. Search preserves these distinctions, including fallback Pet Attack labels. Spell search is literal; pet-only filtering requires a supplied name or explicit pet flag. Unknown membership is never inferred from the word Attack alone. The live branch is a comparison reference, not a Forever compatibility certificate.
3. [Blizzard Forever map definitions](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/MapDocumentation.lua) expose optional player/world positions and waypoint capability checks. The HUD tolerates unavailable positions. It remains a straight-line bearing to the destination the player selects.
4. [Questie feature documentation](https://github.com/Questie/Questie) describes separate tracking, map and quest-action interactions. Adopted that interaction pattern through tracker Go, explicit map actions and service filtering. No Questie code or database is copied into the package.
5. [QuestieDB Forever provenance](https://github.com/Questie/QuestieDB/blob/master/docs/forever-data.md) records conversions and coverage audits. It does not establish a completed player walkthrough for this addon. Retain compatible-provider contracts, explicit objective matches and current-state checks. New routes are calculated from the current quest snapshot; no authored quest coordinates or universal availability claims were added.
6. [Details repository](https://github.com/Tercioo/Details-Damage-Meter) remains a presentation reference. This update adds searchable native spell analysis, not claimed Details feature parity or a replacement combat collection system.

The official Forever overview URL already recorded in FOREVER_SOURCE_NOTES.md returned HTTP 403 during this pass. Its contents were not newly verified. Existing published class guidance remains provisional. No new optimal rotation, talent ranking, recipe, drop-rate or zone walkthrough claim was introduced.

## Delivered behavior

- Meter: spell/pet search with Clear, Pets only, contribution/name/native sorting, full-set share denominators, stable public creature selection, coalesced native events and hidden-window scheduling avoidance. Existing docking, paging, two themes and secret-safe display remain.
- Questing: all/pinned/turn-in/focused route filters, approximate-distance/log order, optional map opening, tracker Go and /fc next. No matched objective returns a useful explanation instead of inventing a destination.
- Navigation: title dragging, saved placement, lock, small/standard/large sizes and reset through /fc arrow. Current-world-position loss hides the directional arrow and reports unavailable direction.
- Maps: per-category filters for banks, auction houses, flight masters, inns, repairs, vendors, trainers and mailboxes; Stop navigation; stale party blips cleared on invalid map/canvas states. Filters operate before clustering and do not relocate provider points.
- Reliability: callback failures are counted and reported without preventing unrelated queued panels from refreshing. Field-guide clicks re-resolve the live objective and exact location before navigation.

## Validation and practical limits

The acceptance entry point is `python tools/validate_all.py`. It covers Lua 5.1 syntax, 22 Lua suites, 15 Python tests, release/API/protected-action checks, metadata and package integrity. One Python case-collision test is skipped on Windows. New suites exercise HUD controls and stale party markers; expanded regressions cover literal spell search, secret names/amounts, pet identity, route filters, click-time completion changes, callback failures and event coalescing.

Offline native-widget previews were rendered and visually inspected for the populated breakdown, pet search, itinerary and map toolbar. Their names/data are explicitly synthetic fixtures kept under tests; no fixture or preview is packaged in the addon. Font metrics and game textures are approximated. Real-client screenshots, UI scale testing, populated group combat and taint/secret-value acceptance remain required.

## Remaining work after this candidate

| Area | Result of this pass | Remaining evidence needed |
| --- | --- | --- |
| Combat meter | Native data boundaries retained; search, sorting, identity and UI checks expanded | Solo/party/raid sessions, pet summons, damage taken/healing, reload and real fonts |
| Questing and routes | Live matching and stale-action checks expanded | Actual starter-zone playthroughs and terrain-aware travel validation |
| Maps and services | Real coordinates retained; filtering and stale-blip fixes | Outdoor/city maps, zoom and conflicting map addons in the client |
| Class/leveling advice | Existing sourced/provisional guidance regression checked | Current client spells, talents and balance evidence before recommending optimized builds |
| Professions/crafting | Existing manual-goal and planner suites retained | Complete verified recipes, trainer requirements and inventory integration |
| Performance | Event bursts merged; failures isolated and measurable | Comparable actual-client samples before any FPS or CPU improvement claim |
| Publishing | Versioned addon ZIP plus source and audit records | Manual in-game acceptance and any owner-chosen CurseForge submission |

## First in-game checks

1. Replace the addon folder with the packaged ForeverCompanion folder; retain SavedVariables. Confirm 3.41.0-beta in /fcdiag.
2. Open a player breakdown after combat. Search a spell and a pet name, toggle Pets only, change sort order, clear search and page through results.
3. Accept a real quest, then try tracker Go and /fc next. Test an objective finishing between display and click. Confirm no route is invented for unmatched locations.
4. Drag the arrow, change its size, lock it, reload and check placement. Use /fc arrow reset to recover the default position.
5. Toggle service types and change maps/zoom. Confirm previously visible party markers disappear on unsupported maps.
6. Start a performance sample, perform a consistent activity, refresh the report and record any failures with the first Lua error and client build.

CurseForge approval was not checked or changed. This candidate is not automatically uploaded or marked live-client verified.
