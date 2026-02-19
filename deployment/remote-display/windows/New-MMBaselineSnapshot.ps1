param(
    [string]$CorePath = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")),
    [string]$SnapshotRoot = (Join-Path $PSScriptRoot "snapshots"),
    [string[]]$AdditionalFiles = @()
)

$ErrorActionPreference = "Stop"

function Copy-IfExists {
    param(
        [string]$Source,
        [string]$Destination
    )

    if (Test-Path $Source) {
        $destDir = Split-Path -Path $Destination -Parent
        if (-not (Test-Path $destDir)) {
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        }
        Copy-Item -Path $Source -Destination $Destination -Force
        return $true
    }

    return $false
}

if (-not (Test-Path $CorePath)) {
    throw "CorePath not found: $CorePath"
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$snapshotDir = Join-Path $SnapshotRoot "snapshot-$timestamp"
New-Item -ItemType Directory -Path $snapshotDir -Force | Out-Null

$filesToCapture = @(
    "config\config.js",
    "css\custom.css"
) + $AdditionalFiles

$captureReport = @()
foreach ($relativePath in $filesToCapture) {
    $sourceFile = Join-Path $CorePath $relativePath
    $destFile = Join-Path $snapshotDir $relativePath
    $copied = Copy-IfExists -Source $sourceFile -Destination $destFile
    $captureReport += [PSCustomObject]@{
        File = $relativePath
        Captured = $copied
    }
}

$gitInfoPath = Join-Path $snapshotDir "git-info.txt"
Push-Location $CorePath
try {
    $gitBranch = git branch --show-current
    $gitCommit = git rev-parse HEAD
    $gitStatus = git status --short --branch

    @(
        "Branch: $gitBranch",
        "Commit: $gitCommit",
        "",
        "Status:",
        $gitStatus
    ) | Set-Content -Path $gitInfoPath
}
finally {
    Pop-Location
}

$metadata = [PSCustomObject]@{
    CreatedAt = (Get-Date).ToString("o")
    CorePath = $CorePath
    SnapshotPath = $snapshotDir
    Files = $captureReport
    Notes = "Use Restore-MMBaselineSnapshot.ps1 to restore captured files."
}

$metadataPath = Join-Path $snapshotDir "metadata.json"
$metadata | ConvertTo-Json -Depth 6 | Set-Content -Path $metadataPath

Write-Host "Snapshot created: $snapshotDir" -ForegroundColor Green
Write-Host "Captured files:" -ForegroundColor Cyan
$captureReport | ForEach-Object {
    $state = if ($_.Captured) { "captured" } else { "missing" }
    Write-Host " - $($_.File): $state"
}
