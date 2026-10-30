# DeerPenis east placement fix. Reads the live east sprites and writes the fixed ones to Staging/DeerEast.
# Every deer east sprite sat about 40 px behind the Sized Apparel anchor: Sized Apparel human, horse,
# and dog east sprites start at x 235-250, and its balls are centered near x 254, while the deer
# scrotums were centered near x 205-218. Rest 3 and 4 were the horse sheath moved 40 px back.
# Erect 0-5 and rest 3-5 move 40 px forward. Pixels are copied, not resampled.
# Rest 0-2 had the sheath opening toward the back. They are mirrored so the opening faces forward,
# and their left edge is put on the Sized Apparel human rest of the same size (x 238, 239, 234).
# The bottom row and the south and north files do not change.
# The staged files were reviewed and copied into Textures by hand on 2026-10-24.
Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = "Stop"

Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;
using System.Runtime.InteropServices;

public static class DeerEastFix
{
    public static void Build(string live, string stage)
    {
        // Refuse to stage from sprites that were already moved.
        int left = Bounds(Read(Path.Combine(live, "Horny", "DeerPenis_2_east.png")))[0];
        if (left > 225) throw new Exception("Live Horny/DeerPenis_2_east.png already starts at x " + left + ". Fix was applied.");

        int[] restLeft = new int[] { 238, 239, 234 };
        for (int size = 0; size <= 5; size++)
        {
            Fix(Path.Combine(live, "Horny", "DeerPenis_" + size + "_east.png"), Path.Combine(stage, "Horny", "DeerPenis_" + size + "_east.png"), false, 40, -1);
            if (size <= 2)
                Fix(Path.Combine(live, "DeerPenis_" + size + "_east.png"), Path.Combine(stage, "DeerPenis_" + size + "_east.png"), true, 0, restLeft[size]);
            else
                Fix(Path.Combine(live, "DeerPenis_" + size + "_east.png"), Path.Combine(stage, "DeerPenis_" + size + "_east.png"), false, 40, -1);
        }
    }

    // Mirror within the sprite's own box if asked, then move by dx, or so the left edge lands on toLeft.
    static void Fix(string src, string dst, bool mirror, int dx, int toLeft)
    {
        Image img = Read(src);
        int[] b = Bounds(img);
        int minX = b[0], maxX = b[2];
        if (toLeft >= 0) dx = toLeft - minX;
        byte[] outPx = new byte[img.Px.Length];
        for (int y = 0; y < img.H; y++)
        for (int x = 0; x < img.W; x++)
        {
            int i = y * img.Stride + x * 4;
            if (img.Px[i + 3] == 0) continue;
            int sx = mirror ? (minX + maxX - x) : x;
            int nx = sx + dx;
            if (nx < 0 || nx >= img.W) throw new Exception(Path.GetFileName(src) + " would be cropped at x " + nx);
            Buffer.BlockCopy(img.Px, i, outPx, y * img.Stride + nx * 4, 4);
        }
        img.Px = outPx;
        Directory.CreateDirectory(Path.GetDirectoryName(dst));
        Write(img, dst);
        int[] a = Bounds(img);
        Console.WriteLine(Path.GetFileName(Path.GetDirectoryName(dst)) + "/" + Path.GetFileName(dst)
            + (mirror ? " mirrored" : "") + " x " + b[0] + "-" + b[2] + " -> " + a[0] + "-" + a[2] + ", y " + a[1] + "-" + a[3]);
    }

    class Image { public int W, H, Stride; public byte[] Px; }

    static Image Read(string path)
    {
        using (Bitmap src = new Bitmap(path))
        {
            Image img = new Image { W = src.Width, H = src.Height };
            BitmapData d = src.LockBits(new Rectangle(0, 0, img.W, img.H), ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
            img.Stride = d.Stride;
            img.Px = new byte[d.Stride * img.H];
            Marshal.Copy(d.Scan0, img.Px, 0, img.Px.Length);
            src.UnlockBits(d);
            return img;
        }
    }

    static void Write(Image img, string path)
    {
        using (Bitmap bmp = new Bitmap(img.W, img.H, PixelFormat.Format32bppArgb))
        {
            BitmapData d = bmp.LockBits(new Rectangle(0, 0, img.W, img.H), ImageLockMode.WriteOnly, PixelFormat.Format32bppArgb);
            Marshal.Copy(img.Px, 0, d.Scan0, img.Px.Length);
            bmp.UnlockBits(d);
            bmp.Save(path, ImageFormat.Png);
        }
    }

    static int[] Bounds(Image img)
    {
        int minX = img.W, minY = img.H, maxX = -1, maxY = -1;
        for (int y = 0; y < img.H; y++)
        for (int x = 0; x < img.W; x++)
        {
            if (img.Px[y * img.Stride + x * 4 + 3] < 16) continue;
            if (x < minX) minX = x;
            if (x > maxX) maxX = x;
            if (y < minY) minY = y;
            if (y > maxY) maxY = y;
        }
        return new int[] { minX, minY, maxX, maxY };
    }
}
'@

$root = "C:\Users\mathi\Documents\Rimworld new mods\mods\RJWAnimalTextures"
[DeerEastFix]::Build(
    (Join-Path $root "Textures\SizedApparel\BodyParts\Human\Penis"),
    (Join-Path $root "ArtInventory\Staging\DeerEast"))
