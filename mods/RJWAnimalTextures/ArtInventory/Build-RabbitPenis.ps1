# Builds RabbitPenis rest, erect, blank balls, and the gene icon.
# -RestOnly rebuilds the resting south, east, and north sprites.
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = "Stop"
$restOnly = $args -contains "-RestOnly"

Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;

public static class RabbitPenisBuild
{
    public static void Sprite(string source, string dest, string mode, int targetH, int baseY)
    {
        Bitmap art = Largest(Knockout(source));
        if (mode == "east" || mode == "rest-east")
        {
            if (PinkIsLeft(art)) art = Mirror(art);
        }
        float rot = 0f;
        if (mode == "south" || mode == "east")
        {
            float angle = ShaftAngle(art);
            float target = mode == "south" ? -90f : -45f;
            rot = target - angle;
            if (mode == "south" && Math.Abs(angle + 90f) < 12f) rot = 0f;
            Console.WriteLine(Path.GetFileName(dest) + " angle " + angle.ToString("0.0") + " rot " + rot.ToString("0.0"));
        }
        Bitmap turned = Rotate(art, rot);
        art.Dispose();
        Bitmap placed = Fit(turned, targetH, baseY, mode == "east" || mode == "rest-east");
        turned.Dispose();
        GrayFur(placed);
        int minX, minY, maxX, maxY;
        Bounds(placed, out minX, out minY, out maxX, out maxY);
        Directory.CreateDirectory(Path.GetDirectoryName(dest));
        placed.Save(dest, ImageFormat.Png);
        placed.Dispose();
        Console.WriteLine("  h " + (maxY - minY + 1) + " base " + maxY + " x " + minX + "-" + maxX + " cx " + ((minX + maxX) * 0.5).ToString("0.0"));
    }

    public static void Blank(string dest)
    {
        Directory.CreateDirectory(Path.GetDirectoryName(dest));
        using (Bitmap bmp = new Bitmap(4, 4, PixelFormat.Format32bppArgb))
        {
            bmp.Save(dest, ImageFormat.Png);
        }
    }

    public static void Icon(string source, string dest)
    {
        Bitmap art = Largest(Knockout(source));
        GrayFur(art);
        int minX, minY, maxX, maxY;
        Bounds(art, out minX, out minY, out maxX, out maxY);
        Bitmap icon = new Bitmap(512, 512, PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(icon))
        {
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
            g.PixelOffsetMode = PixelOffsetMode.HighQuality;
            g.SmoothingMode = SmoothingMode.HighQuality;
            int cw = maxX - minX + 1;
            int ch = maxY - minY + 1;
            float scale = 460f / ch;
            float dw = cw * scale;
            float dh = ch * scale;
            float dx = (512f - dw) * 0.5f;
            float dy = 500f - dh;
            g.DrawImage(art, new RectangleF(dx, dy, dw, dh), new RectangleF(minX, minY, cw, ch), GraphicsUnit.Pixel);
        }
        art.Dispose();
        Directory.CreateDirectory(Path.GetDirectoryName(dest));
        icon.Save(dest, ImageFormat.Png);
        icon.Dispose();
        Console.WriteLine("ICON " + dest);
    }

    static bool Background(Color c)
    {
        if (c.A < 16) return true;
        int min = Math.Min((int)c.R, Math.Min((int)c.G, (int)c.B));
        int max = Math.Max((int)c.R, Math.Max((int)c.G, (int)c.B));
        return min >= 236 && (max - min) < 24;
    }

    static bool Pink(Color c)
    {
        if (c.A < 16 || c.R < 150) return false;
        float redness = (c.R - Math.Max((int)c.G, (int)c.B)) / (float)c.R;
        return redness >= 0.16f;
    }

    static Bitmap Knockout(string path)
    {
        using (Bitmap source = new Bitmap(path))
        {
            int w = source.Width;
            int h = source.Height;
            bool[] bg = new bool[w * h];
            int[] qx = new int[w * h];
            int[] qy = new int[w * h];
            int tail = 0;
            for (int x = 0; x < w; x++)
            {
                Seed(source, bg, qx, qy, ref tail, x, 0);
                Seed(source, bg, qx, qy, ref tail, x, h - 1);
            }
            for (int y = 0; y < h; y++)
            {
                Seed(source, bg, qx, qy, ref tail, 0, y);
                Seed(source, bg, qx, qy, ref tail, w - 1, y);
            }
            int head = 0;
            while (head < tail)
            {
                int x = qx[head];
                int y = qy[head];
                head++;
                if (x > 0) Seed(source, bg, qx, qy, ref tail, x - 1, y);
                if (x + 1 < w) Seed(source, bg, qx, qy, ref tail, x + 1, y);
                if (y > 0) Seed(source, bg, qx, qy, ref tail, x, y - 1);
                if (y + 1 < h) Seed(source, bg, qx, qy, ref tail, x, y + 1);
            }
            Bitmap bmp = new Bitmap(w, h, PixelFormat.Format32bppArgb);
            for (int y = 0; y < h; y++)
            for (int x = 0; x < w; x++)
            {
                if (bg[y * w + x]) continue;
                Color c = source.GetPixel(x, y);
                if (Background(c)) continue;
                bmp.SetPixel(x, y, Color.FromArgb(255, c.R, c.G, c.B));
            }
            return bmp;
        }
    }

    static void Seed(Bitmap src, bool[] bg, int[] qx, int[] qy, ref int tail, int x, int y)
    {
        int i = y * src.Width + x;
        if (bg[i]) return;
        if (!Background(src.GetPixel(x, y))) return;
        bg[i] = true;
        qx[tail] = x;
        qy[tail] = y;
        tail++;
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
                for (int dy = -1; dy <= 1; dy++)
                for (int dx = -1; dx <= 1; dx++)
                {
                    int nx = cx + dx;
                    int ny = cy + dy;
                    if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue;
                    int ni = ny * w + nx;
                    if (id[ni] != 0) continue;
                    if (src.GetPixel(nx, ny).A < 16) continue;
                    id[ni] = next;
                    qx[tail] = nx;
                    qy[tail] = ny;
                    tail++;
                }
            }
            if (count > bestN)
            {
                bestN = count;
                best = next;
            }
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

    static bool PinkIsLeft(Bitmap src)
    {
        double px = 0, pn = 0, cx = 0, cn = 0;
        for (int y = 0; y < src.Height; y++)
        for (int x = 0; x < src.Width; x++)
        {
            Color c = src.GetPixel(x, y);
            if (c.A < 16) continue;
            cx += x;
            cn++;
            if (!Pink(c)) continue;
            px += x;
            pn++;
        }
        if (pn < 8 || cn < 8) return false;
        return (px / pn) < (cx / cn) - 4.0;
    }

    static float ShaftAngle(Bitmap src)
    {
        double rx = 0, ry = 0, rn = 0;
        for (int y = 0; y < src.Height; y++)
        for (int x = 0; x < src.Width; x++)
        {
            Color c = src.GetPixel(x, y);
            if (c.A < 16 || Pink(c)) continue;
            rx += x;
            ry += y;
            rn++;
        }
        if (rn < 8)
        {
            rx = src.Width * 0.5;
            ry = src.Height * 0.75;
        }
        else
        {
            rx /= rn;
            ry /= rn;
        }
        double best = 1;
        for (int y = 0; y < src.Height; y++)
        for (int x = 0; x < src.Width; x++)
        {
            if (!Pink(src.GetPixel(x, y))) continue;
            double d = (x - rx) * (x - rx) + (y - ry) * (y - ry);
            if (d > best) best = d;
        }
        double tx = 0, ty = 0, tn = 0;
        double keep = best * 0.72;
        for (int y = 0; y < src.Height; y++)
        for (int x = 0; x < src.Width; x++)
        {
            if (!Pink(src.GetPixel(x, y))) continue;
            double d = (x - rx) * (x - rx) + (y - ry) * (y - ry);
            if (d < keep) continue;
            tx += x;
            ty += y;
            tn++;
        }
        if (tn < 1) return -90f;
        return (float)(Math.Atan2((ty / tn) - ry, (tx / tn) - rx) * 180.0 / Math.PI);
    }

    static Bitmap Rotate(Bitmap src, float rot)
    {
        if (Math.Abs(rot) < 0.5f)
        {
            Bitmap copy = new Bitmap(src.Width, src.Height, PixelFormat.Format32bppArgb);
            using (Graphics g = Graphics.FromImage(copy))
            {
                g.DrawImage(src, 0, 0, src.Width, src.Height);
            }
            return copy;
        }
        int side = Math.Max(src.Width, src.Height) * 3;
        Bitmap bmp = new Bitmap(side, side, PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(bmp))
        {
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
            g.PixelOffsetMode = PixelOffsetMode.HighQuality;
            g.SmoothingMode = SmoothingMode.HighQuality;
            g.TranslateTransform(side * 0.5f, side * 0.5f);
            g.RotateTransform(rot);
            g.TranslateTransform(-src.Width * 0.5f, -src.Height * 0.5f);
            g.DrawImage(src, 0, 0, src.Width, src.Height);
        }
        src.Dispose();
        return bmp;
    }

    static void Bounds(Bitmap src, out int minX, out int minY, out int maxX, out int maxY)
    {
        minX = src.Width;
        minY = src.Height;
        maxX = -1;
        maxY = -1;
        for (int y = 0; y < src.Height; y++)
        for (int x = 0; x < src.Width; x++)
        {
            if (src.GetPixel(x, y).A < 16) continue;
            if (x < minX) minX = x;
            if (y < minY) minY = y;
            if (x > maxX) maxX = x;
            if (y > maxY) maxY = y;
        }
        if (maxX < 0)
        {
            minX = 0;
            minY = 0;
            maxX = 1;
            maxY = 1;
        }
    }

    static Bitmap Fit(Bitmap src, int targetH, int baseY, bool east)
    {
        int minX, minY, maxX, maxY;
        Bounds(src, out minX, out minY, out maxX, out maxY);
        int cw = maxX - minX + 1;
        int ch = maxY - minY + 1;
        float scale = targetH / (float)ch;
        float dw = cw * scale;
        float dh = ch * scale;
        float dx = east ? 221f : 256f - dw * 0.5f;
        float dy = baseY - dh;
        Bitmap bmp = new Bitmap(512, 512, PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(bmp))
        {
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
            g.PixelOffsetMode = PixelOffsetMode.HighQuality;
            g.SmoothingMode = SmoothingMode.HighQuality;
            g.DrawImage(src, new RectangleF(dx, dy, dw, dh), new RectangleF(minX, minY, cw, ch), GraphicsUnit.Pixel);
        }
        return bmp;
    }

    static void GrayFur(Bitmap bmp)
    {
        for (int y = 0; y < bmp.Height; y++)
        for (int x = 0; x < bmp.Width; x++)
        {
            Color c = bmp.GetPixel(x, y);
            if (c.A < 16) continue;
            int r = c.R;
            int g = c.G;
            int b = c.B;
            if (r < 1) continue;
            float redness = (r - Math.Max(g, b)) / (float)r;
            int luma = (r * 299 + g * 587 + b * 114) / 1000;
            if (redness > 0.15f) continue;
            if (luma > 225) continue;
            bmp.SetPixel(x, y, Color.FromArgb(c.A, luma, luma, luma));
        }
    }
}
'@

$root = "C:\Users\mathi\.cursor\projects\c-Users-mathi-Documents-Rimworld-new-mods\assets"
$p = "c__Users_mathi_AppData_Roaming_Cursor_User_workspaceStorage_f286a127b07b48d0b85590b38d17346c_images_"
function Ref([string]$name) { return (Join-Path $root ($p + $name)) }

$southErect = @(
    (Ref "mvc11nc5b31be5-b6bfc146-99af-4683-81e6-ca628ac68b1f.jpg"),
    (Ref "Sans_titre8-bec87e62-ab06-4988-ae56-e259e251396d.png"),
    (Ref "mvc0qzbd9nx06u-4dd2b930-31f3-466d-ad0c-83bc00352631.jpg"),
    (Ref "mvc114q3so44qr-01bd46f1-ef40-4edc-a29a-5ddbd07d94b7.jpg"),
    (Ref "mvc11z3litnrn2-0a839628-616d-4314-9c9b-c726e83bb247.jpg"),
    (Ref "Sans_titre-d8008f3c-7fcd-4781-8833-a14b091f950c.png")
)
$eastErect = @(
    (Ref "Capture_d__cran_2026-10-17_091457-4b9ba39a-7d2d-4e73-8209-c9e3de99a9b7.png"),
    (Ref "mvc0z8setxri6k-007a14cf-ee1a-4b9d-8899-627cadf617f8.jpg"),
    (Ref "mvc10eza3whkyw-4233f041-222d-4bca-acc2-2bba4683c088.jpg"),
    (Ref "mvc10lvajygh7l-33a6ff4b-fd4b-49aa-aef7-240d48bb9597.jpg"),
    (Ref "mvc11ez1r6fbdd-fc1c9bdb-bc77-4d81-92ae-c06d95d8cf04.jpg"),
    (Ref "mvc11ez1r6fbdd-fc1c9bdb-bc77-4d81-92ae-c06d95d8cf04.jpg")
)
$southRest = @(
    (Ref "mvc14lmxc1wywz-c9971b9c-23af-41f4-aacc-75d7c3548580.jpg"),
    (Ref "Capture_d__cran_2026-10-17_091700-d4063004-98ef-4771-a876-1bbb869a20ac.png"),
    (Ref "mvc14c7h6vna76-727e3667-2472-4e7b-a8bb-351e89e20213.jpg"),
    (Ref "Capture_d__cran_2026-10-17_091946-8f8d2e4d-3327-423b-bdab-124315aeb9a6.png"),
    (Ref "Capture_d__cran_2026-10-17_091706-6647522c-06f7-4fdf-abf2-b8c97c7d5fcf.png"),
    (Ref "mvc14p5ed2gyp5-62936a9f-f262-44de-b186-e950dd4ac0fb.jpg")
)
$eastClosed = (Ref "Capture_d__cran_2026-10-17_091328-281de8a1-7d0c-49e9-bb4f-40a01e8cfb55.png")
$eastTip = (Ref "Capture_d__cran_2026-10-17_091710-771508cb-e951-4f3c-bd94-10cbf4b1cca0.png")
$eastRest = @($eastClosed, $eastClosed, $eastTip, $eastTip, $eastTip, $eastTip)
$northRest = (Ref "Capture_d__cran_2026-10-17_091951-2eb1809d-0e5f-4db2-97e5-1df6fed8cc29.png")

$live = "C:\Users\mathi\Documents\Rimworld new mods\mods\RJWAnimalTextures\Textures\SizedApparel\BodyParts\Human\Penis"
$horny = Join-Path $live "Horny"
$balls = Join-Path $live "Balls"
$southH = @(40, 46, 64, 79, 92, 120)
$restH = @(27, 37, 59, 61, 67, 81)
$southBase = @(268, 268, 268, 268, 268, 282)
$eastBase = @(282, 282, 286, 286, 286, 300)

for ($i = 0; $i -le 5; $i++) {
    if (-not $restOnly) {
        $name = "RabbitPenis_{0}_{1}.png" -f $i, "south"
        [RabbitPenisBuild]::Sprite($southErect[$i], (Join-Path $horny $name), "south", $southH[$i], $southBase[$i])
        $name = "RabbitPenis_{0}_{1}.png" -f $i, "east"
        [RabbitPenisBuild]::Sprite($eastErect[$i], (Join-Path $horny $name), "east", $southH[$i], $eastBase[$i])
    }
    $name = "RabbitPenis_{0}_{1}.png" -f $i, "south"
    [RabbitPenisBuild]::Sprite($southRest[$i], (Join-Path $live $name), "rest-south", $restH[$i], $southBase[$i])
    $name = "RabbitPenis_{0}_{1}.png" -f $i, "east"
    [RabbitPenisBuild]::Sprite($eastRest[$i], (Join-Path $live $name), "rest-east", $restH[$i], $eastBase[$i])
    [RabbitPenisBuild]::Sprite($northRest, (Join-Path $live ("RabbitPenis_{0}_north.png" -f $i)), "rest-south", $restH[$i], $southBase[$i])
    if (-not $restOnly) {
        foreach ($dir in @("south", "east", "north")) {
            $blank = "RabbitPenis_{0}_{1}.png" -f $i, $dir
            [RabbitPenisBuild]::Blank((Join-Path $horny $blank.Replace("_south", "_north").Replace("_east", "_north")))
            [RabbitPenisBuild]::Blank((Join-Path $balls $blank))
        }
    }
}

if (-not $restOnly) {
    [RabbitPenisBuild]::Icon($southErect[5], "C:\Users\mathi\Documents\Rimworld new mods\mods\RJWAnimalTextures\Textures\Genes\Icons\RJWAT_rabbit.png")
}
