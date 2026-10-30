# DemonTentaclePenis. The gene picture itself, stamped and placed.
# Rest keeps the pale opening from the picture, with a little red around it. Aroused keeps the whole tentacle.
# South points up. East keeps the picture's own up-right angle.
# DemonTentaclePenis is not in BodypartDetail_Penis.xml, so the filenames have no variation suffix.
# Ball files are blank, so the human balls do not draw. North penis files are blank 4x4.
Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = "Stop"

Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;

public static class DemonTentaclePenis
{
    static Bitmap Art;
    static Bitmap RestArt;
    static PointF Anchor;
    static float SourceAngle;

    public static void Build(string sourcePath, string penisRoot, string previewPath)
    {
        string hornyDir = Path.Combine(penisRoot, "Horny");
        string balls = Path.Combine(penisRoot, "Balls");
        Directory.CreateDirectory(penisRoot);
        Directory.CreateDirectory(hornyDir);
        Directory.CreateDirectory(balls);
        using (Bitmap source = new Bitmap(sourcePath))
        {
            Prepare(source);
            for (int size = 0; size <= 5; size++)
            {
                float scale = 0.16f + size * 0.055f;
                Save(Render(scale, false, false), Path.Combine(penisRoot, "DemonTentaclePenis_" + size + "_south.png"));
                Save(Render(scale, true, false), Path.Combine(penisRoot, "DemonTentaclePenis_" + size + "_east.png"));
                Save(Blank(), Path.Combine(penisRoot, "DemonTentaclePenis_" + size + "_north.png"));
                Save(Render(scale, false, true), Path.Combine(hornyDir, "DemonTentaclePenis_" + size + "_south.png"));
                Save(Render(scale, true, true), Path.Combine(hornyDir, "DemonTentaclePenis_" + size + "_east.png"));
                Save(Blank(), Path.Combine(hornyDir, "DemonTentaclePenis_" + size + "_north.png"));
                Save(Blank(), Path.Combine(balls, "DemonTentaclePenis_" + size + "_south.png"));
                Save(Blank(), Path.Combine(balls, "DemonTentaclePenis_" + size + "_east.png"));
                Save(Blank(), Path.Combine(balls, "DemonTentaclePenis_" + size + "_north.png"));
            }
        }
        Art.Dispose();
        RestArt.Dispose();
        BuildPreview(penisRoot, previewPath);
    }

    static void Prepare(Bitmap source)
    {
        int minX = source.Width, minY = source.Height, maxX = -1, maxY = -1, n = 0;
        for (int y = 0; y < source.Height; y++)
        for (int x = 0; x < source.Width; x++)
        {
            if (source.GetPixel(x, y).A < 16) continue;
            n++;
            if (x < minX) minX = x;
            if (y < minY) minY = y;
            if (x > maxX) maxX = x;
            if (y > maxY) maxY = y;
        }
        if (n == 0) throw new InvalidOperationException("No pixels in the tentacle icon.");
        int baseLimit = minX + (int)((maxX - minX) * 0.10f);
        double bsx = 0, bsy = 0;
        int bn = 0;
        for (int y = minY; y <= maxY; y++)
        for (int x = minX; x <= baseLimit; x++)
        {
            if (source.GetPixel(x, y).A < 16) continue;
            bsx += x;
            bsy += y;
            bn++;
        }
        float ax = (float)(bsx / bn);
        float ay = (float)(bsy / bn);
        Anchor = new PointF(ax, ay);
        float far = -1f, tipX = ax, tipY = ay;
        for (int y = minY; y <= maxY; y++)
        for (int x = minX; x <= maxX; x++)
        {
            if (source.GetPixel(x, y).A < 16) continue;
            float dx = x - ax;
            float dy = y - ay;
            float d = dx * dx + dy * dy;
            if (d > far)
            {
                far = d;
                tipX = x;
                tipY = y;
            }
        }
        SourceAngle = (float)(Math.Atan2(-(tipY - ay), tipX - ax) * 180.0 / Math.PI);
        double rad = SourceAngle * Math.PI / 180.0;
        float ux = (float)Math.Cos(rad);
        float uy = -(float)Math.Sin(rad);
        float maxAlong = 0f;
        float uxAlong = ux;
        float uyAlong = uy;
        int[] rimX = new int[2000];
        int[] rimY = new int[2000];
        int rimN = 0;
        for (int y = 0; y < source.Height; y++)
        for (int x = 0; x < source.Width; x++)
        {
            Color c = source.GetPixel(x, y);
            if (c.A < 16) continue;
            float along = (x - ax) * uxAlong + (y - ay) * uyAlong;
            if (along > maxAlong) maxAlong = along;
            if (c.R > 170 && c.G > 120 && along < 80f)
            {
                rimX[rimN] = x;
                rimY[rimN] = y;
                rimN++;
            }
        }
        Art = new Bitmap(source);
        RestArt = new Bitmap(source.Width, source.Height, PixelFormat.Format32bppArgb);
        float reach = 30f;
        for (int y = 0; y < source.Height; y++)
        for (int x = 0; x < source.Width; x++)
        {
            Color c = source.GetPixel(x, y);
            if (c.A < 16)
            {
                RestArt.SetPixel(x, y, Color.Transparent);
                continue;
            }
            float best = reach * reach;
            for (int i = 0; i < rimN; i++)
            {
                float dx = x - rimX[i];
                float dy = y - rimY[i];
                float d2 = dx * dx + dy * dy;
                if (d2 < best) best = d2;
                if (best < 9f) break;
            }
            float dist = (float)Math.Sqrt(best);
            if (dist >= reach)
            {
                RestArt.SetPixel(x, y, Color.Transparent);
                continue;
            }
            float keep = dist <= 16f ? 1f : (reach - dist) / (reach - 16f);
            int a = (int)(c.A * keep);
            if (a < 16) RestArt.SetPixel(x, y, Color.Transparent);
            else RestArt.SetPixel(x, y, Color.FromArgb(a, c.R, c.G, c.B));
        }
        Console.WriteLine("ANCHOR " + ax.ToString("0.0") + "," + ay.ToString("0.0") + " tip " + tipX.ToString("0") + "," + tipY.ToString("0") + " angle " + SourceAngle.ToString("0.0") + " along " + maxAlong.ToString("0.0") + " rim " + rimN);
    }

    static Bitmap Render(float scale, bool east, bool horny)
    {
        Bitmap bmp = new Bitmap(512, 512, PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(bmp))
        {
            g.Clear(Color.Transparent);
            g.TranslateTransform(east ? 246f : 256f, 286f);
            g.RotateTransform(SourceAngle - (east ? SourceAngle : 90f));
            g.ScaleTransform(scale, scale);
            g.TranslateTransform(-Anchor.X, -Anchor.Y);
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
            g.PixelOffsetMode = PixelOffsetMode.HighQuality;
            g.DrawImage(horny ? Art : RestArt, 0, 0);
        }
        for (int y = 0; y < bmp.Height; y++)
        for (int x = 0; x < bmp.Width; x++)
        {
            Color c = bmp.GetPixel(x, y);
            if (c.A > 0 && c.A < 24)
                bmp.SetPixel(x, y, Color.Transparent);
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

    static void Content(Bitmap bmp, out int minX, out int minY, out int maxX, out int maxY, out int count)
    {
        minX = bmp.Width;
        minY = bmp.Height;
        maxX = -1;
        maxY = -1;
        count = 0;
        if (bmp.Width <= 8) return;
        for (int y = 0; y < bmp.Height; y++)
        for (int x = 0; x < bmp.Width; x++)
        {
            if (bmp.GetPixel(x, y).A < 16) continue;
            count++;
            if (x < minX) minX = x;
            if (y < minY) minY = y;
            if (x > maxX) maxX = x;
            if (y > maxY) maxY = y;
        }
    }

    static void BuildPreview(string penisRoot, string previewPath)
    {
        string[] labels = new string[] { "Rest south", "Rest east", "Aroused south", "Aroused east" };
        string[] dirs = new string[] { "south", "east", "south", "east" };
        bool[] horny = new bool[] { false, false, true, true };
        int winL = 511, winT = 511, winR = 0, winB = 0;
        for (int row = 0; row < dirs.Length; row++)
        for (int size = 0; size <= 5; size++)
        {
            string folder = horny[row] ? Path.Combine(penisRoot, "Horny") : penisRoot;
            using (Bitmap bmp = new Bitmap(Path.Combine(folder, "DemonTentaclePenis_" + size + "_" + dirs[row] + ".png")))
            {
                int minX, minY, maxX, maxY, count;
                Content(bmp, out minX, out minY, out maxX, out maxY, out count);
                if (count == 0) continue;
                if (size == 0 || size == 5)
                    Console.WriteLine(labels[row] + " " + size + " box " + minX + "," + minY + "-" + maxX + "," + maxY + " n " + count);
                if (minX < winL) winL = minX;
                if (minY < winT) winT = minY;
                if (maxX > winR) winR = maxX;
                if (maxY > winB) winB = maxY;
            }
        }
        Rectangle window = Rectangle.FromLTRB(Math.Max(0, winL - 8), Math.Max(0, winT - 8), Math.Min(512, winR + 9), Math.Min(512, winB + 9));
        Bitmap sheet = new Bitmap(1200, 860, PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(sheet))
        using (Font font = new Font("Segoe UI", 12f, FontStyle.Regular, GraphicsUnit.Pixel))
        using (Brush brush = new SolidBrush(Color.FromArgb(255, 220, 220, 220)))
        {
            g.Clear(Color.FromArgb(255, 18, 18, 22));
            g.InterpolationMode = InterpolationMode.NearestNeighbor;
            g.PixelOffsetMode = PixelOffsetMode.Half;
            for (int row = 0; row < dirs.Length; row++)
            {
                g.DrawString(labels[row], font, brush, new RectangleF(16f, 8f + row * 210f, 180f, 20f));
                for (int size = 0; size <= 5; size++)
                {
                    string folder = horny[row] ? Path.Combine(penisRoot, "Horny") : penisRoot;
                    using (Bitmap bmp = new Bitmap(Path.Combine(folder, "DemonTentaclePenis_" + size + "_" + dirs[row] + ".png")))
                    {
                        Rectangle cell = new Rectangle(16 + size * 196, 28 + row * 210, 180, 170);
                        float fit = Math.Min(cell.Width / (float)window.Width, cell.Height / (float)window.Height);
                        int pw = Math.Max(1, (int)(window.Width * fit));
                        int ph = Math.Max(1, (int)(window.Height * fit));
                        g.DrawImage(bmp, new Rectangle(cell.X + (cell.Width - pw) / 2, cell.Y + (cell.Height - ph) / 2, pw, ph), window, GraphicsUnit.Pixel);
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

$source = "C:\Program Files (x86)\Steam\steamapps\common\RimWorld\Mods\rjw-genes\Common\Textures\Genes\Icons\Genitalia_tentacle_icon.png"
$ref = "C:\Users\mathi\Documents\Rimworld new mods\mods\RJWAnimalTextures\ArtInventory\TextureV2\reference-Genitalia_tentacle_icon.png"
Copy-Item -LiteralPath $source -Destination $ref -Force
$dest = "C:\Users\mathi\Documents\Rimworld new mods\mods\RJWAnimalTextures\Textures\SizedApparel\BodyParts\Human\Penis"
$preview = "C:\Users\mathi\Documents\Rimworld new mods\mods\RJWAnimalTextures\ArtInventory\TextureV2\preview-DemonTentaclePenis.png"
[DemonTentaclePenis]::Build($source, $dest, $preview)
