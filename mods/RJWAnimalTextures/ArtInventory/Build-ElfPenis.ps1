# ElfPenis sprites. The hediff is "a thinner and longer humanlike penis" and has no gene icon.
# Each file is the default human penis of the same size and direction, narrowed across the shaft
# and lengthened along it. The glans keeps more of its own shape than the shaft does.
# ElfPenis is not in BodypartDetail_Penis.xml, so the filenames have no variation suffix.
# Ball files are blank. The human penis art has no scrotum in it, and the human balls must not be drawn on top.
Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = "Stop"

Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;
using System.Runtime.InteropServices;

public static class ElfPenis
{
    const float ShaftEnd = 0.72f;
    const float LongScale = 1.42f;
    const float GlansScale = 1.08f;
    const float ThinShaft = 0.70f;
    const float ThinGlans = 0.86f;

    public static void Build(string sourceRoot, string penisRoot, string previewPath)
    {
        string hornyOut = Path.Combine(penisRoot, "Horny");
        string balls = Path.Combine(penisRoot, "Balls");
        Directory.CreateDirectory(penisRoot);
        Directory.CreateDirectory(hornyOut);
        Directory.CreateDirectory(balls);
        for (int size = 0; size <= 5; size++)
        {
            foreach (string dir in new string[] { "south", "east", "north" })
            {
                WarpFile(Path.Combine(sourceRoot, "Penis_" + size + "_" + dir + ".png"),
                    Path.Combine(penisRoot, "ElfPenis_" + size + "_" + dir + ".png"), dir, false);
                WarpFile(Path.Combine(sourceRoot, "Horny", "Penis_" + size + "_" + dir + ".png"),
                    Path.Combine(hornyOut, "ElfPenis_" + size + "_" + dir + ".png"), dir, true);
                Save(Blank(), Path.Combine(balls, "ElfPenis_" + size + "_" + dir + ".png"));
            }
        }
        BuildPreview(penisRoot, previewPath);
    }

    static void WarpFile(string sourcePath, string destPath, string dir, bool horny)
    {
        using (Bitmap src = new Bitmap(sourcePath))
        {
            Bitmap dest = Warp(src, dir, horny, Path.GetFileName(destPath));
            dest.Save(destPath, ImageFormat.Png);
            dest.Dispose();
        }
    }

    static Bitmap Warp(Bitmap src, string dir, bool horny, string label)
    {
        int w = src.Width;
        int h = src.Height;
        byte[] pix = Lock(src);
        int stride = Stride(w);
        int minX, minY, maxX, maxY, count;
        Bounds(pix, stride, w, h, out minX, out minY, out maxX, out maxY, out count);
        if (count < 24 || w <= 8 || h <= 8)
        {
            Console.WriteLine(label + " blank");
            return Blank();
        }

        bool side = dir == "east";
        float band = side ? (maxX - minX + 1) * 0.20f : (maxY - minY + 1) * 0.20f;
        if (band < 3f) band = 3f;
        float ax = 0f, ay = 0f, an = 0f;
        for (int y = minY; y <= maxY; y++)
        {
            int row = y * stride;
            for (int x = minX; x <= maxX; x++)
            {
                if (pix[row + x * 4 + 3] < 16) continue;
                bool root = side ? x <= minX + band : (horny ? y >= maxY - band : y <= minY + band);
                if (!root) continue;
                ax += x + 0.5f;
                ay += y + 0.5f;
                an++;
            }
        }
        if (an < 1f)
        {
            Console.WriteLine(label + " blank");
            return Blank();
        }
        ax /= an;
        ay /= an;

        float far = 0f;
        for (int y = minY; y <= maxY; y++)
        {
            int row = y * stride;
            for (int x = minX; x <= maxX; x++)
            {
                if (pix[row + x * 4 + 3] < 16) continue;
                float dx = (x + 0.5f) - ax;
                float dy = (y + 0.5f) - ay;
                float d = dx * dx + dy * dy;
                if (d > far) far = d;
            }
        }
        float reach = (float)Math.Sqrt(far);
        float tx = 0f, ty = 0f, tn = 0f;
        float gate = reach * 0.92f;
        for (int y = minY; y <= maxY; y++)
        {
            int row = y * stride;
            for (int x = minX; x <= maxX; x++)
            {
                if (pix[row + x * 4 + 3] < 16) continue;
                float dx = (x + 0.5f) - ax;
                float dy = (y + 0.5f) - ay;
                if (dx * dx + dy * dy < gate * gate) continue;
                tx += x + 0.5f;
                ty += y + 0.5f;
                tn++;
            }
        }
        if (tn < 1f)
        {
            tx = ax;
            ty = ay + (horny && !side ? -reach : reach);
            tn = 1f;
        }
        tx /= tn;
        ty /= tn;
        float organLen = (float)Math.Sqrt((tx - ax) * (tx - ax) + (ty - ay) * (ty - ay));
        if (organLen < 6f)
        {
            Console.WriteLine(label + " blank");
            return Blank();
        }
        float ux = (tx - ax) / organLen;
        float uy = (ty - ay) / organLen;

        float longScale = LongScale;
        for (int attempt = 0; attempt < 10; attempt++)
        {
            float tipAlong = ForwardAlong(organLen + 8f, organLen, longScale);
            float px = ax + ux * tipAlong;
            float py = ay + uy * tipAlong;
            if (px >= 10f && px < w - 10f && py >= 10f && py < h - 10f) break;
            longScale = 1f + (longScale - 1f) * 0.82f;
        }

        Bitmap dest = new Bitmap(w, h, PixelFormat.Format32bppArgb);
        byte[] outPix = new byte[stride * h];
        for (int y = 0; y < h; y++)
        {
            for (int x = 0; x < w; x++)
            {
                float vx = (x + 0.5f) - ax;
                float vy = (y + 0.5f) - ay;
                float alongD = vx * ux + vy * uy;
                float px = vx - alongD * ux;
                float py = vy - alongD * uy;
                float u;
                float along = InverseAlong(alongD, organLen, longScale, out u);
                float thin = ThinAt(u);
                float sx = ax + ux * along + px / thin;
                float sy = ay + uy * along + py / thin;
                int a, r, g, b;
                if (!Sample(pix, stride, w, h, sx, sy, out a, out r, out g, out b)) continue;
                if (a < 14) continue;
                int i = y * stride + x * 4;
                outPix[i] = (byte)b;
                outPix[i + 1] = (byte)g;
                outPix[i + 2] = (byte)r;
                outPix[i + 3] = (byte)a;
            }
        }
        Unlock(dest, outPix, stride);
        int dminX, dminY, dmaxX, dmaxY, dn;
        Bounds(outPix, stride, w, h, out dminX, out dminY, out dmaxX, out dmaxY, out dn);
        Console.WriteLine(label + " scale=" + longScale.ToString("0.00")
            + " from " + (maxX - minX + 1) + "x" + (maxY - minY + 1)
            + " to " + (dmaxX - dminX + 1) + "x" + (dmaxY - dminY + 1));
        return dest;
    }

    static float ForwardAlong(float along, float organLen, float longScale)
    {
        float u = along / organLen;
        if (u <= 0f) return along;
        if (u <= ShaftEnd) return along * longScale;
        float shaftOut = organLen * ShaftEnd * longScale;
        float glansU = (u - ShaftEnd) / (1f - ShaftEnd);
        return shaftOut + glansU * organLen * (1f - ShaftEnd) * GlansScale;
    }

    static float InverseAlong(float alongD, float organLen, float longScale, out float u)
    {
        float shaftOut = organLen * ShaftEnd * longScale;
        float glansLen = organLen * (1f - ShaftEnd) * GlansScale;
        if (alongD <= 0f)
        {
            u = alongD / organLen;
            return alongD;
        }
        if (alongD <= shaftOut || glansLen < 0.001f)
        {
            float along = alongD / longScale;
            u = along / organLen;
            return along;
        }
        float glansU = (alongD - shaftOut) / glansLen;
        u = ShaftEnd + glansU * (1f - ShaftEnd);
        return u * organLen;
    }

    static float ThinAt(float u)
    {
        if (u <= ShaftEnd) return ThinShaft;
        if (u >= 0.90f) return ThinGlans;
        float t = (u - ShaftEnd) / (0.90f - ShaftEnd);
        return ThinShaft + (ThinGlans - ThinShaft) * t;
    }

    static bool Sample(byte[] pix, int stride, int w, int h, float x, float y, out int a, out int r, out int g, out int b)
    {
        a = r = g = b = 0;
        if (x < 0f || y < 0f || x >= w - 1f || y >= h - 1f) return false;
        int x0 = (int)Math.Floor(x);
        int y0 = (int)Math.Floor(y);
        float fx = x - x0;
        float fy = y - y0;
        float ba = 0f, br = 0f, bg = 0f, bb = 0f, bw = 0f;
        Accumulate(pix, stride, x0, y0, (1f - fx) * (1f - fy), ref ba, ref br, ref bg, ref bb, ref bw);
        Accumulate(pix, stride, x0 + 1, y0, fx * (1f - fy), ref ba, ref br, ref bg, ref bb, ref bw);
        Accumulate(pix, stride, x0, y0 + 1, (1f - fx) * fy, ref ba, ref br, ref bg, ref bb, ref bw);
        Accumulate(pix, stride, x0 + 1, y0 + 1, fx * fy, ref ba, ref br, ref bg, ref bb, ref bw);
        if (bw < 0.001f) return false;
        a = Clamp(ba / bw);
        r = Clamp((br / bw) / (ba / bw > 0.001f ? ba / bw : 1f));
        g = Clamp((bg / bw) / (ba / bw > 0.001f ? ba / bw : 1f));
        b = Clamp((bb / bw) / (ba / bw > 0.001f ? ba / bw : 1f));
        a = Clamp(ba / bw);
        return a > 0;
    }

    static void Accumulate(byte[] pix, int stride, int x, int y, float weight, ref float a, ref float r, ref float g, ref float b, ref float covered)
    {
        int i = y * stride + x * 4;
        float alpha = pix[i + 3] / 255f;
        float m = weight * alpha;
        b += pix[i] / 255f * m;
        g += pix[i + 1] / 255f * m;
        r += pix[i + 2] / 255f * m;
        a += m;
        covered += weight;
    }

    static int Clamp(float v)
    {
        int i = (int)Math.Round(v * 255f);
        if (i < 0) return 0;
        if (i > 255) return 255;
        return i;
    }

    static void Bounds(byte[] pix, int stride, int w, int h, out int minX, out int minY, out int maxX, out int maxY, out int count)
    {
        minX = w;
        minY = h;
        maxX = -1;
        maxY = -1;
        count = 0;
        for (int y = 0; y < h; y++)
        {
            int row = y * stride;
            for (int x = 0; x < w; x++)
            {
                if (pix[row + x * 4 + 3] < 16) continue;
                if (x < minX) minX = x;
                if (y < minY) minY = y;
                if (x > maxX) maxX = x;
                if (y > maxY) maxY = y;
                count++;
            }
        }
    }

    static byte[] Lock(Bitmap bmp)
    {
        int stride = Stride(bmp.Width);
        byte[] pix = new byte[stride * bmp.Height];
        BitmapData data = bmp.LockBits(new Rectangle(0, 0, bmp.Width, bmp.Height), ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
        Marshal.Copy(data.Scan0, pix, 0, pix.Length);
        bmp.UnlockBits(data);
        return pix;
    }

    static void Unlock(Bitmap bmp, byte[] pix, int stride)
    {
        BitmapData data = bmp.LockBits(new Rectangle(0, 0, bmp.Width, bmp.Height), ImageLockMode.WriteOnly, PixelFormat.Format32bppArgb);
        Marshal.Copy(pix, 0, data.Scan0, stride * bmp.Height);
        bmp.UnlockBits(data);
    }

    static int Stride(int width)
    {
        return width * 4;
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

    static void BuildPreview(string penisRoot, string previewPath)
    {
        Bitmap sheet = new Bitmap(1200, 980, PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(sheet))
        {
            g.Clear(Color.FromArgb(255, 18, 18, 22));
            g.InterpolationMode = System.Drawing.Drawing2D.InterpolationMode.NearestNeighbor;
            g.PixelOffsetMode = System.Drawing.Drawing2D.PixelOffsetMode.Half;
            string[] dirs = new string[] { "south", "south", "east", "east", "north" };
            bool[] horny = new bool[] { false, true, false, true, false };
            for (int row = 0; row < dirs.Length; row++)
            {
                for (int size = 0; size <= 5; size++)
                {
                    string folder = horny[row] ? Path.Combine(penisRoot, "Horny") : penisRoot;
                    string path = Path.Combine(folder, "ElfPenis_" + size + "_" + dirs[row] + ".png");
                    using (Bitmap bmp = new Bitmap(path))
                    {
                        if (bmp.Width <= 8) continue;
                        int minX, minY, maxX, maxY, count;
                        byte[] pix = Lock(bmp);
                        Bounds(pix, Stride(bmp.Width), bmp.Width, bmp.Height, out minX, out minY, out maxX, out maxY, out count);
                        if (count < 1) continue;
                        int pad = 4;
                        int sx = Math.Max(0, minX - pad);
                        int sy = Math.Max(0, minY - pad);
                        int sw = Math.Min(bmp.Width - sx, (maxX - minX + 1) + pad * 2);
                        int sh = Math.Min(bmp.Height - sy, (maxY - minY + 1) + pad * 2);
                        Rectangle cell = new Rectangle(16 + size * 196, 16 + row * 192, 180, 176);
                        float scale = Math.Min(cell.Width / (float)sw, cell.Height / (float)sh);
                        int dw = Math.Max(1, (int)(sw * scale));
                        int dh = Math.Max(1, (int)(sh * scale));
                        Rectangle dest = new Rectangle(cell.X + (cell.Width - dw) / 2, cell.Y + (cell.Height - dh) / 2, dw, dh);
                        g.DrawImage(bmp, dest, new Rectangle(sx, sy, sw, sh), GraphicsUnit.Pixel);
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

$source = "C:\Program Files (x86)\Steam\steamapps\common\RimWorld\Mods\sized-apparel-zero\Textures\SizedApparel\BodyParts\Human\Penis"
$dest = "C:\Users\mathi\Documents\Rimworld new mods\mods\RJWAnimalTextures\Textures\SizedApparel\BodyParts\Human\Penis"
$preview = "C:\Users\mathi\Documents\Rimworld new mods\mods\RJWAnimalTextures\ArtInventory\TextureV2\preview-ElfPenis.png"
[ElfPenis]::Build($source, $dest, $preview)
