# Fox size 4 erect is the slimmer knotted front. Wolf size 4 erect is the thicker veined front.
# Both pictures already include the knot and the scrotum. Rests, balls, north, and the other sizes stay.
# Wolf size 4 east is not written here: a front picture leaned up-right read as a front view on the side.
Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = "Stop"

Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;

public static class CanineKnot
{
    public static void Build(string foxSrc, string wolfSrc, string hornyDir, string previewPath)
    {
        using (Bitmap fox = Largest(Load(foxSrc)))
        using (Bitmap wolf = Largest(Load(wolfSrc)))
        {
            Place(fox, Path.Combine(hornyDir, "FoxPenis_4_south.png"), 188f, 256f, 402f, true);
            Place(fox, Path.Combine(hornyDir, "FoxPenis_4_east.png"), 188f, 220f, 408f, false);
            Place(wolf, Path.Combine(hornyDir, "WolfPenis_4_south.png"), 210f, 256f, 408f, true);
            // Wolf size 4 east is a side view from ref-big-b, written by Build-WolfSide4.ps1.
        }
        Preview(hornyDir, previewPath);
    }

    static void Place(Bitmap art, string dest, float targetH, float dx, float dy, bool south)
    {
        float angle = ShaftAngle(art);
        float rot = (south ? -90f : -45f) - angle;
        if (south && Math.Abs(angle + 90f) < 12f) rot = 0f;
        float scale = targetH / ContentH(art);
        PointF root = BottomCenter(art);
        Console.WriteLine(Path.GetFileName(dest) + " angle " + angle.ToString("0.0") + " rot " + rot.ToString("0.0"));
        Bitmap bmp = new Bitmap(512, 512, PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(bmp))
        {
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
            g.PixelOffsetMode = PixelOffsetMode.HighQuality;
            g.TranslateTransform(dx, dy);
            g.RotateTransform(rot);
            g.ScaleTransform(scale, scale);
            g.TranslateTransform(-root.X, -root.Y);
            g.DrawImage(art, 0, 0, art.Width, art.Height);
        }
        bmp.Save(dest, ImageFormat.Png);
        bmp.Dispose();
    }

    static bool Page(Color c)
    {
        int min = Math.Min(c.R, Math.Min(c.G, c.B));
        int max = Math.Max(c.R, Math.Max(c.G, c.B));
        return c.A < 16 || (min >= 248 && (max - min) < 14);
    }

    static bool Red(Color c)
    {
        return c.A > 16 && c.R > 150 && (c.R - Math.Max(c.G, c.B)) > 28 && c.G < 190;
    }

    static Bitmap Load(string path)
    {
        using (Bitmap source = new Bitmap(path))
        {
            int w = source.Width;
            int h = source.Height;
            bool[,] bg = new bool[w, h];
            var queue = new System.Collections.Generic.Queue<int>();
            for (int y = 0; y < h; y++)
            for (int x = 0; x < w; x++)
            {
                if (x != 0 && y != 0 && x != w - 1 && y != h - 1) continue;
                if (!Page(source.GetPixel(x, y))) continue;
                bg[x, y] = true;
                queue.Enqueue(y * w + x);
            }
            int[] dxs = new int[] { -1, 1, 0, 0 };
            int[] dys = new int[] { 0, 0, -1, 1 };
            while (queue.Count > 0)
            {
                int id = queue.Dequeue();
                int x = id % w;
                int y = id / w;
                for (int i = 0; i < 4; i++)
                {
                    int nx = x + dxs[i];
                    int ny = y + dys[i];
                    if (nx < 0 || ny < 0 || nx >= w || ny >= h || bg[nx, ny]) continue;
                    if (!Page(source.GetPixel(nx, ny))) continue;
                    bg[nx, ny] = true;
                    queue.Enqueue(ny * w + nx);
                }
            }
            Bitmap bmp = new Bitmap(w, h, PixelFormat.Format32bppArgb);
            for (int y = 0; y < h; y++)
            for (int x = 0; x < w; x++)
            {
                if (bg[x, y]) continue;
                Color c = source.GetPixel(x, y);
                bmp.SetPixel(x, y, Color.FromArgb(255, c.R, c.G, c.B));
            }
            return bmp;
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
            qx[tail] = x;
            qy[tail] = y;
            tail++;
            id[y * w + x] = next;
            int count = 0;
            while (head < tail)
            {
                int cx = qx[head];
                int cy = qy[head];
                head++;
                count++;
                for (int oy = -1; oy <= 1; oy++)
                for (int ox = -1; ox <= 1; ox++)
                {
                    int nx = cx + ox;
                    int ny = cy + oy;
                    if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue;
                    if (src.GetPixel(nx, ny).A < 16 || id[ny * w + nx] != 0) continue;
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

    static float ShaftAngle(Bitmap src)
    {
        int minY = src.Height;
        int maxY = 0;
        for (int y = 0; y < src.Height; y++)
        for (int x = 0; x < src.Width; x++)
        {
            if (!Red(src.GetPixel(x, y))) continue;
            if (y < minY) minY = y;
            if (y > maxY) maxY = y;
        }
        int span = Math.Max(1, maxY - minY);
        int mid0 = minY + (int)(span * 0.32f);
        int mid1 = minY + (int)(span * 0.52f);
        double topX = 0, topN = 0, botX = 0, botY = 0, botN = 0;
        for (int y = 0; y < src.Height; y++)
        for (int x = 0; x < src.Width; x++)
        {
            if (!Red(src.GetPixel(x, y))) continue;
            if (y <= minY + 10) { topX += x; topN++; }
            if (y >= mid0 && y <= mid1) { botX += x; botY += y; botN++; }
        }
        if (topN < 1 || botN < 1) return -90f;
        return (float)(Math.Atan2(minY - (botY / botN), (topX / topN) - (botX / botN)) * 180.0 / Math.PI);
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
        int y0 = Math.Max(0, maxY - 4);
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

    static void Preview(string hornyDir, string previewPath)
    {
        Bitmap sheet = new Bitmap(640, 360, PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(sheet))
        {
            g.Clear(Color.FromArgb(255, 22, 22, 26));
            g.InterpolationMode = InterpolationMode.NearestNeighbor;
            string[] names = new string[] { "FoxPenis_4_south.png", "FoxPenis_4_east.png", "WolfPenis_4_south.png", "WolfPenis_4_east.png" };
            for (int i = 0; i < names.Length; i++)
            {
                using (Bitmap b = new Bitmap(Path.Combine(hornyDir, names[i])))
                    g.DrawImage(b, 16 + (i % 2) * 300, 16 + (i / 2) * 170, 280, 150);
            }
        }
        sheet.Save(previewPath, ImageFormat.Png);
        sheet.Dispose();
    }
}
'@

$assets = "C:\Users\mathi\.cursor\projects\c-Users-mathi-Documents-Rimworld-new-mods\assets"
$inv = "C:\Users\mathi\Documents\Rimworld new mods\mods\RJWAnimalTextures\ArtInventory\TextureV2"
$fox = Join-Path $inv "ref-fox-knot-front.png"
$wolf = Join-Path $inv "ref-wolf-knot-front.png"
Copy-Item (Join-Path $assets "c__Users_mathi_AppData_Roaming_Cursor_User_workspaceStorage_f286a127b07b48d0b85590b38d17346c_images_Capture_d__cran_2026-10-15_132525-c0907a87-db48-4be0-8d15-bdf6313ca7a0.png") $fox -Force
Copy-Item (Join-Path $assets "c__Users_mathi_AppData_Roaming_Cursor_User_workspaceStorage_f286a127b07b48d0b85590b38d17346c_images_Capture_d__cran_2026-10-15_132822-fbe0f612-5da2-49e8-a84b-459a3bfd9a05.png") $wolf -Force
$horny = "C:\Users\mathi\Documents\Rimworld new mods\mods\RJWAnimalTextures\Textures\SizedApparel\BodyParts\Human\Penis\Horny"
[CanineKnot]::Build($fox, $wolf, $horny, (Join-Path $inv "preview-CanineKnot.png"))
