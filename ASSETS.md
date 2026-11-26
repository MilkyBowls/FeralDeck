# FeralDeck Field Journal assets

All shipped media lives in `Media/`. The addon loads local files and the installed client's creature models and role icons.

## Typography and card backs

| Shipped file | Source and license |
| --- | --- |
| Barlow-Medium.ttf, Barlow-SemiBold.ttf, Barlow-MediumItalic.ttf | Jeremy Tribby and the Barlow Project Authors. [Barlow](https://github.com/jpt/barlow), SIL Open Font License 1.1. |
| Cinzel-Regular.ttf | Natanael Gama and the Cinzel Project Authors. [Cinzel](https://github.com/NDISCOVER/Cinzel), SIL Open Font License 1.1. |
| WolfSeal.tga | FeralDeck card back incorporating Lorc's [Wolf head](https://game-icons.net/1x1/lorc/wolf-head.html) under [CC BY 3.0](https://creativecommons.org/licenses/by/3.0/). The icon was recolored, resized, and set into an engraved frame. |

The fonts' notices ship in Media as Barlow-OFL.txt and Cinzel-OFL.txt.

## Interface audio

Original sound effects synthesized for FeralDeck and released under CC0 1.0. All cues ship as 44.1 kHz mono MP3s at 128 kbps.

| Shipped files | Events |
| --- | --- |
| `hit.mp3`, `hit2.mp3`, `hit3.mp3` | Rotating clean-hit impacts |
| `shield.mp3`, `guard.mp3`, `break.mp3` | Shield absorption, guard, and shield break |
| `mark.mp3`, `technique.mp3`, `signature.mp3` | Mark application, non-damaging utility actions, and signatures |
| `combo.mp3`, `pack.mp3`, `tunnel.mp3`, `whiteout.mp3` | Generic combos and the Pack Hunt, Hold the Tunnel, and Whiteout synergies |
| `place.mp3`, `reveal.mp3`, `discovery.mp3`, `perk.mp3` | Card placement, reveal, first discovery, and perk unlock |
| `victory.mp3`, `defeat.mp3`, `draw.mp3`, `interrupted.mp3` | Battle results |

## Original journal art

Created for FeralDeck and released under [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/). The TGA files use uncompressed RGB or RGBA with power-of-two dimensions.

| Shipped file | Artwork |
| --- | --- |
| `OwnershipGold.tga`, `OwnershipDark.tga` | Original wolf emblems for collected and uncollected enemy nameplates. |
| `Types/*.tga` | 18 original creature type badges. Each uses a distinct silhouette and palette. |
| `TypeCorners.tga` | Atlas of 18 engraved corner motifs in creature type order. |
| `CardNameplate.tga` | Transparent engraved plate used for creature names, type badges, and rarity. |
| `Journal.tga` | Faded paper grain, inset ruled border and elevation contours |
| `Table.tga` | Forest-green tabletop with a worn brass rule |
| `Landscape.tga` | Layered mountains, conifers and distant light behind the creature model |
| `Gloom.tga` | Moonlit woodland with gravestones and a ruined chapel |
| `Drylands.tga` | Sunlit sandstone canyon with a natural arch |
| `Marsh.tga` | Cypress wetland with fireflies and still water |
| `Volcanic.tga` | Lava channels winding between basalt columns |
| `Mine.tga` | Timbered tunnel with lanterns, mining carts, and blue crystals |
| `Coast.tga` | Moonlit surf below rocky cliffs and sea arches |
| `Twilight.tga` | Violet forest glade with luminous mushrooms |
| `Highlands.tga` | Misty hills and standing stones at dawn |
| `City.tga` | Lantern-lit fantasy capital with a stone archway and spires |
| `Filigree.tga` | Transparent portrait border and engraved corner details |
| `CardBack.tga` | Compass rose on the green journal cover |
| `Foil.tga` | Transparent iridescent reflection for foil, reveal and placement |

The visual reference review included Mattias Lejbrink's [Parchment](https://opengameart.org/content/parchment), Kenney's [RPG UI expansion](https://kenney.nl/assets/ui-pack-rpg-expansion) and [Game Icons](https://kenney.nl/assets/game-icons). The nine habitat paintings above were generated for FeralDeck and shipped as 512 × 512 textures. Each has a softer, muted 256 × 256 Depth version for use behind creature models on smaller cards. Woodland, Snow, and Jungle use their established paintings and Depth variants.

Blizzard supplies creature models, fallback icons, font objects, and standard widget highlights at runtime. 

GildedFrame.tga combines original scrollwork and a recolored [Laurels](https://game-icons.net/1x1/lorc/laurels.html) ornament by Lorc under [CC BY 3.0](https://creativecommons.org/licenses/by/3.0/).

CardAura.tga is an original transparent halo and mote texture for the showcase card.

GlassShell, GlassPanel, and GlassButton are original TGA textures for the translucent interface.

ArenaVignette and ArenaBrass are original lighting and metallic trim textures for the Solo Battle arena.

ArenaHighlands and ArenaWoodland are original generated environment paintings created for FeralDeck. The battle view renders the Blizzard creature models as separate live layers.

The glass theme uses original TGA textures. JournalShell is the 1,024 × 1,024 window surface. JournalOpaque is the matching solid backing for the opaque setting. JournalPane and JournalStrip cover reading surfaces and compact rows. HeroShade keeps text legible over illustrated headers. GlassButton supplies the shared control fill and hover sheen.

The Neutral variants of JournalShell, JournalOpaque, JournalPane, and JournalStrip preserve the original alpha channels and use grayscale color channels for runtime theme tinting.
