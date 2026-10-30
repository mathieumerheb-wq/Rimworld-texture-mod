# Lynx rests are the feline sheath pictures, so the lynx is not the fox scrotum.
# Erect sizes 3-5 are whole pictures that already include the scrotum.
# Sizes 0-2 erect are left as they are. Balls and north stay blank.
Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = "Stop"

Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;

public static class LynxVariety
{
    public static void Build(string inv, string outRoot, string previewPath)
    {
        string horny = Path.Combine(outRoot, "Horny");
        Directory.CreateDirectory(outRoot);
        Directory.CreateDirectory(horny);
        string restFrontA = Path.Combine(inv, "ref-lynx-rest-front-closed.png");
        string restFrontB = Path.Combine(inv, "ref-lynx-rest-front-hole.png");
        string restFrontC = Path.Combine(inv, "ref-lynx-rest-front-open.png");
        string restSideA = Path.Combine(inv, "ref-lynx-rest-side-smooth.png");
        string restSideB = Path.Combine(inv, "ref-lynx-rest-side-sheath.png");
        float[] restH = new float[] { 72f, 88f, 104f, 122f, 142f, 164f };
        for (int size = 0; size <= 5; size++)
        {
            string front = size < 2 ? restFrontA : (size == 2 ? restFrontB : restFrontC);
            string side = size < 3 ? restSideA : restSideB;
            Save(PlaceRest(Load(front), restH[size], false, 256f, 268f), Path.Combine(outRoot, "LynxPenis_" + size + "_south.png"));
            Save(PlaceRest(Load(side), restH[size], true, 230f, 276f), Path.Combine(outRoot, "LynxPenis_" + size + "_east.png"));
        }
        EmitErect(Path.Combine(inv, "ref-lynx-erect-front-mid.png"), Path.Combine(horny, "LynxPenis_3_south.png"), 230f, true, 256f, 430f);
        EmitErect(Path.Combine(inv, "ref-lynx-erect-front-tall.png"), Path.Combine(horny, "LynxPenis_4_south.png"), 300f, true, 256f, 430f);
        EmitErect(Path.Combine(inv, "ref-lynx-erect-front-barbed.png"), Path.Combine(horny, "LynxPenis_5_south.png"), 370f, true, 256f, 430f);
        EmitErect(Path.Combine(inv, "ref-lynx-erect-side-clean.png"), Path.Combine(horny, "LynxPenis_3_east.png"), 230f, false, 214f, 420f);
        EmitErect(Path.Combine(inv, "ref-lynx-erect-side-long.png"), Path.Combine(horny, "LynxPenis_4_east.png"), 255f, false, 190f, 415f);
        EmitErect(Path.Combine(inv, "ref-lynx-erect-side-thick.png"), Path.Combine(horny, "LynxPenis_5_east.png"), 340f, false, 200f, 425f);
        BuildPreview(outRoot, previewPath);
    }

    static void FitSouth(string path, float targetH)
    {
        Bitmap src = new Bitmap(path);
        int minX, minY, maxX, maxY;
        Box(src, out minX, out minY, out maxX, out maxY);
        float contentH = Math.Max(1, maxY - minY + 1);
        float scale = targetH / contentH;
        float rootX = (minX + maxX) * 0.5f;
        float rootY = maxY;
        Bitmap bmp = new Bitmap(512, 512, PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(bmp))
        {
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
            g.PixelOffsetMode = PixelOffsetMode.HighQuality;
            g.TranslateTransform(rootX, rootY);
            g.ScaleTransform(scale, scale);
            g.TranslateTransform(-rootX, -rootY);
            g.DrawImage(src, 0, 0, src.Width, src.Height);
        }
        src.Dispose();
        bmp.Save(path, ImageFormat.Png);
        bmp.Dispose();
        Console.WriteLine(Path.GetFileName(path) + " fit " + contentH.ToString("0") + " -> " + targetH.ToString("0"));
    }

    static void EmitErect(string src, string dest, float targetH, bool south, float dx, float dy)
    {
        Bitmap loaded = Load(src);
        PointF pivot;
        float angle = Measure(loaded, out pivot);
        if (!south && Math.Abs(angle) > 90f)
        {
            float rad = angle * (float)Math.PI / 180f;
            angle = (float)(Math.Atan2(Math.Sin(rad), -Math.Cos(rad)) * 180.0 / Math.PI);
            pivot = new PointF(loaded.Width - 1f - pivot.X, pivot.Y);
            Bitmap flipped = Mirror(loaded);
            loaded = flipped;
        }
        using (Bitmap art = loaded)
        {
            float target = south ? -90f : -45f;
            float rot = target - angle;
            if (south && Math.Abs(angle + 90f) < 12f) rot = 0f;
            Console.WriteLine(Path.GetFileName(dest) + " angle " + angle.ToString("0.0") + " rot " + rot.ToString("0.0"));
            Save(PlaceErect(art, targetH, rot, pivot, dx, dy), dest);
        }
    }

    static bool Page(Color c)
    {
        int min = Math.Min(c.R, Math.Min(c.G, c.B));
        int max = Math.Max(c.R, Math.Max(c.G, c.B));
        return c.A < 16 || (min >= 246 && (max - min) < 16);
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
            return Largest(bmp);
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
                for (int dy = -1; dy <= 1; dy++)
                for (int dx = -1; dx <= 1; dx++)
                {
                    int nx = cx + dx;
                    int ny = cy + dy;
                    if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue;
                    if (src.GetPixel(nx, ny).A < 16 || id[ny * w + nx] != 0) continue;
                    id[ny * w + nx] = next;
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

    static void Box(Bitmap src, out int minX, out int minY, out int maxX, out int maxY)
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
    }

    static bool FaceRight(Bitmap src)
    {
        int minX, minY, maxX, maxY;
        Box(src, out minX, out minY, out maxX, out maxY);
        int cut = minY + Math.Max(1, (maxY - minY) / 4);
        double sx = 0;
        int n = 0;
        for (int y = minY; y <= cut; y++)
        for (int x = minX; x <= maxX; x++)
        {
            if (src.GetPixel(x, y).A < 16) continue;
            sx += x;
            n++;
        }
        float topX = n > 0 ? (float)(sx / n) : (minX + maxX) * 0.5f;
        return topX >= (minX + maxX) * 0.5f;
    }

    static Bitmap PlaceRest(Bitmap art, float targetH, bool east, float destX, float destY)
    {
        if (east && !FaceRight(art)) art = Mirror(art);
        int minX, minY, maxX, maxY;
        Box(art, out minX, out minY, out maxX, out maxY);
        float contentH = Math.Max(1, maxY - minY + 1);
        float scale = targetH / contentH;
        Bitmap bmp = new Bitmap(512, 512, PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(bmp))
        {
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
            g.PixelOffsetMode = PixelOffsetMode.HighQuality;
            float dw = art.Width * scale;
            float dh = art.Height * scale;
            float dx = destX - ((minX + maxX) * 0.5f) * scale;
            float dy = destY - minY * scale;
            g.DrawImage(art, dx, dy, dw, dh);
        }
        art.Dispose();
        return bmp;
    }

    static int Mass(Bitmap src, int x, int y, int radius)
    {
        int n = 0;
        for (int dy = -radius; dy <= radius; dy++)
        for (int dx = -radius; dx <= radius; dx++)
        {
            int nx = x + dx;
            int ny = y + dy;
            if (nx < 0 || ny < 0 || nx >= src.Width || ny >= src.Height) continue;
            if (src.GetPixel(nx, ny).A < 16) continue;
            n++;
        }
        return n;
    }

    static float Measure(Bitmap src, out PointF pivot)
    {
        double cx = 0, cy = 0, n = 0;
        for (int y = 0; y < src.Height; y++)
        for (int x = 0; x < src.Width; x++)
        {
            if (src.GetPixel(x, y).A < 16) continue;
            cx += x;
            cy += y;
            n++;
        }
        if (n < 1)
        {
            pivot = new PointF(0, 0);
            return -90f;
        }
        cx /= n;
        cy /= n;
        int ax = 0, ay = 0;
        double far = -1;
        for (int y = 0; y < src.Height; y++)
        for (int x = 0; x < src.Width; x++)
        {
            if (src.GetPixel(x, y).A < 16) continue;
            double d = (x - cx) * (x - cx) + (y - cy) * (y - cy);
            if (d > far) { far = d; ax = x; ay = y; }
        }
        int bx = ax, by = ay;
        far = -1;
        for (int y = 0; y < src.Height; y++)
        for (int x = 0; x < src.Width; x++)
        {
            if (src.GetPixel(x, y).A < 16) continue;
            double d = (x - ax) * (x - ax) + (y - ay) * (y - ay);
            if (d > far) { far = d; bx = x; by = y; }
        }
        int tipX = ax, tipY = ay, baseX = bx, baseY = by;
        if (Mass(src, ax, ay, 18) > Mass(src, bx, by, 18))
        {
            tipX = bx;
            tipY = by;
            baseX = ax;
            baseY = ay;
        }
        pivot = new PointF(baseX, baseY);
        return (float)(Math.Atan2(tipY - baseY, tipX - baseX) * 180.0 / Math.PI);
    }

    static Bitmap PlaceErect(Bitmap art, float targetH, float rot, PointF pivot, float destX, float destY)
    {
        int minX, minY, maxX, maxY;
        Box(art, out minX, out minY, out maxX, out maxY);
        float len = Math.Max(maxX - minX + 1, maxY - minY + 1);
        float scale = targetH / Math.Max(8f, len);
        Bitmap bmp = new Bitmap(512, 512, PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(bmp))
        {
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
            g.PixelOffsetMode = PixelOffsetMode.HighQuality;
            g.TranslateTransform(destX, destY);
            g.RotateTransform(rot);
            g.ScaleTransform(scale, scale);
            g.TranslateTransform(-pivot.X, -pivot.Y);
            g.DrawImage(art, 0, 0, art.Width, art.Height);
        }
        return bmp;
    }

    static void Save(Bitmap bmp, string path)
    {
        bmp.Save(path, ImageFormat.Png);
        bmp.Dispose();
    }

    static void BuildPreview(string outRoot, string previewPath)
    {
        Bitmap sheet = new Bitmap(980, 640, PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(sheet))
        {
            g.Clear(Color.FromArgb(255, 22, 22, 26));
            g.InterpolationMode = InterpolationMode.NearestNeighbor;
            using (Font font = new Font("Segoe UI", 12f))
            using (Brush brush = new SolidBrush(Color.White))
            {
                string[] rows = new string[] { "rest south", "rest east", "erect south", "erect east" };
                for (int size = 0; size <= 5; size++)
                {
                    g.DrawString(size.ToString(), font, brush, 8, 70 + size * 0);
                }
                for (int r = 0; r < 2; r++)
                for (int size = 0; size <= 5; size++)
                {
                    string name = r == 0 ? "LynxPenis_" + size + "_south.png" : "LynxPenis_" + size + "_east.png";
                    using (Bitmap b = new Bitmap(Path.Combine(outRoot, name)))
                        g.DrawImage(b, 40 + size * 150, 30 + r * 150, 140, 140);
                }
                for (int r = 0; r < 2; r++)
                for (int size = 3; size <= 5; size++)
                {
                    string name = r == 0 ? "LynxPenis_" + size + "_south.png" : "LynxPenis_" + size + "_east.png";
                    using (Bitmap b = new Bitmap(Path.Combine(outRoot, "Horny", name)))
                        g.DrawImage(b, 40 + (size - 3) * 150, 340 + r * 150, 140, 140);
                }
                g.DrawString("rest south / rest east, then erect 3-5 south / east", font, brush, 16, 8);
            }
        }
        sheet.Save(previewPath, ImageFormat.Png);
        sheet.Dispose();
        Console.WriteLine("PREVIEW " + previewPath);
    }
}
'@

$assets = "C:\Users\mathi\.cursor\projects\c-Users-mathi-Documents-Rimworld-new-mods\assets"
$inv = "C:\Users\mathi\Documents\Rimworld new mods\mods\RJWAnimalTextures\ArtInventory\TextureV2"
function Copy-Ref($name, $file) {
    Copy-Item (Join-Path $assets $file) (Join-Path $inv $name) -Force
}
Copy-Ref "ref-lynx-rest-front-closed.png" "c__Users_mathi_AppData_Roaming_Cursor_User_workspaceStorage_f286a127b07b48d0b85590b38d17346c_images_Capture_d__cran_2026-10-15_133136-38352cb9-08ef-466f-a2ec-82063fabef9d.png"
Copy-Ref "ref-lynx-rest-front-hole.png" "c__Users_mathi_AppData_Roaming_Cursor_User_workspaceStorage_f286a127b07b48d0b85590b38d17346c_images_Capture_d__cran_2026-10-15_132806-92cf4346-ea6a-494c-8462-e5953b237cbe.png"
Copy-Ref "ref-lynx-rest-front-open.png" "c__Users_mathi_AppData_Roaming_Cursor_User_workspaceStorage_f286a127b07b48d0b85590b38d17346c_images_Capture_d__cran_2026-10-15_133029-e74d0f6b-fb56-4a23-a5b1-50ab5d4a580b.png"
Copy-Ref "ref-lynx-rest-side-smooth.png" "c__Users_mathi_AppData_Roaming_Cursor_User_workspaceStorage_f286a127b07b48d0b85590b38d17346c_images_Capture_d__cran_2026-10-15_132508-a72a25dc-27dc-484e-a6b0-da578e119614.png"
Copy-Ref "ref-lynx-rest-side-sheath.png" "c__Users_mathi_AppData_Roaming_Cursor_User_workspaceStorage_f286a127b07b48d0b85590b38d17346c_images_Capture_d__cran_2026-10-15_133132-9cb27dfe-4a5e-4676-9c25-18b1342d9c32.png"
Copy-Ref "ref-lynx-erect-front-mid.png" "c__Users_mathi_AppData_Roaming_Cursor_User_workspaceStorage_f286a127b07b48d0b85590b38d17346c_images_Capture_d__cran_2026-10-15_132415-82e537b1-034d-486d-8bb9-28020e38edbd.png"
Copy-Ref "ref-lynx-erect-threequarter.png" "c__Users_mathi_AppData_Roaming_Cursor_User_workspaceStorage_f286a127b07b48d0b85590b38d17346c_images_Capture_d__cran_2026-10-15_133126-c8d81ab3-7ce9-46a5-9363-f11285ef38ed.png"
Copy-Ref "ref-lynx-erect-front-barbed.png" "c__Users_mathi_AppData_Roaming_Cursor_User_workspaceStorage_f286a127b07b48d0b85590b38d17346c_images_Capture_d__cran_2026-10-15_132519-9cc36901-d36e-4a39-bb82-b69064fbd6db.png"
Copy-Ref "ref-lynx-erect-front-tall.png" "c__Users_mathi_AppData_Roaming_Cursor_User_workspaceStorage_f286a127b07b48d0b85590b38d17346c_images_Capture_d__cran_2026-10-15_132954-4657da26-8db4-4b45-bb36-ab8f8e80ce8a.png"
Copy-Ref "ref-lynx-erect-side-clean.png" "c__Users_mathi_AppData_Roaming_Cursor_User_workspaceStorage_f286a127b07b48d0b85590b38d17346c_images_Capture_d__cran_2026-10-15_132459-9e90d23e-1dc5-402b-b1a5-1bfe7bac0c28.png"
Copy-Ref "ref-lynx-erect-side-thick.png" "c__Users_mathi_AppData_Roaming_Cursor_User_workspaceStorage_f286a127b07b48d0b85590b38d17346c_images_Capture_d__cran_2026-10-15_132503-738d279d-982a-4953-a935-ff630f89e32b.png"
Copy-Ref "ref-lynx-erect-side-long.png" "c__Users_mathi_AppData_Roaming_Cursor_User_workspaceStorage_f286a127b07b48d0b85590b38d17346c_images_Capture_d__cran_2026-10-15_132641-0873d00a-4bdb-4a88-a0b6-f4d72a06614f.png"
$live = "C:\Users\mathi\Documents\Rimworld new mods\mods\RJWAnimalTextures\Textures\SizedApparel\BodyParts\Human\Penis"
[LynxVariety]::Build($inv, $live, (Join-Path $inv "preview-LynxVariety.png"))
