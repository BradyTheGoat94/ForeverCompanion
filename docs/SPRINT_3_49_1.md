# 3.49.1 beta — Training discovery and layout repair

The reported screenshot showed 3.48.0, before the training module shipped.
This build includes all 3.49.0 work and adds a visible Training Guide sidebar
entry directly below Class Guides. `/fc training` and `/fc open training guide`
also work. Opening the standalone guide preserves the selected main page.

The main scroll viewport now explicitly clips its children. The Leveling Route
parent is resized to contain the objective itinerary. The 13-entry sidebar fits
both full and compact layouts. Offline geometry cannot certify WoW's actual
clipping behavior, so check the reported overlap in the client after installing.

The Training Guide defaults to At your level. Coming soon and At this trainer
are direct tabs; other views remain in the filter menu. Client spell textures,
localized names and native rank text have guarded fallbacks. Unknown icons use
a question mark. The UI separates base reference estimates from current trainer
prices and never substitutes a base price for an unknown live price. Tooltip
IDs and prerequisites remain available without cluttering the row title.

References: the MIT-licensed training data attribution remains in TrainingData.lua;
spell icon/subtext APIs were checked against the Forever client documentation:
https://raw.githubusercontent.com/Gethe/wow-ui-source/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/SpellDocumentation.lua

No automated spell purchases, casts, or trainer filter changes are performed.
Main is unchanged. In-game visual and trainer verification remains pending.
