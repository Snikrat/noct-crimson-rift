$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
Add-Type -AssemblyName System.Drawing
$projectRoot = Split-Path $PSScriptRoot -Parent
$auditRoot = Join-Path $projectRoot 'docs/assets-audit/new-packages'
[IO.Directory]::CreateDirectory($auditRoot) | Out-Null
$inventory = @()
foreach ($archive in Get-ChildItem -LiteralPath $projectRoot -File -Filter '*.zip') {
    $packageRoot = Join-Path $auditRoot $archive.BaseName
    [IO.Directory]::CreateDirectory($packageRoot) | Out-Null
    $zip = [IO.Compression.ZipFile]::OpenRead($archive.FullName)
    try {
        foreach ($entry in $zip.Entries) {
            if ([IO.Path]::GetExtension($entry.FullName) -notin @('.png', '.txt')) { continue }
            $destination = [IO.Path]::GetFullPath((Join-Path $packageRoot $entry.FullName))
            if (-not $destination.StartsWith($packageRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw 'Archive path outside audit directory' }
            [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($destination)) | Out-Null
            [IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $destination, $true)
            $item = [ordered]@{ package = $archive.BaseName; path = $entry.FullName; bytes = $entry.Length }
            if ($destination.EndsWith('.png')) {
                $img = [Drawing.Bitmap]::new($destination)
                $item.width = $img.Width
                $item.height = $img.Height
                $item.alpha = $img.PixelFormat.ToString()
                $img.Dispose()
            }
            $inventory += [pscustomobject]$item
        }
    } finally { $zip.Dispose() }
}
$inventory | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $auditRoot 'inventory.json') -Encoding utf8
$representatives = @($inventory | Where-Object { $_.path -like '*.png' -and $_.path -notmatch 'Objects_separately|EnvironmentTiles/Tile_|Sprites/(Heavy|Light) Bandit/' })
$representatives += @($inventory | Where-Object { $_.path -match 'Bandits/Sprites/(Heavy|Light) Bandit/(Attack|Run|Idle|Combat Idle)/.*_0.png' })
$font = [Drawing.Font]::new('Arial', 9)
$brush = [Drawing.SolidBrush]::new([Drawing.Color]::White)
for ($offset = 0; $offset -lt $representatives.Count; $offset += 20) {
    $bitmap = [Drawing.Bitmap]::new(1200, 1000)
    $graphics = [Drawing.Graphics]::FromImage($bitmap)
    $graphics.Clear([Drawing.Color]::FromArgb(32, 30, 40))
    $graphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
    $graphics.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::Half
    for ($i = $offset; $i -lt [Math]::Min($offset + 20, $representatives.Count); $i++) {
        $item = $representatives[$i]
        $x = (($i - $offset) % 4) * 300
        $y = [Math]::Floor(($i - $offset) / 4) * 200
        $img = [Drawing.Bitmap]::new((Join-Path (Join-Path $auditRoot $item.package) $item.path))
        $scale = [Math]::Min(290.0 / $img.Width, 145.0 / $img.Height)
        $scale = [Math]::Min(4.0, $scale)
        $w = [int]($img.Width * $scale)
        $h = [int]($img.Height * $scale)
        $rect = [Drawing.Rectangle]::new([int]($x + (300-$w)/2), [int]$y, $w, $h)
        $graphics.DrawImage($img, $rect, 0, 0, $img.Width, $img.Height, [Drawing.GraphicsUnit]::Pixel)
        $graphics.DrawString(($item.path + " ($($item.width)x$($item.height))"), $font, $brush, [Drawing.RectangleF]::new($x+4, $y+148, 292, 50))
        $img.Dispose()
    }
    $bitmap.Save((Join-Path $auditRoot ('contact-{0:D2}.png' -f (1 + [int]($offset/20)))), [Drawing.Imaging.ImageFormat]::Png)
    $graphics.Dispose()
    $bitmap.Dispose()
}
$font.Dispose()
$brush.Dispose()
$inventory | Group-Object package | ForEach-Object { Write-Output ($_.Name + ': ' + $_.Count + ' files') }
