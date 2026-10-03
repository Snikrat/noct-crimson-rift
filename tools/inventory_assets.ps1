$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$projectRoot = Split-Path -Parent $PSScriptRoot
$outputDir = Join-Path $projectRoot 'docs\assets-audit'
[IO.Directory]::CreateDirectory($outputDir) | Out-Null
$files = @(Get-ChildItem (Join-Path $projectRoot 'assets'), (Join-Path $projectRoot 'art_source') -Recurse -File | Where-Object Extension -ne '.import')
$files += @(Get-ChildItem -LiteralPath $projectRoot -File | Where-Object Extension -in @('.png', '.ico', '.svg'))
$inventory = @()
foreach ($file in $files) {
    $relative = $file.FullName.Substring($projectRoot.Length + 1).Replace('\', '/')
    $entry = [ordered]@{ path = $relative; extension = $file.Extension; bytes = $file.Length; sha256 = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash }
    if ($file.Extension -in @('.png', '.gif', '.ico')) {
        try {
            $img = [Drawing.Image]::FromFile($file.FullName)
            $entry.width = $img.Width
            $entry.height = $img.Height
            $entry.pixel_format = $img.PixelFormat.ToString()
            $img.Dispose()
        } catch { $entry.error = $_.Exception.Message }
    }
    $inventory += [pscustomobject]$entry
}
$inventory | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $outputDir 'inventory.json') -Encoding utf8
$groups = @($inventory | Where-Object extension -eq '.png' | Group-Object { if ($_.path -match 'sword-icons|/Final/|MountainsLayers') { $_.path } else { $_.path -replace '\d+(?=\.png$)', '{frame}' } })
$representatives = @()
foreach ($group in $groups) {
    $ordered = @($group.Group | Sort-Object path)
    $representatives += $ordered[0]
    if ($ordered.Count -gt 2) { $representatives += $ordered[[int]($ordered.Count / 2)] }
}
$representatives = @($representatives | Sort-Object path)
$font = New-Object Drawing.Font 'Arial', 8
$brush = New-Object Drawing.SolidBrush ([Drawing.Color]::FromArgb(225, 225, 230))
for ($offset = 0; $offset -lt $representatives.Count; $offset += 40) {
    $bitmap = New-Object Drawing.Bitmap 1200, 1150
    $graphics = [Drawing.Graphics]::FromImage($bitmap)
    $graphics.Clear([Drawing.Color]::FromArgb(32, 30, 40))
    $graphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
    $graphics.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::Half
    for ($index = $offset; $index -lt [Math]::Min($offset + 40, $representatives.Count); $index++) {
        $entry = $representatives[$index]
        $localIndex = $index - $offset
        $x = ($localIndex % 5) * 240
        $y = [int][Math]::Floor($localIndex / 5) * 142
        $img = [Drawing.Image]::FromFile((Join-Path $projectRoot $entry.path))
        try {
            $scale = [Math]::Min(226.0 / $img.Width, 95.0 / $img.Height)
            $scale = [Math]::Min(3.0, $scale)
            $width = [int]($img.Width * $scale)
            $height = [int]($img.Height * $scale)
            $destination = New-Object Drawing.Rectangle ($x + [int]((240 - $width) / 2)), ($y + [int]((95 - $height) / 2)), $width, $height
            $graphics.DrawImage($img, $destination, 0, 0, $img.Width, $img.Height, [Drawing.GraphicsUnit]::Pixel)
        } finally { $img.Dispose() }
        $label = $entry.path.Replace('assets/vendor/', '').Replace('gothicvania-', 'gv-')
        $graphics.DrawString("$index  $label", $font, $brush, (New-Object Drawing.RectangleF ($x + 4), ($y + 96), 232, 44))
    }
    $page = [int]($offset / 40) + 1
    $bitmap.Save((Join-Path $outputDir ('contact-{0:D2}.png' -f $page)), [Drawing.Imaging.ImageFormat]::Png)
    $graphics.Dispose()
    $bitmap.Dispose()
}
$font.Dispose()
$brush.Dispose()
Write-Output "Files: $($inventory.Count); PNGs: $(($inventory | Where-Object extension -eq '.png').Count); representatives: $($representatives.Count); sheets: $([Math]::Ceiling($representatives.Count / 40))"
$inventory | Group-Object { ($_.path -split '/')[0..2] -join '/' } | ForEach-Object { Write-Output "$($_.Name): $($_.Count) files" }
$duplicates = @($inventory | Group-Object sha256 | Where-Object Count -gt 1)
Write-Output "Identical file groups: $($duplicates.Count)"
