# Changelog

## 0.5.2-beta (visual polish; live-client testing pending)
- Dark, higher-contrast panel with gold accent and improved status header.
- Compact and expanded guide window modes, saved per character.
- Active quest counter in the header.
- Quest-log display grouped by available zone metadata and sorted alphabetically.
- Ready-to-turn-in quest summary and shorter objective lists.
- Interface remains a prototype pending screenshot-based QA and client testing.

## 0.5.1-beta (prelaunch, API compatibility unverified)
- Added automatic read-only detection of active quests from the in-game quest log.
- Refreshes on world entry and quest-related events.
- Supports both C_QuestLog and legacy quest-log APIs where exposed.
- Displays available quest objectives and ready-to-turn-in state.
- Manual planner remains available for optional custom goals.
- Does not auto-accept, abandon, turn in or navigate quests.

## 0.5.0-beta (prelaunch source, not in-client tested)
- Added Quests tab and persistent manual quest planner (up to 100 entries).
- Track quest name, zone, and completion; list, complete, reopen and remove entries with `/fcq`.
- Added seven-tab layout with compact navigation.
- No copied Questie data, unverified quest locations, automatic tracking, or prohibited automation.

## 0.4.1-beta (prelaunch source, not in-client tested)
- Added in-window class preview and role cycling buttons.
- Persist window position per character and provide `/fc position reset`.
- Dynamically size guide scroll content.
- Harden saved-variable initialization and invalid tab recovery.
- Added automated Lua 5.1 syntax, manifest and packaging checks.
- Documented CurseForge submission requirements and release gates.

## 0.4.0-beta
- Initial class-aware six-tab guide browser.
- General leveling and dungeon reference content.
- Manual checklists and saved settings.

**Note:** The current manifest Interface value is provisional pending live-client verification.
