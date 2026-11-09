# Forever Companion 3.40 beta

Implemented a live objective itinerary, more granular performance samples and adjustable meter refresh rates. Existing data/secret-value boundaries are preserved.

## Try it
1. Open Leveling Route and scroll to Live objective itinerary. It lists matched unfinished objectives and known turn-ins on the current map, with missing/other-map/unknown-objective counts.
2. Click Go to objective. The addon rechecks that the quest, unfinished step and exact location still exist before starting navigation. Quest acceptance and turn-in remain manual.
3. Open Settings → Performance sample, or /fc performance window. Start a new sample, perform a consistent activity, then refresh the report. /fc performance prints it; /fc performance reset clears counters.
4. In meter options, choose Refresh rate: Fast 0.2 s, Standard 0.4 s, or Low frequency 0.8 s. Compare samples under the same conditions.

## Validation
20 Lua suites pass, including objective matching, multi-step planning, stale-navigation rejection, unknown position handling, bounded route work, profiler reset/snapshots and secret/malformed meter settings. Python: 15 tests, 14 pass and one Windows-specific skip. Root release, submission, API, protected-action and beta gates pass through the unified validation entry point. Offline widget previews approximate native game fonts/icons.

## Limits and remaining acceptance
This route is built from the live quest snapshot and matched client/provider coordinates. It does not invent quest starts or locations, infer objective locations from generic markers, calculate terrain-aware paths or claim completed starter-zone playthroughs. At most 40 stops are planned at once; the mapped count remains visible. Native combat data is never fabricated. Populated meter visuals, real group sessions and all UI scales still require client testing.
Performance reports measure named refresh scopes only. Calls without a profiling clock have no timing value. Scopes can overlap, so their times must not be summed as overall addon CPU. No FPS improvement is asserted.

Both source branches receive this candidate. CurseForge upload remains manual; this candidate is not automatically uploaded or approved. Keep SavedVariables when replacing the addon folder.
