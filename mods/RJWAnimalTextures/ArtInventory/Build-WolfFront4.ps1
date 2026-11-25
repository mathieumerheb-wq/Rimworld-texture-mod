# WolfPenis_4_south rebuilt from TextureV2/ref-wolf-knot-front.png. Its shaft is mauve, so the
# earlier build (Build-CanineKnot.ps1) turned most of it into the gray skin mask and left a patchy
# gray and red shaft. This uses FoxFix.Prepare from Build-FoxFix.ps1 (same method as fox size 4):
# the shaft is picked by saturation and shaded in the size 3 red, the rest is the gray mask.
# Measured saturation: shaft 0.27-0.41, scrotum 0.15-0.22, so the cutoff is 0.24.
# Placed at the live sprite's height and base: south 165 px, bottom center (256, 269).
# Writes only to Staging/WolfFront4. Build-WolfCleanup.ps1 then picks it up from there.
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = "Stop"

$art = $PSScriptRoot
$fox = Get-Content (Join-Path $art "Build-FoxFix.ps1") -Raw
$start = $fox.IndexOf("@'") + 2
$end = $fox.IndexOf("'@", $start)
if (-not ("FoxFix" -as [type])) {
    Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition $fox.Substring($start, $end - $start)
}

$out = Join-Path $art "Staging\WolfFront4"
New-Item -ItemType Directory -Force $out | Out-Null
# The scrotum's lower shadow (reference rows 265-292) is as saturated as the shaft (0.24-0.31), so
# saturation alone paints it red. Below row 248, under the knot, the picture is only scrotum: a copy
# of the reference is desaturated there before Prepare, so it all stays in the gray mask.
$ref = New-Object System.Drawing.Bitmap (Join-Path $art "TextureV2\ref-wolf-knot-front.png")
for ($y = 248; $y -lt $ref.Height; $y++) {
    for ($x = 0; $x -lt $ref.Width; $x++) {
        $c = $ref.GetPixel($x, $y)
        $l = [int](($c.R * 299 + $c.G * 587 + $c.B * 114) / 1000)
        $ref.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($c.A, [int]($l + ($c.R - $l) * 0.3), [int]($l + ($c.G - $l) * 0.3), [int]($l + ($c.B - $l) * 0.3)))
    }
}
$prepped = Join-Path $out "ref-wolf-knot-front-lowgray.png"
$ref.Save($prepped, [System.Drawing.Imaging.ImageFormat]::Png)
$ref.Dispose()
$src = [FoxFix]::Prepare($prepped, 0.24)
$s = [FoxFix]::Place($src, -90, 165, $false, 256, 269)
$s.Save((Join-Path $out "WolfPenis_4_south.png"), [System.Drawing.Imaging.ImageFormat]::Png)
$s.Dispose()
$src.Dispose()
