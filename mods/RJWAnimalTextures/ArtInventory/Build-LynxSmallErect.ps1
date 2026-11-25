# LynxPenis aroused sizes 0-2, south and east, rebuilt as smaller copies of the size 3 picture.
# The earlier small sprites were 49/58/66 px tall (south) and 58/60/80 (east), then size 3 jumped
# to 144 and 130, so micro to average looked alike and large looked far bigger.
# Each small size is the live size 3 sprite scaled down about its base: the bottom center of the
# opaque box on south, the bottom-left corner on east, so the base stays on the size 3 anchor.
# Shrinking keeps the drawing sharp, where enlarging the old small sprites would blur them.
# Target heights step evenly up to size 3: south 72, 96, 120 (size 3 is 144); east 70, 90, 110
# (size 3 is 130). Writes only to Staging/LynxSmallErect, plus a review sheet.
Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = "Stop"

$art = $PSScriptRoot
$horny = Join-Path (Split-Path $art) "Textures\SizedApparel\BodyParts\Human\Penis\Horny"
$out = Join-Path $art "Staging\LynxSmallErect"
New-Item -ItemType Directory -Force $out | Out-Null

$targets = @{ south = @(72, 96, 120); east = @(70, 90, 110) }

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

foreach ($dir in "south", "east") {
    $big = New-Object System.Drawing.Bitmap (Join-Path $horny "LynxPenis_3_$dir.png")
    $b = Get-Bounds $big
    $ax = if ($dir -eq "south") { $b.X + $b.Width / 2 } else { $b.X }
    $ay = $b.Bottom
    for ($size = 0; $size -le 2; $size++) {
        $s = $targets[$dir][$size] / $b.Height
        $bmp = New-Object System.Drawing.Bitmap 512, 512, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        $g.InterpolationMode = "HighQualityBicubic"
        $g.PixelOffsetMode = "HighQuality"
        $g.DrawImage($big, [single]($ax - $ax * $s), [single]($ay - $ay * $s), [single](512 * $s), [single](512 * $s))
        $g.Dispose()
        $bmp.Save((Join-Path $out "LynxPenis_${size}_$dir.png"), [System.Drawing.Imaging.ImageFormat]::Png)
        $nb = Get-Bounds $bmp
        "$dir $size  box x $($nb.X) y $($nb.Y) w $($nb.Width) h $($nb.Height) bottom $($nb.Bottom)"
        $bmp.Dispose()
    }
    "$dir 3  box x $($b.X) y $($b.Y) w $($b.Width) h $($b.Height) bottom $($b.Bottom) (live, unchanged)"
    $big.Dispose()
}

# Review sheet: top row live sizes 0-5, bottom row staged 0-2 with live 3-5, per direction.
$cell = 200
$sheet = New-Object System.Drawing.Bitmap ($cell * 6), ($cell * 4 + 40)
$g = [System.Drawing.Graphics]::FromImage($sheet)
$g.Clear([System.Drawing.Color]::FromArgb(90, 90, 90))
$font = New-Object System.Drawing.Font "Arial", 11
$row = 0
foreach ($dir in "south", "east") {
    foreach ($staged in $false, $true) {
        for ($size = 0; $size -le 5; $size++) {
            $path = if ($staged -and $size -le 2) { Join-Path $out "LynxPenis_${size}_$dir.png" } else { Join-Path $horny "LynxPenis_${size}_$dir.png" }
            $img = [System.Drawing.Image]::FromFile($path)
            $g.DrawImage($img, (New-Object System.Drawing.Rectangle ($size * $cell), ($row * $cell + 40), $cell, $cell), (New-Object System.Drawing.Rectangle 156, 40, 260, 260), [System.Drawing.GraphicsUnit]::Pixel)
            $img.Dispose()
        }
        $label = "$dir " + $(if ($staged) { "staged" } else { "live" })
        $g.DrawString($label, $font, [System.Drawing.Brushes]::White, 4, ($row * $cell + 44))
        $row++
    }
}
for ($size = 0; $size -le 5; $size++) { $g.DrawString("size $size", $font, [System.Drawing.Brushes]::White, ($size * $cell + 70), 10) }
$g.Dispose()
$sheet.Save((Join-Path $art "Staging\LynxSmallErect-review.png"), [System.Drawing.Imaging.ImageFormat]::Png)
$sheet.Dispose()
