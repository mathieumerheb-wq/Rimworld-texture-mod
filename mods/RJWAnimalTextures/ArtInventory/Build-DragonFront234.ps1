# Replaces dragon erect south sizes 2, 3, and 4 with front views.
# Reads TextureV2 refs. Writes the live horny south files in sized-apparel-zero.
Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = "Stop"

Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;

public static class DragonFront234
{
    public static void Build(string[] sources, int[] sizes, int[] heights, int[] bases, string hornyDir, string previewPath)
    {
        for (int i = 0; i < sources.Length; i++)
        {
            Bitmap art = Knockout(sources[i]);
            int minX, minY, maxX, maxY;
            Bounds(art, out minX, out minY, out maxX, out maxY);
            int ch = maxY - minY + 1;
            float scale = heights[i] / (float)ch;
            float originX = (minX + maxX) * 0.5f;
            float originY = maxY;
            Bitmap placed = new Bitmap(512, 512, PixelFormat.Format32bppArgb);
            using (Graphics g = Graphics.FromImage(placed))
            {
                g.SmoothingMode = SmoothingMode.HighQuality;
                g.InterpolationMode = InterpolationMode.HighQualityBicubic;
                g.PixelOffsetMode = PixelOffsetMode.HighQuality;
                g.TranslateTransform(256f, bases[i]);
                g.ScaleTransform(scale, scale);
                g.TranslateTransform(-originX, -originY);
                g.DrawImage(art, 0, 0, art.Width, art.Height);
            }
            art.Dispose();
            GraySheath(placed);
            int pMinX, pMinY, pMaxX, pMaxY;
            Bounds(placed, out pMinX, out pMinY, out pMaxX, out pMaxY);
            string path = Path.Combine(hornyDir, "DragonPenis_" + sizes[i] + "_RNW_south.png");
            placed.Save(path, ImageFormat.Png);
            placed.Dispose();
            Console.WriteLine("size " + sizes[i]
                + " h " + (pMaxY - pMinY + 1)
                + " base " + pMaxY
                + " cx " + ((pMinX + pMaxX) * 0.5).ToString("0.0")
                + " x " + pMinX + "-" + pMaxX
                + " y " + pMinY + "-" + pMaxY);
        }
        Preview(hornyDir, previewPath);
    }

    static bool Background(Color c)
    {
        if (c.A < 16) return true;
        int min = Math.Min((int)c.R, Math.Min((int)c.G, (int)c.B));
        int max = Math.Max((int)c.R, Math.Max((int)c.G, (int)c.B));
        return min >= 236 && (max - min) < 24;
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
                TrySeed(source, bg, qx, qy, ref tail, x, 0);
                TrySeed(source, bg, qx, qy, ref tail, x, h - 1);
            }
            for (int y = 0; y < h; y++)
            {
                TrySeed(source, bg, qx, qy, ref tail, 0, y);
                TrySeed(source, bg, qx, qy, ref tail, w - 1, y);
            }
            int head = 0;
            while (head < tail)
            {
                int x = qx[head];
                int y = qy[head];
                head++;
                if (x > 0) TrySeed(source, bg, qx, qy, ref tail, x - 1, y);
                if (x + 1 < w) TrySeed(source, bg, qx, qy, ref tail, x + 1, y);
                if (y > 0) TrySeed(source, bg, qx, qy, ref tail, x, y - 1);
                if (y + 1 < h) TrySeed(source, bg, qx, qy, ref tail, x, y + 1);
            }
            Bitmap bmp = new Bitmap(w, h, PixelFormat.Format32bppArgb);
            for (int y = 0; y < h; y++)
            for (int x = 0; x < w; x++)
            {
                if (bg[y * w + x]) continue;
                Color c = source.GetPixel(x, y);
                bmp.SetPixel(x, y, Color.FromArgb(255, c.R, c.G, c.B));
            }
            return bmp;
        }
    }

    static void TrySeed(Bitmap src, bool[] bg, int[] qx, int[] qy, ref int tail, int x, int y)
    {
        int i = y * src.Width + x;
        if (bg[i]) return;
        if (!Background(src.GetPixel(x, y))) return;
        bg[i] = true;
        qx[tail] = x;
        qy[tail] = y;
        tail++;
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
    }

    static void GraySheath(Bitmap bmp)
    {
        for (int y = 0; y < bmp.Height; y++)
        for (int x = 0; x < bmp.Width; x++)
        {
            Color c = bmp.GetPixel(x, y);
            if (c.A < 16) continue;
            int r = c.R;
            int g = c.G;
            int b = c.B;
            if (r < 1) continue;
            float redness = (r - Math.Max(g, b)) / (float)r;
            if (redness > 0.34f) continue;
            int luma = (r * 299 + g * 587 + b * 114) / 1000;
            bmp.SetPixel(x, y, Color.FromArgb(c.A, luma, luma, luma));
        }
    }

    static void Preview(string hornyDir, string previewPath)
    {
        Bitmap sheet = new Bitmap(6 * 180, 220, PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(sheet))
        {
            g.Clear(Color.FromArgb(255, 28, 24, 32));
            g.InterpolationMode = InterpolationMode.NearestNeighbor;
            g.PixelOffsetMode = PixelOffsetMode.Half;
            using (Font font = new Font("Segoe UI", 14f, FontStyle.Regular, GraphicsUnit.Pixel))
            using (Brush brush = new SolidBrush(Color.White))
            {
                for (int size = 0; size <= 5; size++)
                {
                    string path = Path.Combine(hornyDir, "DragonPenis_" + size + "_RNW_south.png");
                    using (Bitmap part = new Bitmap(path))
                    {
                        g.DrawString("south " + size, font, brush, new RectangleF(size * 180, 2, 160, 20));
                        g.DrawImage(part, size * 180 + 10, 24, 160, 160);
                    }
                }
            }
        }
        sheet.Save(previewPath, ImageFormat.Png);
        sheet.Dispose();
    }
}
'@

$inv = "C:\Users\mathi\Documents\Rimworld new mods\mods\RJWAnimalTextures\ArtInventory\TextureV2"
$horny = "C:\Users\mathi\Documents\Rimworld new mods\sized-apparel-zero\Textures\SizedApparel\BodyParts\Human\Penis\Horny"
$sources = @(
    (Join-Path $inv "ref-dragon-front-s2.png"),
    (Join-Path $inv "ref-dragon-front-s3.png"),
    (Join-Path $inv "ref-dragon-front-s4.png")
)
# Size 2 stays at the average height. Sizes 3 and 4 are the large and huge fronts, drawn taller.
[DragonFront234]::Build($sources, @(2, 3, 4), @(66, 143, 166), @(268, 268, 268), $horny, (Join-Path $inv "preview-DragonFront234.png"))
