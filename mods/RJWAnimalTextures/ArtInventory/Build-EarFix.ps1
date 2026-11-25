# Re-places the black-tipped cat ears and the lynx ears on the Sized Apparel Heads cat-ear spots.
# Measured on the 512 canvas: SA cat ears south/north are two ears, left x 161-232 and right x 279-351,
# bottom y 227 (outer edges flush with the average head's sides, 46 px gap). East is one ear,
# x 212-281, bottom 229.
# Problems in the live files (2026-11-12):
#  - Black-tipped south: the two ears touch in the middle. North: both ears merged into one narrow V.
#    The fur was a fixed white, so it ignored hair color.
#  - Lynx south/north: each ear 58 px wide with a 5 px gap, so the pair sat inside the head.
#    East sat 31 px too far back. Narrow heads squeeze head attachments to 87% width, so it got worse.
# Each ear is cut out of the live picture, scaled, and placed on its own spot. Black-tipped north is
# the south pair with the pink inner ear filled with fur (the back of the ear). Black-tipped fur is
# turned into a gray mask for the hair color; the pink inner ear goes into a separate untinted layer
# (BlacktipCatEarsInner), drawn just above the fur.
# Writes only to Staging/EarFix, plus Staging/EarFix-review.png.
param([double]$LynxScale = 1.3, [double]$BlacktipScale = 0.9)
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = "Stop"

if (-not ("EarFix" -as [type])) {
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

public static class EarFix
{
    public static byte[] Load(string p, out int W, out int H)
    {
        using (var b = new Bitmap(p))
        {
            W = b.Width; H = b.Height;
            var d = b.LockBits(new Rectangle(0, 0, W, H), ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
            var P = new byte[W * H * 4]; Marshal.Copy(d.Scan0, P, 0, P.Length); b.UnlockBits(d);
            return P;
        }
    }

    static Bitmap ToBitmap(byte[] P, int W, int H)
    {
        var o = new Bitmap(W, H, PixelFormat.Format32bppArgb);
        var d = o.LockBits(new Rectangle(0, 0, W, H), ImageLockMode.WriteOnly, PixelFormat.Format32bppArgb);
        Marshal.Copy(P, 0, d.Scan0, P.Length); o.UnlockBits(d);
        return o;
    }

    // The visible groups of at least minSize pixels, left to right, each cropped to its own bitmap.
    public static List<Bitmap> Ears(string p, int minSize)
    {
        int W, H; var P = Load(p, out W, out H);
        var lab = new int[W * H]; var st = new Stack<int>(); var res = new List<KeyValuePair<int, Bitmap>>();
        int id = 0;
        for (int s = 0; s < W * H; s++)
        {
            if (lab[s] != 0 || P[s * 4 + 3] <= 16) continue;
            id++; var mem = new List<int>(); lab[s] = id; st.Push(s);
            int x0 = W, y0 = H, x1 = 0, y1 = 0;
            while (st.Count > 0)
            {
                int q = st.Pop(); mem.Add(q); int x = q % W, y = q / W;
                if (x < x0) x0 = x; if (x > x1) x1 = x; if (y < y0) y0 = y; if (y > y1) y1 = y;
                for (int dy = -1; dy <= 1; dy++) for (int dx = -1; dx <= 1; dx++)
                {
                    int xx = x + dx, yy = y + dy; if (xx < 0 || yy < 0 || xx >= W || yy >= H) continue;
                    int r = yy * W + xx; if (lab[r] != 0 || P[r * 4 + 3] <= 16) continue; lab[r] = id; st.Push(r);
                }
            }
            if (mem.Count < minSize) continue;
            int cw = x1 - x0 + 1, ch = y1 - y0 + 1; var C = new byte[cw * ch * 4];
            foreach (int q in mem) { int x = q % W - x0, y = q / W - y0; Array.Copy(P, q * 4, C, (y * cw + x) * 4, 4); }
            res.Add(new KeyValuePair<int, Bitmap>(x0, ToBitmap(C, cw, ch)));
        }
        res.Sort((a, b) => a.Key.CompareTo(b.Key));
        var list = new List<Bitmap>(); foreach (var kv in res) list.Add(kv.Value);
        return list;
    }

    // Draws an ear at the given scale, its bottom at 'bottom', with its left edge at 'left' (alignLeft)
    // or its right edge at 'left' (otherwise).
    public static void Place(Graphics g, Bitmap ear, double scale, double edge, bool alignLeft, double bottom)
    {
        double w = ear.Width * scale, h = ear.Height * scale;
        double x = alignLeft ? edge : edge - w;
        g.DrawImage(ear, (float)x, (float)(bottom - h), (float)w, (float)h);
    }

    public static void PlaceCenter(Graphics g, Bitmap ear, double scale, double cx, double bottom)
    {
        double w = ear.Width * scale, h = ear.Height * scale;
        g.DrawImage(ear, (float)(cx - w / 2), (float)(bottom - h), (float)w, (float)h);
    }

    public static Bitmap Canvas() { return new Bitmap(512, 512, PixelFormat.Format32bppArgb); }
    public static Graphics G(Bitmap b)
    {
        var g = Graphics.FromImage(b);
        g.InterpolationMode = InterpolationMode.HighQualityBicubic; g.PixelOffsetMode = PixelOffsetMode.HighQuality; g.SmoothingMode = SmoothingMode.HighQuality;
        return g;
    }

    static bool Pink(byte b, byte g, byte r) { int l = (r * 299 + g * 587 + b * 114) / 1000; return l > 110 && r > g + 22 && r > b + 8; }

    // mode 0: everything to a gray mask (pink included, as fur gray).
    // mode 1: only the pink inner ear, as drawn; the rest transparent.
    // mode 2: pink inner filled with the light fur gray (back of the ear), all to a gray mask.
    public static Bitmap Split(Bitmap src, int mode)
    {
        int W = src.Width, H = src.Height;
        var d = src.LockBits(new Rectangle(0, 0, W, H), ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
        var P = new byte[W * H * 4]; Marshal.Copy(d.Scan0, P, 0, P.Length); src.UnlockBits(d);
        for (int i = 0; i < P.Length; i += 4)
        {
            if (P[i + 3] == 0) continue;
            bool pink = Pink(P[i], P[i + 1], P[i + 2]);
            int l = (P[i + 2] * 299 + P[i + 1] * 587 + P[i] * 114) / 1000;
            if (mode == 1) { if (!pink) P[i + 3] = 0; continue; }
            if (pink) l = mode == 2 ? 236 : Math.Max(l, 220);
            byte v = (byte)Math.Min(255, l);
            P[i] = v; P[i + 1] = v; P[i + 2] = v;
        }
        return ToBitmap(P, W, H);
    }

    public static Bitmap Tint(Bitmap src, Color c)
    {
        int W = src.Width, H = src.Height;
        var d = src.LockBits(new Rectangle(0, 0, W, H), ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
        var P = new byte[W * H * 4]; Marshal.Copy(d.Scan0, P, 0, P.Length); src.UnlockBits(d);
        for (int i = 0; i < P.Length; i += 4) { P[i] = (byte)(P[i] * c.B / 255); P[i + 1] = (byte)(P[i + 1] * c.G / 255); P[i + 2] = (byte)(P[i + 2] * c.R / 255); }
        return ToBitmap(P, W, H);
    }
}
'@
}

$art = $PSScriptRoot
$live = Join-Path (Split-Path $art) "Textures\Things\Pawn\Humanlike\HeadAttachments"
$out = Join-Path $art "Staging\EarFix"
foreach ($d in "BlacktipCatEars", "LynxEars") { New-Item -ItemType Directory -Force (Join-Path $out $d) | Out-Null }

# SA cat-ear spots (512 canvas).
$leftOuter = 161; $rightOuter = 351; $bottomS = 227; $eastCx = 246.5; $bottomE = 229

function Save-Pair($ears, $scale, $mode, $path) {
    $c = [EarFix]::Canvas(); $g = [EarFix]::G($c)
    $l = [EarFix]::Split($ears[0], $mode); $r = [EarFix]::Split($ears[1], $mode)
    [EarFix]::Place($g, $l, $scale, $leftOuter, $true, $bottomS)
    [EarFix]::Place($g, $r, $scale, $rightOuter, $false, $bottomS)
    $g.Dispose(); $c.Save($path, [System.Drawing.Imaging.ImageFormat]::Png); $c.Dispose(); $l.Dispose(); $r.Dispose()
}
function Save-Side($ear, $scale, $mode, $path) {
    $c = [EarFix]::Canvas(); $g = [EarFix]::G($c)
    $e = [EarFix]::Split($ear, $mode)
    [EarFix]::PlaceCenter($g, $e, $scale, $eastCx, $bottomE)
    $g.Dispose(); $c.Save($path, [System.Drawing.Imaging.ImageFormat]::Png); $c.Dispose(); $e.Dispose()
}

# Black-tipped: fur mask + inner layer. North from the south pair with the inner filled.
$bt = Join-Path $live "BlacktipCatEars"; $btOut = Join-Path $out "BlacktipCatEars"
$s = [EarFix]::Ears((Join-Path $bt "BlacktipCatEars_south.png"), 200)
$e = [EarFix]::Ears((Join-Path $bt "BlacktipCatEars_east.png"), 200)
"blacktip south ears $($s.Count), east $($e.Count)"
Save-Pair $s $BlacktipScale 0 (Join-Path $btOut "BlacktipCatEars_south.png")
Save-Pair $s $BlacktipScale 1 (Join-Path $btOut "BlacktipCatEarsInner_south.png")
Save-Pair $s $BlacktipScale 2 (Join-Path $btOut "BlacktipCatEars_north.png")
Save-Side $e[0] 1.0 0 (Join-Path $btOut "BlacktipCatEars_east.png")
Save-Side $e[0] 1.0 1 (Join-Path $btOut "BlacktipCatEarsInner_east.png")
# North has no inner ear showing: a blank 4x4, like the other blank sprites.
$blank = New-Object System.Drawing.Bitmap 4, 4, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$blank.Save((Join-Path $btOut "BlacktipCatEarsInner_north.png"), [System.Drawing.Imaging.ImageFormat]::Png); $blank.Dispose()

# Lynx: already a gray mask. Bigger, apart, side ear moved forward.
$lx = Join-Path $live "LynxEars"; $lxOut = Join-Path $out "LynxEars"
$s = [EarFix]::Ears((Join-Path $lx "LynxEars_south.png"), 200)
$n = [EarFix]::Ears((Join-Path $lx "LynxEars_north.png"), 200)
$e = [EarFix]::Ears((Join-Path $lx "LynxEars_east.png"), 200)
"lynx south ears $($s.Count), north $($n.Count), east $($e.Count)"
Save-Pair $s $LynxScale 0 (Join-Path $lxOut "LynxEars_south.png")
Save-Pair $n $LynxScale 0 (Join-Path $lxOut "LynxEars_north.png")
Save-Side $e[0] $LynxScale 0 (Join-Path $lxOut "LynxEars_east.png")
