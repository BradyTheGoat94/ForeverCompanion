# 3.33 beta verification

Branch: develop only. No client acceptance claim.

## Implemented

The quest journal has a Find new quests shortcut and an expanded current-zone discovery workspace. Search matches quest and giver names literally. Source, level and sorting controls operate on actual client/provider records. Multiple giver locations retain individual evidence labels, exact coordinates and stable selection through result reordering. Removed quests clear the detail selection and disable navigation.

Journey offers up to three distinct pickup options when no active quest is recommended. Client evidence takes priority; approximate normalized map proximity orders candidates within that group. This does not evaluate terrain, travel time or special quest requirements.

Public meter numbers use compact column labels, with unrounded public totals/rates on hover. Secret values pass through unchanged to native display. No synthetic combat data, quest coordinates or service locations were added.

## Offline coverage

- Lua 5.1 compilation of every packaged Lua module.
- Fourteen Lua suites, including the full manifest/UI mock, secret arithmetic traps, compact meter labels and exact hover values, giver grouping/deduplication, per-location sources, literal search, level/proximity ordering, pickup queues, reordering and stale navigation.
- Python release-tool tests, manifest/package validation, API-global audit, combat-automation audit and guide preflight.
- Interface gallery generated from actual mocked widget geometry; discovery uses explicitly labeled fixtures. Fonts/icons are approximated, and these are not game screenshots.

## Remaining acceptance

Actual Forever-client fonts, protected-value propagation, combat transitions, map interaction, server-specific API behavior and eligibility must be checked in game. Provider data may omit special reputation, profession and seasonal conditions. Unknown quest levels stay visible under the level filter.

The historical release_audit.py gate still rejects existing C_Timer.After usage and the original navigation texture assets. This sprint does not waive that gate or claim every release gate passes. The beta builder validates package integrity only; Interface 16001 and target-client compatibility remain unverified.
