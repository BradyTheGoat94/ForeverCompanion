# Forever Companion 3.45.0-beta — Map companion tools

November 9, 2026. Baseline develop e3e533a (3.44.0). Main is unchanged.

## Start here

- `/fc notes`: personal notes, nearby-service choices and overlay presets. Also available under Tools on the expanded world-map dock and through overlay options.
- `/fc note <name>`: save your currently reported position. Preserves capitalization. Use the notes panel to rename, delete (with confirmation), or navigate.
- `/fc nearest repair`: choose from the closest reported current-zone repairs. Also accepts mail, inn, flight, vendor, bank, auction and trainer.
- `/fc overlay exploring`, `/fc overlay questing`, `/fc overlay town`: apply coordinated appearance and layer settings. Existing position and control visibility are retained; applying a preset shows and locks the overlay.
- **Another objective >** on the navigation HUD requests a different live matched destination. Nothing advances automatically or changes quest progress.

## Marker grouping and presets

The transparent overlay clusters nearby quest, service and note points in screen space, with count badges. Quest artwork takes priority within a mixed cluster. Counts represent reported markers, not necessarily distinct NPCs or quests. Larger overlay sizes separate distinct positions when their screen distance exceeds the clustering threshold. Exact shared coordinates remain grouped. At most 80 overlay clusters are drawn; an overflow hint suggests enlarging the map or hiding a layer. Textures and badges are reused.

World-map service/quest grouping remains zoom-dependent. Personal notes cluster independently on the world map, with a click menu for up to eight choices and a link to the complete notes browser. Zoom separates distinct note positions. The overlay remains click-through: use the normal map or browser to choose a destination.

Exploring uses a large, faint monochrome map with notes. Questing uses medium size/opacity with focused quests and notes. Town uses a smaller color map with services and notes. Presets can be adjusted afterward through overlay options; they never remap Tab.

## Nearby services and quest clarity

Only current-zone locations returned by the installed service index are ranked. Sources remain the existing provider references and visited merchant observations. This adds no vendor database or live NPC discovery. Visited records explicitly describe the player's position during interaction. Lookup does not inherit favorites/category-hide preferences, so those cannot silently change the meaning of nearest.

When the player and every candidate convert into the same world-coordinate system, ranking uses straight-line yards. Otherwise all candidates use normalized map proximity together, labeled as approximate. Units are never mixed within a ranking. Terrain, accessibility, travel time, phase and stock are not evaluated. Results are snapshots; selecting one revalidates the service's source/location before navigation.

Map tooltips, map hints, the overlay legend, field guide and itinerary distinguish client quest points, objective search references, general references and turn-in references. Coordinates do not prove an exact enemy/object position. Unlocated quests explain missing client/reference coverage or known targets on other maps. No coordinates or search-area boundaries are guessed.

## Notes and arrival

Save up to 100 named positions per character. Stable IDs prevent a deleted-note action from navigating to a newly created note. Labels strip markup/control characters, cap length and preserve UTF-8 boundaries. Missing/invalid positions refuse saving. Notes are personal observations, not verified rare-spawn or resource data. No sharing or automatic rare detection is added.

The arrow shows **Arrived nearby · inspect destination** within 12 straight-line yards of the selected point. Missing distance clears arrival state. Proximity does not prove completion, a spawn or accessibility. **Another objective >** uses the live itinerary and its current filters, excluding the current coordinate for that request. It does not permanently defer or complete the previous objective. With no other eligible destination, navigation remains unchanged.

## Verification

26 Lua suites, including full addon UI and slash-command integration; 15 Python tests (14 pass, one platform skip); release, API, automation and package audits. New checks cover note persistence, UTF-8, limits, stable IDs, stale actions, distance ranking/fallback, explicit destination choice, presets, cluster reuse, missing coordinates, arrival clearing and manual objective exclusion. The notes panel was rendered and inspected using the offline native-widget preview; fonts/icons are approximated and it is not a game screenshot.

In-game verification remains pending: check floors and phases, artwork loading, overlay click-through during combat, different UI scales, zooming note clusters, service accessibility, arrow orientation and arrival distance. Offline mocks cannot certify client behavior. Interface 16001 remains a declared beta target. This update has not been uploaded to CurseForge.
