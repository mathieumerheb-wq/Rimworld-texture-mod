# Gene icons that show the penis the gene draws in game, and whether that sprite is finished.
# Reads GeneIcons.csv (gene,penis). Writes only to Staging/GeneIcons, plus a review sheet.
# After review, copy the PNGs to Textures/Genes/Icons/Status. Run this again whenever a penis gets
# sprites, so its icon stops showing the old state.
# Picture: aroused size 5 south, cropped, multiplied by a fixed skin color, as Sized Apparel tints it.
# Status, in the order checked:
#   green circle  this mod's sprite, or a Sized Apparel replacement in sized-apparel-zero/Textures
#   amber diamond Sized Apparel's own sprite, not replaced yet
#   red circle    no sprite: Sized Apparel falls back to the human penis. Gray human penis + name.
Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = "Stop"

$art = $PSScriptRoot
$rel = "Textures\SizedApparel\BodyParts\Human\Penis\Horny"
$ourDir = Join-Path (Split-Path $art) $rel
$replaceDir = Join-Path (Split-Path (Split-Path (Split-Path $art))) "sized-apparel-zero\$rel"
$saDir = "C:\Program Files (x86)\Steam\steamapps\common\RimWorld\Mods\sized-apparel-zero\$rel"
$out = Join-Path $art "Staging\GeneIcons"
New-Item -ItemType Directory -Force $out | Out-Null

function Find-Sprite($dir, $penis) {
    foreach ($name in "$($penis)_5_south.png", "$($penis)_5_RNW_south.png") {
        $path = Join-Path $dir $name
        if (Test-Path $path) { return $path }
    }
    return $null
}

function Get-Bounds($bmp) {
    $minX = $bmp.Width; $minY = $bmp.Height; $maxX = -1; $maxY = -1
    for ($y = 0; $y -lt $bmp.Height; $y += 2) {
        for ($x = 0; $x -lt $bmp.Width; $x += 2) {
            if ($bmp.GetPixel($x, $y).A -gt 96) {
                if ($x -lt $minX) { $minX = $x }
                if ($x -gt $maxX) { $maxX = $x }
                if ($y -lt $minY) { $minY = $y }
                if ($y -gt $maxY) { $maxY = $y }
            }
        }
    }
    if ($maxX -lt 0) { throw "blank sprite" }
    return New-Object System.Drawing.Rectangle $minX, $minY, ($maxX - $minX + 2), ($maxY - $minY + 2)
}

function New-Icon($source, $status, $label) {
    $sprite = New-Object System.Drawing.Bitmap $source
    $b = Get-Bounds $sprite
    $boxW = 430
    $boxH = if ($status -eq "none") { 340 } else { 450 }
    $scale = [Math]::Min($boxW / $b.Width, $boxH / $b.Height)
    $w = [int]($b.Width * $scale)
    $h = [int]($b.Height * $scale)
    $x = [int]((512 - $w) / 2)
    $y = [int](($boxH - $h) / 2 + 20)

    $c = New-Object System.Drawing.Imaging.ColorMatrix
    if ($status -eq "none") {
        foreach ($i in 0, 1, 2) { $c[0, $i] = 0.30; $c[1, $i] = 0.59; $c[2, $i] = 0.11 }
        $c[3, 3] = 0.8
    } else {
        $c[0, 0] = 0.93; $c[1, 1] = 0.77; $c[2, 2] = 0.65; $c[3, 3] = 1
    }
    $c[4, 4] = 1
    $attr = New-Object System.Drawing.Imaging.ImageAttributes
    $attr.SetColorMatrix($c)

    $icon = New-Object System.Drawing.Bitmap 512, 512, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($icon)
    $g.SmoothingMode = "AntiAlias"
    $g.InterpolationMode = "HighQualityBicubic"
    $dest = New-Object System.Drawing.Rectangle $x, $y, $w, $h
    # Some Sized Apparel sprites carry faint stray pixels; a high alpha cutoff keeps them out of the crop.
    $g.DrawImage($sprite, $dest, $b.X, $b.Y, $b.Width, $b.Height, [System.Drawing.GraphicsUnit]::Pixel, $attr)
    $sprite.Dispose()

    $edge = New-Object System.Drawing.Pen ([System.Drawing.Color]::Black), 14
    if ($status -eq "ours") {
        $fill = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(60, 200, 90))
        $g.FillEllipse($fill, 382, 12, 118, 118)
        $g.DrawEllipse($edge, 382, 12, 118, 118)
    } elseif ($status -eq "stock") {
        $fill = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(245, 180, 40))
        $pts = [System.Drawing.Point[]]@(
            (New-Object System.Drawing.Point 441, 6),
            (New-Object System.Drawing.Point 506, 71),
            (New-Object System.Drawing.Point 441, 136),
            (New-Object System.Drawing.Point 376, 71))
        $g.FillPolygon($fill, $pts)
        $g.DrawPolygon($edge, $pts)
    } else {
        $fill = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(220, 50, 45))
        $g.FillEllipse($fill, 382, 12, 118, 118)
        $g.DrawEllipse($edge, 382, 12, 118, 118)
        $size = 110
        do {
            $font = New-Object System.Drawing.Font "Arial", $size, ([System.Drawing.FontStyle]::Bold), ([System.Drawing.GraphicsUnit]::Pixel)
            $tw = $g.MeasureString($label, $font).Width
            $size -= 4
        } while ($tw -gt 500)
        $fmt = New-Object System.Drawing.StringFormat
        $fmt.Alignment = "Center"
        $fmt.LineAlignment = "Center"
        $path = New-Object System.Drawing.Drawing2D.GraphicsPath
        $path.AddString($label, $font.FontFamily, [int]$font.Style, $font.Size, (New-Object System.Drawing.RectangleF 0, 370, 512, 130), $fmt)
        $outline = New-Object System.Drawing.Pen ([System.Drawing.Color]::Black), 18
        $outline.LineJoin = "Round"
        $g.DrawPath($outline, $path)
        $g.FillPath([System.Drawing.Brushes]::White, $path)
    }
    $g.Dispose()
    return $icon
}

$rows = Import-Csv (Join-Path $art "GeneIcons.csv")
$results = foreach ($row in $rows) {
    $source = Find-Sprite $ourDir $row.penis
    $status = "ours"
    if (-not $source) { $source = Find-Sprite $replaceDir $row.penis }
    if (-not $source) { $source = Find-Sprite $saDir $row.penis; $status = "stock" }
    if (-not $source) { $source = Join-Path $saDir "Penis_5_south.png"; $status = "none" }
    $label = $row.penis -replace "Penis$", ""
    $icon = New-Icon $source $status $label
    $icon.Save((Join-Path $out "$($row.gene).png"), [System.Drawing.Imaging.ImageFormat]::Png)
    $icon.Dispose()
    [pscustomobject]@{ gene = $row.gene; penis = $row.penis; status = $status }
}
$results | Group-Object status | ForEach-Object { "$($_.Name): $($_.Count)" }
$results | Export-Csv (Join-Path $out "status.csv") -NoTypeInformation

# Review sheet on the gene window's dark background, grouped by status.
$cell = 150
$cols = 8
$rank = @{ ours = 0; stock = 1; none = 2 }
$order = @($results | Sort-Object @{ Expression = { $rank[$_.status] } }, penis, gene)
$sheet = New-Object System.Drawing.Bitmap ($cols * $cell), ([int][Math]::Ceiling($order.Count / $cols) * ($cell + 10))
$g = [System.Drawing.Graphics]::FromImage($sheet)
$g.Clear([System.Drawing.Color]::FromArgb(45, 50, 58))
$g.InterpolationMode = "HighQualityBicubic"
$font = New-Object System.Drawing.Font "Arial", 9
for ($i = 0; $i -lt $order.Count; $i++) {
    $cx = ($i % $cols) * $cell
    $cy = [Math]::Floor($i / $cols) * ($cell + 10)
    $img = [System.Drawing.Image]::FromFile((Join-Path $out "$($order[$i].gene).png"))
    $g.DrawImage($img, [int]($cx + 15), [int]($cy + 4), 120, 120)
    $img.Dispose()
    $name = $order[$i].gene -replace "_genitalia$", "" -replace "^rjw_genes_", "" -replace "^ROBTRG_", "R " -replace "^RJWAT_", "AT "
    $g.DrawString($name, $font, [System.Drawing.Brushes]::White, (New-Object System.Drawing.RectangleF $cx, ($cy + 126), $cell, 30))
}
$g.Dispose()
$sheet.Save((Join-Path $art "Staging\GeneIcons-review.png"), [System.Drawing.Imaging.ImageFormat]::Png)
$sheet.Dispose()
