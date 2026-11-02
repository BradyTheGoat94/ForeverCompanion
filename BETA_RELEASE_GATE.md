# Forever Companion — November 4 Beta Gate

**Target:** playable, read-only WoW Forever guide addon beta, not a finished authoritative database.

## Must pass before public upload

- [ ] `develop` CI passes Lua 5.1 syntax, offline smoke tests, mocked UI, ZIP integrity, and SHA256 provenance validation on the **same commit**.
- [ ] Install the produced ZIP in the client's AddOns folder; check the folder layout and that the addon loads without Lua errors.
- [ ] Confirm the client's current interface number; update `ForeverCompanion.toc` only after verifying it from the actual client. The current value is `16001` and is **not independently verified**.
- [ ] Open each tab in-game: leveling, class, professions, quests, dungeons, PvP, and settings; verify navigation, scrolling, layout and text contrast.
- [ ] Test normal and compact window sizes; confirm the premium black/gold theme, selected navigation, and skill tiles render correctly.
- [ ] Test all nine classes and 27 specialization entries; label curated rotations illustrative unless verified against Forever.
- [ ] Test profession guide on a character with a profession and one without; verify skill/cap scanning, recipe goals, edits, gather queue, and no unintended crafting.
- [ ] Test unsupported/partial spellbook APIs; missing API data must remain UNCONFIRMED, never treated as unlearned.
- [ ] Reload UI and relog to verify per-character saved crafting plans, settings and navigation.
- [ ] Test on a clean install without optional libraries or other addons.
- [ ] Verify there is **no automatic combat input, casting, crafting, purchasing, or prohibited protected-action automation**.
- [ ] Add release notes and screenshots captured from the **actual game client**, not only mocked previews.
- [ ] Verify CurseForge project metadata, category, license, supported game version and ZIP contents before submission.

## Automated release-gate evidence (November 2, 2026)

- **Green development commit:** `e9461af627275176f8fa810df6cfb6fb93bdd140`.
- **Passing workflow runs:** `41501681691` and `41501670186` (GitHub Actions completed successfully).
- **Regression caught and fixed:** `de4179f3` failed its new coverage assertion because the optional Guardian / Bear planner choice lacked a playbook. Commit `e9461af6` added its five-step playbook and two conditional-priority notes; both subsequent workflows passed.
- **Guide scope:** 27 standard specialization paths plus an additional conditional Guardian / Bear planner entry. Guardian / Bear availability is **not confirmed** in the current client.
- **Not yet satisfied:** actual in-game installation and visual checks, current interface number confirmation, real spellbook/talent checks, screenshots from the client, and explicit release approval.
- **Simulation:** a full built-in Forever Sim is deferred and not part of the beta scope.
- **Release policy:** no public upload, merge to `main`, or claim of in-game validation based solely on CI.

## Beta scope and transparency

- Curated Warrior spell reference is a **partial client-data snapshot**, not a verified complete trainer/talent tree.
- Other classes use illustrative guide text and/or live spellbook checks; absence from a scan does not establish unavailability.
- Recipe goals and inventory are manually entered; no authoritative Forever recipe database or live bag integration is claimed.
- Crafting queues are planning estimates and do not craft or spend items.
- Class rotations are guidance, not automated execution or performance guarantees.

## Stop-ship

Do not call the build CurseForge-ready if CI fails, the actual client rejects the interface version, the addon throws load-time errors, the ZIP layout is wrong, or any guide performs protected gameplay actions.

## Release procedure

1. Freeze features on `develop` and fix only blocking issues.
2. Wait for all required checks on the release commit to pass.
3. Download the CI ZIP and test it in the actual WoW Forever client.
4. Record the tested commit SHA, client build, screenshots, and observed issues.
5. Publish a clearly marked beta only after the user approves release and the in-game gate passes.
6. Keep `main` untouched until explicit approval to merge.

## Artifact integrity check

The GitHub Actions ZIP and `beta-build-manifest.json` must be downloaded from the **same successful run**. Compare the ZIP SHA256 with the manifest. The manifest intentionally records `in_game_tested: false` and `release_approved: false` because CI cannot perform actual client testing or approve publication. The verified build SHA must match the commit used for the final in-game test.
