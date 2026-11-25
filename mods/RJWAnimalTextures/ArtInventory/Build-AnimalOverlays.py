"""New genital overlays for RJW - Animal Graphics Addon (RimNudeWorld Zoo): elephant and bull (prototype).

How the addon draws them (RimNudeWorld-AnimalAddon.dll, PawnRenderNode_AnimalAddon, 1.6 patch
PawnRenderTreePatch_RenderNodes.xml): texture path = the animal's body texPath + "_Lewd", Graphic_Multi on
the body's own mesh (same drawSize), node baseLayer -1, so it is drawn UNDER the body and only what sticks
out below the belly shows. The node is used only if <path>_north exists. Texture resolution is free: a
512 px file at the same path replaces the 128 px original by load order.

The originals: 128 px, so the visible part is a blurry stub (elephant: pink stub, white sheath edge and a
trail of stray pixels; bull: a thin pink line, no sheath). These are drawn for the HC Animal Reskins bodies
(the user's body textures, 512 elephant / 384 bull): positions from the measured belly line of those bodies,
colours sampled from them (the node colour is white, so colours are baked), outline like theirs.
  elephant: grey skin sheath bulging from mid belly; long S-curved penis, grey turning pink, wide tip.
  bull: furred preputial sheath along the belly in front of the hind legs, with a hair tuft; long thin pink
        penis with a tapered, slightly twisted tip.
Mammals (SPECS2) are drawn from anatomy, placed on the measured belly line of their HC body (belly_fn):
  cervines (deer, elk, caribou): equine-shaped, as asked by the user: short furred sheath on the originals'
    own spot, penis hanging down-forward from it; even dark grey-pink mottled shaft, soft preputial ring
    (no drawn line), wide flared glans with a flat front face; scrotum behind the sheath.
  other ruminants (gazelle, ibex, yak, muffalo, boomalope): pendulous scrotum before the hind legs, furred
    sheath along the belly with a hair tuft, long thin penis; tip: gazelle pointed, bovids with a spiral twist, ibex (caprine) with the thread-like
    urethral process, camelids (alpaca, dromedary) with an upturned cartilage hook and a small perineal scrotum.
  bear, raccoon: scrotum behind a belly sheath, uniform penis with a rounded, slightly swollen tip.
  felines (cat, lynx, cougar): placed like the other carnivores (as asked: not the real perineal layout),
    sheath under the abdomen, cone forward-down with barbs: thorns sticking out of both edges and on the face.
  rhino: no external scrotum; short grey skin sheath mid-belly, long grey shaft along the belly turning pink
    without hard lines, flared flat-fronted glans with lateral flaps.
  Sheath attachment and scrotum neck are clipped to the body silhouette, so they never stick out.
  pig, boar: perineal scrotum, sheath forward on the belly with the preputial pouch, real 3D corkscrew tip.
Birds: duck = everted 3D coil from the cloaca; ratites (BIRDS) = thick curved phallus with a spiral groove,
  emu/cassowary tip curling. Penis tubes are disk sweeps (sweep), split at depth turns so coils overlap.
Traced (faithful): iguana, cobra, tortoise, megascarab, megaspider, spelopede, thrumbo keep their original
  design; the old outline (rim pixels much darker than the brightest colour near them, which includes its bleed into the fill) is removed before the
  colours are spread, so no dark specks are left. Megasloth keeps the carnivore family.
Only east is written. North/south keep coming from the addon (separate texture lookups), which also keeps
its "_north exists" check working; a few originals have a drawn north/south (caribou, cobra, deer,
megaspider, spelopede north; tortoise south) that stay as they are.
Animals left out: overlays already as fine as their body (horses, donkey, sheep, goat, goose, bison,
canines, warg) and those with no HC body to fit (dryads, Grimworld fester rat and mauler).
Writes Staging/AnimalOverlays/Things/Pawn/Animal/<folder>/<name>_Lewd_east.png and
Staging/AnimalOverlays-review.png.
Run: python -I Build-AnimalOverlays.py [Name ...]   (no argument: all; about 5 minutes)
"""
import math, os
from PIL import Image, ImageChops, ImageDraw, ImageFilter

ART = os.path.dirname(os.path.abspath(__file__))
MODS = r"C:\Program Files (x86)\Steam\steamapps\common\RimWorld\Mods"
ZOO = os.path.join(MODS, "RJW - Animal Graphics Addon", "Textures", "Things", "Pawn", "Animal")
HC = os.path.join(MODS, "hc-animalreskins-complete-2-for-canines-animations", "Textures", "Things", "Pawn", "Animal")
OUT = os.path.join(ART, "Staging", "AnimalOverlays", "Things", "Pawn", "Animal")
N = 512          # output size
U = 4            # supersampling
LINE = (22, 20, 20)
L = (-0.45, -0.7, 0.55)
_n = math.sqrt(sum(c * c for c in L)); L = tuple(c / _n for c in L)
H = (L[0], L[1], L[2] + 1); _n = math.sqrt(sum(c * c for c in H)); H = tuple(c / _n for c in H)


# ---------- geometry ----------
def bezier(pts, n=80):
    out = []
    for i in range(n + 1):
        t = i / n
        p = list(pts)
        while len(p) > 1:
            p = [(a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t) for a, b in zip(p, p[1:])]
        out.append(p[0])
    return out


def tube(draw, path, widths, s):
    """filled tube along path; widths: function t -> width (body px); s: scale body px -> canvas px."""
    n = len(path) - 1
    left, right = [], []
    for i, (x, y) in enumerate(path):
        a = path[max(i - 1, 0)]; b = path[min(i + 1, n)]
        dx, dy = b[0] - a[0], b[1] - a[1]; ln = math.hypot(dx, dy) or 1
        nx, ny = -dy / ln, dx / ln
        w = widths(i / n) / 2
        left.append(((x + nx * w) * s, (y + ny * w) * s)); right.append(((x - nx * w) * s, (y - ny * w) * s))
    draw.polygon(left + right[::-1], fill=255)
    for (x, y), t in ((path[0], 0), (path[-1], 1)):
        w = widths(t) / 2 * s
        draw.ellipse((x * s - w, y * s - w, x * s + w, y * s + w), fill=255)


def ellipse_rot(draw, cx, cy, rx, ry, ang, s):
    pts = []
    for i in range(48):
        a = 2 * math.pi * i / 48
        x, y = rx * math.cos(a), ry * math.sin(a)
        pts.append(((cx + x * math.cos(ang) - y * math.sin(ang)) * s, (cy + x * math.sin(ang) + y * math.cos(ang)) * s))
    draw.polygon(pts, fill=255)


# ---------- shading ----------
def distance(mask):
    w, h = mask.size; mp = mask.load(); INF = 10 ** 7
    d = [[0 if mp[x, y] < 128 else INF for x in range(w)] for y in range(h)]
    for y in range(h):
        row, prev = d[y], d[y - 1] if y else None
        for x in range(w):
            if row[x]:
                v = row[x]
                if x: v = min(v, row[x - 1] + 3)
                if prev:
                    v = min(v, prev[x] + 3)
                    if x: v = min(v, prev[x - 1] + 4)
                    if x < w - 1: v = min(v, prev[x + 1] + 4)
                row[x] = v
    for y in range(h - 1, -1, -1):
        row, nxt = d[y], d[y + 1] if y < h - 1 else None
        for x in range(w - 1, -1, -1):
            if row[x]:
                v = row[x]
                if x < w - 1: v = min(v, row[x + 1] + 3)
                if nxt:
                    v = min(v, nxt[x] + 3)
                    if x < w - 1: v = min(v, nxt[x + 1] + 4)
                    if x: v = min(v, nxt[x - 1] + 4)
                row[x] = v
    return d


def shaded(mask, colour_at, spec, gloss=24):
    """lit RGB for a part mask; colour_at(x, y, light 0..1) -> rgb."""
    bb = mask.getbbox()
    out = Image.new("RGB", mask.size)
    if not bb:
        return out
    pad = 4
    box = (max(bb[0] - pad, 0), max(bb[1] - pad, 0), min(bb[2] + pad, mask.width), min(bb[3] + pad, mask.height))
    m = mask.crop(box)
    d = distance(m)
    dmax = max(max(r) for r in d) or 1
    hf = Image.new("L", m.size); hp = hf.load()
    for y, row in enumerate(d):
        for x, v in enumerate(row):
            if v:
                t = min(v / (dmax * 1.02), 1.0)
                hp[x, y] = int(255 * math.sqrt(1 - (1 - t) ** 2))
    hf = hf.filter(ImageFilter.GaussianBlur(U * 1.5)); hp = hf.load()
    k = 255.0 / (dmax / 3 * 0.9)
    part = Image.new("RGB", m.size); pp = part.load(); mp = m.load()
    w, h = m.size
    for y in range(1, h - 1):
        for x in range(1, w - 1):
            if mp[x, y] < 8:
                continue
            nx = -(hp[x + 1, y] - hp[x - 1, y]) / (2 * k); ny = -(hp[x, y + 1] - hp[x, y - 1]) / (2 * k)
            n = math.sqrt(nx * nx + ny * ny + 1); nx, ny, nz = nx / n, ny / n, 1 / n
            lam = max(0.0, nx * L[0] + ny * L[1] + nz * L[2])
            c = colour_at(x + box[0], y + box[1], 0.3 + 0.7 * lam)
            if spec:
                sp = max(0.0, nx * H[0] + ny * H[1] + nz * H[2]) ** gloss * spec
                c = [ci + (255 - ci) * sp for ci in c]
            pp[x, y] = tuple(int(max(0, min(255, ci))) for ci in c)
    out.paste(part, box[:2])
    return out


def mix(a, b, t):
    return tuple(a[i] + (b[i] - a[i]) * t for i in range(3))


def lit(dark, base, l):
    return mix(dark, base, min(l * 1.1, 1.0))


# ---------- compose ----------
def compose(parts, line_w):
    """parts: list of (mask, rgb) back to front. Each part gets its own outline (line_w canvas px)."""
    S = N * U
    col = Image.new("RGB", (S, S), LINE); alpha = Image.new("L", (S, S), 0)
    for part in parts:
        mask, rgb = part[0], part[1]
        k = int(part[2] if len(part) > 2 else line_w) | 1
        grown = mask.filter(ImageFilter.MaxFilter(k)) if k > 1 else mask
        col = Image.composite(Image.new("RGB", (S, S), LINE), col, grown.filter(ImageFilter.GaussianBlur(U * 0.35)))
        col = Image.composite(rgb, col, mask.filter(ImageFilter.GaussianBlur(U * 0.35)))
        alpha = ImageChops.lighter(alpha, grown)
    alpha = alpha.filter(ImageFilter.GaussianBlur(U * 0.4))
    return Image.merge("RGBA", (*col.split(), alpha)).resize((N, N), Image.LANCZOS)


def blank():
    return Image.new("RGBA", (4, 4), (0, 0, 0, 0))


def elephant():
    s = U * N / 512          # body texture is 512
    S = N * U
    # penis: from the sheath at mid belly, down then forward, S-curve, wide flat tip
    path = bezier([(206, 338), (214, 392), (236, 404), (262, 398), (284, 392), (296, 404)], 90)
    m = Image.new("L", (S, S)); d = ImageDraw.Draw(m)
    tube(d, path, lambda t: 24 - 8 * t + 6 * max(0, t - 0.85) / 0.15, s)
    ellipse_rot(d, 297, 405, 14, 10, 0.5, s)
    def pen_col(x, y, l):
        t = min(max((x / s - 210) / 90, 0), 1)                     # grey at the root, pink toward the tip
        base = mix((128, 122, 126), (214, 150, 152), t ** 1.3)
        dark = mix((52, 48, 52), (140, 80, 86), t ** 1.3)
        return lit(dark, base, l)
    pen = shaded(m, pen_col, 0.35)
    # sheath: a rounded skin bulge from the belly
    sh = Image.new("L", (S, S)); d = ImageDraw.Draw(sh)
    ellipse_rot(d, 200, 336, 30, 16, 0.18, s)
    sheath = shaded(sh, lambda x, y, l: lit((30, 30, 32), (92, 92, 96), l), 0.12)
    # the sheath opening: a dark crease where the penis leaves it
    op = Image.new("L", (S, S)); ImageDraw.Draw(op).arc(((198) * s, (336) * s, (222) * s, (356) * s), 200, 340, fill=255, width=int(3 * s))
    sheath = Image.composite(Image.new("RGB", (S, S), (24, 22, 24)), sheath, ImageChops.multiply(op, sh).filter(ImageFilter.GaussianBlur(U * 0.5)))
    return compose([(m, pen), (sh, sheath)], 6 * s)


def bull():
    s = U * N / 384          # body texture is 384
    S = N * U
    # sheath along the belly, in front of the hind legs; tuft of hair at its front end
    sh = Image.new("L", (S, S)); d = ImageDraw.Draw(sh)
    # starts inside the body (drawn under it), so only the lower bulge shows and it stays attached
    tube(d, bezier([(98, 266), (128, 280), (160, 284)], 40), lambda t: 15 + 5 * math.sin(t * math.pi * 0.8), s)
    def fur(x, y, l):
        return lit((52, 38, 26), (128, 96, 66), l)
    sheath = shaded(sh, fur, 0.08)
    tuft = Image.new("L", (S, S)); d = ImageDraw.Draw(tuft)
    for dx, ln, bend in ((-5, 9, -1.5), (-2.5, 11, -0.5), (0, 12, 0.5), (2.5, 10, 1.5), (5, 8, 2.5)):
        x0, y0 = 158 + dx, 288
        pts = bezier([(x0, y0), (x0 + bend * 0.5, y0 + ln * 0.6), (x0 + bend, y0 + ln)], 12)
        d.line([(x * s, y * s) for x, y in pts], fill=255, width=int(1.6 * s))
    tuft = tuft.filter(ImageFilter.GaussianBlur(U * 0.3)).point(lambda v: 255 if v > 100 else 0)
    tuft_rgb = Image.new("RGB", (S, S), (58, 42, 28))
    # penis: long and thin, out of the sheath front, forward and down, tapered twisted tip
    m = Image.new("L", (S, S)); d = ImageDraw.Draw(m)
    path = bezier([(154, 288), (176, 298), (196, 300), (214, 310)], 70)
    tube(d, path, lambda t: 8.5 - 4.5 * t ** 1.6, s)
    pen = shaded(m, lambda x, y, l: lit((150, 70, 82), (236, 150, 158), l), 0.5, 30)
    # a light ridge (the twist) along the last third
    ridge = Image.new("L", (S, S)); ImageDraw.Draw(ridge).line([(p[0] * s, (p[1] - 1.2) * s) for p in path[45:]], fill=255, width=int(1.3 * s))
    pen = Image.composite(Image.new("RGB", (S, S), (250, 196, 200)), pen, ImageChops.multiply(ridge, m).filter(ImageFilter.GaussianBlur(U * 0.5)).point(lambda v: v * 2 // 3))
    return compose([(m, pen), (tuft, tuft_rgb, 1), (sh, sheath)], 4.5 * s)


# ---------- generic families for the other animals ----------
# Coordinates are in the HC body texture's pixels (W = its width); every organ starts inside the body
# (the node is drawn under it) so it stays attached and only the part below the outline shows.
PINK = ((150, 70, 82), (236, 150, 158))
RED = ((120, 40, 50), (214, 96, 104))
PURPLE = ((60, 40, 56), (140, 104, 128))


def body_colour(W, rel, name, x, y, up=6):
    """average body colour just inside the belly above (x, y), ignoring the dark outline."""
    b = Image.open(os.path.join(HC, rel, name + "_east.png")).convert("RGBA")
    px = b.load(); acc = [0, 0, 0]; n = 0
    for yy in range(int(y - up - 6), int(y - up + 1)):
        for xx in range(int(x - 6), int(x + 7)):
            if 0 <= xx < b.width and 0 <= yy < b.height:
                r, g, bl, a = px[xx, yy]
                if a > 200 and r + g + bl > 110:
                    acc[0] += r; acc[1] += g; acc[2] += bl; n += 1
    if not n:
        return (120, 100, 90)
    return tuple(c // n for c in acc)


def fur_pair(c):
    base = tuple(min(255, int(v * 1.05)) for v in c)
    return tuple(int(v * 0.45) for v in base), base


def ctx(W):
    return N * U, U * N / W


def new_mask(S):
    m = Image.new("L", (S, S)); return m, ImageDraw.Draw(m)


def sag_path(a, b, sag, n=60, lift=0.0):
    mx, my = (a[0] + b[0]) / 2, (a[1] + b[1]) / 2
    return bezier([a, (mx - (b[1] - a[1]) * lift, my + sag), b], n)


def carnivore(W, fur, root, tip, bw, pw, pen=PINK, barbs=False):
    """furred sheath bulb on the belly with a short conical pink tip (bear, felines, raccoon)."""
    S, s = ctx(W)
    ang = math.atan2(tip[1] - root[1], tip[0] - root[0])
    sh, d = new_mask(S)
    ellipse_rot(d, root[0], root[1], bw, bw * 0.7, ang, s)
    dk, bs = fur_pair(fur)
    sheath = shaded(sh, lambda x, y, l: lit(dk, bs, l), 0.06)
    m, d = new_mask(S)
    a = (root[0] + math.cos(ang) * bw * 0.4, root[1] + math.sin(ang) * bw * 0.4)
    path = sag_path(a, tip, 1.5, 40)
    tube(d, path, lambda t: pw * (1 - 0.75 * t), s)
    penr = shaded(m, lambda x, y, l: lit(pen[0], pen[1], l), 0.55, 30)
    if barbs:   # feline spines: small light dots along the tip
        bm, d2 = new_mask(S)
        for t in (0.45, 0.6, 0.72, 0.84):
            x, y = path[int(t * (len(path) - 1))]
            r = max(0.6, pw * 0.11)
            d2.ellipse(((x - r) * s, (y - r - pw * 0.15) * s, (x + r) * s, (y + r - pw * 0.15) * s), fill=255)
        penr = Image.composite(Image.new("RGB", (S, S), (252, 214, 218)), penr, ImageChops.multiply(bm, m).filter(ImageFilter.GaussianBlur(U * 0.3)))
    return compose([(m, penr), (sh, sheath)], max(3.5, bw * 0.25) * s)


def faithful(W, src, line=None):
    """keep the original design: the original overlay's own silhouette, colours and pattern, traced at
    512 (smoothed edges), its colours filled under the old outline and smoothed, a light volume shading on
    top, and a clean even outline. Position stays the original's."""
    S = N * U
    im = Image.open(src).convert("RGBA")
    F = S / im.width
    a = im.getchannel("A")
    rgb = im.convert("RGB")
    luma = rgb.convert("L")
    solid = a.point(lambda v: 255 if v > 100 else 0)
    # the old outline bleeds 2-3 px into the fill as darkened colours: in a 4 px rim band, drop every pixel
    # much darker than the brightest colour near it (the tortoise's maroon tip is dark everywhere, so it stays)
    rim = ImageChops.subtract(solid, solid.filter(ImageFilter.MinFilter(11)))
    ref = ImageChops.multiply(luma, solid).filter(ImageFilter.MaxFilter(7))
    dark = Image.frombytes("L", luma.size, bytes(255 if l < r * 0.86 else 0 for l, r in zip(luma.tobytes(), ref.tobytes())))
    inner = ImageChops.subtract(ImageChops.subtract(solid, ImageChops.multiply(rim, dark)), a.point(lambda v: 0 if v > 230 else 255))
    # shape: the whole original silhouette, minus about half its outline (the new outline is drawn outside)
    big = solid.resize((S, S), Image.LANCZOS).filter(ImageFilter.GaussianBlur(F * 0.85)).point(lambda v: 255 if v >= 128 else 0)
    shape = big.filter(ImageFilter.MinFilter(int(F * 0.5) | 1))
    # colours: the inside colours spread over the old outline pixels (normalised blur), then upsampled
    # (multi-scale: where no inside colour is near, take it from a wider blur)
    chans = [Image.new("L", im.size) for _ in range(3)]
    done = Image.new("L", im.size)
    for rad, need in ((1.6, 24), (3.0, 24), (6.0, 12), (16.0, 1)):
        wb = inner.filter(ImageFilter.GaussianBlur(rad)).tobytes()
        ok = Image.frombytes("L", im.size, bytes(255 if w >= need else 0 for w in wb))
        take = ImageChops.subtract(ok, done)
        for k, c in enumerate(rgb.split()):
            nb = ImageChops.multiply(c, inner).filter(ImageFilter.GaussianBlur(rad)).tobytes()
            v = Image.frombytes("L", im.size, bytes(min(255, n * 255 // max(w, 1)) for n, w in zip(nb, wb)))
            chans[k] = Image.composite(v, chans[k], take)
        done = ImageChops.lighter(done, ok)
    filled = Image.composite(rgb, Image.merge("RGB", chans), inner)
    col = filled.resize((S, S), Image.BICUBIC).filter(ImageFilter.GaussianBlur(F * 0.3))
    cp = col.load()
    lit_img = shaded(shape, lambda x, y, l: tuple(v * (0.72 + 0.42 * l) for v in cp[x, y]), 0.3, 24)
    return compose([(shape, lit_img)], (line or max(4.0, F * 0.9)))


# ---------- anatomy drawings (v2): scrotum, belly-attached sheath, species penis ----------
def belly_fn(fold, name):
    a = Image.open(os.path.join(HC, fold, name + "_east.png")).convert("RGBA").getchannel("A")
    px = a.load()
    low = [next((y for y in range(a.height - 1, -1, -1) if px[x, y] > 128), None) for x in range(a.width)]
    def f(x):
        x = int(round(min(max(x, 0), a.width - 1)))
        v = [low[i] for i in range(max(0, x - 2), min(a.width, x + 3)) if low[i] is not None]
        return sum(v) / len(v) if v else 0
    return f


def circ(x, y, r):
    return (x - r, y - r, x + r, y + r)


def sweep(layer, pts, radius, colour, s, lw):
    """shaded tube as overlapping disks. pts (x, y, z) body px, radius(t) body px, colour(t) -> (dark, base,
    light). Split where the depth turns (helix half-turns); back pieces drawn first, each with its outline,
    so coils overlap with a line between them."""
    S = layer.width; n = len(pts)
    chunks, cur = [], [0]
    for i in range(1, n):
        if i >= 2 and (pts[i][2] - pts[i - 1][2]) * (pts[i - 1][2] - pts[i - 2][2]) < 0:
            chunks.append(cur); cur = []
        cur.append(i)
    chunks.append(cur)
    order = sorted(range(len(chunks)), key=lambda k: sum(pts[i][2] for i in chunks[k]) / len(chunks[k]))
    step = (sum(math.dist(pts[i][:2], pts[i - 1][:2]) for i in range(1, n)) / (n - 1)) or 1
    drawn = set()
    for k in order:
        c = chunks[k]
        R = max(radius(i / (n - 1)) for i in c) * s + lw + 8
        xs = [pts[i][0] * s for i in c]; ys = [pts[i][1] * s for i in c]
        box = (max(0, int(min(xs) - R)), max(0, int(min(ys) - R)), min(S, int(max(xs) + R)), min(S, int(max(ys) + R)))
        bw, bh = box[2] - box[0], box[3] - box[1]
        mo, mb, mm, ml, msp = (Image.new("L", (bw, bh)) for _ in range(5))
        cb, cm, cl = (Image.new("RGB", (bw, bh)) for _ in range(3))
        do, db, dm, dl, dsp = (ImageDraw.Draw(m) for m in (mo, mb, mm, ml, msp))
        dcb, dcm, dcl = (ImageDraw.Draw(m) for m in (cb, cm, cl))
        rs = []
        for i in c:
            t = i / (n - 1); r = radius(t) * s; rs.append(r)
            x = pts[i][0] * s - box[0]; y = pts[i][1] * s - box[1]
            dk, bs, lt = (tuple(int(v) for v in col) for col in colour(t))
            m = int(math.ceil(radius(t) * 1.8 / step)) + 1
            if not any(j in drawn for j in range(i - m, i + m + 1)):
                do.ellipse(circ(x, y, r + lw), fill=255)
            db.ellipse(circ(x, y, r), fill=255); dcb.ellipse(circ(x, y, r), fill=dk)
            dcm.ellipse(circ(x, y, r), fill=bs); dcl.ellipse(circ(x, y, r), fill=lt)
            dm.ellipse(circ(x - 0.16 * r, y - 0.2 * r, r * 0.8), fill=255)
            dl.ellipse(circ(x - 0.3 * r, y - 0.36 * r, r * 0.42), fill=255)
            dsp.ellipse(circ(x - 0.38 * r, y - 0.44 * r, r * 0.15), fill=255)
        ra = sum(rs) / len(rs)
        mm = ImageChops.multiply(mm.filter(ImageFilter.GaussianBlur(ra * 0.3)), mb)
        ml = ImageChops.multiply(ml.filter(ImageFilter.GaussianBlur(ra * 0.3)), mb)
        msp = ImageChops.multiply(msp.filter(ImageFilter.GaussianBlur(ra * 0.12)), mb).point(lambda v: v * 3 // 5)
        col = Image.composite(cm, cb, mm); col = Image.composite(cl, col, ml)
        col = Image.composite(Image.new("RGB", (bw, bh), (255, 250, 248)), col, msp)
        rgb = Image.composite(col, Image.new("RGB", (bw, bh), LINE), mb.filter(ImageFilter.GaussianBlur(U * 0.3)))
        alpha = ImageChops.lighter(mo, mb)
        layer.alpha_composite(Image.merge("RGBA", (*rgb.split(), alpha)), box[:2])
        drawn.update(c)


def add_part(canvas, mask, rgb, lw):
    """a shaded mask part with its own outline, over what is already on the canvas."""
    S = canvas.width
    k = int(lw) | 1
    grown = mask.filter(ImageFilter.MaxFilter(k))
    col = Image.composite(rgb, Image.new("RGB", (S, S), LINE), mask.filter(ImageFilter.GaussianBlur(U * 0.35)))
    canvas.alpha_composite(Image.merge("RGBA", (*col.split(), grown)))


def finish(canvas):
    a = canvas.getchannel("A").filter(ImageFilter.GaussianBlur(U * 0.3))
    canvas.putalpha(a)
    return canvas.resize((N, N), Image.LANCZOS)


def light_of(c, k=0.45):
    return mix(c, (255, 255, 255), k)


def pen_colours(base, dark, tip=None):
    def f(t):
        b, d = base, dark
        if tip:
            w = max(0.0, (t - 0.6) / 0.4) ** 1.5
            b = mix(base, tip[0], w); d = mix(dark, tip[1], w)
        return d, b, light_of(b)
    return f


def line_on(layer, pts, s, width, colour, clip_erode=5):
    """a groove/detail line drawn on a layer, kept inside its opaque area."""
    S = layer.width
    m = Image.new("L", (S, S)); ImageDraw.Draw(m).line([(x * s, y * s) for x, y in pts], fill=255, width=int(width), joint="curve")
    inside = layer.getchannel("A").point(lambda v: 255 if v > 250 else 0).filter(ImageFilter.MinFilter(clip_erode))
    m = ImageChops.multiply(m.filter(ImageFilter.GaussianBlur(U * 0.4)), inside)
    rgb = Image.composite(Image.new("RGB", (S, S), colour), layer.convert("RGB"), m)
    layer.paste(Image.merge("RGBA", (*rgb.split(), layer.getchannel("A"))))


def path_frame(path):
    out = []; n = len(path) - 1
    for i, (x, y) in enumerate(path):
        a = path[max(i - 1, 0)]; b = path[min(i + 1, n)]
        dx, dy = b[0] - a[0], b[1] - a[1]; ln = math.hypot(dx, dy) or 1
        out.append((x, y, dx / ln, dy / ln, -dy / ln, dx / ln))
    return out


# ---------- fur pieces ----------
def scrotum(canvas, s, b, x, r, hang, fur, skin=0.0, lw=18, body=None):
    S = canvas.width
    y0 = b(x) - r * 0.4
    yc = b(x) + r * hang
    m = Image.new("L", (S, S)); d = ImageDraw.Draw(m)
    neck = Image.new("L", (S, S))
    ImageDraw.Draw(neck).polygon([((x - r * 0.5) * s, (y0 - r) * s), ((x + r * 0.5) * s, (y0 - r) * s), ((x + r * 0.6) * s, yc * s), ((x - r * 0.6) * s, yc * s)], fill=255)
    if body is not None:   # the neck only exists under the body, so it never sticks out where the belly curves up
        neck = ImageChops.multiply(neck, body)
    m.paste(255, mask=neck)
    for dx, dy in ((-0.38, 0.0), (0.34, 0.12)):
        ellipse_rot(d, x + dx * r, yc + dy * r, r * 0.72, r * 0.92, 0.15, s)
    c = mix(fur, (214, 150, 150), skin)
    dk, bs = tuple(v * 0.5 for v in c), c
    rgb = shaded(m, lambda X, Y, l: lit(dk, bs, l), 0.1 + 0.25 * skin, 20)
    # the crease between the two testes
    cr = Image.new("L", (S, S)); ImageDraw.Draw(cr).line([((x - 0.02 * r) * s, (yc - 0.35 * r) * s), ((x + 0.02 * r) * s, (yc + 0.6 * r) * s)], fill=255, width=max(3, int(r * 0.09 * s)))
    cr = ImageChops.multiply(cr.filter(ImageFilter.GaussianBlur(U * 0.6)), m.filter(ImageFilter.MinFilter(9)))
    rgb = Image.composite(Image.new("RGB", (S, S), tuple(int(v * 0.42) for v in c)), rgb, cr)
    add_part(canvas, m, rgb, lw)


def sheath(canvas, s, b, x0, x1, h, fur, lw=18, tuft=False, pouch=False, drop=0.35, body=None):
    """furred prepuce lying along the belly from x0 (inside, under the body) to its opening at x1. Returns
    the point where the penis leaves it and the sheath's own direction."""
    S = canvas.width
    p0 = (x0, b(x0) - h * 0.7); p2 = (x1, b(x1) + h * drop); p1 = ((x0 + x1) / 2, b((x0 + x1) / 2) + h * drop * 0.45)
    m = Image.new("L", (S, S)); d = ImageDraw.Draw(m)
    tube(d, bezier([p0, p1, p2], 40), lambda t: h * (0.7 + 0.35 * t), s)
    att = Image.new("L", (S, S))
    xs = [x0 + (x1 - x0) * i / 12 for i in range(13)]
    ImageDraw.Draw(att).polygon([(x * s, (b(x) - h * 1.8) * s) for x in xs] + [(x * s, (b(x) + h * drop * 0.5) * s) for x in xs[::-1]], fill=255)
    if body is not None:   # attachment to the belly: only under the body
        att = ImageChops.multiply(att, body)
    m.paste(255, mask=att)
    if pouch:   # pig: the preputial diverticulum, a round bulge above the opening
        ellipse_rot(d, x1 - h * 0.9, b(x1 - h) + h * 0.15, h * 0.85, h * 0.7, 0, s)
    dk, bs = fur_pair(fur)
    rgb = shaded(m, lambda X, Y, l: lit(dk, bs, l), 0.06)
    ang = math.atan2(p2[1] - p1[1], p2[0] - p1[0])
    # the opening: a darker rim on the front end
    rim = Image.new("L", (S, S)); ellipse_rot(ImageDraw.Draw(rim), p2[0] + math.cos(ang) * h * 0.38, p2[1] + math.sin(ang) * h * 0.38, h * 0.2, h * 0.42, ang, s)
    rim = ImageChops.multiply(rim.filter(ImageFilter.GaussianBlur(U * 0.8)), m)
    rgb = Image.composite(Image.new("RGB", (S, S), tuple(int(v * 0.3) for v in fur)), rgb, rim)
    add_part(canvas, m, rgb, lw)
    if tuft:
        tm = Image.new("L", (S, S)); d = ImageDraw.Draw(tm)
        for dx, ln, bend in ((-0.5, 0.8, -0.15), (-0.25, 1.0, -0.05), (0, 1.1, 0.05), (0.22, 0.95, 0.15), (0.42, 0.7, 0.25)):
            xa, ya = p2[0] + dx * h - h * 0.15, p2[1] + h * 0.3
            pts = bezier([(xa, ya), (xa + bend * h * 0.5, ya + ln * h * 0.6), (xa + bend * h, ya + ln * h)], 12)
            d.line([(X * s, Y * s) for X, Y in pts], fill=255, width=max(3, int(h * 0.1 * s)))
        tm = tm.filter(ImageFilter.GaussianBlur(U * 0.3)).point(lambda v: 255 if v > 100 else 0)
        add_part(canvas, tm, Image.new("RGB", (S, S), tuple(int(v * 0.4) for v in fur)), 1)
    start = (p2[0] - math.cos(ang) * h * 0.4, p2[1] - math.sin(ang) * h * 0.4 + h * 0.05)
    return start, ang


# ---------- penis shapes ----------
PINKC = ((236, 150, 158), (150, 70, 82))
PINKT = ((236, 150, 158), (150, 70, 82))
EQUC = ((98, 74, 78), (38, 28, 32))   # equine shaft: darker, mottled-looking skin, pink glans
REDC = ((214, 104, 116), (118, 42, 56))


def straight_penis(layer, s, start, ang0, L, ang, pw, style, lw, cols=PINKC, tipc=None):
    """from start leaving at ang0, bending to ang (radians, 0 = forward, + = down)."""
    a0, a1 = ang0, ang
    p1 = (start[0] + math.cos(a0) * L * 0.35, start[1] + math.sin(a0) * L * 0.35)
    tip = (start[0] + math.cos(a1) * L, start[1] + math.sin(a1) * L)
    p2 = (tip[0] - math.cos(a1) * L * 0.3, tip[1] - math.sin(a1) * L * 0.3)
    pts = bezier([start, p1, p2, tip], 90)
    if style == "camelid":   # cartilage hook curling up at the tip
        e = pts[-1]
        pts += bezier([e, (e[0] + math.cos(a1) * L * 0.08, e[1] + math.sin(a1) * L * 0.08), (e[0] + L * 0.1, e[1] - L * 0.04), (e[0] + L * 0.07, e[1] - L * 0.1)], 20)[1:]
    if style == "caprine":   # the thread-like urethral process beyond the glans
        e = pts[-1]
        pts += bezier([e, (e[0] + math.cos(a1) * L * 0.1, e[1] + math.sin(a1) * L * 0.1 + 2), (e[0] + math.cos(a1 - 0.5) * L * 0.2, e[1] + math.sin(a1 - 0.5) * L * 0.2)], 24)[1:]
    n = len(pts) - 1
    tmain = 90 / n
    hp = pw / 2
    def rad(t):
        u = t / tmain   # 0..1 over the main shaft
        if style in ("cervid", "bovid"):
            return hp * (1 if u < 0.7 else 1 - 0.6 * ((u - 0.7) / 0.3))
        if style == "caprine":
            if u <= 1:
                return hp * (0.95 + 0.25 * math.exp(-((u - 0.88) / 0.09) ** 2)) * (1 if u < 0.95 else 1 - 3 * (u - 0.95))
            return hp * 0.2
        if style == "camelid":
            return hp * (1 - 0.35 * min(u, 1)) if u <= 1 else hp * 0.65 * (1 - 0.4 * (u - 1) / (1 / tmain - 1))
        if style == "bear":
            return hp * (0.92 + 0.16 * math.exp(-((u - 0.86) / 0.09) ** 2) - (0.25 * (u - 0.95) / 0.05 if u > 0.95 else 0))
        if style == "feline":
            return hp * (1 - 0.6 * u)
        if style in ("equine", "rhino"):   # even shaft, soft preputial ring, wide glans flaring at the end
            k = min(1.0, max(0.0, (u - 0.78) / 0.14)); k = k * k * (3 - 2 * k)
            ring = 0.08 * math.exp(-((u - 0.4) / 0.06) ** 2)
            flare = 0.6 if style == "equine" else 0.35
            return hp * (0.96 + ring + flare * k)
        return hp
    colour = pen_colours(cols[0], cols[1], tip=tipc or (REDC if style in ("cervid", "bovid", "caprine") else None))
    if style in ("equine", "rhino"):   # dark skin up to the ring, lighter free part, pink glans; no hard lines
        c_mid = mix(cols[0], tipc[0], 0.25) if style == "equine" else cols[0]
        def colour(t):
            u = t / tmain
            a = min(1.0, max(0.0, (u - 0.45) / 0.2)); g = min(1.0, max(0.0, (u - 0.72) / 0.1))
            b_ = mix(mix(cols[0], c_mid, a), tipc[0], g); d_ = mix(cols[1], tipc[1], g * 0.9 + a * 0.15)
            return d_, b_, light_of(b_, 0.3)
    fr = path_frame(pts)
    if style == "rhino":     # the lateral flaps of the glans, behind the shaft
        x, y, tx, ty, nx, ny = fr[int(n * 0.9)]
        w = hp * 2.6
        flap = [(x + nx * w * (v - 0.5) - tx * hp * 0.2, y + ny * w * (v - 0.5) - ty * hp * 0.2, 0) for v in [i / 30 for i in range(31)]]
        sweep(layer, flap, lambda t: hp * (0.45 + 0.15 * math.sin(t * math.pi)), lambda t: colour(0.95), s, lw)
    sweep(layer, [(x, y, 0) for x, y in pts], rad, colour, s, lw)
    if style == "equine":   # mottled skin: soft pink patches on the dark part of the shaft
        import random
        rnd = random.Random(11); S = layer.width
        sp = Image.new("L", (S, S)); d = ImageDraw.Draw(sp)
        for _ in range(6):
            t = rnd.uniform(0.03, 0.62); x, y, tx, ty, nx, ny = fr[int(t * n)]
            o = rnd.uniform(-0.6, 0.6) * hp; r = rnd.uniform(0.16, 0.3) * hp
            d.ellipse(((x + nx * o - r) * s, (y + ny * o - r) * s, (x + nx * o + r) * s, (y + ny * o + r) * s), fill=170)
        inside = layer.getchannel("A").point(lambda v: 255 if v > 250 else 0).filter(ImageFilter.MinFilter(9))
        sp = ImageChops.multiply(sp.filter(ImageFilter.GaussianBlur(hp * s * 0.18)), inside)
        rgb = Image.composite(Image.new("RGB", (S, S), tuple(int(v) for v in mix(cols[0], tipc[0], 0.5))), layer.convert("RGB"), sp)
        layer.paste(Image.merge("RGBA", (*rgb.split(), layer.getchannel("A"))))
    if style in ("equine", "rhino"):   # the flat front of the glans: cut the round end, show the face as an oval
        S = layer.width
        x, y, tx, ty, nx, ny = fr[n]; re = rad(1.0)
        cx, cy = x - tx * re * 0.55, y - ty * re * 0.55
        keep = Image.new("L", (S, S), 255)
        far = re * 4
        ImageDraw.Draw(keep).polygon([((cx + nx * far) * s, (cy + ny * far) * s), ((cx + nx * far + tx * far) * s, (cy + ny * far + ty * far) * s),
                                      ((cx - nx * far + tx * far) * s, (cy - ny * far + ty * far) * s), ((cx - nx * far) * s, (cy - ny * far) * s)], fill=0)
        layer.putalpha(ImageChops.multiply(layer.getchannel("A"), keep))
        face = Image.new("L", (S, S)); ellipse_rot(ImageDraw.Draw(face), cx, cy, re * 0.32, re * 1.0, math.atan2(ty, tx), s)
        fc = colour(1.0)[1]
        frgb = shaded(face, lambda X, Y, l: lit(tuple(v * 0.7 for v in fc), light_of(fc, 0.15), l), 0.25, 20)
        dot = Image.new("L", (S, S)); ellipse_rot(ImageDraw.Draw(dot), cx + tx * re * 0.05, cy + ty * re * 0.05, re * 0.12, re * 0.22, math.atan2(ty, tx), s)
        frgb = Image.composite(Image.new("RGB", (S, S), tuple(int(v * 0.5) for v in fc)), frgb, dot.filter(ImageFilter.GaussianBlur(U * 0.5)))
        add_part(layer, face, frgb, lw)
    if style == "bovid":   # the spiral twist of the tip
        fr = path_frame(pts)
        g = []
        for i in range(int(n * 0.55), n):
            x, y, tx, ty, nx, ny = fr[i]; u = (i / n - 0.55) / 0.45
            o = rad(i / n) * 0.7 * math.sin(u * 2.4 * math.pi)
            g.append((x + nx * o, y + ny * o))
        line_on(layer, g, s, max(3, pw * 0.13 * s), tuple(int(v * 0.62) for v in cols[0]))
    if style == "feline":    # the barbs: thorns pointing back toward the base, out of both edges and on the face
        S = layer.width
        def spine(d, x, y, tx, ty, nx, ny, ln, wd, out):
            px_, py_ = x - tx * ln * 0.7 + nx * ln * out, y - ty * ln * 0.7 + ny * ln * out
            d.polygon([((x + tx * wd) * s, (y + ty * wd) * s), ((x - tx * wd) * s, (y - ty * wd) * s), (px_ * s, py_ * s)], fill=255)
        edge = Image.new("L", (S, S)); de = ImageDraw.Draw(edge)
        face = Image.new("L", (S, S)); df = ImageDraw.Draw(face)
        for k, t in enumerate([0.24 + 0.13 * i for i in range(6)]):
            x, y, tx, ty, nx, ny = fr[int(t * n)]; r = rad(t)
            for side in (1, -1):
                off = 0.0 if side == 1 else 0.06          # staggered on the two edges
                xx, yy, txx, tyy, nxx, nyy = fr[min(n, int((t + off) * n))]; rr = rad(t + off)
                spine(de, xx + nxx * rr * side * 0.7, yy + nyy * rr * side * 0.7, txx, tyy, nxx * side, nyy * side, rr * 1.5 + lw / s, rr * 0.42, 0.8)
            if k % 2 == 0 and t < 0.8:   # a thorn on the visible face
                spine(df, x - nx * r * 0.15, y - ny * r * 0.15, tx, ty, nx, ny, r * 1.0, r * 0.3, -0.25)
        under = Image.new("RGBA", (S, S), (0, 0, 0, 0))
        add_part(under, edge, Image.new("RGB", (S, S), (252, 222, 226)), max(5, int(lw * 0.45)))
        under.alpha_composite(layer)
        add_part(under, face, Image.new("RGB", (S, S), (252, 222, 226)), max(5, int(lw * 0.35)))
        layer.paste(under)
    return pts


def helix_penis(layer, s, axis, pw, R, turns, k0, lw, cols, taper=0.45):
    """corkscrew: a real helix around the axis path from fraction k0 on (straight before)."""
    fr = path_frame(axis); n = len(axis) - 1
    pts = []
    for i, (x, y, tx, ty, nx, ny) in enumerate(fr):
        t = i / n
        k = max(0.0, (t - k0) / (1 - k0))
        ramp = min(1.0, k * 4)
        ph = k * turns * 2 * math.pi
        rr = R * ramp * (1 - 0.3 * k)
        pts.append((x + nx * rr * math.sin(ph), y + ny * rr * math.sin(ph), rr * math.cos(ph)))
    sweep(layer, pts, lambda t: pw / 2 * (1 - taper * t), pen_colours(cols[0], cols[1]), s, lw)


# ---------- species ----------
def mammal(fold, name, W, kind, scrot=None, sh=None, L=0, ang=20, pw=5, cols=PINKC, skin=0.0, tuft=False, pouch=False, turns=3.0, drop=0.35, ang0=None, tipc=None):
    S, s = N * U, U * N / W
    b = belly_fn(fold, name)
    lw = 4.2 * U
    anchor = sh[0]
    fur = body_colour(W, fold, name, anchor, b(anchor), up=max(6, W // 40))
    canvas = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    body = Image.open(os.path.join(HC, fold, name + "_east.png")).convert("RGBA").getchannel("A").resize((S, S), Image.BILINEAR).point(lambda v: 255 if v > 128 else 0)
    if scrot:
        scrotum(canvas, s, b, scrot[0], scrot[1], scrot[2], fur, skin, lw, body)
    a = math.radians(ang)
    pen = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    tmp = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    start, a0 = sheath(tmp, s, b, sh[0], sh[1], sh[2], fur, lw, tuft, pouch, drop, body)
    if ang0 is not None:
        a0 = math.radians(ang0)
    if kind == "pig":
        tip = (start[0] + math.cos(a) * L, start[1] + math.sin(a) * L)
        axis = bezier([start, (start[0] + math.cos(a0) * L * 0.35, start[1] + math.sin(a0) * L * 0.35), (tip[0] - math.cos(a) * L * 0.3, tip[1] - math.sin(a) * L * 0.3), tip], 160)
        helix_penis(pen, s, axis, pw, pw * 0.95, turns, 0.45, lw, cols)
    else:
        straight_penis(pen, s, start, a0, L, a, pw, kind, lw, cols, tipc)
    canvas.alpha_composite(pen)
    canvas.alpha_composite(tmp)
    return finish(canvas)


def ratite(W, root, tip, pw, cols, coil=0.0):
    S, s = N * U, U * N / W
    lw = 4.2 * U
    L = math.dist(root, tip)
    p1 = (root[0] - L * 0.08, root[1] + L * 0.45)
    p2 = (root[0] + L * 0.1, root[1] + L * 0.9)
    pts = bezier([root, p1, p2, tip], 100)
    if coil:   # emu / cassowary: the tip curls back up
        e = pts[-1]
        pts += bezier([e, (e[0] + L * 0.12, e[1] + L * 0.02), (e[0] + L * 0.16 * coil, e[1] - L * 0.12 * coil)], 24)[1:]
    n = len(pts) - 1
    layer = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    rad = lambda t: pw / 2 * (1.08 - 0.5 * t ** 1.2 + 0.12 * math.exp(-(t / 0.08) ** 2))
    sweep(layer, [(x, y, 0) for x, y in pts], rad, pen_colours(cols[0], cols[1]), s, lw)
    # the sperm groove (sulcus) spiralling along the shaft
    fr = path_frame(pts); g = []
    for i in range(int(n * 0.12), n - 3):
        x, y, tx, ty, nx, ny = fr[i]; t = i / n
        o = rad(t) * 0.55 * math.sin(t * 1.3 * 2 * math.pi + 0.6)
        g.append((x + nx * o, y + ny * o))
    line_on(layer, g, s, max(3, pw * 0.11 * s), tuple(int(v * 0.74) for v in cols[0]), 9)
    c = Image.new("RGBA", (S, S), (0, 0, 0, 0)); c.alpha_composite(layer)
    return finish(c)


def duck(W, root, L, pw, cols):
    S, s = N * U, U * N / W
    lw = 4.2 * U
    axis = bezier([root, (root[0] - L * 0.1, root[1] + L * 0.45), (root[0] + L * 0.25, root[1] + L * 0.8), (root[0] + L * 0.7, root[1] + L * 0.85)], 220)
    layer = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    helix_penis(layer, s, axis, pw, pw * 0.7, 4.0, 0.08, lw, cols, taper=0.6)
    return finish(layer)


DUCKC = ((232, 156, 156), (140, 72, 82))
SPECS2 = {
    # felines: placed like the other carnivores (sheath under the abdomen, forward-down), barbed cone
    "Cat":      ("Cat", 256, dict(kind="feline", scrot=(68, 6, 0.4), sh=(76, 96, 8), L=19, ang=34, ang0=40, pw=10, skin=0.15)),
    "Lynx":     ("Lynx", 256, dict(kind="feline", scrot=(56, 5.5, 0.4), sh=(64, 84, 7.5), L=18, ang=34, ang0=40, pw=9.5, skin=0.15)),
    "Cougar":   ("Cougar", 384, dict(kind="feline", scrot=(128, 8, 0.4), sh=(138, 164, 11), L=27, ang=34, ang0=40, pw=14, skin=0.15)),
    "Bear":     ("Bear", 512, dict(kind="bear", scrot=(146, 11, 0.45), sh=(168, 222, 16), L=40, ang=30, pw=11)),
    "Raccoon":  ("Raccoon", 256, dict(kind="bear", scrot=(106, 6, 0.4), sh=(122, 148, 8), L=20, ang=38, pw=5.5)),
    # cervines: equine-shaped (even mottled shaft, soft preputial ring, wide flared glans), short sheath on
    # the originals' own spot, penis hanging down-forward from it
    "DeerMale": ("Deer", 333, dict(kind="equine", scrot=(100, 7, 0.45), sh=(108, 124, 12), L=40, ang=46, ang0=58, pw=10, drop=0.5, cols=EQUC, tipc=PINKT)),
    "ElkMale":  ("Elk", 384, dict(kind="equine", scrot=(108, 8, 0.45), sh=(116, 134, 13), L=44, ang=46, ang0=58, pw=11, drop=0.5, cols=EQUC, tipc=PINKT)),
    "Caribou":  ("Caribou", 512, dict(kind="equine", scrot=(168, 11, 0.45), sh=(180, 204, 17), L=56, ang=46, ang0=58, pw=14.5, drop=0.5, cols=EQUC, tipc=PINKT)),
    "Rhino":    ("Rhino", 512, dict(kind="rhino", sh=(128, 152, 22), L=140, ang=6, ang0=40, pw=18, drop=0.5, cols=((128, 122, 126), (52, 48, 52)), tipc=((214, 150, 152), (140, 84, 90)))),
    "Gazelle":  ("Gazelle", 256, dict(kind="cervid", scrot=(66, 7, 0.9), sh=(80, 108, 8), L=30, ang=24, pw=4.2, tuft=True)),
    "IbexMale": ("Ibex", 256, dict(kind="caprine", scrot=(58, 8, 1.3), sh=(70, 100, 8), L=30, ang=24, pw=4.6, tuft=True)),
    "YakMale":  ("Yak", 384, dict(kind="bovid", scrot=(92, 11, 1.1), sh=(116, 166, 13), L=48, ang=22, pw=7, tuft=True)),
    "Muffalo":  ("Muffalo", 512, dict(kind="bovid", scrot=(126, 14, 1.1), sh=(160, 222, 17), L=64, ang=22, pw=9, tuft=True)),
    "Boomalope": ("Boomalope", 256, dict(kind="bovid", scrot=(62, 8, 1.0), sh=(78, 110, 9), L=32, ang=22, pw=5, tuft=True)),
    "Alpaca":   ("Alpaca", 384, dict(kind="camelid", scrot=(88, 8, 0.35), sh=(140, 174, 10), L=36, ang=26, pw=5.2)),
    "Dromedary": ("Dromedary", 512, dict(kind="camelid", scrot=(80, 11, 0.35), sh=(168, 216, 14), L=50, ang=26, pw=7)),
    "Pig":      ("Pig", 384, dict(kind="pig", scrot=(54, 12, 0.6), sh=(150, 192, 12), L=72, ang=52, pw=6.4, skin=0.5, pouch=True, turns=2.6)),
    "WildBoar": ("WildBoar", 256, dict(kind="pig", scrot=(42, 9, 0.6), sh=(88, 118, 9), L=46, ang=52, pw=4.8, skin=0.25, pouch=True, turns=2.4)),
}
BIRDS = {
    "Cassowary": ("Cassowary", 256, lambda: ratite(256, (54, 180), (90, 234), 15, PINKC, coil=0.8)),
    "Emu":       ("Emu", 256, lambda: ratite(256, (56, 182), (98, 242), 15, PINKC, coil=1.0)),
    "Ostrich":   ("Ostrich", 384, lambda: ratite(384, (80, 272), (134, 356), 23, REDC)),
    "DuckMale":  ("Duck", 192, lambda: duck(192, (38, 140), 38, 7.5, DUCKC)),
}



# name: (folder under Things/Pawn/Animal, W of the HC body, family, kwargs). Points (x, y) in body px.
SPECS = {
    "Megasloth": ("Megasloth", 512, carnivore, dict(root=(210, 356), tip=(236, 376), bw=15, pw=8)),
    "Iguana":    ("Iguana", 256, faithful, dict()),
    "Cobra":     ("Cobra", 192, faithful, dict()),
    "Tortoise":  ("Tortoise", 256, faithful, dict()),
    "Megascarab": ("Megascarab", 256, faithful, dict()),
    "Megaspider": ("Megaspider", 512, faithful, dict()),
    "Spelopede": ("Spelopede", 384, faithful, dict()),
    "Thrumbo":   ("Thrumbo", 512, faithful, dict()),
}
NEEDS_FUR = {carnivore}


def build_generic(name):
    fold, W, fn, kw = SPECS[name]
    kw = dict(kw)
    if fn is faithful:
        kw["src"] = os.path.join(ZOO, fold, f"{name}_Lewd_east.png")
    if fn in NEEDS_FUR:
        anchor = kw.get("sf") or kw.get("root") or kw.get("sheath_at")
        c = body_colour(W, fold, name, anchor[0], anchor[1], up=max(6, W // 40))
        kw["fur"] = c
    return fn(W, **kw)


def main(only=None):
    jobs = [("Elephant", "Elephant", "Elephant", elephant), ("Cow", "Bull", "Bull", bull)]
    jobs += [(f, n, n, (lambda n=n: build_generic(n))) for n, (f, W, fn, kw) in SPECS.items()]
    jobs += [(f, n, n, (lambda f=f, n=n, W=W, kw=kw: mammal(f, n, W, **kw))) for n, (f, W, kw) in SPECS2.items()]
    jobs += [(f, n, n, fn) for n, (f, W, fn) in BIRDS.items()]
    if only:
        jobs = [j for j in jobs if j[1] in only]
    for fold, lewd, body, fn in jobs:
        od = os.path.join(OUT, fold); os.makedirs(od, exist_ok=True)
        fn().save(os.path.join(od, f"{lewd}_Lewd_east.png"))
        print("wrote", fold, lewd)
    review(jobs)


def review(jobs):
    """grid: for each animal the original and the new overlay under the HC body, close up."""
    cell = 220; cols = 4
    rows = (len(jobs) + cols - 1) // cols
    sheet = Image.new("RGBA", (cols * cell * 2 + 10, rows * (cell + 18)), (96, 104, 88, 255))
    d = ImageDraw.Draw(sheet)
    for i, (fold, lewd, body, _) in enumerate(jobs):
        b = Image.open(os.path.join(HC, fold, f"{body}_east.png")).convert("RGBA").resize((N, N), Image.LANCZOS)
        old = Image.open(os.path.join(ZOO, fold, f"{lewd}_Lewd_east.png")).convert("RGBA").resize((N, N), Image.BILINEAR)
        new = Image.open(os.path.join(OUT, fold, f"{lewd}_Lewd_east.png")).convert("RGBA")
        def under(o):
            c = Image.new("RGBA", (N, N), (0, 0, 0, 0)); c.alpha_composite(o); c.alpha_composite(b); return c
        bb = new.getchannel("A").getbbox()
        cx, cy = (bb[0] + bb[2]) // 2, (bb[1] + bb[3]) // 2 - 10
        sz = max(bb[2] - bb[0], bb[3] - bb[1]) // 2 + 70
        x = (i % cols) * (cell * 2 + 2); y = (i // cols) * (cell + 18)
        d.text((x + 4, y + 2), f"{lewd}: original | new", fill="white")
        for k, im in enumerate((under(old), under(new))):
            sheet.alpha_composite(im.crop((cx - sz, cy - sz, cx + sz, cy + sz)).resize((cell - 4, cell - 4), Image.LANCZOS), (x + k * cell, y + 16))
    sheet.save(os.path.join(ART, "Staging", "AnimalOverlays-review.png"))


if __name__ == "__main__":
    import sys
    main(sys.argv[1:])
