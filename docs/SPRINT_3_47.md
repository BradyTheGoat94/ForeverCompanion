# Forever Companion 3.47.0-beta — Reliability and usability pass

November 9, 2026. Based on develop 8369f08 (3.46.0). Main remains unchanged.

## Search and refresh work

The previous map search rebuilt note, quest and service records while typing and paging. The new index is reused for query/filter/selection changes. Quest, zone, addon-load, note and service-index changes invalidate it; visible refreshes use the existing coalescing queue. Provider indexing completion, merchant observations, provider rescans and cleared visit records now invalidate the hub too. **Refresh results** explicitly rebuilds the index. A zone change also invalidates it when next accessed, even if a zone event was missed.

Use Up/Down to choose a result, Enter to activate it, and Escape to close the search panel. A cyan rail identifies the keyboard selection. Mouse activation updates that selection as well. These shortcuts apply to the focused search field; no global key binding or Tab targeting behavior is changed.

Tests count source builds to verify reuse while typing and keyboard selection, rather than claiming an unmeasured frame-rate increase. Real client profiling is still needed for performance claims.

## Navigation handoff and service data

Previously a new navigation attempt stopped the old custom arrow before establishing that the new destination could start. Invalid coordinates now fail before touching navigation, and a failed replacement preserves the previous arrow. If only the native waypoint succeeds, the obsolete custom arrow stops. If only the custom arrow succeeds, its obsolete addon-owned native pin is cleared. A waypoint placed afterward by the player remains untouched. The result message states when the old navigation is still active.

Service revalidation previously returned the stale input record after finding a matching current key. It now returns the current provider/visit record, so labels and source information reflect the rescan. Visited observations cannot silently resume as provider references at identical coordinates after observations are cleared. This does not verify live NPC availability, phase, stock or reachability.

## Panels, overlay and notes

Search, personal notes and the service atlas now scale down to fit available viewport space and react to display/UI-scale changes. Their logical layout remains unchanged, and they register with the client's Escape panel stack. The search field also closes its own panel explicitly on Escape.

The overlay checks its current zone on the faster player-update cycle and clears old-zone artwork/markers while awaiting the slower full refresh. It refits when viewport dimensions change, and its title/control placement follows the actual map width. Unreadable player-position objects and map-art identifiers fail closed. Existing click-through, presets and opacity behavior remain available.

Personal notes can be starred through Actions. Starred notes sort first and can be viewed using the category filter's **Starred notes** choice. The search index includes their starred label. **Undo delete** restores the last deleted note during this login session, retaining its stable ID, category and star. It refuses restoration if the note limit or an ID conflict prevents it. This is one session-local undo, not a persistent recycle bin. Deletion confirmation remains in place.

Recent destinations now deduplicate personal notes by stable note identity even if their coordinates have changed. Malformed result metadata and unknown saved history types are ignored safely; existing valid notes and destinations remain intact.

## Validation

28 Lua suites passed, including a new navigation handoff/ownership suite; 15 Python tests ran (14 passed, one platform skip). The unified acceptance command also passed API, automation, release and package audits. Regression tests cover failure preservation, native/custom handoff, player-owned pins, private-like inputs, current service records, observed/provider identity, search-cache reuse/invalidation, keyboard Enter/Escape behavior, responsive panel calculations, viewport changes, fast old-zone clearing, starred-note ordering and deletion undo.

The updated search and notes layouts were rendered and visually inspected using offline native-widget snapshots. Fonts/icons are approximated; previews are not game screenshots. In-game verification remains pending for navigation transitions, real UI scaling, keyboard focus, combat click-through, map loading/phasing and coexistence with other addons. Interface 16001 remains the declared beta target, not a client-certified claim. No CurseForge upload was performed.
