"""Lynx tail, version 2, drawn procedurally with Pillow in the style of the other installed tails
(Sized Apparel furry tail, Anthrosonae cat tail): thick dark outline, cel-shaded gray fur mask that the
gene tints with the hair color, fur tufts, a curved hook, plus the lynx black tip and faint spots.

The earlier tail was a thin painted strip (east 18% of the canvas tall, straight) with no outline.

Placement: the gene uses the vanilla furry-tail offsets, so each view is fitted into the opaque box of
the Sized Apparel furry tail on the 512 canvas (measured 2026-11-16):
  east  x 83-450, y 142-406   (base on the right, toward the body; tip curls up on the left)
  south x 20-298, y 141-409   (tail out to the pawn's right, screen left)
  north x 186-464, y 122-390  (south mirrored)
Writes Staging/LynxTailV2/LynxTail_{south,east,north}.png and Staging/LynxTailV2-review.png.
Run: python -I Build-LynxTailV2.py
"""
import math, os, sys
from PIL import Image, ImageDraw, ImageFilter, ImageChops

ART = os.path.dirname(os.path.abspath(__file__))
MOD = os.path.dirname(ART)
OUT = os.path.join(ART, "Staging", "LynxTailV2")
SS = 4                      # supersampling
N = 512 * SS

# Shape parameters (512 space), overridable on the command line as key=value.
P = dict(
    base=(445, 150), c1=(420, 400), c2=(150, 430), tip=(118, 235),   # centerline Bezier, base -> tip
    w_base=14, w_mid=96, w_tip=112,     # full widths: pointed base, fat fluffy end
    tip_frac=0.24,                      # black part of the length
    tufts=5, tuft_len=26,               # swept fur tufts along the outer edge
    outline=9,                          # outline thickness
    spots=9,
)
for a in sys.argv[1:]:
    k, v = a.split("=")
    P[k] = eval(v)

BOX = {"east": (83, 142, 450, 406), "south": (20, 141, 298, 409), "north": (186, 122, 464, 390)}


def bez(t):
    (x0, y0), (x1, y1), (x2, y2), (x3, y3) = P["base"], P["c1"], P["c2"], P["tip"]
    u = 1 - t
    return (u**3 * x0 + 3 * u * u * t * x1 + 3 * u * t * t * x2 + t**3 * x3,
            u**3 * y0 + 3 * u * u * t * y1 + 3 * u * t * t * y2 + t**3 * y3)


def width(t):
    # Narrow at the base, widest past the middle, round fluffy end.
    if t < 0.5:
        s = t / 0.5
        return P["w_base"] + (P["w_mid"] - P["w_base"]) * (math.sin(s * math.pi / 2))
    s = (t - 0.5) / 0.5
    return P["w_mid"] + (P["w_tip"] - P["w_mid"]) * math.sin(s * math.pi / 2)


def build_east():
    K = 400
    pts = [bez(i / K) for i in range(K + 1)]
    normals = []
    for i in range(K + 1):
        a = pts[max(0, i - 1)]; b = pts[min(K, i + 1)]
        dx, dy = b[0] - a[0], b[1] - a[1]; L = math.hypot(dx, dy) or 1
        normals.append((-dy / L, dx / L))
    # Outer side = the side away from the curve's inside (toward the bottom of the hook).
    cx = sum(p[0] for p in pts) / len(pts); cy = sum(p[1] for p in pts) / len(pts)
    mid = K // 2
    sgn = 1 if (normals[mid][0] * (pts[mid][0] - cx) + normals[mid][1] * (pts[mid][1] - cy)) > 0 else -1
    left, right = [], []
    for i, (p, n) in enumerate(zip(pts, normals)):
        t = i / K; w = width(t) / 2
        o = (p[0] + n[0] * w * sgn, p[1] + n[1] * w * sgn)     # outer edge
        q = (p[0] - n[0] * w * sgn, p[1] - n[1] * w * sgn)     # inner edge
        # fur tufts on the outer edge, between 15% and 95% of the length
        if P["tufts"] and 0.15 < t < 0.97:
            ph = (t - 0.15) / 0.82 * P["tufts"]
            f = ph - math.floor(ph)
            # sawtooth: grows along the tail, then drops, so each tuft points back toward the base
            spike = P["tuft_len"] * (f ** 1.6) * min(1.0, (t - 0.15) / 0.15)
            o = (o[0] + n[0] * spike * sgn - (p[0] - pts[max(0, i - 3)][0]) * spike * 0.05,
                 o[1] + n[1] * spike * sgn - (p[1] - pts[max(0, i - 3)][1]) * spike * 0.05)
        left.append(o); right.append(q)
    # round cap at the tip
    tp = pts[-1]; tn = normals[-1]; tdx, tdy = tn[1], -tn[0]
    if (tp[0] - pts[-5][0]) * tdx + (tp[1] - pts[-5][1]) * tdy < 0:
        tdx, tdy = -tdx, -tdy
    cap = []
    r = width(1) / 2
    ang0 = math.atan2(left[-1][1] - tp[1], left[-1][0] - tp[0])
    ang1 = math.atan2(right[-1][1] - tp[1], right[-1][0] - tp[0])
    # sweep through the forward direction
    fwd = math.atan2(tdy, tdx)
    def norm(a):
        while a < fwd - math.pi: a += 2 * math.pi
        while a > fwd + math.pi: a -= 2 * math.pi
        return a
    a0, a1 = norm(ang0), norm(ang1)
    for j in range(1, 40):
        a = a0 + (a1 - a0) * j / 40
        # small fluffy bumps on the cap
        rr = r * (1 + 0.08 * math.sin(j / 40 * math.pi * 5))
        cap.append((tp[0] + math.cos(a) * rr, tp[1] + math.sin(a) * rr))
    poly = left + cap + right[::-1]
    S = lambda pt: (pt[0] * SS, pt[1] * SS)
    mask = Image.new("L", (N, N), 0)
    ImageDraw.Draw(mask).polygon([S(p) for p in poly], fill=255)

    # Tone per pixel: position across the width (-1 inner .. +1 outer) from the nearest centerline sample.
    tone = Image.new("L", (N, N), 0)
    td = ImageDraw.Draw(tone)
    # paint bands as thick strokes along offset curves, from outer (dark) to inner (light)
    bands = [(1.25, 172), (0.55, 200), (0.15, 226), (-0.55, 246)]
    for frac, val in bands:
        line = []
        for i, (p, n) in enumerate(zip(pts, normals)):
            w = width(i / K) / 2
            line.append(S((p[0] + n[0] * w * frac * sgn, p[1] + n[1] * w * frac * sgn)))
    # simpler: fill strips between offsets
    def strip(f0, f1, val):
        a = []; b = []
        for i, (p, n) in enumerate(zip(pts, normals)):
            w = width(i / K) / 2 * 1.6
            a.append(S((p[0] + n[0] * w * f0 * sgn, p[1] + n[1] * w * f0 * sgn)))
            b.append(S((p[0] + n[0] * w * f1 * sgn, p[1] + n[1] * w * f1 * sgn)))
        td.polygon(a + b[::-1], fill=val)
    strip(-1.0, 1.0, 226)
    strip(0.30, 1.0, 196)      # underside shade
    strip(0.55, 1.0, 170)      # deepest shade along the outer edge
    strip(-1.0, -0.40, 246)    # highlight on the inner/top edge
    tone = tone.filter(ImageFilter.GaussianBlur(SS * 1.2))
    # Tip cap gets the same tones (the polygon cap extends past the last sample).
    capfill = Image.new("L", (N, N), 0); ImageDraw.Draw(capfill).polygon([S(p) for p in poly], fill=226)
    tone = ImageChops.lighter(tone, ImageChops.multiply(capfill, ImageChops.invert(tone.point(lambda v: 255 if v > 0 else 0))))

    # Black tip: a union of discs along the last tip_frac of the centerline, wide enough to cover the
    # tufts and the round cap, so the whole end is black with a rounded boundary. Three short fur
    # points reach back from the boundary along the top, middle and bottom.
    import random
    rnd = random.Random(7)
    tipmask = Image.new("L", (N, N), 0); tdm = ImageDraw.Draw(tipmask)
    i0 = int(K * (1 - P["tip_frac"]))
    for i in range(i0, K + 1, 2):
        p = pts[i]; r = width(i / K) / 2 + P["tuft_len"] + 6
        tdm.ellipse([S((p[0] - r, p[1] - r)), S((p[0] + r, p[1] + r))], fill=255)
    p0, n0 = pts[i0], normals[i0]
    # keep only the part past the line across the tail at i0 (slightly bowed toward the tip)
    fwd = (pts[min(K, i0 + 6)][0] - pts[max(0, i0 - 6)][0], pts[min(K, i0 + 6)][1] - pts[max(0, i0 - 6)][1])
    L = math.hypot(*fwd) or 1; fwd = (fwd[0] / L, fwd[1] / L)
    W0 = width(i0 / K) / 2 + P["tuft_len"] + 60
    arc = [(p0[0] + n0[0] * W0 * f + fwd[0] * 10 * (1 - f * f), p0[1] + n0[1] * W0 * f + fwd[1] * 10 * (1 - f * f)) for f in [j / 10 - 1 for j in range(21)]]
    far = [(q[0] + fwd[0] * 400, q[1] + fwd[1] * 400) for q in (arc[-1], arc[0])]
    clip = Image.new("L", (N, N), 0); ImageDraw.Draw(clip).polygon([S(q) for q in arc + far], fill=255)
    tipmask = ImageChops.multiply(tipmask, clip); tdm = ImageDraw.Draw(tipmask)
    for f in (-0.55, 0.0, 0.55):
        w = width(i0 / K) / 2
        bow = 10 * (1 - f * f) + 6          # base sits inside the black, past the bowed boundary
        bx, by = p0[0] + n0[0] * w * f + fwd[0] * bow, p0[1] + n0[1] * w * f + fwd[1] * bow
        tx, ty = bx - fwd[0] * 30, by - fwd[1] * 30
        tdm.polygon([S((bx + n0[0] * 9, by + n0[1] * 9)), S((tx, ty)), S((bx - n0[0] * 9, by - n0[1] * 9))], fill=255)
    # Spots: irregular soft dabs scattered over the middle of the tail, low contrast.
    spots = Image.new("L", (N, N), 0); sd = ImageDraw.Draw(spots)
    for k in range(P["spots"]):
        t = rnd.uniform(0.22, 0.70)
        i = int(t * K); p, n = pts[i], normals[i]; w = width(t) / 2
        f = rnd.uniform(-0.55, 0.35)
        x, y = p[0] + n[0] * w * f * sgn, p[1] + n[1] * w * f * sgn
        q = pts[min(K, i + 10)]; dx, dy = q[0] - p[0], q[1] - p[1]; L = math.hypot(dx, dy) or 1
        ln = rnd.uniform(5, 11); th = rnd.uniform(3.5, 6)
        sd.line([S((x - dx / L * ln, y - dy / L * ln)), S((x + dx / L * ln, y + dy / L * ln))], fill=255, width=int(th * SS))
    spots = spots.filter(ImageFilter.GaussianBlur(SS * 1.5))

    gray = tone.copy()
    gray.paste(150, mask=spots.point(lambda v: int(v * 0.7)))
    gray.paste(40, mask=tipmask)
    # outline: dilated mask behind
    k = P["outline"] * SS * 2 + 1
    outer = mask.filter(ImageFilter.MaxFilter(k if k % 2 else k + 1))
    rgb = Image.new("L", (N, N), 24)
    rgb.paste(gray, mask=mask)
    img = Image.merge("RGBA", (rgb, rgb, rgb, outer))
    img = img.resize((512, 512), Image.LANCZOS)
    return img


def fit(img, box, mirror=False, squeeze=1.0):
    bb = img.getchannel("A").point(lambda a: 255 if a > 40 else 0).getbbox()
    crop = img.crop(bb)
    if mirror:
        crop = crop.transpose(Image.FLIP_LEFT_RIGHT)
    bw, bh = box[2] - box[0], box[3] - box[1]
    crop = crop.resize((bw, bh), Image.LANCZOS)
    out = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
    out.alpha_composite(crop, (box[0], box[1]))
    return out


def main():
    os.makedirs(OUT, exist_ok=True)
    east = build_east()
    e = fit(east, BOX["east"])
    s = fit(east, BOX["south"])
    n = fit(east, BOX["north"], mirror=True)
    for name, im in (("east", e), ("south", s), ("north", n)):
        im.save(os.path.join(OUT, f"LynxTail_{name}.png"))
        print(name, im.getchannel("A").point(lambda a: 255 if a > 40 else 0).getbbox())
    review(e, s, n)


def tint(im, rgb):
    r, g, b, a = im.split()
    r = r.point(lambda v: v * rgb[0] // 255); g = g.point(lambda v: v * rgb[1] // 255); b = b.point(lambda v: v * rgb[2] // 255)
    return Image.merge("RGBA", (r, g, b, a))


def review(e, s, n):
    M = r"C:\Program Files (x86)\Steam\steamapps\common\RimWorld\Mods"
    live = os.path.join(MOD, r"Textures\Things\Pawn\Humanlike\BodyAttachments\LynxTail\LynxTail")
    sa = os.path.join(M, r"sized-apparel-zero\Textures\Things\Pawn\Humanlike\BodyAttachments\FurryTail\FurryTail")
    blond, blue = (193, 146, 85), (154, 216, 255)
    rows = [("SA furry (reference)", lambda d: Image.open(f"{sa}_{d}.png").convert("RGBA"), (230, 230, 230)),
            ("lynx live, blond", lambda d: Image.open(f"{live}_{d}.png").convert("RGBA"), blond),
            ("lynx new, blond", lambda d: {"south": s, "east": e, "north": n}[d], blond),
            ("lynx new, blue", lambda d: {"south": s, "east": e, "north": n}[d], blue)]
    cell = 256
    sheet = Image.new("RGBA", (170 + cell * 3, 24 + cell * len(rows)), (150, 120, 90, 255))
    d = ImageDraw.Draw(sheet)
    for r, (label, get, col) in enumerate(rows):
        d.text((4, 24 + r * cell + 120), label, fill="white")
        for c, dr in enumerate(("south", "east", "north")):
            im = tint(get(dr), col).resize((cell, cell), Image.LANCZOS)
            sheet.alpha_composite(im, (170 + c * cell, 24 + r * cell))
    for c, dr in enumerate(("south", "east", "north")):
        d.text((170 + c * cell + 110, 4), dr, fill="white")
    sheet.save(os.path.join(ART, "Staging", "LynxTailV2-review.png"))


if __name__ == "__main__":
    main()
