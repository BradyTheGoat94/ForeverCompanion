## 3.49.0-beta — Detailed maps, quest clarity, training and dungeon coverage

- Add 1–4× overlay zoom, drag-to-pan inspection, hover details, location actions and native landmarks. Locked mode stays click-through.
- Draw the native explored-terrain layer in outdoor zones, including power-of-two edge cropping. Add Detailed preset and exploration refresh events.
- Correct player-arrow facing direction and compensate for differences between world and artwork proportions; align marker projection with zoom/pan.
- Add a nine-class Training Guide using MIT-licensed What's Training Forever reference data, spellbook checks, rank coverage, search, requirements, quest rewards and read-only current-trainer observations. `/fc training`.
- Lead quest details with a plain-language next step; hide technical details and unrelated class controls. Give quest rows more room, add literal quest/zone/objective/ID search and a focused details/back flow. Distinguish same-title chain parts by quest ID.
- Require an explicit area choice for cross-map or widely separated objective references. Add reversible per-character bad-location exclusions and copyable local reports.
- For Faire breadcrumbs #7905/#7926, filter destinations to the documented Elwynn opening camp on November 9–15, 2026, using the client calendar and provider map mapping. This rule expires; no permanent faction-based event location is assumed.
- Separate the dungeon directory from loot imports: 34 dungeon/wing entries remain visible even without imported loot. Add Stockades and Sunken Temple search aliases.
- Add 129 source-attributed loot records across Stockades, Gnomeregan, Razorfen Kraul, four Scarlet Monastery wings and Razorfen Downs: 256 total across 17 dungeons/wings. Rare and trash sources stay explicit; no drop rates inferred.
- Automated offline checks cover these changes. In-game location, artwork, training and loot verification remains pending; Worgen coordinates have not been independently verified.

## 3.48.0-beta — Minimap launcher

- Added a crest button on the minimap. Left-click opens/closes the main addon; right-click offers map, overlay, hide and reset actions.
- Drag the button around the minimap edge; position and visibility persist per character. Uses no external library.
- Restore with /fc minimap, hide with /fc minimap hide, or reset with /fc minimap reset.

## 3.47.0-beta — Map reliability and usability pass

- Reuse the unified search index while typing, paging and selecting; invalidate on quest, zone, note and service-data changes. Refresh results explicitly rebuilds it.
- Add Up/Down selection, Enter activation, Escape closing and a visible selection rail in map search.
- Preserve the previous arrow when a new destination cannot start. Reconcile successful custom/native navigation so obsolete addon-owned pins/arrows do not conflict; preserve player-owned waypoints.
- Service revalidation returns the fresh record and distinguishes visited observations from provider references at the same coordinate.
- Fit search, notes and service panels to smaller viewports, react to scale changes and register with the native Escape panel stack.
- Clear old-zone overlay art on the faster player-update cycle, refit on viewport changes, and keep header controls within the map width.
- Add starred notes, starred filtering and one-session Undo delete. Recent-note entries deduplicate by stable note identity even if coordinates change.

## 3.46.0-beta — Search, organized notes and compact travel

- Added a unified Map Companion search for all personal notes, live active quests and reported services in the current zone. Supports literal multi-word queries, type filters, bounded results and source-aware navigation checks.
- Added a movable quick-access Map button, /fc map, /fc search <text>, and /fc recent.
- Added up to 20 recent successful destination choices per character, with source-specific resume checks, pause and clear controls. No movement trail or automatic travel is recorded.
- Added General, Farming, Rare sightings, Gathering and Reminders note categories, matching map icons/colors and category filtering. Existing notes default to General.
- Added a compact travel strip and source label alongside the full arrow display. Switching layouts preserves the chosen destination.
- Added optional combat fading for the transparent overlay, plus a session override. Fading defaults off and changes no targeting bindings.

## 3.45.0-beta — Map companion tools

- Cluster crowded overlay quest, service and note markers with count badges. World-map personal-note clusters offer destination choices and separate with zoom.
- Find nearby repairs, mail, inns, flight masters and other services using straight-line distance when available or explicitly approximate map proximity. Choose a result to navigate; stale records are revalidated.
- Distinguish objective search references, general client points, turn-ins and unavailable location coverage in the map, overlay and field guide.
- Add Exploring, Questing and Town overlay presets for opacity, size, color and marker layers.
- Save up to 100 named personal positions per character; rename, delete or navigate from the browser and world map.
- Add a nearby-arrival indicator and manual Another objective action. No quest progress changes or automatic navigation advancement.

## 3.44.0-beta — Transparent map overlay

- Added an independent click-through native zone map with adjustable opacity, size, monochrome art, saved position and an explicit drag/edit mode.
- Shows the player and focused quest; optional service markers respect map category filters.
- Toggle with /fc overlay or the expanded map dock. Options: /fc overlay options. Tab targeting remains unchanged.
- Missing map artwork or coordinates clear stale terrain/markers. Phase artwork changes refresh the tiles.

## 3.43.0-beta — Map dock and service atlas

- Replaced the large central map toolbar with a compact, draggable bottom-left dock. Expand its controls when needed; saved placement and a reset are available. Native map terrain is the default for new preferences; existing style choices remain supported. Atlas tint/grid are more restrained.
- Added a searchable Service Atlas from Find services, /fc services or /fc vendors. Search NPC names, specialties, service roles and IDs; filter by category/source, browse current or world-map zones, save favorites and navigate revalidated locations.
- Modernized service markers with slim category-colored borders, stable icon sizes, source pips, hover names, optional labels and tighter-cluster settings. Right-click a cluster to select a service, or Shift-click to cycle.
- Added unobtrusive current-view player coordinates with unavailable-state clearing. Coordinate updates do not rebuild the map overlay.
- Provider service records now retain NPC IDs, specialty text and source information. Duplicate service coordinates are removed. Rescan reads current data/corrections from the installed compatible Forever QuestieDB provider.
- Observed merchant visits supplement provider references. Records are per character, bounded to 100 NPC/map visits, can be disabled or cleared, and explicitly use the player's position during interaction rather than claiming an exact NPC coordinate. Distinct observations do not overwrite database references.
- Added click-time service and pickup-marker validation, provider-index completion refresh for the standalone atlas, and map-change handling.
- Added service-index/atlas coverage and populated UI checks for the atlas and collapsed/expanded map dock. Latest provider release checked: QuestieDB 1.0.13 Forever. Provider data is not bundled or automatically updated.

## 3.42.0-beta — Leveling sessions and flexible quest planning

- New My Leveling Session window from the Overview shortcut, /fc session and route options. Shows tracked time, observed XP, XP/hour, observed turn-ins, reported rewards and six recent turn-ins.
- Pause/resume excludes time, XP gains and quest rewards while paused. End & start new saves a summary; the ten latest manually ended sessions persist per character. Reload starts a fresh current session.
- XP/hour needs at least 60 seconds and complete public samples. Missing/backwards samples, skipped level thresholds and clock discontinuities suppress the rate. Reported quest rewards are separate from sampled XP and never double counted.
- Right-click a live itinerary step to set it aside temporarily. Restore from Route options or reload. Completion and removal clear obsolete deferrals; quest progress and watched quests remain unchanged.
- Discovery source, sort, near-level and zone preferences persist per character. Sort and atlas state choices use explicit menus.
- Pickup discovery and atlas giver navigation revalidate the current location at click time. Accepted/removed pickups, moved givers and changed maps cannot retain stale navigation.
- Added session state and populated UI regressions plus expanded route-deferral and stale-pickup checks. This candidate still requires live client acceptance.

## 3.41.0-beta — Quest navigation, meter analysis and map controls

- Search spell breakdowns by spell or pet name, switch to Pets only, and choose contribution, alphabetical or native ordering. Shares and coverage continue to use the full reported spell set. Secret names and amounts never enter string search or arithmetic.
- Preserve selected creature sources across ranking changes using public creature IDs when no public GUID is supplied. Keep pet labels in tooltips and retain the 3.40.2 docking/paging improvements.
- Filter the live itinerary to all, pinned, ready-to-turn-in or focused quests. Choose approximate distance or quest-log order. Save route preferences per character and optionally open the map on navigation.
- Navigate to the next matched objective from the tracker Go button, itinerary Next objective or /fc next. Revalidate the live quest and objective before navigating. General quest POIs remain separate from objective-specific targets.
- Move the navigation arrow by its title area. /fc arrow opens position lock, three size presets and reset; /fc arrow reset restores its initial position. Missing positions report direction unavailable.
- Filter eight map service categories before clustering. Add Stop navigation to the map toolbar. Retain original provider coordinates and built-in service artwork.
- Clear party-map markers before handling missing maps, invalid dimensions or unavailable positions. Reject invalid clustering dimensions and radii.
- Isolate failed queued panel refreshes, preserve other callbacks and error reporting, and expose failure counts in performance samples. Coalesce native meter event bursts; hidden meters do not enqueue updates.
- Field-guide navigation now revalidates completion and locations at click time.
- Added navigation-HUD and party-map suites plus route, search, secret-value, callback-failure, stale-navigation and synthetic populated-layout coverage. No test data ships with the addon.

## 3.40.2-beta — Breakdown navigation and pet clarity

- Added Dock to meter directly beside the Spells tab; disabled while already docked. Dragging still saves independent placement.
- Scroll the breakdown with the mouse wheel to page through spells. Page limits remain bounded as data changes.
- Spell ranks now continue across pages. Hover text preserves pet creature names and confirmed Pet Attack labels.
- Regression checks cover docking, wheel page limits, ranks and pet-label distinctions. Offline acceptance does not establish in-game compatibility.

## 3.40.1-beta — Movable player breakdown

- Drag the player breakdown title bar to position the analysis window independently of the meter. Saves the position per character and suppresses automatic side docking after manual movement.
- Added Reset breakdown position to meter options. Reset appearance and /fcmeter resetpos also restore automatic docking. The window remains screen-clamped and its close/paging controls remain separate from the drag region.
- Added regression coverage for dragging, position persistence during refresh/reopen and restoring automatic placement.

## 3.40.0-beta — Live objective itinerary and scoped performance sampling

- Added a live objective itinerary under Leveling Route. Plans individual unfinished objectives and known turn-ins from explicitly matched locations, instead of limiting the list to one stop per quest. General quest POIs remain separate.
- Prioritizes pins and turn-ins with approximate within-map distance when position is available; falls back to log order within priority groups when it is not. Reports unlocated steps, other-map steps and missing objective details. Planning is bounded to 40 displayed stops with the full mapped count retained.
- Route actions revalidate the current quest/objective/location before starting navigation. Completed steps, removed locations and stale snapshots cannot retain a navigation action. Paging and panel height follow actual visible results.
- Added meter/map/itinerary sampling scopes to /fc performance, with actual call counts and available clock timings. Reset with /fc performance reset; view the report from Settings or /fc performance window. Missing timings remain unknown, and overlapping scopes are not summed into an overall CPU claim.
- Added persisted 0.2/0.4/0.8 second native meter refresh settings. Secret/malformed saved rates use the public default; combat data handling and native reset restrictions are preserved.
- Added objective-route and UI navigation regressions, profiler scope/reset checks and refresh-setting validation. This is a data-grounded live itinerary, not a claimed playthrough-verified starter walkthrough. Populated native meter acceptance still requires the client.

## 3.39.0-beta — Quest setup and reliable acceptance checks

- Added Quest data & setup from the journal, Settings and /fc setup. Reports native support, compatible provider/contract, indexing, current-character map coverage and unknown completion eligibility without starting background scans.
- Next objective keeps player-started map navigation and opens the live objective field guide. Specialization and guide-role controls now expose explicit choice menus instead of cycling blindly.
- Coalesced visible-page refresh event bursts into a 50 ms frame queue, with idle teardown and safe handling of refreshes queued during a flush. /fc performance and /fcdiag report measured queued-work timing when a client clock is available; no FPS or overall CPU claims are inferred.
- Added one offline acceptance command used by all three workflows. Candidate version is checked against the TOC and submission handoff, not an obsolete hard-coded release.
- Reviewed original navigation texture formats/dimensions and existing read-only timer sites. New timer sites and unknown artwork still fail policy checks; protected-gameplay checks remain separate.
- Updated publishing records to project 1793299 and owner-reported pending review. 3.39 is a new candidate and has not been uploaded automatically. License decision and full client acceptance remain separate.
- Added setup, queue, choice-menu and negative release-policy tests. All 19 Lua suites and 14 Python tests pass; one Windows case-collision test is skipped.

## 3.38.1-beta — Header overlap fix

- Fixed the Combat Meter button overlapping the role selector on Class Guides. Meter, specialization and role now occupy three separate header slots with consistent heights and spacing.
- Other pages retain their existing meter position. Added regression checks for header separation in both compact and expanded modes.

## 3.38.0-beta — Full interface review and reading layouts

- Replaced class-guide text walls with reusable measured reading cards. Gear references now place ranked stats beside item-comparison advice and reported targets, with source attribution and caveats retained below.
- Added consistent hover feedback to shared selection rows and complete outlines to custom topic controls. Bank item names and tab labels now use the shared type scale.
- Rebuilt Settings command help into a bounded quick-reference panel. Added continuation/end-of-page cues and clamped stale scroll offsets when page content shrinks.
- Quest discovery fits its actual visible result count, retaining room for explanations in the empty state. Its details and pagination follow the panel height.
- Brought the world-map toolbar into the shared charcoal/gold style without changing terrain, marker coordinates or zoom mechanics.
- Expanded offline review captures to include bank, map toolbar and discovery empty states. Added measured-layout checks across every supported specialization, discovery-height checks and scroll-state regression checks. Client rendering remains unverified.

## 3.37.0-beta — Interface finish pass

- Unified dark surface, border and secondary-text tones across shared panels and controls; raised title bands separate headings from content.
- Added complete control outlines, more readable button labels, explicit disabled contrast and warm hover feedback. Active controls now retain a left selection cue as well as an accent edge.
- Refined the main shell, journal headings, quest-zone labels and journal hover contrast. Native meter themes and combat-data handling are preserved.
- Validated with offline widget captures and regression checks. Real-client font rendering and compatibility still require in-game acceptance.

## 3.36.0-beta — Zone quest catalog and personal turn-in history

- Added Find quests, Zone catalog and Turn-in history tabs beneath the objective field guide. Added /fc questbook and /fc history, plus tracker-menu shortcuts.
- Expanded the mapped-giver index to retain higher-level character-compatible quests for catalog browsing while continuing to suppress them from available pickup markers. Catalog states distinguish active/ready, completed, pickup references, blocked references and unknown completion.
- Added supported level/prerequisite/choice/parent/breadcrumb explanations and named prerequisite references. Unknown prerequisite completion stays unknown instead of becoming an availability claim. Catalog counts describe only the indexed mapped-giver scope, not every quest in a zone.
- Added a per-character ledger of the latest 300 observed turn-ins. Stores reported XP/money, actual observation time when available and the turn-in map, supports repeatable events, and preserves selection as newer records arrive. Old completion flags never create dates, rewards or historical coordinates.
- Added history search, chronological order, turn-in-map filters and explicit reward-reporting counts. Missing rewards remain unknown. Saved-title truncation preserves UTF-8 boundaries; malformed saved rows are ignored.
- Catalog search and state filters reuse the current query result rather than repeatedly scanning completion APIs. Zone changes refresh the catalog and discard the old giver selection. History hides irrelevant giver-navigation controls.
- Added history/catalog regression coverage and UI captures. In-game acceptance and full Questie coverage remain pending.

## 3.35.0-beta — Objective field guide and live quest tracker

- Added a quest field guide with live objective counts, known/unknown progress, completed states, matched objective locations, multiple source choices, explicit navigation feedback and a separate turn-in view. Short quests use a shorter panel rather than four empty objective slots.
- Added an optional movable, collapsible quest tracker with remaining-objective previews, addon-only pins, ready/current-zone priorities, two/four-quest layouts, paging, map actions and field-guide shortcuts. It refreshes while the main window is hidden and never changes Blizzard's watched quests.
- Fixed the full modern quest-log enumeration path losing objective type and required-count metadata. Both modern paths now preserve type, fulfilled/required counts and quest level; legacy objectives retain their reported type. Failed scans preserve the last successful snapshot.
- Matched provider locations retain exact objective indices. General native quest POIs stay separate from objective-specific locations, and completed objectives cannot keep stale navigation actions.
- Expanded pickup discovery to browse either the player's zone or the zone selected on the world map. Map changes refresh the browser and clear old giver selection. Added active-marker right-click actions for field guides and pins, plus progress context in map tooltips.
- Added /fc tracker and /fc discover, quest-journal shortcuts and a tracker toggle in the briefing. Unknown or cached progress is labeled, and navigation is disabled when the quest snapshot is unavailable.
- Added two Lua suites plus broader UI regression checks for matching, counts, deduplication, stale snapshots, tracker updates and source selection. New field-guide/tracker previews use explicitly labeled fixtures. Real-client acceptance and Questie feature parity remain unverified.

## 3.34.0-beta — Compact Details-style meter

- Replaced the large branded header, control rows and stacked footer with a compact title bar, five native-art toolbar controls and a single status line. Eight player rows now fit in 320 by 218 pixels; compact is 280 by 134 and expanded is 440 by 302.
- Added full-list mouse-wheel scrolling, absolute ranking numbers, a visible rank range and stable player selection across scrolling, resizing and native ranking changes. The visible row count no longer limits which raid members can be inspected.
- Added separate total and per-second columns for damage/healing views, outlined text, bounded name/value wells, a selected-row underline and larger-text support. Single-value mode remains available. Secret values continue to pass directly to native display without concatenation or arithmetic.
- Added title-bar display/segment menus, named native combat sessions, right-click quick displays, Ctrl-wheel display cycling, and a complete options menu for layouts, rows, columns, type size, skins, lock and position recovery.
- Added a native combat-data reset with an explicit confirmation and combat-state recheck. Reset affects Blizzard's shared combat sessions; missing APIs disable the confirmation action. Resetting window appearance preserves combat data.
- Retained both Details-inspired and Recount-inspired skins and the native spell breakdown. Added geometry, 40-source scrolling, selection, history, reset and options regressions plus empty-state previews for all presets and themes. In-game validation and full Details feature parity are not claimed.

## 3.33.0-beta — Quest-giver analysis and readable combat values

- Expanded Discover Quests with selected-giver details, per-location source labels, navigation feedback, level filtering, reset controls and sorting by name, level, client evidence or approximate map proximity. Unknown levels stay visible; proximity is not a terrain-aware route or yard measurement.
- Added a Find new quests shortcut beside the active quest controls. Selection follows a giver's coordinates when provider results reorder, and stale quests disable navigation. Invalid coordinates and duplicate locations are excluded.
- Journey now offers up to three distinct quest pickups when no active quest is recommended. Client-reported starts take priority over database references; map proximity helps order candidates when position is available. Each pickup can start navigation explicitly.
- Refreshes the visible guide when background quest indexing finishes. Database-only availability still requires confirmation with the giver; special reputation, profession and seasonal rules are not fully evaluated.
- Compact public combat totals and rates into narrow meter columns, spell rows and player summaries. Hover shows unrounded public values. Secret values retain their original native display path and are never formatted or used for derived totals.
- Extended offline regression checks for mixed-source giver locations, sorting, level filters, invalid coordinates, selection recovery, stale navigation, pickup queues and secret-safe number formatting. Added a dedicated quest-discovery capture to the offline interface gallery. In-game acceptance remains pending.

## 3.32.0-beta — Searchable quest discovery

- Added a searchable current-zone browser for unaccepted quest pickups, with native/database source filters, grouped giver locations and explicit navigation.
- Kept discovery usable when map pickup icons are hidden, without changing marker preferences.
- Added an initial pickup suggestion to Journey's empty quest-log state and automated discovery checks.

## 3.31.0-beta — Unified interface and profession workspace

- Unified the application shell, navigation, dashboard, guide cards, checklists, catalog controls and settings around charcoal surfaces, restrained brass accents and a shared native-font type scale. Removed stacked ornamental borders and default push-button chrome from addon-owned controls.
- Added consistent input insets, focus indicators, persistent search hints, selected-row edge markers and modern close controls. Preserved per-character state, class colors, meter themes and navigation behavior.
- Made quest pagination and detail placement follow the visible row count, added informative empty states, bounded row labels and fixed compact-sidebar/footer collisions.
- Replaced command-only material entry with a profession workspace: add, edit, cancel and remove goals with aligned owned/needed/remaining columns and pagination. Invalid, duplicate or stale edits cannot overwrite a saved goal. Counts remain explicitly manual; no crafting, trading or inventory actions are performed.
- Improved bank name/count separation and empty search feedback, long loot-title flow, talent-tile text and rank spacing, detail-sidebar growth, notebook status spacing, navigation HUD typography and meter empty states.
- Added a reproducible 15-screen offline design-review gallery with client font/icon approximations, including a meter capture containing no invented combat data.
- Lua 5.1 and mocked-client checks cover the new form workflow and atomic updates, compact navigation, input hints, existing talent planning, quest pickups and secret-safe combat data. Actual Forever-client acceptance is still pending.

## 3.30.0-beta — Unaccepted quests and professional interface pass

- Added background indexing of unaccepted quest-giver locations from Forever QuestieDB, including NPCs and objects. Checks active/completed state, minimum level, provider race/class masks, quest prerequisites, exclusive choices, parent quests and breadcrumbs. No item-drop pickup coordinates are guessed.
- Native Blizzard pickup records take precedence. Database-only markers explicitly require availability confirmation because reputation, profession and seasonal rules are not fully evaluated. Phased and invalid spawns are omitted.
- Added native yellow quest pickup icons, nearby pickup clusters, Shift-click cycling, navigation and a Pickups map toggle with source/loading help.
- Added shared dark interface controls and explicit meter metric/session menus. Rebuilt spell analysis into spacious rows with separate values, shares, bars and stacked player statistics. Sorts only inspectable spell totals and keeps selection attached to a public player GUID when rankings change.
- Added an Up Next quest queue to Journey, compact zone cards and consistent action buttons.
- Offline regression coverage includes eligibility, Skyborne masks, native precedence, clustered pickup interaction, metric menus, spell sorting and rank changes. Real-client acceptance remains pending.

## 3.29.0-beta — Meter readability, map services, and live quest guidance

- Rebuilt meter text/texture layers above the native bars; separated header controls, added column labels and a layout toggle, constrained footer text, and corrected spell breakdown row collisions. Both skins share the detail-panel styling.
- Retained direct native secret-value display; invalid public maxima produce empty bars. Duration is shown only when safely inspectable.
- Replaced generic service pictures with Blizzard minimap tracking textures. Deterministic screen-distance clustering combines nearby service categories; Shift-click chooses a member, and ordinary click navigates to its provider coordinate.
- Added only native-reported, titled quest pickup markers with explicit player navigation.
- Added current-map quest-stop suggestions with pins, turn-ins, and approximate distance priority, plus beginner hub, travel, dungeon and alternate-character preparation guidance. Suggestions do not evaluate terrain or quest prerequisites.
- Added Lua regression suites and fixed stale width, event-handler and map-style assumptions in the existing mock tests.
- Client verification remains pending; see docs/SPRINT_3_29_VERIFICATION.md for coverage and release-gate limitations.

## 3.28.0-beta

- Show all active quests with a known destination on the displayed map by default. Nearby quests share a marker and the focused quest keeps its cyan highlight.
- Add a switchable atlas style using a subtle grid and tint over the client map.
- Show friendly town services using Forever QuestieDB: vendors, repairs, bankers, auction houses, inns, and flight masters.
- Save your personal bank while it is open. View the most recent snapshot from the Bank tab or /fc bank.

## 3.27.0-beta

- Added Leveling Route with a live next quest, map navigation, faction-aware zone choices, and a 1–60 bracket browser.
- Simplified the quest map. Focus shows up to three highlighted destinations, All adds one small marker per nearby quest up to a map-wide limit, and Off hides Companion markers. Zoom focus uses the native map zoom.
- Click a highlighted destination to start the on-screen arrow. It displays straight-line distance and uses Blizzard waypoint navigation when a custom bearing cannot start.

## 3.26.0-beta

- Give all 27 specs a setup and a spec-specific rotation view across Leveling, Dungeon, Boss, AoE and PvP. Separate spell names from the instructions and keep the priority order stable.
- Separate Protection and Retribution Paladin from the first trained seal onward. Cover Righteous Fury, Seal of Fury and the taunt interaction for tanks, and damage seals, Holy Strike and optional Unsealed Wrath swaps for Ret.
- Import location data at runtime from the separately installed Forever QuestieDB. Show known locations for unfinished NPC, object, item and supported exploration objectives, plus turn-ins.
- Put a focused-quest card and destination highlights on the Blizzard world map. Click a marker to focus it or Shift-click to request the native navigation arrow.
- Keep Blizzard objective boundaries when available. Destination rings identify reported points and do not imply an official boundary.

## 3.25.0-beta

- Track active quests as you accept them. Auto focus follows new quests while you can lock focus by choosing or pinning a quest.
- Mark active objectives, ready turn-ins and your focused quest on the world map. The focus area uses the Forever client’s quest boundaries where available.
- Keep the direction arrow under Show on map, so journal and map updates leave your waypoint alone.

## 3.24.0-beta

- Show a map pin and native direction arrow on demand for quests with a usable location. Use WoW quest data first, with an optional standalone Forever QuestieDB fallback for unambiguous turn-ins.
- Show the next unfinished objective in the quest focus card. Keep location writes behind an explicit click and skip stale quest snapshots.

## 3.23.0-beta

- Choose dungeons, bosses and drops in one journal. Open an item’s loot card or jump to preparation and notes.
- Simplified the loot catalog and moved wishlist and obtained actions beside the selected item.
- Shortened guide copy and put detailed profession references behind a toggle.

## 3.22.0-beta

- Added 100 source-attributed equipment entries from six Forever dungeons. The catalog now has 127 entries across nine dungeons, with item and encounter references.
- Trim spaces around loot searches and avoid rebuilding the closed addon window on XP, zone and profession updates.

## 3.21.1-beta

- Save the planning level separately for each specialization’s talent draft, including when resetting ranks.
- Refresh open class guides on spellbook changes. Keep unmatched translated spell names unconfirmed and keep live spell ownership out of other-class previews.

## 3.21.0-beta

- Added Recommended Build to Class Guides → Talents. Preview a complete Icy Veins level-60 PvE allocation for every specialization, including a separate Bear tank build. See the split across all three trees and copy a build to an empty draft.
- Checked all 28 allocations against the bundled 1.60.1.70790 data and tested that previewing a build preserves saved drafts.

## 3.20.0-beta

- Rebuilt Class Guides → Talents into a grid of 467 talents across all nine classes and 27 trees, with Blizzard client icon and tooltip references.
- Added loadable opening ranks and three build milestones per tree. Druid has a separate Bear draft and opening within Feral.
- Save one draft per class and spec. Plan across all three trees with rank, tier, prerequisite and base point budget checks.
- Talent grid adapted from [Zephras](https://zephras.com/data/) ([CC BY 4.0](https://creativecommons.org/licenses/by/4.0/)), Forever build 1.60.1.70790. Names and icon references belong to Blizzard. The addon does not apply talents.
- Includes the 3.19.0-beta update with explicit spell icons and learned-spell-aware rotation priorities across every class.

## 3.18.0-beta — November 2, 2026 (develop)

- Added source-reviewed Forever beta PvE stat references for all 27 standard specializations, with separate Bear-tank guidance under the conditional planner label. Included source URLs, practical caveats, conditional target references, and explicit uncertainty where sources conflict.
- Corrected class emblems to Blizzard's class sheet/crops across dashboard, banner, class strip and general priority cards. Skill artwork now requires a named cue present in the instruction; unresolved lookups show a question mark. Class-to-skill transitions reset texture crops.
- Added a clickable paged loot catalog, slot and manual-acquisition filters, source-detail panel and item-to-boss-notebook navigation. Existing wishlist and acquisition controls remain independent. No new item/drop claims or verified BiS rankings.
- Added all-profile/icon regression checks, compound filter and UI navigation tests, and native gear/loot preview artifacts. Mock text measurement now accounts for explicit line breaks and widget width.
- Live client icon rendering, installation, current Interface version and CurseForge acceptance remain unverified. Main and public release are unchanged.

## 3.17.0-beta: readable class-guide details (develop)

- Replace the one-line selected-priority area with a larger, measured multiline card.
- Reflow the practice desk and long-form guidance below expanding instructions.
- Enlarge explanation row text and click targets; retain full text in hover details.
- Separate resource and specialization labels and give quick information more space.
- Expand long topic bodies and reposition their handbook navigation below the text.
- Keep gold borders attached to resized cards and resize offline inspection crops.
- Exercise every available priority across all nine classes and five contexts, plus
  forced long-text expansion/shrink-back and panel separation in the mocked client.
- Preserve all advisory evidence labels; real-client testing remains pending.

## 3.16.0-beta: illustrated class-guide workspace (develop)

- Replaced the two small class cards with a wide illustrated class banner,
  breadcrumb, large class icon/name, specialization/role line and XP strip.
- Added eight functional, persisted topic tabs across all nine classes: Overview,
  Talents, Rotations, Leveling, Dungeons, PvP, Gear & Stats and Professions.
- Added original Warrior header artwork; other classes retain the neutral citadel
  backdrop. Class and ability icons remain client-sourced.
- Enlarged priority icons and number badges, added concise headings and flow
  markers, and made the explanation table clickable with full selected detail.
- Added class-specific quick tips and resource/spec information. Context and topic
  switches preserve the underlying advisory data and do not automate gameplay.
- Moved specialization/role controls into the top header, added class-strip icons,
  and removed duplicate class-page headings/footer controls from the reading area.
- Added guarded C_Spell.GetSpellTexture artwork lookup with safe class-icon fallback;
  missing APIs, unresolved English names and invalid/restricted results remain safe.
- Expanded offline coverage for all 72 class/topic combinations, all 45 class/context
  combinations, topic state recovery and selected table instructions. Native
  previews remain approximations; live-client visual/interaction approval is pending.

## 3.15.0-beta: reference-inspired visual rebuild (develop)

- Added original illustrated citadel and transparent heraldic crest textures to
  the actual addon, with explicit provenance and audited package inclusion.
- Added shared charcoal/brass panel styling and guarded native serif font styling.
- Rebuilt dashboard shortcuts as six icon-first tiles and enlarged the header crest.
- Added direct Leveling/Dungeon/Boss/AoE/PvP rotation-context navigation, selected
  priority explanations and visible resource tips; preserved existing guide data,
  priority tooltips, class/spec controls and the lower practice desk.
- Added geometry/color/visibility/texture exports and an offline native renderer.
  Previews use actual widget layout; game fonts/icons are approximate.
- Retained live-client acceptance and CurseForge submission gates.

## Develop: searchable encounter navigation and session drafts

- Replaced boss-only cycling with four clickable, paginated catalog rows and
  literal boss/dungeon/item search within the selected dungeon.
- Preserved explicit boss selection while filtering, including no-result searches;
  research context and loot navigation follow only the selected encounter.
- Retained unsaved research drafts across page and boss changes for the current
  session. Explicit Save persists; Escape discards; Clear affects only one context.
- Added mocked interaction coverage and a coordinate-derived encounter preview
  to CI. Increased the Dungeon scroll offsets to fit the browser and notebook.
- Catalog coverage, live API compatibility, in-game appearance and CurseForge
  acceptance remain unverified.

## Develop research and acquisition tracking — 2026-11-02

- Added editable, per-character research notebooks for Legacy, alt preparation and individual catalog bosses, with explicit save, restore and clear controls. Personal notes never change evidence status.
- Added manual obtained markers separate from the loot wishlist, with per-boss/dungeon acquisition summaries and clear inventory-scan disclaimers.
- Preserved unsaved research during ordinary refreshes; bounded input and removed control/formatting characters from stored notes.
- Fixed loot-card spacing and text bounds; reject non-finite drop-rate input.
- Added notebook and acquisition integration tests and CI coverage. Live-client verification and submission acceptance remain pending.

## 3.14.0-beta (develop, 2026-11-02; mocked-client verification only)
### Dashboard mission-control improvements (develop, 2026-11-02)
- The three progress metrics are now native, clickable navigation targets: XP opens Leveling, quest readiness opens Quests, and manual materials open Professions. Hover tooltips disclose data provenance and current values.
- The welcome banner now summarizes actual available level, quest readiness, and manual material shortages. Missing/failed quest APIs are shown as unavailable or stale rather than treated as current progress.
- Today's Focus displays an updating 0–4 completion counter and a thin gilded progress rail, driven by the existing per-character daily checklist and reset rules.
- Quest recommendations expose observed zone/objective text in tooltips; profession shortcuts explicitly state that material counts are manual. All interactions remain addon-only and read-only with respect to the game.
- Offline widget tests exercise progress navigation, tooltip fallbacks, source disclosures, and daily completion behavior. The illustrative offline dashboard PNG now checks and draws the new live widget strings.
- These are mocked-client tests only, not proof of live Forever compatibility or final visual fidelity.

- Added persistent, per-character quest priorities with a real Pin Focus / Unpin Focus control in the native Quest Journal.
- Highlighted pinned rows with [PIN] badges, a pinned quest count in the journal summary, and a fourth sorting mode that puts pinned quests first.
- Dashboard recommendations still prioritize ready-to-turn-in quests, then unfinished pinned quests. Clicking a recommendation focuses the corresponding quest in the addon before navigating.
- Added /fcq pin N, /fcq pin selected, /fcq pins and /fcq clearpins. Pins are capped at 100 and never alter the game's quest tracking or map.
- Added `/fcm shopping`, deterministic ranked manual shortages, named material recommendations on the dashboard, and a top-five shopping summary in the Professions handbook. Counts are manual, not bag scans or market prices.
- Reworked the quest toolbar spacing so pin, sort, filter and section information remain distinct. Updated the mock-derived quest preview to render the actual toolbar and highlighted rows.
- Refined the original native FC monogram with a stepped shield, a small inset jewel and symmetrical gold rivets; updated offline previews to approximate the new in-game texture geometry.
- Expanded Lua and mock UI regression tests for pin persistence, sorting, slash commands, and visual controls. This is offline verification only; no Forever-client compatibility is claimed.
- Interface version, guide accuracy, original illustrated artwork, licensing and CurseForge version support remain unverified.

## 3.13.0-beta (2026-11-02)
- Replaced the Settings page's plain top section with two native, black-and-gold briefing cards for per-character preferences and exposed client APIs.
- Added working Settings shortcuts to restore automatic class detection, center the addon window, and toggle compact layout. These change only addon preferences and never protected game state.
- Exposed the actual client build/interface value when GetBuildInfo is available; otherwise the UI explicitly reports unknown rather than guessing.
- Added read-only quest, profession, spellbook and XP API visibility indicators. These do **not** claim game compatibility or verify API results.
- Expanded offline Lua and mocked-widget regression coverage for the Settings buttons and missing APIs, plus a new Settings screenshot approximation in the CI preview artifact.
- Kept the Interface number provisional and live-client/CurseForge compatibility unverified.

## 3.12.0-beta (develop, November 2, 2026; offline mock testing only)
- Added native dark-gold Dungeon and PvP preparation cards showing the current class, manually chosen role, general class guidance, and the next unchecked preparation task.
- Replaced duplicate stock checklist controls on those pages with four real interactive preparation tiles. Each tile persists its checked state per character; the gold progress bar represents **manual checklist completion only**, not actual dungeon/PvP readiness.
- Added working shortcuts from both preparation pages to Leveling and Quests, without casting spells, queueing, targeting, or modifying game quests.
- Corrected a content mismatch where PvP role notes could display dungeon-specific tank-target advice; PvP now has separate general role guidance.
- Introduced an original geometric **FC heraldic monogram** drawn with built-in WoW textures and fonts, shared by the main header and dashboard banner. This is not yet the full illustrated fantasy crest from the reference concept.
- Extended mocked-client tests for independent Dungeon/PvP progress, undo, navigation, hidden panels, and crest presence. Added separate mock-derived Dungeon/PvP PNG previews and snapshots to the CI workflow.
- Reflowed the long-form guide text below the new native tiles and retained slash-command checklist access.
- Target client, actual Interface version, exact rendering, guide mechanics, and CurseForge support still require live verification.

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

