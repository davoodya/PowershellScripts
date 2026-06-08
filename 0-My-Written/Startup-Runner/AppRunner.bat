@echo off
:: ==========================================
:: اسکریپت اجرای خودکار AutoHotkey در Startup
:: ==========================================

:: اجرای مخفی با start /b
start /b "" "C:\Program Files\AutoHotkey\AutoHotkey.exe" "H:\Repo\Auto-HotKey\autocorrect.ahk"
start /b "" "C:\Program Files\AutoHotkey\AutoHotkey.exe" "H:\Repo\Auto-HotKey\ChangeLangF3.ahk"

:: === دستورات جدید را اینجا اضافه کنید ===
:: مثال:
:: start /b "" "C:\Program Files\SomeApp\app.exe"