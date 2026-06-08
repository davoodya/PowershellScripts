# اسکریپت برای دریافت لیست کامل نرم‌افزارها (شامل Microsoft Store، Chocolatey، Scoop، Winget و نصب‌های معمولی)
$List = @()

# 1. نرم‌افزارهای نصب‌شده از طریق رجیستری (دستی)
$List += Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" | Select-Object DisplayName, DisplayVersion, Publisher
$List += Get-ItemProperty "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" | Select-Object DisplayName, DisplayVersion, Publisher
$List += Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" | Select-Object DisplayName, DisplayVersion, Publisher

# 2. نرم‌افزارهای Microsoft Store (Appx)
try {
    $List += Get-AppxPackage -AllUsers | Select-Object @{N='DisplayName';E={$_.Name}}, @{N='DisplayVersion';E={$_.Version}}, @{N='Publisher';E={$_.Publisher}}
} catch {}

# 3. نرم‌افزارهای نصب‌شده از Chocolatey (اگر نصب باشد)
if (Get-Command choco -ErrorAction SilentlyContinue) {
    try {
        $chocoList = choco list -l --json | ConvertFrom-Json
        $chocoList | ForEach-Object {
            [PSCustomObject]@{
                DisplayName = $_.Name
                DisplayVersion = $_.Version
                Publisher = "Chocolatey"
            }
        }
    } catch {}
}

# 4. نرم‌افزارهای نصب‌شده از Scoop (اگر نصب باشد)
if (Get-Command scoop -ErrorAction SilentlyContinue) {
    try {
        $scoopList = scoop list | Select-Object -Skip 1 | ForEach-Object {
            $parts = $_ -split '\s{2,}'
            if ($parts.Count -ge 2) {
                [PSCustomObject]@{
                    DisplayName = $parts[0]
                    DisplayVersion = $parts[1]
                    Publisher = "Scoop"
                }
            }
        }
        $scoopList
    } catch {}
}

# 5. نرم‌افزارهای نصب‌شده از Winget (اگر نصب باشد)
if (Get-Command winget -ErrorAction SilentlyContinue) {
    try {
        $wingetList = winget list --format json | ConvertFrom-Json
        $wingetList | ForEach-Object {
            [PSCustomObject]@{
                DisplayName = $_.Name
                DisplayVersion = $_.Version
                Publisher = $_.Publisher
            }
        }
    } catch {}
}

# 6. حذف موارد خالی و مرتب‌سازی
$FinalList = $List | Where-Object { $_.DisplayName -ne $null } | Sort-Object DisplayName -Unique

# 7. ذخیره لیست در فایل متنی روی دسکتاپ
$DesktopPath = [Environment]::GetFolderPath("Desktop")
$FilePath = Join-Path $DesktopPath "Complete_Software_List.txt"
$FinalList | Format-Table -AutoSize | Out-File -FilePath $FilePath -Encoding UTF8

# پیام تأیید
Write-Host "----------------------------------------"
Write-Host "لیست کامل با موفقیت ساخته شد!"
Write-Host "مسیر فایل: $FilePath"
Write-Host "----------------------------------------"