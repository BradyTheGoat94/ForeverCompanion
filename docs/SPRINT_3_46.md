# Forever Companion 3.46.0-beta — Map search and compact travel

November 9, 2026. Baseline develop 20a21e5 (3.45.0). Main is unchanged.

## Open the new tools

- `/fc map`: unified Map Companion search.
- `/fc search <text>`: open with a query. All words must match literally; punctuation is not treated as a search pattern.
- `/fc recent`: recently chosen successful destinations.
- `/fc map button`: restore the quick-access button. `/fc map button reset` restores its default position.
- Left-click the floating **Map** button to search, right-click for quick actions, or drag it to a saved position. Its menu can hide it.
- `/fc arrow`: travel display options, including **Use compact travel strip** and the full arrow display.
- Overlay options: **Fade during combat** is off by default. `/fc overlay show` or the full-visibility option overrides fading for this session; `/fc overlay auto` resumes automatic fading.

## Unified search

Search all saved personal notes, live active quest titles/objectives, and services reported in the player's current zone. Note category and zone names, service roles and specialties also participate. Type filters, six rows per page, a true match count and a 300-result display cap keep the list manageable. Narrow the query if more results match. A known zone can supply service search even if the player's coordinates are unavailable; that does not imply a distance estimate.

Rows show source/context and a navigation or inspect action. Selecting a personal note resolves its current stable ID. Services use the atlas's existing source/location revalidation. Quest results require a successful live snapshot and the quest must remain active; a formerly selected target must still match a current reported location. Missing or changed destinations request a new search. A quest with no reported target can be inspected without inventing coordinates.

Search refreshes on quest/zone events through the existing refresh queue while open. A manual Refresh results button also updates provider-loading results. The index reuses the installed provider and existing addon data; it does not download a database or discover NPCs. No travel-path or service-availability guarantee is added.

## Recent destinations

Only successful player-requested navigation choices enter the per-character list, capped at 20 entries. Revisiting the same typed destination refreshes its entry. This is not a movement trail. The quick menu can pause new entries or clear the list with confirmation.

Notes resume their current saved location. Service references are resolved again before navigation. Active quest destinations must remain active and retain the reported target coordinate. Generic previously selected points are explicitly coordinate snapshots with no live location validation; they never claim to be current quest objectives or live NPCs. Search navigation does not begin until the player chooses a result.

## Organized notes and travel display

Personal notes now have General, Farming, Rare sightings, Gathering and Reminders categories. Choose **Category, icon & color** in a note's Actions menu. Categories supply distinct built-in map icons/colors and can be filtered in the note browser or searched in the hub. Older notes remain General, with their names and coordinates preserved. Categories are personal annotations, not verification that a rare enemy or resource is currently present.

The compact travel strip shows the destination, straight-line distance or nearby-arrival state, a short source/precision label and a manual Another objective action. The full arrow display remains available with the same source label. Layout changes retain the chosen destination, placement and configured scale. Arrival stays informational and does not change quest progress.

Optional combat fading lowers the overlay frame to 30% of its normal alpha, including markers and controls; terrain opacity remains configurable beneath that multiplier. Leaving combat restores normal alpha. Edit mode and a manual session override keep full visibility. Missing or unreadable combat state falls back to full visibility. The feature uses a guarded read of the same public combat-state function used by the [Forever Blizzard UI](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_RestrictedAddOnEnvironment/SecureHandlers.lua); it modifies only this addon's overlay and does not alter combat/targeting bindings. Automatic instance hiding is not included in this release.

## Verification

27 Lua suites, including full manifest/UI construction and new search/compact-layout integration; 15 Python tests (14 pass, one platform skip); API, automation, release and ZIP audits. Tests cover literal multi-word search, result limits, note categories/defaults, immutable history snapshots, deduplication, pause/clear, source revalidation, current-zone search without coordinates, recording only successful navigation, compact layout continuity and combat fade/override logic.

The search hub, categorized notes and compact travel strip were rendered and visually inspected using offline native-widget snapshots. Preview fonts/icons are approximate; these are not game screenshots. In-game verification remains pending, including combat transitions, icon readability, UI scaling, quick-button drag/click behavior, source changes, map phases and interactions with other addons. Interface 16001 remains a declared beta target rather than a client-certified claim. This update has not been uploaded to CurseForge.
