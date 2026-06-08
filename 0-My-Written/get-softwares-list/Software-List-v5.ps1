# Script to generate categorized software list for batch reinstallation (winget/choco)
$List = @()

# 1. Manual installations (Registry)
$List += Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" | 
    Select-Object DisplayName, DisplayVersion, Publisher, @{Name="Category";Expression={"Manual"}}
$List += Get-ItemProperty "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" | 
    Select-Object DisplayName, DisplayVersion, Publisher, @{Name="Category";Expression={"Manual"}}
$List += Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" | 
    Select-Object DisplayName, DisplayVersion, Publisher, @{Name="Category";Expression={"Manual"}}

# 2. Microsoft Store applications
try {
    $List += Get-AppxPackage -AllUsers | 
        Select-Object @{N='DisplayName';E={$_.Name}}, @{N='DisplayVersion';E={$_.Version}}, @{N='Publisher';E={$_.Publisher}}, @{N='Category';E={"Microsoft Store"}}
} catch {}

# 3. Chocolatey packages (if installed)
if (Get-Command choco -ErrorAction SilentlyContinue) {
    try {
        $chocoList = choco list -l --json | ConvertFrom-Json
        $chocoList | ForEach-Object {
            [PSCustomObject]@{
                DisplayName = $_.Name
                DisplayVersion = $_.Version
                Publisher = "Chocolatey"
                Category = "Choco"
                PackageId = $_.Name
            }
        }
    } catch {}
}

# 4. Scoop packages (if installed)
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
                    PackageId = $parts[0]
                }
            }
        }
        $scoopList
    } catch {}
}

# 5. Winget packages (if installed)
if (Get-Command winget -ErrorAction SilentlyContinue) {
    try {
        $wingetList = winget list --format json | ConvertFrom-Json
        $wingetList | ForEach-Object {
            [PSCustomObject]@{
                DisplayName = $_.Name
                DisplayVersion = $_.Version
                Publisher = $_.Publisher
                Category = "Winget"
                PackageId = $_.Id
            }
        }
    } catch {}
}

# 6. Filter and sort results
$FinalList = $List | Where-Object { $_.DisplayName -ne $null } | 
    Sort-Object Category, DisplayName

# 7. Save categorized list to current directory as Markdown
$CurrentDir = Get-Location
$FilePath = Join-Path $CurrentDir "Complete_Software_List.md"

# Generate categorized Markdown output with reinstallation identifiers
$FinalList | Group-Object Category | ForEach-Object {
    $category = $_.Name
    $entries = $_.Group | ForEach-Object -Begin { $i = 0 } -Process {
        $i++
        $id = $_.PackageId
        $name = $_.DisplayName
        $version = $_.DisplayVersion
        
        if ($category -eq "Winget") {
            "$i. $id ($name) ($version)"
        }
        elseif ($category -eq "Choco" -or $category -eq "Scoop") {
            "$i. $id ($version)"
        }
        else {
            "$i. $name ($version)"
        }
    }
    
    # Create category header with reinstallation commands
    "### $category Softwares:"
    $entries
    "--------------------------------------------------"
} | Out-File -FilePath $FilePath -Encoding UTF8

# Confirmation message
Write-Host "----------------------------------------"
Write-Host "Complete software list created successfully!"
Write-Host "File saved to: $FilePath"
Write-Host "----------------------------------------"