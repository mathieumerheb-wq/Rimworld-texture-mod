# WolfPenis aroused cleanup, south and east, all sizes. Two artifacts from the source pictures:
#  1. Gloss highlights on the red shaft became gray or blue-gray specks, because the gray-fur pass
#     turned every low-saturation pixel into the skin mask, including the white shine on the shaft.
#     A gray pixel whose neighborhood is mostly red shaft (and not the gray sheath or scrotum) is
#     recolored to the surrounding red, lightened at most 10% toward white, so it reads as faint shine.
#     (2026-11-12: a 55% cap still left white-looking dots on the side views at sizes 4 and 5.)
#  2. A light fringe outside the black outline, left from the reference's white page. A light,
#     unsaturated pixel that touches transparency and has a clearly darker outline pixel within 2 px is cleared.
#     The size 5 side view uses 4 px: 2 px left a white chunk outside its sheath outline. 4 px on the
#     other sprites bites notches into the pale scrotum and sheath edges, so it is not used there.
# Reads the live Horny sprites. Writes only to Staging/WolfCleanup, plus a review sheet.
param([string[]]$Files)
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = "Stop"

Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

public static class WolfClean
{
    static int W, H;
    static byte[] P;

    static int A(int x, int y) { return P[(y * W + x) * 4 + 3]; }
    static int Luma(int i) { return (P[i + 2] * 299 + P[i + 1] * 587 + P[i] * 114) / 1000; }
    static int Sat(int i) { int mx = Math.Max(P[i], Math.Max(P[i + 1], P[i + 2])); int mn = Math.Min(P[i], Math.Min(P[i + 1], P[i + 2])); return mx - mn; }
    static bool Red(int i) { return P[i + 3] > 128 && P[i + 2] > P[i + 1] + 35 && P[i + 2] > P[i] + 25; }
    // Shaft red at its usual brightness and saturation (green at most 64% of red); paler or grayer pink
    // is shine that may be a speck.
    static bool Shaft(int i) { return Red(i) && Luma(i) < 165 && (P[i + 2] - P[i + 1]) * 100 >= P[i + 2] * 36; }
    static bool Gray(int i) { return P[i + 3] > 16 && Sat(i) < 32; }

    public static string Clean(string src, string dest, int edgeReach)
    {
        int specks = 0, fringe = 0;
        using (var b = new Bitmap(src))
        {
            W = b.Width; H = b.Height;
            if (W < 64) { b.Save(dest, ImageFormat.Png); return "blank"; }
            var d = b.LockBits(new Rectangle(0, 0, W, H), ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
            P = new byte[W * H * 4]; Marshal.Copy(d.Scan0, P, 0, P.Length); b.UnlockBits(d);
        }
        for (int pass = 0; pass < 3; pass++)
        {
            byte[] next = (byte[])P.Clone();
            for (int y = 3; y < H - 3; y++)
            for (int x = 3; x < W - 3; x++)
            {
                int i = (y * W + x) * 4;
                // Any pale, not-red pixel on the shaft: gray specks and the pale pink left by lightening.
                // Dark outline strokes (luma < 90) stay as drawn.
                if (Shaft(i) || (Sat(i) > 80 && Luma(i) < 165) || P[i + 3] < 64 || Luma(i) < 90) continue;
                int red = 0, gray = 0, opaque = 0; long sr = 0, sg = 0, sb = 0;
                for (int dy = -3; dy <= 3; dy++)
                for (int dx = -3; dx <= 3; dx++)
                {
                    int j = ((y + dy) * W + x + dx) * 4;
                    if (P[j + 3] < 64) continue;
                    opaque++;
                    if (Red(j) && Luma(j) < 175) { red++; sr += P[j + 2]; sg += P[j + 1]; sb += P[j]; }
                    else if (Gray(j) && Luma(j) > 60) gray++;
                }
                if (red < 8 || red * 10 < opaque * 5 || gray * 10 > opaque * 4) continue;
                double mr = sr / (double)red, mg = sg / (double)red, mb = sb / (double)red;
                double ml = (mr * 299 + mg * 587 + mb * 114) / 1000.0;
                int l = Luma(i);
                double nr, ng, nb;
                if (l >= ml)
                {
                    double t = Math.Min(0.10, (l - ml) / Math.Max(1.0, 255 - ml)); // faint shine only; more reads as a white speck
                    nr = mr + (255 - mr) * t; ng = mg + (255 - mg) * t; nb = mb + (255 - mb) * t;
                }
                else
                {
                    double f = Math.Max(0.35, l / Math.Max(1.0, ml));
                    nr = mr * f; ng = mg * f; nb = mb * f;
                }
                next[i + 2] = (byte)Math.Round(nr); next[i + 1] = (byte)Math.Round(ng); next[i] = (byte)Math.Round(nb);
                specks++;
            }
            P = next;
        }
        for (int pass = 0; pass < 5; pass++)
        {
            byte[] next = (byte[])P.Clone();
            for (int y = 4; y < H - 4; y++)
            for (int x = 4; x < W - 4; x++)
            {
                int i = (y * W + x) * 4;
                if (P[i + 3] == 0 || Luma(i) < 140 || Sat(i) > 40) continue;
                int l = Luma(i);
                // Opaque light pixel: must touch transparency and have the outline within edgeReach px (2, or 4 where listed below).
                // Partly transparent light pixel (the white page's soft edge): outline within 4 px.
                bool soft = P[i + 3] < 235 && l > 170;
                // Opaque pixels only in the first edgeReach passes: the page fringe is at most that deep,
                // and more passes bite notches where the outline has gaps (scrotum-shaft joint).
                if (!soft && pass >= edgeReach) continue;
                int reach = soft ? Math.Max(4, edgeReach) : edgeReach;
                bool edge = soft, dark = false;
                for (int dy = -reach; dy <= reach; dy++)
                for (int dx = -reach; dx <= reach; dx++)
                {
                    int j = ((y + dy) * W + x + dx) * 4;
                    if (Math.Abs(dx) <= 1 && Math.Abs(dy) <= 1 && P[j + 3] < 16) edge = true;
                    if (P[j + 3] > 128 && Luma(j) < Math.Min(135, l - 55)) dark = true;
                }
                if (!edge || !dark) continue;
                next[i + 3] = 0;
                fringe++;
            }
            P = next;
        }
        // Detached bits left from the page: any visible group of fewer than 40 pixels not joined to the organ.
        {
            int N = W * H; int[] lab = new int[N]; var st = new System.Collections.Generic.Stack<int>(); var members = new System.Collections.Generic.List<int>();
            for (int s0 = 0; s0 < N; s0++)
            {
                if (lab[s0] != 0 || P[s0 * 4 + 3] <= 16) continue;
                members.Clear(); lab[s0] = 1; st.Push(s0);
                while (st.Count > 0)
                {
                    int p = st.Pop(); members.Add(p); int px = p % W, py = p / W;
                    for (int dy = -1; dy <= 1; dy++) for (int dx = -1; dx <= 1; dx++)
                    {
                        int qx = px + dx, qy = py + dy; if (qx < 0 || qy < 0 || qx >= W || qy >= H) continue;
                        int q = qy * W + qx; if (lab[q] != 0 || P[q * 4 + 3] <= 16) continue;
                        lab[q] = 1; st.Push(q);
                    }
                }
                if (members.Count < 40) foreach (int p in members) { P[p * 4 + 3] = 0; fringe++; }
            }
        }
        // Stray dots left from the page: a pixel with at most 2 visible neighbors is cleared.
        for (int pass = 0; pass < 2; pass++)
        {
            byte[] next = (byte[])P.Clone();
            for (int y = 1; y < H - 1; y++)
            for (int x = 1; x < W - 1; x++)
            {
                int i = (y * W + x) * 4;
                if (P[i + 3] == 0) continue;
                int n = 0;
                for (int dy = -1; dy <= 1; dy++)
                for (int dx = -1; dx <= 1; dx++)
                    if ((dx != 0 || dy != 0) && A(x + dx, y + dy) > 16) n++;
                if (n > 2) continue;
                next[i + 3] = 0;
                fringe++;
            }
            P = next;
        }
        using (var o = new Bitmap(W, H, PixelFormat.Format32bppArgb))
        {
            var d = o.LockBits(new Rectangle(0, 0, W, H), ImageLockMode.WriteOnly, PixelFormat.Format32bppArgb);
            Marshal.Copy(P, 0, d.Scan0, P.Length); o.UnlockBits(d);
            o.Save(dest, ImageFormat.Png);
        }
        return "specks " + specks + " fringe " + fringe;
    }
}
'@

$art = $PSScriptRoot
$horny = Join-Path (Split-Path $art) "Textures\SizedApparel\BodyParts\Human\Penis\Horny"
$out = Join-Path $art "Staging\WolfCleanup"
New-Item -ItemType Directory -Force $out | Out-Null
if (-not $Files) { $Files = foreach ($s in 0..5) { foreach ($d in "south", "east") { "WolfPenis_${s}_$d.png" } } }
# A rebuilt sprite waiting in Staging/WolfFront4 (Build-WolfFront4.ps1) is cleaned instead of the live one.
$rebuilt = Join-Path $art "Staging\WolfFront4"
foreach ($f in $Files) {
    $src = if (Test-Path (Join-Path $rebuilt $f)) { Join-Path $rebuilt $f } else { Join-Path $horny $f }
    $reach = if ($f -eq "WolfPenis_5_east.png") { 4 } else { 2 }
    "$f  " + [WolfClean]::Clean($src, (Join-Path $out $f), $reach)
}

# Review sheet: live above cleaned, zoomed 2x on the organ, on the in-game floor color.
$cell = 300
$sheet = New-Object System.Drawing.Bitmap ($cell * 6), ($cell * 4 + 24)
$g = [System.Drawing.Graphics]::FromImage($sheet)
$g.Clear([System.Drawing.Color]::FromArgb(150, 120, 90))
$g.InterpolationMode = "NearestNeighbor"
$g.PixelOffsetMode = "Half"
$font = New-Object System.Drawing.Font "Arial", 11
$row = 0
foreach ($d in "south", "east") {
    foreach ($clean in $false, $true) {
        for ($s = 0; $s -le 5; $s++) {
            $p = if ($clean) { Join-Path $out "WolfPenis_${s}_$d.png" } else { Join-Path $horny "WolfPenis_${s}_$d.png" }
            $img = [System.Drawing.Image]::FromFile($p)
            $src = if ($d -eq "south") { New-Object System.Drawing.Rectangle 181, 90, 150, 220 } else { New-Object System.Drawing.Rectangle 225, 90, 210, 220 }
            $g.DrawImage($img, (New-Object System.Drawing.Rectangle ($s * $cell), ($row * $cell + 24), $cell, $cell), $src, [System.Drawing.GraphicsUnit]::Pixel)
            $img.Dispose()
        }
        $g.DrawString("$d " + $(if ($clean) { "cleaned" } else { "live" }), $font, [System.Drawing.Brushes]::White, 4, ($row * $cell + 28))
        $row++
    }
}
for ($s = 0; $s -le 5; $s++) { $g.DrawString("size $s", $font, [System.Drawing.Brushes]::White, ($s * $cell + 120), 4) }
$g.Dispose()
$sheet.Save((Join-Path $art "Staging\WolfCleanup-review.png"), [System.Drawing.Imaging.ImageFormat]::Png)
$sheet.Dispose()
