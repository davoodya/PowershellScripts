<#
.SYNOPSIS
    Create PATH-friendly CMD wrappers (shims).

.DESCRIPTION
    Generate CMD wrappers for executable files so they can be
    exposed through a central PATH directory.

SUPPORTED FILE TYPES
    .exe
    .cmd
    .bat
    .ps1
    .com
    .msc

USAGE

    path-wrapper.ps1 -f "C:\Path\App.exe"

    path-wrapper.ps1 --file "C:\Path\App.exe"

    path-wrapper.ps1 -d "C:\Path\Directory"

    path-wrapper.ps1 --directory "C:\Path\Directory"

    path-wrapper.ps1 -f "C:\Path\App.exe" -t "D:\Apps"

    path-wrapper.ps1 --directory "C:\Path" --target "D:\Apps"

    path-wrapper.ps1 -h

    path-wrapper.ps1 --help
#>

$DefaultTargetDirectory = "C:\Apps\EXE-Scripts"

$SupportedExtensions = @(
    ".exe",
    ".cmd",
    ".bat",
    ".ps1",
    ".com",
    ".msc"
)

function Show-Help {

    Write-Host ""
    Write-Host "PATH-WRAPPER" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "Create CMD wrappers (shims) for executables." `
        -ForegroundColor Gray

    Write-Host ""

    Write-Host "USAGE" -ForegroundColor Yellow

    Write-Host '  path-wrapper.ps1 -f "C:\Path\App.exe"'
    Write-Host '  path-wrapper.ps1 --file "C:\Path\App.exe"'

    Write-Host ""

    Write-Host '  path-wrapper.ps1 -d "C:\Apps\PHP"'
    Write-Host '  path-wrapper.ps1 --directory "C:\Apps\PHP"'

    Write-Host ""

    Write-Host '  path-wrapper.ps1 -f "C:\Path\App.exe" -t "D:\Apps"'
    Write-Host '  path-wrapper.ps1 --directory "C:\Apps\PHP" --target "D:\Apps"'

    Write-Host ""

    Write-Host "FLAGS" -ForegroundColor Yellow

    Write-Host "  -f, --file"
    Write-Host "      Create wrapper for a single file."

    Write-Host ""

    Write-Host "  -d, --directory"
    Write-Host "      Create wrappers for all supported executables"
    Write-Host "      inside a directory."

    Write-Host ""

    Write-Host "  -t, --target"
    Write-Host "      Output directory for generated wrappers."

    Write-Host ""

    Write-Host "  -h, --help"
    Write-Host "      Show help."

    Write-Host ""

    Write-Host "SUPPORTED EXTENSIONS" `
        -ForegroundColor Yellow

    Write-Host "  .exe .cmd .bat .ps1 .com .msc"

    Write-Host ""

    exit 0
}

function New-Wrapper {

    param(
        [string]$ExecutablePath,
        [string]$TargetDirectory
    )

    $ResolvedPath = (
        Resolve-Path $ExecutablePath
    ).Path

    $CommandName =
        [System.IO.Path]::GetFileNameWithoutExtension(
            $ResolvedPath
        )

    $WrapperPath =
        Join-Path `
            $TargetDirectory `
            "$CommandName.cmd"

    if (Test-Path $WrapperPath) {

        Write-Host "[SKIP]" `
            -ForegroundColor DarkYellow `
            -NoNewline

        Write-Host " $CommandName"
        return
    }

    $WrapperContent = @"
@echo off
setlocal
"$ResolvedPath" %*
exit /b %errorlevel%
"@

    Set-Content `
        -Path $WrapperPath `
        -Value $WrapperContent `
        -Encoding ASCII

    Write-Host "[OK]" `
        -ForegroundColor Green `
        -NoNewline

    Write-Host " $CommandName" `
        -ForegroundColor Cyan
}

#
# Argument Parser
#

if ($args.Count -eq 0) {
    Show-Help
}

$Mode = $null
$InputPath = $null
$TargetDirectory = $DefaultTargetDirectory

for ($i = 0; $i -lt $args.Count; $i++) {

    switch ($args[$i]) {

        "-h"      { Show-Help }
        "--help"  { Show-Help }

        "-f" {
            $Mode = "file"
            $InputPath = $args[++$i]
        }

        "--file" {
            $Mode = "file"
            $InputPath = $args[++$i]
        }

        "-d" {
            $Mode = "directory"
            $InputPath = $args[++$i]
        }

        "--directory" {
            $Mode = "directory"
            $InputPath = $args[++$i]
        }

        "-t" {
            $TargetDirectory = $args[++$i]
        }

        "--target" {
            $TargetDirectory = $args[++$i]
        }
    }
}

if (-not $Mode) {
    Write-Host ""
    Write-Host "Error: Missing -f or -d argument." `
        -ForegroundColor Red
    Write-Host ""
    exit 1
}

if (-not (Test-Path $TargetDirectory)) {

    New-Item `
        -ItemType Directory `
        -Path $TargetDirectory `
        -Force | Out-Null
}

Write-Host ""
Write-Host "Target Directory:" `
    -ForegroundColor Yellow

Write-Host "  $TargetDirectory" `
    -ForegroundColor Cyan

Write-Host ""

switch ($Mode) {

    "file" {

        if (-not (Test-Path $InputPath)) {

            Write-Host "File not found:" `
                -ForegroundColor Red

            Write-Host $InputPath

            exit 1
        }

        New-Wrapper `
            -ExecutablePath $InputPath `
            -TargetDirectory $TargetDirectory
    }

    "directory" {

        if (-not (Test-Path $InputPath)) {

            Write-Host "Directory not found:" `
                -ForegroundColor Red

            Write-Host $InputPath

            exit 1
        }

        Get-ChildItem `
            -Path $InputPath `
            -File |
        ForEach-Object {

            if (
                $_.Extension.ToLower() `
                -in `
                $SupportedExtensions
            ) {

                New-Wrapper `
                    -ExecutablePath $_.FullName `
                    -TargetDirectory $TargetDirectory
            }
        }
    }
}

Write-Host ""
Write-Host "Done." `
    -ForegroundColor Green

Write-Host ""