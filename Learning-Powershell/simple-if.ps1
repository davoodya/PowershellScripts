#Version 1:
function wsl-ubuntu {
    if ($args[0] -eq 24) {
        wsl.exe -d Ubuntu-24.04
    }
    elseif ($args[0] -eq 25) {
        wsl.exe -d Ubuntu-25.04
    }
    else {
        Write-Host "استفاده: wsl-ubuntu 24 یا 25"
    }
}
<#
Version 1 Running Method:
wsl-ubuntu 24
wsl-ubuntu 25
#>


# Version 2
function wsl-ubuntu {
    if ($args.Count -lt 1) {
        Write-Host "کاربرد: wsl-ubuntu 24 | 25"
        return
    }

    $ver = [int]$args[0]

    if ($ver -eq 24) {
        wsl.exe -d Ubuntu-24.04
    }
    elseif ($ver -eq 25) {
        wsl.exe -d Ubuntu-25.04
    }
    else {
        Write-Host "فرمت نادرست: فقط 24 یا 25 مجاز است."
    }
}
<#
Version 2 Running Method:
wsl-ubuntu 24
wsl-ubuntu 25
#>


# Version 3: With Parameter
function wsl-ubuntu {
    param(
        [int]$Version      # مقدار 24 یا 25
    )

    if ($Version -eq 24) {
        wsl.exe -d Ubuntu-24.04
    }
    elseif ($Version -eq 25) {
        wsl.exe -d Ubuntu-25.04
    }
    else {
        Write-Host "کاربرد: wsl-ubuntu 24 | 25"
    }
}
<#
Version 3 Running Method:
wsl-ubuntu -Version 24
wsl-ubuntu -Version 25
#OR
wsl-ubuntu 24
wsl-ubuntu 25
#>