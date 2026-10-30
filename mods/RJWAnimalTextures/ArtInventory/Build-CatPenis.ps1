# Builds the CatPenis replacement for the Sized Apparel paste folder.
# Reads TextureV2 refs. Writes sized-apparel-zero Textures. Balls and north are blank.
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = "Stop"

Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;

public static class CatPenisBuild
{
    public static void Sprite(string source, string dest, string mode, int targetH, int baseY)
    {
        Bitmap art = Largest(Knockout(source));
        if (mode == "east" || mode == "rest-east")
        {
            if (PinkIsLeft(art)) art = Mirror(art);
        }
        float rot = 0f;
        if (mode == "south" || mode == "east")
        {
            float angle = ShaftAngle(art);
            float target = mode == "south" ? -90f : -45f;
            rot = target - angle;
            if (mode == "south" && Math.Abs(angle + 90f) < 4f) rot = 0f;
            Console.WriteLine(Path.GetFileName(dest) + " angle " + angle.ToString("0.0") + " rot " + rot.ToString("0.0"));
        }
        Bitmap turned = Rotate(art, rot);
        art.Dispose();
        Bitmap placed = Fit(turned, targetH, baseY, mode == "east" || mode == "rest-east");
        turned.Dispose();
        GrayFur(placed);
        int minX, minY, maxX, maxY;
        Bounds(placed, out minX, out minY, out maxX, out maxY);
        Directory.CreateDirectory(Path.GetDirectoryName(dest));
        placed.Save(dest, ImageFormat.Png);
        placed.Dispose();
        Console.WriteLine("  h " + (maxY - minY + 1) + " base " + maxY + " x " + minX + "-" + maxX + " cx " + ((minX + maxX) * 0.5).ToString("0.0"));
    }

    public static void Blank(string dest)
    {
        Directory.CreateDirectory(Path.GetDirectoryName(dest));
        using (Bitmap bmp = new Bitmap(4, 4, PixelFormat.Format32bppArgb))
        {
            bmp.Save(dest, ImageFormat.Png);
        }
    }

    static bool Background(Color c)
    {
        if (c.A < 16) return true;
        int min = Math.Min((int)c.R, Math.Min((int)c.G, (int)c.B));
        int max = Math.Max((int)c.R, Math.Max((int)c.G, (int)c.B));
        return min >= 236 && (max - min) < 24;
    }

    static bool Pink(Color c)
    {
        if (c.A < 16 || c.R < 150) return false;
        float redness = (c.R - Math.Max((int)c.G, (int)c.B)) / (float)c.R;
        return redness >= 0.16f;
    }

    static Bitmap Knockout(string path)
    {
        using (Bitmap source = new Bitmap(path))
        {
            int w = source.Width;
            int h = source.Height;
            bool[] bg = new bool[w * h];
            int[] qx = new int[w * h];
            int[] qy = new int[w * h];
            int tail = 0;
            for (int x = 0; x < w; x++)
            {
                Seed(source, bg, qx, qy, ref tail, x, 0);
                Seed(source, bg, qx, qy, ref tail, x, h - 1);
            }
            for (int y = 0; y < h; y++)
            {
                Seed(source, bg, qx, qy, ref tail, 0, y);
                Seed(source, bg, qx, qy, ref tail, w - 1, y);
            }
            int head = 0;
            while (head < tail)
            {
                int x = qx[head];
                int y = qy[head];
                head++;
                if (x > 0) Seed(source, bg, qx, qy, ref tail, x - 1, y);
                if (x + 1 < w) Seed(source, bg, qx, qy, ref tail, x + 1, y);
                if (y > 0) Seed(source, bg, qx, qy, ref tail, x, y - 1);
                if (y + 1 < h) Seed(source, bg, qx, qy, ref tail, x, y + 1);
            }
            Bitmap bmp = new Bitmap(w, h, PixelFormat.Format32bppArgb);
            for (int y = 0; y < h; y++)
            for (int x = 0; x < w; x++)
            {
                if (bg[y * w + x]) continue;
                Color c = source.GetPixel(x, y);
                if (Background(c)) continue;
                bmp.SetPixel(x, y, Color.FromArgb(255, c.R, c.G, c.B));
            }
            return bmp;
        }
    }

    static void Seed(Bitmap src, bool[] bg, int[] qx, int[] qy, ref int tail, int x, int y)
    {
        int i = y * src.Width + x;
        if (bg[i]) return;
        if (!Background(src.GetPixel(x, y))) return;
        bg[i] = true;
        qx[tail] = x;
        qy[tail] = y;
        tail++;
    }

    static Bitmap Largest(Bitmap src)
    {
        int w = src.Width;
        int h = src.Height;
        int[] id = new int[w * h];
        int next = 0;
        int best = 0;
        int bestN = 0;
        int[] qx = new int[w * h];
        int[] qy = new int[w * h];
        for (int y = 0; y < h; y++)
        for (int x = 0; x < w; x++)
        {
            if (src.GetPixel(x, y).A < 16 || id[y * w + x] != 0) continue;
            next++;
            int head = 0;
            int tail = 0;
            qx[tail] = x;
            qy[tail] = y;
            tail++;
            id[y * w + x] = next;
            int count = 0;
            while (head < tail)
            {
                int cx = qx[head];
                int cy = qy[head];
                head++;
                count++;
                for (int dy = -1; dy <= 1; dy++)
                for (int dx = -1; dx <= 1; dx++)
                {
                    int nx = cx + dx;
                    int ny = cy + dy;
                    if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue;
                    int ni = ny * w + nx;
                    if (id[ni] != 0) continue;
                    if (src.GetPixel(nx, ny).A < 16) continue;
                    id[ni] = next;
                    qx[tail] = nx;
                    qy[tail] = ny;
                    tail++;
                }
            }
            if (count > bestN)
            {
                bestN = count;
                best = next;
            }
        }
        Bitmap bmp = new Bitmap(w, h, PixelFormat.Format32bppArgb);
        for (int y = 0; y < h; y++)
        for (int x = 0; x < w; x++)
        {
            if (id[y * w + x] != best) continue;
            bmp.SetPixel(x, y, src.GetPixel(x, y));
        }
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
            if (c.A < 16) continue;
            bmp.SetPixel(src.Width - 1 - x, y, c);
        }
        src.Dispose();
        return bmp;
    }

    static bool PinkIsLeft(Bitmap src)
    {
        double px = 0, pn = 0, cx = 0, cn = 0;
        for (int y = 0; y < src.Height; y++)
        for (int x = 0; x < src.Width; x++)
        {
            Color c = src.GetPixel(x, y);
            if (c.A < 16) continue;
            cx += x;
            cn++;
            if (!Pink(c)) continue;
            px += x;
            pn++;
        }
        if (pn < 8 || cn < 8) return false;
        return (px / pn) < (cx / cn) - 4.0;
    }

    static float ShaftAngle(Bitmap src)
    {
        double rx = 0, ry = 0, rn = 0;
        for (int y = 0; y < src.Height; y++)
        for (int x = 0; x < src.Width; x++)
        {
            Color c = src.GetPixel(x, y);
            if (c.A < 16 || Pink(c)) continue;
            rx += x;
            ry += y;
            rn++;
        }
        if (rn < 8)
        {
            rx = src.Width * 0.5;
            ry = src.Height * 0.75;
        }
        else
        {
            rx /= rn;
            ry /= rn;
        }
        double best = 1;
        for (int y = 0; y < src.Height; y++)
        for (int x = 0; x < src.Width; x++)
        {
            if (!Pink(src.GetPixel(x, y))) continue;
            double d = (x - rx) * (x - rx) + (y - ry) * (y - ry);
            if (d > best) best = d;
        }
        double tx = 0, ty = 0, tn = 0;
        double keep = best * 0.72;
        for (int y = 0; y < src.Height; y++)
        for (int x = 0; x < src.Width; x++)
        {
            if (!Pink(src.GetPixel(x, y))) continue;
            double d = (x - rx) * (x - rx) + (y - ry) * (y - ry);
            if (d < keep) continue;
            tx += x;
            ty += y;
            tn++;
        }
        if (tn < 1) return -90f;
        return (float)(Math.Atan2((ty / tn) - ry, (tx / tn) - rx) * 180.0 / Math.PI);
    }

    static Bitmap Rotate(Bitmap src, float rot)
    {
        if (Math.Abs(rot) < 0.5f)
        {
            Bitmap copy = new Bitmap(src.Width, src.Height, PixelFormat.Format32bppArgb);
            using (Graphics g = Graphics.FromImage(copy))
            {
                g.DrawImage(src, 0, 0, src.Width, src.Height);
            }
            return copy;
        }
        int side = Math.Max(src.Width, src.Height) * 3;
        Bitmap bmp = new Bitmap(side, side, PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(bmp))
        {
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
            g.PixelOffsetMode = PixelOffsetMode.HighQuality;
            g.SmoothingMode = SmoothingMode.HighQuality;
            g.TranslateTransform(side * 0.5f, side * 0.5f);
            g.RotateTransform(rot);
            g.TranslateTransform(-src.Width * 0.5f, -src.Height * 0.5f);
            g.DrawImage(src, 0, 0, src.Width, src.Height);
        }
        return bmp;
    }

    static void Bounds(Bitmap src, out int minX, out int minY, out int maxX, out int maxY)
    {
        minX = src.Width;
        minY = src.Height;
        maxX = -1;
        maxY = -1;
        for (int y = 0; y < src.Height; y++)
        for (int x = 0; x < src.Width; x++)
        {
            if (src.GetPixel(x, y).A < 16) continue;
            if (x < minX) minX = x;
            if (y < minY) minY = y;
            if (x > maxX) maxX = x;
            if (y > maxY) maxY = y;
        }
        if (maxX < 0)
        {
            minX = 0;
            minY = 0;
            maxX = 1;
            maxY = 1;
        }
    }

    static Bitmap Fit(Bitmap src, int targetH, int baseY, bool east)
    {
        int minX, minY, maxX, maxY;
        Bounds(src, out minX, out minY, out maxX, out maxY);
        int cw = maxX - minX + 1;
        int ch = maxY - minY + 1;
        float scale = targetH / (float)ch;
        float dw = cw * scale;
        float dh = ch * scale;
        float dx = east ? 221f : 256f - dw * 0.5f;
        float dy = baseY - dh;
        Bitmap bmp = new Bitmap(512, 512, PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(bmp))
        {
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
            g.PixelOffsetMode = PixelOffsetMode.HighQuality;
            g.SmoothingMode = SmoothingMode.HighQuality;
            g.DrawImage(src, new RectangleF(dx, dy, dw, dh), new RectangleF(minX, minY, cw, ch), GraphicsUnit.Pixel);
        }
        return bmp;
    }

    static void GrayFur(Bitmap bmp)
    {
        for (int y = 0; y < bmp.Height; y++)
        for (int x = 0; x < bmp.Width; x++)
        {
            Color c = bmp.GetPixel(x, y);
            if (c.A < 16) continue;
            int r = c.R;
            int gch = c.G;
            int b = c.B;
            if (r < 1) continue;
            float redness = (r - Math.Max(gch, b)) / (float)r;
            int luma = (r * 299 + gch * 587 + b * 114) / 1000;
            if (redness > 0.15f) continue;
            if (luma > 225) continue;
            bmp.SetPixel(x, y, Color.FromArgb(c.A, luma, luma, luma));
        }
    }
}
'@

$v2 = "C:\Users\mathi\Documents\Rimworld new mods\mods\RJWAnimalTextures\ArtInventory\TextureV2"
$live = "C:\Users\mathi\Documents\Rimworld new mods\sized-apparel-zero\Textures\SizedApparel\BodyParts\Human\Penis"
$horny = Join-Path $live "Horny"
$balls = Join-Path $live "Balls"
$southH = @(40, 46, 64, 79, 92, 120)
$restH = @(27, 37, 59, 61, 67, 81)
$southBase = @(268, 268, 268, 268, 268, 282)
$eastBase = @(282, 282, 286, 286, 286, 300)
$eastRest = @("e0", "e0", "e0", "e3", "e4", "e5")

for ($i = 0; $i -le 5; $i++) {
    $southName = "CatPenis_{0}_RNW_south.png" -f $i
    $eastName = "CatPenis_{0}_RNW_east.png" -f $i
    $northName = "CatPenis_{0}_RNW_north.png" -f $i
    [CatPenisBuild]::Sprite((Join-Path $v2 ("ref-cat-erect-s{0}.png" -f $i)), (Join-Path $horny $southName), "south", $southH[$i], $southBase[$i])
    [CatPenisBuild]::Sprite((Join-Path $v2 ("ref-cat-erect-e{0}.png" -f $i)), (Join-Path $horny $eastName), "east", $southH[$i], $eastBase[$i])
    [CatPenisBuild]::Blank((Join-Path $horny $northName))
    [CatPenisBuild]::Sprite((Join-Path $v2 ("ref-cat-rest-s{0}.png" -f $i)), (Join-Path $live $southName), "rest-south", $restH[$i], $southBase[$i])
    [CatPenisBuild]::Sprite((Join-Path $v2 ("ref-cat-rest-{0}.png" -f $eastRest[$i])), (Join-Path $live $eastName), "rest-east", $restH[$i], $eastBase[$i])
    [CatPenisBuild]::Blank((Join-Path $live $northName))
    [CatPenisBuild]::Blank((Join-Path $balls $southName))
    [CatPenisBuild]::Blank((Join-Path $balls $eastName))
    [CatPenisBuild]::Blank((Join-Path $balls $northName))
}

Write-Output "cat sprites written"
