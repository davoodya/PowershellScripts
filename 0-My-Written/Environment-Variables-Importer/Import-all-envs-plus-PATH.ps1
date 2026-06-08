# ================================================
# Import All  Environment Variables + USER PATH Environment Variable + MACHINE(SYSTEM)  Environment Variables
# Include: PATH_USER, PATH_MACHINE and Other  Environment Variables
# Files:
# "H:\Repo\powershell-scripting\0-My-Written\Environment-Variables-Importer\System-PATH-Variables.txt"
# "H:\Repo\powershell-scripting\0-My-Written\Environment-Variables-Importer\User-PATH-Variables.txt"
# "H:\Repo\powershell-scripting\0-My-Written\Environment-Variables-Importer\Environment-Variables.txt"
# ================================================

$basePath = "H:\Repo\powershell-scripting\0-My-Written\Environment-Variables-Importer\"

# مسیر فایل‌ها
$userPathFile = Join-Path $basePath "User-PATH-Variables.txt"
$machinePathFile = Join-Path $basePath "System-PATH-Variables.txt"
$otherVarsFile = Join-Path $basePath "Environment-Variables.txt"

Write-Host "🔧 شروع فرآیند بازگردانی متغیرهای محیطی..." -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor White

# ================================================
# 1. بازگردانی PATH_USER
# ================================================
if (Test-Path $userPathFile) {
    Write-Host "`n📁 Import PATH_USER..." -ForegroundColor Yellow
    $userPathContent = Get-Content $userPathFile -Raw -Encoding UTF8
    # حذف "PATH-USER:" اگر در ابتدای فایل وجود دارد
    # $userPathContent = $userPathContent -replace '^PATH-USER:\s*', ''
    # حذف کاراکترهای اضافی (مثل نقل قول)
    $userPathContent = $userPathContent -replace '^"|"$', ''
    
    try {
        [Environment]::SetEnvironmentVariable("PATH", $userPathContent, [EnvironmentVariableTarget]::User)
        Write-Host "✅ PATH_USER Imported Succesfully" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Error when Import PATH_USER: $_" -ForegroundColor Red
    }
} else {
    Write-Host "⚠PATH_USER File Not Founded: $userPathFile" -ForegroundColor Red
}

# ================================================
# 2. بازگردانی PATH_MACHINE (نیاز به ادمین)
# ================================================
if (Test-Path $machinePathFile) {
    Write-Host "`n📁 Import PATH_MACHINE..." -ForegroundColor Yellow
    $machinePathContent = Get-Content $machinePathFile -Raw -Encoding UTF8
    # حذف "PATH-MACHINE:" اگر در ابتدای فایل وجود دارد
    # $machinePathContent = $machinePathContent -replace '^PATH-MACHINE:\s*', ''
    $machinePathContent = $machinePathContent -replace '^"|"$', ''
    
    try {
        [Environment]::SetEnvironmentVariable("PATH", $machinePathContent, [EnvironmentVariableTarget]::Machine)
        Write-Host "✅ PATH_MACHINE Imported Succesfully" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Error when Import PATH_MACHINE: $_" -ForegroundColor Red
        Write-Host "   (You Should Run PowerShell As Administrator.)" -ForegroundColor Magenta
    }
} else {
    Write-Host "⚠️ PATH_MACHINE File Not Founded: $machinePathFile" -ForegroundColor Red
}

# ================================================
# 3. بازگردانی سایر متغیرهای محیطی
# ================================================
if (Test-Path $otherVarsFile) {
    Write-Host "`n📁 Import Other Environment Variables" -ForegroundColor Yellow
    
    $content = Get-Content $otherVarsFile -Encoding UTF8
    $envHash = @{}
    
    # پردازش فایل جدول
    foreach ($line in $content) {
        if ($line -match "^----" -or $line -match "^Name\s+Value" -or $line.Trim() -eq "") {
            continue
        }
        if ($line -match "^(?<Name>[A-Za-z_][A-Za-z0-9_]*)\s+(?<Value>.+)$") {
            $name = $matches['Name'].Trim()
            $value = $matches['Value'].Trim()
            $value = $value -replace '^"|"$', ''
            $envHash[$name] = $value
        }
    }
    
    # لیست متغیرهای فقط خواندنی و سیستمی که نباید تغییر کنند
    $skipVariables = @(
        "ALLUSERSPROFILE", "CommonProgramFiles", "CommonProgramFiles(x86)", "CommonProgramW6432",
        "COMPUTERNAME", "ComSpec", "HOMEDRIVE", "HOMEPATH", "NUMBER_OF_PROCESSORS", "OS",
        "PROCESSOR_ARCHITECTURE", "PROCESSOR_IDENTIFIER", "PROCESSOR_LEVEL", "PROCESSOR_REVISION",
        "ProgramData", "ProgramFiles", "ProgramFiles(x86)", "ProgramW6432", "PUBLIC",
        "SystemDrive", "SystemRoot", "USERDOMAIN", "USERNAME", "windir",
        "PATH", "Path", "PSModulePath", "TEMP", "TMP", "asl.log", "WSLENV", 
        "WT_SESSION", "WT_PROFILE_ID", "VIRTUAL_ENV", "VIRTUAL_ENV_PROMPT", "_OLD_VIRTUAL_PATH"
    )
    
    $restoredCount = 0
    foreach ($name in $envHash.Keys) {
        if ($name -in $skipVariables) {
            Write-Host "⏩ Excepting $name" -ForegroundColor DarkYellow
            continue
        }
        
        $value = $envHash[$name]
        try {
            [Environment]::SetEnvironmentVariable($name, $value, [EnvironmentVariableTarget]::User)
            Write-Host "✅ $name = $value" -ForegroundColor Green
            $restoredCount++
        }
        catch {
            Write-Host "❌ Error when Excepting: $name : $_" -ForegroundColor Red
        }
    }
    Write-Host "📊 Number of Imported Environments: $restoredCount" -ForegroundColor Cyan
} else {
    Write-Host "⚠️ Other Environment Variables File Not Founded: $otherVarsFile" -ForegroundColor Red
}

# ================================================
# گزارش نهایی
# ================================================
Write-Host "`n================================================" -ForegroundColor White
Write-Host "✅ All  Environment Variables Imported Succesfully" -ForegroundColor Green
Write-Host "⚠️ Restart System for Apply Changes. " -ForegroundColor Magenta
Write-Host "================================================" -ForegroundColor White