# Forever Companion 3.44.0-beta — Transparent map overlay

November 9, 2026. Based on develop 7cef938. Main is unchanged.

Use `/fc overlay` or **Overlay map** in the expanded world-map dock. It displays a translucent native WoW zone map over the game, with opaque player and focused-quest indicators. This is native map artwork, not Diablo line-only cartography. It follows the player zone/floor reported by the client; the normal world map remains available independently.

Use `/fc overlay options` for 20/35/50/65% artwork opacity, three sizes, monochrome/color, focused quests, optional services, position reset and drag/lock. The map body starts click-through. `/fc overlay edit` enables dragging; `/fc overlay lock` returns to click-through. Hide controls for a fully click-through overlay; `/fc overlay controls` restores them. `/fc overlay hide`, `show` and `reset` are also available. Tab keeps its existing targeting behavior. A user-created macro containing `/fc overlay` can be assigned a preferred key.

Settings and position are saved per character. Visibility restores on entering the world, always locked. Markers stay readable when map opacity is reduced. Services default off and respect existing service-category filters. Locations come from the same installed provider/observed-visit sources as the service atlas; this release adds no location database or guessed coordinates. Focused quest points may be reported reference locations, not guaranteed precise objective positions. There is no terrain-aware pathfinding.

Map art refreshes when the client changes map or phase artwork. Missing/invalid tiles clear old terrain; missing coordinates hide the player marker. Tiles and marker textures are reused, with bounded counts. Fast updates only move the player; slower updates refresh map identity and markers while visible.

The implementation follows Blizzard's Forever [map API declarations](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/MapDocumentation.lua) and [native detail-layer tile order and geometry](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_MapCanvas/Blizzard_MapCanvasDetailLayer.lua). It does not reparent Blizzard map frames.

Validation: 25 Lua suites including full addon UI construction and slash-command integration; 15 Python tests (14 pass, one platform skip); release, API, automation and ZIP audits. The overlay-specific suite checks row-major art, edge cropping, invalid geometry, caching, phase refresh, stale clearing, bounded textures, interaction modes and setting bounds.

In-game acceptance remains required: check outdoor/interior floors, phased areas, map artwork loading, arrow orientation, transparency over moving terrain, UI scaling, screen clamping, dragging/locking, reload visibility, combat targeting through the map, optional marker density and coexistence with the world map. Interface compatibility remains a declared beta target, not client-certified. Nothing has been uploaded to CurseForge by this update.
