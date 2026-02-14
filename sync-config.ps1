# Sync configuration files between MMM-Core and MMM-config-files
# Usage: 
#   .\sync-config.ps1 pull   - Copy from MMM-config-files to MMM-Core
#   .\sync-config.ps1 push   - Copy from MMM-Core to MMM-config-files

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('pull','push')]
    [string]$Direction
)

$MMMCore = "D:\REPOS\MMM-Core"
$ConfigRepo = "D:\REPOS\MMM-config-files"

# Define files to sync (relative paths)
$FilesToSync = @(
    "config\config.js",
    "css\custom.css"
    # Add more files as needed
)

if ($Direction -eq "pull") {
    Write-Host "Pulling config files from MMM-config-files to MMM-Core..." -ForegroundColor Green
    foreach ($file in $FilesToSync) {
        $source = Join-Path $ConfigRepo $file
        $dest = Join-Path $MMMCore $file
        
        if (Test-Path $source) {
            Copy-Item -Path $source -Destination $dest -Force
            Write-Host "  ✓ Copied $file" -ForegroundColor Gray
        } else {
            Write-Host "  ✗ Not found: $file" -ForegroundColor Yellow
        }
    }
    Write-Host "Pull complete!" -ForegroundColor Green
}
elseif ($Direction -eq "push") {
    Write-Host "Pushing config files from MMM-Core to MMM-config-files..." -ForegroundColor Cyan
    foreach ($file in $FilesToSync) {
        $source = Join-Path $MMMCore $file
        $dest = Join-Path $ConfigRepo $file
        
        if (Test-Path $source) {
            # Ensure directory exists
            $destDir = Split-Path $dest -Parent
            if (!(Test-Path $destDir)) {
                New-Item -ItemType Directory -Path $destDir -Force | Out-Null
            }
            
            Copy-Item -Path $source -Destination $dest -Force
            Write-Host "  ✓ Copied $file" -ForegroundColor Gray
        } else {
            Write-Host "  ✗ Not found: $file" -ForegroundColor Yellow
        }
    }
    Write-Host "Push complete! Don't forget to commit and push in MMM-config-files repo." -ForegroundColor Cyan
}
