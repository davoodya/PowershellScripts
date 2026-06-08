@echo off
setlocal

:: --- Configuration ---
set "VPN_NAME=ik1.foxup.xyz_2"
set "DNS1=178.22.122.100"
set "DNS2=185.51.200.2"

echo ============================
echo Checking existing VPN connections...
echo ============================

:: Check if VPN is already connected
rasdial | findstr /C:"%VPN_NAME%" >nul
if %ERRORLEVEL% EQU 0 (
    echo 🔌 VPN %VPN_NAME% is already connected.
    echo Disconnecting current VPN session...
    rasdial "%VPN_NAME%" /disconnect
    timeout /t 3 > nul
)

echo ============================
echo Connecting to VPN: %VPN_NAME%
echo ============================

rasdial "%VPN_NAME%"
if %ERRORLEVEL% NEQ 0 (
    echo Failed to connect to VPN %VPN_NAME%.
    pause
    exit /b 1
)
echo VPN connected successfully.

:: Wait for the interface to be fully initialized
timeout /t 5 > nul

:: Set DNS using PowerShell
echo ============================
echo Setting DNS on interface: %VPN_NAME%
echo ============================

powershell -Command ^
 "Set-DnsClientServerAddress -InterfaceAlias '%VPN_NAME%' -ServerAddresses ('%DNS1%', '%DNS2%');" ^
 "Get-DnsClientServerAddress -InterfaceAlias '%VPN_NAME%' | Format-Table InterfaceAlias, ServerAddresses -AutoSize"

echo ============================
echo DNS configured successfully.
pause
endlocal
