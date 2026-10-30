# Raises dragon aroused sizes 3, 4, and 5. South 3 and 4 are rebuilt from the source drawings.
# This pass rescales the remaining files onto the same taller heights.
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = "Stop"

Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;

public static class DragonLarge
{
    public static void Scale(string path, int targetH, int baseY, bool east)
    {
        Bitmap src = new Bitmap(path);
        int minX, minY, maxX, maxY;
        Bounds(src, out minX, out minY, out maxX, out maxY);
        int cw = maxX - minX + 1;
        int ch = maxY - minY + 1;
        float scale = targetH / (float)ch;
        float dw = cw * scale;
        float dh = ch * scale;
        float dx = east ? 221f : 256f - dw * 0.5f;
        float dy = baseY - dh;
        Bitmap placed = new Bitmap(512, 512, PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(placed))
        {
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
            g.PixelOffsetMode = PixelOffsetMode.HighQuality;
            g.SmoothingMode = SmoothingMode.HighQuality;
            g.DrawImage(src, new RectangleF(dx, dy, dw, dh), new RectangleF(minX, minY, cw, ch), GraphicsUnit.Pixel);
        }
        src.Dispose();
        int pMinX, pMinY, pMaxX, pMaxY;
        Bounds(placed, out pMinX, out pMinY, out pMaxX, out pMaxY);
        placed.Save(path, ImageFormat.Png);
        placed.Dispose();
        Console.WriteLine(Path.GetFileName(path)
            + " h " + (pMaxY - pMinY + 1)
            + " base " + pMaxY
            + " x " + pMinX + "-" + pMaxX);
    }

    public static void ScaleSheet(string horny, string dest)
    {
        int cellW = 210;
        int cellH = 230;
        int label = 24;
        Bitmap sheet = new Bitmap(6 * cellW, 2 * (cellH + label), PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(sheet))
        using (Font font = new Font("Segoe UI", 16f, FontStyle.Regular, GraphicsUnit.Pixel))
        using (Brush brush = new SolidBrush(Color.White))
        {
            g.Clear(Color.FromArgb(255, 28, 24, 32));
            g.InterpolationMode = InterpolationMode.NearestNeighbor;
            g.PixelOffsetMode = PixelOffsetMode.Half;
            string[] dirs = new string[] { "south", "east" };
            for (int row = 0; row < 2; row++)
            {
                for (int i = 0; i < 6; i++)
                {
                    string path = Path.Combine(horny, "DragonPenis_" + i + "_RNW_" + dirs[row] + ".png");
                    using (Bitmap src = new Bitmap(path))
                    {
                        int minX, minY, maxX, maxY;
                        Bounds(src, out minX, out minY, out maxX, out maxY);
                        int cw = maxX - minX + 1;
                        int ch = maxY - minY + 1;
                        float dx = i * cellW + (cellW - cw) * 0.5f;
                        float dy = row * (cellH + label) + label + (cellH - ch);
                        g.DrawImage(src, new RectangleF(dx, dy, cw, ch), new RectangleF(minX, minY, cw, ch), GraphicsUnit.Pixel);
                        g.DrawString(dirs[row] + " " + i + "  " + ch + "px", font, brush, new RectangleF(i * cellW + 8, row * (cellH + label) + 4, cellW - 12, label));
                    }
                }
            }
        }
        sheet.Save(dest, ImageFormat.Png);
        sheet.Dispose();
    }

    static void Bounds(Bitmap src, out int minX, out int minY, out int maxX, out int maxY)
    {
        minX = src.Width;
        minY = src.Height;
        maxX = 0;
        maxY = 0;
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

$horny = "C:\Users\mathi\Documents\Rimworld new mods\sized-apparel-zero\Textures\SizedApparel\BodyParts\Human\Penis\Horny"
[DragonLarge]::Scale((Join-Path $horny "DragonPenis_5_RNW_south.png"), 200, 282, $false)
[DragonLarge]::Scale((Join-Path $horny "DragonPenis_3_RNW_east.png"), 130, 286, $true)
[DragonLarge]::Scale((Join-Path $horny "DragonPenis_4_RNW_east.png"), 144, 286, $true)
[DragonLarge]::Scale((Join-Path $horny "DragonPenis_5_RNW_east.png"), 180, 300, $true)
$sheet = "C:\Users\mathi\Documents\Rimworld new mods\mods\RJWAnimalTextures\ArtInventory\review-DragonScale.png"
[DragonLarge]::ScaleSheet($horny, $sheet)
Write-Output "SCALE $sheet"
