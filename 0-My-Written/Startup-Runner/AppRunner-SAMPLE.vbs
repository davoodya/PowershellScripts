' ==========================================
' اسکریپت اجرای خودکار در Startup
' ==========================================

Sub RunHidden(command)
    CreateObject("WScript.Shell").Run command, 0, False
End Sub

' Function for Normal Run 
Sub RunNormal(command)
	CreateObject("WScript.Shell").Run command, 1, False
End Sub

' === AutoHotkey ===
RunHidden """C:\Program Files\AutoHotkey\AutoHotkey.exe"" H:\Repo\Auto-HotKey\autocorrect.ahk"
RunHidden """C:\Program Files\AutoHotkey\AutoHotkey.exe"" H:\Repo\Auto-HotKey\ChangeLangF3.ahk"

' === Java - Burp Suite ===
RunHidden "java -jar ""C:\Apps\HackingSec\BurpsuitePro2026\BurpLoaderKeygen117.jar"""

' === PowerShell Script ===
RunNormal "powershell -windowstyle hidden -file ""H:\Repo\powershell-scripting\0-My-Written\Backuper\backuper.ps1"""

' === Python Script ===
RunHidden "python ""H:\Repo\black_python\mini_projects\modules\tor_connect.py"" -t 60 -cp 645121"

' === دستورات جدید را اینجا اضافه کنید ===
' مثال:
' RunHidden """C:\Program Files\Some App\app.exe"" arg1 arg2"