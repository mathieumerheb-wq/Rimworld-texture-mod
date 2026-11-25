# Fills see-through holes inside a sprite (fully or partly transparent). Some source pictures had small gaps in the fill (the cat
# scrotum, for example), so the floor showed through as a dark dot. A hole is a group of
# not-opaque pixels (alpha < 240) that cannot reach the canvas edge through other not-opaque pixels,
# (a gap in the outline narrower than 2*Gap px does not count as reaching it: -Gap 1 closes 1 px
# gaps, -Gap 2 closes up to 3 px; larger values start filling real notches in the outline),
# and is no bigger than -MaxHole pixels (larger enclosed gaps may be meant, and are only reported).
# Each hole, plus its soft one-pixel rim, is filled from the outside in with the average color of its
# opaque neighbors, at full alpha.
# -Report lists holes without writing. Otherwise writes each file to -OutDir under the same name.
param([Parameter(Mandatory)][string[]]$Files, [string]$OutDir, [int]$MaxHole = 400, [int]$Gap = 1, [switch]$Report)
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = "Stop"

if (-not ("HoleFill" -as [type])) {
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

public static class HoleFill
{
    public static string Run(string src, string dest, int maxHole, int gap)
    {
        int W, H; byte[] P;
        using (var b = new Bitmap(src))
        {
            W = b.Width; H = b.Height;
            if (W < 64) { if (!string.IsNullOrEmpty(dest)) b.Save(dest, ImageFormat.Png); return "blank"; }
            var d = b.LockBits(new Rectangle(0, 0, W, H), ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
            P = new byte[W * H * 4]; Marshal.Copy(d.Scan0, P, 0, P.Length); b.UnlockBits(d);
        }
        int N = W * H;
        // Outside: flood from the canvas edge through "wide" not-opaque pixels (everything within -Gap px
        // not opaque), so the flood cannot slip into a hole through a narrow gap in the outline;
        // then grow it by -Gap px to take back the outline's soft edge.
        bool[] clear = new bool[N];
        for (int p = 0; p < N; p++) clear[p] = P[p * 4 + 3] < 240;
        bool[] wide = new bool[N];
        int gr = gap; // a gap up to 2*gap-1 px wide is closed
        for (int y = 0; y < H; y++) for (int x = 0; x < W; x++)
        {
            bool ok = true; // beyond the canvas counts as clear
            for (int dy = -gr; dy <= gr && ok; dy++) for (int dx = -gr; dx <= gr; dx++)
            {
                int xx = x + dx, yy = y + dy;
                if (xx >= 0 && yy >= 0 && xx < W && yy < H && !clear[yy * W + xx]) { ok = false; break; }
            }
            wide[y * W + x] = ok;
        }
        bool[] ext = new bool[N];
        var stack = new Stack<int>();
        for (int x = 0; x < W; x++) { stack.Push(x); stack.Push((H - 1) * W + x); }
        for (int y = 0; y < H; y++) { stack.Push(y * W); stack.Push(y * W + W - 1); }
        while (stack.Count > 0)
        {
            int p = stack.Pop();
            if (ext[p] || !clear[p]) continue;
            int x = p % W, y = p / W;
            bool border = x == 0 || y == 0 || x == W - 1 || y == H - 1;
            if (!border && !wide[p]) continue;
            ext[p] = true;
            if (x > 0) stack.Push(p - 1); if (x < W - 1) stack.Push(p + 1);
            if (y > 0) stack.Push(p - W); if (y < H - 1) stack.Push(p + W);
        }
        bool[] outsideMask = new bool[N];
        for (int y = 0; y < H; y++) for (int x = 0; x < W; x++)
        {
            int p = y * W + x; if (!clear[p]) continue;
            for (int dy = -gr; dy <= gr; dy++) for (int dx = -gr; dx <= gr; dx++)
            {
                int xx = x + dx, yy = y + dy;
                if (xx >= 0 && yy >= 0 && xx < W && yy < H && ext[yy * W + xx]) outsideMask[p] = true;
            }
        }
        // Holes: the remaining not-opaque groups. A group that touches the outside (a hole opening
        // through a 1 px gap, or the second pixel of a soft edge) is filled only if it has a truly
        // see-through core (alpha < 128); soft edges have none.
        bool[] fill = new bool[N];
        int[] comp = new int[N];
        int holes = 0, filled = 0; var big = new List<int>();
        var members = new List<int>();
        for (int s0 = 0; s0 < N; s0++)
        {
            if (comp[s0] != 0 || !clear[s0] || outsideMask[s0]) continue;
            members.Clear(); bool touches = false, core = false;
            comp[s0] = 1; stack.Push(s0);
            while (stack.Count > 0)
            {
                int p = stack.Pop(); members.Add(p);
                if (P[p * 4 + 3] < 128) core = true;
                int x = p % W, y = p / W;
                int[] nb = { x > 0 ? p - 1 : -1, x < W - 1 ? p + 1 : -1, y > 0 ? p - W : -1, y < H - 1 ? p + W : -1 };
                foreach (int q in nb)
                {
                    if (q < 0) continue;
                    if (outsideMask[q]) { touches = true; continue; }
                    if (comp[q] != 0 || !clear[q]) continue;
                    comp[q] = 1; stack.Push(q);
                }
            }
            if (touches && !core) continue;
            if (members.Count > maxHole) { big.Add(members.Count); continue; }
            holes++;
            foreach (int p in members) fill[p] = true;
        }
        // Soft rim: partly transparent pixels next to a hole join it.
        bool[] rim = new bool[N];
        for (int p = 0; p < N; p++)
        {
            if (fill[p] || P[p * 4 + 3] == 255) continue;
            int x = p % W, y = p / W;
            for (int dy = -1; dy <= 1; dy++) for (int dx = -1; dx <= 1; dx++)
            {
                int xx = x + dx, yy = y + dy;
                if (xx < 0 || yy < 0 || xx >= W || yy >= H) continue;
                if (fill[yy * W + xx]) rim[p] = true;
            }
        }
        for (int p = 0; p < N; p++) if (rim[p]) fill[p] = true;
        // Fill from the outside in.
        bool any = true;
        while (any)
        {
            any = false;
            var next = new List<int[]>();
            for (int p = 0; p < N; p++)
            {
                if (!fill[p]) continue;
                int x = p % W, y = p / W; int n = 0; long r = 0, g = 0, bl = 0;
                for (int dy = -1; dy <= 1; dy++) for (int dx = -1; dx <= 1; dx++)
                {
                    int xx = x + dx, yy = y + dy;
                    if ((dx == 0 && dy == 0) || xx < 0 || yy < 0 || xx >= W || yy >= H) continue;
                    int q = yy * W + xx;
                    if (fill[q] || P[q * 4 + 3] < 250) continue;
                    n++; bl += P[q * 4]; g += P[q * 4 + 1]; r += P[q * 4 + 2];
                }
                if (n >= 2) next.Add(new int[] { p, (int)(bl / n), (int)(g / n), (int)(r / n) });
            }
            foreach (var e in next)
            {
                int i = e[0] * 4;
                P[i] = (byte)e[1]; P[i + 1] = (byte)e[2]; P[i + 2] = (byte)e[3]; P[i + 3] = 255;
                fill[e[0]] = false; filled++; any = true;
            }
        }
        if (!string.IsNullOrEmpty(dest))
        {
            using (var o = new Bitmap(W, H, PixelFormat.Format32bppArgb))
            {
                var d = o.LockBits(new Rectangle(0, 0, W, H), ImageLockMode.WriteOnly, PixelFormat.Format32bppArgb);
                Marshal.Copy(P, 0, d.Scan0, P.Length); o.UnlockBits(d);
                o.Save(dest, ImageFormat.Png);
            }
        }
        return "holes " + holes + " pixels " + filled + (big.Count > 0 ? " kept-large " + string.Join("/", big) : "");
    }
}
'@
}

if (-not $Report) { New-Item -ItemType Directory -Force $OutDir | Out-Null }
foreach ($f in $Files) {
    $dest = if ($Report) { $null } else { Join-Path $OutDir (Split-Path $f -Leaf) }
    "$(Split-Path $f -Leaf)  " + [HoleFill]::Run($f, $dest, $MaxHole, $Gap)
}
