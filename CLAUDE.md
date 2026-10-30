@AGENTS.md

## Claude-specific notes

- Active mod: `mods/RJWAnimalTextures` (RimWorld 1.6). Read its README before changing it; it records per-hediff decisions and exceptions.
- Game install: `C:\Program Files (x86)\Steam\steamapps\common\RimWorld` — read-only reference.
  Workshop: `C:\Program Files (x86)\Steam\steamapps\workshop\content\294100` — read-only.
- Player.log: `%USERPROFILE%\AppData\LocalLow\Ludeon Studios\RimWorld by Ludeon Studios\Player.log`.
- `ArtInventory/` and `capture/` are development-only. Never ship them, and never overwrite reference images.
- Never overwrite a live texture without first archiving it under `ArtInventory/`.
- Installing into the game Mods folder, building the DLL, and Git writes each need explicit approval.

## Sprite structure (Sized Apparel genitals)

Each sprite shows the genital of one hediff (one gene/species) in one slot. A slot is the combination of:

- **State:** rest → `Penis/`, erect → `Penis/Horny/`. `Penis/Balls/` is a separate layer.
- **Size index 0–5**, from hediff severity: 0 below 0.20, 1 from 0.20, 2 from 0.40, 3 from 0.60, 4 from 0.80, 5 from 1.01.
- **Direction:** `south` (front), `east` (side), `north` (rear). West is mirrored from east by the game.

File name: `Textures/SizedApparel/BodyParts/Human/Penis/{|Horny/|Balls/}<Hediff>_<size>_<direction>.png`. There is no `_RNW`/`_default` suffix unless `BodypartDetail_Penis.xml` in Sized Apparel defines a variation for that hediff. One hediff = 54 files.

Rules for every sprite:

- **Canvas:** 512×512 RGBA, transparent background. Blank placeholders are a fully transparent 4×4.
- **Orientation:** south erect points up; east erect points up-right; rest hangs. North is blank unless real rear art exists.
- **Position:** the base (where the organ meets the crotch) must sit on the same anchor point as the existing live sprite for that slot, across all sizes and both states. Measure the anchor from the live sprite; do not guess it.
- **Balls are normally blank.** The scrotum or sheath is drawn inside the rest and erect pictures, so the organ is one seamless image. A separate ball sprite would be positioned independently and can drift or overlap. Only fill a ball file when the README documents why (for example `FoxPenis_2_north`).
- **Size is the size of the organ, not of the image.** Sized Apparel draws the whole texture at one cell, so the visible organ's pixel extent is its on-pawn size. Size N must show a visibly smaller organ than size N+1 in the same state and direction. Erect is normally larger than rest at the same size. Verify by measuring the opaque bounding box and, where relevant, shaft length and width — not by trusting the file or canvas size.
- **Height ladders:** rest follows the human penis ladder; erect follows the dragon ladder (south 46, 57, 67, 144, 167, 199 px; east 59, 62, 81, 130, 144, 180 px). Per-hediff exceptions are recorded in the README; follow them and record any new one there.
- **Tinting:** Sized Apparel multiplies penis textures by skin color. Fur meant to follow the pawn is a gray mask; strong colors will be darkened by the tint.

## Using a reference image for a sprite

When the user supplies a reference and points at a sprite to create or improve:

1. Identify the target slot exactly: hediff, state, size, direction. Open the current live sprite for that slot and its neighbors (size ±1, other state, other direction).
2. Analyze the reference: species, view angle, state, whether it includes the sheath/scrotum/knot, its orientation, and its background (must become transparent).
3. Explain how it will fit: rotation or mirroring needed to match the slot's orientation, the target organ size from the ladder and the neighbors, and the anchor it must sit on.
4. Build into a staging folder, never directly into `Textures/`.
5. Validate: dimensions, alpha, file name, anchor, organ size strictly between its size neighbors, nothing cropped at the canvas edge. Produce a review sheet next to the current sprite.
6. Get approval, archive the old file, then replace it and update the README if the reasoning or an exception changed.

State which measurements were made and which points are assumptions.
