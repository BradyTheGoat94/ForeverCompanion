# Zone catalog and turn-in history: 3.36 beta

Open Quest Log and use the tabs below the objective field guide:

- **Find quests** keeps the existing pickup search, source filters and explicit navigation.
- **Zone catalog** lists indexed, mapped quest givers compatible with the current character's race/class masks. It includes higher-level references, with active, completed, pickup-reference, blocked-reference and unknown states. Supported prerequisite explanations can name earlier quests.
- **Turn-in history** shows actual turn-ins observed while the addon is loaded. It retains the latest 300 per character, with reported XP/money, observation time when available and the map where the turn-in occurred.

The tracker menu also opens the catalog/history. Direct commands are /fc questbook and /fc history.

## Evidence and scope

Catalog totals are not a claim about every quest in a zone. They exclude unmapped/item-start/phase-restricted locations and incompatible race/class references. Special profession, reputation, seasonal and event rules remain incompletely evaluated. A pickup reference means the supported checks passed and the giver's special requirements still need confirmation. Unknown completion or prerequisite data cannot establish availability.

The existing pickup marker feed still rejects higher-level quests, active/completed quests and unmet supported prerequisites. Broader catalog indexing does not turn those entries into available map markers. General map POIs and objective-specific destinations retain the 3.35 separation.

History uses the native QUEST_TURNED_IN event. Repeatable turn-ins remain separate records. Completion flags never create historical timestamps, rewards or coordinates. Reward totals include reported amounts only; the interface shows how many events reported XP and money. Missing values stay unknown. The stored map is the observed turn-in map, not an inferred quest origin. Historical giver navigation is hidden.

Selection uses a stable per-event sequence, so inserting newer records does not select a different old turn-in. Saved rows are validated, bounded and truncated without splitting UTF-8 characters. Current search/filter operations reuse a catalog query; map/quest refreshes rebuild it from current evidence.

## Verification

Seventeen Lua suites cover existing combat/map/quest workflows plus catalog state classification, level gating, prerequisite unknowns, completion flags, repeated turn-ins, reward evidence, retention, UTF-8, corrupt saves, stable event identities, query caching and tab switching. Full UI captures use labeled sample fixtures and approximated client fonts/icons. Python packaging tests, API-global and automation scans and guide preflight supplement these checks.

Real Forever-client event timing, persistence across reloads, native fonts, provider compatibility and API behavior still require in-game acceptance. Questie feature parity is not claimed. Existing release_audit.py findings about legacy timers/navigation assets remain unresolved; the beta package builder validates integrity, not target-client compatibility.

[Blizzard-generated QuestLog documentation](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/QuestLogDocumentation.lua) confirms the turn-in event's quest ID, XP and money payload. Capability checks and unknown-value handling remain in place for the target client.
