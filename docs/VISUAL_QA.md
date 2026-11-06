# Visual QA and beta release gate

Scope: world map, minimap, quest navigation, DPS meter, and party indicators.
This is a testing checklist, not a claim of live-client verification.

## Visual system
- Midnight/navy panels; cyan navigation accents; gold directional/focus accents.
- High contrast for text against map terrain and meter fills.
- Blizzard class colors remain recognizable in combat rows.
- No external map addon required. Original/Clear map styles remain available.

## World map
- [ ] Confirm the toolbar does not overlap map controls at 720p, 1080p, 1440p and UI scales 0.65/1.0.
- [ ] Check quest marker, town service and party marker z-order and hover tooltips.
- [ ] Check zoom, pan, zone changes and opening/closing the map.
- [ ] Confirm custom raid/party markers exclude the local player and hide for unavailable map coordinates.
- [ ] Validate arrow orientation with two grouped characters facing north, east, south and west.
- [ ] Verify original terrain and Clear style do not apply the atlas grid.

## Minimap
- [ ] Confirm /fcparty status identifies available native radius/position APIs.
- [ ] Verify native Blizzard party dots remain unchanged when /fcparty off.
- [ ] With /fcparty on, verify correct range at every minimap zoom level.
- [ ] Compare rotation with rotateMinimap off/on and cardinal facings.
- [ ] Test indoor floors, different instances, combat and raid conversion.
- [ ] Verify markers do not obscure minimap buttons or native party dots.
- [ ] Keep opt-in until actual client calibration passes.

## Quest navigation
- [ ] Confirm direction arrow remains legible over bright/dark terrain.
- [ ] Verify straight-line distance label is explicitly not a pathing guarantee.
- [ ] Verify closing the arrow clears the active destination.
- [ ] Test multiple quests, missing location data and town services.

## DPS meter
- [ ] Check 4/8/12 rows, narrow/wide sizes, screen edges, and UI scale.
- [ ] Verify names, amounts and class-color fills remain legible.
- [ ] Check row hover, selected details, and detail panel edge docking.
- [ ] Confirm current, past, overall, healing, damage, and interrupt views.
- [ ] Ensure no secret-value arithmetic or combat automation.

## Automated checks
- Lua 5.1 syntax: `find ForeverCompanion tests -name '*.lua' -print0 | xargs -0 -n1 luac5.1 -p`
- Smoke: `lua5.1 tests/offline_smoke.lua`
- Both must pass on GitHub Actions before tagging a beta.

## Known limitations
- High-resolution terrain rendering is **not implemented**; atlas style adds an overlay to Blizzard terrain.
- Party minimap coordinates/rotation are **not live-client verified** and may be unsupported.
- The visual changes are code-level improvements; screenshots and in-game QA remain outstanding.


## November 6 beta implementation pass — verify in game

- **Quest completeness:** Compare the Quests tab total against the native quest log with headers expanded and collapsed. The planner now prefers read-only `C_QuestLog.GetQuestLogQuests` when present, falling back to indexed `GetInfo`; do not assume the API exists in Forever. Verify objective completion and a quest with no coordinates.
- **Quest UI:** Rows now show known completed objectives out of the total, and tooltips display up to 12 objectives. Check narrow UI scales for clipping and verify the count does not imply unknown objectives are completed.
- **Combat meter:** Test /fcmeter compact, standard, expanded; confirm class icon atlas coordinates, player-name alignment, right-side values, click-to-open details, and Blizzard API availability. Visual bars use the native meter only; class icon availability may vary by client.
- **Town POIs:** With compatible Forever QuestieDB data installed, banks, auction houses, flight masters, inns and mailboxes stay visible at broad map scale; generic vendors, repairs and trainers appear on closer zoom (canvas scale >= 1.25). Zoom and pan repeatedly; confirm markers are anchored correctly. This is not a complete verified census of every NPC/vendor.
- **Minimap:** Existing experimental party markers remain opt-in and rely on native radius API; there is no new minimap terrain renderer or guarantee that all town POIs appear on the minimap.
- **Release gate:** Run `lua5.1 tests/offline_smoke.lua` and verify the addon in the Forever client. GitHub commits alone do not establish client compatibility.
