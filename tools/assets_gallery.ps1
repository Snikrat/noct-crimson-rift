$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$auditDir = Join-Path $projectRoot 'docs\assets-audit'
$inventory = Get-Content -Raw (Join-Path $auditDir 'inventory.json') | ConvertFrom-Json
$cards = New-Object Text.StringBuilder
foreach ($entry in $inventory) {
    if ($entry.extension -notin @('.png', '.gif', '.ico', '.wav', '.ogg', '.mp3')) { continue }
    $label = [Net.WebUtility]::HtmlEncode($entry.path)
    $relativeUrl = '../../' + (($entry.path -split '/' | ForEach-Object { [Uri]::EscapeDataString($_) }) -join '/')
    $type = if ($entry.extension -in @('.wav', '.ogg', '.mp3')) { 'audio' } else { 'image' }
    $media = if ($type -eq 'audio') { "<audio controls preload='none' src='$relativeUrl'></audio>" } else { "<a href='$relativeUrl'><img loading='lazy' src='$relativeUrl' alt='$label'></a>" }
    $size = if ($entry.width) { "$($entry.width) × $($entry.height)" } else { "$([Math]::Round($entry.bytes / 1024)) KB" }
    [void]$cards.AppendLine("<article data-kind='$type' data-path='$label'>$media<p>$label</p><small>$size</small></article>")
}
$html = @'
<!doctype html><html lang="pt-BR"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>NOCT — Catálogo de assets</title><style>
body{margin:0;background:#191720;color:#e8e2ee;font:15px system-ui}header{position:sticky;top:0;background:#211b29;padding:18px 24px;border-bottom:1px solid #a63d62;z-index:2}h1{font-size:22px;margin:0 0 12px}input,select{background:#302738;color:inherit;border:1px solid #705165;border-radius:6px;padding:10px;margin-right:8px}input{width:min(55vw,500px)}main{display:grid;grid-template-columns:repeat(auto-fill,minmax(260px,1fr));gap:14px;padding:20px}article{min-width:0;background:#272331;border-radius:8px;padding:12px}article[hidden]{display:none}img{width:100%;height:160px;object-fit:contain;image-rendering:pixelated;background:#393440}p{font-size:12px;overflow-wrap:anywhere;margin-bottom:6px}small{color:#bfaebf}audio{max-width:100%}#count{margin-left:10px;font-size:12px}header p{font-size:13px;color:#c3b6c4}a{color:#ef92b5}</style>
<header><h1>NOCT: CRIMSON RIFT — Catálogo de assets</h1><p>Imagens e áudio locais. Clique numa imagem para abrir o original. A prévia não indica uso no jogo.</p><input id="search" placeholder="Buscar pacote, personagem ou arquivo"><select id="kind"><option value="all">Tudo</option><option value="image">Imagens</option><option value="audio">Áudio</option></select><span id="count"></span></header><main>
'@
$html += $cards.ToString()
$html += @'
</main><script>const cards=[...document.querySelectorAll('article')],search=document.querySelector('#search'),kind=document.querySelector('#kind');function filter(){let n=0;for(const c of cards){c.hidden=!(c.dataset.path.toLowerCase().includes(search.value.toLowerCase())&&(kind.value==='all'||c.dataset.kind===kind.value));if(!c.hidden)n++}document.querySelector('#count').textContent=n+' arquivos'}search.addEventListener('input',filter);kind.addEventListener('change',filter);filter();</script></html>
'@
$html | Set-Content -LiteralPath (Join-Path $auditDir 'gallery.html') -Encoding utf8
Write-Output 'Catálogo criado em docs/assets-audit/gallery.html'
