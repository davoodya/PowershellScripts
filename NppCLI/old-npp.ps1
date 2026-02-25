function npp {
    param(
        [switch]$d,
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Paths
    )

    $exe = "C:\Program Files\Notepad++\notepad++.exe"

    # اگر هیچ آرگومانی داده نشد
    if (-not $Paths -or $Paths.Count -eq 0) {
        & $exe
        return
    }

    $resolvedFiles = @()

    if ($d) {
        foreach ($path in $Paths) {
            if (Test-Path $path -PathType Container) {
                $files = Get-ChildItem -Path $path -File | Select-Object -ExpandProperty FullName
                $resolvedFiles += $files
            }
            else {
                Write-Warning "Directory not found: $path"
            }
        }
    }
    else {
        foreach ($path in $Paths) {

            # اگر وجود دارد
            if (Test-Path $path) {
                $resolvedFiles += (Resolve-Path $path).Path
            }
            else {
                # اگر وجود ندارد → بساز
                try {
                    New-Item -Path $path -ItemType File -Force | Out-Null
                    $resolvedFiles += (Resolve-Path $path).Path
                }
                catch {
                    Write-Warning "Could not create file: $path"
                }
            }
        }
    }

    if ($resolvedFiles.Count -gt 0) {
        & $exe @resolvedFiles
    }
}