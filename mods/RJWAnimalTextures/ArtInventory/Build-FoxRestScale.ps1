# Retired. Penis scale is applied by Build-PenisScale.ps1.
Write-Host "Build-FoxRestScale.ps1 is retired. Use Build-PenisScale.ps1."
exit 0

Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = "Stop"

Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;

public static class FoxRestScale
{
    public static void Build(string root)
    {
        float[] south = new float[] { 48f, 64f, 78f, 87f, 102f, 118f };
        float[] east = new float[] { 47f, 65f, 96f, 86f, 102f, 119f };
        for (int size = 0; size <= 5; size++)
        {
            Fit(root + "\\FoxPenis_" + size + "_south.png", south[size]);
            Fit(root + "\\FoxPenis_" + size + "_east.png", east[size]);
        }
    }

    static void Fit(string path, float targetH)
    {
        Bitmap src = new Bitmap(path);
        int minX = src.Width, minY = src.Height, maxX = -1, maxY = -1;
        for (int y = 0; y < src.Height; y++)
        for (int x = 0; x < src.Width; x++)
        {
            if (src.GetPixel(x, y).A < 16) continue;
            if (x < minX) minX = x;
            if (y < minY) minY = y;
            if (x > maxX) maxX = x;
            if (y > maxY) maxY = y;
        }
        float contentH = Math.Max(1, maxY - minY + 1);
        if (Math.Abs(contentH - targetH) < 2f)
        {
            src.Dispose();
            Console.WriteLine(System.IO.Path.GetFileName(path) + " already " + contentH.ToString("0"));
            return;
        }
        float scale = targetH / contentH;
        float topX = (minX + maxX) * 0.5f;
        float topY = minY;
        Bitmap bmp = new Bitmap(512, 512, PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(bmp))
        {
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
            g.PixelOffsetMode = PixelOffsetMode.HighQuality;
            g.TranslateTransform(topX, topY);
            g.ScaleTransform(scale, scale);
            g.TranslateTransform(-topX, -topY);
            g.DrawImage(src, 0, 0, src.Width, src.Height);
        }
        src.Dispose();
        bmp.Save(path, ImageFormat.Png);
        bmp.Dispose();
        Console.WriteLine(System.IO.Path.GetFileName(path) + " " + contentH.ToString("0") + " -> " + targetH.ToString("0"));
    }
}
'@

$root = "C:\Users\mathi\Documents\Rimworld new mods\mods\RJWAnimalTextures\Textures\SizedApparel\BodyParts\Human\Penis"
[FoxRestScale]::Build($root)
