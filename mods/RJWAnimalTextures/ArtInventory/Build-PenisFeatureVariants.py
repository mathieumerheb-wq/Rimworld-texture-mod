"""Species-specific penis variants, drawn (prototype on aroused front views).

The shaft is the red/pink pixels; positions along it run from its base (t = 0, lowest shaft row) to
its tip (t = 1). New parts are drawn at 4x on an overlay, in colours sampled from the sprite, then
downsampled and composited, so they keep the sprite's look:
  DeerPenis "Flared": a continuous magnification of the tip: from just below the neck the zoom ramps
      smoothly from 1 to 1.5, then the head is enlarged evenly, so the flare grows out of the shaft.
  FoxPenis "BigKnot": the original knot lobes are erased and redrawn at 1.35x their radius on the same
      bottom, with the original red, a highlight and a dark outline; the shaft is redrawn on top.
  LynxPenis "Spiny": every existing barb (small dark spots in the shaft) is redrawn as a bigger barb
      raked toward the base; barbs at the edge stick out of the outline; the knot lobes are skipped.
Aroused south and east, sizes 0-5 (east via side_view: rotated upright, drawn, rotated back; the fox
side view gets one bulb). North is copied from the plain file. Rest pictures are not made: the
features are hidden when sheathed, and Sized Apparel falls back to the plain rest files.
Writes Staging/PenisFeatures/<hediff>/Horny/<hediff>_<size>_<Variant>_<dir>.png and
Staging/PenisFeatures/Features-review.png.
Run: python -I Build-PenisFeatureVariants.py
"""
import math, os, statistics
from PIL import Image, ImageChops, ImageDraw, ImageFilter

ART = os.path.dirname(os.path.abspath(__file__))
LIVE = os.path.join(os.path.dirname(ART), "Textures", "SizedApparel", "BodyParts", "Human", "Penis", "Horny")
OUT = os.path.join(ART, "Staging", "PenisFeatures")
SIZES = (0, 1, 2, 3, 4, 5)
SS = 4


def is_red(p):
    return p[3] > 100 and p[0] > p[1] + 40 and p[0] > p[2] + 25


def shaft_rows(im):
    px = im.load(); w, h = im.size
    rows = {}
    for y in range(h):
        xs = [x for x in range(w) if is_red(px[x, y])]
        if len(xs) >= 2:
            rows[y] = (min(xs), max(xs))
    return rows


def red_stats(im, y0, y1):
    px = im.load()
    cols = [px[x, y] for y in range(y0, y1) for x in range(im.width) if is_red(px[x, y])]
    med = tuple(int(statistics.median(c[i] for c in cols)) for i in range(3))
    return med


def smooth(e0, e1, x):
    t = max(0.0, min(1.0, (x - e0) / (e1 - e0)))
    return t * t * (3 - 2 * t)


def shade(c, f):
    return tuple(max(0, min(255, int(v * f))) for v in c) + (255,)


def lighten(c, t):
    return tuple(int(v + (255 - v) * t) for v in c) + (255,)


def overlay(size=(512, 512)):
    return Image.new("RGBA", (size[0] * SS, size[1] * SS), (0, 0, 0, 0))


def S(p):
    return (p[0] * SS, p[1] * SS)


def down(ov):
    return ov.resize((ov.width // SS, ov.height // SS), Image.LANCZOS)


# ---------------------------------------------------------------- deer flare
def flared(im, k=1.5, neck=(0.70, 0.92)):
    """Continuous magnification of the tip. Going up from just below the neck (the narrowest shaft row
    between 70% and 92% of the length), the zoom factor ramps smoothly from 1 to k over 12% of the
    length, then stays k: each output row samples the input row reached by integrating 1/zoom, and is
    scaled by the zoom about that input row's own shaft centre. The head is enlarged evenly in both
    directions (not stretched), and the shaft flows into the flare with no seam. If the head would
    leave the canvas, k is reduced for that size."""
    rows = shaft_rows(im); ys = sorted(rows)
    base, tip = ys[-1], ys[0]; L = base - tip
    cand = [y for y in ys if neck[0] <= (base - y) / L <= neck[1]]
    y_neck = min(cand, key=lambda y: rows[y][1] - rows[y][0])
    y_start = y_neck + round(0.06 * L)
    ramp = 0.12 * L
    top_in = im.getchannel("A").point(lambda v: 255 if v > 8 else 0).getbbox()[1]

    def plan(kk):
        mapping = []          # (y_out, y_in, zoom)
        y_in = float(y_start); y_out = y_start
        while y_in > top_in - 1 and y_out > 0:
            z = 1 + (kk - 1) * smooth(0, ramp, y_start - y_out)
            mapping.append((y_out, y_in, z))
            y_out -= 1; y_in -= 1 / z
        return mapping, y_in <= top_in - 1

    kk = k
    mapping, ok = plan(kk)
    while not ok and kk > 1.05:
        kk -= 0.05
        mapping, ok = plan(kk)
    centre = {y: (rows[y][0] + rows[y][1]) / 2 for y in ys}
    def cx_at(y):
        near = min(ys, key=lambda r: abs(r - y)); return centre[near]
    out = im.copy()
    ImageDraw.Draw(out).rectangle([0, 0, im.width - 1, y_start], fill=(0, 0, 0, 0))
    big = im.resize((im.width * 4, im.height * 4), Image.LANCZOS)
    for y_out, y_in, z in mapping:
        yi = min(big.height - 1, max(0, round(y_in * 4)))
        strip = big.crop((0, yi, big.width, yi + 1)).resize((im.width, 1), Image.LANCZOS)
        c = cx_at(y_in)
        w2 = max(1, round(im.width * z))
        row = strip.resize((w2, 1), Image.BICUBIC)
        out.alpha_composite(row, (round(c - c * z), y_out))
    return out


# ---------------------------------------------------------------- fox knot
def big_knot(im, k=1.35, pair=True):
    rows = shaft_rows(im); ys = sorted(rows)
    base, tip = ys[-1], ys[0]; L = base - tip
    y_sh = min(ys, key=lambda y: abs(y - (base - 0.65 * L)))
    sw = rows[y_sh][1] - rows[y_sh][0]
    lower = [y for y in ys if (base - y) / L < 0.5]
    ym = max(lower, key=lambda y: rows[y][1] - rows[y][0])          # widest row: the knot's middle
    wide = lambda y: y in rows and rows[y][1] - rows[y][0] > sw * 1.12
    ky0 = ym
    while wide(ky0 - 1): ky0 -= 1
    ky1 = ym
    while wide(ky1 + 1): ky1 += 1
    knot_rows = list(range(ky0, ky1 + 1))
    kx0 = min(rows[y][0] for y in knot_rows if y in rows); kx1 = max(rows[y][1] for y in knot_rows if y in rows)
    cx = (rows[y_sh][0] + rows[y_sh][1]) / 2
    W = kx1 - kx0
    R = W / 4 if pair else W / 2         # front: two lobes side by side; side view: one bulb
    R = min(R, sw * (0.85 if pair else 0.65))  # per lobe: front about the shaft width; side bulb ~1.5x shaft thickness after k
    col = red_stats(im, ky0, ky1 + 1)
    if not pair:
        col = tuple(min(255, int(v * 1.08)) for v in col)
    R2 = R * k; off2 = R2 * 0.95 if pair else 0.0
    bottom = max(ky1, round(ym + R))
    cy2 = bottom - R2                    # same bottom, grows upward
    out = im.copy()
    # erase the original knot lobes: red and outline pixels in the knot rows outside the shaft band,
    # so their edge does not show as a second bulb next to the new lobes
    po = out.load(); pi = im.load()
    lum = lambda q: (q[0] * 299 + q[1] * 587 + q[2] * 114) // 1000
    for y in range(max(0, ky0 - 2), ky1 + 3):
        for x in range(int(kx0) - 4, int(kx1) + 5):
            if abs(x - cx) <= sw / 2 + 1:
                continue
            q = pi[x, y]
            if q[3] > 0 and (is_red(q) or lum(q) < 80):
                po[x, y] = (0, 0, 0, 0)
    ov = overlay(im.size); d = ImageDraw.Draw(ov)
    ink = (38, 22, 22, 255)
    for sgn in ((-1, 1) if pair else (1,)):
        lx = cx + sgn * off2
        d.ellipse([S((lx - R2, cy2 - R2)), S((lx + R2, cy2 + R2))], fill=col + (255,), outline=ink, width=int(1.8 * SS))
        # shading: darker lower-inner crescent, highlight upper-outer
        d.ellipse([S((lx - R2 * 0.85 + sgn * R2 * 0.05, cy2 - R2 * 0.55)), S((lx + R2 * 0.85 + sgn * R2 * 0.05, cy2 + R2 * 0.95))], fill=shade(col, 0.82))
        d.ellipse([S((lx - R2 * 0.80, cy2 - R2 * 0.80)), S((lx + R2 * 0.70, cy2 + R2 * 0.55))], fill=col + (255,))
        hx = lx + sgn * R2 * 0.35
        d.ellipse([S((hx - R2 * 0.18, cy2 - R2 * 0.55)), S((hx + R2 * 0.18, cy2 - R2 * 0.20))], fill=lighten(col, 0.55))
    knot_layer = down(ov).filter(ImageFilter.GaussianBlur(0.4))
    out.alpha_composite(knot_layer)
    # shaft back on top: the original pixels in the shaft's own column band, from the knot up
    band = Image.new("L", im.size, 0); bd = ImageDraw.Draw(band)
    for y in range(tip, base + 1):
        if y in rows and y <= cy2 + R2 * 0.2:
            hw = sw / 2 + 2
            bd.line([(cx - hw, y), (cx + hw, y)], fill=255)
    shaft = Image.new("RGBA", im.size, (0, 0, 0, 0)); shaft.paste(im, (0, 0), band)
    out.alpha_composite(shaft)
    return out


# ---------------------------------------------------------------- lynx barbs
def spiny(im, scale=0.055):
    rows = shaft_rows(im); ys = sorted(rows)
    base, tip = ys[-1], ys[0]; L = base - tip
    px = im.load()
    col = red_stats(im, tip, base)
    lum = lambda p: (p[0] * 299 + p[1] * 587 + p[2] * 114) // 1000
    ref = lum(col)
    widths = sorted(rows[y][1] - rows[y][0] for y in ys if 0.45 <= (base - y) / L <= 0.8)
    shaft_w = widths[len(widths) // 2]
    # barb pixels: inside the shaft rows, clearly darker than the shaft colour, not the outline band
    pts = []
    for y in ys:
        t = (base - y) / L
        if t < 0.12 or t > 0.96:
            continue
        x0, x1 = rows[y]
        if x1 - x0 > shaft_w * 1.3:      # knot lobes, not barbs
            continue
        for x in range(x0 - 2, x1 + 3):
            p = px[x, y]
            if p[3] > 120 and lum(p) < ref - 28 and p[0] > p[2]:
                pts.append((x, y))
    # group into barbs (simple grid clustering)
    barbs = []
    used = set()
    for p in pts:
        if p in used:
            continue
        group = [q for q in pts if abs(q[0] - p[0]) <= 2 and abs(q[1] - p[1]) <= 2]
        for q in group:
            used.add(q)
        gx = sum(q[0] for q in group) / len(group); gy = sum(q[1] for q in group) / len(group)
        if all(math.hypot(gx - b[0], gy - b[1]) > 3.5 for b in barbs):
            barbs.append((gx, gy))
    out = im.copy()
    ov = overlay(im.size); d = ImageDraw.Draw(ov)
    ink = (112, 42, 48, 255)
    fill = shade(col, 0.72)
    hi = lighten(col, 0.25)
    for gx, gy in barbs:
        y = min(ys, key=lambda r: abs(r - gy)); x0, x1 = rows[y]
        t = (base - gy) / L
        ln = max(4.0, scale * L * (1.15 - 0.4 * t))
        wb = ln * 0.42
        edge = None
        if gx - x0 < 4: edge = -1
        elif x1 - gx < 4: edge = 1
        if edge:
            bx = (x0 if edge < 0 else x1)
            tipp = (bx + edge * ln * 0.9, gy + ln * 0.55)
            tri = [(bx - edge * 1.5, gy - wb), tipp, (bx - edge * 1.5, gy + wb * 0.6)]
        else:
            tipp = (gx, gy + ln * 0.75)         # surface barb, raked down toward the base
            tri = [(gx - wb * 0.8, gy - ln * 0.15), (gx + wb * 0.8, gy - ln * 0.15), tipp]
            d.polygon([S(q) for q in tri], fill=shade(col, 0.8), outline=shade(col, 0.6), width=int(0.8 * SS))
            d.line([S(tri[0]), S(tipp)], fill=hi, width=int(0.7 * SS))
            continue
        d.polygon([S(q) for q in tri], fill=fill, outline=ink, width=int(1.1 * SS))
        d.line([S(tri[0]), S(tipp)], fill=hi, width=int(0.8 * SS))
    out.alpha_composite(down(ov))
    return out


def side_view(im, fn, pad=256):
    """Aroused side views point up-right. On a canvas padded by `pad` on every side, rotate so the
    shaft (principal axis of the red pixels) stands vertical with the tip up, apply fn, rotate back,
    crop, and paste only the pixels fn changed onto the original, so the untouched parts stay sharp."""
    px = im.load()
    pts = [(x, y) for y in range(0, im.height, 2) for x in range(0, im.width, 2) if is_red(px[x, y])]
    n = len(pts); mx = sum(p[0] for p in pts) / n; my = sum(p[1] for p in pts) / n
    cxx = sum((p[0] - mx) ** 2 for p in pts) / n; cyy = sum((p[1] - my) ** 2 for p in pts) / n
    cxy = sum((p[0] - mx) * (p[1] - my) for p in pts) / n
    ang = 0.5 * math.atan2(2 * cxy, cxx - cyy)
    vx, vy = math.cos(ang), math.sin(ang)
    if vy > 0: vx, vy = -vx, -vy                       # point toward the tip (up)
    lean = math.degrees(math.atan2(vx, -vy))           # positive = leaning right
    big = Image.new("RGBA", (im.width + 2 * pad, im.height + 2 * pad), (0, 0, 0, 0))
    big.paste(im, (pad, pad))
    c = (mx + pad, my + pad)
    up = big.rotate(lean, resample=Image.BICUBIC, center=c)      # PIL rotates counter-clockwise
    done = fn(up)
    a, b = up.load(), done.load()
    diff = Image.new("L", up.size, 0); dp = diff.load()
    for y in range(up.height):
        for x in range(up.width):
            p, q = a[x, y], b[x, y]
            if (p[3] or q[3]) and max(abs(p[i] - q[i]) for i in range(4)) > 6:
                dp[x, y] = 255
    diff = diff.filter(ImageFilter.MaxFilter(5))
    back = done.rotate(-lean, resample=Image.BICUBIC, center=c).crop((pad, pad, pad + im.width, pad + im.height))
    mask = diff.rotate(-lean, resample=Image.BILINEAR, center=c).crop((pad, pad, pad + im.width, pad + im.height))
    return Image.composite(back, im, mask)


FRONT = {"Flared": flared, "BigKnot": big_knot, "Spiny": spiny}
SIDE = {"Flared": lambda im: flared(im, k=1.6, neck=(0.60, 0.85)), "BigKnot": lambda im: big_knot(im, pair=False), "Spiny": spiny}
JOBS = [("DeerPenis", "Flared", flared), ("FoxPenis", "BigKnot", big_knot), ("LynxPenis", "Spiny", spiny)]


def main():
    results = []
    for hd, var, _ in JOBS:
        od = os.path.join(OUT, hd, "Horny"); os.makedirs(od, exist_ok=True)
        for d in ("south", "east"):
            row = []
            for sz in SIZES:
                im = Image.open(os.path.join(LIVE, f"{hd}_{sz}_{d}.png")).convert("RGBA")
                if im.width < 64:
                    new = im
                else:
                    new = FRONT[var](im) if d == "south" else side_view(im, SIDE[var])
                    if var == "Flared" and d == "east":
                        # a side flare must stay inside the canvas: retry with a smaller zoom
                        kk = 1.6
                        while kk > 1.15:
                            box = new.getchannel("A").point(lambda v: 255 if v > 8 else 0).getbbox()
                            if box[0] > 1 and box[1] > 1 and box[2] < im.width - 1 and box[3] < im.height - 1:
                                break
                            kk -= 0.1
                            new = side_view(im, lambda u, kk=kk: flared(u, k=kk, neck=(0.60, 0.85)))
                new.save(os.path.join(od, f"{hd}_{sz}_{var}_{d}.png"))
                row.append((im, new))
            results.append((hd, var, d, row))
        # north: Sized Apparel uses the variant name for every direction; copy the plain north
        for sz in SIZES:
            Image.open(os.path.join(LIVE, f"{hd}_{sz}_north.png")).save(os.path.join(od, f"{hd}_{sz}_{var}_north.png"))
    cell = 150
    sheet = Image.new("RGBA", (170 + cell * len(SIZES) * 2, 24 + cell * len(results)), (150, 120, 90, 255))
    dr = ImageDraw.Draw(sheet)
    for r, (hd, var, d, row) in enumerate(results):
        dr.text((4, 24 + r * cell + 60), f"{hd} {d}" + chr(10) + f"current | {var}", fill="white")
        for c, (a_, b_) in enumerate(row):
            if a_.width < 64:
                continue
            bb = a_.getchannel("A").getbbox()
            for k, im in enumerate((a_, b_)):
                bb2 = im.getchannel("A").getbbox()
                box = (min(bb[0], bb2[0]) - 6, min(bb[1], bb2[1]) - 6, max(bb[2], bb2[2]) + 6, max(bb[3], bb2[3]) + 6)
                side = max(box[2] - box[0], box[3] - box[1])
                cx_, cy_ = (box[0] + box[2]) / 2, (box[1] + box[3]) / 2
                crop = im.crop((round(cx_ - side / 2), round(cy_ - side / 2), round(cx_ + side / 2), round(cy_ + side / 2)))
                sheet.alpha_composite(crop.resize((cell, cell), Image.LANCZOS), (170 + (c * 2 + k) * cell, 24 + r * cell))
    for c, sz in enumerate(SIZES):
        dr.text((170 + c * 2 * cell + cell - 20, 4), f"size {sz}", fill="white")
    sheet.save(os.path.join(OUT, "Features-review.png"))


if __name__ == "__main__":
    main()
