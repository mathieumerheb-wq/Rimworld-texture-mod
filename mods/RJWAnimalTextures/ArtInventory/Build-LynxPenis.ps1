# Retired. Rests and erect sizes 3-5 are written by Build-LynxVariety.ps1.
# Sizes 0-2 erect stay as the last files this script wrote.
Write-Host "Build-LynxPenis.ps1 is retired. Use Build-LynxVariety.ps1."
exit 0
Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = "Stop"

Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;

public static class LynxPenis
{
    const float EastAngle = -34f;

    public static void Build(string southPath, string sidePath, string frontSacPath, string sideSacPath, string bigPath, string outRoot, string genePath, string previewPath)
    {
        string hornyDir = Path.Combine(outRoot, "Horny");
        string ballDir = Path.Combine(outRoot, "Balls");
        Directory.CreateDirectory(outRoot);
        Directory.CreateDirectory(hornyDir);
        Directory.CreateDirectory(ballDir);
        Bitmap organ = CutSouthBulb(Largest(Load(southPath)));
        Bitmap side = Mirror(CutSideBulb(Largest(Load(sidePath))));
        Bitmap front = Largest(Load(frontSacPath));
        Bitmap sideSac = Largest(StripStub(Load(sideSacPath)));
        Bitmap big = FaceRight(Largest(Load(bigPath)));
        PointF sideBase;
        PointF sideTip;
        float sideAngle = Measure(side, out sideBase, out sideTip);
        float sideRot = EastAngle - sideAngle;
        PointF frontMouth = SheathTop(front);
        PointF sideMouth = SheathTop(sideSac);
        float bigAngle = ShaftAngle(big);
        float bigSouthRot = -90f - bigAngle;
        float bigEastRot = -45f - bigAngle;
        PointF bigBase = BottomCenter(big);
        Console.WriteLine("SHAFT rot " + sideRot.ToString("0.0")
            + " BIG angle " + bigAngle.ToString("0.0")
            + " southRot " + bigSouthRot.ToString("0.0")
            + " eastRot " + bigEastRot.ToString("0.0"));
        SaveGene(organ, genePath);
        float[] restH = new float[] { 64f, 80f, 98f, 118f, 140f, 164f };
        float[] bigH = new float[] { 0f, 0f, 0f, 270f, 322f, 376f };
        for (int size = 0; size <= 5; size++)
        {
            float sacScale = restH[size] / ContentH(front);
            float sideScale = restH[size] / ContentH(sideSac);
            float scale = 0.30f + size * 0.076f;
            float bury = restH[size] * 0.32f;
            float southJoinX = 256f;
            float southJoinY = 292f;
            float eastJoinX = 228f;
            float eastJoinY = 300f;
            float eastBuryX = SpanW(sideSac) * sideScale * 0.28f;
            float eastBuryY = restH[size] * 0.06f;
            PointF shaftSouth = BottomCenter(organ);
            Save(DrawFused(front, sacScale, frontMouth, 0f, organ, scale, shaftSouth, 0f, southJoinX, southJoinY, 0f, 0f, false), Path.Combine(outRoot, "LynxPenis_" + size + "_south.png"));
            Save(DrawFused(sideSac, sideScale, sideMouth, 0f, side, scale, sideBase, sideRot, eastJoinX, eastJoinY, 0f, 0f, false), Path.Combine(outRoot, "LynxPenis_" + size + "_east.png"));
            if (size < 3)
            {
                Save(DrawFused(front, sacScale, frontMouth, 0f, organ, scale, shaftSouth, 0f, southJoinX, southJoinY, 0f, bury, true), Path.Combine(hornyDir, "LynxPenis_" + size + "_south.png"));
                Save(DrawFused(sideSac, sideScale, sideMouth, 0f, side, scale, sideBase, sideRot, eastJoinX, eastJoinY, eastBuryX, eastBuryY, true), Path.Combine(hornyDir, "LynxPenis_" + size + "_east.png"));
            }
            else
            {
                Save(PlaceBig(big, bigH[size], bigSouthRot, bigBase, 256f, 420f), Path.Combine(hornyDir, "LynxPenis_" + size + "_south.png"));
                Save(PlaceBig(big, bigH[size], bigEastRot, bigBase, 214f, 410f), Path.Combine(hornyDir, "LynxPenis_" + size + "_east.png"));
            }
            Save(Blank(), Path.Combine(outRoot, "LynxPenis_" + size + "_north.png"));
            Save(Blank(), Path.Combine(hornyDir, "LynxPenis_" + size + "_north.png"));
            Save(Blank(), Path.Combine(ballDir, "LynxPenis_" + size + "_south.png"));
            Save(Blank(), Path.Combine(ballDir, "LynxPenis_" + size + "_east.png"));
            Save(Blank(), Path.Combine(ballDir, "LynxPenis_" + size + "_north.png"));
        }
        BuildPreview(outRoot, previewPath);
        organ.Dispose();
        side.Dispose();
        front.Dispose();
        sideSac.Dispose();
        big.Dispose();
    }

    static Bitmap StripStub(Bitmap src)
    {
        Bitmap bmp = new Bitmap(src.Width, src.Height, PixelFormat.Format32bppArgb);
        for (int y = 0; y < src.Height; y++)
        for (int x = 0; x < src.Width; x++)
        {
            Color c = src.GetPixel(x, y);
            if (c.A < 16) continue;
            int gap = c.R - Math.Max(c.G, c.B);
            bool stub = gap >= 60 && c.R > 150 && c.G < 150;
            bool stubEdge = x > src.Width * 0.70f && c.R > 40 && c.G < 100 && c.B < 100 && c.R > c.G + 28;
            if (stub || stubEdge) continue;
            bmp.SetPixel(x, y, c);
        }
        src.Dispose();
        return bmp;
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
        return Math.Max(1, maxY - minY + 1);
    }

    static Bitmap CutSouthBulb(Bitmap src)
    {
        int h = src.Height;
        int[] width = new int[h];
        int minY = h;
        int maxY = 0;
        for (int y = 0; y < h; y++)
        {
            int minX = src.Width;
            int maxX = -1;
            for (int x = 0; x < src.Width; x++)
            {
                if (src.GetPixel(x, y).A < 16) continue;
                if (x < minX) minX = x;
                if (x > maxX) maxX = x;
            }
            if (maxX < 0) continue;
            width[y] = maxX - minX + 1;
            if (y < minY) minY = y;
            if (y > maxY) maxY = y;
        }
        int start = minY + (int)((maxY - minY) * 0.55f);
        int maxW = 1;
        for (int y = start; y <= maxY; y++) if (width[y] > maxW) maxW = width[y];
        int neck = maxY;
        for (int y = maxY; y >= start; y--)
        {
            if (width[y] > 0 && width[y] < maxW * 0.72f)
            {
                neck = y;
                break;
            }
        }
        for (int y = neck + 4; y < h; y++)
        for (int x = 0; x < src.Width; x++)
            src.SetPixel(x, y, Color.Transparent);
        Console.WriteLine("SOUTH neck " + neck + " of " + minY + "-" + maxY);
        return src;
    }

    static Bitmap CutSideBulb(Bitmap src)
    {
        int w = src.Width;
        int[] height = new int[w];
        int minX = w;
        int maxX = 0;
        for (int x = 0; x < w; x++)
        {
            int minY = src.Height;
            int maxY = -1;
            for (int y = 0; y < src.Height; y++)
            {
                if (src.GetPixel(x, y).A < 16) continue;
                if (y < minY) minY = y;
                if (y > maxY) maxY = y;
            }
            if (maxY < 0) continue;
            height[x] = maxY - minY + 1;
            if (x < minX) minX = x;
            if (x > maxX) maxX = x;
        }
        int left = minX + (int)((maxX - minX) * 0.62f);
        int right = minX + (int)((maxX - minX) * 0.82f);
        int neck = right;
        int best = int.MaxValue;
        for (int x = left; x <= right; x++)
        {
            if (height[x] > 0 && height[x] < best)
            {
                best = height[x];
                neck = x;
            }
        }
        for (int x = neck; x < w; x++)
        for (int y = 0; y < src.Height; y++)
            src.SetPixel(x, y, Color.Transparent);
        Console.WriteLine("SIDE neck " + neck);
        return src;
    }

    static PointF SheathTop(Bitmap src)
    {
        int minY = src.Height;
        double sx = 0;
        int n = 0;
        for (int y = 0; y < src.Height; y++)
        for (int x = 0; x < src.Width; x++)
        {
            if (src.GetPixel(x, y).A < 16) continue;
            if (y < minY) minY = y;
            sx += x;
            n++;
        }
        if (n < 1) return new PointF(src.Width * 0.5f, 0f);
        return new PointF((float)(sx / n), minY);
    }

    static PointF TopCenter(Bitmap src)
    {
        int minY = src.Height;
        for (int y = 0; y < src.Height; y++)
        for (int x = 0; x < src.Width; x++)
        {
            if (src.GetPixel(x, y).A < 16) continue;
            if (y < minY) minY = y;
        }
        double sx = 0;
        int n = 0;
        int y1 = Math.Min(src.Height - 1, minY + 10);
        for (int y = minY; y <= y1; y++)
        for (int x = 0; x < src.Width; x++)
        {
            if (src.GetPixel(x, y).A < 16) continue;
            sx += x;
            n++;
        }
        if (n < 1) return new PointF(src.Width * 0.5f, minY);
        return new PointF((float)(sx / n), minY);
    }

    static PointF RightCenter(Bitmap src)
    {
        int maxX = 0;
        for (int y = 0; y < src.Height; y++)
        for (int x = 0; x < src.Width; x++)
        {
            if (src.GetPixel(x, y).A < 16) continue;
            if (x > maxX) maxX = x;
        }
        double sy = 0;
        int n = 0;
        int x0 = Math.Max(0, maxX - 8);
        for (int y = 0; y < src.Height; y++)
        for (int x = x0; x <= maxX; x++)
        {
            if (src.GetPixel(x, y).A < 16) continue;
            sy += y;
            n++;
        }
        if (n < 1) return new PointF(maxX, src.Height * 0.3f);
        return new PointF(maxX, (float)(sy / n));
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
        int y0 = Math.Max(0, maxY - 8);
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

    static bool Red(Color c)
    {
        return c.A >= 16 && c.R > 120 && (c.R - Math.Max(c.G, c.B)) > 28 && c.G < 170;
    }

    static float ShaftAngle(Bitmap src)
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
        double best = 1;
        for (int y = 0; y < src.Height; y++)
        for (int x = 0; x < src.Width; x++)
        {
            if (!Red(src.GetPixel(x, y))) continue;
            double d = (x - rx) * (x - rx) + (y - ry) * (y - ry);
            if (d > best) best = d;
        }
        double tx = 0, ty = 0, tn = 0;
        double keep = best * 0.72;
        for (int y = 0; y < src.Height; y++)
        for (int x = 0; x < src.Width; x++)
        {
            if (!Red(src.GetPixel(x, y))) continue;
            double d = (x - rx) * (x - rx) + (y - ry) * (y - ry);
            if (d < keep) continue;
            tx += x; ty += y; tn++;
        }
        if (tn < 1) return 0f;
        return (float)(Math.Atan2((ty / tn) - ry, (tx / tn) - rx) * 180.0 / Math.PI);
    }

    static Bitmap FaceRight(Bitmap src)
    {
        float angle = ShaftAngle(src);
        if (Math.Abs(angle) < 90f) return src;
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

    static Bitmap PlaceBig(Bitmap art, float targetH, float rot, PointF origin, float dx, float dy)
    {
        int minY = art.Height, maxY = 0, minX = art.Width, maxX = 0;
        for (int y = 0; y < art.Height; y++)
        for (int x = 0; x < art.Width; x++)
        {
            if (art.GetPixel(x, y).A < 16) continue;
            if (y < minY) minY = y;
            if (y > maxY) maxY = y;
            if (x < minX) minX = x;
            if (x > maxX) maxX = x;
        }
        float len = Math.Max(maxX - minX, maxY - minY);
        if (len < 8f) len = 8f;
        float scale = targetH / len;
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

    static bool Page(Color c)
    {
        int min = Math.Min(c.R, Math.Min(c.G, c.B));
        int max = Math.Max(c.R, Math.Max(c.G, c.B));
        return c.A < 16 || (min >= 236 && (max - min) < 28);
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

    static bool Pink(Color c)
    {
        int gap = c.R - Math.Max(c.G, c.B);
        return c.A >= 16 && c.R > 150 && gap > 80;
    }

    static PointF PinkCenter(Bitmap src)
    {
        double sx = 0;
        double sy = 0;
        int n = 0;
        for (int y = 0; y < src.Height; y++)
        for (int x = 0; x < src.Width; x++)
        {
            if (!Pink(src.GetPixel(x, y))) continue;
            sx += x;
            sy += y;
            n++;
        }
        if (n < 1) return new PointF(src.Width * 0.5f, 8f);
        return new PointF((float)(sx / n), (float)(sy / n));
    }

    static PointF BodyCenter(Bitmap src)
    {
        double sx = 0;
        double sy = 0;
        int n = 0;
        for (int y = 0; y < src.Height; y++)
        for (int x = 0; x < src.Width; x++)
        {
            Color c = src.GetPixel(x, y);
            if (c.A < 16 || Pink(c)) continue;
            sx += x;
            sy += y;
            n++;
        }
        if (n < 1) return new PointF(src.Width * 0.5f, src.Height * 0.5f);
        return new PointF((float)(sx / n), (float)(sy / n));
    }

    static float Angle(PointF from, PointF to)
    {
        return (float)(Math.Atan2(to.Y - from.Y, to.X - from.X) * 180.0 / Math.PI);
    }

    static int SpanW(Bitmap src)
    {
        int minX = src.Width;
        int maxX = 0;
        for (int y = 0; y < src.Height; y++)
        for (int x = 0; x < src.Width; x++)
        {
            if (src.GetPixel(x, y).A < 16) continue;
            if (x < minX) minX = x;
            if (x > maxX) maxX = x;
        }
        int span = maxX - minX;
        if (span < 1) return src.Width;
        return span;
    }

    static void Place(Graphics g, Bitmap art, float scale, float ox, float oy, float dx, float dy, float rot)
    {
        GraphicsState state = g.Save();
        g.TranslateTransform(dx, dy);
        g.RotateTransform(rot);
        g.ScaleTransform(scale, scale);
        g.TranslateTransform(-ox, -oy);
        g.DrawImage(art, 0, 0, art.Width, art.Height);
        g.Restore(state);
    }

    static Bitmap DrawFused(Bitmap sac, float sacScale, PointF sacOrigin, float sacRot, Bitmap shaft, float shaftScale, PointF shaftOrigin, float shaftRot, float dx, float dy, float ox, float oy, bool withShaft)
    {
        Bitmap bmp = new Bitmap(512, 512, PixelFormat.Format32bppArgb);
        using (Graphics g = Open(bmp))
        {
            Place(g, sac, sacScale, sacOrigin.X, sacOrigin.Y, dx, dy, sacRot);
            if (withShaft) Place(g, shaft, shaftScale, shaftOrigin.X, shaftOrigin.Y, dx + ox, dy + oy, shaftRot);
        }
        return bmp;
    }

    static Bitmap KeepRows(Bitmap src, int y0, int y1)
    {
        Bitmap bmp = new Bitmap(src.Width, src.Height, PixelFormat.Format32bppArgb);
        for (int y = y0; y < y1 && y < src.Height; y++)
        for (int x = 0; x < src.Width; x++)
        {
            Color c = src.GetPixel(x, y);
            if (c.A < 16) continue;
            bmp.SetPixel(x, y, c);
        }
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
        src.Dispose();
        return bmp;
    }

    static float Measure(Bitmap side, out PointF organBase, out PointF tip)
    {
        int maxX = 0;
        int minX = side.Width;
        for (int y = 0; y < side.Height; y++)
        for (int x = 0; x < side.Width; x++)
        {
            if (side.GetPixel(x, y).A < 16) continue;
            if (x > maxX) maxX = x;
            if (x < minX) minX = x;
        }
        double bx = 0, by = 0, bn = 0, tx = 0, ty = 0, tn = 0;
        for (int y = 0; y < side.Height; y++)
        for (int x = 0; x < side.Width; x++)
        {
            if (side.GetPixel(x, y).A < 16) continue;
            if (x < minX + 70) { bx += x; by += y; bn++; }
            if (x > maxX - 36) { tx += x; ty += y; tn++; }
        }
        organBase = new PointF((float)(bx / bn), (float)(by / bn));
        tip = new PointF((float)(tx / tn), (float)(ty / tn));
        return (float)(Math.Atan2(tip.Y - organBase.Y, tip.X - organBase.X) * 180.0 / Math.PI);
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

    static Bitmap DrawUpright(Bitmap art, float scale, float ox, float oy, float dx, float dy, float rot)
    {
        Bitmap bmp = new Bitmap(512, 512, PixelFormat.Format32bppArgb);
        using (Graphics g = Open(bmp))
        {
            GraphicsState state = g.Save();
            g.TranslateTransform(dx, dy);
            g.RotateTransform(rot);
            g.ScaleTransform(scale, scale);
            g.TranslateTransform(-ox, -oy);
            g.DrawImage(art, 0, 0, art.Width, art.Height);
            g.Restore(state);
        }
        return bmp;
    }

    static void SaveGene(Bitmap organ, string path)
    {
        Bitmap bmp = new Bitmap(512, 512, PixelFormat.Format32bppArgb);
        using (Graphics g = Open(bmp))
        {
            float scale = 460f / organ.Height;
            float dw = organ.Width * scale;
            float dh = organ.Height * scale;
            g.DrawImage(organ, (512f - dw) * 0.5f, (512f - dh) * 0.5f, dw, dh);
        }
        string dir = Path.GetDirectoryName(path);
        if (!string.IsNullOrEmpty(dir)) Directory.CreateDirectory(dir);
        Save(bmp, path);
        bmp.Dispose();
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
        Bitmap sheet = new Bitmap(980, 980, PixelFormat.Format32bppArgb);
        using (Graphics g = Open(sheet))
        {
            g.Clear(Color.FromArgb(255, 244, 240, 236));
            DrawLayer(g, Path.Combine(outRoot, "Balls", "LynxPenis_5_south.png"), Path.Combine(outRoot, "LynxPenis_5_south.png"), 16, 16);
            DrawLayer(g, Path.Combine(outRoot, "Balls", "LynxPenis_5_south.png"), Path.Combine(outRoot, "Horny", "LynxPenis_5_south.png"), 500, 16);
            DrawLayer(g, Path.Combine(outRoot, "Balls", "LynxPenis_5_east.png"), Path.Combine(outRoot, "LynxPenis_5_east.png"), 16, 500);
            DrawLayer(g, Path.Combine(outRoot, "Balls", "LynxPenis_5_east.png"), Path.Combine(outRoot, "Horny", "LynxPenis_5_east.png"), 500, 500);
        }
        sheet.Save(previewPath, ImageFormat.Png);
        sheet.Dispose();
        Console.WriteLine("PREVIEW " + previewPath);
    }

    static void DrawLayer(Graphics g, string back, string front, int x, int y)
    {
        using (Bitmap a = new Bitmap(back))
        using (Bitmap b = new Bitmap(front))
        {
            g.DrawImage(a, x, y, 460, 460);
            g.DrawImage(b, x, y, 460, 460);
        }
    }
}
'@

$inv = "C:\Users\mathi\Documents\Rimworld new mods\mods\RJWAnimalTextures\ArtInventory\TextureV2"
$live = "C:\Users\mathi\Documents\Rimworld new mods\mods\RJWAnimalTextures\Textures\SizedApparel\BodyParts\Human\Penis"
$gene = "C:\Users\mathi\Documents\Rimworld new mods\mods\RJWAnimalTextures\Textures\Genes\Icons\RJWAT_lynx.png"
$bigSrc = "C:\Users\mathi\.cursor\projects\c-Users-mathi-Documents-Rimworld-new-mods\assets\c__Users_mathi_AppData_Roaming_Cursor_User_workspaceStorage_f286a127b07b48d0b85590b38d17346c_images_Capture_d__cran_2026-10-15_102842-727fc935-d1c4-468d-b565-273471ce3024.png"
if (Test-Path $bigSrc) { Copy-Item $bigSrc (Join-Path $inv "ref-lynx-erect-big.png") -Force }
[LynxPenis]::Build(
    (Join-Path $inv "reference-lynx-south.png"),
    (Join-Path $inv "reference-lynx-side.png"),
    (Join-Path $inv "reference-fox-rest.png"),
    (Join-Path $inv "reference-fox-sideball.png"),
    (Join-Path $inv "ref-lynx-erect-big.png"),
    $live,
    $gene,
    (Join-Path $inv "preview-LynxPenis.png"))
