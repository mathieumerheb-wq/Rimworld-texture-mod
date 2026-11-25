"""Dragon ears and dragon tail, drawn procedurally with Pillow in the style of the other installed
attachments (thick dark outline, cel shading), as gray masks the genes tint with the skin color.

Ears (2026-11-17): the pointed anthro dragon ears (groove, ridges, two back-edge notches) on the
upper sides of the head, plus a pair of short horns on top of the head, curving slightly back. The gene draws them behind the
head (layer 45), and each base starts well inside the Sized Apparel Heads average head (512 canvas), so
the head's own outline covers the bases.
Tail: a thick reptile tail tapering to a spade tip, dorsal spikes along the top, pale belly plates
with segment lines underneath. Fitted into a box a little larger than the Sized Apparel furry tail
(the gene uses the vanilla furry-tail offsets), so it sits where that tail sits.

Writes Staging/Dragon/{DragonEars,DragonTail}/... and Staging/Dragon-review.png.
Run: python -I Build-DragonParts.py
"""
import math, os, random
from PIL import Image, ImageDraw, ImageFilter, ImageChops

ART = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(ART, "Staging", "Dragon")
SS = 4
N = 512 * SS
S = lambda p: (p[0] * SS, p[1] * SS)
OUTLINE = 9
INK = 24


def finish(mask, gray):
    """Gray picture inside mask, dark outline around it, downsampled to 512."""
    k = OUTLINE * SS * 2 + 1
    outer = mask.filter(ImageFilter.MaxFilter(k))
    lum = Image.new("L", (N, N), INK)
    lum.paste(gray, mask=mask)
    return Image.merge("RGBA", (lum, lum, lum, outer)).resize((512, 512), Image.LANCZOS)


def bez(P, t):
    (x0, y0), (x1, y1), (x2, y2), (x3, y3) = P
    u = 1 - t
    return (u**3 * x0 + 3 * u * u * t * x1 + 3 * u * t * t * x2 + t**3 * x3,
            u**3 * y0 + 3 * u * u * t * y1 + 3 * u * t * t * y2 + t**3 * y3)


# ---------------------------------------------------------------- ears
# Anthro dragon ears (2026-11-17, replacing a webbed-fin draft): tall pointed ears that rise from the
# upper sides of the head and lean outward, the tip curling slightly back. Front: a darker inner groove
# crossed by ridges, a light rim, two small notches on the back edge. Back: no groove, scale ridges.
def ear(base, h=136, w=44, lean=22.0, curl=0.26, front=True, notches=2, groove_val=150, ridges=True):
    """One ear in local coordinates (pointing up), rotated by lean degrees (positive = toward screen
    right) about its base center, then placed at base. Returns (mask, gray) at supersampled size."""
    def outline(scale_w=1.0, scale_h=1.0, inset=0.0):
        pts_o, pts_i = [], []
        M = 40
        for i in range(M + 1):
            t = i / M
            y = -h * scale_h * t
            # half width: full at the base, bulging a little low down, to a point
            hw = w / 2 * scale_w * (1 - t ** 1.6) * (1 + 0.25 * math.sin(t * math.pi))
            bend = h * curl * t ** 2.2          # tip curls toward the back edge (+x)
            pts_o.append((bend + hw, y))         # back (outer) edge
            pts_i.append((bend - hw * 0.9, y))   # front (inner) edge, a little straighter
        return pts_o, pts_i
    po, pi = outline()
    # notches: small V cuts into the back edge
    if notches:
        po2 = []
        for i, (x, y) in enumerate(po):
            t = i / (len(po) - 1)
            cut = 0
            for c in ([0.38, 0.6][:notches]):
                d = abs(t - c)
                if d < 0.05:
                    cut = max(cut, (0.05 - d) / 0.05 * w * 0.16)
            po2.append((x - cut, y))
        po = po2
    poly = po + pi[::-1]
    ang = math.radians(lean)
    ca, sa = math.cos(ang), math.sin(ang)
    T = lambda q: (base[0] + q[0] * ca - q[1] * sa, base[1] + q[0] * sa + q[1] * ca)
    mask = Image.new("L", (N, N), 0)
    ImageDraw.Draw(mask).polygon([S(T(q)) for q in poly], fill=255)
    gray = Image.new("L", (N, N), 214)
    gd = ImageDraw.Draw(gray)
    # light rim along the back edge
    rim_o, rim_i = outline(0.80)
    gd.polygon([S(T(q)) for q in po + rim_o[::-1]], fill=236)
    if front:
        # inner groove: an inset ear shape shifted toward the front edge, darker
        go, gi = outline(0.52, 0.86)
        shift = (-w * 0.08, -h * 0.03)
        groove = [(x + shift[0], y + shift[1]) for x, y in go + gi[::-1]]
        gd.polygon([S(T(q)) for q in groove], fill=groove_val)
        gray = gray.filter(ImageFilter.GaussianBlur(SS * 1.3))
        rd = ImageDraw.Draw(gray)
        # ridges across the groove
        for k, t in enumerate((0.22, 0.38, 0.54) if ridges else ()):
            y = -h * 0.86 * t + shift[1]
            hw = w / 2 * 0.52 * (1 - t ** 1.6) * (1 + 0.25 * math.sin(t * math.pi))
            bend = h * curl * t ** 2.2 + shift[0]
            a, b2 = (bend - hw * 0.85, y + 4), (bend + hw * 0.95, y - 3)
            rd.line([S(T(a)), S(T(((a[0] + b2[0]) / 2, y - 3))), S(T(b2))], fill=112, width=int(3 * SS), joint="curve")
    else:
        gray = gray.filter(ImageFilter.GaussianBlur(SS * 1.3))
        rd = ImageDraw.Draw(gray)
        for t in (0.18, 0.32, 0.46, 0.60):
            y = -h * t
            hw = w / 2 * (1 - t ** 1.6) * (1 + 0.25 * math.sin(t * math.pi)) * 0.8
            bend = h * curl * t ** 2.2
            c = T((bend, y)); rr = hw * SS
            rd.arc([c[0] * SS - rr, c[1] * SS - 6 * SS, c[0] * SS + rr, c[1] * SS + 6 * SS], 200, 340, fill=150, width=int(2.5 * SS))
    # shadow at the base, where the ear meets the head
    sh = Image.new("L", (N, N), 0)
    ImageDraw.Draw(sh).ellipse([S((base[0] - w * 0.6, base[1] - 16)), S((base[0] + w * 0.6, base[1] + 16))], fill=255)
    gray.paste(170, mask=sh.filter(ImageFilter.GaussianBlur(SS * 5)).point(lambda v: v * 2 // 3))
    return mask, gray


HEADS = r"C:\Program Files (x86)\Steam\steamapps\common\RimWorld\Mods\sized-apparel-heads\Textures\Things\Pawn\Humanlike\Heads\Female\Female_Average_Normal_"


def head_interior(direction):
    """The inside of the Sized Apparel average head (its fill, not its dark outline), at the
    supersampled size. Pieces start inside it, so they grow out of the head."""
    h = Image.open(HEADS + direction + ".png").convert("RGBA").resize((N, N), Image.LANCZOS)
    r, g, b, a = h.split()
    lum = Image.merge("RGB", (r, g, b)).convert("L")
    inside = ImageChops.multiply(a.point(lambda v: 255 if v > 200 else 0), lum.point(lambda v: 255 if v > 90 else 0))
    return inside.filter(ImageFilter.MinFilter(5))


def finish_seated(mask, gray, interior):
    """Like finish(), but no outline inside the head, and the piece fades into the head over a
    few pixels, so its base has no seam."""
    k = OUTLINE * SS * 2 + 1
    outer = mask.filter(ImageFilter.MaxFilter(k))
    ink = ImageChops.subtract(outer, mask)
    ink = ImageChops.multiply(ink, ImageChops.invert(interior))
    alpha = ImageChops.lighter(mask, ink)
    fade = interior.filter(ImageFilter.MinFilter(4 * SS + 1)).filter(ImageFilter.GaussianBlur(5 * SS))
    alpha = ImageChops.multiply(alpha, ImageChops.invert(fade))
    lum = Image.new("L", (N, N), INK)
    lum.paste(gray, mask=mask)
    return Image.merge("RGBA", (lum, lum, lum, alpha)).resize((512, 512), Image.LANCZOS)


def horn(P, w0=34.0, rings=6, front=True):
    """A tapering horn along the Bezier P (base first), ridged with rings, a light strip along
    the outer curve. Returns (mask, gray)."""
    K = 200
    pts = [bez(P, i / K) for i in range(K + 1)]
    nrm = []
    for i in range(K + 1):
        a2, b2 = pts[max(0, i - 1)], pts[min(K, i + 1)]
        dx, dy = b2[0] - a2[0], b2[1] - a2[1]; L = math.hypot(dx, dy) or 1
        nrm.append((-dy / L, dx / L))
    wd = lambda t: w0 * (1 - t) ** 0.9 + 1.0
    side1 = [(p[0] + n[0] * wd(i / K) / 2, p[1] + n[1] * wd(i / K) / 2) for i, (p, n) in enumerate(zip(pts, nrm))]
    side2 = [(p[0] - n[0] * wd(i / K) / 2, p[1] - n[1] * wd(i / K) / 2) for i, (p, n) in enumerate(zip(pts, nrm))]
    mask = Image.new("L", (N, N), 0)
    ImageDraw.Draw(mask).polygon([S(q) for q in side1 + side2[::-1]], fill=255)
    gray = Image.new("L", (N, N), 150)
    gd = ImageDraw.Draw(gray)
    # light strip along side1, shadow along side2
    l1 = [(p[0] + n[0] * wd(i / K) * 0.15, p[1] + n[1] * wd(i / K) * 0.15) for i, (p, n) in enumerate(zip(pts, nrm))]
    gd.polygon([S(q) for q in side1 + l1[::-1]], fill=198 if front else 176)
    l2 = [(p[0] - n[0] * wd(i / K) * 0.25, p[1] - n[1] * wd(i / K) * 0.25) for i, (p, n) in enumerate(zip(pts, nrm))]
    gd.polygon([S(q) for q in side2 + l2[::-1]], fill=118)
    gray = gray.filter(ImageFilter.GaussianBlur(SS * 1.2))
    rd = ImageDraw.Draw(gray)
    for k in range(rings):
        t = 0.12 + 0.62 * k / max(1, rings - 1)
        i = int(t * K); p, n = pts[i], nrm[i]; w = wd(t) / 2
        # ring: a shallow arc across the horn, bowed toward the tip
        q = pts[min(K, i + 4)]; fx, fy = q[0] - p[0], q[1] - p[1]; L = math.hypot(fx, fy) or 1
        mid = (p[0] + fx / L * w * 0.35, p[1] + fy / L * w * 0.35)
        rd.line([S((p[0] + n[0] * w, p[1] + n[1] * w)), S(mid), S((p[0] - n[0] * w, p[1] - n[1] * w))], fill=92, width=int(2.6 * SS), joint="curve")
    return mask, gray


def _mirror(img):
    return img.transpose(Image.FLIP_LEFT_RIGHT)


def head_set(direction):
    """Ears plus short horns for one view, as a 512 RGBA picture. The gene draws them behind the
    head (layer 45; the head is 50, hair 62), so each base starts well inside the head outline and
    the head covers it: the pieces grow out from behind the head's own outline."""
    layers = []
    if direction in ("south", "north"):
        front = direction == "south"
        # right side of the screen built, then mirrored for the left side
        em, eg = ear((318, 238), h=150, w=48, lean=22.0, curl=0.26, front=front, notches=2)
        hm, hg = horn([(280, 206), (283, 152), (293, 128), (310, 120)], w0=32, rings=3, front=front)
        for m, g in ((em, eg), (hm, hg)):
            m2, g2 = _mirror(m), _mirror(g)
            mm = ImageChops.lighter(m, m2)
            gg = Image.new("L", (N, N), 0); gg.paste(g, mask=m); gg.paste(g2, mask=m2)
            layers.append(finish(mm, gg))
    else:
        em, eg = ear((212, 222), h=146, w=50, lean=-26.0, curl=-0.22, front=True, notches=2)
        hm, hg = horn([(268, 204), (262, 150), (248, 126), (228, 120)], w0=34, rings=3, front=True)
        layers.append(finish(em, eg))
        layers.append(finish(hm, hg))
    out = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
    for l in layers:          # ears first, horns on top
        out.alpha_composite(l)
    return out


def ears_south():
    return head_set("south")


def ears_north():
    return head_set("north")


def ears_east():
    return head_set("east")


# ---------------------------------------------------------------- tail
def tail_east(P=None, w_base=96, tip_w=8, spikes=8):
    P = P or [(445, 205), (430, 430), (130, 440), (98, 220)]
    K = 400
    pts = [bez(P, i / K) for i in range(K + 1)]
    nrm = []
    for i in range(K + 1):
        a, b = pts[max(0, i - 1)], pts[min(K, i + 1)]
        dx, dy = b[0] - a[0], b[1] - a[1]; L = math.hypot(dx, dy) or 1
        nrm.append((-dy / L, dx / L))
    width = lambda t: tip_w + (w_base - tip_w) * (1 - t) ** 1.15
    # "up" side: the inside of the hook (top of the tail), chosen once at the middle and kept
    # consistent along the length, so it does not flip where the tail curls up.
    mid = K // 2
    sg = 1 if nrm[mid][1] < 0 else -1
    up = [(n[0] * sg, n[1] * sg) for n in nrm]
    top = [(p[0] + u[0] * width(i / K) / 2, p[1] + u[1] * width(i / K) / 2) for i, (p, u) in enumerate(zip(pts, up))]
    bot = [(p[0] - u[0] * width(i / K) / 2, p[1] - u[1] * width(i / K) / 2) for i, (p, u) in enumerate(zip(pts, up))]
    mask = Image.new("L", (N, N), 0); md = ImageDraw.Draw(mask)
    md.polygon([S(p) for p in top + bot[::-1]], fill=255)
    # rounded base end (hidden behind the body, but keeps the outline closed)
    r0 = width(0) / 2; md.ellipse([S((pts[0][0] - r0, pts[0][1] - r0)), S((pts[0][0] + r0, pts[0][1] + r0))], fill=255)
    # spade tip: a diamond past the end
    tp, tq = pts[-1], pts[-12]
    fx, fy = tp[0] - tq[0], tp[1] - tq[1]; L = math.hypot(fx, fy) or 1; fx, fy = fx / L, fy / L
    nx, ny = -fy, fx
    spade = [(tp[0] - fx * 4, tp[1] - fy * 4),
             (tp[0] - fx * 16 + nx * 34, tp[1] - fy * 16 + ny * 34),     # back barb
             (tp[0] + fx * 6 + nx * 22, tp[1] + fy * 6 + ny * 22),
             (tp[0] + fx * 46, tp[1] + fy * 46),                         # point
             (tp[0] + fx * 6 - nx * 22, tp[1] + fy * 6 - ny * 22),
             (tp[0] - fx * 16 - nx * 34, tp[1] - fy * 16 - ny * 34)]
    md.polygon([S(p) for p in spade], fill=255)
    # dorsal spikes along the top edge, shrinking toward the tip
    spike = Image.new("L", (N, N), 0); sd = ImageDraw.Draw(spike)
    for k in range(spikes):
        t = 0.10 + 0.72 * k / (spikes - 1)
        i = int(t * K); p, u = top[i], up[i]
        h = 30 * (1 - t * 0.7); w = 16 * (1 - t * 0.6)
        q0 = top[max(0, i - int(w / 1.2))]; q1 = top[min(K, i + int(w / 1.2))]
        # lean back toward the base
        back = pts[max(0, i - 14)]
        bx, by = (pts[i][0] - back[0]), (pts[i][1] - back[1]); BL = math.hypot(bx, by) or 1
        apex = (p[0] + u[0] * h - bx / BL * h * 0.45, p[1] + u[1] * h - by / BL * h * 0.45)
        sd.polygon([S(q0), S(apex), S(q1)], fill=255)
    mask = ImageChops.lighter(mask, spike)

    # tones
    gray = Image.new("L", (N, N), 196)
    gd = ImageDraw.Draw(gray)
    # Bands and the belly also run back past the base, over the rounded cap, so there is no seam.
    tx0, ty0 = pts[1][0] - pts[0][0], pts[1][1] - pts[0][1]; TL = math.hypot(tx0, ty0) or 1
    ext = lambda q: (q[0] - tx0 / TL * r0 * 1.4, q[1] - ty0 / TL * r0 * 1.4)
    def band(f0, f1, val):  # f across the width from top (+1) to bottom (-1)
        a = [(p[0] + u[0] * width(i / K) / 2 * f0, p[1] + u[1] * width(i / K) / 2 * f0) for i, (p, u) in enumerate(zip(pts, up))]
        b = [(p[0] + u[0] * width(i / K) / 2 * f1, p[1] + u[1] * width(i / K) / 2 * f1) for i, (p, u) in enumerate(zip(pts, up))]
        gd.polygon([S(p) for p in [ext(a[0])] + a + b[::-1] + [ext(b[0])]], fill=val)
    band(1.3, 0.45, 222)       # light upper back
    band(0.45, -0.15, 196)     # side
    band(-0.15, -0.42, 168)    # shadow above the belly
    gray = gray.filter(ImageFilter.GaussianBlur(SS * 1.5))
    # belly plates: pale band with segment lines
    belly = Image.new("L", (N, N), 0); bd = ImageDraw.Draw(belly)
    a = [(p[0] - u[0] * width(i / K) / 2 * 0.42, p[1] - u[1] * width(i / K) / 2 * 0.42) for i, (p, u) in enumerate(zip(pts, up))]
    b = [(p[0] - u[0] * width(i / K) / 2 * 1.2, p[1] - u[1] * width(i / K) / 2 * 1.2) for i, (p, u) in enumerate(zip(pts, up))]
    bd.polygon([S(p) for p in [ext(a[0])] + a[: int(K * 0.93)] + b[: int(K * 0.93)][::-1] + [ext(b[0])]], fill=255)
    belly = ImageChops.multiply(belly, mask)
    gray.paste(240, mask=belly)
    ld = ImageDraw.Draw(gray)
    seg = 0.035
    t = 0.03
    while t < 0.9:
        i = int(t * K); p, u = pts[i], up[i]; w = width(t) / 2
        ld.line([S((p[0] - u[0] * w * 0.42, p[1] - u[1] * w * 0.42)), S((p[0] - u[0] * w * 1.1, p[1] - u[1] * w * 1.1))], fill=150, width=int(2.2 * SS))
        t += seg * (0.6 + 0.4 * w / (w_base / 2))
    # scale marks on the side: small dark arcs
    rnd = random.Random(3)
    for k in range(18):
        t = rnd.uniform(0.08, 0.8); i = int(t * K); p, u = pts[i], up[i]; w = width(t) / 2
        f = rnd.uniform(-0.05, 0.75)
        x, y = p[0] + u[0] * w * f, p[1] + u[1] * w * f
        r = 3 + w * 0.07
        ld.arc([S((x - r, y - r)), S((x + r, y + r))], 200, 340, fill=140, width=int(2 * SS))
    # spikes darker
    gray.paste(110, mask=ImageChops.subtract(spike, mask.point(lambda v: 0)))
    gray.paste(110, mask=Image.composite(spike, Image.new("L", (N, N), 0), spike))
    # spade tip darker
    sp = Image.new("L", (N, N), 0); ImageDraw.Draw(sp).polygon([S(p) for p in spade], fill=255)
    gray.paste(120, mask=sp)
    return finish(mask, gray)


def fit(img, box, mirror=False):
    bb = img.getchannel("A").point(lambda a: 255 if a > 40 else 0).getbbox()
    crop = img.crop(bb)
    if mirror:
        crop = crop.transpose(Image.FLIP_LEFT_RIGHT)
    crop = crop.resize((box[2] - box[0], box[3] - box[1]), Image.LANCZOS)
    out = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
    out.alpha_composite(crop, (box[0], box[1]))
    return out


TAIL_BOX = {"east": (70, 120, 460, 420), "south": (14, 128, 304, 420), "north": (208, 108, 498, 400)}


def tint(im, rgb):
    r, g, b, a = im.split()
    return Image.merge("RGBA", (r.point(lambda v: v * rgb[0] // 255), g.point(lambda v: v * rgb[1] // 255), b.point(lambda v: v * rgb[2] // 255), a))


def main():
    for d in ("DragonEars", "DragonTail"):
        os.makedirs(os.path.join(OUT, d), exist_ok=True)
    es = ears_south()
    ee = ears_east()
    ears = {"south": es, "north": ears_north(), "east": ee}
    for dr, im in ears.items():
        im.save(os.path.join(OUT, "DragonEars", f"DragonEars_{dr}.png"))
    te = tail_east()
    tail = {"east": fit(te, TAIL_BOX["east"]), "south": fit(te, TAIL_BOX["south"]), "north": fit(te, TAIL_BOX["north"], mirror=True)}
    for dr, im in tail.items():
        im.save(os.path.join(OUT, "DragonTail", f"DragonTail_{dr}.png"))
    for k, d in (("ears", ears), ("tail", tail)):
        for dr, im in d.items():
            print(k, dr, im.getchannel("A").point(lambda a: 255 if a > 40 else 0).getbbox())
    review(ears, tail)


def review(ears, tail):
    HA = r"C:\Program Files (x86)\Steam\steamapps\common\RimWorld\Mods\sized-apparel-heads\Textures\Things\Pawn\Humanlike"
    W = r"C:\Program Files (x86)\Steam\steamapps\workshop\content\294100"
    bs = W + r"\2920751126\Textures\BS_HeadAttachments\BS_DragonEars"
    afu = W + r"\2880942803\1.5\Textures\Things\Pawn\Humanlike\AFUBodyAttachments\SpikedLizardTail\SpikedLizardTailA"
    if not os.path.exists(afu + "_south.png"):
        afu = afu.replace(r"\1.5\\", r"\1.4\\").replace("\\1.5\\", "\\1.4\\")
    sa = r"C:\Program Files (x86)\Steam\steamapps\common\RimWorld\Mods\sized-apparel-zero\Textures\Things\Pawn\Humanlike\BodyAttachments\FurryTail\FurryTail"
    red, orange = (196, 72, 58), (232, 146, 70)
    heads = {(h, dr): Image.open(HA + rf"\Heads\Female\Female_{h}_Normal_{dr}.png").convert("RGBA").resize((512, 512)) for h in ("Average", "Narrow") for dr in ("south", "east", "north")}
    def on_head(h, dr, im, col, behind=False):
        tile = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
        e = tint(im, col)
        if h == "Narrow":
            w = int(512 * 1.3 / 1.5); e2 = Image.new("RGBA", (512, 512), (0, 0, 0, 0)); e2.alpha_composite(e.resize((w, 512), Image.LANCZOS), ((512 - w) // 2, 0)); e = e2
        if behind:
            tile.alpha_composite(e)
        tile.alpha_composite(tint(heads[(h, dr)], col))
        if not behind:
            tile.alpha_composite(e)
        return tile
    load = lambda p: Image.open(p).convert("RGBA")
    rows = [
        ("BS dragon ears (live)", [on_head(h, dr, load(f"{bs}_{dr}.png"), red) for h in ("Average", "Narrow") for dr in ("south", "east", "north")]),
        ("new ears, red skin", [on_head(h, dr, ears[dr], red, True) for h in ("Average", "Narrow") for dr in ("south", "east", "north")]),
        ("new ears, orange skin", [on_head(h, dr, ears[dr], orange, True) for h in ("Average", "Narrow") for dr in ("south", "east", "north")]),
        ("AFU lizard tail (live)", [tint(load(f"{afu}_{dr}.png"), red) for dr in ("south", "east", "north")] + [None] * 3),
        ("SA furry tail (size ref)", [tint(load(f"{sa}_{dr}.png"), (230, 230, 230)) for dr in ("south", "east", "north")] + [None] * 3),
        ("new tail, red / orange", [tint(tail[dr], red) for dr in ("south", "east", "north")] + [tint(tail[dr], orange) for dr in ("south", "east", "north")]),
    ]
    cell = 200
    sheet = Image.new("RGBA", (170 + cell * 6, 24 + cell * len(rows)), (150, 120, 90, 255))
    d = ImageDraw.Draw(sheet)
    for r, (label, tiles) in enumerate(rows):
        d.text((4, 24 + r * cell + 90), label, fill="white")
        for c, t in enumerate(tiles):
            if t is not None:
                sheet.alpha_composite(t.resize((cell, cell), Image.LANCZOS), (170 + c * cell, 24 + r * cell))
    for c, lab in enumerate(["avg front", "avg side", "avg back", "narrow front", "narrow side", "narrow back"]):
        d.text((170 + c * cell + 60, 4), lab, fill="white")
    sheet.save(os.path.join(ART, "Staging", "Dragon-review.png"))


if __name__ == "__main__":
    main()
