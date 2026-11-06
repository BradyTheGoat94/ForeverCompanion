# Quest navigation implementation and verification gate

Status: development specification; **not** a claim of live-client compatibility.
Scope: Forever Companion leveling experience. No automated combat, movement, interaction, quest acceptance or quest turn-in.

## Data boundaries

Separate information into:
1. **Live client observations:** quest-log entries, tracked quest flags, zone/map identity, player position, and objective progress, only after successful API reads.
2. **Sourced static records:** quest giver/turn-in and objective coordinates, prerequisites, zone transitions, and NPC services. Every record needs provenance, game build/era, and review status.
3. **Player preferences:** pinned quest, hidden marker categories, manual route waypoint, and per-character settings.
4. **Unknown:** any quest or coordinate not validated for the Forever client. Never display unknown coordinates as exact pins.

## API compatibility adapter

Before drawing markers, probe the actual client for API presence and expected return types; do not infer compatibility from similarly named APIs in retail/classic versions.

- Quest log: enumerate only through APIs verified for the target client. Cache the last successful scan separately from the current scan status.
- Player position and map: detect whether map ID and normalized coordinates are available. If not, suppress direction/distance indicators rather than displaying zero or stale values.
- Tracking: do not silently replace the game's tracked quests. Addon pins and client tracking are distinct.
- Quest identifiers: prefer stable quest IDs when exposed; otherwise use scoped ephemeral identity and avoid pretending a title uniquely identifies a quest.
- Objective coordinates: draw only when map identity and coordinate provenance match; do not equate quest giver position with objective position.
- Map transforms: test world-map, minimap and zone/continent changes independently. Never reuse normalized coordinates across different map IDs.
- API failures: indicate unavailable, unsupported or stale status in the UI.

## UI behavior

### World map
- Show all **available, verified** active quest objectives for the current map, not just the pinned quest.
- Distinguish objective, turn-in, quest giver and user pin through separate shapes and accessible text, not color alone.
- Group nearby overlapping markers; preserve a readable tooltip with all quests.
- Filters: All active / Pinned / Ready to turn in; separate service toggles for vendors, trainers, bank, mailbox and auction house.
- Never promise all quests have coordinates: list missing/unknown positions in a clearly labeled sidebar.

### Direction guidance
- A non-interactive directional indicator may point to the user's manually selected, verified waypoint when the client exposes reliable player position and orientation.
- Hide bearing when heading, position, or target map is unavailable. Do not guess routes around obstacles or across floors.
- Display zone transitions as separate steps rather than projecting a straight arrow between unrelated maps.
- Navigation is advisory only; no simulated key presses, movement, targeting or quest automation.

### Beginner-focused quest detail
- Quest name and level (when known), objective checklist, last refresh status, prerequisite/source notes, and explicit next step.
- Explain whether the objective is to kill, collect, speak, explore or turn in only if verified by quest text or curated evidence.
- Include an 'unknown location' state and allow a user waypoint without fabricating quest data.

### Town services
- Records require verified map ID, coordinates, service type and source. Some NPCs provide multiple services.
- Bank contents outside the bank require a **last-seen snapshot** from a permitted bank interaction; mark its timestamp and never imply live remote bank access.
- Auction house and vendors are navigation references, not automatic transactions.

## Verification matrix

| Test | Expected result |
| --- | --- |
| Quest log API unavailable | No crash; unsupported state; no phantom markers |
| Empty quest log | Empty state; no stale active markers |
| Zone change | Old-map pins disappear; new-map coordinates revalidated |
| Two objectives share a coordinate | Both are discoverable via grouping/tooltip |
| Quest ready for turn-in | Turn-in state is visually distinct |
| Quest removed or completed | Marker removed after successful rescan |
| Quest scan fails | Prior data labeled stale, never current |
| Missing position or heading | No arrow or numerical distance |
| Unknown objective coordinates | Quest listed without invented map pin |
| Different characters | Pins, filters and notes remain character-scoped |
| UI reload | Preferences restored; live data refreshed |
| Combat lockdown | No protected action or blocked UI mutation |
| Localization | No English-only spell/quest name used as a global identifier |
| Bank closed | Cached bank data explicitly labeled last seen |
| Missing art/texture | Readable fallback icon and text |

## Release gates

- Static analysis and offline UI tests pass.
- API compatibility tested in the **actual target client**.
- Map alignment validated in at least two zones and at two map scales.
- No protected action or automatic gameplay behavior.
- Quest database coverage and evidence quality reported numerically, without claiming 100% coverage.
- CurseForge description distinguishes shipped, beta, and planned features.

## Later optional work

A Details-style damage meter is a separate feasibility investigation. It must not be described as equivalent to Details until actual combat-log event coverage, ownership attribution, encounter boundaries, and performance are validated in Forever. A stationary/rotation layout toggle is independent of damage parsing and can be implemented without inventing DPS values.
