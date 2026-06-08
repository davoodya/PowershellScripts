' ==========================================
' اسکریپت اجرای خودکار AutoHotkey در Startup
' ==========================================

' تابع اجرای مخفی
Sub RunHidden(command)
    CreateObject("WScript.Shell").Run command, 0, False
End Sub

' Function for Normal Run 
Sub RunNormal(command)
	CreateObject("WScript.Shell").Run command, 1, False
End Sub

' === دستورات خود را اینجا اضافه کنید ===

RunHidden """C:\Program Files\AutoHotkey\AutoHotkey.exe"" H:\Repo\Auto-HotKey\autocorrect.ahk"
RunHidden """C:\Program Files\AutoHotkey\AutoHotkey.exe"" H:\Repo\Auto-HotKey\ChangeLangF3.ahk"
RunNormal "powershell -file ""H:\Repo\powershell-scripting\0-My-Written\Backuper\backuper.ps1"""
' === دستورات جدید را اینجا اضافه کنید ===
' مثال:
' RunHidden """C:\Program Files\SomeApp\app.exe"""