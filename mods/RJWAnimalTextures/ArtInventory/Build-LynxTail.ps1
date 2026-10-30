# Retired. Rebuilding would restore the painted tail and drop the hair-color mask.
exit 0

# Lynx tail on the feline furry-tail attachment.
# East is the middle sheet tail, base at the left and tip at the right.
# South is the lower sheet tail, turned down. North mirrors south.
Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = "Stop"

Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;

public static class LynxTail
{
    public static void Build(string midPath, string lowPath, string outDir, string genePath, string catDir, string previewPath)
    {
        Directory.CreateDirectory(outDir);
        {
            Bitmap eastArt = Rotate(Largest(Load(midPath)), -14f);
            Bitmap southArt = Rotate(Largest(Load(lowPath)), 36f);
            SaveFit(eastArt, 83, 142, 366, 264, 0, Path.Combine(outDir, "LynxTail_east.png"));
            SaveFit(southArt, 20, 141, 278, 268, 2, Path.Combine(outDir, "LynxTail_south.png"));
            MirrorFile(Path.Combine(outDir, "LynxTail_south.png"), Path.Combine(outDir, "LynxTail_north.png"));
            SaveGene(eastArt, genePath);
            BuildPreview(catDir, outDir, previewPath);
            eastArt.Dispose();
            southArt.Dispose();
        }
    }

    static bool Page(Color c)
    {
        int min = Math.Min(c.R, Math.Min(c.G, c.B));
        int max = Math.Max(c.R, Math.Max(c.G, c.B));
        return c.A < 16 || (min >= 246 && (max - min) < 16);
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

    static void Content(Bitmap art, out int minX, out int minY, out int maxX, out int maxY)
    {
        minX = art.Width;
        minY = art.Height;
        maxX = -1;
        maxY = -1;
        for (int y = 0; y < art.Height; y++)
        for (int x = 0; x < art.Width; x++)
        {
            if (art.GetPixel(x, y).A < 16) continue;
            if (x < minX) minX = x;
            if (y < minY) minY = y;
            if (x > maxX) maxX = x;
            if (y > maxY) maxY = y;
        }
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

    static Bitmap Rotate(Bitmap src, float degrees)
    {
        int minX, minY, maxX, maxY;
        Content(src, out minX, out minY, out maxX, out maxY);
        float cx = (minX + maxX) * 0.5f;
        float cy = (minY + maxY) * 0.5f;
        double rad = degrees * Math.PI / 180.0;
        float c = (float)Math.Cos(rad);
        float s = (float)Math.Sin(rad);
        float minRX = float.MaxValue, minRY = float.MaxValue, maxRX = float.MinValue, maxRY = float.MinValue;
        float[] xs = new float[] { minX, maxX, minX, maxX };
        float[] ys = new float[] { minY, minY, maxY, maxY };
        for (int i = 0; i < 4; i++)
        {
            float dx = xs[i] - cx;
            float dy = ys[i] - cy;
            float rx = cx + dx * c - dy * s;
            float ry = cy + dx * s + dy * c;
            if (rx < minRX) minRX = rx;
            if (ry < minRY) minRY = ry;
            if (rx > maxRX) maxRX = rx;
            if (ry > maxRY) maxRY = ry;
        }
        int bw = (int)Math.Ceiling(maxRX - minRX) + 4;
        int bh = (int)Math.Ceiling(maxRY - minRY) + 4;
        Bitmap bmp = new Bitmap(bw, bh, PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(bmp))
        {
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
            g.PixelOffsetMode = PixelOffsetMode.HighQuality;
            g.TranslateTransform(-minRX + 2f, -minRY + 2f);
            g.TranslateTransform(cx, cy);
            g.RotateTransform(degrees);
            g.TranslateTransform(-cx, -cy);
            g.DrawImage(src, 0, 0, src.Width, src.Height);
        }
        src.Dispose();
        return bmp;
    }

    static void SaveFit(Bitmap art, int boxX, int boxY, int boxW, int boxH, int align, string path)
    {
        int minX, minY, maxX, maxY;
        Content(art, out minX, out minY, out maxX, out maxY);
        float contentW = Math.Max(1, maxX - minX + 1);
        float contentH = Math.Max(1, maxY - minY + 1);
        float scale = Math.Min(boxW / contentW, boxH / contentH);
        Bitmap bmp = new Bitmap(512, 512, PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(bmp))
        {
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
            g.PixelOffsetMode = PixelOffsetMode.HighQuality;
            float dw = art.Width * scale;
            float dh = art.Height * scale;
            float dx = boxX - minX * scale;
            float dy = boxY - minY * scale;
            if (align == 0) dy += (boxH - contentH * scale) * 0.5f;
            if (align == 2)
            {
                dx += (boxW - contentW * scale) * 0.5f;
                dy += (boxH - contentH * scale) * 0.5f;
            }
            g.DrawImage(art, dx, dy, dw, dh);
        }
        bmp.Save(path, ImageFormat.Png);
        bmp.Dispose();
    }

    static void MirrorFile(string sourcePath, string destPath)
    {
        using (Bitmap src = new Bitmap(sourcePath))
        {
            Bitmap bmp = new Bitmap(src.Width, src.Height, PixelFormat.Format32bppArgb);
            using (Graphics g = Graphics.FromImage(bmp))
            {
                g.TranslateTransform(src.Width, 0);
                g.ScaleTransform(-1f, 1f);
                g.DrawImage(src, 0, 0, src.Width, src.Height);
            }
            bmp.Save(destPath, ImageFormat.Png);
            bmp.Dispose();
        }
    }

    static void SaveGene(Bitmap art, string path)
    {
        int minX, minY, maxX, maxY;
        Content(art, out minX, out minY, out maxX, out maxY);
        float contentW = Math.Max(1, maxX - minX + 1);
        float contentH = Math.Max(1, maxY - minY + 1);
        float scale = Math.Min(460f / contentW, 220f / contentH);
        Bitmap bmp = new Bitmap(512, 512, PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(bmp))
        {
            g.Clear(Color.FromArgb(255, 46, 42, 40));
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
            float dx = 256f - ((minX + maxX) * 0.5f) * scale;
            float dy = 256f - ((minY + maxY) * 0.5f) * scale;
            g.DrawImage(art, dx, dy, art.Width * scale, art.Height * scale);
        }
        string dir = Path.GetDirectoryName(path);
        if (!string.IsNullOrEmpty(dir)) Directory.CreateDirectory(dir);
        bmp.Save(path, ImageFormat.Png);
        bmp.Dispose();
    }

    static void BuildPreview(string catDir, string outDir, string previewPath)
    {
        string[] names = new string[] { "south", "east", "north" };
        Bitmap sheet = new Bitmap(1100, 1680, PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(sheet))
        {
            g.Clear(Color.FromArgb(255, 28, 28, 32));
            g.InterpolationMode = InterpolationMode.NearestNeighbor;
            using (Font font = new Font("Segoe UI", 20f, FontStyle.Regular, GraphicsUnit.Pixel))
            using (Brush brush = new SolidBrush(Color.FromArgb(255, 230, 226, 220)))
            {
                for (int i = 0; i < names.Length; i++)
                {
                    int y = 16 + i * 550;
                    g.DrawString("Feline " + names[i], font, brush, 24, y);
                    g.DrawString("Lynx " + names[i], font, brush, 560, y);
                    using (Bitmap cat = new Bitmap(Path.Combine(catDir, "FurryTail_" + names[i] + ".png")))
                    using (Bitmap lynx = new Bitmap(Path.Combine(outDir, "LynxTail_" + names[i] + ".png")))
                    {
                        g.DrawImage(cat, 24, y + 28, 500, 500);
                        g.DrawImage(lynx, 560, y + 28, 500, 500);
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
$out = "C:\Users\mathi\Documents\Rimworld new mods\mods\RJWAnimalTextures\Textures\Things\Pawn\Humanlike\BodyAttachments\LynxTail"
$gene = "C:\Users\mathi\Documents\Rimworld new mods\mods\RJWAnimalTextures\Textures\Genes\Icons\RJWAT_lynx_tail.png"
$cat = "C:\Program Files (x86)\Steam\steamapps\common\RimWorld\Mods\sized-apparel-zero\Textures\Things\Pawn\Humanlike\BodyAttachments\FurryTail"
[LynxTail]::Build(
    (Join-Path $inv "reference-lynx-tail-mid.png"),
    (Join-Path $inv "reference-lynx-tail-low.png"),
    $out,
    $gene,
    $cat,
    (Join-Path $inv "preview-LynxTail.png"))
