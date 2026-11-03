# Install and first-run verification — Brady's Forever Companion

This is a **pre-release beta**. It has not been certified on the final WoW Forever client.

## Install manually
1. Download the ZIP from the successful **CurseForge beta package audit** run's `bradys-forever-companion-beta-review` artifact.
2. Extract the ZIP. The resulting folder must be named **ForeverCompanion**, containing **ForeverCompanion.toc** directly inside. Do not leave a second outer folder around it.
3. Copy that folder into the game's `Interface/AddOns/` directory under the **actual Forever client installation** (often the `_forever_` installation). Confirm the folder in your launcher rather than assuming its path.
4. Restart the game or reload its UI. Enable the addon in the character selection addon list if available.
5. Open the addon with its documented slash command and run `/fcdiag` in-game. Record any missing API, Lua error, or interface mismatch.
6. Open every major navigation section, select a class and spec, inspect spell icons, and verify that class guidance is labeled advisory where not tested.
7. Create a manual quest/loot note, reload the UI, and confirm the note persists. Also test a clean character profile.
8. During combat, ensure navigation and UI interactions do not trigger protected-action errors. The addon should **never** automate combat or spell execution.

## When a test fails
Record the **exact client build and interface number** shown by `/fcdiag`, the addon version in the TOC, the precise Lua error, and the steps that reproduce it. Do not silently change the interface number to make the addon load; verify the target build and fix the underlying API issue.

## Release safety checklist
- [ ] GitHub Actions package audit passes on the intended commit
- [ ] ZIP artifact contains exactly one `ForeverCompanion/` root
- [ ] Manual install loads without Lua errors
- [ ] `/fcdiag` reviewed against actual client
- [ ] Class/spec pages, dungeon browser, loot and leveling panels navigable
- [ ] SavedVariables survive reload and logout/login
- [ ] Icons and UI checked at common display resolutions
- [ ] All unverified Forever-specific guidance labeled clearly
- [ ] CurseForge logo, description, screenshots, license and changelog reviewed
- [ ] Submit file as **Beta** until live verification warrants Release

This checklist is intentionally not pre-checked: automation cannot certify a real client session.
