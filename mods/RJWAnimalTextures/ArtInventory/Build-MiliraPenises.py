"""Milira copies of this mod's penis sprites (and of the Sized Apparel dragon/cat paste set).

Why: Sized Apparel looks for body-part textures in the pawn's race folder first
(SizedApparelsDatabase.GetSupportedBodyPartPath), trying the hediff's own name and then the generic
"Penis". The SizedApparel-Milira patch ships BodyParts/Milira_Race/Penis/Penis_*, so a Milira always
finds the generic penis there and never reaches the Human folder where FoxPenis, WolfPenis, ... live.
Files named after our hediffs in BodyParts/Milira_Race are found first instead.

Milira's penis sits lower on the canvas and is drawn smaller (measured 2026-11-18 against Sized
Apparel's human Penis_* of the same size). Each sprite is scaled about the human anchor and moved onto
the Milira anchor, so every species keeps its own placement relative to the anchor:
  aroused south  scale 0.74  human bottom centre (256, 263) -> (256, 341)
  aroused east   scale 0.61  human bottom-left   (246, 267) -> (263, 341)
  rest south     scale 0.74  human top centre    (256, 250) -> (256, 332)
  rest east      scale 0.61  human top-left      (239, 246) -> (260, 330)
  north (both)   blank: the Milira patch draws no penis from behind
Ball files are copied as they are (ours are blank), so Milira's own balls are not drawn under ours.
Writes Staging/Milira/Penis/{.,Horny,Balls} and Staging/Milira-review.png.
Run: python -I Build-MiliraPenises.py
"""
import os
from PIL import Image, ImageDraw

ART = os.path.dirname(os.path.abspath(__file__))
MOD = os.path.dirname(ART)
WORK = os.path.dirname(os.path.dirname(MOD))
OURS = os.path.join(MOD, "Textures", "SizedApparel", "BodyParts", "Human", "Penis")
PASTE = None   # the dragon/cat set is in this mod since 2026-11-25, so OURS covers it
OUT = os.path.join(ART, "Staging", "Milira", "Penis")
MILIRA = r"C:\Program Files (x86)\Steam\steamapps\common\RimWorld\Mods\sized-apparel-races-milira\Textures"

T = {  # (state, dir): (scale, human anchor, milira anchor)
    ("aroused", "south"): (0.74, (256, 263), (256, 341)),
    ("aroused", "east"): (0.61, (246, 267), (263, 341)),
    ("rest", "south"): (0.74, (256, 250), (256, 332)),
    ("rest", "east"): (0.61, (239, 246), (260, 330)),
}
BLANK = Image.new("RGBA", (4, 4), (0, 0, 0, 0))


def convert(im, state, d):
    if im.width < 64 or d == "north":
        return BLANK
    s, (hx, hy), (mx, my) = T[(state, d)]
    big = im.resize((round(im.width * s), round(im.height * s)), Image.LANCZOS)
    out = Image.new("RGBA", im.size, (0, 0, 0, 0))
    out.alpha_composite(big, (round(mx - hx * s), round(my - hy * s)))
    return out


def sources():
    for root, only in ((OURS, None),):
        for sub in ("", "Horny", "Balls"):
            folder = os.path.join(root, sub)
            for f in sorted(os.listdir(folder)):
                if not f.endswith(".png") or (only and not f.startswith(only)):
                    continue
                yield os.path.join(folder, f), sub, f


def main():
    n = 0
    for path, sub, f in sources():
        od = os.path.join(OUT, sub)
        os.makedirs(od, exist_ok=True)
        im = Image.open(path).convert("RGBA")
        if sub == "Balls":
            im.save(os.path.join(od, f))
        else:
            d = f.rsplit("_", 1)[1][:-4]
            convert(im, "aroused" if sub == "Horny" else "rest", d).save(os.path.join(od, f))
        n += 1
    print("files", n)
    review()


def review():
    body = {d: Image.open(os.path.join(MILIRA, "Milira", "Pawn", "Body", f"Naked_Female_BaseBody_{d}.png")).convert("RGBA") for d in ("south", "east")}
    mil = os.path.join(MILIRA, "SizedApparel", "BodyParts", "Milira_Race", "Penis")
    rows = [("Milira default", lambda sub, s, d: os.path.join(mil, sub, f"Penis_{min(s, 2) if not sub else s}_{d}.png")),
            ("fox", lambda sub, s, d: os.path.join(OUT, sub, f"FoxPenis_{s}_{d}.png")),
            ("wolf", lambda sub, s, d: os.path.join(OUT, sub, f"WolfPenis_{s}_{d}.png")),
            ("lynx", lambda sub, s, d: os.path.join(OUT, sub, f"LynxPenis_{s}_{d}.png")),
            ("dragon", lambda sub, s, d: os.path.join(OUT, sub, f"DragonPenis_{s}_RNW_{d}.png"))]
    cell = 150
    cols = [(sub, d, s) for sub in ("", "Horny") for d in ("south", "east") for s in (1, 3, 5)]
    sheet = Image.new("RGBA", (130 + cell * len(cols), 24 + cell * len(rows)), (150, 120, 90, 255))
    dr = ImageDraw.Draw(sheet)
    for r, (label, getp) in enumerate(rows):
        dr.text((4, 24 + r * cell + 65), label, fill="white")
        for c, (sub, d, s) in enumerate(cols):
            tile = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
            b = body[d].resize((512, 512))
            tile.alpha_composite(b)
            p = getp(sub, s, d)
            if os.path.exists(p):
                im = Image.open(p).convert("RGBA")
                if im.width >= 64:
                    tile.alpha_composite(im)
            sheet.alpha_composite(tile.crop((140, 200, 380, 440)).resize((cell, cell), Image.LANCZOS), (130 + c * cell, 24 + r * cell))
    for c, (sub, d, s) in enumerate(cols):
        dr.text((130 + c * cell + 20, 4), f"{'aroused' if sub else 'rest'} {d[0].upper()} {s}", fill="white")
    sheet.save(os.path.join(ART, "Staging", "Milira-review.png"))


if __name__ == "__main__":
    main()
