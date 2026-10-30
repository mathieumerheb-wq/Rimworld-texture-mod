# DragonPenis replacement for Sized Apparel's DragonPenis_RNW files.
# Rest slits are written by Build-DragonSlits.ps1.
# Aroused sizes are written by Build-DragonErect.ps1.
# Running this file does not overwrite those sprites.
Write-Output "Dragon rest is Build-DragonSlits.ps1. Dragon erect is Build-DragonErect.ps1."
exit 0
# Aroused south is the whole front picture. Aroused east is the side picture mirrored, leaned to 45 degrees up-right.
# Balls are blank. Output goes to sized-apparel-zero, outside this mod.
# The previous sprites stay in sized-apparel-zero/Archive.
Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = "Stop"

Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;

public static class DragonPenis
{
    public static void Build(string slitPath, string southPath, string sidePath, string outRoot, string previewPath)
    {
        string hornyDir = Path.Combine(outRoot, "Horny");
        string ballDir = Path.Combine(outRoot, "Balls");
        Directory.CreateDirectory(outRoot);
        Directory.CreateDirectory(hornyDir);
        Directory.CreateDirectory(ballDir);
        Bitmap front = Largest(Load(southPath));
        Bitmap side = Mirror(Largest(Load(sidePath)));
        PointF frontBottom = BottomCenter(front);
        PointF sideBase;
        PointF sideTip;
        float sideAngle = Measure(side, out sideBase, out sideTip);
        float sideRot = -45f - sideAngle;
        Console.WriteLine("SIDE base " + sideBase.X.ToString("0.0") + "," + sideBase.Y.ToString("0.0")
            + " tip " + sideTip.X.ToString("0.0") + "," + sideTip.Y.ToString("0.0")
            + " angle " + sideAngle.ToString("0.0") + " rot " + sideRot.ToString("0.0"));
        for (int size = 0; size <= 5; size++)
        {
            float scale = 0.36f + size * 0.068f;
            Save(DrawAt(front, scale, frontBottom, 0f, 256f, 430f), Path.Combine(hornyDir, FileName(size, "south")));
            Save(DrawAt(side, scale, sideBase, sideRot, 230f, 420f), Path.Combine(hornyDir, FileName(size, "east")));
            Save(Blank(), Path.Combine(outRoot, FileName(size, "north")));
            Save(Blank(), Path.Combine(hornyDir, FileName(size, "north")));
            Save(Blank(), Path.Combine(ballDir, FileName(size, "south")));
            Save(Blank(), Path.Combine(ballDir, FileName(size, "east")));
            Save(Blank(), Path.Combine(ballDir, FileName(size, "north")));
        }
        BuildPreview(outRoot, previewPath);
        front.Dispose();
        side.Dispose();
    }

    static string FileName(int size, string dir)
    {
        return "DragonPenis_" + size + "_RNW_" + dir + ".png";
    }

    static bool Page(Color c)
    {
        int min = Math.Min(c.R, Math.Min(c.G, c.B));
        int max = Math.Max(c.R, Math.Max(c.G, c.B));
        return c.A < 16 || (min >= 248 && (max - min) < 14);
    }

    static bool Pink(Color c)
    {
        return c.A >= 16 && c.R > 130 && (c.R - c.G) > 25 && (c.R - c.B) > 20;
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

    static float Measure(Bitmap src, out PointF root, out PointF tip)
    {
        int minY = src.Height;
        int maxY = 0;
        for (int y = 0; y < src.Height; y++)
        for (int x = 0; x < src.Width; x++)
        {
            if (!Pink(src.GetPixel(x, y))) continue;
            if (y < minY) minY = y;
            if (y > maxY) maxY = y;
        }
        int top = minY + 36;
        int bot = maxY - 28;
        double tx = 0, ty = 0, tn = 0, bx = 0, by = 0, bn = 0;
        for (int y = 0; y < src.Height; y++)
        for (int x = 0; x < src.Width; x++)
        {
            if (!Pink(src.GetPixel(x, y))) continue;
            if (y <= top) { tx += x; ty += y; tn++; }
            if (y >= bot) { bx += x; by += y; bn++; }
        }
        tip = tn > 0 ? new PointF((float)(tx / tn), (float)(ty / tn)) : new PointF(src.Width * 0.5f, minY);
        root = bn > 0 ? new PointF((float)(bx / bn), (float)(by / bn)) : new PointF(src.Width * 0.5f, maxY);
        return (float)(Math.Atan2(tip.Y - root.Y, tip.X - root.X) * 180.0 / Math.PI);
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

    static Graphics Open(Bitmap bmp)
    {
        Graphics g = Graphics.FromImage(bmp);
        g.SmoothingMode = SmoothingMode.HighQuality;
        g.InterpolationMode = InterpolationMode.HighQualityBicubic;
        g.PixelOffsetMode = PixelOffsetMode.HighQuality;
        return g;
    }

    static Bitmap DrawAt(Bitmap art, float scale, PointF origin, float rot, float dx, float dy)
    {
        Bitmap bmp = new Bitmap(512, 512, PixelFormat.Format32bppArgb);
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
        string[] labels = new string[] { "Rest south", "Aroused south", "Rest east", "Aroused east" };
        string[] files = new string[] {
            Path.Combine(outRoot, FileName(5, "south")),
            Path.Combine(outRoot, "Horny", FileName(5, "south")),
            Path.Combine(outRoot, FileName(5, "east")),
            Path.Combine(outRoot, "Horny", FileName(5, "east"))
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
$live = "C:\Users\mathi\Documents\Rimworld new mods\sized-apparel-zero\Textures\SizedApparel\BodyParts\Human\Penis"
[DragonPenis]::Build(
    (Join-Path $inv "reference-dragon-slit.png"),
    (Join-Path $inv "reference-dragon-south.png"),
    (Join-Path $inv "reference-dragon-side.png"),
    $live,
    (Join-Path $inv "preview-DragonPenis.png"))
