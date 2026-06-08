if not %errorlevel%==0 (
    rem Not elevated: try to relaunch as Administrator via UAC
    if "%*"=="" (
        powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    ) else (
        powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -ArgumentList '%*' -Verb RunAs"
    )
    if errorlevel 1 (
        echo This script must be run as Administrator.
        echo Please right-click on this script and select 'Run as Administrator'.
        pause
        exit /b
    )
    exit /b
)