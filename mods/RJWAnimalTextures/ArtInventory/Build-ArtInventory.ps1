# Read-only inventory of Sized Apparel penis textures.
# Does not modify installed mods or original images.
Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = "Stop"

Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @"
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

public static class PenisTextureStats
{
    public static string Measure(string path)
    {
        using (Bitmap source = new Bitmap(path))
        {
            int width = source.Width;
            int height = source.Height;
            string format = source.PixelFormat.ToString();
            if (width <= 4 && height <= 4)
            {
                return string.Join("|", new string[] {
                    "placeholder", width.ToString(), height.ToString(), format,
                    "0", (width * height).ToString(), "100",
                    "0", "0", "0", "0", "0"
                });
            }

            Bitmap bmp = source;
            bool disposeCopy = false;
            if (source.PixelFormat != PixelFormat.Format32bppArgb)
            {
                bmp = new Bitmap(width, height, PixelFormat.Format32bppArgb);
                using (Graphics g = Graphics.FromImage(bmp))
                {
                    g.DrawImage(source, 0, 0, width, height);
                }
                disposeCopy = true;
            }

            int opaque = 0;
            int maxDelta = 0;
            int minX = width, minY = height, maxX = -1, maxY = -1;
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
                        int i = row + (x * 4);
                        byte a = buffer[i + 3];
                        if (a > 0) opaque++;
                        if (a >= 16)
                        {
                            if (x < minX) minX = x;
                            if (y < minY) minY = y;
                            if (x > maxX) maxX = x;
                            if (y > maxY) maxY = y;
                            int b = buffer[i];
                            int g = buffer[i + 1];
                            int r = buffer[i + 2];
                            int delta = Math.Max(Math.Abs(r - g), Math.Max(Math.Abs(g - b), Math.Abs(r - b)));
                            if (delta > maxDelta) maxDelta = delta;
                        }
                    }
                }
            }
            finally
            {
                bmp.UnlockBits(data);
                if (disposeCopy) bmp.Dispose();
            }

            int total = width * height;
            double transparent = Math.Round(100.0 * (total - opaque) / total, 2);
            string klass = "empty";
            int cx = 0, cy = 0, cw = 0, ch = 0;
            if (maxX >= 0)
            {
                klass = "usable";
                cx = minX;
                cy = minY;
                cw = maxX - minX + 1;
                ch = maxY - minY + 1;
            }
            return string.Join("|", new string[] {
                klass, width.ToString(), height.ToString(), format,
                opaque.ToString(), total.ToString(), transparent.ToString(System.Globalization.CultureInfo.InvariantCulture),
                cx.ToString(), cy.ToString(), cw.ToString(), ch.ToString(), maxDelta.ToString()
            });
        }
    }
}
"@

$SourceRoot = "C:\Program Files (x86)\Steam\steamapps\common\RimWorld\Mods\sized-apparel-zero\Textures\SizedApparel\BodyParts\Human\Penis"
$OutDir = "C:\Users\mathi\Documents\Rimworld new mods\mods\RJWAnimalTextures\ArtInventory"
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

$Targets = @(
    @{ Name = "HorsePenis"; Variation = "" },
    @{ Name = "DogPenis"; Variation = "RNW" },
    @{ Name = "CatPenis"; Variation = "RNW" },
    @{ Name = "DragonPenis"; Variation = "RNW" },
    @{ Name = "SlimeTentacles"; Variation = "RNW" },
    @{ Name = "OvipositorM"; Variation = "RNW" },
    @{ Name = "OrcPenis"; Variation = "" },
    @{ Name = "PigPenis"; Variation = "" }
)
$Sizes = 0..5
$Directions = @("south", "east", "north")
$Slots = @(
    @{ Part = "Penis"; State = "Rest"; Folder = "" },
    @{ Part = "Penis"; State = "Aroused"; Folder = "Horny" },
    @{ Part = "Balls"; State = "Rest"; Folder = "Balls" },
    @{ Part = "Balls"; State = "Aroused"; Folder = "Balls\Horny" }
)

function Get-ExpectedFileName([string]$Name, [int]$Index, [string]$Variation, [string]$Direction) {
    if ([string]::IsNullOrEmpty($Variation)) {
        return "{0}_{1}_{2}.png" -f $Name, $Index, $Direction
    }
    return "{0}_{1}_{2}_{3}.png" -f $Name, $Index, $Variation, $Direction
}

function Get-ImageStats([string]$Path) {
    $parts = ([PenisTextureStats]::Measure($Path)) -split '\|'
    return [pscustomobject]@{
        Class = $parts[0]
        Width = [int]$parts[1]
        Height = [int]$parts[2]
        PixelFormat = $parts[3]
        OpaquePixels = [int]$parts[4]
        TotalPixels = [int]$parts[5]
        TransparentPercent = [double]::Parse($parts[6], [System.Globalization.CultureInfo]::InvariantCulture)
        ContentX = [int]$parts[7]
        ContentY = [int]$parts[8]
        ContentWidth = [int]$parts[9]
        ContentHeight = [int]$parts[10]
        MaxChannelDelta = [int]$parts[11]
    }
}

function New-CheckerBrush {
    $tile = New-Object System.Drawing.Bitmap 16, 16
    $g = [System.Drawing.Graphics]::FromImage($tile)
    $dark = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 46, 46, 50))
    $lite = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 68, 68, 74))
    $g.FillRectangle($dark, 0, 0, 16, 16)
    $g.FillRectangle($lite, 0, 0, 8, 8)
    $g.FillRectangle($lite, 8, 8, 8, 8)
    $g.Dispose()
    $dark.Dispose()
    $lite.Dispose()
    $brush = New-Object System.Drawing.TextureBrush $tile
    return @{ Brush = $brush; Tile = $tile }
}

function Draw-SpriteCell {
    param($Graphics, $Bounds, $Record, $Font, $SmallFont)
    $missingBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 58, 34, 34))
    $placeholderBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 62, 48, 24))
    $emptyBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 36, 36, 40))
    $textBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 230, 226, 214))
    $dimBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 180, 176, 164))
    $format = New-Object System.Drawing.StringFormat
    $format.Alignment = [System.Drawing.StringAlignment]::Center
    $format.LineAlignment = [System.Drawing.StringAlignment]::Center

    $textRect = New-Object System.Drawing.RectangleF $Bounds.X, $Bounds.Y, $Bounds.Width, $Bounds.Height
    if ($Record.Status -eq "missing") {
        $Graphics.FillRectangle($missingBrush, $Bounds)
        $Graphics.DrawString("missing", $Font, $textBrush, $textRect, $format)
    }
    elseif ($Record.Status -eq "placeholder") {
        $Graphics.FillRectangle($placeholderBrush, $Bounds)
        $label = "4x4 placeholder`n$($Record.Width)x$($Record.Height)"
        $Graphics.DrawString($label, $SmallFont, $textBrush, $textRect, $format)
    }
    elseif ($Record.Status -eq "empty") {
        $Graphics.FillRectangle($emptyBrush, $Bounds)
        $Graphics.DrawString("empty $($Record.Width)x$($Record.Height)", $SmallFont, $textBrush, $textRect, $format)
    }
    else {
        $checker = New-CheckerBrush
        $Graphics.FillRectangle($checker.Brush, $Bounds)
        $checker.Brush.Dispose()
        $checker.Tile.Dispose()

        $src = [System.Drawing.Bitmap]::FromFile($Record.FullName)
        try {
            $sx = [int]$Record.ContentX
            $sy = [int]$Record.ContentY
            $sw = [int]$Record.ContentWidth
            $sh = [int]$Record.ContentHeight
            $pad = 4
            $innerW = $Bounds.Width - ($pad * 2)
            $innerH = $Bounds.Height - ($pad * 2) - 14
            $scale = [Math]::Min($innerW / $sw, $innerH / $sh)
            $dw = [Math]::Max(1, [int]($sw * $scale))
            $dh = [Math]::Max(1, [int]($sh * $scale))
            $dx = $Bounds.X + [int](($Bounds.Width - $dw) / 2)
            $dy = $Bounds.Y + $pad + [int](($innerH - $dh) / 2)
            $dest = New-Object System.Drawing.Rectangle $dx, $dy, $dw, $dh
            $srcRect = New-Object System.Drawing.Rectangle $sx, $sy, $sw, $sh
            $Graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $Graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
            $Graphics.DrawImage($src, $dest, $srcRect, [System.Drawing.GraphicsUnit]::Pixel)
        }
        finally {
            $src.Dispose()
        }
        $caption = "{0}x{1}  art {2}x{3}" -f $Record.Width, $Record.Height, $Record.ContentWidth, $Record.ContentHeight
        $capRect = New-Object System.Drawing.RectangleF $Bounds.X, ($Bounds.Bottom - 14), $Bounds.Width, 14
        $Graphics.DrawString($caption, $SmallFont, $dimBrush, $capRect, $format)
    }

    $missingBrush.Dispose()
    $placeholderBrush.Dispose()
    $emptyBrush.Dispose()
    $textBrush.Dispose()
    $dimBrush.Dispose()
    $format.Dispose()
}

function Save-ContactSheet {
    param($Title, $Subtitle, $RowLabels, $ColLabels, $Cells, $OutPath)
    $margin = 12
    $headerH = 54
    $colHeadH = 28
    $rowHeadW = 132
    $cell = 132
    $gap = 4
    $footer = 22
    $cols = $ColLabels.Count
    $rows = $RowLabels.Count
    $width = $margin + $rowHeadW + ($cols * ($cell + $gap)) + $margin
    $height = $margin + $headerH + $colHeadH + ($rows * ($cell + $gap)) + $footer + $margin
    $sheet = New-Object System.Drawing.Bitmap $width, $height
    $g = [System.Drawing.Graphics]::FromImage($sheet)
    $g.Clear([System.Drawing.Color]::FromArgb(255, 22, 22, 26))
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit
    $titleFont = New-Object System.Drawing.Font "Segoe UI", 13, ([System.Drawing.FontStyle]::Bold)
    $subFont = New-Object System.Drawing.Font "Segoe UI", 8
    $labelFont = New-Object System.Drawing.Font "Segoe UI", 8
    $cellFont = New-Object System.Drawing.Font "Segoe UI", 8
    $white = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 236, 232, 220))
    $muted = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 176, 172, 160))
    $center = New-Object System.Drawing.StringFormat
    $center.Alignment = [System.Drawing.StringAlignment]::Center
    $center.LineAlignment = [System.Drawing.StringAlignment]::Center

    $g.DrawString($Title, $titleFont, $white, 16, 10)
    $g.DrawString($Subtitle, $subFont, $muted, 16, 32)

    for ($c = 0; $c -lt $cols; $c++) {
        $x = $margin + $rowHeadW + ($c * ($cell + $gap))
        $rect = New-Object System.Drawing.RectangleF $x, ($margin + $headerH), $cell, $colHeadH
        $g.DrawString($ColLabels[$c], $labelFont, $white, $rect, $center)
    }
    for ($r = 0; $r -lt $rows; $r++) {
        $y = $margin + $headerH + $colHeadH + ($r * ($cell + $gap))
        $rect = New-Object System.Drawing.RectangleF $margin, $y, ($rowHeadW - 4), $cell
        $g.DrawString($RowLabels[$r], $labelFont, $white, $rect, $center)
        for ($c = 0; $c -lt $cols; $c++) {
            $x = $margin + $rowHeadW + ($c * ($cell + $gap))
            $bounds = New-Object System.Drawing.Rectangle $x, $y, $cell, $cell
            Draw-SpriteCell -Graphics $g -Bounds $bounds -Record $Cells[$r][$c] -Font $cellFont -SmallFont $subFont
        }
    }
    $g.DrawString("Existing Sized Apparel files only. Cropped to opaque pixels, aspect ratio preserved. Originals were not modified.", $subFont, $muted, 16, ($height - 24))

    $sheet.Save($OutPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $center.Dispose(); $white.Dispose(); $muted.Dispose()
    $titleFont.Dispose(); $subFont.Dispose(); $labelFont.Dispose(); $cellFont.Dispose()
    $g.Dispose(); $sheet.Dispose()
}

Write-Host "Scanning $SourceRoot"
$records = New-Object System.Collections.Generic.List[object]
$lookup = @{}

foreach ($target in $Targets) {
    foreach ($slot in $Slots) {
        foreach ($size in $Sizes) {
            foreach ($dir in $Directions) {
                $fileName = Get-ExpectedFileName $target.Name $size $target.Variation $dir
                $full = if ([string]::IsNullOrEmpty($slot.Folder)) {
                    Join-Path $SourceRoot $fileName
                } else {
                    Join-Path (Join-Path $SourceRoot $slot.Folder) $fileName
                }
                $status = "missing"
                $stats = $null
                $hash = ""
                if (Test-Path -LiteralPath $full) {
                    $stats = Get-ImageStats $full
                    $status = $stats.Class
                    $hash = (Get-FileHash -LiteralPath $full -Algorithm MD5).Hash
                }
                $row = [pscustomobject]@{
                    Hediff = $target.Name
                    Variation = $target.Variation
                    Part = $slot.Part
                    State = $slot.State
                    Size = $size
                    Direction = $dir
                    Status = $status
                    FileName = $fileName
                    FullName = $(if ($status -eq "missing") { "" } else { $full })
                    Width = $(if ($stats) { $stats.Width } else { "" })
                    Height = $(if ($stats) { $stats.Height } else { "" })
                    PixelFormat = $(if ($stats) { $stats.PixelFormat } else { "" })
                    OpaquePixels = $(if ($stats) { $stats.OpaquePixels } else { "" })
                    TransparentPercent = $(if ($stats) { $stats.TransparentPercent } else { "" })
                    ContentX = $(if ($stats) { $stats.ContentX } else { "" })
                    ContentY = $(if ($stats) { $stats.ContentY } else { "" })
                    ContentWidth = $(if ($stats) { $stats.ContentWidth } else { "" })
                    ContentHeight = $(if ($stats) { $stats.ContentHeight } else { "" })
                    MaxChannelDelta = $(if ($stats) { $stats.MaxChannelDelta } else { "" })
                    MD5 = $hash
                }
                $records.Add($row)
                $lookup["$($target.Name)|$($slot.Part)|$($slot.State)|$size|$dir"] = $row
            }
        }
    }
}

# Files present for these hediffs that are outside the expected matrix.
$expectedNames = @{}
foreach ($row in $records) {
    if ($row.FullName) { $expectedNames[$row.FullName.ToLowerInvariant()] = $true }
}
$extra = New-Object System.Collections.Generic.List[object]
Get-ChildItem -LiteralPath $SourceRoot -Recurse -File -Filter *.png | ForEach-Object {
    $base = $_.BaseName
    $matched = $false
    foreach ($target in $Targets) {
        if ($base.StartsWith($target.Name + "_")) { $matched = $true; break }
    }
    if (-not $matched) { return }
    if ($expectedNames.ContainsKey($_.FullName.ToLowerInvariant())) { return }
    $stats = Get-ImageStats $_.FullName
    $extra.Add([pscustomobject]@{
        RelativePath = $_.FullName.Substring($SourceRoot.Length + 1)
        Width = $stats.Width
        Height = $stats.Height
        Class = $stats.Class
        TransparentPercent = $stats.TransparentPercent
        ContentWidth = $stats.ContentWidth
        ContentHeight = $stats.ContentHeight
    })
}

$inventoryPath = Join-Path $OutDir "penis-texture-inventory.csv"
$invariant = [System.Globalization.CultureInfo]::InvariantCulture
$exportRows = foreach ($row in $records) {
    $copy = $row.PSObject.Copy()
    if ($copy.TransparentPercent -ne "") {
        $copy.TransparentPercent = [string]::Format($invariant, "{0:0.00}", [double]$copy.TransparentPercent)
    }
    $copy
}
$exportRows | Export-Csv -LiteralPath $inventoryPath -NoTypeInformation -Encoding UTF8
$extraPath = Join-Path $OutDir "unexpected-penis-files.csv"
$extra | Export-Csv -LiteralPath $extraPath -NoTypeInformation -Encoding UTF8

$colLabels = @(
    "Rest south", "Rest east", "Rest north",
    "Aroused south", "Aroused east", "Aroused north"
)
$colKeys = @(
    @{ State = "Rest"; Direction = "south" },
    @{ State = "Rest"; Direction = "east" },
    @{ State = "Rest"; Direction = "north" },
    @{ State = "Aroused"; Direction = "south" },
    @{ State = "Aroused"; Direction = "east" },
    @{ State = "Aroused"; Direction = "north" }
)

$sheetPaths = New-Object System.Collections.Generic.List[string]
foreach ($target in $Targets) {
    $hasUsable = $false
    foreach ($row in $records) {
        if ($row.Hediff -eq $target.Name -and $row.Part -eq "Penis" -and $row.Status -eq "usable") { $hasUsable = $true; break }
    }
    if (-not $hasUsable) { continue }

    $varNote = if ([string]::IsNullOrEmpty($target.Variation)) { "no variation suffix" } else { "variation suffix _$($target.Variation)" }
    $rowLabels = @()
    $cells = @()
    foreach ($size in $Sizes) {
        $rowLabels += "size $size"
        $rowCells = @()
        foreach ($key in $colKeys) {
            $rowCells += $lookup["$($target.Name)|Penis|$($key.State)|$size|$($key.Direction)"]
        }
        $cells += , $rowCells
    }
    $out = Join-Path $OutDir ("contact-{0}-penis.png" -f $target.Name)
    Save-ContactSheet -Title "$($target.Name) penis reference" -Subtitle "Sized Apparel Human/Penis. $varNote. Checkerboard is transparency." -RowLabels $rowLabels -ColLabels $colLabels -Cells $cells -OutPath $out
    $sheetPaths.Add($out)

    $hasBalls = $false
    foreach ($row in $records) {
        if ($row.Hediff -eq $target.Name -and $row.Part -eq "Balls" -and $row.Status -ne "missing") { $hasBalls = $true; break }
    }
    if ($hasBalls) {
        $ballCells = @()
        foreach ($size in $Sizes) {
            $rowCells = @()
            foreach ($key in $colKeys) {
                $rowCells += $lookup["$($target.Name)|Balls|$($key.State)|$size|$($key.Direction)"]
            }
            $ballCells += , $rowCells
        }
        $ballOut = Join-Path $OutDir ("contact-{0}-balls.png" -f $target.Name)
        Save-ContactSheet -Title "$($target.Name) balls reference" -Subtitle "Sized Apparel Human/Penis/Balls. Aroused lookup falls back to resting balls when Horny files are absent." -RowLabels $rowLabels -ColLabels $colLabels -Cells $ballCells -OutPath $ballOut
        $sheetPaths.Add($ballOut)
    }
}

# Side-by-side style reference: south views at sizes 0, 2, and 5.
$styleCols = @(
    @{ State = "Rest"; Size = 0; Label = "Rest s0" },
    @{ State = "Rest"; Size = 2; Label = "Rest s2" },
    @{ State = "Rest"; Size = 5; Label = "Rest s5" },
    @{ State = "Aroused"; Size = 0; Label = "Aroused s0" },
    @{ State = "Aroused"; Size = 2; Label = "Aroused s2" },
    @{ State = "Aroused"; Size = 5; Label = "Aroused s5" }
)
$styleLabels = @()
$styleCells = @()
foreach ($target in $Targets) {
    $any = $false
    foreach ($col in $styleCols) {
        $rec = $lookup["$($target.Name)|Penis|$($col.State)|$($col.Size)|south"]
        if ($rec.Status -eq "usable") { $any = $true }
    }
    if (-not $any) { continue }
    $styleLabels += $target.Name
    $rowCells = @()
    foreach ($col in $styleCols) {
        $rowCells += $lookup["$($target.Name)|Penis|$($col.State)|$($col.Size)|south"]
    }
    $styleCells += , $rowCells
}
$stylePath = Join-Path $OutDir "contact-style-reference-south.png"
if ($styleLabels.Count -gt 0) {
    Save-ContactSheet -Title "South-view style reference" -Subtitle "Usable or placeholder south sprites at sizes 0, 2, and 5. PigPenis is omitted because no files exist." -RowLabels $styleLabels -ColLabels @($styleCols.Label) -Cells $styleCells -OutPath $stylePath
    $sheetPaths.Add($stylePath)
}

Write-Host "INVENTORY $inventoryPath"
Write-Host "EXTRA $extraPath count=$($extra.Count)"
Write-Host "SHEETS $($sheetPaths.Count)"
$sheetPaths | ForEach-Object { Write-Host $_ }

# Compact coverage lines for the report.
Write-Host "=== COVERAGE ==="
foreach ($target in $Targets) {
    foreach ($part in @("Penis", "Balls")) {
        foreach ($state in @("Rest", "Aroused")) {
            $parts = @()
            foreach ($size in $Sizes) {
                $flags = @()
                foreach ($dir in $Directions) {
                    $rec = $lookup["$($target.Name)|$part|$state|$size|$dir"]
                    $mark = switch ($rec.Status) {
                        "usable" { "U" }
                        "placeholder" { "P" }
                        "empty" { "E" }
                        default { "-" }
                    }
                    $flags += $mark
                }
                $parts += ("{0}:{1}" -f $size, ($flags -join ""))
            }
            Write-Host ("{0} {1} {2}  {3}" -f $target.Name, $part, $state, ($parts -join " "))
        }
    }
}
