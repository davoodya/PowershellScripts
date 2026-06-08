```powershell
#Requires -RunAsAdministrator

$ErrorActionPreference = "SilentlyContinue"

function Get-FolderSize {
    param([string]$Path)

    if (!(Test-Path $Path)) {
        return 0
    }

    try {
        $size = (Get-ChildItem $Path -Force -Recurse -ErrorAction SilentlyContinue |
                 Measure-Object -Property Length -Sum).Sum

        if ($null -eq $size) {
            return 0
        }

        return [math]::Round($size / 1GB, 2)
    }
    catch {
        return 0
    }
}

function Confirm-Cleanup {
    param(
        [string]$Title,
        [string]$Path
    )

    if (!(Test-Path $Path)) {
        return
    }

    $size = Get-FolderSize $Path

    Write-Host ""
    Write-Host "===================================" -ForegroundColor Cyan
    Write-Host "Target : $Title"
    Write-Host "Path   : $Path"
    Write-Host "Size   : $size GB"
    Write-Host "===================================" -ForegroundColor Cyan

    $answer = Read-Host "[Enter/Y]=Delete  [N]=Skip"

    if ([string]::IsNullOrWhiteSpace($answer) -or $answer -match "^(y|yes)$") {

        try {
            Get-ChildItem $Path -Force -ErrorAction SilentlyContinue |
                Remove-Item -Force -Recurse -ErrorAction SilentlyContinue

            Write-Host "[DELETED]" -ForegroundColor Green
        }
        catch {
            Write-Host "[FAILED] $_" -ForegroundColor Red
        }
    }
    else {
        Write-Host "[SKIPPED]" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Windows Safe Cleaner" -ForegroundColor Green
Write-Host "Interactive Cleanup Mode"
Write-Host ""

# Windows Temp
Confirm-Cleanup `
    -Title "User TEMP" `
    -Path $env:TEMP

Confirm-Cleanup `
    -Title "Windows TEMP" `
    -Path "C:\Windows\Temp"

# Python
Confirm-Cleanup `
    -Title "PIP Cache" `
    -Path "$env:LOCALAPPDATA\pip\Cache"

# NPM
Confirm-Cleanup `
    -Title "NPM Cache" `
    -Path "$env:LOCALAPPDATA\npm-cache"

# Yarn
Confirm-Cleanup `
    -Title "Yarn Cache" `
    -Path "$env:LOCALAPPDATA\Yarn\Cache"

# PNPM
Confirm-Cleanup `
    -Title "PNPM Store" `
    -Path "$env:LOCALAPPDATA\pnpm-store"

# VS Code
Confirm-Cleanup `
    -Title "VSCode Logs" `
    -Path "$env:APPDATA\Code\logs"

Confirm-Cleanup `
    -Title "VSCode Cached Extensions" `
    -Path "$env:APPDATA\Code\CachedExtensionVSIXs"

# NuGet
Confirm-Cleanup `
    -Title "NuGet Cache" `
    -Path "$env:USERPROFILE\.nuget\packages"

# Crash Dumps
Confirm-Cleanup `
    -Title "Windows Minidumps" `
    -Path "C:\Windows\Minidump"

if (Test-Path "C:\Windows\MEMORY.DMP") {

    $size = [math]::Round(
        ((Get-Item "C:\Windows\MEMORY.DMP").Length / 1GB),
        2
    )

    Write-Host ""
    Write-Host "MEMORY.DMP Size: $size GB"

    $ans = Read-Host "Delete MEMORY.DMP ? [Enter/Y/N]"

    if ([string]::IsNullOrWhiteSpace($ans) -or $ans -match "^(y|yes)$") {
        Remove-Item "C:\Windows\MEMORY.DMP" -Force
    }
}

# Windows Update Cache
Confirm-Cleanup `
    -Title "Windows Update Download Cache" `
    -Path "C:\Windows\SoftwareDistribution\Download"

# Delivery Optimization
Confirm-Cleanup `
    -Title "Delivery Optimization Cache" `
    -Path "C:\Windows\ServiceProfiles\NetworkService\AppData\Local\Microsoft\Windows\DeliveryOptimization"

# Windows Error Reporting
Confirm-Cleanup `
    -Title "Windows Error Reports" `
    -Path "$env:ProgramData\Microsoft\Windows\WER"

# Telegram Desktop Cache
Confirm-Cleanup `
    -Title "Telegram Cache" `
    -Path "$env:APPDATA\Telegram Desktop\tdata\user_data\cache"

# Discord Cache
Confirm-Cleanup `
    -Title "Discord Cache" `
    -Path "$env:APPDATA\discord\Cache"

# Chrome Cache
Confirm-Cleanup `
    -Title "Chrome Cache" `
    -Path "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache"

# Edge Cache
Confirm-Cleanup `
    -Title "Edge Cache" `
    -Path "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache"

# Firefox Cache
Confirm-Cleanup `
    -Title "Firefox Cache" `
    -Path "$env:LOCALAPPDATA\Mozilla\Firefox\Profiles"

# Recycle Bin
Write-Host ""
$ans = Read-Host "Empty Recycle Bin ? [Enter/Y/N]"

if ([string]::IsNullOrWhiteSpace($ans) -or $ans -match "^(y|yes)$") {
    Clear-RecycleBin -Force
}

Write-Host ""
Write-Host "Cleanup Finished." -ForegroundColor Green
```
