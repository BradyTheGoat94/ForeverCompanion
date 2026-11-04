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

## Final visual and icon acceptance matrix

Test at **1920x1080**, **2560x1440**, and a smaller windowed resolution where possible, at UI scale 100% and a reduced scale. Record screenshots of each state, not just the default dashboard.

| Screen | Required checks |
| --- | --- |
| Dashboard | All cards visible, decorative art does not obscure text, no clipped headings, navigation state obvious |
| Class selection | All nine class icons display the intended Blizzard class, no atlas crop bleed, selected class unmistakable |
| 27 specialization pages | Correct spec title and role; priority order understandable to beginners; every ability icon matches the text or shows an honest fallback |
| Rotation workspace | Readable steps and cooldown notes, manual-only instructional presentation, no cast/action buttons |
| Gear & Stats | Role-specific stat priority with a visible evidence caveat, no unverified numerical caps presented as fact |
| Dungeons and loot | Search and pagination functional, no fabricated drop rates or confirmed-only labels for historical data |
| Legacy, alts and leveling | Navigation and saved checklist state survive reload; speculative mechanics labeled |
| Professions, PvP and settings | Controls usable with mouse, text contrast adequate, no overlay collision |

**Stop-ship conditions:** a missing or wrong class icon; misleading spell art with no fallback; unreadable/clipped navigation; a runtime Lua error; any combat automation; or unsupported gameplay claims presented as verified.

When the game client is available, capture the client build and UI screenshots before marking any of these checks complete. Code review cannot substitute for the screenshot comparison.
