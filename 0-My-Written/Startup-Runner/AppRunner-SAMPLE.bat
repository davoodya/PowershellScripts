@echo off
:: ==========================================
:: اسکریپت اجرای خودکار در Startup
:: ==========================================

:: === AutoHotkey ===
start /b "" "C:\Program Files\AutoHotkey\AutoHotkey.exe" "H:\Repo\Auto-HotKey\autocorrect.ahk"
start /b "" "C:\Program Files\AutoHotkey\AutoHotkey.exe" "H:\Repo\Auto-HotKey\ChangeLangF3.ahk"

:: === Java - Burp Suite ===
start /b java -jar "C:\Apps\HackingSec\BurpsuitePro2026\BurpLoaderKeygen117.jar"

:: === PowerShell Script ===
start /b powershell -windowstyle hidden -file "H:\Repo\powershell-scripting\0-My-Written\Backuper\backuper.ps1"

:: === Python Script ===
start /b python "H:\Repo\black_python\mini_projects\modules\tor_connect.py" -t 60 -cp 645121

:: === دستورات جدید را اینجا اضافه کنید ===
:: مثال:
:: start /b "C:\Program Files\Some App\app.exe" arg1