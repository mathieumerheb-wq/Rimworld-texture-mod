# WolfPenis size 4 aroused east, rebuilt as a side view from ref-big-b.
# Build-CanineKnot.ps1 had replaced it with the front picture leaned up-right.
# Writes only to Staging/WolfSide4, plus a review sheet beside live sizes 3 and 5.
# The staged file was reviewed and copied into Textures by hand on 2026-10-23.
# Superseded on 2026-10-30 by Build-WolfSideEast.ps1, which rebuilds aroused east 2 to 5 from true side views.
# The picture is mirrored so the tip points right, leaned 31 degrees up-right (between sizes 3 and 5),
# fitted to the 144 px east height, and its bottom-left corner is put on the live size 4
# corner (x 242, bottom 286). The sheath and scrotum become gray so the skin tint applies;
# the red shaft stays red.
Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = "Stop"

Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;

public static class WolfSide4
{
    public static void Build(string refPath, string outPath, float targetH, float left, float bottom, float lean)
    {
        Bitmap art = Largest(Load(refPath));
        if (TipIsLeft(art))
        {
            Bitmap m = Mirror(art);
            art.Dispose();
            art = m;
        }
        Gray(art);
        float angle = ShaftAngle(art);
        // Lean is degrees from vertical toward the right. Live size 3 leans 23, size 5 leans 39.
        float rot = (-90f + lean) - angle;
        PointF c = new PointF(art.Width * 0.5f, art.Height * 0.5f);

        // Measure the rotated picture at scale 1, then fit height and corner.
        const int probe = 2048;
        RectangleF box;
        using (Bitmap test = Draw(art, probe, 1f, c, probe * 0.5f, probe * 0.5f, rot)) box = Bounds(test);
        float s = targetH / box.Height;
        float dx = left - s * (box.Left - probe * 0.5f);
        float dy = bottom - s * (box.Bottom - 1 - probe * 0.5f);
        Console.WriteLine("angle " + angle.ToString("0.0") + " rot " + rot.ToString("0.0") + " scale " + s.ToString("0.000"));

        Directory.CreateDirectory(Path.GetDirectoryName(outPath));
        using (Bitmap result = Draw(art, 512, s, c, dx, dy, rot))
        {
            result.Save(outPath, ImageFormat.Png);
            RectangleF b = Bounds(result);
            Console.WriteLine("bbox x" + b.Left + "-" + (b.Right - 1) + " y" + b.Top + "-" + (b.Bottom - 1) + " W" + b.Width + " H" + b.Height);
        }
        art.Dispose();
    }

    static bool Page(Color c)
    {
        int min = Math.Min(c.R, Math.Min(c.G, c.B));
        int max = Math.Max(c.R, Math.Max(c.G, c.B));
        return c.A < 16 || (min >= 250 && (max - min) < 10);
    }

    // Same test as Build-CanineLargePenis.ps1, used for the shaft direction.
    static bool Red(Color c)
    {
        return c.A > 16 && c.R > 165 && (c.R - Math.Max(c.G, c.B)) > 42 && c.G < 175;
    }

    // Keeps color by hue: in ref-big-b the shaft sits around 0 degrees (-10 to +5),
    // the tan sheath and scrotum around 10 to 20 degrees.
    static bool Shaft(Color c)
    {
        int max = Math.Max(c.R, Math.Max(c.G, c.B));
        int min = Math.Min(c.R, Math.Min(c.G, c.B));
        if (max != c.R || max - min < 40) return false;
        float hue = 60f * (c.G - c.B) / (max - min);
        return hue < 8f;
    }

    static void Gray(Bitmap bmp)
    {
        for (int y = 0; y < bmp.Height; y++)
        for (int x = 0; x < bmp.Width; x++)
        {
            Color c = bmp.GetPixel(x, y);
            if (c.A < 16 || Shaft(c)) continue;
            // x1.15 brings the average gray near live sizes 3 and 5 (about 182).
            int l = Math.Min(255, (int)((0.299 * c.R + 0.587 * c.G + 0.114 * c.B) * 1.15));
            bmp.SetPixel(x, y, Color.FromArgb(c.A, l, l, l));
        }
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
        int w = src.Width;
        int h = src.Height;
        int[] id = new int[w * h];
        int next = 0, best = 0, bestN = 0;
        int[] qx = new int[w * h];
        int[] qy = new int[w * h];
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
                head++;
                count++;
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

    static bool TipIsLeft(Bitmap src)
    {
        int minY = src.Height, maxY = 0;
        for (int y = 0; y < src.Height; y++)
        for (int x = 0; x < src.Width; x++)
        {
            if (!Red(src.GetPixel(x, y))) continue;
            if (y < minY) minY = y;
            if (y > maxY) maxY = y;
        }
        double topX = 0, topN = 0, botX = 0, botN = 0;
        for (int y = 0; y < src.Height; y++)
        for (int x = 0; x < src.Width; x++)
        {
            if (!Red(src.GetPixel(x, y))) continue;
            if (y <= minY + 10) { topX += x; topN++; }
            if (y >= maxY - 24) { botX += x; botN++; }
        }
        if (topN < 1 || botN < 1) return false;
        return (topX / topN) < (botX / botN);
    }

    static float ShaftAngle(Bitmap src)
    {
        int minY = src.Height, maxY = 0;
        for (int y = 0; y < src.Height; y++)
        for (int x = 0; x < src.Width; x++)
        {
            if (!Shaft(src.GetPixel(x, y))) continue;
            if (y < minY) minY = y;
            if (y > maxY) maxY = y;
        }
        int span = maxY - minY;
        int mid0 = minY + (int)(span * 0.32f);
        int mid1 = minY + (int)(span * 0.52f);
        double topX = 0, topN = 0, botX = 0, botY = 0, botN = 0;
        for (int y = 0; y < src.Height; y++)
        for (int x = 0; x < src.Width; x++)
        {
            if (!Shaft(src.GetPixel(x, y))) continue;
            if (y <= minY + 10) { topX += x; topN++; }
            if (y >= mid0 && y <= mid1) { botX += x; botY += y; botN++; }
        }
        if (topN < 1 || botN < 1) return -90f;
        return (float)(Math.Atan2(minY - (botY / botN), (topX / topN) - (botX / botN)) * 180.0 / Math.PI);
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
        System.Runtime.InteropServices.Marshal.Copy(d.Scan0, px, 0, px.Length);
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

    // Each 512 canvas at the same scale on a pale skin color, so organ sizes compare directly.
    // Guide lines mark the live size 4 corner (x 242, y 286).
    public static void Review(string[] files, string[] labels, string outPath)
    {
        const int cell = 360;
        const float zoom = 1.6f;
        const int crop = 225;
        Bitmap sheet = new Bitmap(cell * files.Length, cell + 34, PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(sheet))
        using (Font font = new Font("Segoe UI", 14f, FontStyle.Regular, GraphicsUnit.Pixel))
        using (Pen guide = new Pen(Color.FromArgb(140, 40, 90, 200), 1f))
        {
            g.Clear(Color.FromArgb(255, 236, 214, 196));
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
            for (int i = 0; i < files.Length; i++)
            {
                int x0 = i * cell;
                g.DrawString(labels[i], font, Brushes.Black, x0 + 6, 6);
                using (Bitmap part = new Bitmap(files[i]))
                {
                    RectangleF b = Bounds(part);
                    g.DrawString("W" + b.Width + " H" + b.Height, font, Brushes.Black, x0 + 6, cell + 10);
                    g.DrawImage(part, new RectangleF(x0, 30, cell, cell - 4),
                        new RectangleF(crop, 90, cell / zoom, (cell - 4) / zoom), GraphicsUnit.Pixel);
                }
                float gx = x0 + (242 - crop) * zoom;
                float gy = 30 + (286 - 90) * zoom;
                g.DrawLine(guide, gx, 30, gx, cell + 26);
                g.DrawLine(guide, x0, gy, x0 + cell, gy);
                g.DrawLine(Pens.DimGray, x0 + cell - 1, 0, x0 + cell - 1, cell + 34);
            }
        }
        sheet.Save(outPath, ImageFormat.Png);
        sheet.Dispose();
        Console.WriteLine("REVIEW " + outPath);
    }
}
'@

$art = "C:\Users\mathi\Documents\Rimworld new mods\mods\RJWAnimalTextures\ArtInventory"
$live = "C:\Users\mathi\Documents\Rimworld new mods\mods\RJWAnimalTextures\Textures\SizedApparel\BodyParts\Human\Penis\Horny"
$stage = Join-Path $art "Staging\WolfSide4"
$out = Join-Path $stage "Horny\WolfPenis_4_east.png"
[WolfSide4]::Build((Join-Path $art "TextureV2\ref-big-b.png"), $out, 144, 242, 286, 31)
[WolfSide4]::Review(
    @((Join-Path $live "WolfPenis_3_east.png"), $out, (Join-Path $live "WolfPenis_5_east.png"), (Join-Path $live "WolfPenis_4_east.png")),
    @("Live 3 east (ref-big-f)", "STAGED 4 east (ref-big-b)", "Live 5 east (ref-big-g)", "Live 4 east (front, replaced)"),
    (Join-Path $stage "review-WolfPenis_4_east.png"))
