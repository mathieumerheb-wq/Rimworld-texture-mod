# Sized Apparel dragon and cat replacement

**Since 2026-11-25 this set ships inside RJWAnimalTextures** (`mods/RJWAnimalTextures/Textures/SizedApparel/BodyParts/Human/Penis/`, same file names). Sized Apparel's lazy texture loader and RimWorld's texture lookup both take the copy from the last-loaded mod when two mods provide the same path, and RJWAnimalTextures loads after Sized Apparel, so our pictures override Sized Apparel's without touching its folder, and Sized Apparel updates no longer undo them. Nothing needs to be pasted any more. The installed Sized Apparel folder was put back to its own originals (`Archive/Textures`). This folder stays as the history and archive of the set; the build scripts now write into RJWAnimalTextures.

This folder is not a RimWorld mod. `RJWAnimalTextures` is copied into the Mods folder as it is. These files replace the dragon and cat sprites inside Sized Apparel for RJW (SAR version), the local folder `sized-apparel-zero`.

`Textures/` is the new set. It uses the same paths as the installed mod:

`Textures/SizedApparel/BodyParts/Human/Penis/DragonPenis_{0-5}_RNW_{south|east|north}.png`

`Textures/SizedApparel/BodyParts/Human/Penis/CatPenis_{0-5}_RNW_{south|east|north}.png`

and the same names under `Horny/` and `Balls/`.

`Archive/Textures/` is the previous set, with those same paths. The installed Sized Apparel files were not edited when this folder was built.

## Paste

1. Close RimWorld.
2. Copy `Textures` from this folder into:

`C:\Program Files (x86)\Steam\steamapps\common\RimWorld\Mods\sized-apparel-zero`

3. Replace the files when asked. This tree has the `DragonPenis_*_RNW_*` and `CatPenis_*_RNW_*` files.

To go back, copy `Archive/Textures` into that same mod folder and replace the files.

Updating Sized Apparel (for example with an RJW suite update) puts its original dragon and cat files back. Paste `Textures` again after every update. On 2026-11-12 the installed files matched `Archive/Textures` after an update, and the set was pasted again.

Dragon rest south and rest east are genital slits with the scrotum drawn in. Sizes 0 and 1 use the closed slit, sizes 2 and 3 the middle opening with its own side view, and sizes 4 and 5 the widest opening. The side view faces right. Aroused sizes 0 and 1 use the short front penises. Size 2 south is the narrow front. Sizes 3, 4, and 5 are the large end and are drawn about half again as tall: south 144, 167, and 199 pixels, east 130, 144, and 180. Size 3 south is the narrow chevron, size 4 south the wider two-lobe front, and size 5 south the long front. East stays the side view, pointed up-right. Ball files are blank, so they do not draw over the scrotum already in the picture. North is blank, so the old north sprite does not remain.

Dragongirl in Fantasy Races already uses the `DragonPenis` hediff. Pasting these files is what changes her sprite. This set has not been tested in-game.

CatPenis is the same kind of replacement. Rest south sizes 0 and 1 are a closed sheath, with no penis showing. Size 2 is a small opening. Sizes 3, 4, and 5 show the penis in the sheath, from a round opening, to the tip, to the fullest. Rest east sizes 0, 1, and 2 are a closed side sheath. Sizes 3, 4, and 5 are side views with the tip showing, pointed to the right. Aroused south is a front, pointed up, shorter on the small sizes and longer on the large sizes. Aroused east is the side view, pointed up-right. Since 2026-11-12 the aroused heights follow the shared ladder: south 72, 96, 120, 144, 167, 199 pixels, east 70, 90, 110, 130, 144, 180 (built by `RJWAnimalTextures/ArtInventory/Build-CatPenis.ps1`; before, they were 40 to 120 pixels, smaller than the lynx). The same day, see-through holes in the rest and aroused south and east pictures (mostly on the scrotum) were filled with the surrounding color by `RJWAnimalTextures/ArtInventory/Build-FillHoles.ps1 -Gap 2`; sizes and anchors are unchanged. The set before those two changes is in `Archive/2026-11-12-Cat-ladder-holes/`. Ball files are blank, so they do not draw over the scrotum already in the picture. North is blank. Catgirl in Fantasy Races already uses the `CatPenis` hediff. Pasting these files is what changes her sprite. This set has not been tested in-game.

On 2026-11-17 the resting side views were moved forward onto the Sized Apparel human penis's attachment (`RJWAnimalTextures/ArtInventory/Build-RestEastAnchor.py`): DragonPenis all sizes by 27 to 53 px (in game the slit showed back toward the tail), CatPenis sizes 0 and 1 by 21 and 19 px. Heights are unchanged. The earlier files are in `Archive/2026-11-17-RestEastAnchor/`.

On 2026-11-18 the aroused DragonPenis and CatPenis pictures were moved so their scrotum sits on Sized Apparel's human balls position (see the RJWAnimalTextures README, Aroused placement). The earlier files are in `Archive/2026-11-18-AnchorFix/`.
