## 3.11.1-beta (develop, November 2, 2026; mock-tested only)
- Fixed dashboard recommendations that updated an untemplated Button instead of its visible FontString, and added optional full-text hover tooltips.
- Added a two-line read-only data provenance footer for current/cached/unavailable quest snapshots, profession detection and manually entered material quantities.
- Prevented zone-less quests from being mislabeled as a known zone and from disappearing under the current-zone filter; expanded mixed/unknown-zone regression coverage.
- Added `/fc open <section>`, direct `/fc <section>` navigation and `/fc status` with no game-state mutation.
- Improved gilded hover rails and graduated progress bars; made the offline dashboard preview display the actual mocked data-source label and manifest version.
- Expanded UI regression tests and live-client checklist. Passing offline CI is **not** proof of compatibility, safety, or CurseForge approval.

## 3.11.0-beta (development branch, November 2, 2026; not client-verified)
- Replaced generic quest-list buttons with native dark fantasy journal rows, including quest title, zone, ready/active status, focus highlight, and optional read-only objective tooltip.
- Added persistent quest sorting (log, zone, ready) with UI selector and `/fcq sort`; preserved the underlying quest-log indices and addon-only focus selection.
- Preserved known objective completion flags from modern and Classic quest APIs, displaying completion counts only when the client actually reports them.
- Fixed a sparse-slot bug in modern profession scanning and added a guarded Classic skill-line fallback for standard English trade skills.
- Styled profession handbook navigation with gold-accented icon tabs.
- Made dashboard recommendations real clickable guide shortcuts, added native ornamental trim and framed crest, and reset Today's Focus on confirmed day changes.
- Added live level-band information to the class hero and dynamic scaling for display/UI-scale changes.
- Expanded Lua smoke/UI tests and mock-derived preview validation. Fixed a Lua multiple-return-value bug discovered by CI.
- No game-client or CurseForge approval claims: Interface number, artwork, compatibility, licensing and final submission remain pending verification.

## 3.10.0-beta (development branch, not client-verified)
- Added native black-and-gold Quest Journal briefing cards: live quest totals, ready count, top zone, focused objective, and explicit stale/unavailable states.
- Added native Profession Skills and Material Goals cards with detected skill/cap bars, aggregate manual material progress, and selected-guide shortage advice.
- Reflowed quest filtering, paging, handbook buttons and material +/- controls below the new cards.
- Added 63 distinct class planning tips and 54 distinct profession planning tips. These are general Classic-era references, **not verified WoW Forever builds or recipes**.
- Hardened class, level, XP, zone and profession API reads and expanded mocked-client tests for failures, navigation, material changes and read-only guidance.
- Added grounded illustrative quest and profession PNG previews and snapshot artifacts to GitHub Actions.
- No automated combat, targeting, quest turn-ins, inventory movement or crafting was introduced.
- Still pending: real WoW Forever client testing, confirmed Interface number, original art, licensing decision, and CurseForge game flavor/moderation checks.

## 3.8.0-beta
- Expanded offline Lua regression suite to cover modern quest scanning, transient API failures, specialization preview cycling, and profession read failures.
- Clarified that empty profession reads may reflect unloaded data rather than an unlearned profession.
- All client API tests remain simulated; live Forever compatibility and account safety are not certified.

## 3.5.0-beta
- Added passive /fcdiag client build and API availability report.
- Added Overview compatibility summary for modern spellbook, talents, quests, professions and XP.
- Continued account-safety-first testing with no combat actions or automated gameplay.

## 3.4.0-beta
- Added a CI-enforced static release audit for manifest completeness and legacy API patterns.
- Expanded CurseForge moderation readiness and publication requirements based on official author guidance.
- Added release ZIP, client validation, licensing, and moderation acceptance test cases.
- CurseForge approval has not been requested or granted; live Forever client testing remains required.

## 3.2.0-beta
- Added guarded read-only spellbook inspection for candidate cooldown availability.
- Shows learned, not-found, or unverified states where spellbook API support permits.
- Avoids assuming compound/version-dependent abilities are learned and never performs casting.
- Added compatibility testing notes for actual-character spellbook versus previewed classes.

## 3.1.0-beta
- Connected multi-recipe ingredient demand to the existing manually owned material checklist.
- Added per-ingredient shortage calculations in the Professions tab.
- Added explicit /fcbridge preview and /fcbridge sync commands with quantity/capacity validation.
- Preserved owned quantities and unrelated checklist entries during sync; no automatic bag scanning.

## 3.0.0-beta
- Added 28 selectable specialization preview profiles across nine classes.
- Added context-aware role planning for five rotation modes and offensive, defensive, and utility cooldown usage.
- Added a specialization selector next to rotation modes with saved per-class selections and /fcspec commands.
- Expanded documentation and manual testing; spell priorities remain unverified for the Forever client.

## 2.1.0-beta
- Added per-profession manual recipe goals and per-recipe ingredient quantities.
- Aggregated material demand across outstanding crafts, accounting for recorded completion.
- Added /fcr chat commands for adding recipes, ingredients, progress and removal.
- Displayed recipe plans in the Professions handbook and added regression coverage.
- No verified Forever recipe database, bag scanning, or crafting automation is included.

## 2.0.0-beta
- Added in-window crafting material rows with current/needed/remaining quantities.
- Added plus/minus buttons for quick manual quantity updates and five-row pagination.
- Kept profession material lists separate and reset page on profession changes.
- Added test cases for quantity bounds, pagination, tab visibility, persistence, and layout.
- Recipe and inventory automation remain out of scope pending live-client verification.

## 1.7.0-beta
- Introduced persistent per-profession material planning with needed, owned and remaining quantities.
- Added /fcm commands to add, update and remove material entries.
- Added detected profession skill-stage guidance, with explicit verification limits.
- Connected progress and material checklists to profession handbook pages.
- Updated README and regression checklist; no recipe database or inventory automation is claimed.

## 1.1.0-beta (development; rotations not yet client-verified)
- Added Rotations.lua with beginner-friendly priority sequences for all nine original classes.
- Five selectable contexts per class: leveling, dungeon, boss, AoE and PvP.
- Added a rotation-mode button in the Leveling handbook.
- Sequences are general Classic-era teaching examples, not tested or optimized Forever-specific builds; icons per individual ability are not implemented yet.

## 1.0.0-beta (development milestone, not a stable release)
- Added AdvancedGuides.lua with nine original-class specialization overviews, core priorities, party guidance and progression checklists.
- Added five-stage introductory progression guidance for nine gathering and crafting professions.
- Integrated advanced content into the existing icon-backed class and profession handbook pages.
- Expanded in-game testing checklist for handbook coverage and long-page scrolling.
- Not yet included: verified Forever-specific talent builds, recipe IDs, material quantities, exact skill-level ranges, map routing, or confirmed client compatibility.

## 0.9.0-beta (source committed; live-client validation pending)
- Introduced class handbook sections for nine original classes, with icon references, leveling, dungeon, PvP and profession notes.
- Added selectable icon-backed profession handbook pages for nine gathering and crafting professions.
- Profession pages include beginner-friendly purpose, pairing suggestions and basic progression checklists.
- Existing role-specific tips remain in the leveling and dungeon sections.
- Exact talent builds, recipe IDs, material quantities, skill thresholds and Forever-specific changes are not yet verified or included.
- Icon availability and UI layout require testing on the target client.

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
