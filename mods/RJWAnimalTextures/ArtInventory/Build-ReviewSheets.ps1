Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = "Stop"

Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;

public static class ReviewSheets
{
    public static void Build(string root, string prefix, string dest)
    {
        string[] rows = new string[] { "Aroused south", "Aroused east", "Rest south", "Rest east" };
        string[] folders = new string[] { "Horny", "Horny", "", "" };
        string[] dirs = new string[] { "south", "east", "south", "east" };
        int cell = 240;
        int label = 28;
        Bitmap sheet = new Bitmap(6 * cell, 4 * (cell + label), PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(sheet))
        using (Font font = new Font("Segoe UI", 16f, FontStyle.Regular, GraphicsUnit.Pixel))
        using (Brush brush = new SolidBrush(Color.White))
        {
            g.Clear(Color.FromArgb(255, 28, 24, 32));
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
            g.PixelOffsetMode = PixelOffsetMode.HighQuality;
            for (int row = 0; row < 4; row++)
            {
                for (int i = 0; i < 6; i++)
                {
                    string folder = folders[row].Length == 0 ? root : Path.Combine(root, folders[row]);
                    string path = Path.Combine(folder, prefix + "_" + i + "_RNW_" + dirs[row] + ".png");
                    using (Bitmap src = new Bitmap(path))
                    {
                        int minX, minY, maxX, maxY;
                        Bounds(src, out minX, out minY, out maxX, out maxY);
                        int cw = Math.Max(1, maxX - minX + 1);
                        int ch = Math.Max(1, maxY - minY + 1);
                        float scale = Math.Min((cell - 16f) / cw, (cell - 16f) / ch);
                        float dw = cw * scale;
                        float dh = ch * scale;
                        float dx = i * cell + (cell - dw) * 0.5f;
                        float dy = row * (cell + label) + label + (cell - dh) * 0.5f;
                        g.DrawImage(src, new RectangleF(dx, dy, dw, dh), new RectangleF(minX, minY, cw, ch), GraphicsUnit.Pixel);
                    }
                    g.DrawString(rows[row] + "  " + i, font, brush, new RectangleF(i * cell + 8, row * (cell + label) + 4, cell - 12, label));
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
        bool any = false;
        for (int y = 0; y < src.Height; y++)
        {
            for (int x = 0; x < src.Width; x++)
            {
                if (src.GetPixel(x, y).A < 16) continue;
                any = true;
                if (x < minX) minX = x;
                if (y < minY) minY = y;
                if (x > maxX) maxX = x;
                if (y > maxY) maxY = y;
            }
        }
        if (!any)
        {
            minX = 0;
            minY = 0;
            maxX = Math.Min(8, src.Width - 1);
            maxY = Math.Min(8, src.Height - 1);
        }
    }
}
'@

$root = "C:\Users\mathi\Documents\Rimworld new mods\sized-apparel-zero\Textures\SizedApparel\BodyParts\Human\Penis"
$out = "C:\Users\mathi\Documents\Rimworld new mods\mods\RJWAnimalTextures\ArtInventory"
[ReviewSheets]::Build($root, "DragonPenis", (Join-Path $out "review-DragonPenis.png"))
[ReviewSheets]::Build($root, "CatPenis", (Join-Path $out "review-CatPenis.png"))
Write-Output "sheets written"
