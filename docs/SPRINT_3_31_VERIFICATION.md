# 3.31 interface overhaul — 2026-11-08

Implemented on `develop`. This update changes addon-owned presentation and manual planning tools; it does not alter `main`, fabricate combat data, or automate gameplay.

## Interface coverage

- Main application shell: quieter frame and header, bounded metadata, consistent title hierarchy, adaptive navigation rows and footer spacing.
- Dashboard: one card style, simpler action tiles and checklist rows, clearer reading contrast, compact data-status strip.
- Class guides: shared tabs and controls; selected rows use an edge cue rather than a saturated fill.
- Talent planning: larger talent tiles and readable names/ranks, dynamic detail-sidebar spacing and footer placement; draft and recommendation behavior is preserved.
- Quest journal: bounded name/zone/status columns, pagination below the visible rows, informative empty states and less unused space before details.
- Professions: shared summaries and a new material-goal form/table. Add, edit, cancel and remove manual goals on screen. Quantities are validated; duplicate, invalid and stale edits cannot overwrite another goal. Tab and Shift-Tab move through the form fields; Enter submits.
- Catalogs: consistent search fields, hints, focus styling, selected rows and long-title detail flow.
- Bank: item names and counts have separate columns, and missing snapshots or empty searches explain the next action.
- Notes, Legacy, Alts, PvP and Settings: shared surfaces, actions, typography and bounded status messages.
- Meter and navigation HUD: consistent close controls, readable empty states, bounded labels and a font-independent resize grip. Both meter themes, native data display and secret-value guards are retained.

## Review gallery

Run the mocked UI and then `python tests/render_design_review.py --output work/design-review`. The gallery renders 15 captured widget layouts. It uses actual addon geometry, labels, colors and bundled project artwork. Blizzard icons and installed game fonts are approximated; sample character and quest names are test fixtures. The meter view deliberately contains no invented combat values.

The renderer now supports Windows font fallback, UTF-8 snapshots, backdrop colors, input hints and bounded single-line text. Existing CI preview commands remain supported.

## Validation

- All addon Lua files compile under Lua 5.1.
- All 13 Lua smoke suites pass, including the complete mocked UI and new atomic material-update tests.
- The full material form workflow is exercised: add, edit, validation failure, stale-edit rejection, cancel and removal.
- Compact navigation geometry, search-hint updates, native quest pickups, eligibility filtering, talent allocation and secret-safe meter behavior remain covered.
- Python packaging tests: 11 pass; the case-collision creation test skips on Windows because the filesystem cannot create two files with the same case-insensitive name.
- Manifest/package validation, curated legacy-API audit, no-combat-automation audit and guide preflight pass.

## Remaining acceptance limits

A running Forever client was not available. Offline rendering does not establish actual native font rasterization, texture availability, protected-value propagation, GPU draw order or live addon compatibility. Check expanded and compact windows, UI scaling, long names, talent scrolling, material editing, map pickup interaction and both meter skins in the game.

The separate older `release_audit.py` still has the previously recorded timer-scheduling and existing quest-arrow/ring asset review findings. This development package does not waive that gate or claim production client acceptance. Quest pickup coverage and eligibility boundaries remain as documented in the 3.30 verification record.
