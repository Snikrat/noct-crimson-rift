$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$projectRoot = Split-Path $PSScriptRoot -Parent
$packages = @{
    'Bandits.zip' = 'bandits'
    'EVil Wizard 2.zip' = 'evil-wizard-2'
    'Hero Knight.zip' = 'hero-knight'
    "Garden's Forest.zip" = 'gardens-forest'
    'Free-Undead-Tileset-Top-Down-Pixel-Art.zip' = 'undead-props'
}
foreach ($name in $packages.Keys) {
    $destinationRoot = Join-Path $projectRoot ('assets/vendor/' + $packages[$name])
    [IO.Directory]::CreateDirectory($destinationRoot) | Out-Null
    $zip = [IO.Compression.ZipFile]::OpenRead((Join-Path $projectRoot $name))
    try {
        foreach ($entry in $zip.Entries) {
            $relative = $entry.FullName
            if ($relative.EndsWith('/')) { continue }
            if ($packages[$name] -eq 'undead-props') {
                if ($relative -notmatch '^(License.txt|readme.txt|PNG/Objects_separately/(Crystal_shadow1_1|Grave_shadow1_1|Pile_sculls_shadow1|Ruin_shadow1_1|Scull_door_shadow1|Bones_shadow1_1).png)$') { continue }
            } else {
                if ([IO.Path]::GetExtension($relative) -notin @('.png', '.txt') -or $relative -match '/Preview/|EnvironmentTiles/') { continue }
                $relative = $relative.Substring($relative.IndexOf('/') + 1)
            }
            $destination = [IO.Path]::GetFullPath((Join-Path $destinationRoot $relative))
            if (-not $destination.StartsWith($destinationRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw 'Archive path outside asset directory' }
            [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($destination)) | Out-Null
            [IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $destination, $true)
        }
    } finally { $zip.Dispose() }
    Write-Output ('Installed ' + $packages[$name])
}
