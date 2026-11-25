"""Aroused placement fix (2026-11-18): scrotum on Sized Apparel's balls position.

The aroused sprites that draw their own scrotum or sheath were anchored by their bounding box on the
human penis base, so the scrotum's bottom sat where the human shaft starts and the shaft root sat far
above the crotch (up to ~60 px on south). Sized Apparel's human balls picture (Balls/Penis_<size>_<dir>)
shows where it puts a scrotum. Each such sprite is moved so its opaque bottom lands on the human balls'
bottom (south and east), and on east its left edge on the balls' left edge; south stays centred.
The shift is measured on the plain sprite and applied to every variant of the same hediff, size and
direction, so variants stay aligned with it. A sprite that already reaches the right edge is not
moved further right. Rest pictures and the slit/no-scrotum types
(Crocodilian, Hemi, Cloacal, DemonTentacle, Elf) are not changed.
Writes Staging/AnchorFix/{ours/Horny, paste/Horny} and Staging/AnchorFix-review.png.
Run: python -I Build-AnchorFix.py
"""
import os, re
from PIL import Image, ImageDraw

ART = os.path.dirname(os.path.abspath(__file__))
MOD = os.path.dirname(ART)
WORK = os.path.dirname(os.path.dirname(MOD))
SA = r"C:\Program Files (x86)\Steam\steamapps\common\RimWorld\Mods\sized-apparel-zero\Textures\SizedApparel\BodyParts\Human\Penis"
OURS = os.path.join(MOD, "Textures", "SizedApparel", "BodyParts", "Human", "Penis", "Horny")
PASTE = OURS   # the dragon/cat set moved into this mod on 2026-11-25
OUT = os.path.join(ART, "Staging", "AnchorFix")
SCROTUM = {"FoxPenis": OURS, "WolfPenis": OURS, "LynxPenis": OURS, "RabbitPenis": OURS, "DeerPenis": OURS,
           "BovinePenis": OURS, "PigPenis": OURS, "NeedlePenis": OURS, "RaccoonPenis": OURS,
           "DragonPenis": PASTE, "CatPenis": PASTE}


def bbox(im):
    return im.getchannel("A").point(lambda v: 255 if v > 40 else 0).getbbox()


def shifted(im, dx, dy):
    out = Image.new("RGBA", im.size, (0, 0, 0, 0))
    out.paste(im, (dx, dy), im)
    return out


def main():
    balls = {(s, d): bbox(Image.open(os.path.join(SA, "Balls", f"Penis_{s}_{d}.png")).convert("RGBA")) for s in range(6) for d in ("south", "east")}
    log = []
    for hd, folder in SCROTUM.items():
        where = "paste" if folder == PASTE else "ours"
        od = os.path.join(OUT, where, "Horny"); os.makedirs(od, exist_ok=True)
        plain_suffix = "_RNW" if folder == PASTE else ""
        files = os.listdir(folder)
        for s in range(6):
            for d in ("south", "east"):
                plain = os.path.join(folder, f"{hd}_{s}{plain_suffix}_{d}.png")
                im = Image.open(plain).convert("RGBA")
                if im.width < 64:
                    continue
                b, hb = bbox(im), balls[(s, d)]
                dy = hb[3] - b[3]
                dx = (hb[0] - b[0]) if d == "east" else 0
                if b[2] >= 510 and dx > 0:
                    dx = 0          # already at the right edge (deer size 5 side): do not push it further out
                # every file of this hediff, size and direction (plain and variants)
                pat = re.compile(rf"^{hd}_{s}(_[A-Za-z]+)?_{d}\.png$")
                for f in files:
                    if not pat.match(f):
                        continue
                    v = Image.open(os.path.join(folder, f)).convert("RGBA")
                    if v.width < 64:
                        continue
                    nv = shifted(v, dx, dy)
                    nb = bbox(nv)
                    if nb[0] <= 0 or nb[1] <= 0 or nb[2] >= 511 or nb[3] >= 511:
                        log.append(f"EDGE {f} {nb}")
                    nv.save(os.path.join(od, f))
                log.append(f"{hd:12} {s} {d:5} shift ({dx:+d},{dy:+d})")
    print("\n".join(log))
    review(balls)


def review(balls):
    tint = (236, 196, 168)
    def t(im):
        r, g, b, a = im.split()
        return Image.merge("RGBA", (r.point(lambda v: v * tint[0] // 255), g.point(lambda v: v * tint[1] // 255), b.point(lambda v: v * tint[2] // 255), a))
    rows = list(SCROTUM.items())
    cols = [(d, s, k) for d in ("south", "east") for s in (1, 3, 5) for k in ("before", "after")]
    cell = 120
    sheet = Image.new("RGBA", (130 + cell * len(cols), 24 + cell * len(rows)), (70, 70, 70, 255))
    dr = ImageDraw.Draw(sheet)
    for r, (hd, folder) in enumerate(rows):
        dr.text((4, 24 + r * cell + 50), hd, fill="white")
        where = "paste" if folder == PASTE else "ours"
        suf = "_RNW" if folder == PASTE else ""
        for c, (d, s, k) in enumerate(cols):
            tile = Image.new("RGBA", (512, 512), (120, 100, 80, 255))
            ghost = Image.open(os.path.join(SA, "Balls", f"Penis_{s}_{d}.png")).convert("RGBA")
            hp = Image.open(os.path.join(SA, "Horny", f"Penis_{s}_{d}.png")).convert("RGBA")
            for g in (ghost, hp):
                if g.width >= 64:
                    a = g.getchannel("A").point(lambda v: v // 3)
                    tile.alpha_composite(Image.merge("RGBA", (*Image.new("RGB", g.size, (60, 230, 255)).split(), a)))
            p = os.path.join(folder if k == "before" else os.path.join(OUT, where, "Horny"), f"{hd}_{s}{suf}_{d}.png")
            im = Image.open(p).convert("RGBA")
            if im.width >= 64:
                tile.alpha_composite(t(im))
            sheet.alpha_composite(tile.crop((136, 96, 416, 376)).resize((cell, cell), Image.LANCZOS), (130 + c * cell, 24 + r * cell))
    for c, (d, s, k) in enumerate(cols):
        dr.text((130 + c * cell + 10, 4), f"{d[0].upper()}{s} {k}", fill="white")
    sheet.save(os.path.join(ART, "Staging", "AnchorFix-review.png"))


if __name__ == "__main__":
    main()
