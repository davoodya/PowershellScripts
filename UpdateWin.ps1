# ==========================
# Temporary Windows Update Script
# By Davood (YakuzaCyberSec)
# ==========================

Write-Host "Setting Windows Update service to Manual..." -ForegroundColor Cyan
Set-Service -Name wuauserv -StartupType Manual

Write-Host "Starting Windows Update service..." -ForegroundColor Cyan
Start-Service -Name wuauserv

Start-Sleep -Seconds 3

# ---- Method 1: Try PowerShell Windows Update Module ----
try {
    Import-Module PSWindowsUpdate -ErrorAction Stop
    Write-Host "Checking for updates (PSWindowsUpdate)..." -ForegroundColor Yellow
    
    Get-WindowsUpdate -Install -AcceptAll -IgnoreReboot
}
catch {
    Write-Host "PSWindowsUpdate module not available, using UsoClient..." -ForegroundColor Red
    
    # ---- Method 2: USO Client Fallback ----
    Write-Host "Checking for updates..." -ForegroundColor Yellow
    UsoClient StartScan
    Start-Sleep -Seconds 10

    Write-Host "Downloading updates..." -ForegroundColor Yellow
    UsoClient StartDownload
    Start-Sleep -Seconds 10

    Write-Host "Installing updates..." -ForegroundColor Yellow
    UsoClient StartInstall
}

Write-Host "Waiting for update operations to finish..." -ForegroundColor Cyan
Start-Sleep -Seconds 15

Write-Host "Stopping Windows Update service..." -ForegroundColor Cyan
Stop-Service -Name wuauserv -Force

Write-Host "Disabling Windows Update service..." -ForegroundColor Cyan
Set-Service -Name wuauserv -StartupType Disabled

Write-Host "`nAll done! Windows Update completed safely." -ForegroundColor Green
