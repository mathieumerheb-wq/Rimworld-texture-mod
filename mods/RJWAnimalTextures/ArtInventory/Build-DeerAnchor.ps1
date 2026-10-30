# Already applied. Running again would shift the deer erects a second time.
# Deer east was later moved 40 px forward by Build-DeerEastFix.ps1 (2026-10-24).
Write-Host "Build-DeerAnchor.ps1 already applied. Do not run it again."
exit 0

Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = "Stop"

Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;

public static class DeerAnchor
{
    public static void Build(string horny)
    {
        Shift(Path.Combine(horny, "DeerPenis_3_south.png"), 5, -21);
        Shift(Path.Combine(horny, "DeerPenis_4_south.png"), 5, -23);
        Shift(Path.Combine(horny, "DeerPenis_5_south.png"), 10, -35);
        Shift(Path.Combine(horny, "DeerPenis_3_east.png"), 75, -44);
        Shift(Path.Combine(horny, "DeerPenis_4_east.png"), 92, -59);
        Shift(Path.Combine(horny, "DeerPenis_5_east.png"), 98, -129);
    }

    static void Shift(string path, int dx, int dy)
    {
        Bitmap src = new Bitmap(path);
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
        Console.WriteLine(Path.GetFileName(path) + " dx " + dx + " dy " + dy);
    }
}
'@

$horny = "C:\Users\mathi\Documents\Rimworld new mods\mods\RJWAnimalTextures\Textures\SizedApparel\BodyParts\Human\Penis\Horny"
[DeerAnchor]::Build($horny)
