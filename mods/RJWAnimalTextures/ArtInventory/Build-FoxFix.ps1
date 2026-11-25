# FoxPenis aroused sizes 0, 1, 2 and 4, south and east. Writes only to Staging/FoxFix, plus a review sheet.
# Size 2 was reference-fox-south: a knotted shaft with no scrotum, as wide as size 3, so average read
# bigger than large. Sizes 0 and 1 were 56 and 68 px tall, then size 2 jumped to 124.
# Sizes 0-2 are now ref-big-c, the slim knotted front with the scrotum (fox size 4 before
# Build-CanineKnot.ps1 swapped in the pointed tip), at even steps below size 3:
# south 72, 96, 120 (size 3 is 144), east 70, 90, 110 (size 3 is 128).
# Size 4 stays ref-fox-knot-front at its live heights (south 166, east 142). Its shaft is mauve, so
# Build-CanineKnot.ps1's red test kept only the darkest strokes and the rest became the gray skin mask.
# Here the shaft is picked by saturation instead, then shaded into the fox red of size 3.
# The cutoff sits between each picture's shaft and scrotum: ref-big-c shaft 0.49-0.59 and scrotum
# 0.18-0.30, so 0.40; ref-fox-knot-front shaft 0.31-0.42 and scrotum 0.14-0.24, so 0.28.
# Colors: shaft median (180, 85, 88), scrotum gray median 180, like the live size 3. Dark outline kept.
# South stands the shaft up on the size 3 base, bottom center (256, 262).
# East leans it 45 degrees up-right on the size 3 corner, bottom left (242, 266).
Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = "Stop"

Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;

public static class FoxFix
{
    static float Lum(Color c) { return 0.30f * c.R + 0.59f * c.G + 0.11f * c.B; }

    static float sat = 0.28f;

    static bool Shaft(Color c)
    {
        int max = Math.Max(c.R, Math.Max(c.G, c.B));
        int min = Math.Min(c.R, Math.Min(c.G, c.B));
        return max > 70 && (max - min) > sat * max && c.R >= c.G && c.R >= c.B;
    }

    // White page out, largest piece kept, shaft shaded red and the rest turned to the gray mask.
    public static Bitmap Prepare(string path, float shaftSaturation)
    {
        sat = shaftSaturation;
        Bitmap src = new Bitmap(path);
        int w = src.Width, h = src.Height;
        Color[,] px = new Color[w, h];
        bool[,] on = new bool[w, h];
        for (int y = 0; y < h; y++)
            for (int x = 0; x < w; x++)
            {
                Color c = src.GetPixel(x, y);
                px[x, y] = c;
                int min = Math.Min(c.R, Math.Min(c.G, c.B));
                int max = Math.Max(c.R, Math.Max(c.G, c.B));
                on[x, y] = c.A > 16 && !(min >= 238 && max - min < 14);
            }
        src.Dispose();

        int[,] label = new int[w, h];
        int best = 0, bestSize = 0, next = 0;
        Queue<Point> q = new Queue<Point>();
        for (int y = 0; y < h; y++)
            for (int x = 0; x < w; x++)
            {
                if (!on[x, y] || label[x, y] != 0) continue;
                next++;
                int size = 0;
                label[x, y] = next;
                q.Enqueue(new Point(x, y));
                while (q.Count > 0)
                {
                    Point p = q.Dequeue();
                    size++;
                    for (int dy = -1; dy <= 1; dy++)
                        for (int dx = -1; dx <= 1; dx++)
                        {
                            int nx = p.X + dx, ny = p.Y + dy;
                            if (nx < 0 || ny < 0 || nx >= w || ny >= h || !on[nx, ny] || label[nx, ny] != 0) continue;
                            label[nx, ny] = next;
                            q.Enqueue(new Point(nx, ny));
                        }
                }
                if (size > bestSize) { bestSize = size; best = next; }
            }

        List<float> shaftL = new List<float>(), skinL = new List<float>();
        for (int y = 0; y < h; y++)
            for (int x = 0; x < w; x++)
            {
                if (label[x, y] != best) continue;
                Color c = px[x, y];
                float l = Lum(c);
                if (l < 70) continue;
                if (Shaft(c)) shaftL.Add(l); else skinL.Add(l);
            }
        shaftL.Sort();
        skinL.Sort();
        float shaftMid = shaftL[shaftL.Count / 2];
        float skinMid = skinL[skinL.Count / 2];

        Bitmap outBmp = new Bitmap(w, h, PixelFormat.Format32bppArgb);
        for (int y = 0; y < h; y++)
            for (int x = 0; x < w; x++)
            {
                if (label[x, y] != best) { outBmp.SetPixel(x, y, Color.Transparent); continue; }
                Color c = px[x, y];
                float l = Lum(c);
                Color o;
                if (l < 70)
                {
                    int v = (int)l;
                    o = Color.FromArgb(255, v, v, v);
                }
                else if (Shaft(c))
                {
                    float k = l / shaftMid;
                    o = Color.FromArgb(255, Clamp(180 * k), Clamp(85 * k), Clamp(88 * k));
                }
                else
                {
                    int v = Clamp(180 * l / skinMid);
                    o = Color.FromArgb(255, v, v, v);
                }
                outBmp.SetPixel(x, y, o);
            }
        return outBmp;
    }

    static int Clamp(float v) { return (int)Math.Max(0, Math.Min(255, v)); }

    // Direction from the base to the tip of the red shaft, in image degrees (up is -90).
    public static float ShaftAngle(Bitmap art)
    {
        double sx = 0, sy = 0, n = 0, gx = 0, gy = 0, gn = 0;
        for (int y = 0; y < art.Height; y++)
            for (int x = 0; x < art.Width; x++)
            {
                Color c = art.GetPixel(x, y);
                if (c.A < 128) continue;
                if (c.R - Math.Max(c.G, c.B) > 40) { sx += x; sy += y; n++; }
                else if (c.R > 120 && c.R - c.B < 10) { gx += x; gy += y; gn++; }
            }
        double mx = sx / n, my = sy / n;
        double cxx = 0, cyy = 0, cxy = 0;
        for (int y = 0; y < art.Height; y++)
            for (int x = 0; x < art.Width; x++)
            {
                Color c = art.GetPixel(x, y);
                if (c.A < 128 || c.R - Math.Max(c.G, c.B) <= 40) continue;
                cxx += (x - mx) * (x - mx); cyy += (y - my) * (y - my); cxy += (x - mx) * (y - my);
            }
        double theta = 0.5 * Math.Atan2(2 * cxy, cxx - cyy);
        double dx = Math.Cos(theta), dy = Math.Sin(theta);
        // Point away from the gray scrotum.
        if (gn > 0 && (mx - gx / gn) * dx + (my - gy / gn) * dy < 0) { dx = -dx; dy = -dy; }
        return (float)(Math.Atan2(dy, dx) * 180 / Math.PI);
    }

    static Rectangle Bounds(Bitmap b)
    {
        int minX = b.Width, minY = b.Height, maxX = -1, maxY = -1;
        for (int y = 0; y < b.Height; y++)
            for (int x = 0; x < b.Width; x++)
                if (b.GetPixel(x, y).A > 32)
                {
                    if (x < minX) minX = x; if (x > maxX) maxX = x;
                    if (y < minY) minY = y; if (y > maxY) maxY = y;
                }
        return new Rectangle(minX, minY, maxX - minX + 1, maxY - minY + 1);
    }

    static Bitmap Rotated(Bitmap art, float degrees, float scale)
    {
        int side = (int)(Math.Sqrt(art.Width * art.Width + art.Height * art.Height) * scale) + 8;
        Bitmap b = new Bitmap(side, side, PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(b))
        {
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
            g.PixelOffsetMode = PixelOffsetMode.HighQuality;
            g.TranslateTransform(side / 2f, side / 2f);
            g.RotateTransform(degrees);
            g.ScaleTransform(scale, scale);
            g.DrawImage(art, -art.Width / 2f, -art.Height / 2f, art.Width, art.Height);
        }
        return b;
    }

    // Turn the shaft to pointAngle, fit the opaque box to targetH, and set its anchor on the canvas.
    public static Bitmap Place(Bitmap art, float pointAngle, float targetH, bool anchorLeft, float ax, float ay)
    {
        float rot = pointAngle - ShaftAngle(art);
        Rectangle b1;
        using (Bitmap probe = Rotated(art, rot, 1f)) b1 = Bounds(probe);
        Bitmap big = Rotated(art, rot, targetH / b1.Height);
        Rectangle b = Bounds(big);
        Bitmap canvas = new Bitmap(512, 512, PixelFormat.Format32bppArgb);
        float left = anchorLeft ? ax : ax - b.Width / 2f;
        float top = ay - b.Height;
        using (Graphics g = Graphics.FromImage(canvas))
        {
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
            g.DrawImage(big, new RectangleF(left, top, b.Width, b.Height), new RectangleF(b.X, b.Y, b.Width, b.Height), GraphicsUnit.Pixel);
        }
        big.Dispose();
        return canvas;
    }
}
'@

$art = $PSScriptRoot
$inv = Join-Path $art "TextureV2"
$out = Join-Path $art "Staging\FoxFix"
New-Item -ItemType Directory -Force $out | Out-Null

$jobs = @(
    @{ size = 0; src = "ref-big-c.png"; sat = 0.40; south = 72; east = 70 },
    @{ size = 1; src = "ref-big-c.png"; sat = 0.40; south = 96; east = 90 },
    @{ size = 2; src = "ref-big-c.png"; sat = 0.40; south = 120; east = 110 },
    @{ size = 4; src = "ref-fox-knot-front.png"; sat = 0.28; south = 166; east = 142 }
)
$prepared = @{}
foreach ($job in $jobs) {
    if (-not $prepared.ContainsKey($job.src)) { $prepared[$job.src] = [FoxFix]::Prepare((Join-Path $inv $job.src), $job.sat) }
    $src = $prepared[$job.src]
    $s = [FoxFix]::Place($src, -90, $job.south, $false, 256, 262)
    $s.Save((Join-Path $out "FoxPenis_$($job.size)_south.png"), [System.Drawing.Imaging.ImageFormat]::Png); $s.Dispose()
    $e = [FoxFix]::Place($src, -45, $job.east, $true, 242, 266)
    $e.Save((Join-Path $out "FoxPenis_$($job.size)_east.png"), [System.Drawing.Imaging.ImageFormat]::Png); $e.Dispose()
}
foreach ($p in $prepared.Values) { $p.Dispose() }

# Review sheet: live and staged rows for south and east, sizes 0-5.
$horny = Join-Path (Split-Path $art) "Textures\SizedApparel\BodyParts\Human\Penis\Horny"
$cell = 200
$sheet = New-Object System.Drawing.Bitmap ($cell * 6), ($cell * 4 + 40)
$g = [System.Drawing.Graphics]::FromImage($sheet)
$g.Clear([System.Drawing.Color]::FromArgb(90, 90, 90))
$font = New-Object System.Drawing.Font "Arial", 11
$row = 0
foreach ($dir in "south", "east") {
    foreach ($staged in $false, $true) {
        for ($size = 0; $size -le 5; $size++) {
            $path = Join-Path $out "FoxPenis_${size}_$dir.png"
            if (-not $staged -or -not (Test-Path $path)) { $path = Join-Path $horny "FoxPenis_${size}_$dir.png" }
            $img = [System.Drawing.Image]::FromFile($path)
            $g.DrawImage($img, (New-Object System.Drawing.Rectangle ($size * $cell), ($row * $cell + 40), $cell, $cell), (New-Object System.Drawing.Rectangle 156, 30, 280, 280), [System.Drawing.GraphicsUnit]::Pixel)
            $img.Dispose()
        }
        $g.DrawString("$dir " + $(if ($staged) { "staged" } else { "live" }), $font, [System.Drawing.Brushes]::White, 4, ($row * $cell + 44))
        $row++
    }
}
for ($size = 0; $size -le 5; $size++) { $g.DrawString("size $size", $font, [System.Drawing.Brushes]::White, ($size * $cell + 70), 10) }
$g.Dispose()
$sheet.Save((Join-Path $art "Staging\FoxFix-review.png"), [System.Drawing.Imaging.ImageFormat]::Png)
$sheet.Dispose()
