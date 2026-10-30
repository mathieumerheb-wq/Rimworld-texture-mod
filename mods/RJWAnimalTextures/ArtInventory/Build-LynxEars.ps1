# The live ear files were adjusted after this script: the side ear is rotated, and the fur is a hair-color mask.
# Re-running this restores the old painted ears.
Write-Host "Build-LynxEars.ps1 would restore the old ears. The live files are the adjusted ones."
exit 0

# Lynx ears. South is the supplied front pair.
# East is the right ear, at the cat side-ear size.
# North is the same pair with the inner ear closed, so the back has no pink cavity.
# All three sit on a 512 canvas in the same place as the feline ears.
Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = "Stop"

Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;

public static class LynxEars
{
    public static void Build(string referencePath, string catDir, string outDir, string genePath, string previewPath)
    {
        Directory.CreateDirectory(outDir);
        using (Bitmap reference = Load(referencePath))
        {
            Bitmap north = CloseInner(reference);
            Bitmap side = CropEar(reference, 68);
            float scale = 1.15f;
            SavePlaced(reference, scale, 227f, 256f, Path.Combine(outDir, "LynxEars_south.png"));
            SavePlaced(north, scale, 227f, 256f, Path.Combine(outDir, "LynxEars_north.png"));
            SavePlaced(side, scale, 229f, 246f, Path.Combine(outDir, "LynxEars_east.png"));
            SaveGene(reference, genePath);
            BuildPreview(catDir, outDir, previewPath);
            north.Dispose();
            side.Dispose();
        }
    }

    static bool Page(Color c)
    {
        int min = Math.Min(c.R, Math.Min(c.G, c.B));
        int max = Math.Max(c.R, Math.Max(c.G, c.B));
        return c.A < 16 || (min >= 248 && (max - min) < 18);
    }

    static Bitmap Load(string path)
    {
        using (Bitmap source = new Bitmap(path))
        {
            Bitmap bmp = new Bitmap(source.Width, source.Height, PixelFormat.Format32bppArgb);
            for (int y = 0; y < source.Height; y++)
            for (int x = 0; x < source.Width; x++)
            {
                Color c = source.GetPixel(x, y);
                if (Page(c)) continue;
                bmp.SetPixel(x, y, Color.FromArgb(255, c.R, c.G, c.B));
            }
            return bmp;
        }
    }

    static Bitmap CloseInner(Bitmap src)
    {
        Bitmap bmp = new Bitmap(src.Width, src.Height, PixelFormat.Format32bppArgb);
        for (int y = 0; y < src.Height; y++)
        for (int x = 0; x < src.Width; x++)
        {
            Color c = src.GetPixel(x, y);
            if (c.A < 16) continue;
            int min = Math.Min(c.R, Math.Min(c.G, c.B));
            int max = Math.Max(c.R, Math.Max(c.G, c.B));
            bool inner = min >= 176 && (max - min) < 70;
            if (!inner)
            {
                bmp.SetPixel(x, y, c);
                continue;
            }
            bmp.SetPixel(x, y, Color.FromArgb(255, 168, 124, 92));
        }
        return bmp;
    }

    static Bitmap CropEar(Bitmap src, int x0)
    {
        Bitmap bmp = new Bitmap(src.Width, src.Height, PixelFormat.Format32bppArgb);
        for (int y = 0; y < src.Height; y++)
        for (int x = x0; x < src.Width; x++)
        {
            Color c = src.GetPixel(x, y);
            if (c.A < 16) continue;
            bmp.SetPixel(x, y, c);
        }
        return bmp;
    }

    static void Content(Bitmap art, out int minX, out int minY, out int maxX, out int maxY)
    {
        minX = art.Width;
        minY = art.Height;
        maxX = -1;
        maxY = -1;
        for (int y = 0; y < art.Height; y++)
        for (int x = 0; x < art.Width; x++)
        {
            if (art.GetPixel(x, y).A < 16) continue;
            if (x < minX) minX = x;
            if (y < minY) minY = y;
            if (x > maxX) maxX = x;
            if (y > maxY) maxY = y;
        }
    }

    static void SavePlaced(Bitmap art, float scale, float bottom, float centerX, string path)
    {
        int minX, minY, maxX, maxY;
        Content(art, out minX, out minY, out maxX, out maxY);
        Bitmap bmp = new Bitmap(512, 512, PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(bmp))
        {
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
            g.PixelOffsetMode = PixelOffsetMode.HighQuality;
            g.SmoothingMode = SmoothingMode.HighQuality;
            float dw = art.Width * scale;
            float dh = art.Height * scale;
            float dx = centerX - ((minX + maxX) * 0.5f) * scale;
            float dy = bottom - (maxY + 1) * scale;
            g.DrawImage(art, dx, dy, dw, dh);
        }
        bmp.Save(path, ImageFormat.Png);
        bmp.Dispose();
    }

    static void SaveGene(Bitmap art, string path)
    {
        int minX, minY, maxX, maxY;
        Content(art, out minX, out minY, out maxX, out maxY);
        float contentW = Math.Max(1, maxX - minX + 1);
        float contentH = Math.Max(1, maxY - minY + 1);
        float scale = Math.Min(420f / contentW, 420f / contentH);
        Bitmap bmp = new Bitmap(512, 512, PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(bmp))
        {
            g.Clear(Color.FromArgb(255, 46, 42, 40));
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
            g.PixelOffsetMode = PixelOffsetMode.HighQuality;
            float dw = art.Width * scale;
            float dh = art.Height * scale;
            float dx = 256f - ((minX + maxX) * 0.5f) * scale;
            float dy = 256f - ((minY + maxY) * 0.5f) * scale;
            g.DrawImage(art, dx, dy, dw, dh);
        }
        string dir = Path.GetDirectoryName(path);
        if (!string.IsNullOrEmpty(dir)) Directory.CreateDirectory(dir);
        bmp.Save(path, ImageFormat.Png);
        bmp.Dispose();
    }

    static void BuildPreview(string catDir, string outDir, string previewPath)
    {
        string[] names = new string[] { "south", "east", "north" };
        Bitmap sheet = new Bitmap(1100, 1680, PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(sheet))
        {
            g.Clear(Color.FromArgb(255, 28, 28, 32));
            g.InterpolationMode = InterpolationMode.NearestNeighbor;
            using (Font font = new Font("Segoe UI", 20f, FontStyle.Regular, GraphicsUnit.Pixel))
            using (Brush brush = new SolidBrush(Color.FromArgb(255, 230, 226, 220)))
            {
                for (int i = 0; i < names.Length; i++)
                {
                    int y = 16 + i * 550;
                    g.DrawString("Cat " + names[i], font, brush, 24, y);
                    g.DrawString("Lynx " + names[i], font, brush, 560, y);
                    using (Bitmap cat = new Bitmap(Path.Combine(catDir, "CatEars_" + names[i] + ".png")))
                    using (Bitmap lynx = new Bitmap(Path.Combine(outDir, "LynxEars_" + names[i] + ".png")))
                    {
                        g.DrawImage(cat, 24, y + 28, 500, 500);
                        g.DrawImage(lynx, 560, y + 28, 500, 500);
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

$inv = "C:\Users\mathi\Documents\Rimworld new mods\mods\RJWAnimalTextures\ArtInventory\TextureV2"
$ref = Join-Path $inv "reference-lynx-ears.png"
Copy-Item "C:\Users\mathi\.cursor\projects\c-Users-mathi-Documents-Rimworld-new-mods\assets\c__Users_mathi_AppData_Roaming_Cursor_User_workspaceStorage_f286a127b07b48d0b85590b38d17346c_images_Capture_d__cran_2026-10-14_171323-66f22780-2e1f-4f1c-b1ee-a68feeb8fde0.png" $ref -Force
$out = "C:\Users\mathi\Documents\Rimworld new mods\mods\RJWAnimalTextures\Textures\Things\Pawn\Humanlike\HeadAttachments\LynxEars"
$gene = "C:\Users\mathi\Documents\Rimworld new mods\mods\RJWAnimalTextures\Textures\Genes\Icons\RJWAT_lynx_ears.png"
$cat = "C:\Program Files (x86)\Steam\steamapps\common\RimWorld\Mods\sized-apparel-heads\Textures\Things\Pawn\Humanlike\HeadAttachments\CatEars"
[LynxEars]::Build($ref, $cat, $out, $gene, (Join-Path $inv "preview-LynxEars.png"))
