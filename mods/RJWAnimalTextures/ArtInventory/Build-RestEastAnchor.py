"""Re-anchors resting side-view (east) sprites on the Sized Apparel human penis.

Measured 2026-11-17 (base point = mean x of the opaque pixels in the top 8 rows, and the top y):
  human Penis_N_east base x 250-252 at every size; top y 247, 245, 243, 237, 233, 230.
  DragonPenis (paste set) base x 198-223: 28-53 px behind the human base. In game the dragon slit
  showed toward the tail (Azhalia, Female body, size 1).
  CatPenis (paste set) and RabbitPenis sizes 0-1: base x 229-234, 17-21 px behind.
  WolfPenis sizes 0-2: base x matches, but the top is 7, 5, 3 px above the human top (Yuna, Thin, size 0).
Dragon (all sizes), cat and rabbit (sizes 0-1): shifted horizontally so the base x equals the human base x of the same size
(height kept: these sheaths reach up the belly). Wolf sizes 0-2: shifted down to the human top.
Writes Staging/RestEastAnchor/{Penis paths} and Staging/RestEastAnchor-review.png.
Run: python -I Build-RestEastAnchor.py
"""
import os
from PIL import Image, ImageDraw

ART = os.path.dirname(os.path.abspath(__file__))
MOD = os.path.dirname(ART)
WORK = os.path.dirname(os.path.dirname(MOD))
SA = r"C:\Program Files (x86)\Steam\steamapps\common\RimWorld\Mods\sized-apparel-zero\Textures\SizedApparel\BodyParts\Human\Penis"
OURS = os.path.join(MOD, r"Textures\SizedApparel\BodyParts\Human\Penis")
PASTE = OURS   # the dragon/cat set moved into this mod on 2026-11-25
OUT = os.path.join(ART, "Staging", "RestEastAnchor")


def base(im, rows=8):
    a = im.getchannel("A")
    b = a.point(lambda v: 255 if v > 40 else 0).getbbox()
    px = a.load()
    xs = [x for y in range(b[1], b[1] + rows) for x in range(b[0], b[2]) if px[x, y] > 40]
    return round(sum(xs) / len(xs)), b[1]


def shifted(im, dx, dy):
    out = Image.new("RGBA", im.size, (0, 0, 0, 0))
    out.alpha_composite(im, (dx, dy)) if dx >= 0 and dy >= 0 else out.paste(im, (dx, dy), im)
    return out


JOBS = []   # (label, src, dest_rel, size)
for s in range(6):
    JOBS.append(("DragonPenis", os.path.join(PASTE, f"DragonPenis_{s}_RNW_east.png"), ("paste", f"DragonPenis_{s}_RNW_east.png"), s, "x"))
# Cat and rabbit: only sizes 0-1 sit behind. From size 2 the penis tip is in the top rows, so the
# base measure is not the attachment there, and the sprites already overlap the human penis.
for s in range(2):
    JOBS.append(("CatPenis", os.path.join(PASTE, f"CatPenis_{s}_RNW_east.png"), ("paste", f"CatPenis_{s}_RNW_east.png"), s, "x"))
    JOBS.append(("RabbitPenis", os.path.join(OURS, f"RabbitPenis_{s}_east.png"), ("ours", f"RabbitPenis_{s}_east.png"), s, "x"))
for s in range(3):
    JOBS.append(("WolfPenis", os.path.join(OURS, f"WolfPenis_{s}_east.png"), ("ours", f"WolfPenis_{s}_east.png"), s, "y"))


def main():
    human = {s: base(Image.open(os.path.join(SA, f"Penis_{s}_east.png")).convert("RGBA")) for s in range(6)}
    results = {}
    for label, src, (where, name), s, axis in JOBS:
        im = Image.open(src).convert("RGBA")
        bx, by = base(im)
        dx = human[s][0] - bx if axis == "x" else 0
        dy = human[s][1] - by if axis == "y" else 0
        new = shifted(im, dx, dy)
        d = os.path.join(OUT, where)
        os.makedirs(d, exist_ok=True)
        new.save(os.path.join(d, name))
        nb = base(new)
        clip = new.getchannel("A").point(lambda v: 255 if v > 40 else 0).getbbox()
        print(f"{label:12} size {s}  shift ({dx:+d},{dy:+d})  base {bx},{by} -> {nb[0]},{nb[1]}  box {clip}")
        results[(label, s)] = (im, new)
    review(results, human)


def review(results, human):
    labels = ["DragonPenis", "CatPenis", "RabbitPenis", "WolfPenis"]
    cell = 220
    sheet = Image.new("RGBA", (130 + cell * 6, 24 + cell * 2 * len(labels)), (150, 120, 90, 255))
    d = ImageDraw.Draw(sheet)
    crop = (176, 176, 336, 336)
    for r, lab in enumerate(labels):
        for k, which in enumerate(("live", "new")):
            y0 = 24 + (r * 2 + k) * cell
            d.text((4, y0 + 100), f"{lab}\n{which}", fill="white")
            for s in range(6):
                if (lab, s) not in results:
                    continue
                tile = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
                hum = Image.open(os.path.join(SA, f"Penis_{s}_east.png")).convert("RGBA")
                ghost = Image.merge("RGBA", (*Image.new("RGB", hum.size, (40, 220, 255)).split(), hum.getchannel("A").point(lambda v: v * 2 // 3)))
                tile.alpha_composite(ghost)
                tile.alpha_composite(results[(lab, s)][k])
                td = ImageDraw.Draw(tile)
                hx, hy = human[s]
                td.line([(hx, 176), (hx, 336)], fill=(255, 255, 0, 200), width=1)
                td.line([(176, hy), (336, hy)], fill=(255, 255, 0, 200), width=1)
                sheet.alpha_composite(tile.crop(crop).resize((cell, cell), Image.NEAREST), (130 + s * cell, y0))
    for s in range(6):
        d.text((130 + s * cell + 90, 4), f"size {s}", fill="white")
    sheet.save(os.path.join(ART, "Staging", "RestEastAnchor-review.png"))


if __name__ == "__main__":
    main()
