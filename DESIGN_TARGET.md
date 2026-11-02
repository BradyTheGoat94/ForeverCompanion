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

## Still missing / release blockers

- Original goat/ram crest artwork and high-quality fantasy banner texture; built-in game icons are temporary stand-ins.
- Class-guide visual hierarchy, rotation tile layout, and rich data coverage comparable to the second reference image.
- Pixel-level verification on a real WoW Forever client, including all seven sections, icons, compact layout, UI scales and SavedVariables.
- Verified target-client Interface number, game flavor availability on CurseForge, licensing decision, real in-game screenshots and author-side submission.
- The offline preview is an illustration of mocked widgets, **not proof of in-game rendering**.

Prioritize functional fidelity and test coverage over artificial commit counts. Never merge develop into main without explicit approval.
