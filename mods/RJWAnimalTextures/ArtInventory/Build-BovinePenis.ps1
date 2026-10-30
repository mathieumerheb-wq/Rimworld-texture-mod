# BovinePenis. Exact bull sprite from RJW Animal Graphics Addon.
# Scale2x cleans the stair-steps. The silhouette is still that sprite.
# Rest is the white scrotum. Aroused is the whole sprite, scrotum and pink shaft together.
# East is flipped so the tip points up-right. South erect points up.
# BovinePenis is not in BodypartDetail_Penis.xml, so the filenames have no variation suffix.
# Ball files are blank. North penis files are blank 4x4.
Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = "Stop"

Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;

public static class BovinePenis
{
    const int Up = 8;
    static readonly Color SheathHi = Color.FromArgb(255, 255, 246, 242);
    static readonly Color SheathShade = Color.FromArgb(255, 186, 150, 146);
    static readonly Color Outline = Color.FromArgb(255, 12, 8, 10);
    static readonly Color Sheath = Color.FromArgb(255, 250, 246, 242);

    public static void Build(string sourcePath, string penisRoot, string previewPath)
    {
        string hornyDir = Path.Combine(penisRoot, "Horny");
        string balls = Path.Combine(penisRoot, "Balls");
        Directory.CreateDirectory(penisRoot);
        Directory.CreateDirectory(hornyDir);
        Directory.CreateDirectory(balls);
        using (Bitmap source = new Bitmap(sourcePath))
        {
            Color pink = AveragePink(source);
            for (int size = 0; size <= 5; size++)
            {
                float scale = 2.15f + size * 0.72f;
                Save(Render(source, scale, false, 0, pink), Path.Combine(penisRoot, "BovinePenis_" + size + "_south.png"));
                Save(Render(source, scale, true, 0, pink), Path.Combine(penisRoot, "BovinePenis_" + size + "_east.png"));
                Save(Blank(), Path.Combine(penisRoot, "BovinePenis_" + size + "_north.png"));
                Save(Render(source, scale, false, 2, pink), Path.Combine(hornyDir, "BovinePenis_" + size + "_south.png"));
                Save(Render(source, scale, true, 2, pink), Path.Combine(hornyDir, "BovinePenis_" + size + "_east.png"));
                Save(Blank(), Path.Combine(hornyDir, "BovinePenis_" + size + "_north.png"));
                Save(Blank(), Path.Combine(balls, "BovinePenis_" + size + "_south.png"));
                Save(Blank(), Path.Combine(balls, "BovinePenis_" + size + "_east.png"));
                Save(Blank(), Path.Combine(balls, "BovinePenis_" + size + "_north.png"));
            }
        }
        BuildPreview(penisRoot, previewPath);
    }

    static void Save(Bitmap bmp, string path)
    {
        bmp.Save(path, ImageFormat.Png);
        bmp.Dispose();
    }

    static Bitmap Blank()
    {
        Bitmap bmp = new Bitmap(4, 4, PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(bmp)) g.Clear(Color.Transparent);
        return bmp;
    }

    static bool IsPink(Color c)
    {
        return c.A >= 16 && c.R > c.G + 12 && c.R > c.B + 12 && c.R > 90;
    }

    static Color AveragePink(Bitmap source)
    {
        float r = 0f, g = 0f, b = 0f, n = 0f;
        for (int y = 0; y < source.Height; y++)
        {
            for (int x = 0; x < source.Width; x++)
            {
                Color c = source.GetPixel(x, y);
                if (!IsPink(c)) continue;
                r += c.R; g += c.G; b += c.B; n++;
            }
        }
        if (n < 1f) return Color.FromArgb(255, 214, 120, 124);
        return Color.FromArgb(255, (int)(r / n), (int)(g / n), (int)(b / n));
    }

    static Bitmap Render(Bitmap source, float scale, bool east, int mode, Color pink)
    {
        int minX = source.Width, minY = source.Height, maxX = -1, maxY = -1;
        for (int y = 0; y < source.Height; y++)
        {
            for (int x = 0; x < source.Width; x++)
            {
                if (source.GetPixel(x, y).A < 16) continue;
                if (x < minX) minX = x;
                if (y < minY) minY = y;
                if (x > maxX) maxX = x;
                if (y > maxY) maxY = y;
            }
        }
        int w = maxX - minX + 1;
        int h = maxY - minY + 1;
        byte[,] cell = new byte[w, h];
        float rootX = 0f, rootY = 0f, rootN = 0f;
        float tipX = 0f, tipY = 0f, tipN = 0f;
        for (int y = 0; y < h; y++)
        {
            for (int x = 0; x < w; x++)
            {
                Color c = source.GetPixel(minX + x, minY + y);
                if (c.A < 16) continue;
                cell[x, y] = (byte)(c.R < 80 ? 1 : (IsPink(c) ? 2 : 3));
                if (y <= 8) { rootX += x + 0.5f; rootY += y + 0.5f; rootN++; }
                if (y >= h - 5) { tipX += x + 0.5f; tipY += y + 0.5f; tipN++; }
            }
        }
        rootX /= rootN;
        rootY /= rootN;
        float ax = tipX - rootX;
        float ay = tipY - rootY;
        float len = (float)Math.Sqrt(ax * ax + ay * ay);
        ax /= len;
        ay /= len;
        if (mode == 0)
        {
            for (int y = 0; y < h; y++)
            {
                for (int x = 0; x < w; x++)
                {
                    if (cell[x, y] != 3) continue;
                    Color c = source.GetPixel(minX + x, minY + y);
                    if (c.R < 170 || c.G < 150 || c.B < 140) cell[x, y] = 0;
                }
            }
            byte[,] rim = new byte[w, h];
            for (int y = 0; y < h; y++)
            {
                for (int x = 0; x < w; x++)
                {
                    if (cell[x, y] != 1) continue;
                    bool touch = false;
                    for (int dy = -1; dy <= 1 && !touch; dy++)
                    {
                        for (int dx = -1; dx <= 1; dx++)
                        {
                            int nx = x + dx;
                            int ny = y + dy;
                            if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue;
                            if (cell[nx, ny] == 3) touch = true;
                        }
                    }
                    if (touch) rim[x, y] = 1;
                }
            }
            for (int y = 0; y < h; y++)
            {
                for (int x = 0; x < w; x++)
                {
                    if (cell[x, y] == 2) cell[x, y] = 0;
                    else if (cell[x, y] == 1 && rim[x, y] == 0) cell[x, y] = 0;
                }
            }
            int[] part = new int[w * h];
            int[] qx = new int[w * h];
            int[] qy = new int[w * h];
            int bestId = 0;
            int bestN = 0;
            int nextId = 1;
            for (int y = 0; y < h; y++)
            {
                for (int x = 0; x < w; x++)
                {
                    if (cell[x, y] == 0 || part[y * w + x] != 0) continue;
                    int head = 0;
                    int tail = 0;
                    qx[tail] = x;
                    qy[tail] = y;
                    tail++;
                    part[y * w + x] = nextId;
                    int count = 0;
                    while (head < tail)
                    {
                        int px = qx[head];
                        int py = qy[head];
                        head++;
                        count++;
                        for (int oy = -1; oy <= 1; oy++)
                        {
                            for (int ox = -1; ox <= 1; ox++)
                            {
                                if (ox == 0 && oy == 0) continue;
                                int nx = px + ox;
                                int ny = py + oy;
                                if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue;
                                if (cell[nx, ny] == 0 || part[ny * w + nx] != 0) continue;
                                part[ny * w + nx] = nextId;
                                qx[tail] = nx;
                                qy[tail] = ny;
                                tail++;
                            }
                        }
                    }
                    if (count > bestN)
                    {
                        bestN = count;
                        bestId = nextId;
                    }
                    nextId++;
                }
            }
            for (int y = 0; y < h; y++)
            {
                for (int x = 0; x < w; x++)
                {
                    if (cell[x, y] != 0 && part[y * w + x] != bestId) cell[x, y] = 0;
                }
            }
            float maxSheath = -1000f;
            for (int y = 0; y < h; y++)
            {
                for (int x = 0; x < w; x++)
                {
                    if (cell[x, y] != 3) continue;
                    float along = (x + 0.5f - rootX) * ax + (y + 0.5f - rootY) * ay;
                    if (along > maxSheath) maxSheath = along;
                }
            }
            float cut = maxSheath + 1.2f;
            for (int y = 0; y < h; y++)
            {
                for (int x = 0; x < w; x++)
                {
                    if (cell[x, y] == 0) continue;
                    float along = (x + 0.5f - rootX) * ax + (y + 0.5f - rootY) * ay;
                    if (along > cut) cell[x, y] = 0;
                }
            }
        }
        else if (mode == 1)
        {
            byte[,] rim = new byte[w, h];
            for (int y = 0; y < h; y++)
            {
                for (int x = 0; x < w; x++)
                {
                    if (cell[x, y] != 1) continue;
                    bool touch = false;
                    for (int dy = -1; dy <= 1 && !touch; dy++)
                    {
                        for (int dx = -1; dx <= 1; dx++)
                        {
                            int nx = x + dx;
                            int ny = y + dy;
                            if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue;
                            if (cell[nx, ny] == 2) touch = true;
                        }
                    }
                    if (touch) rim[x, y] = 1;
                }
            }
            for (int y = 0; y < h; y++)
            {
                for (int x = 0; x < w; x++)
                {
                    if (cell[x, y] == 3) cell[x, y] = 0;
                    else if (cell[x, y] == 1 && rim[x, y] == 0) cell[x, y] = 0;
                }
            }
        }

        byte[,] big = cell;
        int bw = w;
        int bh = h;
        for (int pass = 0; pass < 3; pass++)
        {
            big = Scale2x(big, bw, bh);
            bw *= 2;
            bh *= 2;
        }
        if (east)
        {
            big = FlipY(big, bw, bh);
            rootY = h - rootY;
        }

        float angle = (float)(Math.Atan2(ay, ax) * 180.0 / Math.PI);
        float turn = east ? 0f : -90f - angle;
        Bitmap master = ToBitmap(big, bw, bh, pink);
        Bitmap turned = turn == 0f ? master : Turn(master, turn, rootX * Up, rootY * Up, out rootX, out rootY);
        if (!object.ReferenceEquals(turned, master)) master.Dispose();
        else
        {
            rootX *= Up;
            rootY *= Up;
        }

        Bitmap canvas = new Bitmap(512, 512, PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(canvas))
        {
            g.Clear(Color.Transparent);
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
            g.PixelOffsetMode = PixelOffsetMode.HighQuality;
            g.CompositingQuality = CompositingQuality.HighQuality;
            float destX = east ? 246f : 256f;
            float destY = 278f;
            float drawW = turned.Width * (scale / Up);
            float drawH = turned.Height * (scale / Up);
            float left = destX - rootX * (scale / Up);
            float top = destY - rootY * (scale / Up);
            g.DrawImage(turned, left, top, drawW, drawH);
        }
        turned.Dispose();
        for (int y = 0; y < canvas.Height; y++)
        {
            for (int x = 0; x < canvas.Width; x++)
            {
                Color c = canvas.GetPixel(x, y);
                if (c.A > 0 && c.A < 48) canvas.SetPixel(x, y, Color.Transparent);
            }
        }
        return canvas;
    }

    static byte[,] Scale2x(byte[,] src, int w, int h)
    {
        byte[,] dst = new byte[w * 2, h * 2];
        for (int y = 0; y < h; y++)
        {
            for (int x = 0; x < w; x++)
            {
                byte e = src[x, y];
                byte b = y > 0 ? src[x, y - 1] : e;
                byte d = x > 0 ? src[x - 1, y] : e;
                byte f = x < w - 1 ? src[x + 1, y] : e;
                byte hh = y < h - 1 ? src[x, y + 1] : e;
                byte e0 = e, e1 = e, e2 = e, e3 = e;
                if (b != hh && d != f)
                {
                    if (d == b) e0 = d;
                    if (b == f) e1 = f;
                    if (d == hh) e2 = d;
                    if (hh == f) e3 = f;
                }
                dst[x * 2, y * 2] = e0;
                dst[x * 2 + 1, y * 2] = e1;
                dst[x * 2, y * 2 + 1] = e2;
                dst[x * 2 + 1, y * 2 + 1] = e3;
            }
        }
        return dst;
    }

    static byte[,] FlipY(byte[,] src, int w, int h)
    {
        byte[,] dst = new byte[w, h];
        for (int y = 0; y < h; y++)
        {
            for (int x = 0; x < w; x++) dst[x, h - 1 - y] = src[x, y];
        }
        return dst;
    }

    static Bitmap ToBitmap(byte[,] src, int w, int h, Color pink)
    {
        Bitmap bmp = new Bitmap(w, h, PixelFormat.Format32bppArgb);
        for (int y = 0; y < h; y++)
        {
            for (int x = 0; x < w; x++)
            {
                byte v = src[x, y];
                if (v == 1) bmp.SetPixel(x, y, Outline);
                else if (v == 2) bmp.SetPixel(x, y, pink);
                else if (v == 3) bmp.SetPixel(x, y, Sheath);
            }
        }
        return bmp;
    }

    static Bitmap Turn(Bitmap src, float clockwiseDeg, float anchorX, float anchorY, out float newX, out float newY)
    {
        double rad = clockwiseDeg * Math.PI / 180.0;
        float c = (float)Math.Cos(rad);
        float s = (float)Math.Sin(rad);
        PointF[] corners = new PointF[] {
            Spin(0, 0, anchorX, anchorY, c, s),
            Spin(src.Width, 0, anchorX, anchorY, c, s),
            Spin(0, src.Height, anchorX, anchorY, c, s),
            Spin(src.Width, src.Height, anchorX, anchorY, c, s)
        };
        float minX = corners[0].X, minY = corners[0].Y, maxX = corners[0].X, maxY = corners[0].Y;
        for (int i = 1; i < 4; i++)
        {
            if (corners[i].X < minX) minX = corners[i].X;
            if (corners[i].Y < minY) minY = corners[i].Y;
            if (corners[i].X > maxX) maxX = corners[i].X;
            if (corners[i].Y > maxY) maxY = corners[i].Y;
        }
        int dw = Math.Max(1, (int)Math.Ceiling(maxX - minX));
        int dh = Math.Max(1, (int)Math.Ceiling(maxY - minY));
        Bitmap dest = new Bitmap(dw, dh, PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(dest))
        {
            g.Clear(Color.Transparent);
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
            g.PixelOffsetMode = PixelOffsetMode.HighQuality;
            g.TranslateTransform(-minX, -minY);
            g.TranslateTransform(anchorX, anchorY);
            g.RotateTransform(clockwiseDeg);
            g.TranslateTransform(-anchorX, -anchorY);
            g.DrawImage(src, 0, 0, src.Width, src.Height);
        }
        newX = anchorX - minX;
        newY = anchorY - minY;
        return dest;
    }

    static PointF Spin(float x, float y, float ox, float oy, float c, float s)
    {
        float dx = x - ox;
        float dy = y - oy;
        return new PointF(ox + dx * c - dy * s, oy + dx * s + dy * c);
    }

    static Bitmap DrawBalls(int size, bool east, bool north)
    {
        Bitmap bmp = new Bitmap(512, 512, PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(bmp))
        {
            g.Clear(Color.Transparent);
            g.SmoothingMode = SmoothingMode.AntiAlias;
            g.PixelOffsetMode = PixelOffsetMode.HighQuality;
            float d = 28f + size * 8f;
            float penW = Math.Max(2.2f, d * 0.07f);
            if (east)
            {
                Oval(g, 244f, 260f, d * 0.78f, d * 0.88f, penW);
                Oval(g, 262f, 274f, d * 0.92f, d * 1.02f, penW);
            }
            else
            {
                float y = north ? 262f : 272f;
                float gap = d * 0.34f;
                Oval(g, 256f - gap, y, d * 0.86f, d, penW);
                Oval(g, 256f + gap, y, d * 0.86f, d, penW);
            }
        }
        return bmp;
    }

    static void Oval(Graphics g, float cx, float cy, float w, float h, float penW)
    {
        RectangleF box = new RectangleF(cx - w * 0.5f, cy - h * 0.5f, w, h);
        using (GraphicsPath path = new GraphicsPath())
        {
            path.AddEllipse(box);
            using (PathGradientBrush brush = new PathGradientBrush(path))
            {
                brush.CenterColor = SheathHi;
                brush.SurroundColors = new Color[] { SheathShade };
                brush.CenterPoint = new PointF(cx - w * 0.12f, cy - h * 0.16f);
                g.FillPath(brush, path);
            }
            using (Pen pen = new Pen(Outline, penW))
            {
                pen.LineJoin = LineJoin.Round;
                g.DrawPath(pen, path);
            }
        }
    }

    static void BuildPreview(string penisRoot, string previewPath)
    {
        Bitmap sheet = new Bitmap(1200, 1160, PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(sheet))
        {
            g.Clear(Color.FromArgb(255, 18, 18, 22));
            g.InterpolationMode = InterpolationMode.NearestNeighbor;
            g.PixelOffsetMode = PixelOffsetMode.Half;
            string[] dirs = new string[] { "south", "south", "east", "east", "south", "east" };
            bool[] horny = new bool[] { false, true, false, true, false, false };
            bool[] ball = new bool[] { false, false, false, false, true, true };
            for (int row = 0; row < dirs.Length; row++)
            {
                for (int size = 0; size <= 5; size++)
                {
                    string folder = ball[row] ? Path.Combine(penisRoot, "Balls") : (horny[row] ? Path.Combine(penisRoot, "Horny") : penisRoot);
                    string path = Path.Combine(folder, "BovinePenis_" + size + "_" + dirs[row] + ".png");
                    using (Bitmap bmp = new Bitmap(path))
                    {
                        if (bmp.Width <= 8) continue;
                        int bminX = bmp.Width, bminY = bmp.Height, bmaxX = -1, bmaxY = -1;
                        for (int y = 0; y < bmp.Height; y++)
                        {
                            for (int x = 0; x < bmp.Width; x++)
                            {
                                if (bmp.GetPixel(x, y).A < 16) continue;
                                if (x < bminX) bminX = x;
                                if (y < bminY) bminY = y;
                                if (x > bmaxX) bmaxX = x;
                                if (y > bmaxY) bmaxY = y;
                            }
                        }
                        if (bmaxX < 0) continue;
                        int pad = 4;
                        int sx = Math.Max(0, bminX - pad);
                        int sy = Math.Max(0, bminY - pad);
                        int sw = Math.Min(bmp.Width - sx, (bmaxX - bminX + 1) + pad * 2);
                        int sh = Math.Min(bmp.Height - sy, (bmaxY - bminY + 1) + pad * 2);
                        Rectangle cell = new Rectangle(16 + size * 196, 16 + row * 190, 180, 174);
                        float fit = Math.Min(cell.Width / (float)sw, cell.Height / (float)sh);
                        int pw = Math.Max(1, (int)(sw * fit));
                        int ph = Math.Max(1, (int)(sh * fit));
                        g.DrawImage(bmp, new Rectangle(cell.X + (cell.Width - pw) / 2, cell.Y + (cell.Height - ph) / 2, pw, ph), new Rectangle(sx, sy, sw, sh), GraphicsUnit.Pixel);
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

$source = "C:\Program Files (x86)\Steam\steamapps\common\RimWorld\Mods\RJW - Animal Graphics Addon\Textures\Things\Pawn\Animal\Cow\Bull_Lewd_east.png"
$dest = "C:\Users\mathi\Documents\Rimworld new mods\mods\RJWAnimalTextures\Textures\SizedApparel\BodyParts\Human\Penis"
$preview = "C:\Users\mathi\Documents\Rimworld new mods\mods\RJWAnimalTextures\ArtInventory\TextureV2\preview-BovinePenis.png"
[BovinePenis]::Build($source, $dest, $preview)
