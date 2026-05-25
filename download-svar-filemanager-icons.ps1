# Downloads SVAR "Willow vivid" filemanager SVGs from CDN into ./svg/.
# Icon basenames mirror the internal map (`me`) in @svar-ui/react-filemanager (see dist/index.es.js).
# Fallback icon `unknown` is included even though it is not in that map.

$ErrorActionPreference = 'Stop'

$names = @(
    '7z', 'rar', 'zip',
    'css', 'html', 'js', 'php', 'md', 'xml', 'sql',
    'aif', 'mid', 'mp3', 'waw', 'wma',
    'doc', 'docx', 'txt',
    'avi', 'mov', 'mp4', 'mpeg', 'mpg',
    'pdf', 'xls', 'xlsx',
    'gif', 'jpg', 'jpeg', 'png', 'psd', 'tiff', 'svg',
    'folder', 'file',
    'multiple', 'search', 'none',
    'unknown'
)
$sizes = @('small', 'big')
$scriptRoot = $PSScriptRoot
$destRoot = Join-Path $scriptRoot 'svg'
$baseUrl = 'https://cdn.svar.dev/icons/filemanager/vivid'

foreach ($size in $sizes) {
    $dir = Join-Path $destRoot $size
    New-Item -ItemType Directory -Force -Path $dir | Out-Null

    foreach ($name in $names) {
        $url = "$baseUrl/$size/$name.svg"
        $out = Join-Path $dir "$name.svg"
        try {
            Invoke-WebRequest -Uri $url -OutFile $out -UseBasicParsing -TimeoutSec 45
            if ((Get-Item $out).Length -lt 80) {
                Remove-Item $out -Force
            }
        } catch {
            if (Test-Path $out) { Remove-Item $out -Force -ErrorAction SilentlyContinue }
        }
    }
}

# SVAR CDN has no small/ variants for UI meta icons — reuse big/.
foreach ($n in @('multiple', 'search', 'none')) {
    $big = Join-Path $destRoot "big\$n.svg"
    $small = Join-Path $destRoot "small\$n.svg"
    if ((Test-Path $big) -and -not (Test-Path $small)) {
        Copy-Item $big $small -Force
    }
}

Write-Host "Done. small: $((Get-ChildItem (Join-Path $destRoot 'small') -Filter *.svg -ErrorAction SilentlyContinue).Count) big: $((Get-ChildItem (Join-Path $destRoot 'big') -Filter *.svg -ErrorAction SilentlyContinue).Count)"
