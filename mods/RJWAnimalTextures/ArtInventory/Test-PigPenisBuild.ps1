# Validates the PigPenis test build and writes a HorsePenis comparison sheet.
# Reads the installed HorsePenis sprites. Does not modify them or the generated archive.
Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = "Stop"

Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @"
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.Globalization;
using System.IO;
using System.Runtime.InteropServices;

public static class PigBuildCheck
{
    public static string Measure(string path)
    {
        if (!File.Exists(path)) return "missing|0|0|missing|0|0|0|0|0";
        byte[] header = new byte[26];
        using (FileStream stream = File.OpenRead(path))
        {
            if (stream.Read(header, 0, 26) < 26) return "bad-header|0|0|bad-header|0|0|0|0|0";
        }
        int width = (header[16] << 24) | (header[17] << 16) | (header[18] << 8) | header[19];
        int height = (header[20] << 24) | (header[21] << 16) | (header[22] << 8) | header[23];
        int bitDepth = header[24];
        int colorType = header[25];
        bool png = header[0] == 137 && header[1] == 80 && header[2] == 78 && header[3] == 71;
        if (!png) return "not-png|0|0|not-png|0|0|0|0|0";

        using (Bitmap source = new Bitmap(path))
        {
            string format = source.PixelFormat.ToString();
            bool rgba = bitDepth == 8 && colorType == 6 && source.PixelFormat == PixelFormat.Format32bppArgb;
            if (width <= 4 && height <= 4)
            {
                return Join("placeholder", width, height, format, 0, rgba);
            }

            Bitmap bmp = source;
            bool disposeCopy = false;
            if (source.PixelFormat != PixelFormat.Format32bppArgb)
            {
                bmp = new Bitmap(width, height, PixelFormat.Format32bppArgb);
                using (Graphics g = Graphics.FromImage(bmp)) g.DrawImage(source, 0, 0, width, height);
                disposeCopy = true;
            }

            int visible = 0;
            BitmapData data = bmp.LockBits(new Rectangle(0, 0, width, height), ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
            try
            {
                int stride = Math.Abs(data.Stride);
                byte[] buffer = new byte[stride * height];
                Marshal.Copy(data.Scan0, buffer, 0, buffer.Length);
                for (int y = 0; y < height; y++)
                {
                    int row = y * stride;
                    for (int x = 0; x < width; x++)
                    {
                        if (buffer[row + (x * 4) + 3] >= 16) visible++;
                    }
                }
            }
            finally
            {
                bmp.UnlockBits(data);
                if (disposeCopy) bmp.Dispose();
            }

            string kind = visible > 0 ? "visible" : "empty";
            if (!rgba) kind = "bad-format";
            return Join(kind, width, height, format, visible, rgba);
        }
    }

    static string Join(string kind, int width, int height, string format, int visible, bool rgba)
    {
        return string.Join("|", new string[] {
            kind,
            width.ToString(CultureInfo.InvariantCulture),
            height.ToString(CultureInfo.InvariantCulture),
            format,
            visible.ToString(CultureInfo.InvariantCulture),
            rgba ? "rgba" : "not-rgba"
        });
    }

    public static void ContactSheet(string pigRest, string pigAroused, string horseRest, string horseAroused, string outputPath)
    {
        int cell = 220;
        int labelW = 92;
        int header = 56;
        int gap = 8;
        int cols = 2;
        int rows = 2;
        int width = 20 + labelW + cols * (cell + gap);
        int height = 20 + header + rows * (cell + gap) + 36;
        string[] files = { pigRest, horseRest, pigAroused, horseAroused };
        var bitmaps = new Bitmap[4];
        var boxes = new Rectangle[4];
        int maxDim = 1;
        for (int i = 0; i < 4; i++)
        {
            if (!File.Exists(files[i])) continue;
            bitmaps[i] = new Bitmap(files[i]);
            boxes[i] = ContentBox(bitmaps[i]);
            if (boxes[i].Width > maxDim) maxDim = boxes[i].Width;
            if (boxes[i].Height > maxDim) maxDim = boxes[i].Height;
        }
        float scale = (cell - 24f) / maxDim;

        using (Bitmap sheet = new Bitmap(width, height, PixelFormat.Format32bppArgb))
        using (Graphics g = Graphics.FromImage(sheet))
        {
            g.Clear(Color.FromArgb(255, 22, 22, 26));
            g.SmoothingMode = SmoothingMode.AntiAlias;
            g.TextRenderingHint = System.Drawing.Text.TextRenderingHint.ClearTypeGridFit;
            using (Font title = new Font("Segoe UI", 13f, FontStyle.Bold))
            using (Font small = new Font("Segoe UI", 8f))
            using (SolidBrush white = new SolidBrush(Color.FromArgb(255, 236, 232, 220)))
            using (SolidBrush muted = new SolidBrush(Color.FromArgb(255, 176, 172, 160)))
            {
                g.DrawString("PigPenis size 2 south vs HorsePenis", title, white, 14f, 8f);
                g.DrawString("Test build compared with the installed HorsePenis reference. Shared scale. Checkerboard is transparency.", small, muted, 14f, 30f);
                string[] headers = { "Rest south", "Aroused south" };
                for (int c = 0; c < cols; c++)
                {
                    RectangleF rect = new RectangleF(16 + labelW + c * (cell + gap), header - 2, cell, 18);
                    using (StringFormat fmt = new StringFormat { Alignment = StringAlignment.Center })
                        g.DrawString(headers[c], small, white, rect, fmt);
                }
                string[] rowLabels = { "PigPenis", "HorsePenis" };
                for (int r = 0; r < rows; r++)
                {
                    int y = header + 16 + r * (cell + gap);
                    g.DrawString(rowLabels[r], small, white, 12f, y + cell * 0.45f);
                    for (int c = 0; c < cols; c++)
                    {
                        int index = c == 0 ? r : r + 2;
                        int x = 16 + labelW + c * (cell + gap);
                        DrawCell(g, bitmaps[index], boxes[index], new Rectangle(x, y, cell, cell), scale, small, white);
                    }
                }
                g.DrawString("Size index 2 only. East, north, and other sizes are not in the test build.", small, muted, 14f, height - 24);
            }
            sheet.Save(outputPath, ImageFormat.Png);
        }

        for (int i = 0; i < bitmaps.Length; i++)
        {
            if (bitmaps[i] != null) bitmaps[i].Dispose();
        }
    }

    static Rectangle ContentBox(Bitmap sprite)
    {
        int minX = sprite.Width, minY = sprite.Height, maxX = -1, maxY = -1;
        BitmapData data = sprite.LockBits(new Rectangle(0, 0, sprite.Width, sprite.Height), ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
        try
        {
            int stride = Math.Abs(data.Stride);
            byte[] buffer = new byte[stride * sprite.Height];
            Marshal.Copy(data.Scan0, buffer, 0, buffer.Length);
            for (int y = 0; y < sprite.Height; y++)
            {
                int row = y * stride;
                for (int x = 0; x < sprite.Width; x++)
                {
                    if (buffer[row + (x * 4) + 3] < 16) continue;
                    if (x < minX) minX = x;
                    if (y < minY) minY = y;
                    if (x > maxX) maxX = x;
                    if (y > maxY) maxY = y;
                }
            }
        }
        finally
        {
            sprite.UnlockBits(data);
        }
        if (maxX < 0) return Rectangle.Empty;
        return new Rectangle(minX, minY, maxX - minX + 1, maxY - minY + 1);
    }

    static void DrawCell(Graphics g, Bitmap sprite, Rectangle box, Rectangle cell, float scale, Font font, Brush brush)
    {
        using (SolidBrush dark = new SolidBrush(Color.FromArgb(255, 46, 46, 50)))
        using (SolidBrush lite = new SolidBrush(Color.FromArgb(255, 68, 68, 74)))
        {
            for (int y = 0; y < cell.Height; y += 8)
            for (int x = 0; x < cell.Width; x += 8)
            {
                bool alt = ((x / 8) + (y / 8)) % 2 == 0;
                g.FillRectangle(alt ? dark : lite, cell.X + x, cell.Y + y, 8, 8);
            }
        }
        if (sprite == null || box.Width <= 0 || box.Height <= 0)
        {
            g.DrawString("missing", font, brush, cell.X + 16f, cell.Y + cell.Height * 0.45f);
            return;
        }
        int dw = Math.Max(1, (int)Math.Round(box.Width * scale));
        int dh = Math.Max(1, (int)Math.Round(box.Height * scale));
        int dx = cell.X + (cell.Width - dw) / 2;
        int dy = cell.Y + (cell.Height - dh) / 2;
        g.InterpolationMode = InterpolationMode.HighQualityBicubic;
        g.DrawImage(sprite, new Rectangle(dx, dy, dw, dh), box, GraphicsUnit.Pixel);
    }
}
"@

$modRoot = Split-Path $PSScriptRoot -Parent
$penis = Join-Path $modRoot "Textures\SizedApparel\BodyParts\Human\Penis"
$horseRoot = "C:\Program Files (x86)\Steam\steamapps\common\RimWorld\Mods\sized-apparel-zero\Textures\SizedApparel\BodyParts\Human\Penis"
$reportPath = Join-Path $PSScriptRoot "test-build-validation.csv"
$sheetPath = Join-Path $PSScriptRoot "contact-test-build-pig-vs-horse.png"

$rows = New-Object System.Collections.Generic.List[object]
$failed = $false
$expected = @{}

function Add-Row($role, $state, $size, $direction, $relative, $status, $width, $height, $format, $visible, $notes) {
    $rows.Add([pscustomobject]@{
        Role = $role
        State = $state
        Size = $size
        Direction = $direction
        RelativePath = $relative
        Status = $status
        Width = $width
        Height = $height
        PixelFormat = $format
        VisiblePixels = $visible
        Notes = $notes
    })
}

function Add-Expected($state, $size, $direction, $relative, $blankNorth) {
    $script:expected[$relative.ToLowerInvariant()] = $true
    $path = Join-Path $penis $relative
    $parts = ([PigBuildCheck]::Measure($path)).Split("|")
    $kind = $parts[0]
    $width = [int]$parts[1]
    $height = [int]$parts[2]
    $format = $parts[3]
    $visible = [int]$parts[4]
    $rgba = $parts[5]
    $status = "OK"
    $notes = "Included sprite"
    if ($kind -eq "missing") {
        $status = "Missing"
        $notes = "Expected file is absent"
        $script:failed = $true
    }
    elseif ($kind -eq "placeholder" -and $blankNorth) {
        $status = "Placeholder"
        $notes = "Blank 4x4 north, same role as HorsePenis"
    }
    elseif ($kind -eq "placeholder") {
        $status = "Placeholder"
        $notes = "4x4 placeholder is not valid artwork here"
        $script:failed = $true
    }
    elseif ($kind -eq "empty") {
        $status = "Empty"
        $notes = "No visible pixels"
        $script:failed = $true
    }
    elseif ($kind -eq "bad-format" -or $rgba -ne "rgba") {
        $status = "BadFormat"
        $notes = "Expected 8-bit RGBA PNG"
        $script:failed = $true
    }
    elseif ($width -ne 512 -or $height -ne 512) {
        $status = "BadSize"
        $notes = "Expected 512x512"
        $script:failed = $true
    }
    Add-Row "TestBuild" $state $size $direction $relative $status $width $height $format $visible $notes
}

foreach ($state in @("Rest", "Aroused")) {
    foreach ($size in 0..5) {
        foreach ($direction in @("south", "east", "north")) {
            $relative = "PigPenis_${size}_${direction}.png"
            if ($state -eq "Aroused") { $relative = "Horny\$relative" }
            Add-Expected $state $size $direction $relative ($direction -eq "north")
        }
    }
}
foreach ($size in 0..5) {
    foreach ($direction in @("south", "east", "north")) {
        $relative = "Balls\PigPenis_${size}_${direction}.png"
        Add-Expected "Balls" $size $direction $relative $false
    }
}

Get-ChildItem $penis -Recurse -Filter *.png -ErrorAction SilentlyContinue | ForEach-Object {
    $relative = $_.FullName.Substring($penis.Length).TrimStart("\")
    if (-not $expected.ContainsKey($relative.ToLowerInvariant())) {
        $parts = ([PigBuildCheck]::Measure($_.FullName)).Split("|")
        Add-Row "ExtraFile" "" "" "" $relative "Unexpected" $parts[1] $parts[2] $parts[3] $parts[4] "PNG is outside the PigPenis set"
        $script:failed = $true
    }
}

$rows | Export-Csv -Path $reportPath -NoTypeInformation -Encoding UTF8

$pigRest = Join-Path $penis "PigPenis_2_south.png"
$pigAroused = Join-Path $penis "Horny\PigPenis_2_south.png"
$horseRest = Join-Path $horseRoot "HorsePenis_2_south.png"
$horseAroused = Join-Path $horseRoot "Horny\HorsePenis_2_south.png"
[PigBuildCheck]::ContactSheet($pigRest, $pigAroused, $horseRest, $horseAroused, $sheetPath)

$okCount = @($rows | Where-Object { $_.Status -eq "OK" }).Count
$missingCount = @($rows | Where-Object { $_.Status -eq "Missing" }).Count
$placeholderCount = @($rows | Where-Object { $_.Status -eq "Placeholder" }).Count
Write-Host "REPORT $reportPath"
Write-Host "SHEET $sheetPath"
Write-Host ("TEST {0}" -f ($(if ($failed) { "FAIL" } else { "PASS" })))
Write-Host "OK $okCount"
Write-Host "MISSING $missingCount"
Write-Host "PLACEHOLDER $placeholderCount"
$rows | Where-Object { $_.Status -ne "OK" -and $_.Status -ne "Placeholder" } | ForEach-Object {
    Write-Host ("{0} {1}" -f $_.Status, $_.RelativePath)
}
if ($failed) { exit 1 }
