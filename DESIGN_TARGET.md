# Visual fidelity targets (develop branch)

The user's two reference concepts show a premium black-and-gold fantasy guide, not a generic gray addon. The current implementation is a **native UI approximation**, not a pixel-perfect reproduction.

## Dashboard target

- Wide dark panel with antique gold outer trim, branded crest, title and version, narrow top header, and left icon navigation.
- Welcome banner with castle/fantasy visual treatment.
- Top three cards: Character Overview, Quick Actions, Progress & Goals.
- Bottom two cards: Recommended Next Steps and Today's Focus.
- Bottom account-safety note: describe read-only data and absence of gameplay automation without claiming client certification.
- Functional values must come from the real client when available, and show honest unavailable states otherwise. No invented quest, skill, gear, or progression percentages.

## Class guide target

- Sidebar and class-specific header with class icon and title.
- Separate class-guide views: Overview, Talents, Rotations, Leveling, Dungeons, PvP, Gear & Stats, Professions.
- Rotation context selector, numbered icon priority tiles, detailed explanations, and quick tips.
- All abilities and talent data are **general references until tested on WoW Forever**; never label them verified without evidence.
- Responsive layout, readable text, keyboard/slash accessibility, and persistent preferences.

## Implemented in this development cycle

- Native black/gold sidebar, large branded header, responsive window sizing and compact layout.
- Real welcome banner with a lightweight skyline, class/profile card, four quick actions, XP/quest/material progress, recommended next steps and per-character focus checklist.
- Optional client API reads with safe fallbacks and event-driven XP/profession refresh.
- Source-validated offline UI preview with simulated data and explicit watermark.
- Lua 5.1 syntax, mocked client interaction, release audit and ZIP packaging in CI.

## Second overnight implementation pass

- Added a native Leveling hero with character/class icon, preferred role, selected spec preview, rotation context, live XP percentage and progress bar. Unavailable XP is labeled rather than fabricated.
- Replaced five stock rotation buttons with gold-accented, selectable ability-priority tiles. Full advisory text remains available via tooltip and guide details.
- Relocated rotation/spec controls, quest focus text and checklist actions away from the sidebar to reduce collisions.
- Added a reusable gold-trimmed header to Leveling, Quests, Dungeons, Professions, PvP and Settings, with context-specific labels and icons.
- Added a read-only quest journal overview showing active/in-progress/ready counts, top reported zones and explicit stale-data warnings. A guarded Classic-era legacy quest-log reader is now available when the modern C_QuestLog API is absent.
- Added detected profession skill/cap summaries with current-cap distance; recipe availability remains unverified.
- Expanded mocked client tests and added a second illustrative PNG preview generated from the actual Leveling widget snapshot.

## Still missing / release blockers

- Original goat/ram crest artwork and high-quality fantasy banner texture; built-in game icons are temporary stand-ins.
- Further class-guide visual fidelity, including original crest artwork, class-specific visual assets, and deeper verified ability/talent coverage.
- Pixel-level verification on a real WoW Forever client, including all seven sections, icons, compact layout, UI scales and SavedVariables.
- Verified target-client Interface number, game flavor availability on CurseForge, licensing decision, real in-game screenshots and author-side submission.
- The offline preview is an illustration of mocked widgets, **not proof of in-game rendering**.

Prioritize functional fidelity and test coverage over artificial commit counts. Never merge develop into main without explicit approval.

## Third overnight implementation pass

- Added native black-and-gold quest briefing cards for current quest count, ready-to-turn-in count, leading reported zone, selected quest and its first objective.
- Added a real quest-ready progress strip and explicit cached/stale/unavailable states. Quest list, filter, paging and long-form guidance were repositioned below the cards.
- Added native profession skill/cap bars for up to two detected professions and an aggregate **manual** material-goal bar, with selected handbook context.
- Reflowed profession handbook buttons and material +/- controls to prevent overlap with the new panels.
- Added mock-client interaction assertions for the cards, navigation, stale quest scans, restricted profession APIs, manual material updates, and unavailable player class/level reads.
- Added two new illustrative CI preview images, both checked against required headings from the actual mocked UI tree.
- Replaced repeated generic class and crafting paragraphs with 63 distinct class-specific and 54 profession-specific planning tips. These remain **general, unverified reference guidance**, not optimized Forever builds.
- Guarded client reads for class, level, XP, zone and profession skill conversion; missing data is explicitly labeled instead of inventing a character class or skill level.

Still to do: genuine original crest/banner art, finer pixel-level layout fidelity, client-verified spells and talents, live-client interaction and scaling tests, license approval, confirmed Interface number and supported CurseForge game flavor.
