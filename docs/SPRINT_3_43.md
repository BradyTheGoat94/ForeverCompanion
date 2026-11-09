# Forever Companion 3.43.0-beta — Map and service overhaul

November 9, 2026. Baseline: develop eb7411d (3.42.0). Main remains outside this update.

## Map appearance

The previous 120-unit central toolbar is replaced by a 54-unit bottom-left dock. It expands to reveal map layers, focused-quest zoom, styles, pickup/service filters and navigation controls. Drag its header to reposition it. Appearance options reset the dock and select service icon sizes, label visibility, tighter clustering and player coordinates.

New preferences default to unobstructed Blizzard map artwork. Existing saved Atlas/Original/Clear preferences remain respected. The optional Atlas grid/tint is lighter. No generated terrain, external tile pack or invented geography replaces Blizzard's map. Service pins use built-in tracking artwork with a fallback, thin category-colored borders, count badges, hover names and a cyan indicator for visited-nearby positions. Optional persistent labels are limited to twelve clusters to reduce clutter. Right-click a cluster to choose a service; clusters larger than the menu limit remain searchable in the atlas.

Coordinates are the player's reported position in the viewed map, refreshed at most four times a second while the dock is visible. Missing/invalid positions clear the readout; they never preserve old coordinates. These updates do not rebuild the whole map overlay.

## Service Atlas

Open **Find services** on the map, `/fc services`, or `/fc vendors`. Search vendor/NPC name, specialty, service role or NPC ID. Filter banks, auction houses, flight masters, inns, repairs, vendors, trainers and mailboxes where data is available. Choose the player's zone or the selected world-map zone, provider references or visited positions, all locations or favorites. Favorites are listed first; other results can use approximate within-map proximity or name. This is not terrain-aware pathfinding or a travel-time estimate.

Rows combine service roles at the same NPC/location, retain source badges and expose navigation. A click checks that the source/location still exists before starting navigation. A changed map resets paging. Source filters, categories, zone selection and favorites are stored per character. The standalone atlas refreshes when provider indexing finishes, even if the world map is closed.

## Updated service information and its limits

The service index now reads current NPC IDs, names, specialty subtitles, faction eligibility, flags and mapped spawn coordinates from the compatible installed Forever QuestieDB provider. Duplicate coordinates/roles are removed. **Rescan provider** rebuilds this addon's index from the provider's current composed data; it does not download or install a database update.

The current public release checked during this pass is [QuestieDB 1.0.13 Forever](https://www.curseforge.com/wow/addons/questiedb/files/9514215), also offered by its [official release page](https://github.com/Questie/QuestieDB/releases/tag/v1.0.13). Install/update the Forever package alongside ForeverCompanion, reload the client and rescan. It supports API contracts 1–4; this reader requires contract 4. That release's changelog does not establish that every vendor location was updated or verified in game. This update does not bundle provider data or claim a complete current vendor database.

The implementation follows the provider's [public API](https://github.com/Questie/QuestieDB/blob/master/docs/api.md): current named getters and enumeration include its composed corrections; service flags come from the active flavor's contract-4 enumeration. Its [Forever data provenance](https://github.com/Questie/QuestieDB/blob/master/docs/forever-data.md) explains that coordinate conversion does not itself discover newly added or moved content. Unknown faction/phase/location records are not converted into guessed pins. Outdoor service coverage depends on actual mapped provider entries, not a capital-city-only restriction.

## Actual merchant visits

Opening a merchant can record the merchant's NPC identity and the player's reported map position. This follows Blizzard's merchant UI's use of the `npc` unit and read-only repair availability, visible in the [Forever merchant UI source](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_UIPanels_Game/Mainline/MerchantFrame.lua). It does not buy, sell or repair anything.

These records are labeled **Visited nearby**, not exact vendor coordinates. They can help fill missing areas or show a distinct newer visit without overwriting a reference spawn. Vendors may move, and the player may have stood some distance from them. Identical provider coordinates take precedence over duplicate visit entries; distinct visit positions remain separate. Each NPC/map pair keeps its latest visit, with a maximum of 100 records per character. Atlas options can disable capture or explicitly clear all local merchant visits. No visit is shared externally.

## Validation

`python tools/validate_all.py` now runs 24 Lua suites and 15 Python tests (one Windows-specific case-collision skip), plus Lua 5.1 syntax, manifest, API/protected-action, release and ZIP checks. The service suite covers faction gating, duplicate spawns, specialty text, current-provider rescans, reference/visited provenance, bounded visit storage, literal search, grouped roles, favorites and stale navigation. Actual UI construction checks dock collapse/expansion, coordinate clearing, cluster choices, atlas source filters and click-time invalidation.

Populated synthetic atlas and compact/expanded dock previews are rendered and visually inspected. Fonts and built-in game art are approximated. All fixture names/coordinates remain in tests; no sample vendor data ships in the addon. The package contains only the ForeverCompanion folder.

## First in-game checks

1. Enable 3.43.0-beta and the current Forever QuestieDB package, open a zone map and press Find services. If data is missing, check provider/setup status and rescan after updating.
2. Compare several provider NPCs against actual city and outdoor vendors; note moved/missing locations rather than treating the reference as proof of presence.
3. Open a merchant, then filter the atlas to Visited nearby. Confirm the position is where the character stood. Revisit the same NPC/map and confirm its stored visit updates.
4. Try vendor/repair searches, favorites, other zone maps and service-cluster menus. Check zoom, long NPC names, real tracking icons and different UI scales.
5. Move/collapse the dock and reload. Test reset, label/icon-size settings, coordinate unavailable states and native map readability.

Game-client visual acceptance, database completeness and exact live vendor verification remain outstanding. CurseForge upload/approval is not changed by this build.
