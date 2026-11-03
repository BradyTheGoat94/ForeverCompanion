# Forever Companion: external verification pass — 2026-11-03

This is an evidence ledger, **not** a claim that all content or UI has been verified. Audit target: develop.

## Directly checked against live public sources

1. **Arms Warrior stat priority** — the published Wowhead Forever Arms page (updated October 29, patch 1.60.1) lists Hit to 8%, Expertise to 6.5%, Crit, Strength, Agility, Haste, and additional Hit. This agrees in broad order with GearStats.lua. **Evidence level: published guide corroboration, NOT level-60 benchmark**: Wowhead explicitly calls this speculative because beta was capped at level 30.
   https://www.wowhead.com/forever/guide/classes/warrior/arms/stat-priority-pve-dps
2. **Protection Warrior stats** — Icy Veins' October 27 Forever guide separates defensive Stamina > Armor > Agility > Avoidance > Defense from offensive Expertise > Hit > Agility > Strength > Stamina. GearStats.lua's defensive/offensive distinction agrees. **Evidence level: guide corroboration, not actual endgame raid testing.**
   https://www.icy-veins.com/wow-forever/protection-warrior-tank-pve-stat-priority
3. **Stat-system changes** — Wowhead's Forever character-panel article documents unified Hit and Crit categories and explanatory tooltips. Do not copy Classic's separate melee/spell/ranged stat model into the addon.
   https://www.wowhead.com/forever/news/updated-character-panel-ui-in-wow-forever-explains-stats-in-detail-383013
4. **Client-data vs gameplay evidence** — ForeverDB labels its stat reference as extracted from beta client build 1.60.1.70707. This corroborates the build reference in VerifiedAbilities.lua but does **not** independently verify each ability ID, spell availability, icon, or recommended rotation.
   https://foreverdb.net/stats
5. **Scope of prelaunch testing** — contemporary independent leveling guides report the beta was level-capped at 30 and that level-60 builds/raid results were not live-tested. Treat all BiS and level-60 'optimal' claims as predictions until logs and tests exist.
   https://nossuary.com/guides/wow-forever/
6. **CurseForge beta policy** — an approved Beta file can sync for users opting into betas; project moderation and file approval remain required.
   https://support.curseforge.com/support/solutions/articles/9000197242

## Findings requiring follow-up

- All 27 specialization rotation recommendations: **not verified** against live level-60 parses.
- All 27 spec stat priorities: **two Warrior profiles externally corroborated** in this pass; remaining profiles still need source-by-source review.
- Each spell ID and spell icon: **not verified** individually against current client data or live rendering.
- Each boss, item, loot source and dungeon mechanic: **not verified** individually; do not advertise confirmed drop rates.
- Legacy, alt leveling and professions: **not verified** as complete/current Forever-specific guides.
- UI colors, spacing, visual parity, clipping, font readability and actual icons: **not verified by real-client screenshots**.
- Automated tests and ZIP: **not confirmed passing** by this pass.

## Release labeling rule

Mark information as 'client-data reference' only if tied to a build; 'published guide recommendation' only if the linked source supports it; 'game-tested' only with a reproducible live test; 'benchmark validated' only with logged, repeatable comparison. Do not imply a published guide or datamine is the same as live verification.
