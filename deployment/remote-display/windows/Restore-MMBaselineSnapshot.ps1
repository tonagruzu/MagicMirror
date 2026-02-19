param(
    [Parameter(Mandatory = $true)]
    [string]$SnapshotPath,
    [string]$CorePath = (Resolve-Path (Join-Path $PSScriptRoot "..\..\.."))
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $SnapshotPath)) {
    throw "SnapshotPath not found: $SnapshotPath"
}

if (-not (Test-Path $CorePath)) {
    throw "CorePath not found: $CorePath"
}

$metadataPath = Join-Path $SnapshotPath "metadata.json"
if (Test-Path $metadataPath) {
    Write-Host "Restoring snapshot metadata from: $metadataPath" -ForegroundColor Cyan
}

$files = Get-ChildItem -Path $SnapshotPath -Recurse -File |
    Where-Object {
        $_.Name -ne "metadata.json" -and
        $_.Name -ne "git-info.txt"
    }

if (-not $files) {
    throw "No restorable files found in snapshot: $SnapshotPath"
}

foreach ($file in $files) {
    $relativePath = $file.FullName.Substring($SnapshotPath.Length).TrimStart('\\', '/')
    $destination = Join-Path $CorePath $relativePath
    $destinationDir = Split-Path -Path $destination -Parent

    if (-not (Test-Path $destinationDir)) {
        New-Item -ItemType Directory -Path $destinationDir -Force | Out-Null
    }

    Copy-Item -Path $file.FullName -Destination $destination -Force
    Write-Host "Restored: $relativePath" -ForegroundColor Gray
}

Write-Host "Restore completed to: $CorePath" -ForegroundColor Green
Write-Host "Run 'npm run config:check' before restarting MagicMirror." -ForegroundColor Yellow
