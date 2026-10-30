# Sizes 0 and 1 of FoxPenis and WolfPenis.
# Size 0 rest south is the tighter slit. Size 1 rest south is the rounder scrotum.
# Rest east is the side scrotum. Aroused south and east are the short erect pictures, base included.
# Balls and north are blank. Sizes 2 through 5 are left to the fox and wolf scripts.
Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = "Stop"

Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;

public static class CanineSmall
{
    public static void Build(string rest0Path, string rest1Path, string restEastPath, string erectSouthPath, string erectEastPath, string outRoot, string previewPath)
    {
        string hornyDir = Path.Combine(outRoot, "Horny");
        string ballDir = Path.Combine(outRoot, "Balls");
        Directory.CreateDirectory(outRoot);
        Directory.CreateDirectory(hornyDir);
        Directory.CreateDirectory(ballDir);
        Bitmap rest0 = Largest(Load(rest0Path));
        Bitmap rest1 = Largest(Load(rest1Path));
        Bitmap restEast = Largest(Load(restEastPath));
        Bitmap erectSouth = Largest(Load(erectSouthPath));
        Bitmap erectEast = Largest(Load(erectEastPath));
        float erectH = ContentH(erectSouth);
        float southRot = -90f - ShaftAngle(erectSouth);
        Console.WriteLine("SOUTH rot " + southRot.ToString("0.0"));
        float[] restTarget = new float[] { 62f, 84f };
        float[] erectTarget = new float[] { 96f, 118f };
        Bitmap[] rests = new Bitmap[] { rest0, rest1 };
        for (int size = 0; size <= 1; size++)
        {
            float erectScale = erectTarget[size] / erectH;
            float foxBottom = 278f + restTarget[size];
            float foxEastBottom = 284f + restTarget[size];
            WriteSet("FoxPenis", size, rests[size], restEast, erectSouth, erectEast, restTarget[size], erectScale, southRot, true, 256f, 278f, 227f, 284f, foxBottom, foxEastBottom, outRoot, hornyDir, ballDir);
            WriteSet("WolfPenis", size, rests[size], restEast, erectSouth, erectEast, restTarget[size], erectScale, southRot, false, 256f, 408f, 214f, 400f, 408f, 400f, outRoot, hornyDir, ballDir);
        }
        BuildPreview(outRoot, previewPath);
        rest0.Dispose();
        rest1.Dispose();
        restEast.Dispose();
        erectSouth.Dispose();
        erectEast.Dispose();
    }

    static float ShaftAngle(Bitmap src)
    {
        int minY = src.Height;
        int maxY = 0;
        for (int y = 0; y < src.Height; y++)
        for (int x = 0; x < src.Width; x++)
        {
            if (!Red(src.GetPixel(x, y))) continue;
            if (y < minY) minY = y;
            if (y > maxY) maxY = y;
        }
        double topX = 0;
        double topN = 0;
        double botX = 0;
        double botY = 0;
        double botN = 0;
        int topBand = minY + 8;
        int botBand = maxY - 24;
        for (int y = 0; y < src.Height; y++)
        for (int x = 0; x < src.Width; x++)
        {
            if (!Red(src.GetPixel(x, y))) continue;
            if (y <= topBand) { topX += x; topN++; }
            if (y >= botBand) { botX += x; botY += y; botN++; }
        }
        if (topN < 1 || botN < 1) return -90f;
        return (float)(Math.Atan2(minY - (botY / botN), (topX / topN) - (botX / botN)) * 180.0 / Math.PI);
    }

    static bool Red(Color c)
    {
        return c.A > 16 && c.R > 160 && (c.R - Math.Max(c.G, c.B)) > 35;
    }

    static void WriteSet(string name, int size, Bitmap restSouth, Bitmap restEast, Bitmap erectSouth, Bitmap erectEast, float restH, float erectScale, float southRot, bool anchorTop, float southX, float southY, float eastX, float eastY, float erectSouthY, float erectEastY, string outRoot, string hornyDir, string ballDir)
    {
        string file = name + "_" + size + "_";
        SaveFitted(restSouth, restH, anchorTop, southX, southY, Path.Combine(outRoot, file + "south.png"));
        SaveFitted(restEast, restH, anchorTop, eastX, eastY, Path.Combine(outRoot, file + "east.png"));
        Save(DrawAt(erectSouth, erectScale, BottomCenter(erectSouth), southX, erectSouthY, southRot), Path.Combine(hornyDir, file + "south.png"));
        Save(DrawAt(erectEast, erectScale, BottomCenter(erectEast), eastX, erectEastY, 0f), Path.Combine(hornyDir, file + "east.png"));
        Save(Blank(), Path.Combine(outRoot, file + "north.png"));
        Save(Blank(), Path.Combine(hornyDir, file + "north.png"));
        Save(Blank(), Path.Combine(ballDir, file + "south.png"));
        Save(Blank(), Path.Combine(ballDir, file + "east.png"));
        Save(Blank(), Path.Combine(ballDir, file + "north.png"));
    }

    static bool Page(Color c)
    {
        int min = Math.Min(c.R, Math.Min(c.G, c.B));
        int max = Math.Max(c.R, Math.Max(c.G, c.B));
        return c.A < 16 || (min >= 250 && (max - min) < 10);
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

    static float ContentH(Bitmap src)
    {
        int minY = src.Height;
        int maxY = 0;
        for (int y = 0; y < src.Height; y++)
        for (int x = 0; x < src.Width; x++)
        {
            if (src.GetPixel(x, y).A < 16) continue;
            if (y < minY) minY = y;
            if (y > maxY) maxY = y;
        }
        return (maxY - minY) + 1f;
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
        int y0 = maxY - 4;
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

    static void SaveFitted(Bitmap art, float targetH, bool anchorTop, float dx, float dy, string path)
    {
        float scale = targetH / ContentH(art);
        PointF origin = anchorTop ? TopCenter(art) : BottomCenter(art);
        Save(DrawAt(art, scale, origin, dx, dy, 0f), path);
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

    static Bitmap DrawAt(Bitmap art, float scale, PointF origin, float dx, float dy, float rot)
    {
        Bitmap bmp = Canvas();
        using (Graphics g = Open(bmp))
        {
            GraphicsState state = g.Save();
            g.TranslateTransform(dx, dy);
            g.RotateTransform(rot);
            g.ScaleTransform(scale, scale);
            g.TranslateTransform(-origin.X, -origin.Y);
            g.DrawImage(art, 0, 0, art.Width, art.Height);
            g.Restore(state);
        }
        return bmp;
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
        string[] names = new string[] { "Fox 0", "Fox 1", "Wolf 0", "Wolf 1" };
        string[] keys = new string[] { "FoxPenis_0", "FoxPenis_1", "WolfPenis_0", "WolfPenis_1" };
        Bitmap sheet = new Bitmap(980, 1040, PixelFormat.Format32bppArgb);
        using (Graphics g = Open(sheet))
        {
            g.Clear(Color.FromArgb(255, 244, 240, 236));
            using (Font font = new Font("Segoe UI", 16f, FontStyle.Regular, GraphicsUnit.Pixel))
            using (Brush brush = new SolidBrush(Color.FromArgb(255, 40, 32, 28)))
            {
                string[] labels = new string[] { "Rest south", "Erect south", "Rest east", "Erect east" };
                for (int i = 0; i < 4; i++) g.DrawString(labels[i], font, brush, 16 + i * 240, 4);
                for (int row = 0; row < 4; row++)
                {
                    g.DrawString(names[row], font, brush, 4, 28 + row * 250);
                    string[] files = new string[] {
                        Path.Combine(outRoot, keys[row] + "_south.png"),
                        Path.Combine(outRoot, "Horny", keys[row] + "_south.png"),
                        Path.Combine(outRoot, keys[row] + "_east.png"),
                        Path.Combine(outRoot, "Horny", keys[row] + "_east.png")
                    };
                    for (int col = 0; col < 4; col++)
                    {
                        using (Bitmap part = new Bitmap(files[col]))
                        {
                            g.DrawImage(part, 16 + col * 240, 48 + row * 250, 220, 220);
                        }
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
[CanineSmall]::Build(
    (Join-Path $inv "reference-canine-small-rest-south-0.png"),
    (Join-Path $inv "reference-canine-small-rest-south-1.png"),
    (Join-Path $inv "reference-canine-small-rest-east.png"),
    (Join-Path $inv "reference-canine-small-erect-south.png"),
    (Join-Path $inv "reference-canine-small-erect-east.png"),
    $live,
    (Join-Path $inv "preview-CanineSmall.png"))
