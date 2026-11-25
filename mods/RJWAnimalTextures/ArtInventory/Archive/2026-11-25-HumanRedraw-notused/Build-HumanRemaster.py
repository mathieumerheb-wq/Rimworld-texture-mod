"""Remaster of Sized Apparel's human penis and balls (Penis/, Penis/Horny/, Penis/Balls/, files Penis_*).

The originals are small paintings scaled up, so every edge is soft and blocky. This keeps each picture's
exact silhouette, pose, size and position (the placement fix and the Milira copies depend on them) and
re-renders it at 4x, then downsamples to the same 512 canvas:
  - regions from the original: outline (dark), glans (pink), skin (the rest); each region mask is
    upsampled, smoothed and re-thresholded, so its edges are clean curves;
  - colours: the original's own skin and glans colours (outline pixels filled from their
    surroundings), upsampled smoothly, so highlights and hue are kept and the blocks go; a soft darker
    rim toward the outline; a light corona line where the glans meets the skin;
  - outline: crisp, about 20% thinner than the original;
  - the soft fade where the picture meets the body keeps its gradient (no hard edge there);
  - sizes 0-1 are copied unchanged: re-rendering made their thin outlines wobbly.
Writes Staging/HumanRemaster/{Penis,Horny,Balls}/<same names> and Staging/HumanRemaster-review.png.
Run: python -I Build-HumanRemaster.py [name ...]   e.g.  Penis_3_south Horny/Penis_3_east
"""
import os, sys
from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageMath

SA = r"C:\Program Files (x86)\Steam\steamapps\common\RimWorld\Mods\sized-apparel-zero\Textures\SizedApparel\BodyParts\Human\Penis"
ART = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(ART, "Staging", "HumanRemaster")
U = 4


def masks(im):
    """outline, pink and skin masks (L, 0/255) and the luma image, at the original size."""
    w, h = im.size
    px = im.load()
    dark = Image.new("L", im.size, 0); pink = Image.new("L", im.size, 0); skin = Image.new("L", im.size, 0)
    luma = Image.new("L", im.size, 0)
    dp, pp, sp, lp = dark.load(), pink.load(), skin.load(), luma.load()
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a < 8:
                continue
            l = (r * 299 + g * 587 + b * 114) // 1000
            lp[x, y] = l
            if l < 95:
                dp[x, y] = 255
            elif r > g + 28 and r > b + 18:
                pp[x, y] = 255
            else:
                sp[x, y] = 255
    return dark, pink, skin, luma


def up_mask(m, blur, thin=0):
    big = m.resize((m.width * U, m.height * U), Image.LANCZOS).filter(ImageFilter.GaussianBlur(blur))
    big = big.point(lambda v: 255 if v >= 128 else 0)
    if thin:
        big = big.filter(ImageFilter.MinFilter(thin))
    return big.filter(ImageFilter.GaussianBlur(U * 0.35))      # anti-aliased edge


def remaster(im):
    if im.width < 64 or im.getchannel("A").getbbox() is None:
        return im.copy()
    dark, pink, skin, luma = masks(im)
    W, H = im.width * U, im.height * U
    a_soft = im.getchannel("A").resize((W, H), Image.BICUBIC).filter(ImageFilter.GaussianBlur(U * 0.8))
    dark_hi = up_mask(dark, U * 0.9, thin=3)                      # thinner outline (MinFilter 3 at 4x)
    pink_hi = up_mask(pink, U * 1.0)
    fill_hi = up_mask(ImageChops.lighter(skin, pink), U * 1.0)
    # alpha: hard where the outline is near, the original soft gradient elsewhere (the body fade)
    near_line = up_mask(dark, U * 0.9).filter(ImageFilter.MaxFilter(U * 4 + 1)).filter(ImageFilter.GaussianBlur(U * 2))
    hard = ImageChops.lighter(dark_hi, fill_hi)
    alpha = Image.composite(ImageChops.lighter(hard, a_soft.point(lambda v: 0)), a_soft, near_line)
    alpha = ImageChops.lighter(alpha, ImageChops.multiply(dark_hi, near_line))
    # colours: the original's own skin and glans colours, with the outline pixels filled from their
    # surroundings (normalised blur), then upsampled smoothly: highlights and hue are kept, blocks go
    fillm = ImageChops.lighter(skin, pink)
    rgb_src = im.convert("RGB")
    chans = []
    wsum = fillm.filter(ImageFilter.GaussianBlur(2.5)).point(lambda v: max(v, 1))
    for c in rgb_src.split():
        num = ImageChops.multiply(c, fillm).filter(ImageFilter.GaussianBlur(2.5))
        chans.append(ImageMath.lambda_eval(lambda e: e["convert"](e["n"] * 255.0 / e["w"], "L"), n=num, w=wsum))
    filled = Image.composite(rgb_src, Image.merge("RGB", chans), fillm)
    rgb = filled.resize((W, H), Image.BICUBIC).filter(ImageFilter.GaussianBlur(U * 0.7))
    # soft darker rim toward the outline, for a rounder skin
    rim = up_mask(dark, U).filter(ImageFilter.GaussianBlur(U * 3.0))
    rgb = Image.composite(Image.new("RGB", (W, H), (150, 150, 150)), rgb, rim.point(lambda v: v * 30 // 255))
    # corona: a darker line where glans meets skin
    corona = ImageChops.multiply(pink_hi.filter(ImageFilter.MaxFilter(U * 2 + 1)), ImageChops.subtract(fill_hi, pink_hi)).filter(ImageFilter.GaussianBlur(U * 0.6))
    rgb = Image.composite(Image.new("RGB", (W, H), (170, 80, 86)), rgb, corona.point(lambda v: v * 2 // 5))
    rgb = Image.composite(Image.new("RGB", (W, H), (26, 22, 22)), rgb, dark_hi)
    out = Image.merge("RGBA", (*rgb.split(), alpha))
    return out.resize(im.size, Image.LANCZOS)


def all_names():
    for sub in ("", "Horny", "Balls"):
        for f in sorted(os.listdir(os.path.join(SA, sub))):
            if f.startswith("Penis_") and f.endswith(".png"):
                yield sub, f


def main(names):
    picked = []
    if names:
        for n in names:
            sub, f = (n.split("/", 1) if "/" in n else ("", n))
            picked.append((sub, f if f.endswith(".png") else f + ".png"))
    else:
        picked = list(all_names())
    pairs = []
    for sub, f in picked:
        im = Image.open(os.path.join(SA, sub, f)).convert("RGBA")
        new = im.copy() if f.split("_")[1] in ("0", "1") else remaster(im)   # sizes 0-1 kept
        od = os.path.join(OUT, sub or "Penis"); os.makedirs(od, exist_ok=True)
        new.save(os.path.join(od, f))
        pairs.append((sub, f, im, new))
    print("files", len(pairs))
    review(pairs[:16])


def review(pairs):
    cell = 230
    sheet = Image.new("RGBA", (cell * 4, (cell + 22) * ((len(pairs) + 1) // 2)), (150, 120, 90, 255))
    d = ImageDraw.Draw(sheet)
    for i, (sub, f, a, b) in enumerate(pairs):
        bb = a.getchannel("A").getbbox()
        if not bb:
            continue
        side = max(bb[2] - bb[0], bb[3] - bb[1]) + 10
        cx, cy = (bb[0] + bb[2]) / 2, (bb[1] + bb[3]) / 2
        box = (int(cx - side / 2), int(cy - side / 2), int(cx + side / 2), int(cy + side / 2))
        x = (i % 2) * cell * 2; y = (i // 2) * (cell + 22)
        d.text((x + 4, y + 2), f"{sub or 'rest'} {f}  before | after", fill="white")
        for k, im in enumerate((a, b)):
            sheet.alpha_composite(im.crop(box).resize((cell - 10, cell - 10), Image.LANCZOS), (x + k * cell + 5, y + 18))
    sheet.save(os.path.join(ART, "Staging", "HumanRemaster-review.png"))


if __name__ == "__main__":
    main(sys.argv[1:])
