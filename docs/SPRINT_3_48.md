# Forever Companion 3.48.0-beta — Minimap launcher

The minimap now has a crest button for the main addon, enabled by default.

- Left-click: open or close Forever Companion, matching `/fc`.
- Right-click: main addon, map search, transparent overlay, hide and position-reset actions.
- Drag with the left mouse button to move around the minimap edge. Position and visibility are saved per character.
- `/fc minimap` restores the button, `/fc minimap hide` hides it, and `/fc minimap reset` restores its default position and visibility.

The launcher uses the existing original crest and native minimap-button artwork. No extra addon/library is required. It follows minimap resizing and UI scale changes. Cursor coordinates are converted using the minimap's effective scale. Drag updates run only during a drag, and releasing a drag cannot also toggle the addon. A missing minimap is retried on normal load/world events.

29 Lua suites passed, including geometry, scaled dragging, visibility persistence, idle teardown, drag-release suppression and toggling the actual main addon through the launcher. The 15 Python tests ran with 14 passes and one platform skip; release, API, automation and ZIP audits passed. No new timer site was added.

In-game verification remains pending for visual placement, interactions with other minimap buttons/skins, window scaling and drag behavior. The default positioning follows a round minimap edge; custom square-minimap skins may need manual positioning. Interface 16001 remains a declared beta target. This update stays on develop, leaves main unchanged and has not been uploaded to CurseForge.
