# NeedlePenis. The gene picture itself, stamped and placed.
# Rest is the pale bulb. Aroused is the whole icon, bulb and red shaft together.
# South points up. East keeps the picture's own up-right angle.
# NeedlePenis is not in BodypartDetail_Penis.xml, so the filenames have no variation suffix.
# Ball files are blank. North penis files are blank 4x4.
Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = "Stop"

Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;

public static class NeedlePenis
{
    static Bitmap Art;
    static Bitmap RestArt;
    static Bitmap ShaftArt;
    static PointF Anchor;
    static float SourceAngle;
    static float Ax;
    static float Ay;

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
                float scale = 0.17f + size * 0.058f;
                Save(Render(scale, false, RestArt), Path.Combine(penisRoot, "NeedlePenis_" + size + "_south.png"));
                Save(Render(scale, true, RestArt), Path.Combine(penisRoot, "NeedlePenis_" + size + "_east.png"));
                Save(Blank(), Path.Combine(penisRoot, "NeedlePenis_" + size + "_north.png"));
                Save(Render(scale, false, Art), Path.Combine(hornyDir, "NeedlePenis_" + size + "_south.png"));
                Save(Render(scale, true, Art), Path.Combine(hornyDir, "NeedlePenis_" + size + "_east.png"));
                Save(Blank(), Path.Combine(hornyDir, "NeedlePenis_" + size + "_north.png"));
                Save(Blank(), Path.Combine(balls, "NeedlePenis_" + size + "_south.png"));
                Save(Blank(), Path.Combine(balls, "NeedlePenis_" + size + "_east.png"));
                Save(Blank(), Path.Combine(balls, "NeedlePenis_" + size + "_north.png"));
            }
        }
        Art.Dispose();
        RestArt.Dispose();
        ShaftArt.Dispose();
        BuildPreview(penisRoot, previewPath);
    }

    static bool Pale(Color c)
    {
        return c.A >= 16 && c.R > 140 && c.G > 90 && c.G > c.B && c.R > c.G - 10;
    }

    static void Prepare(Bitmap source)
    {
        double sx = 0, sy = 0;
        int n = 0;
        int minX = source.Width, minY = source.Height, maxX = -1, maxY = -1;
        for (int y = 0; y < source.Height; y++)
        for (int x = 0; x < source.Width; x++)
        {
            Color c = source.GetPixel(x, y);
            if (c.A < 16) continue;
            if (x < minX) minX = x;
            if (y < minY) minY = y;
            if (x > maxX) maxX = x;
            if (y > maxY) maxY = y;
            if (!Pale(c)) continue;
            sx += x;
            sy += y;
            n++;
        }
        if (n == 0) throw new InvalidOperationException("No pale sheath pixels in the needle icon.");
        float ax = (float)(sx / n);
        float ay = (float)(sy / n);
        Anchor = new PointF(ax, ay);
        float far = -1f;
        float tipX = ax;
        float tipY = ay;
        for (int y = minY; y <= maxY; y++)
        for (int x = minX; x <= maxX; x++)
        {
            Color c = source.GetPixel(x, y);
            if (c.A < 16 || Pale(c)) continue;
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
        float vx = tipX - ax;
        float vy = tipY - ay;
        SourceAngle = (float)(Math.Atan2(-vy, vx) * 180.0 / Math.PI);
        double rad = SourceAngle * Math.PI / 180.0;
        Ax = (float)Math.Cos(rad);
        Ay = -(float)Math.Sin(rad);
        float maxPale = 0f;
        for (int y = minY; y <= maxY; y++)
        for (int x = minX; x <= maxX; x++)
        {
            Color c = source.GetPixel(x, y);
            if (c.A < 16 || !Pale(c)) continue;
            float along = (x - ax) * Ax + (y - ay) * Ay;
            if (along > maxPale) maxPale = along;
        }
        int[] paleX = new int[n];
        int[] paleY = new int[n];
        int pi = 0;
        for (int y = minY; y <= maxY; y++)
        for (int x = minX; x <= maxX; x++)
        {
            if (!Pale(source.GetPixel(x, y))) continue;
            paleX[pi] = x;
            paleY[pi] = y;
            pi++;
        }
        Art = new Bitmap(source);
        RestArt = new Bitmap(source.Width, source.Height, PixelFormat.Format32bppArgb);
        for (int y = 0; y < source.Height; y++)
        for (int x = 0; x < source.Width; x++)
        {
            Color c = source.GetPixel(x, y);
            if (c.A < 16)
            {
                RestArt.SetPixel(x, y, Color.Transparent);
                continue;
            }
            if (Pale(c))
            {
                RestArt.SetPixel(x, y, c);
                continue;
            }
            bool outline = c.R < 80 && c.G < 80 && c.B < 80;
            if (!outline)
            {
                RestArt.SetPixel(x, y, Color.Transparent);
                continue;
            }
            float along = (x - ax) * Ax + (y - ay) * Ay;
            if (along > maxPale + 2f)
            {
                RestArt.SetPixel(x, y, Color.Transparent);
                continue;
            }
            float best = 16f;
            for (int i = 0; i < pi; i++)
            {
                float dx = x - paleX[i];
                float dy = y - paleY[i];
                float d2 = dx * dx + dy * dy;
                if (d2 < best) best = d2;
            }
            if (best > 9f) RestArt.SetPixel(x, y, Color.Transparent);
            else RestArt.SetPixel(x, y, c);
        }
        ShaftArt = new Bitmap(source.Width, source.Height, PixelFormat.Format32bppArgb);
        for (int y = 0; y < source.Height; y++)
        for (int x = 0; x < source.Width; x++)
        {
            Color c = source.GetPixel(x, y);
            if (c.A < 16 || RestArt.GetPixel(x, y).A >= 16)
                ShaftArt.SetPixel(x, y, Color.Transparent);
            else
                ShaftArt.SetPixel(x, y, c);
        }
        Console.WriteLine("ANCHOR " + ax.ToString("0.0") + "," + ay.ToString("0.0") + " tip " + tipX.ToString("0") + "," + tipY.ToString("0") + " angle " + SourceAngle.ToString("0.0") + " pale " + maxPale.ToString("0.0"));
    }

    static Bitmap Render(float scale, bool east, Bitmap art)
    {
        Bitmap bmp = new Bitmap(512, 512, PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(bmp))
        {
            g.Clear(Color.Transparent);
            g.TranslateTransform(east ? 248f : 256f, 272f);
            g.RotateTransform(SourceAngle - (east ? SourceAngle : 90f));
            g.ScaleTransform(scale, scale);
            g.TranslateTransform(-Anchor.X, -Anchor.Y);
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
            g.PixelOffsetMode = PixelOffsetMode.HighQuality;
            g.DrawImage(art, 0, 0);
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

    static void BuildPreview(string penisRoot, string previewPath)
    {
        Bitmap sheet = new Bitmap(1200, 860, PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(sheet))
        using (Font font = new Font("Segoe UI", 12f, FontStyle.Regular, GraphicsUnit.Pixel))
        using (Brush brush = new SolidBrush(Color.FromArgb(255, 220, 220, 220)))
        {
            g.Clear(Color.FromArgb(255, 18, 18, 22));
            g.InterpolationMode = InterpolationMode.NearestNeighbor;
            g.PixelOffsetMode = PixelOffsetMode.Half;
            string[] labels = new string[] { "Rest south", "Rest east", "Aroused south", "Aroused east" };
            string[] dirs = new string[] { "south", "east", "south", "east" };
            bool[] horny = new bool[] { false, false, true, true };
            for (int row = 0; row < dirs.Length; row++)
            {
                g.DrawString(labels[row], font, brush, new RectangleF(16f, 8f + row * 210f, 180f, 20f));
                for (int size = 0; size <= 5; size++)
                {
                    string folder = horny[row] ? Path.Combine(penisRoot, "Horny") : penisRoot;
                    string path = Path.Combine(folder, "NeedlePenis_" + size + "_" + dirs[row] + ".png");
                    using (Bitmap bmp = new Bitmap(path))
                    {
                        if (bmp.Width <= 8) continue;
                        int bminX = bmp.Width, bminY = bmp.Height, bmaxX = -1, bmaxY = -1;
                        int count = 0;
                        for (int y = 0; y < bmp.Height; y++)
                        for (int x = 0; x < bmp.Width; x++)
                        {
                            if (bmp.GetPixel(x, y).A < 16) continue;
                            count++;
                            if (x < bminX) bminX = x;
                            if (y < bminY) bminY = y;
                            if (x > bmaxX) bmaxX = x;
                            if (y > bmaxY) bmaxY = y;
                        }
                        if (size == 0 || size == 3 || size == 5)
                            Console.WriteLine(labels[row] + " " + size + " box " + bminX + "," + bminY + "-" + bmaxX + "," + bmaxY + " n " + count);
                        Rectangle window = new Rectangle(180, 70, 240, 280);
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

$source = "C:\Program Files (x86)\Steam\steamapps\common\RimWorld\Mods\rjw-genes\Common\Textures\Genes\Icons\Genitalia_thin_icon.png"
$ref = "C:\Users\mathi\Documents\Rimworld new mods\mods\RJWAnimalTextures\ArtInventory\TextureV2\reference-Genitalia_thin_icon.png"
Copy-Item -LiteralPath $source -Destination $ref -Force
$dest = "C:\Users\mathi\Documents\Rimworld new mods\mods\RJWAnimalTextures\Textures\SizedApparel\BodyParts\Human\Penis"
$preview = "C:\Users\mathi\Documents\Rimworld new mods\mods\RJWAnimalTextures\ArtInventory\TextureV2\preview-NeedlePenis.png"
[NeedlePenis]::Build($source, $dest, $preview)
