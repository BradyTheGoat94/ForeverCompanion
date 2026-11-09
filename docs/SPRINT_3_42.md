# Forever Companion 3.42.0-beta

Baseline: develop 0ef0e74 (3.41.0). Main is outside this update.

## My Leveling Session

Open from Overview → My Session, `/fc session`, or Route options → Open leveling session. Four summary cards show elapsed tracking time, observed XP, XP/hour and observed turn-ins. The reading area separates reported quest rewards and the six latest observed turn-ins.

Current sessions begin on login or manual reset. Pause excludes subsequent time, sampled XP gains and turn-in rewards until resumed. Ending a session asks for confirmation, saves its summary and starts a new session. The ten most recent manually ended summaries persist per character. Reload starts a fresh current session; it does not merge offline time or automatically archive unfinished sessions. Previous summaries have a distinct heading and cannot be paused.

XP comes from public player XP/level/max snapshots. A single sampled level transition uses the prior level's remaining XP and the new level's reported XP. Missing data, backwards XP, changed thresholds within a level, skipped levels and clock discontinuities leave explicit gaps. XP/hour requires 60 seconds, positive observed gains and no sample gaps. It describes the tracking interval, including idle time while unpaused, not active combat time or a projected level-up time. Quest reward XP is displayed separately and never added to sampled XP.

The implementation was checked against [Blizzard's Forever Unit definitions](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitDocumentation.lua), which expose UnitXP and UnitXPMax, and the [quest event definitions](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/QuestLogDocumentation.lua), which expose quest turn-in ID and reward fields. The existing history recorder supplies observed turn-ins to the session module. API-source inspection does not establish real-client verification.

## Flexible itinerary

Right-click a displayed objective and choose Set aside. It disappears from the planned stops and `/fc next` until restored, completed, removed or reloaded. Route options can restore all set-aside steps. This is an in-memory planning preference, not quest completion, abandonment or a permanent blacklist. Deferral identities include quest ID, objective index, turn-in state and objective text; a different objective cannot inherit the setting merely by using the same location. A temporary failed quest scan does not erase the preferences.

## Discovery and atlas

Discovery remembers its source, sort, near-level and player/world-map-zone preferences per character. Sort choices and atlas quest states are explicit menus. Search still uses literal text matching.

Discovery rechecks pickup presence and exact giver coordinates when navigation is clicked. Atlas rechecks the current catalog and selected map. Removed/accepted pickups, moved locations and changed maps reject the old action with a readable message. The catalog remains a source of giver references, including blocked/unknown entries; navigating to a reference does not promise eligibility.

## Verification

Run `python tools/validate_all.py` on this candidate. The suite now contains 23 Lua suites, including a new session-progress suite, plus 15 Python tests (one Windows case-collision skip). Acceptance includes Lua 5.1 syntax, manifest integrity, release and API checks, protected-action checks and installable ZIP validation.

New regressions cover XP level transitions and gaps, pause/resume boundaries, separate reward accounting, bounded archived summaries, independent snapshot copies, protected XP values, clock rollback, temporary route deferral/restoration, completed-deferral cleanup and click-time pickup/catalog revalidation. The actual manifest is loaded in the UI mock. A populated session preview with six long quest titles is rendered and visually inspected; fonts and game art are approximations, and fixture values are confined to tests.

## In-game checks still required

1. Confirm version 3.42.0-beta in `/fcdiag` and open `/fc session`.
2. Gain XP, turn in quests, cross one level, pause while earning more XP, then resume. Compare tracked gains and time against the client.
3. End a session, open its saved summary, reload and confirm ended summaries remain while the current session restarts.
4. Set an objective aside and restore it. Complete it and confirm its temporary setting clears. Reload to clear all temporary deferrals.
5. Change discovery preferences, reload and confirm they remain. Accept a displayed pickup before clicking its old navigation action.
6. Check compact and expanded layouts, real fonts, UI scales, long localized titles, and the first Lua error if any.

No new class build, quest coordinate, optimized leveling route or terrain-aware path is claimed. CurseForge submission is not automated; this candidate is not marked approved or game-tested.
