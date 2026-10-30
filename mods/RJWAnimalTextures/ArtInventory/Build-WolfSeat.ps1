# Applied once. Running again would shift the pictures a second time.
exit 0

# Seat wolf erect sprites on the original DogPenis anchor, and draw sizes 3-5 at 120%.
# Dog files are 256 and drawn at one cell, so their base Y is doubled onto our 512 canvas.
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = "Stop"

Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;

public static class WolfSeat
{
    public static void Build(string root)
    {
        int[] southBase = new int[] { 268, 268, 268, 268, 268, 282 };
        int[] eastBase = new int[] { 282, 282, 286, 286, 286, 300 };
        for (int size = 0; size <= 5; size++)
        {
            float scale = size >= 3 ? 1.2f : 1f;
            Seat(Path.Combine(root, "Horny", "WolfPenis_" + size + "_south.png"), scale, true, true, southBase[size]);
            Seat(Path.Combine(root, "Horny", "WolfPenis_" + size + "_east.png"), scale, true, false, eastBase[size]);
            if (size < 3) continue;
            Seat(Path.Combine(root, "WolfPenis_" + size + "_south.png"), 1.2f, false, true, 0);
            Seat(Path.Combine(root, "WolfPenis_" + size + "_east.png"), 1.2f, false, false, 0);
        }
    }

    static void Seat(string path, float scale, bool aroused, bool south, int targetBase)
    {
        Bitmap src = new Bitmap(path);
        if (src.Width < 32)
        {
            src.Dispose();
            Console.WriteLine(Path.GetFileName(path) + " skip");
            return;
        }
        int minX, minY, maxX, maxY;
        Box(src, out minX, out minY, out maxX, out maxY);
        float originX = south ? (minX + maxX) * 0.5f : minX;
        float originY = aroused ? maxY : minY;
        float destX = originX;
        float destY = aroused ? targetBase : minY;
        Bitmap bmp = new Bitmap(512, 512, PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(bmp))
        {
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
            g.PixelOffsetMode = PixelOffsetMode.HighQuality;
            g.TranslateTransform(destX, destY);
            g.ScaleTransform(scale, scale);
            g.TranslateTransform(-originX, -originY);
            g.DrawImage(src, 0, 0, src.Width, src.Height);
        }
        src.Dispose();
        bmp.Save(path, ImageFormat.Png);
        bmp.Dispose();
        Bitmap check = new Bitmap(path);
        Box(check, out minX, out minY, out maxX, out maxY);
        check.Dispose();
        Console.WriteLine(Path.GetFileName(path) + " base " + maxY + " top " + minY + " " + (maxX - minX + 1) + "x" + (maxY - minY + 1));
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

$root = "C:\Users\mathi\Documents\Rimworld new mods\mods\RJWAnimalTextures\Textures\SizedApparel\BodyParts\Human\Penis"
[WolfSeat]::Build($root)
