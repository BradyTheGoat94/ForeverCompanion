# 3.30 development update — 2026-11-08

## Using unaccepted quest markers

Open the world map, choose **Map: All**, and leave **Pickups: On**. Yellow exclamation icons represent quests you have not accepted. Hover for quest titles and the quest giver; click to start navigation. When several pickups share a marker, Shift-click selects the next quest and ordinary click navigates to that selected giver.

Blizzard-reported pickups work without a database. Broader outdoor-zone and town coverage requires the separately installed **Forever QuestieDB** provider with public contract 4 support. Its coordinates are read through the public API; no quest-giver locations are invented or bundled from another game flavor.

Background indexing is spread over timer batches. Hover Pickups for a loading or missing-provider message. Active and completed quests are excluded from database pickups, as are unmet level, race, class, supported prerequisite, exclusive-choice, parent and breadcrumb checks. NPC and object quest givers are supported. Item-drop starts, unknown coordinates and phase-restricted spawns are not assigned guessed map locations. Skyborne race masks retain values above 32 bits.

A database reference is not proof the NPC will offer the quest: profession, reputation, seasonal conditions and some unusual chain rules still need in-game confirmation. Previously completed repeatable quests rely on native reporting. Native records take precedence over duplicate database locations.

## Interface work

- Shared dark buttons with restrained highlights replace default buttons in the meter, Journey and map toolbar.
- Metric and combat-session menus allow explicit choices.
- Spell analysis uses wider rows, separate amount/share areas, inspectable-total sorting, clear empty states and stacked statistics. Player selection follows a public GUID through ranking changes and closes when that identity can no longer be verified.
- Journey has compact zone cards and an Up Next queue with journal actions.

## Verification

All addon modules compile under Lua 5.1. Twelve Lua smoke suites pass, including the full mocked UI. Coverage includes pickup eligibility and provider indexing, native precedence, invalid coordinates, clustering, Shift-click selection, navigation, toggling, source identity after rank changes, metric menus, spell sorting/pagination and secret-safe native display.

Python packaging tests pass with the existing filesystem-dependent case-collision test skipped on Windows. Package validation, no-combat-automation audit, curated legacy-API audit and guide preflight pass.

Actual Forever-client visual and API acceptance is still pending. The older `release_audit.py` gate still reports pre-existing timer scheduling and quest-arrow/ring asset review issues; this development package does not waive those findings.

## Sources consulted

- https://github.com/Questie/QuestieDB/blob/master/docs/api.md — public getters, ownership, provider masks and contracts.
- https://github.com/Questie/Questie/blob/master/Database/QuestieDB.lua — quest eligibility relationships; independently implemented here.
- https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/DamageMeterDocumentation.lua — native meter data.
