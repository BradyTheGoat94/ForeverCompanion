# Forever Companion artwork

## Original project assets (3.15 beta)

These two decorative assets were generated for this project using the built-in
image-generation tool on November 2, 2026. They are not extracted Blizzard artwork,
game screenshots, stock images, or representations of a verified game location.
Class, skill, profession and navigation icons continue to reference the installed
client's native `Interface/Icons` textures. The project remains independent.

| Asset | Intended use | Packaged format |
| --- | --- | --- |
| `ForeverCompanion/Media/Citadel.tga` | Dashboard banner and subtle class-card backdrop | 1024×256, RGB, uncompressed true-color TGA |
| `ForeverCompanion/Media/Crest.tga` | Header and dashboard heraldic emblem | 256×256, RGBA, uncompressed true-color TGA |

The generated PNG masters were resized and converted to power-of-two TGA textures
for addon packaging. Crest alpha is preserved. No generated text or spell icons
are used. The main project license decision is unchanged; this record documents
provenance and does not assert trademark clearance or CurseForge acceptance.

## Final generation prompts

**Citadel:** Use case: stylized-concept. Asset type: original fantasy environment
texture for Forever Companion's in-game guide dashboard. Create a wide panoramic
gothic high-fantasy citadel at blue hour: elegant distant towers and cathedral
spires, cloudy indigo sky, a few warm gold windows, dark wooded hills. Painterly
premium fantasy-game loading-screen quality. The architectural focal point sits in
the RIGHT THIRD. LEFT HALF is very dark midnight-blue mist and subtle distant
silhouettes, calm negative space for readable white UI text. Main composition
should work as a shallow horizontal banner crop across the middle 40 percent of
the picture. No people, no game UI, no text, no logos, no border, no watermark.
Original architecture, not a replica of any existing Blizzard location. Landscape
wide composition.

**Crest:** Use case: logo-brand. Asset type: original fantasy addon emblem for
Forever Companion. A polished circular antique-gold heraldic medallion with an
elegant ivory mountain-goat head in three-quarter profile facing right, long
graceful swept-back horns and a short beard. Strong iconic silhouette with rich
but restrained sculpted metallic detail, ivory enamel, aged gold edge, deep
charcoal interior. Premium black-and-gold fantasy RPG guide aesthetic. Centered
isolated circular emblem, generous transparent padding outside the gold circle.
No lettering, no initials, no text, no crown, no shield, no watermark. The design
must be original and readable when reduced to 64 pixels. Transparent background.

## Verification limits

CI validates exact texture names, dimensions, bit depth and TGA image type, and
checks that ZIP bytes match the project assets. The offline native renderer uses
the bundled textures and captured widget coordinates, colors, labels, visibility,
and parent relationships. It approximates client fonts and Blizzard icons;
real-client texture loading, scaling and text appearance must still be tested.

## Warrior header (3.16 beta)

`ForeverCompanion/Media/Warrior.tga` is a new original generated illustration,
1024×256 RGB uncompressed TGA, fitted from its PNG master with a top-aligned crop.
It appears only for the Warrior preview. The source is original fictional character
art, not a Blizzard character, a game screenshot or evidence of available gear.

Built-in image-generation prompt: Use case: stylized-concept. Asset type: original
illustrated header artwork for the Warrior class page of an independent fantasy RPG
companion addon, Forever Companion. Wide cinematic panorama, premium hand-painted
fantasy game artwork. Rightmost third: a battle-worn human warrior with
shoulder-length brown hair in elaborately engraved antique-gold and charcoal plate
armor, a large round burnished shield and broad pauldrons, resolute expression,
chest-up three-quarter view. Behind him dark volcanic mountains and faint warm
ember light. Left TWO THIRDS: very dark charcoal and midnight-blue smoke, almost
black negative space for class title and readable UI copy; no major subjects there.
Sophisticated restrained colors, warm metal highlights, crisp dramatic facial
detail, depth and atmosphere. It should feel elegant and heroic, not cartoonish.
No text, no lettering, no frames, no UI, no badges, no trademarks, no logos, no
watermark. Original fictional character and original armor, not an existing named
character. Compose for a shallow wide class banner crop.
