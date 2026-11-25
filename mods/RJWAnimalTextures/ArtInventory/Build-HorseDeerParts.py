"""Horse ears and tail, deer ears and antlers, drawn with Pillow in the same outlined style as
Build-DragonParts.py (whose helpers this reuses).

Horse ears: tall upright ears with an inner groove, high on the head. Gray mask, hair color.
Horse tail: a long flowing horsehair tail with strands and a ragged end. Gray mask, hair color.
  Fitted like the other tails (vanilla furry-tail offsets), in a box that hangs lower.
Deer ears: large oval ears sticking out sideways with a pale inner ear. Gray mask, hair color.
Deer antlers: a separate layer (untinted bone color in the gene): a beam per side with three tines.
All head pieces are drawn behind the head (gene layer 45) with their bases inside the head, so the
head's own outline covers them (same approach as the dragon ears).

Writes Staging/HorseDeer/{HorseEars,HorseTail,DeerEars}/... and Staging/HorseDeer-review.png.
Run: python -I Build-HorseDeerParts.py
"""
import importlib.util, math, os, random
from PIL import Image, ImageDraw, ImageFilter, ImageChops

ART = os.path.dirname(os.path.abspath(__file__))
spec = importlib.util.spec_from_file_location("dragon", os.path.join(ART, "Build-DragonParts.py"))
D = importlib.util.module_from_spec(spec); spec.loader.exec_module(D)
S, N, SS, bez, finish, ear, horn, tint, fit = D.S, D.N, D.SS, D.bez, D.finish, D.ear, D.horn, D.tint, D.fit
OUT = os.path.join(ART, "Staging", "HorseDeer")


def mirror_pair(m, g):
    m2, g2 = m.transpose(Image.FLIP_LEFT_RIGHT), g.transpose(Image.FLIP_LEFT_RIGHT)
    mm = ImageChops.lighter(m, m2)
    gg = Image.new("L", (N, N), 0); gg.paste(g, mask=m); gg.paste(g2, mask=m2)
    return mm, gg


def combine(pieces):
    """pieces: list of (mask, gray), drawn in order, each with its own outline."""
    out = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
    for m, g in pieces:
        out.alpha_composite(finish(m, g))
    return out


# ---------------------------------------------------------------- horse
def horse_ears(direction):
    if direction in ("south", "north"):
        m, g = ear((298, 214), h=134, w=44, lean=10.0, curl=0.12, front=direction == "south", notches=0, groove_val=160, ridges=False)
        return combine([mirror_pair(m, g)])
    m, g = ear((230, 214), h=136, w=46, lean=-16.0, curl=-0.12, front=True, notches=0, groove_val=160, ridges=False)
    return combine([(m, g)])


def horse_tail_east():
    P = [(440, 190), (380, 110), (250, 200), (190, 470)]
    K = 400
    pts = [bez(P, i / K) for i in range(K + 1)]
    nrm = []
    for i in range(K + 1):
        a, b = pts[max(0, i - 1)], pts[min(K, i + 1)]
        dx, dy = b[0] - a[0], b[1] - a[1]; L = math.hypot(dx, dy) or 1
        nrm.append((-dy / L, dx / L))
    def width(t):
        # narrow dock at the base, flaring into a full fall of hair toward the end
        return 26 + 96 * (math.sin(min(1.0, t / 0.8) * math.pi / 2) ** 1.4) - 14 * max(0.0, t - 0.85) / 0.15
    up = nrm
    A = [(p[0] + n[0] * width(i / K) / 2, p[1] + n[1] * width(i / K) / 2) for i, (p, n) in enumerate(zip(pts, up))]
    B = [(p[0] - n[0] * width(i / K) / 2, p[1] - n[1] * width(i / K) / 2) for i, (p, n) in enumerate(zip(pts, up))]
    # ragged end: points of hair locks fanning past the end
    tp = pts[-1]; tq = pts[-15]; fx, fy = tp[0] - tq[0], tp[1] - tq[1]; L = math.hypot(fx, fy); fx, fy = fx / L, fy / L
    nx, ny = -fy, fx
    w_end = width(1) / 2
    end = []
    locks = 5
    for j in range(locks * 2 + 1):
        f = 1 - 2 * j / (locks * 2)
        reach = (26 + 10 * math.sin(j * 1.7)) if j % 2 == 0 else -4
        end.append((tp[0] + nx * w_end * f + fx * reach, tp[1] + ny * w_end * f + fy * reach))
    poly = A + end + B[::-1]
    mask = Image.new("L", (N, N), 0); md = ImageDraw.Draw(mask)
    md.polygon([S(q) for q in poly], fill=255)
    r0 = width(0) / 2; md.ellipse([S((pts[0][0] - r0, pts[0][1] - r0)), S((pts[0][0] + r0, pts[0][1] + r0))], fill=255)
    gray = Image.new("L", (N, N), 206)
    gd = ImageDraw.Draw(gray)
    def band(f0, f1, val):
        a = [(p[0] + n[0] * width(i / K) / 2 * f0, p[1] + n[1] * width(i / K) / 2 * f0) for i, (p, n) in enumerate(zip(pts, up))]
        b = [(p[0] + n[0] * width(i / K) / 2 * f1, p[1] + n[1] * width(i / K) / 2 * f1) for i, (p, n) in enumerate(zip(pts, up))]
        gd.polygon([S(q) for q in a + b[::-1]], fill=val)
    band(1.4, 0.45, 232)
    band(-0.35, -1.4, 168)
    gray = gray.filter(ImageFilter.GaussianBlur(SS * 1.5))
    # strands: wavy lines along the tail, darker, a few light ones
    rnd = random.Random(11)
    sd = ImageDraw.Draw(gray)
    for k in range(9):
        f = -0.8 + 1.6 * k / 8 + rnd.uniform(-0.06, 0.06)
        ph = rnd.uniform(0, 6.28)
        line = []
        for i in range(int(K * 0.08), K + 1, 4):
            t = i / K; p, n = pts[i], up[i]; w = width(t) / 2
            ff = f + 0.10 * math.sin(t * 11 + ph) * min(1.0, t * 2)
            line.append(S((p[0] + n[0] * w * ff, p[1] + n[1] * w * ff)))
        sd.line(line, fill=(150 if k % 3 else 240), width=int((2.2 if k % 3 else 2.6) * SS), joint="curve")
    return finish(mask, gray)


# ---------------------------------------------------------------- deer
def antler_side(base, flip=False, scale=1.0):
    """One antler: a beam rising up and out from base, with three tines toward the top/inside.
    Built for the right side of the screen; flip mirrors x about 256."""
    bx, by = base
    s = scale
    # beam sweeps out to the side, then up and slightly back in
    # beam sweeps outward and up; tines rise from its top at intervals (candelabra)
    beam = [(bx, by + 30 * s), (bx + 34 * s, by - 26 * s), (bx + 92 * s, by - 52 * s), (bx + 128 * s, by - 96 * s)]
    pieces = [horn(beam, w0=26 * s, rings=0)]
    for t, dx, dy, ln in ((0.34, -8, -62, 1.0), (0.60, -2, -70, 1.0), (0.82, 8, -54, 0.9)):
        p = bez(beam, t)
        # gentle curve: bows outward first, tip leaning back in
        tine = [p, (p[0] + 16 * s, p[1] + dy * 0.35 * s), (p[0] + (dx + 12) * s, p[1] + dy * 0.78 * s), (p[0] + dx * s, p[1] + dy * s * ln * 1.1)]
        pieces.append(horn(tine, w0=15 * s, rings=0))
    m = Image.new("L", (N, N), 0); g = Image.new("L", (N, N), 0)
    for pm, pg in pieces:
        g.paste(pg, mask=pm); m = ImageChops.lighter(m, pm)
    # bark ridges: short dark strokes along the beam
    rd = ImageDraw.Draw(g)
    rnd = random.Random(5)
    for k in range(10):
        t = rnd.uniform(0.15, 0.95); p = bez(beam, t); q = bez(beam, min(1, t + 0.03))
        rd.line([S(p), S(q)], fill=112, width=int(2 * SS))
    g = g.point(lambda v: min(255, int(60 + v * 0.95)))   # lighter bone, before the bone tint
    g = Image.composite(g, Image.new("L", (N, N), 0), m)
    if flip:
        m, g = m.transpose(Image.FLIP_LEFT_RIGHT), g.transpose(Image.FLIP_LEFT_RIGHT)
    return m, g


def deer_ears(direction):
    if direction in ("south", "north"):
        m, g = ear((330, 228), h=92, w=58, lean=72.0, curl=0.06, front=direction == "south", notches=0, groove_val=238, ridges=False)
        return combine([mirror_pair(m, g)])
    m, g = ear((206, 238), h=94, w=60, lean=-66.0, curl=-0.06, front=True, notches=0, groove_val=238, ridges=False)
    return combine([(m, g)])


def deer_antlers(direction):
    if direction in ("south", "north"):
        r = antler_side((280, 206), scale=0.82)
        l = antler_side((280, 206), flip=True, scale=0.82)
        return combine([l, r])
    # side view: one antler, beam rising up and slightly back
    m, g = antler_side((246, 202), scale=0.82)
    m, g = m.transpose(Image.FLIP_LEFT_RIGHT), g.transpose(Image.FLIP_LEFT_RIGHT)   # sweep toward the back (screen left)
    shift = Image.new("L", (N, N), 0)
    # move it back over the crown: the flipped antler is centered on x = 512 - 246
    off = int((246 - (512 - 246)) * SS) - int(14 * SS)
    m2 = ImageChops.offset(m, off, 0); g2 = ImageChops.offset(g, off, 0)
    return combine([(m2, g2)])


HORSE_TAIL_BOX = {"east": (60, 130, 456, 474), "south": (14, 140, 300, 474), "north": (212, 120, 498, 454)}


def main():
    for d in ("HorseEars", "HorseTail", "DeerEars"):
        os.makedirs(os.path.join(OUT, d), exist_ok=True)
    he = {d: horse_ears(d) for d in ("south", "east", "north")}
    t = horse_tail_east()
    ht = {"east": fit(t, HORSE_TAIL_BOX["east"]), "south": fit(t, HORSE_TAIL_BOX["south"]), "north": fit(t, HORSE_TAIL_BOX["north"], mirror=True)}
    de = {d: deer_ears(d) for d in ("south", "east", "north")}
    da = {d: deer_antlers(d) for d in ("south", "east", "north")}
    for d in ("south", "east", "north"):
        he[d].save(os.path.join(OUT, "HorseEars", f"HorseEars_{d}.png"))
        ht[d].save(os.path.join(OUT, "HorseTail", f"HorseTail_{d}.png"))
        de[d].save(os.path.join(OUT, "DeerEars", f"DeerEars_{d}.png"))
        da[d].save(os.path.join(OUT, "DeerEars", f"DeerAntlers_{d}.png"))
    review(he, ht, de, da)


def review(he, ht, de, da):
    HA = r"C:\Program Files (x86)\Steam\steamapps\common\RimWorld\Mods\sized-apparel-heads\Textures\Things\Pawn\Humanlike\Heads\Female\Female_"
    skin = (238, 200, 170)
    heads = {(h, d): tint(Image.open(HA + f"{h}_Normal_{d}.png").convert("RGBA").resize((512, 512)), skin) for h in ("Average", "Narrow") for d in ("south", "east", "north")}
    def tile(h, d, layers):
        t = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
        for im, col in layers:
            e = tint(im, col)
            if h == "Narrow":
                w = int(512 * 1.3 / 1.5); e2 = Image.new("RGBA", (512, 512), (0, 0, 0, 0)); e2.alpha_composite(e.resize((w, 512), Image.LANCZOS), ((512 - w) // 2, 0)); e = e2
            t.alpha_composite(e)
        t.alpha_composite(heads[(h, d)])
        return t
    brown, blond, black = (150, 98, 58), (214, 170, 100), (70, 60, 56)
    bone = (226, 204, 168)
    rows = [
        ("horse ears, brown", [tile(h, d, [(he[d], brown)]) for h in ("Average", "Narrow") for d in ("south", "east", "north")]),
        ("horse ears, black", [tile(h, d, [(he[d], black)]) for h in ("Average", "Narrow") for d in ("south", "east", "north")]),
        ("deer ears + antlers", [tile(h, d, [(da[d], bone), (de[d], brown)]) for h in ("Average", "Narrow") for d in ("south", "east", "north")]),
        ("deer, blond", [tile(h, d, [(da[d], bone), (de[d], blond)]) for h in ("Average", "Narrow") for d in ("south", "east", "north")]),
        ("horse tail brown / black", [tint(ht[d], brown) for d in ("south", "east", "north")] + [tint(ht[d], black) for d in ("south", "east", "north")]),
    ]
    cell = 210
    sheet = Image.new("RGBA", (170 + cell * 6, 24 + cell * len(rows)), (150, 120, 90, 255))
    dr = ImageDraw.Draw(sheet)
    for r, (label, tiles) in enumerate(rows):
        dr.text((4, 24 + r * cell + 95), label, fill="white")
        for c, t in enumerate(tiles):
            sheet.alpha_composite(t.resize((cell, cell), Image.LANCZOS), (170 + c * cell, 24 + r * cell))
    for c, lab in enumerate(["avg front", "avg side", "avg back", "narrow front", "narrow side", "narrow back"]):
        dr.text((170 + c * cell + 60, 4), lab, fill="white")
    sheet.save(os.path.join(ART, "Staging", "HorseDeer-review.png"))


if __name__ == "__main__":
    main()
