# Compact meter: 3.34 beta

The meter now follows the compact title-bar, class-bar and quick-menu arrangement familiar from Details. This is an independent native-API implementation; it does not import Details code or artwork.

## Controls

| Action | Control |
| --- | --- |
| Move the window | Drag the title bar while unlocked |
| Resize | Drag the lower-right grip; size snaps to whole rows |
| Choose a display | Combat icon or right-click the title bar |
| Choose a segment | Clock icon or Shift-right-click the title bar |
| Open quick displays | Right-click a player row or empty body |
| Inspect a player | Left-click the player row |
| Reach other raid members | Mouse wheel over the player list |
| Cycle displays | Ctrl + mouse wheel over a player row |
| Change layout, text, columns or skin | Gear icon, or /fcmeter options |
| Reset shared combat data | Reset icon, then confirm |
| Hide / reopen | Close icon; /fcmeter; dashboard Combat Meter button |

The right-hand columns show total and per-second values for damage/healing views. The options menu can switch to a single metric column. Hover provides unrounded public values and full public player names. Secret values remain direct native labels. Larger text and both existing skins are available without slash commands.

## Layouts

| Layout | Width | Visible rows | Height |
| --- | ---: | ---: | ---: |
| Compact | 280 | 4 | 134 |
| Standard | 320 | 8 | 218 |
| Expanded | 440 | 12 | 302 |

The viewport can scroll through every returned native source. A selected public GUID follows native rank changes even if that player moves off screen. Shrinking or growing the window clamps scrolling without closing a valid player breakdown.

## Verification and limits

Lua tests cover compact geometry, separate name/total/rate columns at the minimum width, both themes, direct secret-value display, public compact formatting, 40-source scrolling, selection through reordering/resizing, named history selection, options and reset confirmation. Reset is blocked in combat, including when combat begins after opening the confirmation. Missing native capabilities are disabled or explained.

Offline gallery captures use actual mocked widget geometry and contain no invented combat values. Fonts and native icons are approximated. Target-client font contrast, secret-value propagation, mouse behavior, drag sizing and native-session reset still require in-game acceptance. The API supports fewer analyses than the complete Details addon; unsupported views are not invented.

The beta package builder and static checks do not establish target-client compatibility. The existing release_audit.py findings about legacy timers/navigation artwork remain unresolved.

## Reference review

- [Details UI API](https://github.com/Tercioo/Details-Damage-Meter/blob/master/API%20UI.txt): toolbar, segment and window interaction patterns.
- [Details profile source](https://github.com/Tercioo/Details-Damage-Meter/blob/master/functions/profiles.lua): compact bar/title/text configuration patterns.
- [Blizzard-generated DamageMeter documentation](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/DamageMeterDocumentation.lua): native session names/IDs, source totals/rates and ResetAllCombatSessions. Actual capabilities remain runtime-checked for Forever.
