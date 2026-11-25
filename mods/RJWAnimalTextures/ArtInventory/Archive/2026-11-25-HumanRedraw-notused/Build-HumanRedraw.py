"""New art for Sized Apparel's human penis and balls (prototype on a sample).

Keeps from SA's picture only what placement depends on: the footprint (silhouette, pose, position on the
512 canvas) and which part is glans, skin or crease. Everything inside is painted anew at 4x:
  - volume: each region (skin, glans) gets a height field from its distance to its own edge, lit from
    the upper left (lambert + ambient), so the shaft reads as a tube, the glans and testicles as domes;
  - glans: its own colour, a specular highlight, a darker corona where it meets the skin;
  - creases (foreskin edge, scrotal seam, veins): SA's interior lines redrawn thin and soft;
  - outline: one even dark line around the silhouette (thinner than SA's), no outline across the
    soft fade where the picture meets the body;
  - colours stay light and near-neutral because Sized Apparel multiplies them by the skin colour.
Writes Staging/HumanRedraw/{Penis,Horny,Balls}/<same names> and Staging/HumanRedraw-review.png.
Run: python -I Build-HumanRedraw.py [all | sub/name ...]   (no argument: the 8-slot sample)
"""
import math, os, sys
from PIL import Image, ImageChops, ImageDraw, ImageFilter

SA = r"C:\Program Files (x86)\Steam\steamapps\common\RimWorld\Mods\sized-apparel-zero\Textures\SizedApparel\BodyParts\Human\Penis"
ART = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(ART, "Staging", "HumanRedraw")
U = 4
SAMPLE = ["Penis_3_south", "Penis_3_east", "Horny/Penis_3_south", "Horny/Penis_3_east", "Horny/Penis_5_east",
          "Horny/Penis_4_Foreskin_east", "Balls/Penis_3_south", "Balls/Penis_3_east"]
SKIN, SKIN_DARK = (250, 244, 240), (196, 172, 170)
GLANS, GLANS_DARK = (236, 128, 130), (170, 70, 80)
LINE = (34, 26, 28)
L = (-0.45, -0.65, 0.62)
LN = math.sqrt(sum(c * c for c in L)); L = tuple(c / LN for c in L)
H = (L[0], L[1], L[2] + 1); HN = math.sqrt(sum(c * c for c in H)); H = tuple(c / HN for c in H)


def regions(im):
    """silhouette, glans, crease masks at the original size."""
    px = im.load(); w, h = im.size
    sil = Image.new("L", im.size); gl = Image.new("L", im.size); dk = Image.new("L", im.size)
    sp, gp, dp = sil.load(), gl.load(), dk.load()
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a < 60:
                continue
            sp[x, y] = 255
            l = (r * 299 + g * 587 + b * 114) // 1000
            if l < 95:
                dp[x, y] = 255
            elif r > g + 28 and r > b + 18:
                gp[x, y] = 255
    return sil, gl, dk


def up(m, blur):
    big = m.resize((m.width * U, m.height * U), Image.LANCZOS).filter(ImageFilter.GaussianBlur(blur))
    return big.point(lambda v: 255 if v >= 128 else 0)


def distance(mask):
    """chamfer distance (px) to the mask's outside, as a list of rows."""
    w, h = mask.size; mp = mask.load(); INF = 10 ** 6
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
    return [[min(v, INF) / 3.0 for v in row] for row in d]


def heightfield(mask):
    """dome-shaped height (0-255 L image) from the distance to the edge, scaled per region."""
    d = distance(mask)
    dmax = max(max(r) for r in d) or 1
    R = dmax * 1.05
    img = Image.new("L", mask.size); p = img.load()
    for y, row in enumerate(d):
        for x, v in enumerate(row):
            if v:
                t = min(v / R, 1.0)
                p[x, y] = int(255 * math.sqrt(1 - (1 - t) ** 2))
    return img.filter(ImageFilter.GaussianBlur(U * 1.5)), dmax


def shade(hf, mask, base, dark, spec, scale):
    """lit colour image from a height field."""
    w, h = hf.size; hp = hf.load(); mp = mask.load()
    out = Image.new("RGB", hf.size); op = out.load()
    k = 255.0 / scale
    for y in range(1, h - 1):
        for x in range(1, w - 1):
            if mp[x, y] < 8:
                continue
            nx = -(hp[x + 1, y] - hp[x - 1, y]) / (2 * k)
            ny = -(hp[x, y + 1] - hp[x, y - 1]) / (2 * k)
            n = math.sqrt(nx * nx + ny * ny + 1)
            nx, ny, nz = nx / n, ny / n, 1 / n
            lam = max(0.0, nx * L[0] + ny * L[1] + nz * L[2])
            s = 0.35 + 0.65 * lam
            c = [dark[i] + (base[i] - dark[i]) * min(s * 1.12, 1.0) for i in range(3)]
            if spec:
                sp = max(0.0, nx * H[0] + ny * H[1] + nz * H[2]) ** 28 * spec
                c = [ci + (255 - ci) * sp for ci in c]
            op[x, y] = tuple(int(min(255, ci)) for ci in c)
    return out


def largest_part(m):
    """keep the largest connected white area of a 0/255 mask."""
    w, h = m.size
    work = m.copy(); px = work.load()
    best, best_n, tag = None, 0, 1
    for y in range(0, h, 2):
        for x in range(0, w, 2):
            if px[x, y] == 255:
                ImageDraw.floodfill(work, (x, y), tag)
                n = work.histogram()[tag]
                if n > best_n:
                    best, best_n = tag, n
                tag += 1
                if tag == 255:
                    break
        if tag == 255:
            break
    if best is None:
        return m
    return work.point(lambda v: 255 if v == best else 0)


def redraw(im, is_balls=False, south=False, horny=False):
    if im.width < 64 or im.getchannel("A").getbbox() is None:
        return im.copy()
    bb = im.getchannel("A").getbbox()
    pad = 6
    box = (max(0, bb[0] - pad), max(0, bb[1] - pad), min(im.width, bb[2] + pad), min(im.height, bb[3] + pad))
    src = im.crop(box)
    sil, gl, dk = regions(src)
    S = up(sil, U * 0.9)
    inner = S.filter(ImageFilter.MinFilter(U * 2 + 1))
    # glans: SA's pink grown over the thin dark line that rims it, then smoothed into one rounded shape
    # (closing fills notches, opening removes spurs, a wide blur + threshold rounds the contour)
    G = up(gl, U * 1.0).filter(ImageFilter.MaxFilter((U + 1) | 1))
    k = U * 3 + 1
    G = G.filter(ImageFilter.MaxFilter(k)).filter(ImageFilter.MinFilter(k))
    G = G.filter(ImageFilter.MinFilter((U + 1) | 1)).filter(ImageFilter.MaxFilter((U + 1) | 1))
    G = ImageChops.multiply(G.filter(ImageFilter.GaussianBlur(U * 2.2)).point(lambda v: 255 if v >= 128 else 0), S)
    G = ImageChops.multiply(G, S.filter(ImageFilter.MinFilter(U * 2 + 1)).filter(ImageFilter.MaxFilter(U * 2 + 1)))
    G = largest_part(G)   # a rolled-back foreskin ring (pink in SA) becomes skin; the glans stays one shape
    # creases: SA's interior lines away from the outline and the glans, thinned
    # (only the outer ~3 px are the outline; dark lines further in, like the foreskin pucker at the tip, are creases)
    D = up(ImageChops.multiply(dk, sil.filter(ImageFilter.MinFilter(5))), U * 0.6)
    crease = ImageChops.subtract(D, G.filter(ImageFilter.MaxFilter(U * 2 + 1))).filter(ImageFilter.MinFilter(3))
    skin = ImageChops.subtract(S, G)
    luma = src.convert("L")
    local = luma.filter(ImageFilter.GaussianBlur(2.5))
    vein0 = ImageChops.subtract(local, luma).point(lambda v: 255 if v > 9 else 0)
    vein0 = ImageChops.multiply(vein0, ImageChops.subtract(sil, ImageChops.lighter(dk, gl.filter(ImageFilter.MaxFilter(3)))))
    vein = ImageChops.multiply(up(vein0, U * 0.7).filter(ImageFilter.MinFilter(3)), inner)
    vein = ImageChops.subtract(vein, G.filter(ImageFilter.MaxFilter(U * 2 + 1)))
    lobes = ImageChops.subtract(skin, crease.filter(ImageFilter.MaxFilter(U + 1)))
    if is_balls and south:
        # two testicles: split the scrotum down the middle (the raphe) below SA's seam
        cx = S.getbbox(); cx = (cx[0] + cx[2]) // 2
        sb = S.getbbox()
        y0 = sb[1] + (sb[3] - sb[1]) * 45 // 100
        raphe = Image.new("L", S.size); ImageDraw.Draw(raphe).line([(cx, y0), (cx, S.height)], fill=255, width=U + 2)
        raphe = ImageChops.multiply(raphe, inner)
        crease = ImageChops.lighter(crease, raphe.filter(ImageFilter.GaussianBlur(U * 0.5)))
        lobes = ImageChops.subtract(lobes, raphe.filter(ImageFilter.MaxFilter(U * 2 + 1)))
    hs, ds = heightfield(lobes)
    col = shade(hs, skin, SKIN, SKIN_DARK, 0.3 if is_balls else 0.2, max(ds, 1) * 0.9)
    if G.getbbox():
        hg, dg = heightfield(G)
        cg = shade(hg, G, GLANS, GLANS_DARK, 0.9, max(dg, 1) * 0.9)
        col = Image.composite(cg, col, G.filter(ImageFilter.GaussianBlur(U * 0.3)))
        # corona: a crisp darker line on the glans edge where it meets the skin
        rim = ImageChops.multiply(ImageChops.subtract(G, G.filter(ImageFilter.MinFilter(U + 1))), skin.filter(ImageFilter.MaxFilter(U * 2 + 1)))
        col = Image.composite(Image.new("RGB", col.size, (120, 50, 58)), col, rim.filter(ImageFilter.GaussianBlur(U * 0.35)))
    if vein.getbbox():
        # raised veins: a soft shadow line with a light edge toward the light
        v = vein.filter(ImageFilter.GaussianBlur(U * 0.5))
        lit = ImageChops.offset(v, -U // 2, -U // 2)
        col = Image.composite(Image.new("RGB", col.size, (255, 252, 250)), col, ImageChops.multiply(lit, skin).point(lambda x: x * 2 // 5))
        col = Image.composite(Image.new("RGB", col.size, (176, 146, 150)), col, ImageChops.multiply(v, skin).point(lambda x: x * 3 // 5))
    if G.getbbox() and horny and south:
        # urethral slit at the top of the glans (aroused front views)
        gb = G.getbbox(); gx = (gb[0] + gb[2]) // 2
        sl = Image.new("L", G.size)
        ImageDraw.Draw(sl).line([(gx, gb[1] + U * 2), (gx, gb[1] + max(U * 3, (gb[3] - gb[1]) // 4))], fill=255, width=max(2, U // 2 + 1))
        col = Image.composite(Image.new("RGB", col.size, (110, 40, 50)), col, ImageChops.multiply(sl, G).filter(ImageFilter.GaussianBlur(U * 0.3)))
    col = Image.composite(Image.new("RGB", col.size, (92, 66, 70)), col, crease.filter(ImageFilter.GaussianBlur(U * 0.45)))
    # alpha and outline: the outline follows the silhouette except across the soft body fade
    a_src = src.getchannel("A").resize(S.size, Image.BICUBIC).filter(ImageFilter.GaussianBlur(U * 0.8))
    near_line = up(dk, U * 0.9).filter(ImageFilter.MaxFilter(U * 4 + 1)).filter(ImageFilter.GaussianBlur(U * 2))
    gate = near_line.point(lambda v: 255 if v > 60 else v * 255 // 60)
    band = ImageChops.subtract(S, S.filter(ImageFilter.MinFilter(U * 6 + 1)))   # about 3 px at 512, like SA's
    line = ImageChops.multiply(band, gate)
    col = Image.composite(Image.new("RGB", col.size, LINE), col, line.filter(ImageFilter.GaussianBlur(U * 0.4)))
    alpha = ImageChops.lighter(ImageChops.multiply(S, gate), a_src)
    alpha = ImageChops.multiply(alpha, S.filter(ImageFilter.GaussianBlur(U * 0.5)))
    piece = Image.merge("RGBA", (*col.split(), alpha)).resize(src.size, Image.LANCZOS)
    out = Image.new("RGBA", im.size, (0, 0, 0, 0))
    out.paste(piece, box[:2])
    return out


def all_names():
    for sub in ("", "Horny", "Balls"):
        for f in sorted(os.listdir(os.path.join(SA, sub))):
            if f.startswith("Penis_") and f.endswith(".png"):
                yield (sub + "/" if sub else "") + f


def main(names):
    pairs = []
    if names == ["all"]:
        names = list(all_names())
    for n in names or SAMPLE:
        sub, f = n.split("/", 1) if "/" in n else ("", n)
        f = f if f.endswith(".png") else f + ".png"
        im = Image.open(os.path.join(SA, sub, f)).convert("RGBA")
        new = redraw(im, sub == "Balls", f.endswith(("_south.png", "_north.png")), sub == "Horny")
        od = os.path.join(OUT, sub or "Penis"); os.makedirs(od, exist_ok=True)
        new.save(os.path.join(od, f))
        pairs.append((sub, f, im, new))
    print("files", len(pairs))
    review([p for p in pairs if p[2].width >= 64 and 'north' not in p[1]][:8])


def review(pairs):
    tints = [(236, 196, 168), (150, 104, 78)]
    def t(im, tint):
        r, g, b, a = im.split()
        return Image.merge("RGBA", (r.point(lambda v: v * tint[0] // 255), g.point(lambda v: v * tint[1] // 255), b.point(lambda v: v * tint[2] // 255), a))
    cell = 160
    rows = [("SA", 0, 0), ("new", 1, 0), ("SA dark", 0, 1), ("new dark", 1, 1)]
    sheet = Image.new("RGBA", (70 + cell * len(pairs), 20 + cell * len(rows) + cell), (70, 70, 70, 255))
    d = ImageDraw.Draw(sheet)
    for i, (sub, f, a, b) in enumerate(pairs):
        d.text((70 + i * cell + 3, 4), (sub or "rest") + " " + f[6:-4], fill="white")
        bb = a.getchannel("A").getbbox(); cx, cy = (bb[0] + bb[2]) // 2, (bb[1] + bb[3]) // 2
        s = max(bb[2] - bb[0], bb[3] - bb[1]) // 2 + 8
        for r, (lab, k, ti) in enumerate(rows):
            tile = Image.new("RGBA", (512, 512), (120, 100, 80, 255) if ti == 0 else (190, 170, 150, 255))
            tile.alpha_composite(t((a, b)[k], tints[ti]))
            sheet.alpha_composite(tile.crop((cx - s, cy - s, cx + s, cy + s)).resize((cell - 6, cell - 6), Image.LANCZOS), (70 + i * cell + 3, 20 + r * cell))
            if i == 0:
                d.text((4, 20 + r * cell + 70), lab, fill="white")
        # game scale: whole 512 canvas at 96 px (roughly a pawn on screen at a close zoom)
        for k in (0, 1):
            tile = Image.new("RGBA", (512, 512), (120, 100, 80, 255)); tile.alpha_composite(t((a, b)[k], tints[0]))
            g = tile.crop((128, 128, 384, 384)).resize((64, 64), Image.LANCZOS)
            sheet.alpha_composite(g, (70 + i * cell + 10 + k * 72, 20 + len(rows) * cell + 40))
    d.text((4, 20 + len(rows) * cell + 60), "game\nscale\nSA|new", fill="white")
    sheet.save(os.path.join(ART, "Staging", "HumanRedraw-review.png"))


if __name__ == "__main__":
    main(sys.argv[1:])
