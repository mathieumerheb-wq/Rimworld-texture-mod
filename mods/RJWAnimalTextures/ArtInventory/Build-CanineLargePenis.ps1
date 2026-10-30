# Sizes 3, 4, and 5 of FoxPenis and WolfPenis.
# Size 2 stays the existing species art.
# Fox size 4 aroused and wolf size 4 aroused south are written afterward by Build-CanineKnot.ps1.
# Wolf aroused east 3 to 5 from this script is replaced afterward by Build-WolfSideEast.ps1.
# Running this again brings back the older east pictures; rerun that script and promote its output after it.
# Fox uses the three slimmer front pictures. Wolf uses the three thicker side pictures.
# Each picture is stood up for south and leaned up-right for east. Balls and north are blank.
Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = "Stop"

Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;

public static class CanineLarge
{
    public static void Build(
        string fox3, string fox4, string fox5,
        string wolf3, string wolf4, string wolf5,
        string rest3, string rest4, string rest5, string restEast,
        string outRoot, string previewPath)
    {
        string hornyDir = Path.Combine(outRoot, "Horny");
        string ballDir = Path.Combine(outRoot, "Balls");
        Directory.CreateDirectory(hornyDir);
        Directory.CreateDirectory(ballDir);
        Bitmap[] fox = new Bitmap[] { Largest(Load(fox3)), Largest(Load(fox4)), Largest(Load(fox5)) };
        Bitmap[] wolf = new Bitmap[] { Largest(Load(wolf3)), Largest(Load(wolf4)), Largest(Load(wolf5)) };
        Bitmap[] rests = new Bitmap[] { Largest(Load(rest3)), Largest(Load(rest4)), Largest(Load(rest5)) };
        Bitmap sideRest = Largest(Load(restEast));
        float[] restH = new float[] { 112f, 132f, 154f };
        float[] foxErect = new float[] { 158f, 188f, 220f };
        float[] wolfErect = new float[] { 176f, 210f, 246f };
        for (int i = 0; i < 3; i++)
        {
            int size = i + 3;
            Emit("FoxPenis", size, fox[i], false, rests[i], sideRest, restH[i], foxErect[i], true, 256f, 270f, 220f, 276f, outRoot, hornyDir, ballDir);
            Emit("WolfPenis", size, wolf[i], true, rests[i], sideRest, restH[i], wolfErect[i], false, 256f, 408f, 214f, 400f, outRoot, hornyDir, ballDir);
        }
        BuildPreview(outRoot, previewPath);
        for (int i = 0; i < 3; i++) { fox[i].Dispose(); wolf[i].Dispose(); rests[i].Dispose(); }
        sideRest.Dispose();
    }

    static void Emit(string name, int size, Bitmap erect, bool faceRight, Bitmap restSouth, Bitmap restEast, float restTarget, float erectTarget, bool anchorTop, float southX, float southY, float eastX, float eastY, string outRoot, string hornyDir, string ballDir)
    {
        Bitmap art = erect;
        bool owned = false;
        if (faceRight && TipIsLeft(art))
        {
            art = Mirror(art);
            owned = true;
        }
        float angle = ShaftAngle(art);
        float southRot = -90f - angle;
        if (faceRight && angle > -65f) southRot -= 24f;
        float eastRot = -45f - angle;
        float scale = erectTarget / ContentH(art);
        float erectSouthY = anchorTop ? southY + restTarget : southY;
        float erectEastY = anchorTop ? eastY + restTarget : eastY;
        Console.WriteLine(name + " " + size + " angle " + angle.ToString("0.0") + " southRot " + southRot.ToString("0.0") + " eastRot " + eastRot.ToString("0.0"));
        string file = name + "_" + size + "_";
        SaveFitted(restSouth, restTarget, anchorTop, southX, southY, Path.Combine(outRoot, file + "south.png"));
        SaveFitted(restEast, restTarget, anchorTop, eastX, eastY, Path.Combine(outRoot, file + "east.png"));
        PointF root = BottomCenter(art);
        Save(DrawAt(art, scale, root, southX, erectSouthY, southRot), Path.Combine(hornyDir, file + "south.png"));
        Save(DrawAt(art, scale, root, eastX, erectEastY, eastRot), Path.Combine(hornyDir, file + "east.png"));
        Save(Blank(), Path.Combine(outRoot, file + "north.png"));
        Save(Blank(), Path.Combine(hornyDir, file + "north.png"));
        Save(Blank(), Path.Combine(ballDir, file + "south.png"));
        Save(Blank(), Path.Combine(ballDir, file + "east.png"));
        Save(Blank(), Path.Combine(ballDir, file + "north.png"));
        if (owned) art.Dispose();
    }

    static bool Page(Color c)
    {
        int min = Math.Min(c.R, Math.Min(c.G, c.B));
        int max = Math.Max(c.R, Math.Max(c.G, c.B));
        return c.A < 16 || (min >= 250 && (max - min) < 10);
    }

    static bool Red(Color c)
    {
        return c.A > 16 && c.R > 165 && (c.R - Math.Max(c.G, c.B)) > 42 && c.G < 175;
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

    static bool TipIsLeft(Bitmap src)
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
        int minY = src.Height;
        int maxY = 0;
        for (int y = 0; y < src.Height; y++)
        for (int x = 0; x < src.Width; x++)
        {
            if (!Red(src.GetPixel(x, y))) continue;
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
            if (!Red(src.GetPixel(x, y))) continue;
            if (y <= minY + 10) { topX += x; topN++; }
            if (y >= mid0 && y <= mid1) { botX += x; botY += y; botN++; }
        }
        if (topN < 1 || botN < 1) return -90f;
        return (float)(Math.Atan2(minY - (botY / botN), (topX / topN) - (botX / botN)) * 180.0 / Math.PI);
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
        string[] names = new string[] { "Fox 3", "Fox 4", "Fox 5", "Wolf 3", "Wolf 4", "Wolf 5" };
        string[] keys = new string[] { "FoxPenis_3", "FoxPenis_4", "FoxPenis_5", "WolfPenis_3", "WolfPenis_4", "WolfPenis_5" };
        Bitmap sheet = new Bitmap(980, 1280, PixelFormat.Format32bppArgb);
        using (Graphics g = Open(sheet))
        {
            g.Clear(Color.FromArgb(255, 244, 240, 236));
            using (Font font = new Font("Segoe UI", 16f, FontStyle.Regular, GraphicsUnit.Pixel))
            using (Brush brush = new SolidBrush(Color.FromArgb(255, 40, 32, 28)))
            {
                string[] labels = new string[] { "Rest south", "Erect south", "Rest east", "Erect east" };
                for (int i = 0; i < 4; i++) g.DrawString(labels[i], font, brush, 16 + i * 240, 4);
                for (int row = 0; row < 6; row++)
                {
                    g.DrawString(names[row], font, brush, 4, 24 + row * 208);
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
                            g.DrawImage(part, 16 + col * 240, 44 + row * 208, 190, 190);
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
[CanineLarge]::Build(
    (Join-Path $inv "ref-big-h.png"),
    (Join-Path $inv "ref-big-c.png"),
    (Join-Path $inv "ref-big-a.png"),
    (Join-Path $inv "ref-big-f.png"),
    (Join-Path $inv "ref-big-b.png"),
    (Join-Path $inv "ref-big-g.png"),
    (Join-Path $inv "ref-big-d.png"),
    (Join-Path $inv "ref-big-e.png"),
    (Join-Path $inv "ref-big-i.png"),
    (Join-Path $inv "ref-big-j.png"),
    $live,
    (Join-Path $inv "preview-CanineLarge.png"))
