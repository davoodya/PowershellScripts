# Quick ASCII compliance check for all NppCLI module source files.
# Usage: pwsh -NoProfile -ExecutionPolicy Bypass -File _ascii_check.ps1

$files = @(
    (Join-Path $PSScriptRoot 'NppCLI.psm1'),
    (Join-Path $PSScriptRoot 'NppCLI.psd1'),
    (Join-Path $PSScriptRoot 'Private' 'Config.ps1'),
    (Join-Path $PSScriptRoot 'Private' 'EditorResolver.ps1'),
    (Join-Path $PSScriptRoot 'Private' 'FileResolver.ps1'),
    (Join-Path $PSScriptRoot 'Private' 'HelpSystem.ps1')
)

$allClean = $true
foreach ($f in $files) {
    $name = Split-Path $f -Leaf
    $bytes = [System.IO.File]::ReadAllBytes($f)
    $count = 0
    $skipBom = 0
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        $skipBom = 3
    }
    for ($i = $skipBom; $i -lt $bytes.Length; $i++) {
        if ($bytes[$i] -gt 127) { $count++ }
    }
    if ($count -eq 0) {
        Write-Host "  PASS: $name" -ForegroundColor Green
    } else {
        Write-Host "  FAIL: $name ($count non-ASCII bytes)" -ForegroundColor Red
        $allClean = $false
    }
}

if ($allClean) {
    Write-Host "`nAll files are pure ASCII." -ForegroundColor Green
} else {
    Write-Host "`nSome files contain non-ASCII bytes!" -ForegroundColor Red
}
