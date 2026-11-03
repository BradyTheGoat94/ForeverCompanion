# Forever Companion — Content verification worksheet

Use this worksheet before promoting any guide entry to **Forever verified**. Pre-release entries must not imply confirmed Forever mechanics.

## Per-entry required fields
- `entry_id`: stable identifier
- `module`: legacy / alt-leveling / dungeon / loot / class / leveling / endgame / professions / pvp / reference
- `title`: player-facing name
- `game_version`: Forever client build or `pending`
- `source_type`: official / client-observed / community / general
- `source_url`: link if available
- `checked_at`: ISO date
- `confidence`: forever-verified / community-reported / general-wow / pending-client
- `player_action`: concrete, beginner-friendly next step
- `requirements`: level, role, quest, or unknown
- `notes`: caveats, conflicts and follow-up

## Verification gates
1. Never call an entry verified without a dated official source or observed released-client evidence.
2. Keep general WoW and other expansion guidance clearly separated from Forever mechanics.
3. Dungeon bosses require encounter-specific evidence before publishing ability names, loot tables, or drop rates.
4. Class sequences must include availability checks for talents, procs, cooldowns and spell unlocks; never present a fixed macro as an optimal rotation.
5. Item and loot entries must distinguish confirmed drops from candidate loot and omit unsourced percentages.
6. Alt/legacy entries must not assert account-wide unlocks or reset cadence until verified.
7. External assets must be distributed only with appropriate rights; prefer game-provided texture APIs when available.
8. Review CurseForge packaging, attribution, addon API compliance, and in-client behavior before submission.

## Acceptance matrix
| Area | Offline UI | Source audit | Client verification |
| --- | --- | --- | --- |
| Legacy | Pending | Pending | Blocked pre-release |
| Alt leveling | Pending | Pending | Blocked pre-release |
| Dungeon mechanics | Pending | Pending | Blocked pre-release |
| Dungeon loot | Pending | Pending | Blocked pre-release |
| 27 specs | Pending | Pending | Blocked pre-release |
| Endgame | Pending | Pending | Blocked pre-release |
| Professions | Pending | Pending | Blocked pre-release |
| PvP | Pending | Pending | Blocked pre-release |

Update each cell with the CI run or source link when evidence exists. No fabricated pass statuses.
