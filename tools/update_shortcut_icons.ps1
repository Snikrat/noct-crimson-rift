param([switch]$UpdateShortcuts)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$sourcePath = Join-Path $projectRoot 'Emblema Gótico de Energia Carmesim.png'
$iconPath = Join-Path $projectRoot 'assets\ui\noct.ico'

if (!$UpdateShortcuts) {
    Add-Type -AssemblyName System.Drawing
    $sourceImage = [System.Drawing.Image]::FromFile($sourcePath)
    $bitmap = New-Object System.Drawing.Bitmap 256, 256
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $pngStream = New-Object System.IO.MemoryStream
    try {
        $graphics.Clear([System.Drawing.Color]::Transparent)
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $scale = [Math]::Min(256.0 / $sourceImage.Width, 256.0 / $sourceImage.Height)
        $width = [int]($sourceImage.Width * $scale)
        $height = [int]($sourceImage.Height * $scale)
        $graphics.DrawImage($sourceImage, [int]((256 - $width) / 2), [int]((256 - $height) / 2), $width, $height)
        $bitmap.Save($pngStream, [System.Drawing.Imaging.ImageFormat]::Png)
        $pngBytes = $pngStream.ToArray()
        [System.IO.Directory]::CreateDirectory((Split-Path -Parent $iconPath)) | Out-Null
        $iconStream = [System.IO.File]::Create($iconPath)
        $writer = New-Object System.IO.BinaryWriter $iconStream
        try {
            $writer.Write([uint16]0)
            $writer.Write([uint16]1)
            $writer.Write([uint16]1)
            $writer.Write([byte]0)
            $writer.Write([byte]0)
            $writer.Write([byte]0)
            $writer.Write([byte]0)
            $writer.Write([uint16]1)
            $writer.Write([uint16]32)
            $writer.Write([uint32]$pngBytes.Length)
            $writer.Write([uint32]22)
            $writer.Write($pngBytes)
        } finally { $writer.Dispose(); $iconStream.Dispose() }
    } finally {
        $pngStream.Dispose()
        $graphics.Dispose()
        $bitmap.Dispose()
        $sourceImage.Dispose()
    }
    Write-Output "Ícone criado: $iconPath"
    exit
}

if (!(Test-Path -LiteralPath $iconPath)) { throw 'Gere o arquivo ICO antes de atualizar os atalhos.' }
$desktopPath = 'C:\Users\felip\OneDrive\Área de Trabalho'
$shell = New-Object -ComObject WScript.Shell
foreach ($name in @('NOCT Crimson Rift (editor).lnk', 'NOCT Crimson Rift.lnk')) {
    $shortcutPath = Join-Path $desktopPath $name
    if (!(Test-Path -LiteralPath $shortcutPath)) { throw "Atalho ausente: $shortcutPath" }
    $shortcut = $shell.CreateShortcut($shortcutPath)
    $shortcut.IconLocation = "$iconPath,0"
    $shortcut.Save()
    $verified = $shell.CreateShortcut($shortcutPath)
    if ($verified.IconLocation -ne "$iconPath,0") { throw "Não foi possível verificar: $shortcutPath" }
    Write-Output "$name : $($verified.IconLocation)"
}
