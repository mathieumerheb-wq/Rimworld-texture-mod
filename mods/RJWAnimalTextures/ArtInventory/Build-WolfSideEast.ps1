# WolfPenis aroused east, sizes 2 to 5, rebuilt as one side-view series.
# Supersedes Build-WolfSide4.ps1. Writes only to Staging/WolfSideEast, plus a review sheet.
# Sources, from least to most bulky, all true side views:
#   2 ref-wolf-side-3  short, smooth
#   3 ref-wolf-side-4  longer, a little thicker
#   4 ref-wolf-side-1  thick shaft, big knot
#   5 ref-wolf-side-5  thickest shaft, biggest knot and scrotum
# Each picture is mirrored when the tip points left, so east points right, then leaned 55 degrees
# from vertical toward the right. 40 read too upright and too narrow at the ladder heights. The shaft direction comes from a principal-axis fit of the red
# shaft pixels, pointing away from the sheath and scrotum. Height and the bottom-left corner match
# the live sprites they replace. The sheath and scrotum become gray, brightened to an average near
# 182 like the other wolf sprites, so the skin tint applies. The red shaft keeps its color.
# Sizes 0 and 1, rest, south, north, and balls are not touched.
# The staged files were reviewed and copied into Textures by hand on 2026-10-30.
Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = "Stop"

Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;
using System.Runtime.InteropServices;

public static class WolfSideEast
{
    public static void Build(string refPath, string outPath, float targetH, float left, float bottom, float lean)
    {
        Bitmap art = Largest(Load(refPath));
        PointF c, tip, body;
        Axis(art, out c, out tip, out body);
        bool mirrored = tip.X < body.X;
        if (mirrored)
        {
            Bitmap m = Mirror(art);
            art.Dispose();
            art = m;
            Axis(art, out c, out tip, out body);
        }
        float k = Gray(art, 182f);
        float angle = (float)(Math.Atan2(tip.Y, tip.X) * 180.0 / Math.PI);
        float rot = (-90f + lean) - angle;
        PointF mid = new PointF(art.Width * 0.5f, art.Height * 0.5f);

        const int probe = 2048;
        RectangleF box;
        using (Bitmap test = Draw(art, probe, 1f, mid, probe * 0.5f, probe * 0.5f, rot)) box = Bounds(test);
        float s = targetH / box.Height;
        float dx = left - s * (box.Left - probe * 0.5f);
        float dy = bottom - s * (box.Bottom - 1 - probe * 0.5f);

        Directory.CreateDirectory(Path.GetDirectoryName(outPath));
        using (Bitmap result = Draw(art, 512, s, mid, dx, dy, rot))
        {
            RectangleF b = Bounds(result);
            if (b.Left < 1 || b.Top < 1 || b.Right > 511 || b.Bottom > 511) throw new Exception(Path.GetFileName(outPath) + " touches the canvas edge");
            result.Save(outPath, ImageFormat.Png);
            Console.WriteLine(Path.GetFileName(refPath) + " -> " + Path.GetFileName(outPath)
                + (mirrored ? " mirrored" : "") + ", shaft " + angle.ToString("0") + " deg, rot " + rot.ToString("0")
                + ", gray x" + k.ToString("0.00") + ", scale " + s.ToString("0.000")
                + ", bbox x" + b.Left + "-" + (b.Right - 1) + " y" + b.Top + "-" + (b.Bottom - 1) + " W" + b.Width + " H" + b.Height);
        }
        art.Dispose();
    }

    static bool Page(Color c)
    {
        int min = Math.Min(c.R, Math.Min(c.G, c.B));
        int max = Math.Max(c.R, Math.Max(c.G, c.B));
        return c.A < 16 || (min >= 245 && (max - min) < 12);
    }

    // Red or pink shaft: red is the top channel, chroma at least 40, hue under 8 degrees.
    // Sheath and scrotum (gray, beige, brown) sit at 10 degrees and above, or have low chroma.
    static bool Shaft(Color c)
    {
        int max = Math.Max(c.R, Math.Max(c.G, c.B));
        int min = Math.Min(c.R, Math.Min(c.G, c.B));
        if (c.A < 16 || max != c.R || max - min < 40) return false;
        return 60f * (c.G - c.B) / (max - min) < 8f;
    }

    // Shaft centroid, unit direction toward the tip, and the sheath-and-scrotum centroid.
    static void Axis(Bitmap bmp, out PointF center, out PointF tip, out PointF body)
    {
        double sx = 0, sy = 0, n = 0, bx = 0, by = 0, bn = 0;
        for (int y = 0; y < bmp.Height; y++)
        for (int x = 0; x < bmp.Width; x++)
        {
            Color c = bmp.GetPixel(x, y);
            if (c.A < 16) continue;
            if (Shaft(c)) { sx += x; sy += y; n++; }
            else { bx += x; by += y; bn++; }
        }
        double cx = sx / n, cy = sy / n;
        double xx = 0, yy = 0, xy = 0;
        for (int y = 0; y < bmp.Height; y++)
        for (int x = 0; x < bmp.Width; x++)
        {
            if (!Shaft(bmp.GetPixel(x, y))) continue;
            xx += (x - cx) * (x - cx); yy += (y - cy) * (y - cy); xy += (x - cx) * (y - cy);
        }
        double a = 0.5 * Math.Atan2(2 * xy, xx - yy);
        double ux = Math.Cos(a), uy = Math.Sin(a);
        body = new PointF((float)(bx / Math.Max(bn, 1)), (float)(by / Math.Max(bn, 1)));
        if ((body.X - cx) * ux + (body.Y - cy) * uy > 0) { ux = -ux; uy = -uy; }
        center = new PointF((float)cx, (float)cy);
        tip = new PointF((float)ux, (float)uy);
    }

    // Non-shaft pixels become gray; the scale brings their average to the target brightness.
    static float Gray(Bitmap bmp, float target)
    {
        double sum = 0; int n = 0;
        for (int y = 0; y < bmp.Height; y++)
        for (int x = 0; x < bmp.Width; x++)
        {
            Color c = bmp.GetPixel(x, y);
            if (c.A < 16 || Shaft(c)) continue;
            sum += 0.299 * c.R + 0.587 * c.G + 0.114 * c.B; n++;
        }
        float k = n > 0 ? (float)Math.Max(0.8, Math.Min(1.6, target / (sum / n))) : 1f;
        for (int y = 0; y < bmp.Height; y++)
        for (int x = 0; x < bmp.Width; x++)
        {
            Color c = bmp.GetPixel(x, y);
            if (c.A < 16 || Shaft(c)) continue;
            int l = Math.Min(255, (int)((0.299 * c.R + 0.587 * c.G + 0.114 * c.B) * k));
            bmp.SetPixel(x, y, Color.FromArgb(c.A, l, l, l));
        }
        return k;
    }

    static Bitmap Load(string path)
    {
        using (Bitmap source = new Bitmap(path))
        {
            Bitmap bmp = new Bitmap(source.Width, source.Height, PixelFormat.Format32bppArgb);
            for (int y = 0; y < source.Height; y++)
            for (int x = 0; x < source.Width; x++)
            {
                Color c = source.GetPixel(x, y);
                if (Page(c)) continue;
                bmp.SetPixel(x, y, Color.FromArgb(255, c.R, c.G, c.B));
            }
            return bmp;
        }
    }

    static Bitmap Largest(Bitmap src)
    {
        int w = src.Width, h = src.Height;
        int[] id = new int[w * h];
        int next = 0, best = 0, bestN = 0;
        int[] qx = new int[w * h], qy = new int[w * h];
        for (int y = 0; y < h; y++)
        for (int x = 0; x < w; x++)
        {
            if (src.GetPixel(x, y).A < 16 || id[y * w + x] != 0) continue;
            next++;
            int head = 0, tail = 0, count = 0;
            qx[tail] = x; qy[tail] = y; tail++;
            id[y * w + x] = next;
            while (head < tail)
            {
                int px = qx[head], py = qy[head];
                head++; count++;
                for (int oy = -1; oy <= 1; oy++)
                for (int ox = -1; ox <= 1; ox++)
                {
                    int nx = px + ox, ny = py + oy;
                    if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue;
                    if (id[ny * w + nx] != 0 || src.GetPixel(nx, ny).A < 16) continue;
                    id[ny * w + nx] = next;
                    qx[tail] = nx; qy[tail] = ny; tail++;
                }
            }
            if (count > bestN) { bestN = count; best = next; }
        }
        Bitmap bmp = new Bitmap(w, h, PixelFormat.Format32bppArgb);
        for (int y = 0; y < h; y++)
        for (int x = 0; x < w; x++)
            if (id[y * w + x] == best) bmp.SetPixel(x, y, src.GetPixel(x, y));
        src.Dispose();
        return bmp;
    }

    static Bitmap Mirror(Bitmap src)
    {
        Bitmap bmp = new Bitmap(src.Width, src.Height, PixelFormat.Format32bppArgb);
        for (int y = 0; y < src.Height; y++)
        for (int x = 0; x < src.Width; x++)
        {
            Color c = src.GetPixel(x, y);
            if (c.A >= 16) bmp.SetPixel(src.Width - 1 - x, y, c);
        }
        return bmp;
    }

    static Bitmap Draw(Bitmap art, int size, float scale, PointF origin, float dx, float dy, float rot)
    {
        Bitmap bmp = new Bitmap(size, size, PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(bmp))
        {
            g.SmoothingMode = SmoothingMode.HighQuality;
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
            g.PixelOffsetMode = PixelOffsetMode.HighQuality;
            g.TranslateTransform(dx, dy);
            g.RotateTransform(rot);
            g.ScaleTransform(scale, scale);
            g.TranslateTransform(-origin.X, -origin.Y);
            g.DrawImage(art, 0, 0, art.Width, art.Height);
        }
        return bmp;
    }

    public static RectangleF Bounds(Bitmap bmp)
    {
        int minX = bmp.Width, minY = bmp.Height, maxX = -1, maxY = -1;
        BitmapData d = bmp.LockBits(new Rectangle(0, 0, bmp.Width, bmp.Height), ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
        byte[] px = new byte[d.Stride * bmp.Height];
        Marshal.Copy(d.Scan0, px, 0, px.Length);
        bmp.UnlockBits(d);
        for (int y = 0; y < bmp.Height; y++)
        for (int x = 0; x < bmp.Width; x++)
        {
            if (px[y * d.Stride + x * 4 + 3] < 16) continue;
            if (x < minX) minX = x;
            if (x > maxX) maxX = x;
            if (y < minY) minY = y;
            if (y > maxY) maxY = y;
        }
        return RectangleF.FromLTRB(minX, minY, maxX + 1, maxY + 1);
    }

    // Rows of 512 canvases cropped the same way and drawn at the same scale on a pale skin color,
    // so sizes compare directly. The blue lines mark x 242 and y 286.
    public static void Review(string[] files, string[] labels, int cols, string outPath)
    {
        const int cell = 260, top = 22, cropX = 180, cropY = 70, cropW = 330;
        float z = (float)cell / cropW;
        int rows = (files.Length + cols - 1) / cols;
        Bitmap sheet = new Bitmap(cell * cols, rows * (cell + top + 18), PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(sheet))
        using (Font font = new Font("Segoe UI", 12f, FontStyle.Regular, GraphicsUnit.Pixel))
        using (Pen guide = new Pen(Color.FromArgb(140, 40, 90, 200), 1f))
        {
            g.Clear(Color.FromArgb(255, 236, 214, 196));
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
            for (int i = 0; i < files.Length; i++)
            {
                int x0 = (i % cols) * cell, y0 = (i / cols) * (cell + top + 18);
                g.DrawString(labels[i], font, Brushes.Black, x0 + 4, y0 + 3);
                if (files[i] == null) continue;
                using (Bitmap part = new Bitmap(files[i]))
                {
                    float k = 512f / part.Width;
                    RectangleF b = Bounds(part);
                    g.DrawImage(part, new RectangleF(x0, y0 + top, cell, cell),
                        new RectangleF(cropX / k, cropY / k, cropW / k, cropW / k), GraphicsUnit.Pixel);
                    g.DrawString("W" + (b.Width * k) + " H" + (b.Height * k), font, Brushes.Black, x0 + 4, y0 + top + cell);
                }
                g.DrawLine(guide, x0 + (242 - cropX) * z, y0 + top, x0 + (242 - cropX) * z, y0 + top + cell);
                g.DrawLine(guide, x0, y0 + top + (286 - cropY) * z, x0 + cell, y0 + top + (286 - cropY) * z);
                g.DrawLine(Pens.DimGray, x0 + cell - 1, y0, x0 + cell - 1, y0 + cell + top + 18);
            }
        }
        sheet.Save(outPath, ImageFormat.Png);
        sheet.Dispose();
        Console.WriteLine("REVIEW " + outPath);
    }
}
'@

$art = "C:\Users\mathi\Documents\Rimworld new mods\mods\RJWAnimalTextures\ArtInventory"
$inv = Join-Path $art "TextureV2"
$live = "C:\Users\mathi\Documents\Rimworld new mods\mods\RJWAnimalTextures\Textures\SizedApparel\BodyParts\Human\Penis\Horny"
$stage = Join-Path $art "Staging\WolfSideEast"
$lean = 55
# size, source, height, left, bottom (height and corner of the live sprite being replaced)
$plan = @(
    @(2, "ref-wolf-side-3.png", 81, 242, 286),
    @(3, "ref-wolf-side-4.png", 130, 242, 287),
    @(4, "ref-wolf-side-1.png", 144, 242, 286),
    # 200 instead of the 180 ladder: at 180 the shaft was only 5 px longer than size 4,
    # because this picture's tall scrotum takes up the height.
    @(5, "ref-wolf-side-5.png", 200, 243, 300)
)
foreach ($p in $plan) {
    [WolfSideEast]::Build((Join-Path $inv $p[1]), (Join-Path $stage ("Horny\WolfPenis_" + $p[0] + "_east.png")), $p[2], $p[3], $p[4], $lean)
}

$files = @(); $labels = @()
foreach ($s in 0..5) { $files += (Join-Path $live "WolfPenis_${s}_east.png"); $labels += "Live erect $s" }
foreach ($s in 0..5) {
    if ($s -le 1) { $files += (Join-Path $live "WolfPenis_${s}_east.png"); $labels += "Kept erect $s" }
    else { $files += (Join-Path $stage "Horny\WolfPenis_${s}_east.png"); $labels += "STAGED erect $s" }
}
[WolfSideEast]::Review($files, $labels, 6, (Join-Path $stage "review-WolfPenis_east.png"))
