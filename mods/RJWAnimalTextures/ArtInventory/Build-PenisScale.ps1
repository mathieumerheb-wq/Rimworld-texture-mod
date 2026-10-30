# Fit generated penis sprites to the Sized Apparel human height ladder.
# The whole 512 texture is drawn at one cell, and the human erect base sits at y=262.
# Deer sizes 3-5 stay on the horse sprites. Wolf is seated by Build-WolfSeat.ps1. Balls and blank north files stay.
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = "Stop"

Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;

public static class PenisScale
{
    public static void Build(string root)
    {
        float[] humanHorny = new float[] { 40f, 46f, 64f, 79f, 92f, 120f };
        float[] humanRest = new float[] { 27f, 37f, 59f, 61f, 67f, 81f };
        float[] horseHorny = new float[] { 52f, 67f, 92f, 120f, 147f, 252f };
        float[] horseRest = new float[] { 23f, 23f, 32f, 39f, 52f, 83f };
        string[] names = new string[] {
            "BovinePenis", "CloacalPenis", "CrocodilianPenis", "DemonTentaclePenis", "ElfPenis",
            "FoxPenis", "HemiPenis", "LynxPenis", "NeedlePenis", "PigPenis", "RaccoonPenis"
        };
        foreach (string name in names)
            FitSpecies(root, name, humanHorny, humanRest, 0, 5);
        FitSpecies(root, "DeerPenis", horseHorny, horseRest, 0, 2);
    }

    static void FitSpecies(string root, string name, float[] horny, float[] rest, int from, int to)
    {
        for (int size = from; size <= to; size++)
        {
            FitPair(root, name, size, false, rest[size]);
            FitPair(root, name, size, true, horny[size]);
        }
    }

    static void FitPair(string root, string name, int size, bool aroused, float targetH)
    {
        string folder = aroused ? Path.Combine(root, "Horny") : root;
        string southPath = Path.Combine(folder, name + "_" + size + "_south.png");
        string eastPath = Path.Combine(folder, name + "_" + size + "_east.png");
        if (!File.Exists(southPath)) return;
        Bitmap south = new Bitmap(southPath);
        if (south.Width < 32)
        {
            south.Dispose();
            return;
        }
        int minX, minY, maxX, maxY;
        if (!Box(south, out minX, out minY, out maxX, out maxY))
        {
            south.Dispose();
            return;
        }
        float contentH = maxY - minY + 1;
        float scale = targetH / Math.Max(1f, contentH);
        Console.WriteLine(Path.GetFileName(southPath) + " " + contentH.ToString("0") + " -> " + targetH.ToString("0"));
        SaveScaled(south, scale, (minX + maxX) * 0.5f, aroused ? maxY : minY, 256f, aroused ? 262f : 245f, southPath);
        if (!File.Exists(eastPath)) return;
        Bitmap east = new Bitmap(eastPath);
        if (east.Width < 32)
        {
            east.Dispose();
            return;
        }
        if (!Box(east, out minX, out minY, out maxX, out maxY))
        {
            east.Dispose();
            return;
        }
        SaveScaled(east, scale, minX, aroused ? maxY : minY, 242f, aroused ? 266f : 240f, eastPath);
    }

    static void SaveScaled(Bitmap src, float scale, float originX, float originY, float destX, float destY, string path)
    {
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

$root = "C:\Users\mathi\Documents\Rimworld new mods\mods\RJWAnimalTextures\Textures\SizedApparel\BodyParts\Human\Penis"
[PenisScale]::Build($root)
