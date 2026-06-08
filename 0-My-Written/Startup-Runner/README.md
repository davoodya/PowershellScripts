╔══════════════════════════════════════════════════════════════════════╗
║                    راهنمای اضافه کردن دستور جدید                     ║
║                         Startup Script Guide                         ║
╚══════════════════════════════════════════════════════════════════════╝

═══════════════════════════════════════════════════════════════════════
                              فایل‌های موجود
═══════════════════════════════════════════════════════════════════════

  📄 Startup_AHK.vbs    → اجرای مخفی (پیشنهادی)
  📄 Startup_AHK.bat    → اجرای ساده
  📄 README.txt         → این فایل راهنما

═══════════════════════════════════════════════════════════════════════
                         نحوه اضافه کردن دستور جدید
═══════════════════════════════════════════════════════════════════════

▸ در فایل VBS:
───────────────────────────────────────────────────────────────────────
  الگو:
    RunHidden """مسیر_برنامه"" آرگومان‌ها"

  مثال:
    RunHidden """C:\Program Files\New App\app.exe"" -arg1 value"

  اگر مسیر Space دارد:
    RunHidden """C:\Program Files\My App\app.exe"" -arg1"

  اگر مسیر Space ندارد:
    RunHidden "C:\Program Files\New App\app.exe -arg1"
	
Note: "" "" in the VBS is " " 
in VBS: RunHidden "powershell -file ""C:\Program Files\New App\app.ps1"""
in Python: "powershell -file 'C:\Program Files\New App\app.ps1'"

▸ در فایل BAT:
───────────────────────────────────────────────────────────────────────
  الگو:
    start /b "مسیر_برمابه" آرگومان‌ها

  مثال:
    start /b "C:\Program Files\New App\app.exe" -arg1 value

  اگر مسیر Space دارد:
    start /b "C:\Program Files\My App\app.exe" -arg1

  اگر مسیر Space ندارد:
    start /b C:\Program Files\New App\app.exe -arg1

═══════════════════════════════════════════════════════════════════════
                           مدیریت Space در مسیرها
═══════════════════════════════════════════════════════════════════════

  در VBS:    ۳ تا " در ابتدا و انتهای مسیر
             """C:\Program Files\My App\app.exe"""

  در BAT:    ۲ تا " در ابتدا و انتهای مسیر
             "C:\Program Files\My App\app.exe"

═══════════════════════════════════════════════════════════════════════
                    تفاوت اجرای مخفی و معمولی (فقط VBS)
═══════════════════════════════════════════════════════════════════════

  اجرای مخفی (همین فایل):
    RunHidden "command"
    → پنجره نمایش داده نمی‌شود

  اجرای معمولی:
    CreateObject("WScript.Shell").Run "command", 1, False
    → پنجره نمایش داده می‌شود

═══════════════════════════════════════════════════════════════════════
                           مثال‌های آماده
═══════════════════════════════════════════════════════════════════════

  ۱. اجرای یک برنامه ساده:
     VBS:  RunHidden "notepad.exe"
     BAT:  start /b notepad.exe

  ۲. اجرای برنامه با مسیر دارای Space:
     VBS:  RunHidden """C:\Program Files\My App\app.exe"""
     BAT:  start /b "C:\Program Files\My App\app.exe"

  ۳. اجرای اسکریپت Python:
     VBS:  RunHidden "python ""H:\Scripts\test.py"" -arg1"
     BAT:  start /b python "H:\Scripts\test.py" -arg1

  ۴. اجرای اسکریپت PowerShell:
     VBS:  RunHidden "powershell -windowstyle hidden -file ""H:\Scripts\script.ps1"""
     BAT:  start /b powershell -windowstyle hidden -file "H:\Scripts\script.ps1"

  ۵. اجرای Java JAR:
     VBS:  RunHidden "java -jar ""C:\Apps\app.jar"""
     BAT:  start /b java -jar "C:\Apps\app.jar"

═══════════════════════════════════════════════════════════════════════
                              نکات مهم
═══════════════════════════════════════════════════════════════════════

  ✓ برای اجرای مخفی از VBS استفاده کنید
  ✓ برای سادگی از BAT استفاده کنید
  ✓ همیشه مسیرهای دارای Space را در " " قرار دهید
  ✓ فایل را در پوشه Startup قرار دهید:
    shell:startup

═══════════════════════════════════════════════════════════════════════

═══════════════════════════════════════════════════════════════════════
                              VBS Run Type
═══════════════════════════════════════════════════════════════════════
in VBS:
' روش ۱: اجرای معمولی (پنجره نمایش داده می‌شود)
CreateObject("WScript.Shell").Run "notepad.exe", 1, False

' روش ۲: اجرای مخفی (پنجره مخفی)
CreateObject("WScript.Shell").Run "notepad.exe", 0, False

' روش ۳: اجرای کمینه (در تسکبار)
CreateObject("WScript.Shell").Run "notepad.exe", 2, False


0 => مخفی
1 => معمولی (نرمال)
2 => کمینه (Minimized)
3 => بزرگ‌نمایی (Maximized)
4 => حالت معمولی (فعال)
5 => فعال اما کمینه
	
