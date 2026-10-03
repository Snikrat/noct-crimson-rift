Add-Type -AssemblyName System.Drawing
$root = Split-Path $PSScriptRoot -Parent
$source = [Drawing.Bitmap]::new((Join-Path $root 'art_source/Atlas de Sprites Pixel Art_ Combate Mágico.png'))
$output = Join-Path $root 'assets/hero/vfx'
New-Item -ItemType Directory -Path $output -Force | Out-Null
# Os limites excluem molduras e rótulos. Apenas a energia vermelha é extraída.
$cuts = @{
    impact = @(194, 908, 128, 85, 64, 43)
    shockwave = @(324, 908, 131, 85, 96, 32)
    circle = @(552, 908, 117, 85, 64, 32)
    trail1 = @(672, 908, 85, 85, 42, 42)
    trail2 = @(760, 908, 90, 85, 44, 42)
    trail3 = @(853, 908, 104, 85, 52, 42)
    portal1 = @(964, 908, 96, 85, 48, 48)
    portal2 = @(1064, 908, 112, 85, 48, 48)
}
foreach ($name in $cuts.Keys) {
    $c = $cuts[$name]
    $image = [Drawing.Bitmap]::new($c[4], $c[5])
    for ($y = 0; $y -lt $c[5]; $y++) {
        for ($x = 0; $x -lt $c[4]; $x++) {
            $p = $source.GetPixel($c[0] + [int][Math]::Floor($x * $c[2] / $c[4]), $c[1] + [int][Math]::Floor($y * $c[3] / $c[5]))
            if ($p.R -gt 110 -and $p.R -gt $p.G * 1.3 -and $p.R -gt $p.B * 1.15) {
                $alpha = [int][Math]::Min(255, [Math]::Max(0, ($p.R - 105) * 2.3))
                $image.SetPixel($x, $y, [Drawing.Color]::FromArgb($alpha, $p.R, $p.G, $p.B))
            }
        }
    }
    $image.Save((Join-Path $output ($name + '.png')), [Drawing.Imaging.ImageFormat]::Png)
    $image.Dispose()
}
$source.Dispose()
