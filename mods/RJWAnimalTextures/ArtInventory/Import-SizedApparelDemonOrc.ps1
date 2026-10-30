# Copies the Sized Apparel DemonPenis and OrcPenis sets into ArtInventory for review.
# Does not write into this mod's Textures folder, and does not change the installed mod.
Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = "Stop"

$sourceRoot = "C:\Program Files (x86)\Steam\steamapps\common\RimWorld\Mods\sized-apparel-zero\Textures\SizedApparel\BodyParts\Human\Penis"
$inventory = "C:\Users\mathi\Documents\Rimworld new mods\mods\RJWAnimalTextures\ArtInventory"
$previewDir = Join-Path $inventory "TextureV2"

function Copy-Set($name) {
    $dest = Join-Path $inventory ("SizedApparel" + $name)
    if (Test-Path $dest) { Remove-Item $dest -Recurse -Force }
    New-Item -ItemType Directory -Path $dest | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $dest "Horny") | Out-Null
    $ballsSrc = Join-Path $sourceRoot "Balls"
    $hasBalls = $false
    Get-ChildItem $sourceRoot -File -Filter ($name + "_*.png") | ForEach-Object {
        Copy-Item $_.FullName (Join-Path $dest $_.Name)
    }
    Get-ChildItem (Join-Path $sourceRoot "Horny") -File -Filter ($name + "_*.png") | ForEach-Object {
        Copy-Item $_.FullName (Join-Path $dest ("Horny\" + $_.Name))
    }
    if (Test-Path $ballsSrc) {
        $ballFiles = Get-ChildItem $ballsSrc -File -Filter ($name + "_*.png")
        if ($ballFiles) {
            $hasBalls = $true
            New-Item -ItemType Directory -Path (Join-Path $dest "Balls") | Out-Null
            $ballFiles | ForEach-Object { Copy-Item $_.FullName (Join-Path $dest ("Balls\" + $_.Name)) }
        }
    }
    $note = @"
Copied from Sized Apparel for review. Not part of the RJWAnimalTextures live texture set.
Source: $sourceRoot
Gene: see the file header in the import script.
"@
    Set-Content -Path (Join-Path $dest "SOURCE.txt") -Value $note -Encoding UTF8
    return $hasBalls
}

function Get-ContentBox($path) {
    $bmp = [System.Drawing.Bitmap]::FromFile($path)
    $minX = $bmp.Width; $minY = $bmp.Height; $maxX = -1; $maxY = -1; $count = 0
    if ($bmp.Width -le 8) {
        $bmp.Dispose()
        return @{ Empty = $true; MinX = 0; MinY = 0; MaxX = 3; MaxY = 3; Count = 0 }
    }
    for ($y = 0; $y -lt $bmp.Height; $y++) {
        for ($x = 0; $x -lt $bmp.Width; $x++) {
            if ($bmp.GetPixel($x, $y).A -lt 16) { continue }
            $count++
            if ($x -lt $minX) { $minX = $x }
            if ($y -lt $minY) { $minY = $y }
            if ($x -gt $maxX) { $maxX = $x }
            if ($y -gt $maxY) { $maxY = $y }
        }
    }
    $bmp.Dispose()
    if ($count -eq 0) { return @{ Empty = $true; MinX = 0; MinY = 0; MaxX = 3; MaxY = 3; Count = 0 } }
    return @{ Empty = $false; MinX = $minX; MinY = $minY; MaxX = $maxX; MaxY = $maxY; Count = $count }
}

function Build-Sheet($name, $hasBalls, $previewPath) {
    $root = Join-Path $inventory ("SizedApparel" + $name)
    $rows = @(
        @{ Label = "Rest south"; Folder = ""; Dir = "south" },
        @{ Label = "Rest east"; Folder = ""; Dir = "east" },
        @{ Label = "Rest north"; Folder = ""; Dir = "north" },
        @{ Label = "Aroused south"; Folder = "Horny"; Dir = "south" },
        @{ Label = "Aroused east"; Folder = "Horny"; Dir = "east" },
        @{ Label = "Aroused north"; Folder = "Horny"; Dir = "north" }
    )
    if ($hasBalls) {
        $rows += @{ Label = "Balls south"; Folder = "Balls"; Dir = "south" }
        $rows += @{ Label = "Balls east"; Folder = "Balls"; Dir = "east" }
        $rows += @{ Label = "Balls north"; Folder = "Balls"; Dir = "north" }
    }
    $winL = 9999; $winT = 9999; $winR = 0; $winB = 0
    foreach ($row in $rows) {
        foreach ($size in 0..5) {
            $folder = if ($row.Folder) { Join-Path $root $row.Folder } else { $root }
            $file = Join-Path $folder ($name + "_" + $size + "_" + $row.Dir + ".png")
            $box = Get-ContentBox $file
            if ($box.Empty) { continue }
            if ($box.MinX -lt $winL) { $winL = $box.MinX }
            if ($box.MinY -lt $winT) { $winT = $box.MinY }
            if ($box.MaxX -gt $winR) { $winR = $box.MaxX }
            if ($box.MaxY -gt $winB) { $winB = $box.MaxY }
        }
    }
    if ($winR -lt $winL) { $winL = 0; $winT = 0; $winR = 64; $winB = 64 }
    $window = [System.Drawing.Rectangle]::FromLTRB([Math]::Max(0, $winL - 8), [Math]::Max(0, $winT - 8), [Math]::Min(512, $winR + 9), [Math]::Min(512, $winB + 9))
    $sheet = New-Object System.Drawing.Bitmap 1200, (40 + $rows.Count * 180)
    $g = [System.Drawing.Graphics]::FromImage($sheet)
    $g.Clear([System.Drawing.Color]::FromArgb(255, 18, 18, 22))
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
    $font = New-Object System.Drawing.Font "Segoe UI", 12
    $brush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 220, 220, 220))
    for ($r = 0; $r -lt $rows.Count; $r++) {
        $g.DrawString($rows[$r].Label, $font, $brush, 16, (8 + $r * 180))
        foreach ($size in 0..5) {
            $folder = if ($rows[$r].Folder) { Join-Path $root $rows[$r].Folder } else { $root }
            $file = Join-Path $folder ($name + "_" + $size + "_" + $rows[$r].Dir + ".png")
            $bmp = [System.Drawing.Bitmap]::FromFile($file)
            $cell = New-Object System.Drawing.Rectangle (16 + $size * 196), (28 + $r * 180), 180, 150
            $fit = [Math]::Min($cell.Width / [single]$window.Width, $cell.Height / [single]$window.Height)
            $pw = [Math]::Max(1, [int]($window.Width * $fit))
            $ph = [Math]::Max(1, [int]($window.Height * $fit))
            $dest = New-Object System.Drawing.Rectangle ($cell.X + ($cell.Width - $pw) / 2), ($cell.Y + ($cell.Height - $ph) / 2), $pw, $ph
            $g.DrawImage($bmp, $dest, $window, [System.Drawing.GraphicsUnit]::Pixel)
            $bmp.Dispose()
        }
    }
    $font.Dispose(); $brush.Dispose(); $g.Dispose()
    $sheet.Save($previewPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $sheet.Dispose()
    Write-Output ("PREVIEW " + $previewPath)
}

$demonBalls = Copy-Set "DemonPenis"
$orcBalls = Copy-Set "OrcPenis"
Build-Sheet "DemonPenis" $demonBalls (Join-Path $previewDir "preview-DemonPenis-sizedapparel.png")
Build-Sheet "OrcPenis" $orcBalls (Join-Path $previewDir "preview-OrcPenis-sizedapparel.png")
Write-Output ("Demon balls " + $demonBalls + " Orc balls " + $orcBalls)
