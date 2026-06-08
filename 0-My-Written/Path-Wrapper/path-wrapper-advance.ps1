<#
====================================================================
 PATH-WRAPPER (SCOOP-STYLE SHIM GENERATOR)
====================================================================

DESCRIPTION
    Creates PATH-compatible CMD wrapper shims for executables.
    Designed for centralized PATH directory usage (Scoop-like model).

SUPPORTED EXTENSIONS
    .exe  .com  .cmd  .bat  .ps1  .msc  .vbs  .js  .wsf

FEATURES
    - Single file wrapping (-f / --file)
    - Directory batch wrapping (-d / --directory)
    - Recursive scanning (-r / --recursive)
    - Force overwrite (-F / --force)
    - Multi-extension intelligent templates
    - Collision detection
    - Colored CLI output
    - Summary report

USAGE
    path-wrapper.ps1 -f "C:\App\tool.exe"

    path-wrapper.ps1 -d "C:\Apps"

    path-wrapper.ps1 -d "C:\Apps" -r

    path-wrapper.ps1 -d "C:\Apps" -r -F

    path-wrapper.ps1 -f "C:\App\tool.exe" -t "D:\Shims"

====================================================================
#>

# ---------------- CONFIG ----------------

$DefaultTarget = "C:\Apps\EXE-Scripts"

$SupportedExtensions = @{
    ".exe" = "exe"
    ".com" = "exe"
    ".cmd" = "cmd"
    ".bat" = "cmd"
    ".ps1" = "ps1"
    ".msc" = "msc"
    ".vbs" = "vbs"
    ".js"  = "js"
    ".wsf" = "wsf"
}

# ---------------- STATE ----------------

[int]$Created = 0
[int]$Skipped = 0
[int]$Failed  = 0

# ---------------- HELP ----------------

function Show-Help {

    Write-Host ""
    Write-Host "PATH-WRAPPER (SCOOP-STYLE SHIM GENERATOR)" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "USAGE" -ForegroundColor Yellow
    Write-Host "  path-wrapper.ps1 -f <file>"
    Write-Host "  path-wrapper.ps1 -d <directory>"
    Write-Host "  path-wrapper.ps1 -d <directory> -r"
    Write-Host "  path-wrapper.ps1 -d <directory> -r -F"
    Write-Host ""

    Write-Host "FLAGS" -ForegroundColor Yellow
    Write-Host "  -f, --file         Wrap a single file"
    Write-Host "  -d, --directory    Wrap directory files"
    Write-Host "  -r, --recursive    Scan subdirectories"
    Write-Host "  -t, --target       Output directory"
    Write-Host "  -F, --force        Overwrite existing wrappers"
    Write-Host "  -h, --help         Show help"
    Write-Host ""

    Write-Host "SUPPORTED" -ForegroundColor Yellow
    Write-Host "  .exe .com .cmd .bat .ps1 .msc .vbs .js .wsf"
    Write-Host ""

    Write-Host "EXAMPLES" -ForegroundColor Yellow
    Write-Host '  path-wrapper.ps1 -f "C:\Apps\php.exe"' -ForegroundColor Green
    Write-Host '  path-wrapper.ps1 -d "C:\Apps" -r' -ForegroundColor Green
    Write-Host '  path-wrapper.ps1 -d "C:\Apps" -r -F -t "D:\Shims"' -ForegroundColor Green
    Write-Host ""

    exit 0
}

# ---------------- WRAPPER ENGINE ----------------

function Get-WrapperTemplate {
    param($Type, $Target)

    switch ($Type) {

        "exe" {
            return "@echo off`r`nsetlocal`r`n`"$Target`" %*`r`nexit /b %errorlevel%"
        }

        "cmd" {
            return "@echo off`r`nsetlocal`r`ncall `"$Target`" %*`r`nexit /b %errorlevel%"
        }

        "ps1" {
            return "@echo off`r`nsetlocal`r`npowershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$Target`" %*`r`nexit /b %errorlevel%"
        }

        "msc" {
            return "@echo off`r`nsetlocal`r`nmmc.exe `"$Target`" %*`r`nexit /b %errorlevel%"
        }

        "vbs" {
            return "@echo off`r`nsetlocal`r`ncscript.exe //nologo `"$Target`" %*`r`nexit /b %errorlevel%"
        }

        "js" {
            return "@echo off`r`nsetlocal`r`ncscript.exe //nologo `"$Target`" %*`r`nexit /b %errorlevel%"
        }

        "wsf" {
            return "@echo off`r`nsetlocal`r`ncscript.exe //nologo `"$Target`" %*`r`nexit /b %errorlevel%"
        }
    }

    return $null
}

function New-Wrap {
    param(
        $FilePath,
        $TargetDir,
        $Force
    )

    try {

        $Resolved = (Resolve-Path $FilePath).Path
        $ext = [System.IO.Path]::GetExtension($Resolved).ToLower()

        if (-not $SupportedExtensions.ContainsKey($ext)) {
            return
        }

        $type = $SupportedExtensions[$ext]
        $name = [System.IO.Path]::GetFileNameWithoutExtension($Resolved)

        $out = Join-Path $TargetDir "$name.cmd"

        if ((Test-Path $out) -and -not $Force) {
            Write-Host "[SKIP] $name" -ForegroundColor DarkYellow
            $script:Skipped++
            return
        }

        $template = Get-WrapperTemplate $type $Resolved

        if (-not $template) {
            throw "No template for $type"
        }

        Set-Content -Path $out -Value $template -Encoding ASCII

        Write-Host "[OK]   $name" -ForegroundColor Green
        $script:Created++

    } catch {
        Write-Host "[FAIL] $FilePath" -ForegroundColor Red
        $script:Failed++
    }
}

# ---------------- ARG PARSER ----------------

if ($args.Count -eq 0) { Show-Help }

$mode = $null
$input = $null
$target = $DefaultTarget
$recursive = $false
$force = $false

for ($i=0; $i -lt $args.Count; $i++) {

    switch ($args[$i]) {

        "-h" { Show-Help }
        "--help" { Show-Help }

        "-f" { $mode="file"; $input=$args[++$i] }
        "--file" { $mode="file"; $input=$args[++$i] }

        "-d" { $mode="dir"; $input=$args[++$i] }
        "--directory" { $mode="dir"; $input=$args[++$i] }

        "-t" { $target=$args[++$i] }
        "--target" { $target=$args[++$i] }

        "-r" { $recursive=$true }
        "--recursive" { $recursive=$true }

        "-F" { $force=$true }
        "--force" { $force=$true }
    }
}

if (-not (Test-Path $target)) {
    New-Item -ItemType Directory -Path $target -Force | Out-Null
}

Write-Host ""
Write-Host "Target: $target" -ForegroundColor Cyan
Write-Host ""

# ---------------- EXECUTION ----------------

switch ($mode) {

    "file" {
        New-Wrap $input $target $force
    }

    "dir" {

        if ($recursive) {

            Get-ChildItem $input -File -Recurse |
            ForEach-Object {
                New-Wrap $_.FullName $target $force
            }

        } else {

            Get-ChildItem $input -File |
            ForEach-Object {
                New-Wrap $_.FullName $target $force
            }
        }
    }
}

# ---------------- SUMMARY ----------------

Write-Host ""
Write-Host "==============================" -ForegroundColor DarkGray
Write-Host "Created : $Created" -ForegroundColor Green
Write-Host "Skipped : $Skipped" -ForegroundColor Yellow
Write-Host "Failed  : $Failed" -ForegroundColor Red
Write-Host "Target  : $target" -ForegroundColor Cyan
Write-Host "==============================" -ForegroundColor DarkGray
Write-Host ""