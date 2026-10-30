# Dragon aroused sprites. Sizes 0-1 are the short penises. Sizes 2-5 are longer pictures, one each.
# South points up. East points up-right. Rest slits and ball files are left alone.
Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = "Stop"

Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;

public static class DragonErect
{
    public static void Build(string[] southPaths, string[] eastPaths, string hornyDir, string previewPath)
    {
        Directory.CreateDirectory(hornyDir);
        float[] height = new float[] { 180f, 214f, 252f, 294f, 338f, 380f };
        for (int size = 0; size <= 5; size++)
        {
            Bitmap south = FaceRight(Largest(Load(southPaths[size])));
            Bitmap east = FaceRight(Largest(Load(eastPaths[size])));
            float southAngle = ShaftAngle(south);
            float eastAngle = ShaftAngle(east);
            float southRot = -90f - southAngle;
            float eastRot = -45f - eastAngle;
            if (Math.Abs(southAngle + 90f) < 8f) southRot = 0f;
            Console.WriteLine("Dragon " + size
                + " southAngle " + southAngle.ToString("0.0") + " rot " + southRot.ToString("0.0")
                + " eastAngle " + eastAngle.ToString("0.0") + " rot " + eastRot.ToString("0.0"));
            Save(Place(south, height[size], southRot, 256f, 430f), Path.Combine(hornyDir, FileName(size, "south")));
            Save(Place(east, height[size], eastRot, 230f, 420f), Path.Combine(hornyDir, FileName(size, "east")));
            south.Dispose();
            east.Dispose();
        }
        BuildPreview(hornyDir, previewPath);
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

    static bool Red(Color c)
    {
        return c.A >= 16 && c.R > 105 && (c.R - Math.Max(c.G, c.B)) > 18 && c.G < 165;
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
        tip = tn > 0 ? new PointF((float)(tx / tn), (float)(ty / tn)) : new PointF(rx, ry);
        root = new PointF(rx, ry);
    }

    static float ShaftAngle(Bitmap src)
    {
        PointF tip, root;
        Ends(src, out tip, out root);
        return (float)(Math.Atan2(tip.Y - root.Y, tip.X - root.X) * 180.0 / Math.PI);
    }

    static Bitmap FaceRight(Bitmap src)
    {
        PointF tip, root;
        Ends(src, out tip, out root);
        bool side = Math.Abs(tip.X - root.X) > Math.Abs(tip.Y - root.Y) * 0.55f;
        if (!side || tip.X >= root.X - 6f) return src;
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
        int y0 = maxY - 8;
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

    static Bitmap Place(Bitmap art, float targetH, float rot, float dx, float dy)
    {
        PointF origin = BottomCenter(art);
        PointF tip, root;
        Ends(art, out tip, out root);
        float len = (float)Math.Sqrt((tip.X - origin.X) * (tip.X - origin.X) + (tip.Y - origin.Y) * (tip.Y - origin.Y));
        if (len < 8f) len = 8f;
        float scale = targetH / len;
        Bitmap bmp = new Bitmap(512, 512, PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(bmp))
        {
            g.SmoothingMode = SmoothingMode.HighQuality;
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
            g.PixelOffsetMode = PixelOffsetMode.HighQuality;
            g.TranslateTransform(dx, dy);
            g.RotateTransform(rot);
            g.ScaleTransform(scale, scale);
            g.TranslateTransform(-origin.X, -origin.Y);
            g.DrawImage(art, 0, 0, art.Width, art.Height);
        }
        return bmp;
    }

    static void Save(Bitmap bmp, string path)
    {
        bmp.Save(path, ImageFormat.Png);
        bmp.Dispose();
    }

    static void BuildPreview(string hornyDir, string previewPath)
    {
        Bitmap sheet = new Bitmap(1040, 1680, PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(sheet))
        {
            g.Clear(Color.FromArgb(255, 244, 240, 236));
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
            using (Font font = new Font("Segoe UI", 18f, FontStyle.Regular, GraphicsUnit.Pixel))
            using (Brush brush = new SolidBrush(Color.FromArgb(255, 40, 32, 28)))
            {
                g.DrawString("Erect south", font, brush, 24, 8);
                g.DrawString("Erect east", font, brush, 530, 8);
                for (int size = 0; size <= 5; size++)
                {
                    int y = 36 + size * 270;
                    g.DrawString("Size " + size, font, brush, 24, y);
                    using (Bitmap south = new Bitmap(Path.Combine(hornyDir, FileName(size, "south"))))
                    using (Bitmap east = new Bitmap(Path.Combine(hornyDir, FileName(size, "east"))))
                    {
                        g.DrawImage(south, 24, y + 24, 250, 250);
                        g.DrawImage(east, 530, y + 24, 250, 250);
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

$src = "C:\Users\mathi\.cursor\projects\c-Users-mathi-Documents-Rimworld-new-mods\assets"
$prefix = "c__Users_mathi_AppData_Roaming_Cursor_User_workspaceStorage_f286a127b07b48d0b85590b38d17346c_images_Capture_d__cran_2026-10-15_"
$inv = "C:\Users\mathi\Documents\Rimworld new mods\mods\RJWAnimalTextures\ArtInventory\TextureV2"
$horny = "C:\Users\mathi\Documents\Rimworld new mods\sized-apparel-zero\Textures\SizedApparel\BodyParts\Human\Penis\Horny"
function Copy-Ref($id, $name) {
    Copy-Item (Join-Path $src ($prefix + $id + ".png")) (Join-Path $inv $name)
    return (Join-Path $inv $name)
}
$south = @(
    (Copy-Ref "102722-0ac6e203-65a2-438f-82dd-4e8910611c19" "ref-dragon-erect-s0.png"),
    (Copy-Ref "103651-2a389fa0-a975-4307-b8df-40450b6caa37" "ref-dragon-erect-s1.png"),
    (Copy-Ref "103551-84f50a60-9633-41a5-a0be-415cddddfd70" "ref-dragon-erect-s2.png"),
    (Copy-Ref "103910-e1530f9e-701b-41f4-a9e0-739cca2ef8d4" "ref-dragon-erect-s3.png"),
    (Copy-Ref "102643-8bd04c2c-553c-46a3-abd3-564cf0c913ed" "ref-dragon-erect-s4.png"),
    (Copy-Ref "103900-2928bc54-bc17-4ac2-aa99-062f85799ab7" "ref-dragon-erect-s5.png")
)
$east = @(
    (Copy-Ref "102648-b6014dd7-0565-4399-a320-813dc0651a70" "ref-dragon-erect-e0.png"),
    (Copy-Ref "104702-277b5e9f-5a37-4ffc-8a19-8fda3b041059" "ref-dragon-erect-e1.png"),
    (Copy-Ref "103148-2bc227c9-b8ee-4127-aa8c-42f912bc75d0" "ref-dragon-erect-e2.png"),
    (Copy-Ref "103541-7493b0d4-4935-4a86-aa84-c788454d5cc2" "ref-dragon-erect-e3.png"),
    (Copy-Ref "102707-3606e9e5-90fa-4bf6-b9f1-77a1ee8237f9" "ref-dragon-erect-e4.png"),
    (Copy-Ref "104654-13d47759-cbfd-4c49-a387-b3b76e5c106d" "ref-dragon-erect-e5.png")
)
[DragonErect]::Build($south, $east, $horny, (Join-Path $inv "preview-DragonErect.png"))
