# DeerPenis. Sizes 0 to 2 are written by Build-DeerVariety.ps1.
# Sizes 3 to 5 keep this art. Rest is the horse sheath, copied in place for each size.
# Aroused south and east are the supplied pictures, which already include the scrotum.
# Ball files are blank so Sized Apparel does not draw a second scrotum on top.
# North is blank, matching the horse.
# East output from this script sits 40 px behind the Sized Apparel anchor. Build-DeerEastFix.ps1
# corrected the live files on 2026-10-24. Running this again brings the offset back; rerun that fix after it.
Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = "Stop"

Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;

public static class DeerPenis
{
    public static void Build(string southPath, string sidePath, string horseDir, string outRoot, string genePath, string previewPath)
    {
        string hornyDir = Path.Combine(outRoot, "Horny");
        string ballDir = Path.Combine(outRoot, "Balls");
        Directory.CreateDirectory(outRoot);
        Directory.CreateDirectory(hornyDir);
        Directory.CreateDirectory(ballDir);
        using (Bitmap south = Largest(Load(southPath)))
        using (Bitmap side = Largest(Mirror(Load(sidePath))))
        {
            PointF southJoin = new PointF(south.Width * 0.5f, 318f);
            PointF sideBase;
            PointF sideTip;
            float sideAngle = Measure(side, out sideBase, out sideTip);
            Console.WriteLine("SIDE base " + sideBase.X.ToString("0.0") + "," + sideBase.Y.ToString("0.0")
                + " tip " + sideTip.X.ToString("0.0") + "," + sideTip.Y.ToString("0.0")
                + " angle " + sideAngle.ToString("0.0"));
            SaveGene(south, genePath);
            for (int size = 3; size <= 5; size++)
            {
                string horseSouth = Path.Combine(horseDir, "HorsePenis_" + size + "_south.png");
                string horseEast = Path.Combine(horseDir, "HorsePenis_" + size + "_east.png");
                CopyPng(horseSouth, Path.Combine(outRoot, "DeerPenis_" + size + "_south.png"));
                CopyPng(horseEast, Path.Combine(outRoot, "DeerPenis_" + size + "_east.png"));
                Save(Blank(), Path.Combine(outRoot, "DeerPenis_" + size + "_north.png"));
                PointF southAnchor = Center(horseSouth);
                PointF eastAnchor = Center(horseEast);
                float width = Span(horseSouth);
                float scale = (width / 79f) * 0.58f;
                Save(Draw(south, scale, southJoin.X, southJoin.Y, southAnchor.X, southAnchor.Y, 0f), Path.Combine(hornyDir, "DeerPenis_" + size + "_south.png"));
                Save(Draw(side, scale, sideBase.X, sideBase.Y, eastAnchor.X, eastAnchor.Y, 0f), Path.Combine(hornyDir, "DeerPenis_" + size + "_east.png"));
                Save(Blank(), Path.Combine(hornyDir, "DeerPenis_" + size + "_north.png"));
                Save(Blank(), Path.Combine(ballDir, "DeerPenis_" + size + "_south.png"));
                Save(Blank(), Path.Combine(ballDir, "DeerPenis_" + size + "_east.png"));
                Save(Blank(), Path.Combine(ballDir, "DeerPenis_" + size + "_north.png"));
            }
            BuildPreview(outRoot, previewPath);
        }
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
        double bx = 0, by = 0, bn = 0, tx = 0, ty = 0, tn = 0;
        int maxX = 0;
        for (int y = 0; y < side.Height; y++)
        for (int x = 0; x < side.Width; x++)
        {
            Color c = side.GetPixel(x, y);
            if (c.A < 16) continue;
            bool pink = c.R > 160 && (c.R - c.G) > 25;
            if (!pink) continue;
            if (x > maxX) maxX = x;
            bool nearTan = false;
            for (int oy = -6; oy <= 6 && !nearTan; oy++)
            for (int ox = -6; ox <= 6; ox++)
            {
                int nx = x + ox;
                int ny = y + oy;
                if (nx < 0 || ny < 0 || nx >= side.Width || ny >= side.Height) continue;
                Color n = side.GetPixel(nx, ny);
                if (n.A < 16) continue;
                if (!(n.R > 160 && (n.R - n.G) > 25)) nearTan = true;
            }
            if (nearTan) { bx += x; by += y; bn++; }
        }
        for (int y = 0; y < side.Height; y++)
        for (int x = 0; x < side.Width; x++)
        {
            Color c = side.GetPixel(x, y);
            if (c.A < 16) continue;
            if (!(c.R > 160 && (c.R - c.G) > 25)) continue;
            if (x > maxX - 30) { tx += x; ty += y; tn++; }
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

    static PointF Center(string path)
    {
        using (Bitmap bmp = new Bitmap(path))
        {
            int minX = bmp.Width, minY = bmp.Height, maxX = -1, maxY = -1;
            for (int y = 0; y < bmp.Height; y++)
            for (int x = 0; x < bmp.Width; x++)
            {
                if (bmp.GetPixel(x, y).A < 16) continue;
                if (x < minX) minX = x;
                if (y < minY) minY = y;
                if (x > maxX) maxX = x;
                if (y > maxY) maxY = y;
            }
            return new PointF((minX + maxX) * 0.5f, (minY + maxY) * 0.5f);
        }
    }

    static float Span(string path)
    {
        using (Bitmap bmp = new Bitmap(path))
        {
            int minX = bmp.Width, maxX = -1;
            for (int y = 0; y < bmp.Height; y++)
            for (int x = 0; x < bmp.Width; x++)
            {
                if (bmp.GetPixel(x, y).A < 16) continue;
                if (x < minX) minX = x;
                if (x > maxX) maxX = x;
            }
            return Math.Max(8, maxX - minX);
        }
    }

    static Graphics Open(Bitmap bmp)
    {
        Graphics g = Graphics.FromImage(bmp);
        g.SmoothingMode = SmoothingMode.HighQuality;
        g.InterpolationMode = InterpolationMode.HighQualityBicubic;
        g.PixelOffsetMode = PixelOffsetMode.HighQuality;
        return g;
    }

    static Bitmap Draw(Bitmap art, float scale, float ox, float oy, float dx, float dy, float rot)
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

    static void CopyPng(string source, string dest)
    {
        using (Bitmap bmp = new Bitmap(source))
        {
            using (Bitmap copy = new Bitmap(bmp.Width, bmp.Height, PixelFormat.Format32bppArgb))
            {
                using (Graphics g = Graphics.FromImage(copy))
                {
                    g.DrawImage(bmp, 0, 0, bmp.Width, bmp.Height);
                }
                copy.Save(dest, ImageFormat.Png);
            }
        }
    }

    static void SaveGene(Bitmap south, string path)
    {
        Bitmap bmp = new Bitmap(512, 512, PixelFormat.Format32bppArgb);
        using (Graphics g = Open(bmp))
        {
            float scale = 460f / south.Height;
            float dw = south.Width * scale;
            float dh = south.Height * scale;
            g.DrawImage(south, (512f - dw) * 0.5f, (512f - dh) * 0.5f, dw, dh);
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
            using (Bitmap a = new Bitmap(Path.Combine(outRoot, "DeerPenis_5_south.png")))
            using (Bitmap b = new Bitmap(Path.Combine(outRoot, "Horny", "DeerPenis_5_south.png")))
            using (Bitmap c = new Bitmap(Path.Combine(outRoot, "DeerPenis_5_east.png")))
            using (Bitmap d = new Bitmap(Path.Combine(outRoot, "Horny", "DeerPenis_5_east.png")))
            {
                g.DrawImage(a, 16, 16, 460, 460);
                g.DrawImage(b, 500, 16, 460, 460);
                g.DrawImage(c, 16, 500, 460, 460);
                g.DrawImage(d, 500, 500, 460, 460);
            }
        }
        sheet.Save(previewPath, ImageFormat.Png);
        sheet.Dispose();
        Console.WriteLine("PREVIEW " + previewPath);
    }
}
'@

$inv = "C:\Users\mathi\Documents\Rimworld new mods\mods\RJWAnimalTextures\ArtInventory\TextureV2"
$live = "C:\Users\mathi\Documents\Rimworld new mods\mods\RJWAnimalTextures\Textures\SizedApparel\BodyParts\Human\Penis"
$horse = "C:\Program Files (x86)\Steam\steamapps\common\RimWorld\Mods\sized-apparel-zero\Textures\SizedApparel\BodyParts\Human\Penis"
$gene = "C:\Users\mathi\Documents\Rimworld new mods\mods\RJWAnimalTextures\Textures\Genes\Icons\RJWAT_deer.png"
Copy-Item "C:\Users\mathi\.cursor\projects\c-Users-mathi-Documents-Rimworld-new-mods\assets\c__Users_mathi_AppData_Roaming_Cursor_User_workspaceStorage_f286a127b07b48d0b85590b38d17346c_images_image-1f7f86c3-7d13-4447-b256-6d82d51961c9.png" (Join-Path $inv "reference-deer-south.png") -Force
Copy-Item "C:\Users\mathi\.cursor\projects\c-Users-mathi-Documents-Rimworld-new-mods\assets\c__Users_mathi_AppData_Roaming_Cursor_User_workspaceStorage_f286a127b07b48d0b85590b38d17346c_images_image-a8fa4656-d5b8-4207-be7d-855a38094154.png" (Join-Path $inv "reference-deer-side.png") -Force
[DeerPenis]::Build(
    (Join-Path $inv "reference-deer-south.png"),
    (Join-Path $inv "reference-deer-side.png"),
    $horse,
    $live,
    $gene,
    (Join-Path $inv "preview-DeerPenis.png"))
