# Already applied. The side ear rotation is not safe to run twice.
Write-Host "Build-LynxAttach.ps1 already applied."
exit 0

Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = "Stop"

Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;

public static class LynxAttach
{
    public static void Build(string horny, string ears)
    {
        for (int size = 0; size <= 5; size++)
            SeatEast(Path.Combine(horny, "LynxPenis_" + size + "_east.png"));
        StandEar(Path.Combine(ears, "LynxEars_east.png"));
        Gray(Path.Combine(ears, "LynxEars_south.png"));
        Gray(Path.Combine(ears, "LynxEars_east.png"));
        Gray(Path.Combine(ears, "LynxEars_north.png"));
    }

    static void SeatEast(string path)
    {
        Bitmap src = new Bitmap(path);
        int minX, minY, maxX, maxY;
        Box(src, out minX, out minY, out maxX, out maxY);
        int cut = maxY - (int)((maxY - minY) * 0.35f);
        double sx = 0, sy = 0;
        int n = 0;
        for (int y = cut; y <= maxY; y++)
        for (int x = minX; x <= maxX; x++)
        {
            if (src.GetPixel(x, y).A < 16) continue;
            sx += x;
            sy += y;
            n++;
        }
        int dx = 244 - (int)Math.Round(sx / Math.Max(1, n));
        int dy = 264 - (int)Math.Round(sy / Math.Max(1, n));
        if (dx == 0 && dy == 0)
        {
            src.Dispose();
            Console.WriteLine(Path.GetFileName(path) + " already seated");
            return;
        }
        Shift(src, dx, dy, path);
        Console.WriteLine(Path.GetFileName(path) + " dx " + dx + " dy " + dy);
    }

    static void StandEar(string path)
    {
        Bitmap src = new Bitmap(path);
        Bitmap bmp = new Bitmap(src.Width, src.Height, PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(bmp))
        {
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
            g.PixelOffsetMode = PixelOffsetMode.HighQuality;
            g.TranslateTransform(245f, 229f);
            g.RotateTransform(15f);
            g.TranslateTransform(-245f, -229f);
            g.DrawImage(src, 14, -8);
        }
        src.Dispose();
        bmp.Save(path, ImageFormat.Png);
        bmp.Dispose();
        Console.WriteLine("east ear stood up");
    }

    static void Gray(string path)
    {
        Bitmap src = new Bitmap(path);
        Bitmap bmp = new Bitmap(src.Width, src.Height, PixelFormat.Format32bppArgb);
        for (int y = 0; y < src.Height; y++)
        for (int x = 0; x < src.Width; x++)
        {
            Color c = src.GetPixel(x, y);
            if (c.A < 16) continue;
            int luma = (int)(c.R * 0.299f + c.G * 0.587f + c.B * 0.114f);
            bmp.SetPixel(x, y, Color.FromArgb(c.A, luma, luma, luma));
        }
        src.Dispose();
        bmp.Save(path, ImageFormat.Png);
        bmp.Dispose();
        Console.WriteLine(Path.GetFileName(path) + " hair mask");
    }

    static void Shift(Bitmap src, int dx, int dy, string path)
    {
        Bitmap bmp = new Bitmap(src.Width, src.Height, PixelFormat.Format32bppArgb);
        for (int y = 0; y < src.Height; y++)
        for (int x = 0; x < src.Width; x++)
        {
            Color c = src.GetPixel(x, y);
            if (c.A < 16) continue;
            int nx = x + dx;
            int ny = y + dy;
            if (nx < 0 || ny < 0 || nx >= bmp.Width || ny >= bmp.Height) continue;
            bmp.SetPixel(nx, ny, c);
        }
        src.Dispose();
        bmp.Save(path, ImageFormat.Png);
        bmp.Dispose();
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
}
'@

$root = "C:\Users\mathi\Documents\Rimworld new mods\mods\RJWAnimalTextures\Textures"
[LynxAttach]::Build(
    (Join-Path $root "SizedApparel\BodyParts\Human\Penis\Horny"),
    (Join-Path $root "Things\Pawn\Humanlike\HeadAttachments\LynxEars"))
