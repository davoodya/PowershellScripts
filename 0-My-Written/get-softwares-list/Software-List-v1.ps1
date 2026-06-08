$List = @()

# 1. دریافت برنامه‌های معمولی (Registry 32-bit & 64-bit)
$List += Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" | Select-Object DisplayName, DisplayVersion, Publisher
$List += Get-ItemProperty "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" | Select-Object DisplayName, DisplayVersion, Publisher
$List += Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" | Select-Object DisplayName, DisplayVersion, Publisher

# 2. دریافت برنامه‌های Microsoft Store (Appx/MSIX)
try {
    $List += Get-AppxPackage -AllUsers | Select-Object @{N='DisplayName';E={$_.Name}}, @{N='DisplayVersion';E={$_.Version}}, @{N='Publisher';E={$_.Publisher}}
} catch {
    # اگر دسترسی وجود نداشت خطا ندهد
}

# 3. حذف موارد خالی و مرتب‌سازی
$FinalList = $List | Where-Object { $_.DisplayName -ne $null } | Sort-Object DisplayName -Unique

# 4. ذخیره در فایل متنی روی دسکتاپ
$DesktopPath = [Environment]::GetFolderPath("Desktop")
$FilePath = Join-Path $DesktopPath "Complete_Software_List.txt"

$FinalList | Out-File -FilePath $FilePath -Encoding UTF8

# پیام پایان
Write-Host "----------------------------------------"
Write-Host "لیست کامل با موفقیت ساخته شد."
Write-Host "مسیر فایل: $FilePath"
Write-Host "----------------------------------------"