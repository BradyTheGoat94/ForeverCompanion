# 3.29 sprint verification — 2026-11-08

Implemented on `develop` only. No third-party addon code or coordinates were copied.

## Implementation references

- Blizzard Forever DamageMeter generated API and native session-window patterns: https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/DamageMeterDocumentation.lua and https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_DamageMeter/DamageMeterSessionWindow.lua
- Details bar text, width and per-window layout concepts: https://github.com/Tercioo/Details-Damage-Meter/blob/master/API%20UI.txt
- Recount native tracker reference: https://github.com/Resike/Recount/blob/main/Tracker_DamageMeter.lua
- Blizzard tracking texture paths used by HandyNotes: https://github.com/Nevcairiel/HandyNotes/blob/master/HandyNotes_HandyNotes.lua
- Forever QuestieDB contracts and flavor boundary: https://github.com/Questie/QuestieDB/blob/master/docs/api.md and https://github.com/Questie/QuestieDB/blob/master/docs/forever.md

## Automated verification

All addon modules compile with Lua 5.1. Existing offline, loot, icon/gear, study-board, notebook and quest-location smoke suites pass. The full mocked UI loads the real addon manifest and exercises map switching, service clustering and waypoint interactions.

New regression suites cover:

- `combat_meter_ui_smoke.lua`: compact/standard/expanded geometry, overlay frame levels, opaque secret values passed directly to native display widgets, spell pagination, healing view, and no breakdown inspection in combat.
- `service_clusters_smoke.lua`: cross-category clusters, stable real-coordinate representatives, zoom separation and invalid coordinates.
- `journey_route_smoke.lua`: pin and turn-in priority, current-log membership, nearest alternative, deduplication and absent positions.
- `quest_pickups_smoke.lua`: only native titled pickups, excluding active quests, duplicates, wrong maps and invalid coordinates.

Python packaging/automation tests: 11 pass, one filesystem-dependent collision test skips on Windows because differently cased files cannot coexist. That collision test continues to run on Linux CI.

Manifest/package builder, legacy-API audit, guide preflight and combat-automation audit pass.

## Remaining release gates and coverage limits

The separate older `release_audit.py` still rejects existing `C_Timer.After` scheduling calls and the pre-existing QuestDirectionArrow/QuestLocationRing assets. This sprint does not waive that audit or declare a production release.

No running Forever client was available. Offline tests cannot establish actual font rendering, UI scale, native secret propagation, GPU draw ordering, or API availability on the installed game build. Test `/fcmeter compact`, `standard`, `expanded`, both skins, four and twelve rows, 280 and 500 widths, all native metrics, history navigation and the player spell pane in the client. Verify long names and numbers, right-edge docking, unavailable APIs, and combat transitions.

Service coverage follows the installed Forever QuestieDB provider. No new service coordinates were invented. Mailboxes appear only if the provider supplies documented service records; no mailbox object database was fabricated. Clusters retain each real destination; Shift-click selects a member, then normal click starts navigation. Confirm artwork paths and icon sizes in the client.

Quest pickups require native `GetQuestsOnMap` start records plus a native title. No eligibility, unlock or prerequisite inference is made. Suggested quest stops use approximate normalized map distance, one destination per quest, and never claim terrain-aware routing. Dungeon, class and alternate-character additions are preparation guidance, not verified new unlock rules or a complete authored leveling route.
