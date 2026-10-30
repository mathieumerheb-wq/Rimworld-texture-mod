# Dragon rest slits. Sizes 0-1 use the closed slit, 2-3 the middle opening, 4-5 the widest.
# Each band has its own side view, faced right. Balls stay blank because the scrotum is already in the picture.
# Aroused sprites are left alone.
Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = "Stop"

Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;

public static class DragonSlits
{
    public static void Build(
        string closedFront, string midFront, string wideFront,
        string closedSide, string midSide, string openSide,
        string outRoot, string ballDir, string previewPath)
    {
        Directory.CreateDirectory(outRoot);
        Directory.CreateDirectory(ballDir);
        Bitmap f0 = Largest(Load(closedFront));
        Bitmap f2 = Largest(Load(midFront));
        Bitmap f4 = Largest(Load(wideFront));
        Bitmap s0 = FaceRight(Largest(Load(closedSide)));
        Bitmap s2 = FaceRight(Largest(Load(midSide)));
        Bitmap s4 = FaceRight(Largest(Load(openSide)));
        float[] height = new float[] { 82f, 100f, 120f, 142f, 166f, 192f };
        Bitmap[] south = new Bitmap[] { f0, f0, f2, f2, f4, f4 };
        Bitmap[] east = new Bitmap[] { s0, s0, s2, s2, s4, s4 };
        for (int size = 0; size <= 5; size++)
        {
            Save(Place(south[size], height[size], 256f, 430f), Path.Combine(outRoot, FileName(size, "south")));
            Save(Place(east[size], height[size], 230f, 420f), Path.Combine(outRoot, FileName(size, "east")));
            Save(Blank(), Path.Combine(ballDir, FileName(size, "south")));
            Save(Blank(), Path.Combine(ballDir, FileName(size, "east")));
            Save(Blank(), Path.Combine(ballDir, FileName(size, "north")));
        }
        BuildPreview(outRoot, previewPath);
        f0.Dispose();
        f2.Dispose();
        f4.Dispose();
        s0.Dispose();
        s2.Dispose();
        s4.Dispose();
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
        return c.A >= 16 && c.R > 140 && (c.R - c.G) > 28 && (c.R - c.B) > 18;
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

    static Bitmap FaceRight(Bitmap src)
    {
        int minY = src.Height;
        int maxY = 0;
        double bodyX = 0;
        int bodyN = 0;
        for (int y = 0; y < src.Height; y++)
        for (int x = 0; x < src.Width; x++)
        {
            if (src.GetPixel(x, y).A < 16) continue;
            if (y < minY) minY = y;
            if (y > maxY) maxY = y;
            bodyX += x;
            bodyN++;
        }
        int top = minY + Math.Max(4, (maxY - minY) / 4);
        double pinkX = 0;
        int pinkN = 0;
        for (int y = minY; y <= top; y++)
        for (int x = 0; x < src.Width; x++)
        {
            if (!Pink(src.GetPixel(x, y))) continue;
            pinkX += x;
            pinkN++;
        }
        bool left = pinkN > 0 && bodyN > 0 && (pinkX / pinkN) < (bodyX / bodyN) - 2.0;
        Console.WriteLine("side opening left=" + left);
        if (!left) return src;
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

    static Bitmap Place(Bitmap art, float targetH, float dx, float dy)
    {
        float scale = targetH / ContentH(art);
        PointF origin = BottomCenter(art);
        Bitmap bmp = new Bitmap(512, 512, PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(bmp))
        {
            g.SmoothingMode = SmoothingMode.HighQuality;
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
            g.PixelOffsetMode = PixelOffsetMode.HighQuality;
            g.TranslateTransform(dx, dy);
            g.ScaleTransform(scale, scale);
            g.TranslateTransform(-origin.X, -origin.Y);
            g.DrawImage(art, 0, 0, art.Width, art.Height);
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
        Bitmap sheet = new Bitmap(1040, 1680, PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(sheet))
        {
            g.Clear(Color.FromArgb(255, 244, 240, 236));
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
            using (Font font = new Font("Segoe UI", 18f, FontStyle.Regular, GraphicsUnit.Pixel))
            using (Brush brush = new SolidBrush(Color.FromArgb(255, 40, 32, 28)))
            {
                g.DrawString("Rest south", font, brush, 24, 8);
                g.DrawString("Rest east", font, brush, 530, 8);
                for (int size = 0; size <= 5; size++)
                {
                    int y = 36 + size * 270;
                    g.DrawString("Size " + size, font, brush, 24, y);
                    using (Bitmap south = new Bitmap(Path.Combine(outRoot, FileName(size, "south"))))
                    using (Bitmap east = new Bitmap(Path.Combine(outRoot, FileName(size, "east"))))
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
$inv = "C:\Users\mathi\Documents\Rimworld new mods\mods\RJWAnimalTextures\ArtInventory\TextureV2"
$live = "C:\Users\mathi\Documents\Rimworld new mods\sized-apparel-zero\Textures\SizedApparel\BodyParts\Human\Penis"
Copy-Item (Join-Path $src "c__Users_mathi_AppData_Roaming_Cursor_User_workspaceStorage_f286a127b07b48d0b85590b38d17346c_images_Capture_d__cran_2026-10-15_103236-e46f0aea-7d1a-459f-a396-26b05cb8b229.png") (Join-Path $inv "ref-dragon-slit-front-closed.png")
Copy-Item (Join-Path $src "c__Users_mathi_AppData_Roaming_Cursor_User_workspaceStorage_f286a127b07b48d0b85590b38d17346c_images_Capture_d__cran_2026-10-15_103231-e75e3779-9282-49a8-a869-883ca9a6adbd.png") (Join-Path $inv "ref-dragon-slit-front-mid.png")
Copy-Item (Join-Path $src "c__Users_mathi_AppData_Roaming_Cursor_User_workspaceStorage_f286a127b07b48d0b85590b38d17346c_images_Capture_d__cran_2026-10-15_103234-f57110bb-a81f-4145-b56e-c28ed018e8e9.png") (Join-Path $inv "ref-dragon-slit-front-wide.png")
Copy-Item (Join-Path $src "c__Users_mathi_AppData_Roaming_Cursor_User_workspaceStorage_f286a127b07b48d0b85590b38d17346c_images_Capture_d__cran_2026-10-15_103240-5872b49f-422f-4e9c-b577-458c1b92d79b.png") (Join-Path $inv "ref-dragon-slit-side-closed.png")
Copy-Item (Join-Path $src "c__Users_mathi_AppData_Roaming_Cursor_User_workspaceStorage_f286a127b07b48d0b85590b38d17346c_images_Capture_d__cran_2026-10-15_103243-5d9e0e7b-7c87-4068-8281-a426481211ba.png") (Join-Path $inv "ref-dragon-slit-side-open.png")
Copy-Item (Join-Path $src "c__Users_mathi_AppData_Roaming_Cursor_User_workspaceStorage_f286a127b07b48d0b85590b38d17346c_images_Capture_d__cran_2026-10-15_103914-43b3e60d-abc2-4274-ba14-f00d82e74c67.png") (Join-Path $inv "ref-dragon-slit-side-mid.png")
[DragonSlits]::Build(
    (Join-Path $inv "ref-dragon-slit-front-closed.png"),
    (Join-Path $inv "ref-dragon-slit-front-mid.png"),
    (Join-Path $inv "ref-dragon-slit-front-wide.png"),
    (Join-Path $inv "ref-dragon-slit-side-closed.png"),
    (Join-Path $inv "ref-dragon-slit-side-mid.png"),
    (Join-Path $inv "ref-dragon-slit-side-open.png"),
    $live,
    (Join-Path $live "Balls"),
    (Join-Path $inv "preview-DragonSlits.png"))
