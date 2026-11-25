"""True side views for FoxPenis aroused east, sizes 0-5.

Until 2026-11-17 the fox aroused east sprites were the front pictures leaned up-right (README), so
they were not side views. This builds them from the fox side references in TextureV2:
  reference-fox-side.png      slim knotted shaft seen from the side (tip top-left, knot bottom-right)
  reference-fox-sideball.png  the side scrotum, with the sheath fur at the top
Both lose their white page, are mirrored so the tip points right, and the scrotum is placed under
the knot, slightly behind it, with the shaft drawn on top. Everything that is not the red shaft
becomes a gray mask, so it takes the skin tint like the other sprites. The whole picture is rotated
so the shaft leans like the current fox side views (about 46 degrees up-right), then each size is
scaled to the current sprite's height and moved so its bottom row and the centre of its bottom 25
rows match the current sprite (same base).
Writes Staging/FoxSideEast/FoxPenis_<size>_east.png and Staging/FoxSideEast-review.png.
Run: python -I Build-FoxSideEast.py
"""
import math, os
from collections import deque
from PIL import Image, ImageDraw, ImageFilter, ImageOps

ART = os.path.dirname(os.path.abspath(__file__))
REF = os.path.join(ART, "TextureV2")
LIVE = os.path.join(os.path.dirname(ART), "Textures", "SizedApparel", "BodyParts", "Human", "Penis", "Horny")
OUT = os.path.join(ART, "Staging", "FoxSideEast")


def is_red(p):
    return p[3] > 100 and p[0] > p[1] + 40 and p[0] > p[2] + 25


def unpage(path, up=4):
    """Remove the white page (near-white pixels connected to the border), at `up` times the size."""
    im = Image.open(path).convert("RGBA")
    im = im.resize((im.width * up, im.height * up), Image.LANCZOS)
    w, h = im.size; px = im.load()
    page = lambda p: min(p[0], p[1], p[2]) >= 232 and max(p[0], p[1], p[2]) - min(p[0], p[1], p[2]) < 22
    seen = bytearray(w * h); q = deque()
    for x in range(w):
        for y in (0, h - 1):
            if page(px[x, y]): q.append((x, y)); seen[y * w + x] = 1
    for y in range(h):
        for x in (0, w - 1):
            if page(px[x, y]) and not seen[y * w + x]: q.append((x, y)); seen[y * w + x] = 1
    while q:
        x, y = q.popleft()
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if 0 <= nx < w and 0 <= ny < h and not seen[ny * w + nx] and page(px[nx, ny]):
                seen[ny * w + nx] = 1; q.append((nx, ny))
    a = Image.new("L", (w, h), 255); ap = a.load()
    for y in range(h):
        for x in range(w):
            if seen[y * w + x]: ap[x, y] = 0
    a = a.filter(ImageFilter.MinFilter(3)).filter(ImageFilter.GaussianBlur(1.2))
    im.putalpha(Image.composite(a, Image.new("L", (w, h), 0), im.getchannel("A")))
    return im.crop(im.getchannel("A").getbbox())


def gray_mask(im, all_pixels=False):
    """Non-red pixels (or every pixel) to gray (luma), so sheath and scrotum take the skin tint."""
    out = im.copy(); px = out.load()
    for y in range(out.height):
        for x in range(out.width):
            p = px[x, y]
            if p[3] and (all_pixels or not is_red(p)):
                l = (p[0] * 299 + p[1] * 587 + p[2] * 114) // 1000
                l = min(255, int(l * 0.96 + 6))
                px[x, y] = (l, l, l, p[3])
    return out


def lean_of(im):
    px = im.load()
    pts = [(x, y) for y in range(0, im.height, 2) for x in range(0, im.width, 2) if is_red(px[x, y])]
    n = len(pts); mx = sum(p[0] for p in pts) / n; my = sum(p[1] for p in pts) / n
    cxx = sum((p[0] - mx) ** 2 for p in pts) / n; cyy = sum((p[1] - my) ** 2 for p in pts) / n
    cxy = sum((p[0] - mx) * (p[1] - my) for p in pts) / n
    a = 0.5 * math.atan2(2 * cxy, cxx - cyy); vx, vy = math.cos(a), math.sin(a)
    if vy > 0: vx, vy = -vx, -vy
    return math.degrees(math.atan2(vx, -vy))


def bbox(im, t=40):
    return im.getchannel("A").point(lambda v: 255 if v > t else 0).getbbox()


def base_x(im, rows=25):
    b = bbox(im); a = im.getchannel("A").load()
    xs = [x for y in range(b[3] - rows, b[3]) for x in range(b[0], b[2]) if a[x, y] > 40]
    return sum(xs) / len(xs)


def build_master():
    organ = ImageOps.mirror(unpage(os.path.join(REF, "reference-fox-side.png")))
    # the scrotum has no shaft in it: all of it becomes the gray mask (its pink shading included)
    sac = gray_mask(ImageOps.mirror(unpage(os.path.join(REF, "reference-fox-sideball.png"))), all_pixels=True)
    # knot: the widest band of red rows in the lower 40% of the organ
    px = organ.load()
    rows = {}
    for y in range(organ.height):
        xs = [x for x in range(organ.width) if is_red(px[x, y])]
        if xs: rows[y] = (min(xs), max(xs))
    ys = sorted(rows); base, tip = ys[-1], ys[0]
    lower = [y for y in ys if y > tip + 0.6 * (base - tip)]
    yk = max(lower, key=lambda y: rows[y][1] - rows[y][0])
    kx0, kx1 = rows[yk]; kw = kx1 - kx0
    # scrotum about 1.5 knot widths wide, hanging under the knot and a little behind (left)
    sc = (1.5 * kw) / sac.width
    sac = sac.resize((round(sac.width * sc), round(sac.height * sc)), Image.LANCZOS)
    W = organ.width + sac.width; Hh = organ.height + sac.height
    canvas = Image.new("RGBA", (W * 2, Hh * 2), (0, 0, 0, 0))
    ox, oy = W // 2, Hh // 4
    sx = ox + kx0 - round(0.35 * sac.width)
    sy = oy + yk - round(0.12 * sac.height)
    canvas.alpha_composite(sac, (sx, sy))
    canvas.alpha_composite(organ, (ox, oy))
    canvas = canvas.crop(canvas.getchannel("A").getbbox())
    return gray_mask(canvas)


def main():
    os.makedirs(OUT, exist_ok=True)
    master = build_master()
    target_lean = sum(lean_of(Image.open(os.path.join(LIVE, f"FoxPenis_{s}_east.png")).convert("RGBA")) for s in (3, 4, 5)) / 3
    pad = Image.new("RGBA", (master.width * 3, master.height * 3), (0, 0, 0, 0))
    pad.alpha_composite(master, (master.width, master.height))
    rot = pad.rotate(lean_of(pad) - target_lean, resample=Image.BICUBIC, expand=False)
    rot = rot.crop(rot.getchannel("A").getbbox())
    print("master", master.size, "lean", round(lean_of(master), 1), "-> target", round(target_lean, 1))
    rows = []
    for s in range(6):
        cur = Image.open(os.path.join(LIVE, f"FoxPenis_{s}_east.png")).convert("RGBA")
        cb = bbox(cur); th = cb[3] - cb[1]
        f = th / bbox(rot)[3] if False else th / rot.height
        sp = rot.resize((max(1, round(rot.width * f)), th), Image.LANCZOS)
        new = Image.new("RGBA", cur.size, (0, 0, 0, 0))
        new.alpha_composite(sp, (cb[0], cb[1]))
        nb = bbox(new)
        dx = round(base_x(cur) - base_x(new)); dy = cb[3] - nb[3]
        out = Image.new("RGBA", cur.size, (0, 0, 0, 0)); out.paste(new, (dx, dy), new)
        out.save(os.path.join(OUT, f"FoxPenis_{s}_east.png"))
        print(s, "current", cb, "h", th, "-> new", bbox(out))
        rows.append((cur, out))
    review(rows)


def review(rows):
    wolf = [Image.open(os.path.join(LIVE, f"WolfPenis_{s}_east.png")).convert("RGBA") for s in range(6)]
    cell = 200
    sheet = Image.new("RGBA", (150 + cell * 6, 24 + cell * 3), (150, 120, 90, 255))
    d = ImageDraw.Draw(sheet)
    for r, (label, ims) in enumerate((("fox current", [a for a, b in rows]), ("fox new", [b for a, b in rows]), ("wolf (side ref)", wolf))):
        d.text((4, 24 + r * cell + 90), label, fill="white")
        for c, im in enumerate(ims):
            sheet.alpha_composite(im.crop((190, 60, 450, 320)).resize((cell, cell), Image.LANCZOS), (150 + c * cell, 24 + r * cell))
    for c in range(6):
        d.text((150 + c * cell + 80, 4), f"size {c}", fill="white")
    sheet.save(os.path.join(ART, "Staging", "FoxSideEast-review.png"))


if __name__ == "__main__":
    main()
