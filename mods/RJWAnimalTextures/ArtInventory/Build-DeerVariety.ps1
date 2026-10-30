# Deer sizes 0, 1, and 2. Sizes 3 to 5 stay the long deer from Build-DeerPenis.ps1.
# Size 0 is the shortest erect. Size 1 is the longer thin one. Size 2 is the one middle erect.
# Balls and north stay blank.
# East output from this script is placed at x 220 and rest east faces backward. Build-DeerEastFix.ps1
# corrected the live files on 2026-10-24. Running this again brings both back; rerun that fix after it.
Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = "Stop"

Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;

public static class DeerVariety
{
    public static void Build(
        string restFront0, string restSide0,
        string restFront1, string restSide1,
        string erect0, string erect1,
        string erectMid, string erectMidSide,
        string outRoot, string previewPath)
    {
        string horny = Path.Combine(outRoot, "Horny");
        string balls = Path.Combine(outRoot, "Balls");
        Directory.CreateDirectory(horny);
        Directory.CreateDirectory(balls);
        Bitmap rf0 = Largest(Load(restFront0));
        Bitmap rs0 = Largest(Load(restSide0));
        Bitmap rf1 = Largest(Load(restFront1));
        Bitmap rs1 = Largest(Load(restSide1));
        Bitmap e0 = Largest(Load(erect0));
        Bitmap e1 = Largest(Load(erect1));
        Bitmap mid = Largest(Load(erectMid));
        Bitmap midSide = Largest(Load(erectMidSide));
        Emit("0", rf0, rs0, e0, e0, true, true, 50f, 74f, outRoot, horny, balls);
        Emit("1", rf0, rs0, e1, e1, true, true, 64f, 94f, outRoot, horny, balls);
        Emit("2", rf1, rs1, mid, midSide, false, true, 80f, 116f, outRoot, horny, balls);
        BuildPreview(outRoot, previewPath);
        rf0.Dispose(); rs0.Dispose(); rf1.Dispose(); rs1.Dispose();
        e0.Dispose(); e1.Dispose(); mid.Dispose(); midSide.Dispose();
    }

    static void Emit(string size, Bitmap restFront, Bitmap restSide, Bitmap south, Bitmap east, bool southFace, bool eastFace, float restH, float erectH, string outRoot, string horny, string balls)
    {
        Bitmap southArt = Prepare(south, southFace);
        Bitmap eastArt = Prepare(east, eastFace);
        bool ownSouth = !object.ReferenceEquals(southArt, south);
        bool ownEast = !object.ReferenceEquals(eastArt, east) && !object.ReferenceEquals(eastArt, southArt);
        float southRot = -90f - ShaftAngle(southArt);
        float eastRot = -45f - ShaftAngle(eastArt);
        Console.WriteLine("Deer " + size + " southRot " + southRot.ToString("0.0") + " eastRot " + eastRot.ToString("0.0"));
        string file = "DeerPenis_" + size + "_";
        SaveFitted(restFront, restH, 256f, 286f, Path.Combine(outRoot, file + "south.png"));
        SaveFitted(restSide, restH, 220f, 300f, Path.Combine(outRoot, file + "east.png"));
        float southScale = erectH / ContentH(southArt);
        float eastScale = erectH / ContentH(eastArt);
        Save(DrawAt(southArt, southScale, BottomCenter(southArt), 256f, 286f, southRot), Path.Combine(horny, file + "south.png"));
        Save(DrawAt(eastArt, eastScale, BottomCenter(eastArt), 220f, 300f, eastRot), Path.Combine(horny, file + "east.png"));
        Save(Blank(), Path.Combine(outRoot, file + "north.png"));
        Save(Blank(), Path.Combine(horny, file + "north.png"));
        Save(Blank(), Path.Combine(balls, file + "south.png"));
        Save(Blank(), Path.Combine(balls, file + "east.png"));
        Save(Blank(), Path.Combine(balls, file + "north.png"));
        if (ownSouth) southArt.Dispose();
        if (ownEast) eastArt.Dispose();
    }

    static Bitmap Prepare(Bitmap src, bool faceRight)
    {
        if (faceRight && TipIsLeft(src)) return Mirror(src);
        return src;
    }

    static bool Page(Color c)
    {
        int min = Math.Min(c.R, Math.Min(c.G, c.B));
        int max = Math.Max(c.R, Math.Max(c.G, c.B));
        return c.A < 16 || (min >= 248 && (max - min) < 12);
    }

    static bool Red(Color c)
    {
        return c.A > 16 && c.R > 160 && (c.R - Math.Max(c.G, c.B)) > 36 && c.G < 180;
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

    static void Ends(Bitmap src, out PointF tip, out PointF root)
    {
        double sx = 0, sy = 0, sn = 0;
        for (int y = 0; y < src.Height; y++)
        for (int x = 0; x < src.Width; x++)
        {
            Color c = src.GetPixel(x, y);
            if (c.A < 16 || Red(c)) continue;
            sx += x; sy += y; sn++;
        }
        float rx = sn > 0 ? (float)(sx / sn) : src.Width * 0.5f;
        float ry = sn > 0 ? (float)(sy / sn) : src.Height * 0.5f;
        double best = -1;
        int tx = (int)rx, ty = (int)ry;
        for (int y = 0; y < src.Height; y++)
        for (int x = 0; x < src.Width; x++)
        {
            if (!Red(src.GetPixel(x, y))) continue;
            double d = (x - rx) * (x - rx) + (y - ry) * (y - ry);
            if (d > best) { best = d; tx = x; ty = y; }
        }
        tip = new PointF(tx, ty);
        root = new PointF(rx, ry);
    }

    static bool TipIsLeft(Bitmap src)
    {
        PointF tip, root;
        Ends(src, out tip, out root);
        return tip.X < root.X - 6f;
    }

    static float ShaftAngle(Bitmap src)
    {
        PointF tip, root;
        Ends(src, out tip, out root);
        return (float)(Math.Atan2(tip.Y - root.Y, tip.X - root.X) * 180.0 / Math.PI);
    }

    static float ContentH(Bitmap src)
    {
        int minY = src.Height, maxY = 0;
        for (int y = 0; y < src.Height; y++)
        for (int x = 0; x < src.Width; x++)
        {
            if (src.GetPixel(x, y).A < 16) continue;
            if (y < minY) minY = y;
            if (y > maxY) maxY = y;
        }
        return (maxY - minY) + 1f;
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
        double sx = 0; int n = 0;
        int y0 = maxY - 4; if (y0 < 0) y0 = 0;
        for (int y = y0; y <= maxY; y++)
        for (int x = 0; x < src.Width; x++)
        {
            if (src.GetPixel(x, y).A < 16) continue;
            sx += x; n++;
        }
        if (n < 1) return new PointF(src.Width * 0.5f, maxY);
        return new PointF((float)(sx / n), maxY);
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
                int px = qx[head], py = qy[head]; head++; count++;
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

    static void SaveFitted(Bitmap art, float targetH, float dx, float dy, string path)
    {
        Save(DrawAt(art, targetH / ContentH(art), BottomCenter(art), dx, dy, 0f), path);
    }

    static Bitmap DrawAt(Bitmap art, float scale, PointF origin, float dx, float dy, float rot)
    {
        Bitmap bmp = new Bitmap(512, 512, PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(bmp))
        {
            g.SmoothingMode = SmoothingMode.HighQuality;
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
            g.PixelOffsetMode = PixelOffsetMode.HighQuality;
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
        Bitmap sheet = new Bitmap(980, 760, PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(sheet))
        {
            g.Clear(Color.FromArgb(255, 244, 240, 236));
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
            using (Font font = new Font("Segoe UI", 16f, FontStyle.Regular, GraphicsUnit.Pixel))
            using (Brush brush = new SolidBrush(Color.FromArgb(255, 40, 32, 28)))
            {
                string[] labels = new string[] { "Rest south", "Erect south", "Rest east", "Erect east" };
                for (int i = 0; i < 4; i++) g.DrawString(labels[i], font, brush, 16 + i * 240, 4);
                for (int row = 0; row < 3; row++)
                {
                    string key = "DeerPenis_" + row;
                    g.DrawString("Size " + row, font, brush, 4, 28 + row * 240);
                    string[] files = new string[] {
                        Path.Combine(outRoot, key + "_south.png"),
                        Path.Combine(outRoot, "Horny", key + "_south.png"),
                        Path.Combine(outRoot, key + "_east.png"),
                        Path.Combine(outRoot, "Horny", key + "_east.png")
                    };
                    for (int col = 0; col < 4; col++)
                    {
                        using (Bitmap part = new Bitmap(files[col]))
                            g.DrawImage(part, 16 + col * 240, 52 + row * 240, 210, 210);
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
[DeerVariety]::Build(
    (Join-Path $inv "ref-deer-rest-front-small.png"),
    (Join-Path $inv "ref-deer-rest-side-small.png"),
    (Join-Path $inv "ref-deer-rest-front-open.png"),
    (Join-Path $inv "ref-deer-rest-side-open.png"),
    (Join-Path $inv "ref-deer-erect-small.png"),
    (Join-Path $inv "ref-deer-erect-small-long.png"),
    (Join-Path $inv "ref-deer-erect-mid.png"),
    (Join-Path $inv "ref-deer-erect-mid-side.png"),
    $live,
    (Join-Path $inv "preview-DeerVariety.png"))
