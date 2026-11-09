# Questing update: 3.35 beta

## Using the new workflow

Open Quest Log and choose an active quest, then select Objective details. The field guide shows each reported objective, actual fulfilled/required counts where provided, completion state and explicitly matched destinations. Select an objective, cycle reported locations and choose Navigate. Completed objectives lose their destination action. Ready quests show sourced turn-in locations.

Quest map destination remains a separate action because a general Blizzard quest POI does not establish which individual objective it represents. Missing locations stay missing; no coordinates, drop rates or route steps are invented. Provider references require the separately installed Forever QuestieDB and its existing title/objective matching guards.

Show tracker enables an optional standalone tracker. Drag its header to move it; use the small menu for two/four-quest layouts, pinned/ready filters and locking. Collapse keeps only the title bar. Click a quest to open its field guide, right-click for pin actions, or choose Map. Mouse wheel and footer buttons page through the active list. Pinned quests come first, then ready quests, then quests in the current reported zone. This ordering is not a terrain-aware route or distance calculation.

Find new quests opens pickup discovery. Zone: mine follows your character's map; Zone: world map follows the map selected in Blizzard's world-map window. This supports browsing other zones before travel. Existing search, level, source and proximity controls still apply; unknown levels remain visible, and proximity falls back when a usable position is absent.

Active map markers now offer field-guide and pin actions on right-click. Left-click navigation behavior remains available. Pickup eligibility references still require confirmation with the giver because special reputation, profession, seasonal and event rules are not fully evaluated.

Shortcuts: /fc tracker toggles the tracker; /fc discover opens pickup discovery directly. The addon never accepts or turns in a quest, moves the player, or changes Blizzard's watched quest list.

## Verification

- Lua 5.1 compilation of packaged Lua.
- Sixteen Lua suites, including new objective/target and log-enumerator metadata suites.
- Modern full/indexed paths preserve identical type, count and level metadata. Failed scans keep the previous snapshot.
- Native general POIs, cross-map waypoints and matched provider targets remain distinct; duplicate coordinates are removed within each objective.
- UI tests exercise source cycling, location identity through reorder, completed-objective navigation removal, tracker clicks, collapse and cached navigation rejection while the main window is hidden.
- Preview captures show the actual mocked widget structure. Sample quests and coordinates are fixtures, fonts/native icons are approximations, and these are not game screenshots.

In-game font/layout behavior, event ordering, source-provider compatibility, native map interaction and target-client API behavior still need acceptance. Questie comparison is design research, not a claim of superior coverage or complete feature parity. Party progress communication, a complete historical quest ledger and universal prerequisite evaluation are not implemented by this update.

The beta builder validates package integrity, not client compatibility. Historical release_audit.py findings for existing timers/navigation assets remain unresolved.

## Reference review

[Questie's feature documentation](https://github.com/Questie/Questie/blob/master/README.md) informed the tracker, objective tooltip, map-action and zone-browsing workflow review. This update uses independently implemented presentation and the addon's existing native/Forever QuestieDB data interfaces.
