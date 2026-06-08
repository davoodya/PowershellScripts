@echo off
setlocal

:: --- Configuration ---
set "VPN_NAME=ik1.foxup.xyz_2"


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

pause
endlocal
