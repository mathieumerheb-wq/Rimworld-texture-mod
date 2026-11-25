"""Per-pawn penis variants for Sized Apparel, derived from a hediff's live sprites.

How Sized Apparel does variety (verified in its source, sized-apparel-zero/source/SizedApparel):
  - Variation/VariationHediffComp.cs: when a penis hediff is created, SizedApparelBodyPartDetail picks
    one name at random from the hediff's entry in SizedApparelBodyPartVariationDef "PenisDetail"
    (BodypartDetail_Penis.xml) and saves it on the hediff. "default" means no suffix.
  - SizedApparelUtility.CheckBodyPartGraphicExists: the file is
    {hediff}_{size}_{variation}_{direction}; when that file is missing it falls back to the
    no-variation file of the same size, so a variant only needs the pictures that differ.
  - Dev mode has "Set BodyPart Variation" to change it per pawn. Hediffs made before the variation
    was defined keep variation null (the default look).

Variants built here: each sprite is narrowed (Slender) or widened (Thick) across its long axis: straight
across for rest pictures and aroused front views (they hang or point up), and across the axis found by
principal-axis analysis of the opaque pixels for aroused side views. The line through the pixel centroid along that
axis stays fixed, so the length stays on the size ladder and the organ stays on its anchor. Aroused
side views are then moved so their bottom row and the centre of their bottom 25 rows match the
original (the scrotum skews the axis there).
Writes Staging/PenisVariants/<hediff>/{Penis,Horny}/<hediff>_<size>_<Variant>_<dir>.png, plus
Staging/PenisVariants/<hediff>-review.png.
Run: python -I Build-PenisVariants.py [Hediff ...]   (default: LynxPenis)
"""
import math, os, sys
from PIL import Image, ImageDraw

ART = os.path.dirname(os.path.abspath(__file__))
LIVE = os.path.join(os.path.dirname(ART), r"Textures\SizedApparel\BodyParts\Human\Penis")
OUT = os.path.join(ART, "Staging", "PenisVariants")
VARIANTS = {"Slender": 0.80, "Thick": 1.25}
WORK = os.path.dirname(os.path.dirname(os.path.dirname(ART)))
PASTE = LIVE   # the dragon/cat set moved into this mod on 2026-11-25
# Where each hediff's current look lives, and its file suffix. The dragon's current look is the
# Sized Apparel paste set, registered by Sized Apparel as the "RNW" variation.
SOURCES = {"DragonPenis": (PASTE, "_RNW")}


def axis(im):
    a = im.getchannel("A")
    w, h = im.size
    px = a.load()
    n = sx = sy = 0.0
    pts = []
    for y in range(0, h, 2):
        for x in range(0, w, 2):
            if px[x, y] > 40:
                pts.append((x, y)); sx += x; sy += y; n += 1
    cx, cy = sx / n, sy / n
    cxx = sum((x - cx) ** 2 for x, y in pts) / n
    cyy = sum((y - cy) ** 2 for x, y in pts) / n
    cxy = sum((x - cx) * (y - cy) for x, y in pts) / n
    ang = 0.5 * math.atan2(2 * cxy, cxx - cyy)        # long axis angle
    return (cx, cy), (math.cos(ang), math.sin(ang))


def widen(im, s, vertical=False):
    (cx, cy), (ux, uy) = axis(im)
    if vertical:
        # rest pictures hang and front views point up: scale straight across, about the centre column
        ux, uy = 0.0, 1.0
    nx, ny = -uy, ux                                   # across the organ
    k = 1 / s - 1                                      # inverse map: p_in = c + (I + k n n^T)(p_out - c)
    a = 1 + k * nx * nx; b = k * nx * ny; d = 1 + k * ny * ny
    # PIL affine: x_in = a*x + b*y + c0, y_in = b*x + d*y + f0
    c0 = cx - a * cx - b * cy
    f0 = cy - b * cx - d * cy
    big = im.resize((im.width * 2, im.height * 2), Image.LANCZOS)
    out = big.transform(big.size, Image.AFFINE, (a, b, c0 * 2, b, d, f0 * 2), resample=Image.BICUBIC)
    return out.resize(im.size, Image.LANCZOS)


def base_x(im, rows=25):
    b = bbox(im); a = im.getchannel("A").load()
    xs = [x for y in range(b[3] - rows, b[3]) for x in range(b[0], b[2]) if a[x, y] > 40]
    return sum(xs) / len(xs)


def reseat(orig, new):
    """Aroused side views: the scrotum skews the axis, so the bottom drifts. Move the new picture so
    its bottom row and the centre of its bottom 25 rows match the original's."""
    b0, b1 = bbox(orig), bbox(new)
    dx = round(base_x(orig) - base_x(new)); dy = b0[3] - b1[3]
    out = Image.new("RGBA", new.size, (0, 0, 0, 0))
    out.paste(new, (dx, dy), new)
    return out


def bbox(im):
    return im.getchannel("A").point(lambda v: 255 if v > 40 else 0).getbbox()


def main(hediffs):
    for hd in hediffs:
        rows = []
        for state, sub in (("rest", ""), ("aroused", "Horny")):
            for d in ("south", "east"):
                row = {"default": [], **{v: [] for v in VARIANTS}}
                for s in range(6):
                    base, suf = SOURCES.get(hd, (LIVE, ""))
                    src = os.path.join(base, sub, f"{hd}_{s}{suf}_{d}.png")
                    im = Image.open(src).convert("RGBA")
                    row["default"].append(im)
                    od = os.path.join(OUT, hd, "Horny" if sub else "Penis")
                    os.makedirs(od, exist_ok=True)
                    if im.width < 64:
                        # blank picture: the variant gets the same blank, so its file set is complete
                        for v in VARIANTS:
                            row[v].append(im); im.save(os.path.join(od, f"{hd}_{s}_{v}_{d}.png"))
                        continue
                    b0 = bbox(im)
                    for v, f in VARIANTS.items():
                        side_aroused = bool(sub) and d == "east"
                        new = widen(im, f, vertical=not side_aroused)
                        if side_aroused:
                            new = reseat(im, new)
                        new.save(os.path.join(od, f"{hd}_{s}_{v}_{d}.png"))
                        row[v].append(new)
                        b1 = bbox(new)
                        print(f"{hd} {state:7} {d:5} {s} {v:7} box {b0} -> {b1}  h {b0[3]-b0[1]}->{b1[3]-b1[1]}  w {b0[2]-b0[0]}->{b1[2]-b1[0]}")
                rows.append((f"{state} {d}", row))
            # North: Sized Apparel uses the variant's name for every direction once its south file
            # exists, and RimWorld shows the south picture when north is missing. Copy the plain north.
            base, suf = SOURCES.get(hd, (LIVE, ""))
            od = os.path.join(OUT, hd, "Horny" if sub else "Penis")
            for s in range(6):
                north = Image.open(os.path.join(base, sub, f"{hd}_{s}{suf}_north.png")).convert("RGBA")
                for v in VARIANTS:
                    north.save(os.path.join(od, f"{hd}_{s}_{v}_north.png"))
        review(hd, rows)


def review(hd, rows):
    cell = 150
    lab = 150
    names = ["default"] + list(VARIANTS)
    sheet = Image.new("RGBA", (lab + cell * 6, 24 + cell * len(rows) * len(names)), (150, 120, 90, 255))
    dr = ImageDraw.Draw(sheet)
    r = 0
    for title, row in rows:
        for n in names:
            dr.text((4, 24 + r * cell + 65), f"{title}\n{n}", fill="white")
            for s, im in enumerate(row[n]):
                if im.width < 64:
                    continue
                sheet.alpha_composite(im.crop((136, 60, 416, 340)).resize((cell, cell), Image.LANCZOS), (lab + s * cell, 24 + r * cell))
            r += 1
    for s in range(6):
        dr.text((lab + s * cell + 55, 4), f"size {s}", fill="white")
    sheet.save(os.path.join(OUT, f"{hd}-review.png"))


if __name__ == "__main__":
    main(sys.argv[1:] or ["LynxPenis"])
