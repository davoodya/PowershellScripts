# نصب نرم‌افزارهای Chocolatey
choco install -y $(Get-Content "Complete_Software_List.txt" | Where-Object { $_ -match "Choco Softwares" } | ForEach-Object { $_.Split(' ')[0] })

# نصب نرم‌افزارهای Winget
winget install --id $(Get-Content "Complete_Software_List.txt" | Where-Object { $_ -match "Winget Softwares" } | ForEach-Object { $_.Split(' ')[0] })