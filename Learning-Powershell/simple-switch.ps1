function wsl-ubuntu {
    <#
    .SYNOPSIS
        راه‌اندازی نسخه‌های مخصوص Ubuntu در WSL بر اساس ورودی عددی.

    .PARAMETER Version
        عدد 24 یا 25 که نشان‌دهنده نسخهٔ مطلوب است:
        - 24  →  Ubuntu‑24.04
        - 25  →  Ubuntu‑25.04

    .EXAMPLE
        wsl-ubuntu 24   # اجرای wsl.exe -d Ubuntu-24.04

    .EXAMPLE
        wsl-ubuntu 25   # اجرای wsl.exe -d Ubuntu-25.04
    #>

    param(
        [Parameter(Mandatory = $true]
        [ValidateSet("24","25", "26")]
        [string]$Version
    )

    switch ($Version) {
        "24" { wsl.exe -d Ubuntu-24.04 }
        "25" { wsl.exe -d Ubuntu-25.04 }
		"26"{
			wsl.exe -d Ubuntu-26.04
		}
    }
}