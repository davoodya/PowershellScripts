<#
.SYNOPSIS
    جستجو در GitHub Repository ها با استفاده از GitHub CLI

.DESCRIPTION
    این فانکشن امکان جستجو در ریپازیتوری‌های GitHub را با دو حالت search و user فراهم می‌کند.
    خروجی می‌تواند به صورت نام کامل، جزییات کامل، یا فقط URL باشد.
    همچنین امکان ذخیره خروجی در فایل با فرمت‌های txt، md و json وجود دارد.

.PARAMETER Query
    عبارت جستجو یا نام کاربری (بسته به Mode)

.PARAMETER Mode
    حالت جستجو: search (جستجوی عمومی) یا user (لیست ریپازیتوری‌های کاربر)

.PARAMETER OutputFormat
    فرمت خروجی: fullname (فقط نام), detailed (جزییات کامل), url (فقط آدرس)

.PARAMETER FileFormat
    فرمت فایل خروجی: txt, md (مارک‌داون), json

.PARAMETER OutputFile
    مسیر فایل خروجی (اختیاری)

.PARAMETER Limit
    حداکثر تعداد نتایج (پیش‌فرض: 100)

.PARAMETER Additional
    پارامترهای اضافی برای ارسال مستقیم به gh command

.EXAMPLE
    Get-GitHubRepos -Query "powershell" -Mode search -OutputFormat fullname

.EXAMPLE
    Get-GitHubRepos -Query "microsoft" -Mode user -OutputFormat detailed -FileFormat md -OutputFile "repos.md"

.EXAMPLE
    Get-GitHubRepos -Query "pentest" -Mode search -OutputFormat url -Additional "created:>2025-01-01 --language powershell" -Limit 20

.EXAMPLE
    Get-GitHubRepos -Query "danielmiessler" -Mode user -OutputFormat fullname -Additional "--sort stars --order desc" -Limit 10
#>

function Get-GitHubRepos {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Query,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("search", "user")]
        [string]$Mode = "search",
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("fullname", "detailed", "url")]
        [string]$OutputFormat = "fullname",
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("txt", "md", "json")]
        [string]$FileFormat = "txt",
        
        [Parameter(Mandatory=$false)]
        [string]$OutputFile = "",
        
        [Parameter(Mandatory=$false)]
        [int]$Limit = 100,
        
        [Parameter(Mandatory=$false)]
        [string]$Additional = "",
        
        [Parameter(Mandatory=$false)]
        [switch]$Help
    )
    
    # نمایش راهنما
    if ($Help) {
        Write-Host @"
`n═══════════════════════════════════════════════════════════════════════════════
                    GitHub Repository Search Tool - راهنمای کامل
═══════════════════════════════════════════════════════════════════════════════

`n【حالت‌های اجرا】`n
  Mode "search"  : جستجوی عمومی در تمام ریپازیتوری‌های GitHub
  Mode "user"    : نمایش ریپازیتوری‌های یک کاربر خاص

`n【پارامترها】`n
  -Query         : عبارت جستجو یا نام کاربری (اجباری)
  -Mode          : حالت جستجو (search/user) - پیش‌فرض: search
  -OutputFormat  : فرمت خروجی (fullname/detailed/url) - پیش‌فرض: fullname
  -FileFormat    : فرمت فایل خروجی (txt/md/json) - پیش‌فرض: txt
  -OutputFile    : مسیر فایل خروجی (اختیاری)
  -Limit         : حداکثر تعداد نتایج - پیش‌فرض: 100
  -Additional    : پارامترهای اضافی برای gh command
  -Help یا -h    : نمایش این راهنما

`n【مثال‌های کاربردی】`n

  ▸ جستجوی ساده ریپازیتوری‌های PowerShell:
    Get-GitHubRepos -Query "powershell" -Mode search -OutputFormat fullname

  ▸ جستجوی پیشرفته با فیلتر تاریخ و زبان:
    Get-GitHubRepos -Query "pentest" -Mode search -OutputFormat detailed `
    -Additional "created:>2025-01-01 --language python" -Limit 20

  ▸ نمایش ریپازیتوری‌های یک کاربر با مرتب‌سازی بر اساس ستاره:
    Get-GitHubRepos -Query "microsoft" -Mode user -OutputFormat detailed `
    -Additional "--sort stars --order desc" -Limit 15

  ▸ ذخیره خروجی مارک‌داون از جستجوی امنیت:
    Get-GitHubRepos -Query "security tools" -Mode search -OutputFormat detailed `
    -FileFormat md -OutputFile "security-tools.md"

  ▸ دریافت فقط URL ریپازیتوری‌های یک تاپیک خاص:
    Get-GitHubRepos -Query "machine-learning" -Mode search -OutputFormat url `
    -Additional "topic:deep-learning --limit 30"

  ▸ ترکیب چند فیلتر در جستجو:
    Get-GitHubRepos -Query "api" -Mode search -OutputFormat detailed `
    -Additional "stars:>100 --language go --sort stars --order desc" -Limit 10

  ▸ جستجو در ریپازیتوری‌های یک سازمان:
    Get-GitHubRepos -Query "google" -Mode user -OutputFormat fullname `
    -Additional "--limit 50"

`n【پارامترهای مفید برای Additional】`n

  در حالت search:
    --language python    : فیلتر بر اساس زبان برنامه‌نویسی
    --stars:>100         : ریپازیتوری‌های با بیش از 100 ستاره
    --created:>2024-01-01: ریپازیتوری‌های ایجاد شده بعد از تاریخ مشخص
    --topic:security     : فیلتر بر اساس topic
    --sort stars         : مرتب‌سازی بر اساس تعداد ستاره
    --order desc         : ترتیب نزولی

  در حالت user:
    --sort stars         : مرتب‌سازی ریپازیتوری‌های کاربر
    --order asc/desc     : ترتیب مرتب‌سازی
    --visibility public  : فقط ریپازیتوری‌های عمومی

`n【پیش‌نیازها】`n
  ⚡ نصب GitHub CLI: https://cli.github.com/
  ⚡ احراز هویت: gh auth login

`n═══════════════════════════════════════════════════════════════════════════════
"@ -ForegroundColor Cyan
        return
    }
    
    # تابع برای فرمت کردن خروجی با PowerShell (بدون استفاده از JQ برای فرمت پیچیده)
    function Format-Output {
        param(
            [array]$Data,
            [string]$Format,
            [string]$FileType
        )
        
        $output = @()
        
        if ($Format -eq "fullname") {
            foreach ($item in $Data) {
                $output += $item.nameWithOwner
            }
        }
        elseif ($Format -eq "url") {
            foreach ($item in $Data) {
                $output += $item.url
            }
        }
        elseif ($Format -eq "detailed") {
            if ($FileType -eq "md") {
                # هدر مارک‌داون
                $output += "| Repository | Description | Stars |"
                $output += "|--------|-------------|-------|"
                
                foreach ($item in $Data) {
                    $desc = $item.description
                    if ([string]::IsNullOrEmpty($desc)) { $desc = "No description" }
                    # پاک کردن کاراکترهای خاص برای مارک‌داون
                    $desc = $desc -replace '\|', '\\|' -replace "\n", " "
                    $output += "| [$($item.nameWithOwner)]($($item.url)) | $desc | $($item.stargazerCount) |"
                }
            }
            else {
                # فرمت متنی ساده
                foreach ($item in $Data) {
                    $output += "Repository: $($item.nameWithOwner)"
                    $desc = $item.description
                    if ([string]::IsNullOrEmpty($desc)) { $desc = "No description" }
                    $output += "Description: $desc"
                    $output += "Stars: $($item.stargazerCount)"
                    $output += "---"
                }
            }
        }
        
        return $output
    }
    
    # اجرای دستور و دریافت JSON
    try {
        # تعیین فیلدهای JSON مورد نیاز
        $jsonFields = switch ($OutputFormat) {
            "fullname" { @("nameWithOwner") }
            "detailed" { @("nameWithOwner", "description", "stargazerCount", "url") }
            "url" { @("url") }
        }
        
        $jsonFieldsStr = $jsonFields -join ','
        
        if ($Mode -eq "search") {
            # ساخت عبارت جستجو با پارامترهای اضافی
            $searchQuery = if ($Additional) { "$Query $Additional" } else { $Query }
            
            # دستور جستجو - دریافت JSON خام
            $command = "gh search repos `"$searchQuery`" --limit $Limit --json $jsonFieldsStr"
        }
        else {
            # Mode user
            $userQuery = $Query
            $additionalParams = if ($Additional) { " $Additional" } else { "" }
            
            # دستور لیست کاربر - دریافت JSON خام
            $command = "gh repo list $userQuery$additionalParams --limit $Limit --json $jsonFieldsStr"
        }
        
        # نمایش command در حال اجرا (برای دیباگ)
        Write-Host "`n🔧 Executing: $command" -ForegroundColor Cyan
        
        # اجرا و دریافت JSON
        $jsonResult = Invoke-Expression $command | ConvertFrom-Json
        
        if ($jsonResult.Count -eq 0) {
            Write-Host "⚠️ No results found for query: $Query" -ForegroundColor Yellow
            return
        }
        
        # فرمت کردن خروجی
        $formattedOutput = Format-Output -Data $jsonResult -Format $OutputFormat -FileType $FileFormat
        
        # ذخیره یا نمایش خروجی
        if ($OutputFile) {
            # برای فایل JSON، خود JSON رو ذخیره کن
            if ($FileFormat -eq "json") {
                $jsonResult | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputFile -Encoding utf8
                Write-Host "✅ JSON output saved to: $OutputFile" -ForegroundColor Green
            }
            else {
                $formattedOutput | Out-File -FilePath $OutputFile -Encoding utf8
                Write-Host "✅ Output saved to: $OutputFile" -ForegroundColor Green
            }
            
            # نمایش پیش‌نمایش
            Write-Host "`n📄 Preview (first 10 lines):" -ForegroundColor Yellow
            $formattedOutput | Select-Object -First 10 | ForEach-Object { Write-Host $_ -ForegroundColor Gray }
            if ($formattedOutput.Count -gt 10) {
                Write-Host "... and $($formattedOutput.Count - 10) more lines" -ForegroundColor Gray
            }
        }
        else {
            # نمایش در کنسول
            $formattedOutput | ForEach-Object { Write-Host $_ }
        }
        
        # نمایش آمار
        Write-Host "`n📊 Total results: $($jsonResult.Count)" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Error: $_" -ForegroundColor Red
        Write-Host "💡 Tip: Make sure GitHub CLI is installed and authenticated" -ForegroundColor Yellow
        Write-Host "   Run 'gh auth login' to authenticate" -ForegroundColor Yellow
    }
}

# Aliases for easier usage
Set-Alias -Name grs -Value Get-GitHubRepos -Scope Global
Set-Alias -Name github-search -Value Get-GitHubRepos -Scope Global



# ============================================================================
# COMMANDES FOR TESTING - کامندهای تست برای بررسی تمام ویژگی‌ها
# ============================================================================

<#
تست 1: نمایش راهنما
.\GHResearcher-Simple2.ps1 -Help

تست 2: جستجوی ساده با فرمت نام کامل
.\GHResearcher-Simple2.ps1 -Query "powershell" -Mode search -OutputFormat fullname -Limit 5

تست 3: تست اصلی که قبلاً خطا می‌داد (حالا باید درست کار کنه)
.\GHResearcher-Simple2.ps1 -Query "Pentest PowerShell" -Mode search -OutputFormat md -OutputFile urls.txt -Limit 5

تست 4: جستجوی پیشرفته با Additional
.\GHResearcher-Simple2.ps1 -Query "pentest" -Mode search -OutputFormat detailed -Additional "created:>2025-01-01 --language powershell" -Limit 5

تست 5: خروجی مارک‌داون با جزییات کامل
.\GHResearcher-Simple2.ps1 -Query "security tools" -Mode search -OutputFormat detailed -FileFormat md -OutputFile "security.md" -Additional "language:python" -Limit 5

تست 6: حالت user با مرتب‌سازی
.\GHResearcher-Simple2.ps1 -Query "microsoft" -Mode user -OutputFormat detailed -Additional "--sort stars --order desc" -Limit 5

تست 7: فقط URL ها با فیلتر topic
.\GHResearcher-Simple2.ps1 -Query "machine-learning" -Mode search -OutputFormat url -Additional "topic:deep-learning" -Limit 5

تست 8: ترکیب چند فیلتر در Additional
.\GHResearcher-Simple2.ps1 -Query "api" -Mode search -OutputFormat detailed -Additional "stars:>50 --language python --sort stars --order desc" -Limit 5

تست 9: تست خروجی JSON
.\GHResearcher-Simple2.ps1 -Query "docker" -Mode search -OutputFormat detailed -FileFormat json -OutputFile "docker-repos.json" -Limit 5

تست 10: تست بدون خروجی فایل (نمایش در کنسول)
.\GHResearcher-Simple2.ps1 -Query "terraform" -Mode search -OutputFormat detailed -Limit 3

تست 11: حالت user با فرمت مارک‌داون
.\GHResearcher-Simple2.ps1 -Query "google" -Mode user -OutputFormat detailed -FileFormat md -OutputFile "google-repos.md" -Limit 5

تست 12: تست با محدودیت کم
.\GHResearcher-Simple2.ps1 -Query "vscode" -Mode search -OutputFormat fullname -Limit 3
#>
