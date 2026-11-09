# Forever Companion 3.38 beta — visual review

## Changes
- Class-guide reading cards with measured wrapping; separate stat priorities, comparison advice, reported targets and source notes.
- Consistent outlines and hover feedback on custom topic controls and shared rows.
- Settings command reference, bank typography and compact short-list panels.
- Quest discovery resizes around visible results and retains readable empty-state explanations.
- Continuation/end-of-page cues and scroll-offset clamping when content shrinks.
- Charcoal/gold world-map toolbar; existing marker coordinates and map behavior preserved.

## Verification
- Lua 5.1 syntax and 17 Lua regression suites, including actual TOC/widget construction.
- Additional checks across all supported specialization profiles for measured card heights and retained source advice.
- Short/empty discovery layouts, compact bank layout and continuation/scroll-clamping checks.
- 27 offline captures, including bank, map toolbar, discovery empty state and both meter themes.
- Python packaging regression suite, guide preflight and curated API/combat-automation static audits.

## Limits
Offline previews approximate fonts and native icons. They do not verify real client rendering, DPI, protected/secret value propagation or combat behavior. No fabricated damage is used in the previews. In-game acceptance and Interface 16001 compatibility remain pending. The older root release_audit.py policy conflicts remain unresolved; the dedicated beta packager validates manifest/archive contents but does not establish client compatibility.

## Install
Close the game. Replace the old ForeverCompanion addon folder with the ForeverCompanion folder inside BradysForeverCompanion-3.38.0-beta.zip. Keep your SavedVariables files to retain preferences. Start the client and enable the addon.
