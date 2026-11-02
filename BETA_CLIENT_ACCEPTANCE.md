# Forever Companion beta acceptance checklist

This form is completed only after running the exact GitHub Actions ZIP in the real WoW Forever client. Offline CI and preview PNGs cannot satisfy it.

## Build identification

- Commit SHA:
- GitHub Actions run URL:
- ZIP SHA256 (compare with beta-build-manifest.json):
- Addon version:
- WoW Forever client build and interface number:
- Test date:

## Installation and failure reproduction

1. Download the **ForeverCompanion** ZIP artifact from the successful GitHub Actions run for the commit under test. Do not test an older local checkout or an offline preview.
2. Compare the downloaded ZIP SHA256 with `beta-build-manifest.json` when the manifest provides a matching package hash. Record any mismatch as FAIL before installing.
3. Exit the game, remove any previous `Interface/AddOns/ForeverCompanion` directory, and extract the package so `Interface/AddOns/ForeverCompanion/ForeverCompanion.toc` exists (not a doubly nested folder).
4. Launch WoW Forever, enable the addon on the character selection addon list, and record the exact client build/interface version. Do not guess the interface number from the TOC.
5. Open the addon and visit each tab, change tabs repeatedly, scroll to the bottom, reload UI, and verify that settings and plans persist.
6. If a failure occurs, record the first Lua error verbatim, the tab and action that triggered it, and a screenshot. Re-test after a clean UI reload to distinguish intermittent errors from repeatable defects.
7. Never mark a test PASS based on CI, the mocked widget tree, or the illustrative preview PNG alone.

## In-game acceptance

Mark each item PASS / FAIL / NOT TESTED, and record the first Lua error.

| Test | Result | Notes |
| --- | --- | --- |
| Clean install folder contains ForeverCompanion.toc directly | NOT TESTED | |
| Addon loads with no Lua error | NOT TESTED | |
| Reloading UI twice does not duplicate panels or break commands | NOT TESTED | |
| Missing optional APIs show readable fallback content | NOT TESTED | |
| No error when opening guide with incomplete class or zone data | NOT TESTED | |
| Class guide art and black/gold borders match reference | NOT TESTED | |
| Long class names, roles, phase labels and priority text remain inside cards | NOT TESTED | |
| XP unavailable state is visibly distinguished from 0% XP | NOT TESTED | |
| Navigation gold trim and icons remain readable when selected and hovered | NOT TESTED | |
| Rotation tile hover color resets after leaving or changing tabs | NOT TESTED | |
| Navigation, selected tabs, scrolling and window resizing | NOT TESTED | |
| Leveling guidance for all nine classes | NOT TESTED | |
| Spellbook and missing-API behavior | NOT TESTED | |
| Quest guidance and non-automated quest tracking | NOT TESTED | |
| Dungeon role preparation and PvP notes | NOT TESTED | |
| Profession scanner and sourced Camping preview | NOT TESTED | |
| Manual recipe, material, price and purchase budget workflows | NOT TESTED | |
| Save and reload settings, plans and prices | NOT TESTED | |
| No protected gameplay automation | NOT TESTED | |

## Decision

- Release approved: **NO — pending real-client testing**
- Blocking bugs:
- Screenshots from the real client:
- Tester sign-off:

Never mark an item PASS solely because a mocked UI screenshot or CI job succeeded.
