# Class and spell icon identity audit

Reviewed November 2, 2026. All class and spell artwork is referenced from the
installed Blizzard client. No Blizzard icon files are extracted or shipped.
Generated project banner artwork is separate from the class/skill icon system.

## Class identity

`Icons.lua` uses `Interface\Glues\CharacterCreate\UI-CharacterCreate-Classes`
with the nine exact class crops published in Blizzard's SharedConstants source.
These crops deliberately retain the non-rounded right edges (0.49609375,
0.7421875, 0.98828125). Unknown class tokens show a question mark. The dashboard,
class banner, class strip and general rotation tiles share this mapping. The old
spell-icon proxies have been removed from the class-handbook data.

Source: [Blizzard SharedConstants mirror](https://github.com/Gethe/wow-ui-source/blob/classic/Interface/AddOns/Blizzard_SharedXML/SharedConstants.lua).
Class-sheet usage: [Blizzard QuestInfo source mirror](https://github.com/Ennie/wow-ui-source/blob/master/FrameXML/QuestInfo.lua).

## Named ability artwork

A curated representative cue is used only when its exact name occurs in the
full instructional sentence. A generic request to choose a blessing, poison,
pet or imbue does not invent a particular ability. The cue and lookup status
appear in selected-priority detail and the tooltip. Multi-action sentences may
use one named representative icon; the whole sentence remains authoritative.

The resolver uses optional `C_Spell.GetSpellTexture(name)` with a guarded legacy
`GetSpellTexture` fallback only when the modern function is absent. It accepts
only positive finite integer file IDs. Nil, invalid, fractional or erroring
results show a question mark. It retries on later renders; misses are not cached.
Switching from a class-sheet image to a spell image resets TexCoord to the full
image, preventing the previous class crop from cutting off the spell artwork.

Source: [Blizzard Spell API documentation mirror](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/SpellDocumentation.lua).
The API accepts names/IDs/links and may return nothing for an unknown spell.

An icon lookup does not prove spell ownership, training, rank, talent selection,
optimal priority or current usability. Names are currently authored in English;
localized clients may show a question mark. No unverified cross-version spell
IDs or guessed textures are substituted. Actual Forever texture loading and
spell-name resolution remain live-client acceptance items. Offline previews
approximate client icons; they cannot visually certify Blizzard artwork.
