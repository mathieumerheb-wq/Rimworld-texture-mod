# Aroused sizes 0-2, south and east, rebuilt as smaller copies of each hediff's own size 3 picture.
# Same method as Build-LynxSmallErect.ps1, for every hediff that still followed the dragon aroused
# ladder (south 46/57/67 then 144, east 59/62/81 then 130): micro to average looked alike and tiny,
# and large looked more than twice as big as average.
# Each small size is the live size 3 sprite scaled down about its base: the bottom center of the
# opaque box on south, the bottom-left corner on east, so the base stays on the size 3 anchor.
# Target heights step evenly up to size 3: south 72, 96, 120 (size 3 is ~144); east 70, 90, 110
# (size 3 is ~130). Heights are scaled from the measured size 3 height, so a hediff whose size 3
# differs keeps the same proportions.
# Writes only to Staging/SmallErect/<hediff>, plus one review sheet per hediff and an overview.
param([string[]]$Hediffs = @("BovinePenis", "CloacalPenis", "CrocodilianPenis", "DemonTentaclePenis",
    "ElfPenis", "HemiPenis", "NeedlePenis", "PigPenis", "RabbitPenis", "RaccoonPenis", "WolfPenis"))
Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = "Stop"

$art = $PSScriptRoot
$horny = Join-Path (Split-Path $art) "Textures\SizedApparel\BodyParts\Human\Penis\Horny"
$root = Join-Path $art "Staging\SmallErect"
New-Item -ItemType Directory -Force $root | Out-Null

# Fractions of the size 3 height: 72/144, 96/144, 120/144 south; 70/130, 90/130, 110/130 east.
$fractions = @{ south = @(0.5, 0.6667, 0.8333); east = @(0.5385, 0.6923, 0.8462) }

function Get-Bounds($bmp) {
    $minX = $bmp.Width; $minY = $bmp.Height; $maxX = -1; $maxY = -1
    for ($y = 0; $y -lt $bmp.Height; $y++) {
        for ($x = 0; $x -lt $bmp.Width; $x++) {
            if ($bmp.GetPixel($x, $y).A -gt 32) {
                if ($x -lt $minX) { $minX = $x }
                if ($x -gt $maxX) { $maxX = $x }
                if ($y -lt $minY) { $minY = $y }
                if ($y -gt $maxY) { $maxY = $y }
            }
        }
    }
    return New-Object System.Drawing.Rectangle $minX, $minY, ($maxX - $minX + 1), ($maxY - $minY + 1)
}

function Draw-Cell($g, $path, $cx, $cy, $cell) {
    $img = [System.Drawing.Image]::FromFile($path)
    $g.DrawImage($img, (New-Object System.Drawing.Rectangle $cx, $cy, $cell, $cell), (New-Object System.Drawing.Rectangle 136, 40, 280, 280), [System.Drawing.GraphicsUnit]::Pixel)
    $img.Dispose()
}

$font = New-Object System.Drawing.Font "Arial", 11
foreach ($hediff in $Hediffs) {
    $out = Join-Path $root $hediff
    New-Item -ItemType Directory -Force $out | Out-Null
    foreach ($dir in "south", "east") {
        $big = New-Object System.Drawing.Bitmap (Join-Path $horny "${hediff}_3_$dir.png")
        $b = Get-Bounds $big
        $ax = if ($dir -eq "south") { $b.X + $b.Width / 2 } else { $b.X }
        $ay = $b.Bottom
        for ($size = 0; $size -le 2; $size++) {
            $s = $fractions[$dir][$size]
            $bmp = New-Object System.Drawing.Bitmap 512, 512, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
            $g = [System.Drawing.Graphics]::FromImage($bmp)
            $g.InterpolationMode = "HighQualityBicubic"
            $g.PixelOffsetMode = "HighQuality"
            $g.DrawImage($big, [single]($ax - $ax * $s), [single]($ay - $ay * $s), [single](512 * $s), [single](512 * $s))
            $g.Dispose()
            $bmp.Save((Join-Path $out "${hediff}_${size}_$dir.png"), [System.Drawing.Imaging.ImageFormat]::Png)
            $nb = Get-Bounds $bmp
            "$hediff $dir $size  box x $($nb.X) y $($nb.Y) w $($nb.Width) h $($nb.Height) bottom $($nb.Bottom)"
            $bmp.Dispose()
        }
        "$hediff $dir 3  box x $($b.X) y $($b.Y) w $($b.Width) h $($b.Height) bottom $($b.Bottom) (live, unchanged)"
        $big.Dispose()
    }

    # Per-hediff sheet: live sizes 0-5, then staged 0-2 with live 3-5, per direction.
    $cell = 180
    $sheet = New-Object System.Drawing.Bitmap ($cell * 6), ($cell * 4 + 30)
    $g = [System.Drawing.Graphics]::FromImage($sheet)
    $g.Clear([System.Drawing.Color]::FromArgb(90, 90, 90))
    $row = 0
    foreach ($dir in "south", "east") {
        foreach ($staged in $false, $true) {
            for ($size = 0; $size -le 5; $size++) {
                $path = if ($staged -and $size -le 2) { Join-Path $out "${hediff}_${size}_$dir.png" } else { Join-Path $horny "${hediff}_${size}_$dir.png" }
                Draw-Cell $g $path ($size * $cell) ($row * $cell + 30) $cell
            }
            $g.DrawString("$dir " + $(if ($staged) { "new" } else { "live" }), $font, [System.Drawing.Brushes]::White, 4, ($row * $cell + 34))
            $row++
        }
    }
    for ($size = 0; $size -le 5; $size++) { $g.DrawString("$hediff size $size", $font, [System.Drawing.Brushes]::White, ($size * $cell + 10), 6) }
    $g.Dispose()
    $sheet.Save((Join-Path $root "$hediff-review.png"), [System.Drawing.Imaging.ImageFormat]::Png)
    $sheet.Dispose()
}

# Overview: every hediff, new ladder only (staged 0-2 + live 3-5), south then east.
$cell = 110
$label = 150
$sheet = New-Object System.Drawing.Bitmap ($label + $cell * 12), ($cell * $Hediffs.Count + 24)
$g = [System.Drawing.Graphics]::FromImage($sheet)
$g.Clear([System.Drawing.Color]::FromArgb(90, 90, 90))
for ($i = 0; $i -lt $Hediffs.Count; $i++) {
    $hediff = $Hediffs[$i]
    $col = 0
    foreach ($dir in "south", "east") {
        for ($size = 0; $size -le 5; $size++) {
            $path = if ($size -le 2) { Join-Path $root "$hediff\${hediff}_${size}_$dir.png" } else { Join-Path $horny "${hediff}_${size}_$dir.png" }
            Draw-Cell $g $path ($label + $col * $cell) ($i * $cell + 24) $cell
            $col++
        }
    }
    $g.DrawString($hediff, $font, [System.Drawing.Brushes]::White, 4, ($i * $cell + 24 + $cell / 2 - 8))
}
for ($c = 0; $c -lt 12; $c++) {
    $dir = if ($c -lt 6) { "S" } else { "E" }
    $g.DrawString("$dir$($c % 6)", $font, [System.Drawing.Brushes]::White, ($label + $c * $cell + 40), 4)
}
$g.Dispose()
$sheet.Save((Join-Path $root "Overview-review.png"), [System.Drawing.Imaging.ImageFormat]::Png)
$sheet.Dispose()
