# CrocodilianPenis. Flaccid is the supplied genital slit, with the white background removed.
# Aroused is the croc gene picture coming out of that slit. The lips push apart around the base.
# South points up. East keeps the picture's own up-right angle. The slit stays vertical on the side.
# CrocodilianPenis is not in BodypartDetail_Penis.xml, so the filenames have no variation suffix.
# Ball files are blank so a scrotum is not drawn under the slit. North penis files are blank 4x4.
Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = "Stop"

Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;

public static class CrocodilianPenis
{
    static Bitmap Organ;
    static Bitmap Slit;
    static PointF OrganBase;
    static float OrganAngle;
    static float OrganLen;
    static float SlitCx;
    static float SlitCy;
    static float SlitW;
    static float SlitH;

    public static void Build(string organPath, string slitPath, string penisRoot, string previewPath, string slitOutPath)
    {
        string hornyDir = Path.Combine(penisRoot, "Horny");
        string balls = Path.Combine(penisRoot, "Balls");
        Directory.CreateDirectory(penisRoot);
        Directory.CreateDirectory(hornyDir);
        Directory.CreateDirectory(balls);
        using (Bitmap organ = new Bitmap(organPath))
        using (Bitmap slit = new Bitmap(slitPath))
        {
            Prepare(organ, slit);
            Slit.Save(slitOutPath, ImageFormat.Png);
            for (int size = 0; size <= 5; size++)
            {
                float organScale = 0.14f + size * 0.046f;
                Save(Render(size, organScale, false, false), Path.Combine(penisRoot, "CrocodilianPenis_" + size + "_south.png"));
                Save(Render(size, organScale, true, false), Path.Combine(penisRoot, "CrocodilianPenis_" + size + "_east.png"));
                Save(Blank(), Path.Combine(penisRoot, "CrocodilianPenis_" + size + "_north.png"));
                Save(Render(size, organScale, false, true), Path.Combine(hornyDir, "CrocodilianPenis_" + size + "_south.png"));
                Save(Render(size, organScale, true, true), Path.Combine(hornyDir, "CrocodilianPenis_" + size + "_east.png"));
                Save(Blank(), Path.Combine(hornyDir, "CrocodilianPenis_" + size + "_north.png"));
                Save(Blank(), Path.Combine(balls, "CrocodilianPenis_" + size + "_south.png"));
                Save(Blank(), Path.Combine(balls, "CrocodilianPenis_" + size + "_east.png"));
                Save(Blank(), Path.Combine(balls, "CrocodilianPenis_" + size + "_north.png"));
            }
        }
        Organ.Dispose();
        Slit.Dispose();
        BuildPreview(penisRoot, previewPath);
    }

    static bool Background(Color c)
    {
        int min = Math.Min(c.R, Math.Min(c.G, c.B));
        int max = Math.Max(c.R, Math.Max(c.G, c.B));
        return min >= 226 && (max - min) < 34;
    }

    static void Prepare(Bitmap organ, Bitmap slitSrc)
    {
        int minX = organ.Width, minY = organ.Height, maxX = -1, maxY = -1;
        for (int y = 0; y < organ.Height; y++)
        for (int x = 0; x < organ.Width; x++)
        {
            if (organ.GetPixel(x, y).A < 16) continue;
            if (x < minX) minX = x;
            if (y < minY) minY = y;
            if (x > maxX) maxX = x;
            if (y > maxY) maxY = y;
        }
        int baseLimit = minX + (int)((maxX - minX) * 0.12f);
        double bsx = 0, bsy = 0;
        int bn = 0;
        float far = -1f, tipX = 0f, tipY = 0f;
        for (int y = minY; y <= maxY; y++)
        for (int x = minX; x <= maxX; x++)
        {
            if (organ.GetPixel(x, y).A < 16) continue;
            if (x <= baseLimit)
            {
                bsx += x;
                bsy += y;
                bn++;
            }
        }
        OrganBase = new PointF((float)(bsx / bn), (float)(bsy / bn));
        for (int y = minY; y <= maxY; y++)
        for (int x = minX; x <= maxX; x++)
        {
            if (organ.GetPixel(x, y).A < 16) continue;
            float dx = x - OrganBase.X;
            float dy = y - OrganBase.Y;
            float d = dx * dx + dy * dy;
            if (d > far) { far = d; tipX = x; tipY = y; }
        }
        OrganLen = (float)Math.Sqrt(far);
        OrganAngle = (float)(Math.Atan2(-(tipY - OrganBase.Y), tipX - OrganBase.X) * 180.0 / Math.PI);
        Organ = new Bitmap(organ);

        int sMinX = slitSrc.Width, sMinY = slitSrc.Height, sMaxX = -1, sMaxY = -1;
        double scx = 0, scy = 0;
        int sn = 0;
        Slit = new Bitmap(slitSrc.Width, slitSrc.Height, PixelFormat.Format32bppArgb);
        for (int y = 0; y < slitSrc.Height; y++)
        for (int x = 0; x < slitSrc.Width; x++)
        {
            Color c = slitSrc.GetPixel(x, y);
            if (Background(c))
            {
                Slit.SetPixel(x, y, Color.Transparent);
                continue;
            }
            int min = Math.Min(c.R, Math.Min(c.G, c.B));
            int max = Math.Max(c.R, Math.Max(c.G, c.B));
            int a = 255;
            if (min >= 198 && (max - min) < 24) a = Math.Max(0, (226 - min) * 255 / 28);
            if (a < 16)
            {
                Slit.SetPixel(x, y, Color.Transparent);
                continue;
            }
            Slit.SetPixel(x, y, Color.FromArgb(a, c.R, c.G, c.B));
            sn++;
            scx += x;
            scy += y;
            if (x < sMinX) sMinX = x;
            if (y < sMinY) sMinY = y;
            if (x > sMaxX) sMaxX = x;
            if (y > sMaxY) sMaxY = y;
        }
        SlitCx = (float)(scx / sn);
        SlitCy = (float)(scy / sn);
        SlitW = sMaxX - sMinX + 1;
        SlitH = sMaxY - sMinY + 1;
        Console.WriteLine("ORGAN angle " + OrganAngle.ToString("0.0") + " len " + OrganLen.ToString("0") + " SLIT " + SlitW.ToString("0") + "x" + SlitH.ToString("0"));
    }

    static Bitmap Render(int size, float organScale, bool east, bool horny)
    {
        Bitmap bmp = new Bitmap(512, 512, PixelFormat.Format32bppArgb);
        float destX = east ? 236f : 256f;
        float destY = 300f;
        float angle = east ? OrganAngle : 90f;
        double rad = angle * Math.PI / 180.0;
        float ux = (float)Math.Cos(rad);
        float uy = -(float)Math.Sin(rad);
        float px = -uy;
        float py = ux;
        float baseW = 112f * organScale;
        float centerX = destX + ux * (26f * organScale);
        float centerY = destY + uy * (26f * organScale);
        float targetW = baseW * 1.18f;
        float xScale = targetW / SlitW;
        float yScale = targetW / SlitW;
        Bitmap organLayer = horny ? new Bitmap(512, 512, PixelFormat.Format32bppArgb) : null;
        float[] reach = null;
        if (horny)
        {
            using (Graphics g = Graphics.FromImage(organLayer))
            {
                g.Clear(Color.Transparent);
                g.TranslateTransform(destX, destY);
                g.RotateTransform(OrganAngle - angle);
                g.ScaleTransform(organScale, organScale);
                g.TranslateTransform(-OrganBase.X, -OrganBase.Y);
                g.InterpolationMode = InterpolationMode.HighQualityBicubic;
                g.PixelOffsetMode = PixelOffsetMode.HighQuality;
                g.DrawImage(Organ, 0, 0);
            }
            reach = new float[401];
            float offSide = 0f;
            float offN = 0f;
            for (int y = 0; y < organLayer.Height; y++)
            for (int x = 0; x < organLayer.Width; x++)
            {
                if (organLayer.GetPixel(x, y).A < 16) continue;
                float along0 = (x - centerX) * ux + (y - centerY) * uy;
                float side0 = (x - centerX) * px + (y - centerY) * py;
                if (Math.Abs(along0) > baseW * 0.5f) continue;
                offSide += side0;
                offN++;
            }
            if (offN > 0f)
            {
                centerX += px * (offSide / offN);
                centerY += py * (offSide / offN);
            }
            for (int y = 0; y < organLayer.Height; y++)
            for (int x = 0; x < organLayer.Width; x++)
            {
                if (organLayer.GetPixel(x, y).A < 16) continue;
                float along = (x - centerX) * ux + (y - centerY) * uy;
                float side = (x - centerX) * px + (y - centerY) * py;
                int bin = (int)Math.Round(along) + 200;
                if (bin < 0 || bin >= reach.Length) continue;
                if (Math.Abs(side) > reach[bin]) reach[bin] = Math.Abs(side);
            }
        }
        using (Graphics g = Graphics.FromImage(bmp))
        {
            g.Clear(Color.Transparent);
        }
        int span = (int)Math.Ceiling(SlitH * yScale * 0.5f + baseW * 0.75f);
        float zoneLen = baseW * 0.62f;
        int[] rowMin = null;
        int[] rowMax = null;
        if (horny && east)
        {
            rowMin = new int[organLayer.Height];
            rowMax = new int[organLayer.Height];
            for (int i = 0; i < rowMin.Length; i++)
            {
                rowMin[i] = 9999;
                rowMax[i] = -1;
            }
            for (int y = 0; y < organLayer.Height; y++)
            for (int x = 0; x < organLayer.Width; x++)
            {
                if (organLayer.GetPixel(x, y).A < 16) continue;
                float organAlong = (x - centerX) * ux + (y - centerY) * uy;
                if (Math.Abs(organAlong) > zoneLen) continue;
                if (x < rowMin[y]) rowMin[y] = x;
                if (x > rowMax[y]) rowMax[y] = x;
            }
        }
        Bitmap local = new Bitmap(span * 2 + 1, span * 2 + 1, PixelFormat.Format32bppArgb);
        for (int ly = 0; ly < local.Height; ly++)
        for (int lx = 0; lx < local.Width; lx++)
        {
            float side = lx - span;
            float along = span - ly;
            float push = 0f;
            bool hole = false;
            if (rowMin != null)
            {
                int sx = (int)Math.Round(centerX + side);
                int sy = (int)Math.Round(centerY - along);
                if (sy >= 0 && sy < rowMin.Length && rowMin[sy] <= rowMax[sy])
                {
                    float left = rowMin[sy] + 2.2f;
                    float right = rowMax[sy] - 2.2f;
                    if (right > left && sx > left && sx < right) hole = true;
                }
            }
            else if (reach != null)
            {
                int bin = (int)Math.Round(along) + 200;
                float organHalf = (bin >= 0 && bin < reach.Length) ? reach[bin] : 0f;
                float zone = 1f;
                if (Math.Abs(along) > zoneLen) zone = Math.Max(0f, 1f - (Math.Abs(along) - zoneLen) / (baseW * 0.28f));
                push = Math.Max(0f, organHalf - 2.2f) * zone;
            }
            if (hole) continue;
            if (push > 0.6f && Math.Abs(side) < push) continue;
            float srcSide = side - (float)Math.Sign(side) * push;
            int ix = (int)Math.Round(SlitCx + srcSide / xScale);
            int iy = (int)Math.Round(SlitCy - along / yScale);
            if (ix < 0 || iy < 0 || ix >= Slit.Width || iy >= Slit.Height) continue;
            Color sc = Slit.GetPixel(ix, iy);
            if (sc.A >= 16) local.SetPixel(lx, ly, sc);
        }
        using (Graphics g = Graphics.FromImage(bmp))
        {
            g.TranslateTransform(centerX, centerY);
            if (!east) g.RotateTransform(90f - angle);
            g.TranslateTransform(-span, -span);
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
            g.PixelOffsetMode = PixelOffsetMode.HighQuality;
            g.DrawImage(local, 0, 0);
        }
        local.Dispose();
        if (organLayer != null)
        {
            using (Graphics g = Graphics.FromImage(bmp))
            {
                g.DrawImage(organLayer, 0, 0);
            }
            organLayer.Dispose();
        }
        for (int y = 0; y < bmp.Height; y++)
        for (int x = 0; x < bmp.Width; x++)
        {
            Color c = bmp.GetPixel(x, y);
            int min = Math.Min(c.R, Math.Min(c.G, c.B));
            int max = Math.Max(c.R, Math.Max(c.G, c.B));
            if (c.A > 0 && c.A < 24) bmp.SetPixel(x, y, Color.Transparent);
            else if (c.A < 90 && min > 230 && (max - min) < 20) bmp.SetPixel(x, y, Color.Transparent);
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

    static void Content(Bitmap bmp, out int minX, out int minY, out int maxX, out int maxY, out int count)
    {
        minX = bmp.Width;
        minY = bmp.Height;
        maxX = -1;
        maxY = -1;
        count = 0;
        if (bmp.Width <= 8) return;
        for (int y = 0; y < bmp.Height; y++)
        for (int x = 0; x < bmp.Width; x++)
        {
            if (bmp.GetPixel(x, y).A < 16) continue;
            count++;
            if (x < minX) minX = x;
            if (y < minY) minY = y;
            if (x > maxX) maxX = x;
            if (y > maxY) maxY = y;
        }
    }

    static void BuildPreview(string penisRoot, string previewPath)
    {
        string[] labels = new string[] { "Rest south", "Rest east", "Aroused south", "Aroused east" };
        string[] dirs = new string[] { "south", "east", "south", "east" };
        bool[] horny = new bool[] { false, false, true, true };
        int winL = 511, winT = 511, winR = 0, winB = 0;
        for (int row = 0; row < dirs.Length; row++)
        for (int size = 0; size <= 5; size++)
        {
            string folder = horny[row] ? Path.Combine(penisRoot, "Horny") : penisRoot;
            using (Bitmap bmp = new Bitmap(Path.Combine(folder, "CrocodilianPenis_" + size + "_" + dirs[row] + ".png")))
            {
                int minX, minY, maxX, maxY, count;
                Content(bmp, out minX, out minY, out maxX, out maxY, out count);
                if (count == 0) continue;
                if (size == 0 || size == 5)
                    Console.WriteLine(labels[row] + " " + size + " box " + minX + "," + minY + "-" + maxX + "," + maxY + " n " + count);
                if (minX < winL) winL = minX;
                if (minY < winT) winT = minY;
                if (maxX > winR) winR = maxX;
                if (maxY > winB) winB = maxY;
            }
        }
        Rectangle window = Rectangle.FromLTRB(Math.Max(0, winL - 8), Math.Max(0, winT - 8), Math.Min(512, winR + 9), Math.Min(512, winB + 9));
        Bitmap sheet = new Bitmap(1200, 860, PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(sheet))
        using (Font font = new Font("Segoe UI", 12f, FontStyle.Regular, GraphicsUnit.Pixel))
        using (Brush brush = new SolidBrush(Color.FromArgb(255, 220, 220, 220)))
        {
            g.Clear(Color.FromArgb(255, 18, 18, 22));
            g.InterpolationMode = InterpolationMode.NearestNeighbor;
            g.PixelOffsetMode = PixelOffsetMode.Half;
            for (int row = 0; row < dirs.Length; row++)
            {
                g.DrawString(labels[row], font, brush, new RectangleF(16f, 8f + row * 210f, 180f, 20f));
                for (int size = 0; size <= 5; size++)
                {
                    string folder = horny[row] ? Path.Combine(penisRoot, "Horny") : penisRoot;
                    using (Bitmap bmp = new Bitmap(Path.Combine(folder, "CrocodilianPenis_" + size + "_" + dirs[row] + ".png")))
                    {
                        Rectangle cell = new Rectangle(16 + size * 196, 28 + row * 210, 180, 170);
                        float fit = Math.Min(cell.Width / (float)window.Width, cell.Height / (float)window.Height);
                        int pw = Math.Max(1, (int)(window.Width * fit));
                        int ph = Math.Max(1, (int)(window.Height * fit));
                        g.DrawImage(bmp, new Rectangle(cell.X + (cell.Width - pw) / 2, cell.Y + (cell.Height - ph) / 2, pw, ph), window, GraphicsUnit.Pixel);
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

$organ = "C:\Program Files (x86)\Steam\steamapps\common\RimWorld\Mods\rjw-genes\Common\Textures\Genes\Icons\Genitalia_croc_icon.png"
$slit = "C:\Users\mathi\.cursor\projects\c-Users-mathi-Documents-Rimworld-new-mods\assets\c__Users_mathi_AppData_Roaming_Cursor_User_workspaceStorage_f286a127b07b48d0b85590b38d17346c_images_mv7ttw1legxod7-f7423b16-2758-41ff-b8d0-7bcfdf39cca9.jpg"
$dest = "C:\Users\mathi\Documents\Rimworld new mods\mods\RJWAnimalTextures\Textures\SizedApparel\BodyParts\Human\Penis"
$preview = "C:\Users\mathi\Documents\Rimworld new mods\mods\RJWAnimalTextures\ArtInventory\TextureV2\preview-CrocodilianPenis.png"
$slitOut = "C:\Users\mathi\Documents\Rimworld new mods\mods\RJWAnimalTextures\ArtInventory\TextureV2\reference-crocodilian-slit.png"
Copy-Item -LiteralPath $organ -Destination "C:\Users\mathi\Documents\Rimworld new mods\mods\RJWAnimalTextures\ArtInventory\TextureV2\reference-Genitalia_croc_icon.png" -Force
[CrocodilianPenis]::Build($organ, $slit, $dest, $preview, $slitOut)
