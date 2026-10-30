# DogPenis draft. Not copied into the live Textures folder.
# Rest is a closed sheath in the pose of the existing canine sheath, colored from the supplied picture.
# Aroused east is that picture turned up-right, with the scrotum hanging down.
# Aroused south is a front view: scrotum and penis both face forward, penis pointing up.
Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = "Stop"

Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;

public static class DogPenis
{
    const int Bins = 56;
    static readonly Color CreamHi = Color.FromArgb(255, 252, 236, 218);
    static readonly Color Cream = Color.FromArgb(255, 230, 198, 174);
    static readonly Color CreamShade = Color.FromArgb(255, 186, 138, 118);
    static readonly Color Fur = Color.FromArgb(255, 176, 98, 54);
    static readonly Color FurDark = Color.FromArgb(255, 118, 62, 32);
    static readonly Color Ink = Color.FromArgb(255, 72, 40, 28);
    static readonly Color SlitInk = Color.FromArgb(255, 92, 42, 36);

    static Bitmap Art;
    static Bitmap Sac;
    static Bitmap OrganArt;
    static PointF OrganBasePt;
    static float OrganAngle;
    static PointF Anchor;
    static PointF SacOpen;
    static float SacAngle;
    static float MirrorAngle;
    static float OrganLen;
    static float[] Radius = new float[Bins];
    static Color[] Core = new Color[Bins];
    static Color[] Edge = new Color[Bins];
    static int KnotBin;

    public static void Build(string sourcePath, string outRoot, string previewPath, string referencePath)
    {
        string hornyDir = Path.Combine(outRoot, "Horny");
        Directory.CreateDirectory(outRoot);
        Directory.CreateDirectory(hornyDir);
        using (Bitmap source = new Bitmap(sourcePath))
        {
            Prepare(source);
            Art.Save(referencePath, ImageFormat.Png);
            for (int size = 0; size <= 5; size++)
            {
                float scale = 0.09f + size * 0.030f;
                Save(Render(size, scale, false, false), Path.Combine(outRoot, "DogPenis_" + size + "_RNW_south.png"));
                Save(Render(size, scale, true, false), Path.Combine(outRoot, "DogPenis_" + size + "_RNW_east.png"));
                Save(Blank(), Path.Combine(outRoot, "DogPenis_" + size + "_RNW_north.png"));
                Save(Render(size, scale, false, true), Path.Combine(hornyDir, "DogPenis_" + size + "_RNW_south.png"));
                Save(Render(size, scale, true, true), Path.Combine(hornyDir, "DogPenis_" + size + "_RNW_east.png"));
                Save(Blank(), Path.Combine(hornyDir, "DogPenis_" + size + "_RNW_north.png"));
            }
        }
        BuildPreview(outRoot, previewPath);
        Art.Dispose();
        Sac.Dispose();
        OrganArt.Dispose();
    }

    static bool Page(Color c)
    {
        int min = Math.Min(c.R, Math.Min(c.G, c.B));
        int max = Math.Max(c.R, Math.Max(c.G, c.B));
        return min >= 226 && (max - min) < 36;
    }

    static bool Shaft(Color c)
    {
        return c.R > 130 && (c.R - c.G) > 70 && (c.G - c.B) < 42;
    }

    static bool SheathBody(Color c)
    {
        if (c.G > 120 && c.B > 100 && (c.G - c.B) > 12 && (c.R - c.G) < 65) return true;
        if (c.R > 90 && c.R < 230 && c.B < 150 && c.G > 40 && (c.G - c.B) > 28 && (c.R - c.G) < 100) return true;
        return false;
    }

    static void Prepare(Bitmap source)
    {
        int w = source.Width;
        int h = source.Height;
        Art = new Bitmap(w, h, PixelFormat.Format32bppArgb);
        bool[,] sheath = new bool[w, h];
        bool[,] organ = new bool[w, h];
        double sx = 0, sy = 0;
        int sn = 0;
        for (int y = 0; y < h; y++)
        for (int x = 0; x < w; x++)
        {
            Color c = source.GetPixel(x, y);
            if (Page(c))
            {
                Art.SetPixel(x, y, Color.Transparent);
                continue;
            }
            Art.SetPixel(x, y, Color.FromArgb(255, c.R, c.G, c.B));
            if (Shaft(c)) organ[x, y] = true;
            else if (SheathBody(c))
            {
                sheath[x, y] = true;
                sx += x;
                sy += y;
                sn++;
            }
        }
        if (sn == 0) throw new InvalidOperationException("No sheath pixels in the canine picture.");
        float ax = (float)(sx / sn);
        float ay = (float)(sy / sn);
        Anchor = new PointF(ax, ay);
        float far = -1f, tipX = ax, tipY = ay;
        float near = float.MaxValue, baseX = ax, baseY = ay;
        for (int y = 0; y < h; y++)
        for (int x = 0; x < w; x++)
        {
            if (!organ[x, y]) continue;
            float dx = x - ax;
            float dy = y - ay;
            float d = dx * dx + dy * dy;
            if (d > far) { far = d; tipX = x; tipY = y; }
            if (d < near) { near = d; baseX = x; baseY = y; }
        }
        float vx = tipX - baseX;
        float vy = tipY - baseY;
        OrganLen = (float)Math.Sqrt(vx * vx + vy * vy);
        if (OrganLen < 1f) OrganLen = 1f;
        float ux = vx / OrganLen;
        float uy = vy / OrganLen;
        float px = -uy;
        float py = ux;
        long[] cr = new long[Bins], cg = new long[Bins], cb = new long[Bins], cn = new long[Bins];
        long[] er = new long[Bins], eg = new long[Bins], eb = new long[Bins], en = new long[Bins];
        for (int y = 0; y < h; y++)
        for (int x = 0; x < w; x++)
        {
            if (!organ[x, y]) continue;
            float along = (x - baseX) * ux + (y - baseY) * uy;
            float side = (x - baseX) * px + (y - baseY) * py;
            int bin = (int)Math.Round(along / OrganLen * (Bins - 1));
            if (bin < 0 || bin >= Bins) continue;
            if (Math.Abs(side) > Radius[bin]) Radius[bin] = Math.Abs(side);
            if (Math.Abs(side) < 18f)
            {
                Color c = Art.GetPixel(x, y);
                cr[bin] += c.R; cg[bin] += c.G; cb[bin] += c.B; cn[bin]++;
            }
            else
            {
                Color c = Art.GetPixel(x, y);
                er[bin] += c.R; eg[bin] += c.G; eb[bin] += c.B; en[bin]++;
            }
        }
        for (int i = 0; i < Bins; i++)
        {
            if (cn[i] > 0) Core[i] = Color.FromArgb(255, (int)(cr[i] / cn[i]), (int)(cg[i] / cn[i]), (int)(cb[i] / cn[i]));
            else Core[i] = Color.FromArgb(255, 214, 96, 82);
            if (en[i] > 0) Edge[i] = Color.FromArgb(255, (int)(er[i] / en[i]), (int)(eg[i] / en[i]), (int)(eb[i] / en[i]));
            else Edge[i] = Color.FromArgb(255, 150, 58, 50);
        }
        KnotBin = 0;
        float knotR = 0f;
        int limit = (int)(Bins * 0.42f);
        for (int i = 0; i < limit; i++)
        {
            if (Radius[i] > knotR) { knotR = Radius[i]; KnotBin = i; }
        }
        double ox = 0, oy = 0;
        int on = 0;
        for (int y = 0; y < h; y++)
        for (int x = 0; x < w; x++)
        {
            if (!sheath[x, y]) continue;
            bool touch = false;
            for (int oy2 = -16; oy2 <= 16 && !touch; oy2++)
            for (int ox2 = -16; ox2 <= 16; ox2++)
            {
                int nx = x + ox2;
                int ny = y + oy2;
                if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue;
                if (organ[nx, ny]) touch = true;
            }
            if (!touch) continue;
            ox += x;
            oy += y;
            on++;
        }
        if (on == 0) SacOpen = Anchor;
        else SacOpen = new PointF((float)(ox / on), (float)(oy / on));
        float sacFar = -1f, botX = SacOpen.X, botY = SacOpen.Y;
        for (int y = 0; y < h; y++)
        for (int x = 0; x < w; x++)
        {
            if (!sheath[x, y]) continue;
            float dx = x - SacOpen.X;
            float dy = y - SacOpen.Y;
            float d = dx * dx + dy * dy;
            if (d > sacFar) { sacFar = d; botX = x; botY = y; }
        }
        SacAngle = (float)(Math.Atan2(-(botY - SacOpen.Y), botX - SacOpen.X) * 180.0 / Math.PI);
        MirrorAngle = (float)(Math.Atan2(-(tipY - ay), -(tipX - ax)) * 180.0 / Math.PI);
        OrganBasePt = new PointF(baseX, baseY);
        OrganAngle = (float)(Math.Atan2(-(tipY - baseY), tipX - baseX) * 180.0 / Math.PI);
        OrganArt = new Bitmap(w, h, PixelFormat.Format32bppArgb);
        for (int y = 0; y < h; y++)
        for (int x = 0; x < w; x++)
        {
            if (sheath[x, y]) continue;
            Color c = Art.GetPixel(x, y);
            if (c.A < 16) continue;
            bool keep = organ[x, y];
            if (!keep)
            {
                for (int oy3 = -3; oy3 <= 3 && !keep; oy3++)
                for (int ox3 = -3; ox3 <= 3; ox3++)
                {
                    int nx = x + ox3;
                    int ny = y + oy3;
                    if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue;
                    if (organ[nx, ny]) keep = true;
                }
            }
            if (keep) OrganArt.SetPixel(x, y, c);
        }
        Sac = new Bitmap(w, h, PixelFormat.Format32bppArgb);
        for (int y = 0; y < h; y++)
        for (int x = 0; x < w; x++)
        {
            if (organ[x, y]) continue;
            Color c = Art.GetPixel(x, y);
            if (c.A < 16) continue;
            bool keep = sheath[x, y];
            if (!keep)
            {
                for (int oy2 = -3; oy2 <= 3 && !keep; oy2++)
                for (int ox2 = -3; ox2 <= 3; ox2++)
                {
                    int nx = x + ox2;
                    int ny = y + oy2;
                    if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue;
                    if (sheath[nx, ny]) keep = true;
                }
            }
            if (keep) Sac.SetPixel(x, y, c);
        }
        Console.WriteLine("TIP " + tipX.ToString("0") + "," + tipY.ToString("0") + " base " + baseX.ToString("0") + "," + baseY.ToString("0") + " len " + OrganLen.ToString("0") + " knotBin " + KnotBin.ToString() + " knotR " + knotR.ToString("0") + " sac " + SacAngle.ToString("0.0") + " mirror " + MirrorAngle.ToString("0.0"));
    }

    static Bitmap Render(int size, float scale, bool east, bool horny)
    {
        Bitmap bmp = new Bitmap(512, 512, PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(bmp))
        {
            g.Clear(Color.Transparent);
            g.SmoothingMode = SmoothingMode.AntiAlias;
            g.PixelOffsetMode = PixelOffsetMode.HighQuality;
            if (!horny) DrawClosedSheath(g, size, east);
            else if (east) DrawEast(g, scale);
            else DrawSouth(g, scale);
        }
        for (int y = 0; y < bmp.Height; y++)
        for (int x = 0; x < bmp.Width; x++)
        {
            Color c = bmp.GetPixel(x, y);
            int min = Math.Min(c.R, Math.Min(c.G, c.B));
            int max = Math.Max(c.R, Math.Max(c.G, c.B));
            if (c.A > 0 && c.A < 24) bmp.SetPixel(x, y, Color.Transparent);
            else if (c.A < 80 && min > 230 && (max - min) < 24) bmp.SetPixel(x, y, Color.Transparent);
        }
        return bmp;
    }

    static void DrawClosedSheath(Graphics g, int size, bool east)
    {
        float length = 36f + size * 10f;
        float bulk = 28f + size * 7.5f;
        float destX = east ? 232f : 256f;
        float destY = east ? 292f : 286f;
        g.TranslateTransform(destX, destY);
        if (east) g.RotateTransform(56f);
        g.TranslateTransform(0f, length * 0.15f);
        PointF[] pts = new PointF[] {
            new PointF(0f, -length * 0.56f),
            new PointF(bulk * 0.14f, -length * 0.42f),
            new PointF(bulk * 0.46f, -length * 0.02f),
            new PointF(bulk * 0.50f, length * 0.24f),
            new PointF(bulk * 0.24f, length * 0.48f),
            new PointF(0f, length * 0.52f),
            new PointF(-bulk * 0.24f, length * 0.48f),
            new PointF(-bulk * 0.50f, length * 0.24f),
            new PointF(-bulk * 0.46f, -length * 0.02f),
            new PointF(-bulk * 0.14f, -length * 0.42f)
        };
        using (GraphicsPath path = new GraphicsPath())
        {
            path.AddClosedCurve(pts, 0.55f);
            RectangleF bounds = path.GetBounds();
            bounds.Inflate(2f, 2f);
            using (LinearGradientBrush brush = new LinearGradientBrush(bounds, CreamHi, CreamShade, east ? LinearGradientMode.ForwardDiagonal : LinearGradientMode.Vertical))
            {
                ColorBlend blend = new ColorBlend(3);
                blend.Colors = new Color[] { CreamHi, Cream, CreamShade };
                blend.Positions = new float[] { 0f, 0.45f, 1f };
                brush.InterpolationColors = blend;
                g.FillPath(brush, path);
            }
            float slitW = Math.Max(2.2f, bulk * 0.07f);
            float slitTop = -length * 0.46f;
            float slitH = length * 0.22f;
            if (!east)
            {
                using (SolidBrush slit = new SolidBrush(SlitInk))
                    g.FillEllipse(slit, -slitW * 0.5f, slitTop, slitW, slitH);
            }
            using (SolidBrush fur = new SolidBrush(Fur))
            using (SolidBrush fur2 = new SolidBrush(FurDark))
            {
                g.FillEllipse(fur2, -bulk * 0.16f, -length * 0.58f, bulk * 0.34f, length * 0.14f);
                g.FillEllipse(fur, -bulk * 0.28f, -length * 0.50f, bulk * 0.18f, length * 0.10f);
                g.FillEllipse(fur, bulk * 0.10f, -length * 0.50f, bulk * 0.18f, length * 0.10f);
            }
            using (Pen pen = new Pen(Ink, Math.Max(2.1f, bulk * 0.06f)))
            {
                pen.LineJoin = LineJoin.Round;
                g.DrawPath(pen, path);
            }
        }
    }

    static void DrawEast(Graphics g, float scale)
    {
        g.TranslateTransform(246f, 308f);
        g.RotateTransform(MirrorAngle - 34f);
        g.ScaleTransform(-scale, scale);
        g.TranslateTransform(-Anchor.X, -Anchor.Y);
        g.InterpolationMode = InterpolationMode.HighQualityBicubic;
        g.DrawImage(Art, 0, 0);
    }

    static void DrawSouth(Graphics g, float scale)
    {
        float knotX = 256f;
        float knotY = 292f;
        g.TranslateTransform(knotX, knotY);
        g.RotateTransform(SacAngle + 90f);
        g.ScaleTransform(scale * 1.15f, scale * 1.15f);
        g.TranslateTransform(-SacOpen.X, -SacOpen.Y);
        g.InterpolationMode = InterpolationMode.HighQualityBicubic;
        g.DrawImage(Sac, 0, 0);
        g.ResetTransform();
        g.TranslateTransform(knotX, knotY);
        g.RotateTransform(OrganAngle - 90f);
        g.ScaleTransform(scale, scale);
        g.TranslateTransform(-OrganBasePt.X, -OrganBasePt.Y);
        g.DrawImage(OrganArt, 0, 0);
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

    static void BuildPreview(string outRoot, string previewPath)
    {
        string[] labels = new string[] { "Rest south", "Rest east", "Aroused south", "Aroused east" };
        string[] dirs = new string[] { "south", "east", "south", "east" };
        bool[] horny = new bool[] { false, false, true, true };
        int winL = 511, winT = 511, winR = 0, winB = 0;
        for (int row = 0; row < dirs.Length; row++)
        for (int size = 0; size <= 5; size++)
        {
            string folder = horny[row] ? Path.Combine(outRoot, "Horny") : outRoot;
            using (Bitmap bmp = new Bitmap(Path.Combine(folder, "DogPenis_" + size + "_RNW_" + dirs[row] + ".png")))
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
                g.DrawString(labels[row], font, brush, new RectangleF(16f, 8f + row * 210f, 220f, 20f));
                for (int size = 0; size <= 5; size++)
                {
                    string folder = horny[row] ? Path.Combine(outRoot, "Horny") : outRoot;
                    using (Bitmap bmp = new Bitmap(Path.Combine(folder, "DogPenis_" + size + "_RNW_" + dirs[row] + ".png")))
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

$source = "C:\Users\mathi\.cursor\projects\c-Users-mathi-Documents-Rimworld-new-mods\assets\c__Users_mathi_AppData_Roaming_Cursor_User_workspaceStorage_f286a127b07b48d0b85590b38d17346c_images_mv7t5priibxame-7ee89271-ccae-4ab3-aeba-75f77f9651a0.jpg"
$out = "C:\Users\mathi\Documents\Rimworld new mods\mods\RJWAnimalTextures\ArtInventory\GeneratedDogPenis"
$preview = "C:\Users\mathi\Documents\Rimworld new mods\mods\RJWAnimalTextures\ArtInventory\TextureV2\preview-DogPenis.png"
$reference = "C:\Users\mathi\Documents\Rimworld new mods\mods\RJWAnimalTextures\ArtInventory\TextureV2\reference-canine.png"
[DogPenis]::Build($source, $out, $preview, $reference)
