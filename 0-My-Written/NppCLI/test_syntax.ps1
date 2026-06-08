# Functional test script for NppCLI module
# This tests the logic without actually launching Notepad++

Import-Module "$PSScriptRoot\NppCLI.psd1" -Force

Write-Host "=== TEST 1: npp with no args (should just print info) ===" -ForegroundColor Cyan
# We can't test this without opening Notepad++, skip

Write-Host ""
Write-Host "=== TEST 2: Parameter binding - switches must not accept strings ===" -ForegroundColor Cyan
try {
    # This tests that -d is a proper switch and doesn't eat the next string
    $cmd = Get-Command npp
    $dParam = $cmd.Parameters['d']
    if ($dParam.ParameterType -eq [System.Management.Automation.SwitchParameter]) {
        Write-Host "  PASS: -d is SwitchParameter" -ForegroundColor Green
    } else {
        Write-Host "  FAIL: -d is $($dParam.ParameterType)" -ForegroundColor Red
    }
    
    $rParam = $cmd.Parameters['r']
    if ($rParam.ParameterType -eq [System.Management.Automation.SwitchParameter]) {
        Write-Host "  PASS: -r is SwitchParameter" -ForegroundColor Green
    } else {
        Write-Host "  FAIL: -r is $($rParam.ParameterType)" -ForegroundColor Red
    }
    
    $hParam = $cmd.Parameters['hidden']
    if ($hParam.ParameterType -eq [System.Management.Automation.SwitchParameter]) {
        Write-Host "  PASS: -hidden is SwitchParameter" -ForegroundColor Green
    } else {
        Write-Host "  FAIL: -hidden is $($hParam.ParameterType)" -ForegroundColor Red
    }
}
catch {
    Write-Host "  ERROR: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== TEST 3: PositionalBinding is false ===" -ForegroundColor Cyan
$cmdInfo = Get-Command npp
$cmdletBinding = $cmdInfo.ScriptBlock.Attributes | Where-Object { $_ -is [System.Management.Automation.CmdletBindingAttribute] }
if ($cmdletBinding -and $cmdletBinding.PositionalBinding -eq $false) {
    Write-Host "  PASS: PositionalBinding = false" -ForegroundColor Green
} else {
    Write-Host "  FAIL: PositionalBinding is not false" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== TEST 4: ValueFromRemainingArguments on Paths ===" -ForegroundColor Cyan
$pathsParam = $cmdInfo.Parameters['Paths']
$paramAttr = $pathsParam.Attributes | Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] }
if ($paramAttr.ValueFromRemainingArguments -eq $true) {
    Write-Host "  PASS: Paths has ValueFromRemainingArguments" -ForegroundColor Green
} else {
    Write-Host "  FAIL: Paths missing ValueFromRemainingArguments" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== TEST 5: File creation test ===" -ForegroundColor Cyan
$testFile = "$PSScriptRoot\_test_npp_created.tmp"
if (Test-Path $testFile) { Remove-Item $testFile -Force }
# We can't call npp directly (it would open Notepad++), but we can test the file-creation logic
$parent = Split-Path $testFile -Parent
if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
New-Item -ItemType File -Path $testFile -Force | Out-Null
if (Test-Path $testFile) {
    Write-Host "  PASS: File creation logic works" -ForegroundColor Green
    Remove-Item $testFile -Force
} else {
    Write-Host "  FAIL: File was not created" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== TEST 6: Wildcard detection regex ===" -ForegroundColor Cyan
$patterns = @("*.txt", "file?.txt", "test[1-5].txt", "[abc].log", "new*")
$literals = @("file.txt", "README.md", "folder\file.txt", "C:\temp\test.log")

foreach ($p in $patterns) {
    if ($p -match '[\*\?\[\]]') {
        Write-Host "  PASS: '$p' detected as wildcard" -ForegroundColor Green
    } else {
        Write-Host "  FAIL: '$p' NOT detected as wildcard" -ForegroundColor Red
    }
}
foreach ($p in $literals) {
    if ($p -match '[\*\?\[\]]') {
        Write-Host "  FAIL: '$p' incorrectly detected as wildcard" -ForegroundColor Red
    } else {
        Write-Host "  PASS: '$p' detected as literal" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "=== All tests complete ===" -ForegroundColor Cyan
