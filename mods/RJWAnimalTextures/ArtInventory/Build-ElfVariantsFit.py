"""Fits the ElfPenis Uncut and Foreskin variants (Build-ElfPenis.ps1 -Variant, which warps Sized
Apparel's human variant pictures) onto the live plain ElfPenis sprites of the same size, state and
direction. The plain sprites were later moved onto the shared height ladder (aroused sizes 0-2 by
Build-SmallErect.ps1), so the raw warps came out smaller and off the anchor. Each variant is scaled
evenly to the plain sprite's opaque height (front views) or box diagonal (side views, which lie at
different angles), then placed on the plain sprite's anchor:
  rest south: top centre    rest east: top, left edge
  aroused south: bottom centre    aroused east: bottom, left edge
Blank (4x4) files are left as they are. Rewrites the files in Staging/ElfVariants/Penis in place.
Run: python -I Build-ElfVariantsFit.py
"""
import math, os
from PIL import Image

ART = os.path.dirname(os.path.abspath(__file__))
LIVE = os.path.join(os.path.dirname(ART), "Textures", "SizedApparel", "BodyParts", "Human", "Penis")
ST = os.path.join(ART, "Staging", "ElfVariants", "Penis")


def bbox(im):
    return im.getchannel("A").point(lambda v: 255 if v > 40 else 0).getbbox()


def main():
    for sub, state in (("", "rest"), ("Horny", "aroused")):
        for var in ("Uncut", "Foreskin"):
            for s in range(6):
                for d in ("south", "east"):
                    ref = Image.open(os.path.join(LIVE, sub, f"ElfPenis_{s}_{d}.png")).convert("RGBA")
                    p = os.path.join(ST, sub, f"ElfPenis_{s}_{var}_{d}.png")
                    im = Image.open(p).convert("RGBA")
                    if ref.width < 64 or im.width < 64:
                        continue
                    rb, ib = bbox(ref), bbox(im)
                    crop = im.crop(ib)
                    if d == "south":
                        f = (rb[3] - rb[1]) / crop.height
                    else:
                        # side views lie at different angles: match the overall length (box diagonal)
                        f = math.hypot(rb[2] - rb[0], rb[3] - rb[1]) / math.hypot(crop.width, crop.height)
                    crop = crop.resize((max(1, round(crop.width * f)), max(1, round(crop.height * f))), Image.LANCZOS)
                    if d == "south":
                        x = round((rb[0] + rb[2]) / 2 - crop.width / 2)
                    else:
                        x = rb[0]
                    y = rb[1] if state == "rest" else rb[3] - crop.height
                    out = Image.new("RGBA", ref.size, (0, 0, 0, 0))
                    out.alpha_composite(crop, (x, y))
                    out.save(p)
                    print(f"{state:7} {var:8} {s} {d:5} {ib} -> {bbox(out)}  (plain {rb})")


if __name__ == "__main__":
    main()
