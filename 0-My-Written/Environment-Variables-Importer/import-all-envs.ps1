# ================================================
# Script for Import All  Environment Variables Except MACHINE(SYSTEM) PATH and USER PATH
# File:
# "H:\Repo\powershell-scripting\0-My-Written\Environment-Variables-Importer\Environment-Variables.txt"
# ================================================

$backupPath = "H:\Repo\powershell-scripting\0-My-Written\Environment-Variables-Importer\Environment-Variables.txt"

# بررسی وجود فایل
if (-not (Test-Path $backupPath)) {
    Write-Host "❌ Environment Variables File Not Founded" -ForegroundColor Red
    Write-Host "Path: $backupPath" -ForegroundColor Yellow
    exit
}

Write-Host "✅ Environment Variables File Founded, Importing Starts:..." -ForegroundColor Green

# خواندن فایل و تبدیل به هشتیبل
$content = Get-Content $backupPath -Encoding UTF8
$envHash = @{}

# اسکیپ خط اول (---- ----) و پردازش خطوط
$skipHeader = $false
foreach ($line in $content) {
    # رد کردن خطوط جداکننده و هدر
    if ($line -match "^----" -or $line -match "^Name\s+Value" -or $line.Trim() -eq "") {
        $skipHeader = $true
        continue
    }
    
    # پردازش خطوط حاوی Name و Value
    if ($line -match "^(?<Name>[A-Za-z_][A-Za-z0-9_]*)\s+(?<Value>.+)$") {
        $name = $matches['Name'].Trim()
        $value = $matches['Value'].Trim()
        
        # حذف نقل قول‌های اضافی اگر وجود داشته باشد
        $value = $value -replace '^"|"$', ''
        
        # ذخیره در هشتیبل
        $envHash[$name] = $value
    }
}

Write-Host "📊 Founded  Environment Variables: $($envHash.Count)" -ForegroundColor Cyan

# ================================================
# بازگردانی متغیرها (به جز PATH که جداگانه مدیریت می‌شود)
# ================================================

# لیست متغیرهای سیستمی که نباید تغییر کنند (فقط خواندنی)
$systemReadOnly = @(
    "ALLUSERSPROFILE", "CommonProgramFiles", "CommonProgramFiles(x86)", 
    "CommonProgramW6432", "COMPUTERNAME", "ComSpec", "HOMEDRIVE", 
    "HOMEPATH", "NUMBER_OF_PROCESSORS", "OS", "PROCESSOR_ARCHITECTURE",
    "PROCESSOR_IDENTIFIER", "PROCESSOR_LEVEL", "PROCESSOR_REVISION",
    "ProgramData", "ProgramFiles", "ProgramFiles(x86)", "ProgramW6432",
    "PUBLIC", "SystemDrive", "SystemRoot", "USERDOMAIN", "USERNAME",
    "windir"
)

$skippedCount = 0
$restoredCount = 0

foreach ($name in $envHash.Keys) {
    $value = $envHash[$name]
    
    # اسکیپ متغیرهای PATH (چون جداگانه مدیریت می‌شوند)
    if ($name -eq "PATH" -or $name -eq "Path" -or $name -eq "PSModulePath") {
        Write-Host "⏩ Skipp: $name (Need Extra Process)" -ForegroundColor Cyan
        $skippedCount++
        continue
    }
    
    # اسکیپ متغیرهای فقط خواندنی سیستم
    if ($name -in $systemReadOnly) {
        Write-Host "⏩ Skipped Read Only Environment Variables: $name" -ForegroundColor Cyan
        $skippedCount++
        continue
    }
    
    # اسکیپ متغیرهای موقتی و جلسه (Session)
    if ($name -in @("TEMP", "TMP", "asl.log", "WSLENV", "WT_SESSION", "WT_PROFILE_ID", "VIRTUAL_ENV", "VIRTUAL_ENV_PROMPT")) {
        Write-Host "⏩ Skipped Temp/Session Environment Variables: $name" -ForegroundColor Cyan
        $skippedCount++
        continue
    }
    
    # تنظیم متغیر برای کاربر جاری (User)
    try {
        [Environment]::SetEnvironmentVariable($name, $value, [EnvironmentVariableTarget]::User)
        Write-Host "✅ Imported Succesfully: $name = $value" -ForegroundColor Green
        $restoredCount++
    }
    catch {
        Write-Host "❌ Error when Import: $name : $_" -ForegroundColor Red
    }
}

# ================================================
# بازگردانی PATH کاربر (در صورت وجود در فایل)
# ================================================
if ($envHash.ContainsKey("PATH")) {
    Write-Host "`n📁 Importing USER PATH..." -ForegroundColor Cyan
    $userPath = $envHash["PATH"]
    [Environment]::SetEnvironmentVariable("PATH", $userPath, [EnvironmentVariableTarget]::User)
    Write-Host "✅ USER PATH Imported Succesfully" -ForegroundColor Green
}

# ================================================
# بازگردانی PSModulePath (در صورت وجود در فایل)
# ================================================
if ($envHash.ContainsKey("PSModulePath")) {
    Write-Host "`n📁 Importing: PSModulePath..." -ForegroundColor Cyan
    $modulePath = $envHash["PSModulePath"]
    [Environment]::SetEnvironmentVariable("PSModulePath", $modulePath, [EnvironmentVariableTarget]::User)
    Write-Host "✅ PSModulePath Imported Succesfully" -ForegroundColor Green
}

# ================================================
# گزارش نهایی
# ================================================
Write-Host "`n" + ("="*50) -ForegroundColor White
Write-Host "📊 Final Report:" -ForegroundColor Cyan
Write-Host "✅ Imported Env Vars: $restoredCount" -ForegroundColor Green
Write-Host "⏩ Skipped Env Vars: $skippedCount" -ForegroundColor Cyan
Write-Host "="*50 -ForegroundColor White

Write-Host "`n⚠️ Warning: Restart System to Applied Changes." -ForegroundColor Magenta