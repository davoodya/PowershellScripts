# اسکریپت برای دریافت لیست کامل نرم‌افزارها با دسته‌بندی
$List = @()

# 1. نرم‌افزارهای دستی (Registry)
$List += Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" | 
    Select-Object DisplayName, DisplayVersion, Publisher, @{Name="Category";Expression={"Manual"}}
$List += Get-ItemProperty "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" | 
    Select-Object DisplayName, DisplayVersion, Publisher, @{Name="Category";Expression={"Manual"}}
$List += Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" | 
    Select-Object DisplayName, DisplayVersion, Publisher, @{Name="Category";Expression={"Manual"}}

# 2. نرم‌افزارهای Microsoft Store
try {
    $List += Get-AppxPackage -AllUsers | 
        Select-Object @{N='DisplayName';E={$_.Name}}, @{N='DisplayVersion';E={$_.Version}}, @{N='Publisher';E={$_.Publisher}}, @{N='Category';E={"Microsoft Store"}}
} catch {}

# 3. نرم‌افزارهای Chocolatey (اگر نصب باشد)
if (Get-Command choco -ErrorAction SilentlyContinue) {
    try {
        $chocoList = choco list -l --json | ConvertFrom-Json
        $chocoList | ForEach-Object {
            [PSCustomObject]@{
                DisplayName = $_.Name
                DisplayVersion = $_.Version
                Publisher = "Chocolatey"
                Category = "Choco"
            }
        }
    } catch {}
}

# 4. نرم‌افزارهای Scoop (اگر نصب باشد)
if (Get-Command scoop -ErrorAction SilentlyContinue) {
    try {
        $scoopList = scoop list | Select-Object -Skip 1 | ForEach-Object {
            $parts = $_ -split '\s{2,}'
            if ($parts.Count -ge 2) {
                [PSCustomObject]@{
                    DisplayName = $parts[0]
                    DisplayVersion = $parts[1]
                    Publisher = "Scoop"
                    Category = "Scoop"
                }
            }
        }
        $scoopList
    } catch {}
}

# 5. نرم‌افزارهای Winget (اگر نصب باشد)
if (Get-Command winget -ErrorAction SilentlyContinue) {
    try {
        $wingetList = winget list --format json | ConvertFrom-Json
        $wingetList | ForEach-Object {
            [PSCustomObject]@{
                DisplayName = $_.Name
                DisplayVersion = $_.Version
                Publisher = $_.Publisher
                Category = "Winget"
            }
        }
    } catch {}
}

# 6. فیلتر و مرتب‌سازی
$FinalList = $List | Where-Object { $_.DisplayName -ne $null } | 
    Sort-Object Category, DisplayName

# 7. ذخیره لیست با دسته‌بندی
$DesktopPath = [Environment]::GetFolderPath("Desktop")
$FilePath = Join-Path $DesktopPath "Complete_Software_List.txt"

# ایجاد فایل با دسته‌بندی
$FinalList | Group-Object Category | ForEach-Object {
    $category = $_.Name
    $entries = $_.Group | ForEach-Object { "$($_.DisplayName) ($($_.DisplayVersion))" }
    
    # ساخت هدر دسته‌بندی
    "$($category) Softwares:"
    $entries
    ""
} | Out-File -FilePath $FilePath -Encoding UTF8

# پیام تأیید
Write-Host "----------------------------------------"
Write-Host "لیست کامل با دسته‌بندی با موفقیت ساخته شد!"
Write-Host "مسیر فایل: $FilePath"
Write-Host "----------------------------------------"