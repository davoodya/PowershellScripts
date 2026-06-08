@echo off
setlocal

:: --- Configuration ---
set "VPN_NAME=ik1.foxup.xyz_2"
set "DNS1=178.22.122.100"
set "DNS2=185.51.200.2"

echo ============================
echo Checking existing VPN connections...
echo ============================

:: Check if VPN is already connected, then disconnect
rasdial | findstr /C:"%VPN_NAME%" >nul
if %ERRORLEVEL% EQU 0 (
    echo VPN %VPN_NAME% is already connected.
    echo Disconnecting current VPN session...
    rasdial "%VPN_NAME%" /disconnect
    timeout /t 3 > nul
)

echo ============================

echo ik1.foxup.xyz_2 Disconnected Succesfully.
pause
endlocal
