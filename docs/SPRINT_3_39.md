# Forever Companion 3.39 beta

## Implemented
- Quest data/setup panel with provider compatibility, indexing and honest coverage/unknown states. Open it from Quest Log, Settings or /fc setup.
- Next objective opens the field guide and retains explicit user-started navigation.
- Direct specialization and role choice menus.
- Event-burst refresh queue; /fc performance measures queued refresh work where supported, with no inferred FPS claims.
- Unified validation across local work and all three workflows; stale version checks and reviewed timer/asset policy conflicts reconciled.
- Negative tests preserve rejection of new timer sites and unreviewed artwork.

## Validation
19 Lua suites passed. Python: 15 tests, 14 passed and one Windows-specific skip.
The root release audit, submission metadata audit, curated API audit, protected-action audit, guide preflight and beta gate passed. The package was built and its archive/manifest checked. Offline screenshots approximate game fonts/icons.

## In-game checks still needed
Record the addon version, client build, class/spec, resolution and UI scale alongside results. Report a pass/fail and Lua errors rather than treating a screenshot alone as full acceptance.

1. Setup: with the compatible provider absent, confirm native-only guidance. With it present, confirm loading and current-map coverage. Check that coverage is not described as available-quest totals.
2. Beginner loop: on a real starter character, accept one quest, select Next objective, navigate to its reported objective, complete it, then navigate to the known turn-in. Record missing/incorrect destinations and provider source. Repeat with a prerequisite chain and a shared giver.
3. Scaling: compact and expanded, representative display resolutions/UI scales, longest quest/item names and every header control. Confirm the setup panel fits the screen and buttons stay separate.
4. Meter: real solo and group sessions, damage/healing, pets, long names, resize, session changes and post-combat spells. Keep native/secret-value restrictions intact; do not fabricate benchmark values.
5. Refresh timing: use /fc performance after play. Compare queued request/batch counts and measured timings, including hidden-window behavior. These counters cover queued page refreshes only.

## Remaining work
Verified step-by-step starter routes require real playthrough evidence; existing route suggestions are not promoted to verified walkthroughs. Populated meter appearance and full client performance remain unverified. Licensing retains the existing owner-decision state; no permissive license was selected on the owner's behalf. CurseForge uploads remain manual; 3.39 has not been uploaded or approved by this work.

## Installation
Replace the existing ForeverCompanion folder with the folder inside the ZIP, then restart the game. Keep SavedVariables to retain preferences. Use /fc setup to inspect quest data.
