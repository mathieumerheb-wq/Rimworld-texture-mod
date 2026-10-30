$ErrorActionPreference = "Stop"
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;

public static class LynxFit2 {
    static bool Page(Color c) {
        int min = Math.Min(c.R, Math.Min((int)c.G, (int)c.B));
        int max = Math.Max(c.R, Math.Max((int)c.G, (int)c.B));
        return c.A < 16 || (min >= 236 && (max - min) < 24);
    }
    static int Luma(Color c) { return (c.R * 299 + c.G * 587 + c.B * 114) / 1000; }
    static bool Pinkish(Color c) {
        if (c.A < 16 || c.R < 110) return false;
        float red = c.R < 1 ? 0f : (c.R - Math.Max((int)c.G, (int)c.B)) / (float)c.R;
        return red > 0.10f;
    }
    public static Bitmap Load(string path) {
        using (Bitmap source = new Bitmap(path)) {
            int w = source.Width, h = source.Height;
            Bitmap bmp = new Bitmap(w, h, PixelFormat.Format32bppArgb);
            for (int y = 0; y < h; y++)
            for (int x = 0; x < w; x++) {
                Color c = source.GetPixel(x, y);
                if (Page(c)) continue;
                int luma = Luma(c);
                if (!Pinkish(c) && luma < 232 && luma > 16)
                    c = Color.FromArgb(255, luma, luma, luma);
                else
                    c = Color.FromArgb(255, c.R, c.G, c.B);
                bmp.SetPixel(x, y, c);
            }
            int n = w * h;
            int[] id = new int[n];
            int next = 0, best = 0, bestN = 0;
            int[] qx = new int[n], qy = new int[n];
            for (int y = 0; y < h; y++)
            for (int x = 0; x < w; x++) {
                if (bmp.GetPixel(x, y).A < 16 || id[y * w + x] != 0) continue;
                next++;
                int head = 0, tail = 0, count = 0;
                qx[tail] = x; qy[tail] = y; tail++;
                id[y * w + x] = next;
                while (head < tail) {
                    int px = qx[head], py = qy[head]; head++; count++;
                    for (int oy = -1; oy <= 1; oy++)
                    for (int ox = -1; ox <= 1; ox++) {
                        int nx = px + ox, ny = py + oy;
                        if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue;
                        if (id[ny * w + nx] != 0 || bmp.GetPixel(nx, ny).A < 16) continue;
                        id[ny * w + nx] = next;
                        qx[tail] = nx; qy[tail] = ny; tail++;
                    }
                }
                if (count > bestN) { bestN = count; best = next; }
            }
            int minX = w, minY = h, maxX = 0, maxY = 0;
            for (int y = 0; y < h; y++)
            for (int x = 0; x < w; x++) {
                if (id[y * w + x] != best) continue;
                if (x < minX) minX = x; if (y < minY) minY = y;
                if (x > maxX) maxX = x; if (y > maxY) maxY = y;
            }
            Bitmap kept = new Bitmap(maxX - minX + 1, maxY - minY + 1, PixelFormat.Format32bppArgb);
            for (int y = minY; y <= maxY; y++)
            for (int x = minX; x <= maxX; x++) {
                if (id[y * w + x] != best) continue;
                kept.SetPixel(x - minX, y - minY, bmp.GetPixel(x, y));
            }
            bmp.Dispose();
            return kept;
        }
    }
    static void Axis(Bitmap src, out PointF knot, out PointF tip) {
        double sx = 0, sy = 0, sn = 0;
        for (int y = 0; y < src.Height; y++)
        for (int x = 0; x < src.Width; x++) {
            Color c = src.GetPixel(x, y);
            if (c.A < 16 || Pinkish(c)) continue;
            sx += x; sy += y; sn++;
        }
        float cx = sn > 8 ? (float)(sx / sn) : src.Width * 0.5f;
        float cy = sn > 8 ? (float)(sy / sn) : src.Height * 0.8f;
        int ax = (int)cx, ay = (int)cy;
        double near = 1e15;
        for (int y = 0; y < src.Height; y++)
        for (int x = 0; x < src.Width; x++) {
            if (!Pinkish(src.GetPixel(x, y))) continue;
            double d = (x - cx) * (x - cx) + (y - cy) * (y - cy);
            if (d < near) { near = d; ax = x; ay = y; }
        }
        int radius = Math.Max(28, Math.Max(src.Width, src.Height) / 8);
        double kx = 0, ky = 0, kn = 0;
        for (int y = Math.Max(0, ay - radius); y <= Math.Min(src.Height - 1, ay + radius); y++)
        for (int x = Math.Max(0, ax - radius); x <= Math.Min(src.Width - 1, ax + radius); x++) {
            if (!Pinkish(src.GetPixel(x, y))) continue;
            kx += x; ky += y; kn++;
        }
        if (kn < 4) { kx = ax; ky = ay; kn = 1; }
        knot = new PointF((float)(kx / kn), (float)(ky / kn));
        double far = -1;
        int tx = (int)knot.X, ty = (int)knot.Y;
        for (int y = 0; y < src.Height; y++)
        for (int x = 0; x < src.Width; x++) {
            if (!Pinkish(src.GetPixel(x, y))) continue;
            double d = (x - knot.X) * (x - knot.X) + (y - knot.Y) * (y - knot.Y);
            if (d > far) { far = d; tx = x; ty = y; }
        }
        tip = new PointF(tx, ty);
    }
    static float Angle(PointF knot, PointF tip) {
        return (float)(Math.Atan2(tip.Y - knot.Y, tip.X - knot.X) * 180.0 / Math.PI);
    }
    static Bitmap Turn(Bitmap src, float degrees, PointF pivot) {
        int side = Math.Max(src.Width, src.Height) * 2 + 32;
        Bitmap big = new Bitmap(side, side, PixelFormat.Format32bppArgb);
        int ox = (side - src.Width) / 2;
        int oy = (side - src.Height) / 2;
        using (Graphics g = Graphics.FromImage(big)) {
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
            g.PixelOffsetMode = PixelOffsetMode.HighQuality;
            g.TranslateTransform(ox + pivot.X, oy + pivot.Y);
            g.RotateTransform(degrees);
            g.TranslateTransform(-(ox + pivot.X), -(oy + pivot.Y));
            g.DrawImage(src, ox, oy);
        }
        for (int y = 0; y < side; y++)
        for (int x = 0; x < side; x++)
            if (big.GetPixel(x, y).A < 28) big.SetPixel(x, y, Color.Transparent);
        return big;
    }
    static void Bounds(Bitmap src, out int minX, out int minY, out int maxX, out int maxY) {
        minX = src.Width; minY = src.Height; maxX = -1; maxY = -1;
        for (int y = 0; y < src.Height; y++)
        for (int x = 0; x < src.Width; x++) {
            if (src.GetPixel(x, y).A < 16) continue;
            if (x < minX) minX = x; if (y < minY) minY = y;
            if (x > maxX) maxX = x; if (y > maxY) maxY = y;
        }
    }
    public static string Place(string srcPath, string dest, int targetH, bool east) {
        int oldMinX, oldMinY, oldMaxX, oldMaxY;
        using (Bitmap old = new Bitmap(dest))
            Bounds(old, out oldMinX, out oldMinY, out oldMaxX, out oldMaxY);
        int anchorX = east ? oldMinX : 256;
        int anchorBottom = oldMaxY;
        Bitmap art = Load(srcPath);
        PointF knot, tip;
        Axis(art, out knot, out tip);
        float before = Angle(knot, tip);
        float target = east ? -46f : -90f;
        float delta = target - before;
        while (delta > 180f) delta -= 360f;
        while (delta < -180f) delta += 360f;
        Bitmap turned = Turn(art, delta, knot);
        art.Dispose();
        Axis(turned, out knot, out tip);
        float after = Angle(knot, tip);
        if (east && tip.X < knot.X) {
            Bitmap flip = new Bitmap(turned.Width, turned.Height, PixelFormat.Format32bppArgb);
            using (Graphics g = Graphics.FromImage(flip)) {
                g.TranslateTransform(turned.Width, 0);
                g.ScaleTransform(-1f, 1f);
                g.DrawImage(turned, 0, 0);
            }
            turned.Dispose();
            turned = flip;
            Axis(turned, out knot, out tip);
            after = Angle(knot, tip);
        }
        int minX, minY, maxX, maxY;
        Bounds(turned, out minX, out minY, out maxX, out maxY);
        int h = maxY - minY + 1;
        int w = maxX - minX + 1;
        int newW = Math.Max(1, (int)Math.Round(w * (targetH / (double)h)));
        Bitmap scaled = new Bitmap(newW, targetH, PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(scaled)) {
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
            g.PixelOffsetMode = PixelOffsetMode.HighQuality;
            g.DrawImage(turned, new Rectangle(0, 0, newW, targetH), new Rectangle(minX, minY, w, h), GraphicsUnit.Pixel);
        }
        for (int y = 0; y < scaled.Height; y++)
        for (int x = 0; x < scaled.Width; x++)
            if (scaled.GetPixel(x, y).A < 24) scaled.SetPixel(x, y, Color.Transparent);
        int placeX = east ? anchorX : anchorX - newW / 2;
        int placeY = anchorBottom - targetH + 1;
        if (placeX < 2) placeX = 2;
        if (placeX + newW > 510) placeX = 510 - newW;
        if (placeY < 2) placeY = 2;
        Bitmap dst = new Bitmap(512, 512, PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(dst))
            g.DrawImage(scaled, placeX, placeY, newW, targetH);
        turned.Dispose();
        scaled.Dispose();
        dst.Save(dest, ImageFormat.Png);
        Bounds(dst, out minX, out minY, out maxX, out maxY);
        dst.Dispose();
        return System.IO.Path.GetFileName(dest)
            + " angle " + before.ToString("0") + " to " + after.ToString("0")
            + " h " + (maxY - minY + 1) + " w " + (maxX - minX + 1)
            + " y " + minY + "-" + maxY + " x " + minX + "-" + maxX;
    }
}
'@

$inv = "C:\Users\mathi\Documents\Rimworld new mods\mods\RJWAnimalTextures\ArtInventory\TextureV2"
$live = "C:\Users\mathi\Documents\Rimworld new mods\mods\RJWAnimalTextures\Textures\SizedApparel\BodyParts\Human\Penis\Horny"
$assets = "C:\Users\mathi\.cursor\projects\c-Users-mathi-Documents-Rimworld-new-mods\assets"

function Copy-Ref($stamp, $name) {
    $src = Get-ChildItem -LiteralPath $assets -Filter "*$stamp*" | Select-Object -First 1
    Copy-Item -LiteralPath $src.FullName -Destination (Join-Path $inv $name) -Force
}
Copy-Ref "095620" "ref-lynx-east4.png"
Copy-Ref "095532" "ref-lynx-south4.png"
Copy-Ref "095615" "ref-lynx-south5.png"

Write-Output ([LynxFit2]::Place((Join-Path $inv "ref-lynx-east3.png"), (Join-Path $live "LynxPenis_3_east.png"), 130, $true))
Write-Output ([LynxFit2]::Place((Join-Path $inv "ref-lynx-east4.png"), (Join-Path $live "LynxPenis_4_east.png"), 144, $true))
Write-Output ([LynxFit2]::Place((Join-Path $inv "ref-lynx-east5.png"), (Join-Path $live "LynxPenis_5_east.png"), 180, $true))
Write-Output ([LynxFit2]::Place((Join-Path $inv "ref-lynx-south4.png"), (Join-Path $live "LynxPenis_4_south.png"), 167, $false))
Write-Output ([LynxFit2]::Place((Join-Path $inv "ref-lynx-south5.png"), (Join-Path $live "LynxPenis_5_south.png"), 199, $false))
