# Publish static files to icebot411/cdn-store (jsDelivr via GitHub @main).
# Usage:
#   .\publish-cdn-store-asset.ps1 -Source .\my-icon.svg -Dest svg/small/my-icon.svg -Message "Add my-icon" -Commit -Push
#   .\publish-cdn-store-asset.ps1 -Source C:\assets\batch -Dest svg/custom -Message "Add custom icons" -Commit

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $Source,

    [Parameter(Mandatory = $true)]
    [string] $Dest,

    [string] $Message = '',

    [string] $CdnStoreRoot = $PSScriptRoot,

    [switch] $Commit,
    [switch] $Push,
    [switch] $DryRun
)

$ErrorActionPreference = 'Stop'

$JSDELIVR_BASE = 'https://cdn.jsdelivr.net/gh/icebot411/cdn-store@main'
$DEFAULT_BRANCH = 'main'

function Write-Step([string] $Text) {
    Write-Host "==> $Text"
}

function Assert-RepoRoot([string] $Root) {
    if (-not (Test-Path -LiteralPath $Root -PathType Container)) {
        throw "CdnStoreRoot not found: $Root"
    }
    $gitDir = Join-Path $Root '.git'
    if (-not (Test-Path -LiteralPath $gitDir)) {
        throw "Not a git repository: $Root (clone git@github.com:icebot411/cdn-store.git first)"
    }
}

function Normalize-RepoRelativePath([string] $Path) {
    $p = $Path -replace '\\', '/'
    $p = $p.Trim().TrimStart('/')
    if ($p -match '\.\.') {
        throw "Dest must stay inside the repo (no '..'): $Path"
    }
    if ([string]::IsNullOrWhiteSpace($p)) {
        throw 'Dest cannot be empty.'
    }
    return $p
}

function Copy-IntoRepo {
    param(
        [string] $SourcePath,
        [string] $DestRelative,
        [string] $Root
    )

    $destFull = Join-Path $Root ($DestRelative -replace '/', [IO.Path]::DirectorySeparatorChar)
    $sourceItem = Get-Item -LiteralPath $SourcePath

    if ($sourceItem.PSIsContainer) {
        if (-not (Test-Path -LiteralPath $destFull)) {
            if ($DryRun) {
                Write-Step "mkdir $destFull"
            } else {
                New-Item -ItemType Directory -Force -Path $destFull | Out-Null
            }
        }
        $children = Get-ChildItem -LiteralPath $sourceItem.FullName -Recurse -File
        foreach ($child in $children) {
            $rel = $child.FullName.Substring($sourceItem.FullName.Length).TrimStart('\', '/')
            $target = Join-Path $destFull $rel
            $targetDir = Split-Path -Parent $target
            if ($DryRun) {
                Write-Step "copy $($child.FullName) -> $target"
            } else {
                if ($targetDir -and -not (Test-Path -LiteralPath $targetDir)) {
                    New-Item -ItemType Directory -Force -Path $targetDir | Out-Null
                }
                Copy-Item -LiteralPath $child.FullName -Destination $target -Force
            }
        }
        return
    }

    $destDir = Split-Path -Parent $destFull
    if ($destDir -and -not (Test-Path -LiteralPath $destDir)) {
        if ($DryRun) {
            Write-Step "mkdir $destDir"
        } else {
            New-Item -ItemType Directory -Force -Path $destDir | Out-Null
        }
    }

    if ($DryRun) {
        Write-Step "copy $($sourceItem.FullName) -> $destFull"
    } else {
        Copy-Item -LiteralPath $sourceItem.FullName -Destination $destFull -Force
    }
}

function Invoke-GitInRepo {
    param(
        [string] $Root,
        [string[]] $Args
    )
    $display = "git -C `"$Root`" $($Args -join ' ')"
    if ($DryRun) {
        Write-Step $display
        return
    }
    & git -C $Root @Args
    if ($LASTEXITCODE -ne 0) {
        throw "git failed ($LASTEXITCODE): $display"
    }
}

Assert-RepoRoot -Root $CdnStoreRoot

$sourceResolved = (Resolve-Path -LiteralPath $Source).Path
$destRelative = Normalize-RepoRelativePath -Path $Dest

Write-Step "Repo: $CdnStoreRoot"
Write-Step "Source: $sourceResolved"
Write-Step "Dest (relative): $destRelative"

Copy-IntoRepo -SourcePath $sourceResolved -DestRelative $destRelative -Root $CdnStoreRoot

$doCommit = $Commit -or $Push
if ($Push -and -not $Commit) {
    $Commit = $true
}

if ($doCommit) {
    if ([string]::IsNullOrWhiteSpace($Message)) {
        throw 'Provide -Message when using -Commit or -Push.'
    }
    Invoke-GitInRepo -Root $CdnStoreRoot -Args @('add', '--', $destRelative)
    Invoke-GitInRepo -Root $CdnStoreRoot -Args @('commit', '-m', $Message)
}

if ($Push) {
    Invoke-GitInRepo -Root $CdnStoreRoot -Args @('push', 'origin', $DEFAULT_BRANCH)
}

$cdnUrl = "$JSDELIVR_BASE/$destRelative"
Write-Host ''
Write-Host 'CDN URL (after push + jsDelivr cache):' -ForegroundColor Cyan
Write-Host $cdnUrl
if ((Get-Item -LiteralPath $sourceResolved).PSIsContainer) {
    Write-Host '(folder publish — open each file under the path above)' -ForegroundColor DarkGray
} else {
    Write-Host "Test: start $cdnUrl" -ForegroundColor DarkGray
}
