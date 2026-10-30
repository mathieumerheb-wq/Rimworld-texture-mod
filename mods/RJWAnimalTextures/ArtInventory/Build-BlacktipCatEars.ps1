# Black-tipped cat ears. South is the front pair, north is the back, east is the side ear.
# They sit on a 512 canvas in the same place as the feline ears.
# The gray disk under the side ear is dropped. Painted fur stays its own color.
Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = "Stop"

Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;

public static class BlacktipCatEars
{
    public static void Build(string southPath, string northPath, string eastPath, string catDir, string outDir, string genePath, string previewPath)
    {
        Directory.CreateDirectory(outDir);
        using (Bitmap south = Prepare(southPath, false))
        using (Bitmap north = Prepare(northPath, false))
        using (Bitmap east = Prepare(eastPath, true))
        {
            SavePlaced(south, 118f, 227f, 256f, Path.Combine(outDir, "BlacktipCatEars_south.png"));
            SavePlaced(north, 118f, 227f, 256f, Path.Combine(outDir, "BlacktipCatEars_north.png"));
            SavePlaced(east, 124f, 229f, 246f, Path.Combine(outDir, "BlacktipCatEars_east.png"));
            SaveGene(south, genePath);
            BuildPreview(catDir, outDir, previewPath);
        }
    }

    static bool Page(Color c)
    {
        int min = Math.Min(c.R, Math.Min(c.G, c.B));
        int max = Math.Max(c.R, Math.Max(c.G, c.B));
        return min >= 254 && (max - min) < 6;
    }

    static bool Disk(Color c)
    {
        if (c.A < 16) return false;
        int min = Math.Min(c.R, Math.Min(c.G, c.B));
        int max = Math.Max(c.R, Math.Max(c.G, c.B));
        return min >= 110 && max <= 190 && (max - min) < 40 && c.B + 4 >= c.R;
    }

    static Bitmap Prepare(string path, bool dropDisk)
    {
        using (Bitmap source = new Bitmap(path))
        {
            int w = source.Width;
            int h = source.Height;
            Bitmap bmp = new Bitmap(w, h, PixelFormat.Format32bppArgb);
            bool[,] bg = new bool[w, h];
            var queue = new Queue<int>();
            for (int y = 0; y < h; y++)
            for (int x = 0; x < w; x++)
            {
                if (x != 0 && y != 0 && x != w - 1 && y != h - 1) continue;
                Color c = source.GetPixel(x, y);
                if (!Page(c)) continue;
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
            for (int y = 0; y < h; y++)
            for (int x = 0; x < w; x++)
            {
                if (bg[x, y]) continue;
                Color c = source.GetPixel(x, y);
                if (c.A < 16 || Page(c)) continue;
                bool fringe = false;
                if (Math.Min(c.R, Math.Min(c.G, c.B)) >= 250)
                {
                    for (int i = 0; i < 4 && !fringe; i++)
                    {
                        int nx = x + dxs[i];
                        int ny = y + dys[i];
                        if (nx < 0 || ny < 0 || nx >= w || ny >= h || bg[nx, ny]) fringe = true;
                    }
                }
                if (fringe) continue;
                bmp.SetPixel(x, y, Color.FromArgb(255, c.R, c.G, c.B));
            }
            bool[,] rim = new bool[w, h];
            for (int y = 0; y < h; y++)
            for (int x = 0; x < w; x++)
            {
                Color c = bmp.GetPixel(x, y);
                if (c.A < 16) continue;
                int min = Math.Min(c.R, Math.Min(c.G, c.B));
                int max = Math.Max(c.R, Math.Max(c.G, c.B));
                if (min < 236 || (max - min) > 16) continue;
                for (int i = 0; i < 4 && !rim[x, y]; i++)
                {
                    int nx = x + dxs[i];
                    int ny = y + dys[i];
                    if (nx < 0 || ny < 0 || nx >= w || ny >= h || bmp.GetPixel(nx, ny).A < 16) rim[x, y] = true;
                }
            }
            for (int y = 0; y < h; y++)
            for (int x = 0; x < w; x++)
                if (rim[x, y]) bmp.SetPixel(x, y, Color.Transparent);
            if (dropDisk) EraseDisk(bmp);
            return bmp;
        }
    }

    static void EraseDisk(Bitmap bmp)
    {
        int w = bmp.Width;
        int h = bmp.Height;
        int minY = h;
        int maxY = -1;
        for (int y = 0; y < h; y++)
        for (int x = 0; x < w; x++)
        {
            if (bmp.GetPixel(x, y).A < 16) continue;
            if (y < minY) minY = y;
            if (y > maxY) maxY = y;
        }
        if (maxY < 0) return;
        int limit = maxY - Math.Max(8, (maxY - minY) / 5);
        bool[,] seen = new bool[w, h];
        int[] dxs = new int[] { -1, 1, 0, 0, -1, 1, -1, 1 };
        int[] dys = new int[] { 0, 0, -1, 1, -1, -1, 1, 1 };
        for (int y = 0; y < h; y++)
        for (int x = 0; x < w; x++)
        {
            if (seen[x, y] || !Disk(bmp.GetPixel(x, y))) continue;
            var stack = new List<Point>();
            var queue = new Queue<Point>();
            queue.Enqueue(new Point(x, y));
            seen[x, y] = true;
            int bMinX = x, bMaxX = x, bMinY = y, bMaxY = y;
            while (queue.Count > 0)
            {
                Point p = queue.Dequeue();
                stack.Add(p);
                if (p.X < bMinX) bMinX = p.X;
                if (p.X > bMaxX) bMaxX = p.X;
                if (p.Y < bMinY) bMinY = p.Y;
                if (p.Y > bMaxY) bMaxY = p.Y;
                for (int i = 0; i < 8; i++)
                {
                    int nx = p.X + dxs[i];
                    int ny = p.Y + dys[i];
                    if (nx < 0 || ny < 0 || nx >= w || ny >= h || seen[nx, ny]) continue;
                    if (!Disk(bmp.GetPixel(nx, ny))) continue;
                    seen[nx, ny] = true;
                    queue.Enqueue(new Point(nx, ny));
                }
            }
            int bw = bMaxX - bMinX + 1;
            int bh = bMaxY - bMinY + 1;
            bool round = bw > 8 && bh > 8 && bw < bh * 1.8f && bh < bw * 1.8f;
            if (round && bMinY >= limit)
            {
                foreach (Point p in stack) bmp.SetPixel(p.X, p.Y, Color.Transparent);
                Console.WriteLine("DISK " + bMinX + "," + bMinY + " " + bw + "x" + bh + " n=" + stack.Count);
            }
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

    static void SavePlaced(Bitmap art, float targetH, float bottom, float centerX, string path)
    {
        int minX, minY, maxX, maxY;
        Content(art, out minX, out minY, out maxX, out maxY);
        float contentH = Math.Max(1, maxY - minY + 1);
        float contentW = Math.Max(1, maxX - minX + 1);
        float scale = targetH / contentH;
        if (contentW * scale > 210f) scale = 210f / contentW;
        Bitmap bmp = new Bitmap(512, 512, PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(bmp))
        {
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
            g.PixelOffsetMode = PixelOffsetMode.HighQuality;
            g.SmoothingMode = SmoothingMode.HighQuality;
            float dw = art.Width * scale;
            float dh = art.Height * scale;
            float dx = centerX - ((minX + maxX) * 0.5f) * scale;
            float dy = bottom - (maxY + 1) * scale;
            g.DrawImage(art, dx, dy, dw, dh);
        }
        bmp.Save(path, ImageFormat.Png);
        bmp.Dispose();
        Console.WriteLine(Path.GetFileName(path) + " scale=" + scale.ToString("0.00") + " from " + contentW.ToString("0") + "x" + contentH.ToString("0"));
    }

    static void SaveGene(Bitmap art, string path)
    {
        int minX, minY, maxX, maxY;
        Content(art, out minX, out minY, out maxX, out maxY);
        float contentW = Math.Max(1, maxX - minX + 1);
        float contentH = Math.Max(1, maxY - minY + 1);
        float scale = Math.Min(420f / contentW, 420f / contentH);
        Bitmap bmp = new Bitmap(512, 512, PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(bmp))
        {
            g.Clear(Color.FromArgb(255, 46, 42, 40));
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
            g.PixelOffsetMode = PixelOffsetMode.HighQuality;
            float dw = art.Width * scale;
            float dh = art.Height * scale;
            float dx = 256f - ((minX + maxX) * 0.5f) * scale;
            float dy = 256f - ((minY + maxY) * 0.5f) * scale;
            g.DrawImage(art, dx, dy, dw, dh);
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
                    g.DrawString("Cat " + names[i], font, brush, 24, y);
                    g.DrawString("Black-tipped " + names[i], font, brush, 560, y);
                    using (Bitmap cat = new Bitmap(Path.Combine(catDir, "CatEars_" + names[i] + ".png")))
                    using (Bitmap ears = new Bitmap(Path.Combine(outDir, "BlacktipCatEars_" + names[i] + ".png")))
                    {
                        g.DrawImage(cat, 24, y + 28, 500, 500);
                        g.DrawImage(ears, 560, y + 28, 500, 500);
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
$assets = "C:\Users\mathi\.cursor\projects\c-Users-mathi-Documents-Rimworld-new-mods\assets"
$south = Join-Path $inv "reference-blacktip-ears-south.png"
$north = Join-Path $inv "reference-blacktip-ears-north.png"
$east = Join-Path $inv "reference-blacktip-ears-east.png"
Copy-Item (Join-Path $assets "c__Users_mathi_AppData_Roaming_Cursor_User_workspaceStorage_f286a127b07b48d0b85590b38d17346c_images_Capture_d__cran_2026-10-15_111544-8db4f83d-34e1-474c-b289-d5b599b929ec.png") $south -Force
Copy-Item (Join-Path $assets "c__Users_mathi_AppData_Roaming_Cursor_User_workspaceStorage_f286a127b07b48d0b85590b38d17346c_images_Capture_d__cran_2026-10-15_111636-5e6fc8d1-2769-403c-9b6f-44d71ab5cf0b.png") $north -Force
Copy-Item (Join-Path $assets "c__Users_mathi_AppData_Roaming_Cursor_User_workspaceStorage_f286a127b07b48d0b85590b38d17346c_images_Capture_d__cran_2026-10-15_111633-71c493b1-9c97-4629-a65c-f8c0693a423b.png") $east -Force
$out = "C:\Users\mathi\Documents\Rimworld new mods\mods\RJWAnimalTextures\Textures\Things\Pawn\Humanlike\HeadAttachments\BlacktipCatEars"
$gene = "C:\Users\mathi\Documents\Rimworld new mods\mods\RJWAnimalTextures\Textures\Genes\Icons\RJWAT_blacktip_cat_ears.png"
$cat = "C:\Program Files (x86)\Steam\steamapps\common\RimWorld\Mods\sized-apparel-heads\Textures\Things\Pawn\Humanlike\HeadAttachments\CatEars"
[BlacktipCatEars]::Build($south, $north, $east, $cat, $out, $gene, (Join-Path $inv "preview-BlacktipCatEars.png"))
