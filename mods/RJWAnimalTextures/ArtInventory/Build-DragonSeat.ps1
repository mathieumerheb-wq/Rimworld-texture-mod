# Applied once. Running again would shift the pictures a second time.
exit 0

# Raise each dragon sprite so its base sits on the original dog crotch line.
# Dog files are 256 and drawn as one cell, so their base Y is doubled onto the 512 canvas.
# A sprite that would leave the canvas is scaled down from that base.
# Running this again shifts the pictures a second time.
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = "Stop"

Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.Globalization;
using System.IO;

public static class DragonSeat
{
    public static void Build(string dragonRoot, string dogRoot)
    {
        CultureInfo c = CultureInfo.InvariantCulture;
        for (int size = 0; size <= 5; size++)
        {
            Seat(dragonRoot, dogRoot, size, false, "south", c);
            Seat(dragonRoot, dogRoot, size, false, "east", c);
            Seat(dragonRoot, dogRoot, size, true, "south", c);
            Seat(dragonRoot, dogRoot, size, true, "east", c);
        }
    }

    static void Seat(string dragonRoot, string dogRoot, int size, bool aroused, string dir, CultureInfo c)
    {
        string dragonFolder = aroused ? Path.Combine(dragonRoot, "Horny") : dragonRoot;
        string dogFolder = aroused ? Path.Combine(dogRoot, "Horny") : dogRoot;
        string path = Path.Combine(dragonFolder, "DragonPenis_" + size + "_RNW_" + dir + ".png");
        string dogPath = Path.Combine(dogFolder, "DogPenis_" + size + "_RNW_" + dir + ".png");
        Bitmap src = new Bitmap(path);
        if (src.Width < 32)
        {
            src.Dispose();
            Console.WriteLine(Path.GetFileName(path) + " skip");
            return;
        }
        int minX, minY, maxX, maxY;
        if (!Box(src, out minX, out minY, out maxX, out maxY))
        {
            src.Dispose();
            Console.WriteLine(Path.GetFileName(path) + " blank");
            return;
        }
        Bitmap dog = new Bitmap(dogPath);
        int dMinX, dMinY, dMaxX, dMaxY;
        Box(dog, out dMinX, out dMinY, out dMaxX, out dMaxY);
        int dogCanvas = dog.Width;
        dog.Dispose();
        int targetBase = (int)Math.Round(dMaxY * (512.0 / dogCanvas));
        int height = maxY - minY + 1;
        int room = targetBase - 8;
        float scale = height > room ? (float)room / height : 1f;
        bool south = dir == "south";
        float originX = south ? (minX + maxX) * 0.5f : minX;
        float originY = maxY;
        Bitmap bmp = new Bitmap(512, 512, PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(bmp))
        {
            g.InterpolationMode = scale == 1f ? InterpolationMode.NearestNeighbor : InterpolationMode.HighQualityBicubic;
            g.PixelOffsetMode = PixelOffsetMode.HighQuality;
            g.TranslateTransform(originX, targetBase);
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
        Console.WriteLine(string.Format(c, "{0} {1} scale {2:0.00} base {3} top {4} x {5}-{6}",
            aroused ? "horny" : "rest", Path.GetFileName(path), scale, maxY, minY, minX, maxX));
    }

    static bool Box(Bitmap src, out int minX, out int minY, out int maxX, out int maxY)
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
        return maxX >= 0;
    }
}
'@

$dragon = "C:\Users\mathi\Documents\Rimworld new mods\sized-apparel-zero\Textures\SizedApparel\BodyParts\Human\Penis"
$dog = "C:\Program Files (x86)\Steam\steamapps\common\RimWorld\Mods\sized-apparel-zero\Textures\SizedApparel\BodyParts\Human\Penis"
[DragonSeat]::Build($dragon, $dog)
