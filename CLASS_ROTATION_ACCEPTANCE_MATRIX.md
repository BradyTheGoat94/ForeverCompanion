# Forever Companion — Class Rotation Acceptance Matrix (beta)

This matrix is for manual client verification. Existing priorities are **illustrative** until observed in WoW Forever. Never infer that a spell is unavailable from a partial or blocked spellbook scan.

## Repeat for each of the nine classes

1. Open the class guide on a fresh character, then select each available specialization and the leveling, dungeon, boss, AoE and PvP contexts.
2. Verify that every visible action tile has a readable name, icon or text fallback, explanation, and keyboard/mouse access.
3. Verify an untrained or unavailable spell is identified as **unconfirmed** (not silently presented as usable); compare against the in-game spellbook.
4. At low level, verify the guide does not demand a high-level talent or spell as the only next action.
5. At higher level, compare displayed priorities against the character's actual talents, spells, resource constraints, and combat log; record discrepancies rather than claiming optimization.
6. Switch contexts and specs repeatedly; confirm the selected state, scroll position, tooltips and compact layout remain usable.
7. Reload UI and relog; confirm saved guide preferences persist without modifying combat bindings or taking protected actions.

## Class-specific scenarios

| Class | Scenario to test | Failure to flag |
| --- | --- | --- |
| Warrior | Rage-starved pull; tank stance; Execute range | Suggested spend without sufficient rage or unsafe stance assumption |
| Paladin | Seal/Judgement interaction; healer/tank role | Reapplication advice incompatible with observed Forever mechanics |
| Hunter | Pet passive/active; Aimed Shot and Multi-Shot cooldowns | Accidental pet pull or false cooldown independence |
| Rogue | Energy starvation; Slice and Dice refresh | Unconditional finisher without combo points |
| Priest | Wand filler; healing assignment | Damage priority overriding emergency healing |
| Shaman | Totem availability; shock mana cost | Assumed totem learned or impossible resource budget |
| Mage | Frost root/slow; Fire cast interruption | Guide claims uninterrupted casting under pressure |
| Warlock | Pet control; Life Tap at low health | Unsafe health-to-mana advice |
| Druid | Form changes and form-specific resources | Cat abilities recommended in caster/bear form |

## Evidence record for each discrepancy

- Date, client build, Interface number, addon commit SHA
- Class, level, spec/talents, selected context, spellbook screenshot
- Expected guidance, observed in-game behavior, relevant combat-log excerpt
- Classification: illustrative / client-observed / log-tested; **never** use 'verified optimal' without comparative evidence
- Fix commit and retest outcome

## Release rule

A passing offline mocked UI test does not replace these live-client checks. If a guide has not been tested, keep its illustrative warning prominent and never label it a verified Forever rotation. No automatic casting, targeting, crafting or combat input is permitted.
