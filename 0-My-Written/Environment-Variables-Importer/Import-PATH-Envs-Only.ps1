# ================================================
# Import USER PATH Environment Variable + MACHINE(SYSTEM) PATH Environment Variable from Files
# Files:
# "H:\Repo\powershell-scripting\0-My-Written\Environment-Variables-Importer\System-PATH-Variables.txt"
# "H:\Repo\powershell-scripting\0-My-Written\Environment-Variables-Importer\User-PATH-Variables.txt"
# ================================================

####----- Step 1: Import USER PATH -----####

# خواندن محتوای فایل بکاپ User PATH
$userPathContent = Get-Content "H:\Repo\powershell-scripting\0-My-Written\Environment-Variables-Importer\User-PATH-Variables.txt" -Raw

# حذف عبارت "PATH-USER:" (اگر در ابتدای فایل وجود دارد)
# $userPathContent = $userPathContent -replace '^PATH-USER:\s*', ''

# تنظیم متغیر PATH برای کاربر جاری (جایگزینی کامل)
[Environment]::SetEnvironmentVariable("PATH", $userPathContent, [EnvironmentVariableTarget]::User)

Write-Host "✅ Environment Variable: USER PATH Imported Succesfully" -ForegroundColor Green


####----- Step 2: Import MACHINE(SYSTEM) PATH -----####
# خواندن محتوای فایل بکاپ Machine PATH (نام فایل را بررسی کنید)
$machinePathContent = Get-Content "H:\Repo\powershell-scripting\0-My-Written\Environment-Variables-Importer\System-PATH-Variables.txt" -Raw

# حذف عبارت "PATH-MACHINE:" (اگر در ابتدای فایل وجود دارد)
# $machinePathContent = $machinePathContent -replace '^PATH-MACHINE:\s*', ''

# تنظیم متغیر PATH برای ماشین (سیستم) - جایگزینی کامل
[Environment]::SetEnvironmentVariable("PATH", $machinePathContent, [EnvironmentVariableTarget]::Machine)

Write-Host "✅ Environment Variable: MACHINE(SYSTEM) PATH Imported Succesfully" -ForegroundColor Green