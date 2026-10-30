# FoxPenis from the five supplied pictures. Sizes 0 and 1 are written by Build-CanineSmallPenis.ps1.
# Size 2 keeps this art. Sizes 3 through 5 are written by Build-CanineLargePenis.ps1.
# Rest south and rest east are the scrotum pictures. South and east ball files are blank, so the erect pictures are not given a second scrotum.
# Aroused south is the whole front picture, knot included, pointing up.
# Aroused east is the whole side picture, mirrored so the tip points up-right.
# North balls are the rear scrotum. North penis is blank.
Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = "Stop"

Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;

public static class FoxPenis
{
    public static void Build(string southPath, string restPath, string rearPath, string sidePath, string sideBallPath, string outRoot, string genePath, string previewPath)
    {
        string hornyDir = Path.Combine(outRoot, "Horny");
        string ballDir = Path.Combine(outRoot, "Balls");
        Directory.CreateDirectory(outRoot);
        Directory.CreateDirectory(hornyDir);
        Directory.CreateDirectory(ballDir);
        using (Bitmap south = Load(southPath))
        using (Bitmap rest = Load(restPath))
        using (Bitmap rear = Load(rearPath))
        using (Bitmap sideSrc = Load(sidePath))
        using (Bitmap sideBall = Load(sideBallPath))
        {
            Bitmap organ = Largest(KeepRows(south, 0, south.Height));
            Bitmap frontSac = Largest(KeepRows(rest, 0, rest.Height));
            Bitmap rearSac = Largest(KeepRows(rear, 0, rear.Height));
            Bitmap eastSac = Largest(KeepRows(sideBall, 0, sideBall.Height));
            Bitmap mirrored = Mirror(sideSrc);
            Bitmap sideOrgan = Largest(KeepRows(mirrored, 0, mirrored.Height));
            PointF southRoot = BottomCenter(organ);
            PointF sideBalls = TanCenter(sideOrgan);
            PointF frontJoin = new PointF(52f, 32f);
            PointF frontBottom = BottomCenter(frontSac);
            PointF nub = FindNub(eastSac);
            PointF sacCenter = OpaqueCenter(eastSac);
            PointF rearTop = TopCenter(rearSac);
            Console.WriteLine("SOUTH root " + southRoot.X.ToString("0.0") + "," + southRoot.Y.ToString("0.0")
                + " SIDE balls " + sideBalls.X.ToString("0.0") + "," + sideBalls.Y.ToString("0.0")
                + " nub " + nub.X.ToString("0.0") + "," + nub.Y.ToString("0.0"));
            SaveGene(south, genePath);
            for (int size = 2; size <= 2; size++)
            {
                float scale = 0.48f + size * 0.134f;
                float southY = 292f + (frontBottom.Y - frontJoin.Y) * scale;
                float eastX = 246f + (sacCenter.X - nub.X) * scale;
                float eastY = 292f + (sacCenter.Y - nub.Y) * scale;
                Save(DrawAt(frontSac, scale, frontJoin, 256f, 292f), Path.Combine(outRoot, "FoxPenis_" + size + "_south.png"));
                Save(DrawAt(organ, scale, southRoot, 256f, southY), Path.Combine(hornyDir, "FoxPenis_" + size + "_south.png"));
                Save(Blank(), Path.Combine(outRoot, "FoxPenis_" + size + "_north.png"));
                Save(Blank(), Path.Combine(hornyDir, "FoxPenis_" + size + "_north.png"));
                Save(DrawAt(eastSac, scale, nub, 246f, 292f), Path.Combine(outRoot, "FoxPenis_" + size + "_east.png"));
                Save(DrawAt(sideOrgan, scale, sideBalls, eastX, eastY), Path.Combine(hornyDir, "FoxPenis_" + size + "_east.png"));
                Save(Blank(), Path.Combine(ballDir, "FoxPenis_" + size + "_south.png"));
                Save(Blank(), Path.Combine(ballDir, "FoxPenis_" + size + "_east.png"));
                Save(DrawAt(rearSac, scale, rearTop, 256f, 318f), Path.Combine(ballDir, "FoxPenis_" + size + "_north.png"));
            }
            BuildPreview(outRoot, previewPath);
            organ.Dispose();
            frontSac.Dispose();
            rearSac.Dispose();
            eastSac.Dispose();
            mirrored.Dispose();
            sideOrgan.Dispose();
        }
    }

    static bool Page(Color c)
    {
        int min = Math.Min(c.R, Math.Min(c.G, c.B));
        int max = Math.Max(c.R, Math.Max(c.G, c.B));
        return c.A < 16 || (min >= 236 && (max - min) < 28);
    }

    static bool Pink(Color c)
    {
        return c.A > 16 && c.R > 155 && (c.R - c.G) > 40 && c.G < 185;
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

    static Bitmap KeepRows(Bitmap src, int y0, int y1)
    {
        Bitmap bmp = new Bitmap(src.Width, src.Height, PixelFormat.Format32bppArgb);
        for (int y = y0; y < y1 && y < src.Height; y++)
        for (int x = 0; x < src.Width; x++)
        {
            Color c = src.GetPixel(x, y);
            if (c.A < 16) continue;
            bmp.SetPixel(x, y, c);
        }
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
        return bmp;
    }

    static void FadeBottom(Bitmap bmp, int rows)
    {
        int maxY = 0;
        for (int y = 0; y < bmp.Height; y++)
        for (int x = 0; x < bmp.Width; x++)
        {
            if (bmp.GetPixel(x, y).A < 16) continue;
            if (y > maxY) maxY = y;
        }
        int start = maxY - rows;
        if (start < 0) start = 0;
        for (int y = start; y <= maxY; y++)
        for (int x = 0; x < bmp.Width; x++)
        {
            Color c = bmp.GetPixel(x, y);
            if (c.A < 16) continue;
            float along = (maxY - y) / (float)rows;
            int alpha = (int)(c.A * along);
            if (alpha < 8) bmp.SetPixel(x, y, Color.Transparent);
            else bmp.SetPixel(x, y, Color.FromArgb(alpha, c.R, c.G, c.B));
        }
    }

    static PointF FindNub(Bitmap src)
    {
        double sx = 0, sy = 0, n = 0;
        for (int y = 24; y <= 42; y++)
        for (int x = 70; x < src.Width; x++)
        {
            if (!Pink(src.GetPixel(x, y))) continue;
            sx += x;
            sy += y;
            n++;
        }
        if (n < 1) return new PointF(80f, 32f);
        return new PointF((float)(sx / n), (float)(sy / n));
    }

    static PointF BottomCenter(Bitmap src)
    {
        int maxY = 0;
        for (int y = 0; y < src.Height; y++)
        for (int x = 0; x < src.Width; x++)
        {
            if (src.GetPixel(x, y).A < 16) continue;
            if (y > maxY) maxY = y;
        }
        double sx = 0, sy = 0, n = 0;
        for (int y = maxY - 3; y <= maxY; y++)
        for (int x = 0; x < src.Width; x++)
        {
            if (y < 0 || src.GetPixel(x, y).A < 16) continue;
            sx += x;
            sy += y;
            n++;
        }
        if (n < 1) return new PointF(src.Width * 0.5f, maxY);
        return new PointF((float)(sx / n), (float)(sy / n));
    }

    static PointF OpaqueCenter(Bitmap src)
    {
        return Average(src, false);
    }

    static PointF TanCenter(Bitmap src)
    {
        return Average(src, true);
    }

    static PointF Average(Bitmap src, bool tanOnly)
    {
        double sx = 0, sy = 0, n = 0;
        for (int y = 0; y < src.Height; y++)
        for (int x = 0; x < src.Width; x++)
        {
            Color c = src.GetPixel(x, y);
            if (c.A < 16) continue;
            if (tanOnly && Pink(c)) continue;
            sx += x;
            sy += y;
            n++;
        }
        if (n < 1) return new PointF(src.Width * 0.5f, src.Height * 0.5f);
        return new PointF((float)(sx / n), (float)(sy / n));
    }

    static PointF RootOf(Bitmap src)
    {
        int maxY = 0;
        for (int y = 0; y < src.Height; y++)
        for (int x = 0; x < src.Width; x++)
        {
            if (src.GetPixel(x, y).A < 16) continue;
            if (y > maxY) maxY = y;
        }
        int minX = src.Width;
        int y0 = maxY - 16;
        if (y0 < 0) y0 = 0;
        for (int y = y0; y <= maxY; y++)
        for (int x = 0; x < src.Width; x++)
        {
            if (src.GetPixel(x, y).A < 16) continue;
            if (x < minX) minX = x;
        }
        double sx = 0, sy = 0, n = 0;
        for (int y = y0; y <= maxY; y++)
        for (int x = minX; x <= minX + 12 && x < src.Width; x++)
        {
            if (src.GetPixel(x, y).A < 16) continue;
            sx += x;
            sy += y;
            n++;
        }
        if (n < 1) return new PointF(minX, maxY);
        return new PointF((float)(sx / n), (float)(sy / n));
    }

    static PointF TopCenter(Bitmap src)
    {
        int minY = src.Height;
        double sx = 0;
        int n = 0;
        for (int y = 0; y < src.Height; y++)
        for (int x = 0; x < src.Width; x++)
        {
            if (src.GetPixel(x, y).A < 16) continue;
            if (y < minY) { minY = y; sx = 0; n = 0; }
            if (y == minY) { sx += x; n++; }
        }
        if (n < 1) return new PointF(src.Width * 0.5f, 0f);
        return new PointF((float)(sx / n), minY);
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
            int count = 0;
            qx[tail] = x;
            qy[tail] = y;
            tail++;
            id[y * w + x] = next;
            while (head < tail)
            {
                int px = qx[head];
                int py = qy[head];
                head++;
                count++;
                for (int oy = -1; oy <= 1; oy++)
                for (int ox = -1; ox <= 1; ox++)
                {
                    int nx = px + ox;
                    int ny = py + oy;
                    if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue;
                    if (id[ny * w + nx] != 0) continue;
                    if (src.GetPixel(nx, ny).A < 16) continue;
                    id[ny * w + nx] = next;
                    qx[tail] = nx;
                    qy[tail] = ny;
                    tail++;
                }
            }
            if (count > bestN) { bestN = count; best = next; }
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

    static Bitmap Canvas()
    {
        return new Bitmap(512, 512, PixelFormat.Format32bppArgb);
    }

    static Graphics Open(Bitmap bmp)
    {
        Graphics g = Graphics.FromImage(bmp);
        g.SmoothingMode = SmoothingMode.HighQuality;
        g.InterpolationMode = InterpolationMode.HighQualityBicubic;
        g.PixelOffsetMode = PixelOffsetMode.HighQuality;
        return g;
    }

    static Bitmap DrawAt(Bitmap art, float scale, PointF origin, float dx, float dy)
    {
        Bitmap bmp = Canvas();
        using (Graphics g = Open(bmp))
        {
            GraphicsState state = g.Save();
            g.TranslateTransform(dx, dy);
            g.ScaleTransform(scale, scale);
            g.TranslateTransform(-origin.X, -origin.Y);
            g.DrawImage(art, 0, 0, art.Width, art.Height);
            g.Restore(state);
        }
        return bmp;
    }

    static void SaveGene(Bitmap south, string path)
    {
        Bitmap bmp = Canvas();
        using (Graphics g = Open(bmp))
        {
            float scale = 440f / south.Height;
            float dw = south.Width * scale;
            float dh = south.Height * scale;
            g.DrawImage(south, (512f - dw) * 0.5f, (512f - dh) * 0.5f, dw, dh);
        }
        string dir = Path.GetDirectoryName(path);
        if (!string.IsNullOrEmpty(dir)) Directory.CreateDirectory(dir);
        Save(bmp, path);
        bmp.Dispose();
    }

    static Bitmap Blank()
    {
        return new Bitmap(4, 4, PixelFormat.Format32bppArgb);
    }

    static void Save(Bitmap bmp, string path)
    {
        bmp.Save(path, ImageFormat.Png);
        bmp.Dispose();
    }

    static void BuildPreview(string outRoot, string previewPath)
    {
        Bitmap sheet = new Bitmap(980, 1480, PixelFormat.Format32bppArgb);
        using (Graphics g = Open(sheet))
        {
            g.Clear(Color.FromArgb(255, 244, 240, 236));
            using (Font font = new Font("Segoe UI", 18f, FontStyle.Regular, GraphicsUnit.Pixel))
            using (Brush brush = new SolidBrush(Color.FromArgb(255, 40, 32, 28)))
            {
                g.DrawString("Fox layered size 5", font, brush, 24, 8);
                DrawLayer(g, Path.Combine(outRoot, "Balls", "FoxPenis_5_south.png"), Path.Combine(outRoot, "FoxPenis_5_south.png"), 24, 36);
                DrawLayer(g, Path.Combine(outRoot, "Balls", "FoxPenis_5_south.png"), Path.Combine(outRoot, "Horny", "FoxPenis_5_south.png"), 500, 36);
                DrawLayer(g, Path.Combine(outRoot, "Balls", "FoxPenis_5_east.png"), Path.Combine(outRoot, "FoxPenis_5_east.png"), 24, 520);
                DrawLayer(g, Path.Combine(outRoot, "Balls", "FoxPenis_5_east.png"), Path.Combine(outRoot, "Horny", "FoxPenis_5_east.png"), 500, 520);
                g.DrawString("North balls", font, brush, 24, 1000);
                using (Bitmap north = new Bitmap(Path.Combine(outRoot, "Balls", "FoxPenis_5_north.png")))
                {
                    g.DrawImage(north, 24, 1028, 300, 300);
                }
            }
        }
        sheet.Save(previewPath, ImageFormat.Png);
        sheet.Dispose();
        Console.WriteLine("PREVIEW " + previewPath);
    }

    static void DrawLayer(Graphics g, string back, string front, int x, int y)
    {
        using (Bitmap a = new Bitmap(back))
        using (Bitmap b = new Bitmap(front))
        {
            g.DrawImage(a, x, y, 460, 460);
            g.DrawImage(b, x, y, 460, 460);
        }
    }
}
'@

$inv = "C:\Users\mathi\Documents\Rimworld new mods\mods\RJWAnimalTextures\ArtInventory\TextureV2"
$live = "C:\Users\mathi\Documents\Rimworld new mods\mods\RJWAnimalTextures\Textures\SizedApparel\BodyParts\Human\Penis"
$gene = "C:\Users\mathi\Documents\Rimworld new mods\mods\RJWAnimalTextures\Textures\Genes\Icons\RJWAT_fox.png"
$preview = Join-Path $inv "preview-FoxPenis.png"
[FoxPenis]::Build(
    (Join-Path $inv "reference-fox-south.png"),
    (Join-Path $inv "reference-fox-rest.png"),
    (Join-Path $inv "reference-fox-rear.png"),
    (Join-Path $inv "reference-fox-side.png"),
    (Join-Path $inv "reference-fox-sideball.png"),
    $live,
    $gene,
    $preview)
