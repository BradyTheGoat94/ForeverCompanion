# Forever Companion — Complete Guide Coverage

**Goal:** One read-only in-game reference for a new player through endgame, including alts. This is a coverage plan, not a claim that Forever-specific mechanics are verified.

## Evidence labels (mandatory for guide entries)
- **Forever verified:** linked to a dated official Forever source or confirmed in the released client; cite source and patch/version.
- **Community reported:** attributed community information, date and uncertainty.
- **General WoW guidance:** broadly applicable advice, explicitly not confirmed for Forever.
- **Unknown / pending client:** never invent unlocks, costs, rewards, rotations or boss abilities.

## Content modules and acceptance criteria

| Module | Required content | Offline completion criteria |
| --- | --- | --- |
| Legacy system | Unlocks, account/character scope, progression, reset rules, rewards, limitations, FAQ | Structured reference and unknown-state placeholders; verified claims require citations |
| Alt leveling | First-character vs alt path, shared unlocks (if any), routes, dungeon alternatives, class prep | Side-by-side journey cards with explicit unknown account-wide mechanics |
| Dungeons | Entrance, requirements, trash threats, each boss, abilities, interrupt/dispels, tank/healer/DPS tips, loot | Boss-by-boss checklist; no fabricated encounter names |
| Classes / 27 specs | Beginner spell sequence, priority, role, talents, gearing, leveling, PvP, source confidence | First 3 actionable steps visible without hover; fallback for unavailable skills |
| Leveling / quests | Zone bands, quests, important unlocks, travel, group options | Level-aware suggested next steps and clear source labels |
| Endgame | Attunements, raids, currencies, reputations, gear progression, weekly/daily tasks | Progression checklist and reset details only when verified |
| Professions / economy | Trainers, gathering, recipes, material routes, costs, tradeoffs | Source-tagged progression and vendor lookup |
| PvP | Battleground rules, objectives, gearing, class fundamentals | Objectives and role-specific quick references |
| Reference | Items, currencies, mounts, vendors, achievements, key FAQs | Searchable index with provenance and unknown-state support |

## Pre-release implementation order
1. Add navigation and searchable reference shells for Legacy, Alt Leveling, Dungeons and Endgame; ensure every unsupported claim is clearly marked.
2. Create source/provenance schema and offline fixtures for each module.
3. Expand nine classes and 27 specs with clear beginner actions, with Forever-specific verification labels.
4. Populate sourced content from official Forever documentation and dated community reports; do not extrapolate from other WoW versions.
5. Run offline UI snapshot and Lua mock tests across every tab, long text, narrow layouts, and missing data.
6. After client release, validate actual APIs, mechanics, icons, and screenshots before public release.

**Safety:** Guidance only. Never automate spells, quests, movement, purchases or combat actions.
