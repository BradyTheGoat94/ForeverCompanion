## 0.8.0-beta (source only; target client unverified)
- Added one-click quest filters: all, ready for turn-in, and current zone (where zone metadata is exposed).
- Live quest header shows active and ready counts; filters preserve the underlying quest log.
- Added role-specific tank, damage and healer preparation guidance to Leveling and Dungeons.
- Added Auto Class button to restore real class detection after previewing another class.
- Reduced focused quest label width to avoid overlapping quest navigation buttons.
- No map pins, verified quest coordinates, or automatic navigation included.

## 0.7.0-beta (source committed; live-client verification pending)
- Added up to 15 clickable quest rows per page, with previous/next page navigation.
- Selecting a quest displays its focused details and objective text.
- Retains quest-log auto-detection and manual personal notes.
- Added detailed quest/UI regression tests for launch-day verification.
- Client API compatibility, layout behavior and actual quest-log accuracy remain unverified.

# Changelog

## 0.6.1-beta (prelaunch, client testing pending)
- Previous/Next quest browsing and focused quest details.
- Shows available quest objectives and status from the game quest log.
- Added legacy texture API fallbacks and optional UI method checks.
- No quest route map or quest database is claimed.

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
