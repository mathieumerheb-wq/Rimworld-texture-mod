# WolfPenis from the full references. Sizes 0 and 1 are written by Build-CanineSmallPenis.ps1.
# Size 2 keeps this art. Sizes 3 through 5 are written by Build-CanineLargePenis.ps1.
# Size 2 aroused east is replaced afterward by Build-WolfSideEast.ps1.
# Rest south is the whole sheath-and-scrotum picture.
# Rest east is that same side picture with the red shaft removed, so the sheath and scrotum stay one piece.
# Aroused south and east are the whole erect pictures, knot and scrotum included.
# Ball files are blank, so nothing is drawn on top.
Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = "Stop"

Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;

public static class WolfPenis
{
    public static void Build(string restPath, string southPath, string sidePath, string outRoot, string genePath, string previewPath)
    {
        string hornyDir = Path.Combine(outRoot, "Horny");
        string ballDir = Path.Combine(outRoot, "Balls");
        Directory.CreateDirectory(outRoot);
        Directory.CreateDirectory(hornyDir);
        Directory.CreateDirectory(ballDir);
        Bitmap rest = Largest(Load(restPath));
        Bitmap organ = Largest(Load(southPath));
        Bitmap side = Largest(Load(sidePath));
        Bitmap sideRest = Largest(DropShaft(side));
        PointF restBottom = BottomCenter(rest);
        PointF organBottom = BottomCenter(organ);
        PointF sac = SacBottom(side);
        Console.WriteLine("REST " + restBottom.X.ToString("0.0") + "," + restBottom.Y.ToString("0.0")
            + " ORGAN " + organBottom.X.ToString("0.0") + "," + organBottom.Y.ToString("0.0")
            + " SAC " + sac.X.ToString("0.0") + "," + sac.Y.ToString("0.0"));
        SaveGene(organ, genePath);
        for (int size = 2; size <= 2; size++)
        {
            float scale = 0.40f + size * 0.096f;
            Save(DrawAt(rest, scale, restBottom, 256f, 408f), Path.Combine(outRoot, "WolfPenis_" + size + "_south.png"));
            Save(DrawAt(organ, scale, organBottom, 256f, 408f), Path.Combine(hornyDir, "WolfPenis_" + size + "_south.png"));
            Save(Blank(), Path.Combine(outRoot, "WolfPenis_" + size + "_north.png"));
            Save(Blank(), Path.Combine(hornyDir, "WolfPenis_" + size + "_north.png"));
            Save(DrawAt(sideRest, scale, sac, 214f, 400f), Path.Combine(outRoot, "WolfPenis_" + size + "_east.png"));
            Save(DrawAt(side, scale, sac, 214f, 400f), Path.Combine(hornyDir, "WolfPenis_" + size + "_east.png"));
            Save(Blank(), Path.Combine(ballDir, "WolfPenis_" + size + "_south.png"));
            Save(Blank(), Path.Combine(ballDir, "WolfPenis_" + size + "_east.png"));
            Save(Blank(), Path.Combine(ballDir, "WolfPenis_" + size + "_north.png"));
        }
        BuildPreview(outRoot, previewPath);
        rest.Dispose();
        organ.Dispose();
        side.Dispose();
        sideRest.Dispose();
    }

    static bool Page(Color c)
    {
        int min = Math.Min(c.R, Math.Min(c.G, c.B));
        int max = Math.Max(c.R, Math.Max(c.G, c.B));
        return c.A < 16 || (min >= 250 && (max - min) < 14);
    }

    static bool Red(Color c)
    {
        return c.A >= 16 && c.R > 140 && (c.R - c.G) > 28;
    }

    static bool Tan(Color c)
    {
        if (Page(c)) return false;
        return (c.R - c.B) > 12 && c.G > 110 && c.R > c.G - 5;
    }

    static bool Highlight(Color c)
    {
        if (Page(c)) return false;
        int min = Math.Min(c.R, Math.Min(c.G, c.B));
        int max = Math.Max(c.R, Math.Max(c.G, c.B));
        return min > 200 && (max - min) < 24;
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

    static Bitmap DropShaft(Bitmap src)
    {
        int w = src.Width;
        int h = src.Height;
        bool[] shaft = new bool[w * h];
        int[] qx = new int[w * h];
        int[] qy = new int[w * h];
        int[] qd = new int[w * h];
        int tail = 0;
        for (int y = 0; y < h; y++)
        for (int x = 0; x < w; x++)
        {
            if (!Red(src.GetPixel(x, y))) continue;
            shaft[y * w + x] = true;
            qx[tail] = x;
            qy[tail] = y;
            qd[tail] = 0;
            tail++;
        }
        int[] dist = new int[w * h];
        for (int i = 0; i < dist.Length; i++) dist[i] = 99;
        int head = 0;
        for (int i = 0; i < tail; i++) dist[qy[i] * w + qx[i]] = 0;
        while (head < tail)
        {
            int x = qx[head];
            int y = qy[head];
            int d = qd[head];
            head++;
            if (d >= 28) continue;
            for (int oy = -1; oy <= 1; oy++)
            for (int ox = -1; ox <= 1; ox++)
            {
                int nx = x + ox;
                int ny = y + oy;
                if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue;
                if (dist[ny * w + nx] <= d + 1) continue;
                dist[ny * w + nx] = d + 1;
                qx[tail] = nx;
                qy[tail] = ny;
                qd[tail] = d + 1;
                tail++;
            }
        }
        for (int y = 0; y < h; y++)
        for (int x = 0; x < w; x++)
        {
            if (dist[y * w + x] > 28) continue;
            Color c = src.GetPixel(x, y);
            if (Page(c)) continue;
            if (Red(c)) { shaft[y * w + x] = true; continue; }
            int tanN = 0;
            for (int oy = -1; oy <= 1; oy++)
            for (int ox = -1; ox <= 1; ox++)
            {
                int nx = x + ox;
                int ny = y + oy;
                if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue;
                if (Tan(src.GetPixel(nx, ny))) tanN++;
            }
            if (tanN >= 4) continue;
            shaft[y * w + x] = true;
        }
        Bitmap bmp = new Bitmap(w, h, PixelFormat.Format32bppArgb);
        for (int y = 0; y < h; y++)
        for (int x = 0; x < w; x++)
        {
            if (shaft[y * w + x]) continue;
            Color c = src.GetPixel(x, y);
            if (c.A < 16) continue;
            bmp.SetPixel(x, y, c);
        }
        return bmp;
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

    static PointF BottomCenter(Bitmap src)
    {
        int maxY = 0;
        for (int y = 0; y < src.Height; y++)
        for (int x = 0; x < src.Width; x++)
        {
            if (src.GetPixel(x, y).A < 16) continue;
            if (y > maxY) maxY = y;
        }
        double sx = 0;
        int n = 0;
        int y0 = maxY - 6;
        if (y0 < 0) y0 = 0;
        for (int y = y0; y <= maxY; y++)
        for (int x = 0; x < src.Width; x++)
        {
            if (src.GetPixel(x, y).A < 16) continue;
            sx += x;
            n++;
        }
        if (n < 1) return new PointF(src.Width * 0.5f, maxY);
        return new PointF((float)(sx / n), maxY);
    }

    static PointF SacBottom(Bitmap src)
    {
        int maxY = 0;
        for (int y = 0; y < src.Height; y++)
        for (int x = 0; x < src.Width; x++)
        {
            Color c = src.GetPixel(x, y);
            if (!Tan(c) || Red(c)) continue;
            if (y > maxY) maxY = y;
        }
        double sx = 0;
        int n = 0;
        int y0 = maxY - 8;
        if (y0 < 0) y0 = 0;
        for (int y = y0; y <= maxY; y++)
        for (int x = 0; x < src.Width; x++)
        {
            Color c = src.GetPixel(x, y);
            if (!Tan(c) || Red(c)) continue;
            sx += x;
            n++;
        }
        if (n < 1) return BottomCenter(src);
        return new PointF((float)(sx / n), maxY);
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
        string[] labels = new string[] { "Rest south", "Aroused south", "Rest east", "Aroused east" };
        string[] files = new string[] {
            Path.Combine(outRoot, "WolfPenis_5_south.png"),
            Path.Combine(outRoot, "Horny", "WolfPenis_5_south.png"),
            Path.Combine(outRoot, "WolfPenis_5_east.png"),
            Path.Combine(outRoot, "Horny", "WolfPenis_5_east.png")
        };
        Bitmap sheet = new Bitmap(980, 980, PixelFormat.Format32bppArgb);
        using (Graphics g = Open(sheet))
        {
            g.Clear(Color.FromArgb(255, 244, 240, 236));
            using (Font font = new Font("Segoe UI", 18f, FontStyle.Regular, GraphicsUnit.Pixel))
            using (Brush brush = new SolidBrush(Color.FromArgb(255, 40, 32, 28)))
            {
                for (int i = 0; i < files.Length; i++)
                {
                    int x = 24 + (i % 2) * 480;
                    int y = 16 + (i / 2) * 480;
                    g.DrawString(labels[i], font, brush, x, y);
                    using (Bitmap part = new Bitmap(files[i]))
                    {
                        g.DrawImage(part, x, y + 28, 440, 440);
                    }
                }
            }
        }
        sheet.Save(previewPath, ImageFormat.Png);
        sheet.Dispose();
        Console.WriteLine("PREVIEW " + previewPath);
    }
}
'@

$inv = "C:\Users\mathi\Documents\Rimworld new mods\mods\RJWAnimalTextures\ArtInventory\TextureV2"
$live = "C:\Users\mathi\Documents\Rimworld new mods\mods\RJWAnimalTextures\Textures\SizedApparel\BodyParts\Human\Penis"
$gene = "C:\Users\mathi\Documents\Rimworld new mods\mods\RJWAnimalTextures\Textures\Genes\Icons\RJWAT_wolf.png"
$preview = Join-Path $inv "preview-WolfPenis.png"
[WolfPenis]::Build(
    (Join-Path $inv "reference-wolf-rest-full.png"),
    (Join-Path $inv "reference-wolf-erect-south.png"),
    (Join-Path $inv "reference-wolf-erect-side.png"),
    $live,
    $gene,
    $preview)
