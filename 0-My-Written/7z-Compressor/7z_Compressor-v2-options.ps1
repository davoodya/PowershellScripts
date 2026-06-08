<#
.SYNOPSIS
    Compressor_7z.ps1 - Batch compression tool for files and directories using 7-Zip

.DESCRIPTION
    This script compresses each file and directory individually using 7-Zip with 
    customizable compression settings. Processes items ONE BY ONE to minimize system resource usage.

.PARAMETER SourceDir
    Path to the directory containing files/folders to compress.
    If not provided, a folder selection dialog will appear.

.PARAMETER ExportDir
    Output directory for compressed files.
    Default: Same as SourceDir (files will be created next to source items)

.PARAMETER Format
    Archive format: 7z, zip, tar, wim
    Default: 7z

.PARAMETER CompressionLevel
    Compression level (number):
    - 7z:  0-9 (0=store, 1=fastest, 3=fast, 5=normal, 7=maximum, 9=ultra)
    - zip: 0,1,3,5,7,9 (0=store, 1=fastest, 3=fast, 5=normal, 7=maximum, 9=ultra)
    - tar/wim: Not available (uses default)
    Default: 9 (ultra)

.PARAMETER CompressionMethod
    Compression method:
    - 7z:  LZMA2, LZMA, PPMd, BZip2
    - zip: Deflate, Deflate64, BZip2, LZMA, PPMd
    - tar: GNU, Posix
    - wim: Not available
    Default: LZMA2 (for 7z), Deflate (for zip)

.PARAMETER RAM
    RAM usage percentage (0-100) for 7z and zip only.
    Default: 50

.PARAMETER Threads
    Number of CPU threads to use (1-max).
    Default: Auto-detect (all available)

.PARAMETER Help
    Shows this help message

.EXAMPLE
    .\Compressor_7z.ps1
    # Opens folder selection dialog with default settings

.EXAMPLE
    .\Compressor_7z.ps1 -SourceDir "C:\Videos" -Format zip -CompressionLevel 5
    # Compress as ZIP with normal compression

.EXAMPLE
    .\Compressor_7z.ps1 -SourceDir "C:\Data" -Format 7z -CompressionLevel 9 -CompressionMethod LZMA2 -Threads 8
    # Maximum compression with LZMA2 and 8 threads

.EXAMPLE
    .\Compressor_7z.ps1 -SourceDir "C:\Files" -Format tar -CompressionMethod Posix
    # Create TAR archive with Posix method

.EXAMPLE
    .\Compressor_7z.ps1 -SourceDir "C:\Data" -ExportDir "D:\Backups" -Format zip -RAM 30
    # Compress to ZIP using 30% RAM

.EXAMPLE
    .\Compressor_7z.ps1 -h
    # Shows help message

.NOTES
    Author: PowerShell Script
    Version: 2.0 (Added format, compression level, method, RAM, threads options)
    7-Zip Required: Yes (C:\Program Files\7-Zip\7z.exe)
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$SourceDir = "",
    
    [Parameter(Mandatory=$false)]
    [string]$ExportDir = "",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("7z", "zip", "tar", "wim")]
    [string]$Format = "7z",
    
    [Parameter(Mandatory=$false)]
    [int]$CompressionLevel = 9,
    
    [Parameter(Mandatory=$false)]
    [string]$CompressionMethod = "",
    
    [Parameter(Mandatory=$false)]
    [ValidateRange(0, 100)]
    [int]$RAM = 50,
    
    [Parameter(Mandatory=$false)]
    [int]$Threads = 0,
    
    [Parameter(Mandatory=$false)]
    [switch]$Help
)

# ============== HELP MESSAGE ==============
function Show-Help {
    Write-Host @"

========================================
   Compressor_7z.ps1 - Help
========================================

USAGE:
    .\Compressor_7z.ps1 [-SourceDir <path>] [-ExportDir <path>] [-Format <type>] 
                        [-CompressionLevel <n>] [-CompressionMethod <method>] 
                        [-RAM <n>] [-Threads <n>] [-Help]

PARAMETERS:
    -SourceDir <path>       Source directory containing files/folders to compress
    -ExportDir <path>       Output directory (default: same as source)
    -Format <type>          Archive format: 7z, zip, tar, wim (default: 7z)
    -CompressionLevel <n>   Compression level (0-9)
                            - 7z:  0=store, 1=fastest, 3=fast, 5=normal, 7=maximum, 9=ultra
                            - zip: 0=store, 1=fastest, 3=fast, 5=normal, 7=maximum, 9=ultra
                            - tar/wim: Not available
    -CompressionMethod <m>   Compression method:
                            - 7z:  LZMA2, LZMA, PPMd, BZip2 (default: LZMA2)
                            - zip: Deflate, Deflate64, BZip2, LZMA, PPMd (default: Deflate)
                            - tar: GNU, Posix (default: GNU)
                            - wim: Not available
    -RAM <n>                RAM usage percentage 0-100 (7z/zip only, default: 50)
    -Threads <n>            CPU threads (0=auto, default: 0)
    -h, -Help               Show this help message

EXAMPLES:
    1. Interactive mode (dialog):
       .\Compressor_7z.ps1

    2. Compress as ZIP with normal compression:
       .\Compressor_7z.ps1 -SourceDir "C:\Videos" -Format zip -CompressionLevel 5

    3. Maximum 7z compression with LZMA2 and 8 threads:
       .\Compressor_7z.ps1 -SourceDir "C:\Data" -Format 7z -CompressionLevel 9 -CompressionMethod LZMA2 -Threads 8

    4. TAR archive with Posix method:
       .\Compressor_7z.ps1 -SourceDir "C:\Files" -Format tar -CompressionMethod Posix

    5. ZIP with custom output and RAM usage:
       .\Compressor_7z.ps1 -SourceDir "C:\Data" -ExportDir "D:\Backups" -Format zip -RAM 30

    6. Show help:
       .\Compressor_7z.ps1 -h

COMPRESSION SETTINGS:
    Format:          Customizable (7z, zip, tar, wim)
    Level:           0-9 (Ultra = 9)
    Method:          LZMA2/Deflate/etc.
    Dictionary:     Based on RAM %
    Threads:        Customizable

NOTES:
    - Each file/folder is compressed SEPARATELY
    - Items are processed ONE BY ONE to save resources
    - Output files are created next to source by default
    - 7-Zip must be installed at: C:\Program Files\7-Zip\7z.exe

========================================

"@ -ForegroundColor Cyan
    exit 0
}

# Show help if -h or -Help is used
if ($Help) {
    Show-Help
}

# ============== CONFIGURATION ==============
$7zPath = "C:\Program Files\7-Zip\7z.exe"

# ============== VALIDATION ==============

# Validate compression level based on format
if ($Format -eq "zip") {
    $validLevels = @(0, 1, 3, 5, 7, 9)
    if ($validLevels -notcontains $CompressionLevel) {
        Write-Host "[ERROR] Invalid compression level for ZIP: $CompressionLevel" -ForegroundColor Red
        Write-Host "Valid levels: 0, 1, 3, 5, 7, 9" -ForegroundColor Yellow
        exit 1
    }
} elseif ($Format -eq "tar" -or $Format -eq "wim") {
    if ($CompressionLevel -ne 9) {
        Write-Host "[INFO] Compression level not available for $Format, using default" -ForegroundColor Cyan
    }
}

# Validate compression method based on format
$validMethods7z = @("LZMA2", "LZMA", "PPMd", "BZip2")
$validMethodsZip = @("Deflate", "Deflate64", "BZip2", "LZMA", "PPMd")
$validMethodsTar = @("GNU", "Posix")

if ($Format -eq "7z") {
    if ($CompressionMethod -eq "") { $CompressionMethod = "LZMA2" }
    if ($validMethods7z -notcontains $CompressionMethod) {
        Write-Host "[ERROR] Invalid method for 7z: $CompressionMethod" -ForegroundColor Red
        Write-Host "Valid methods: $($validMethods7z -join ', ')" -ForegroundColor Yellow
        exit 1
    }
} elseif ($Format -eq "zip") {
    if ($CompressionMethod -eq "") { $CompressionMethod = "Deflate" }
    if ($validMethodsZip -notcontains $CompressionMethod) {
        Write-Host "[ERROR] Invalid method for zip: $CompressionMethod" -ForegroundColor Red
        Write-Host "Valid methods: $($validMethodsZip -join ', ')" -ForegroundColor Yellow
        exit 1
    }
} elseif ($Format -eq "tar") {
    if ($CompressionMethod -eq "") { $CompressionMethod = "GNU" }
    if ($validMethodsTar -notcontains $CompressionMethod) {
        Write-Host "[ERROR] Invalid method for tar: $CompressionMethod" -ForegroundColor Red
        Write-Host "Valid methods: $($validMethodsTar -join ', ')" -ForegroundColor Yellow
        exit 1
    }
} elseif ($Format -eq "wim") {
    if ($CompressionMethod -ne "") {
        Write-Host "[WARNING] Compression method not available for WIM, ignoring" -ForegroundColor Yellow
        $CompressionMethod = ""
    }
}

# Validate RAM for tar/wim
if (($Format -eq "tar" -or $Format -eq "wim") -and $RAM -ne 50) {
    Write-Host "[WARNING] RAM parameter not available for $Format, using default" -ForegroundColor Yellow
    $RAM = 50
}

# ============== CHECK 7-ZIP ==============
if (-not (Test-Path $7zPath)) {
    Write-Host "[ERROR] 7-Zip not found at: $7zPath" -ForegroundColor Red
    Write-Host "Please install 7-Zip and update the `$7zPath variable." -ForegroundColor Yellow
    exit 1
}

# ============== FOLDER SELECTION DIALOG ==============
if ([string]::IsNullOrWhiteSpace($SourceDir)) {
    Write-Host "[INFO] No source directory specified. Opening dialog..." -ForegroundColor Cyan
    
    Add-Type -AssemblyName System.Windows.Forms
    $folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderDialog.Description = "Select source directory containing files/folders to compress"
    $folderDialog.ShowNewFolderButton = $false
    
    if ($folderDialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) {
        Write-Host "[CANCELLED] Operation cancelled by user." -ForegroundColor Yellow
        exit 0
    }
    
    $SourceDir = $folderDialog.SelectedPath
    Write-Host "[OK] Selected: $SourceDir" -ForegroundColor Green
}

# Remove trailing backslash
$SourceDir = $SourceDir.TrimEnd('\')

# Validate source path
if (-not (Test-Path $SourceDir)) {
    Write-Host "[ERROR] Source path not found: $SourceDir" -ForegroundColor Red
    exit 1
}

# ============== DETERMINE OUTPUT DIRECTORY ==============
if ([string]::IsNullOrWhiteSpace($ExportDir)) {
    $ExportDir = $SourceDir
} else {
    $ExportDir = $ExportDir.TrimEnd('\')
}

# Create export directory if not exists
if (-not (Test-Path $ExportDir)) {
    New-Item -ItemType Directory -Path $ExportDir -Force | Out-Null
}

# ============== GET FILES AND DIRECTORIES ==============
$itemInfo = Get-Item $SourceDir
$items = @()

if ($itemInfo.PSIsContainer) {
    $children = Get-ChildItem -Path $SourceDir -Force
    
    foreach ($child in $children) {
        if ($child.Name -notmatch '^\.') {
            $items += $child
        }
    }
} else {
    $items += $itemInfo
}

$items = $items | Where-Object { $_.Attributes -notmatch 'System' }

if ($items.Count -eq 0) {
    Write-Host "[WARNING] No files or directories found to compress!" -ForegroundColor Yellow
    exit 0
}

# ============== BUILD COMPRESSION PARAMETERS ==============

# Determine format type
$formatType = $Format

# Build method parameter
$methodParam = ""
switch ($Format) {
    "7z" {
        $methodParam = "-m0=$CompressionMethod"
    }
    "zip" {
        $methodParam = "-mm=$CompressionMethod"
    }
    "tar" {
        if ($CompressionMethod -eq "Posix") {
            $methodParam = "-sfx"
        }
    }
}

# Build thread parameter
$threadParam = ""
if ($Threads -gt 0) {
    $threadParam = "-mmt=$Threads"
} elseif ($Threads -eq 0) {
    # Auto-detect: use all available threads
    $cpuCores = (Get-CimInstance -ClassName Win32_Processor).NumberOfCores
    $cpuThreads = (Get-CimInstance -ClassName Win32_Processor).NumberOfLogicalProcessors
    if ($cpuThreads -gt 0) {
        $threadParam = "-mmt=$cpuThreads"
    }
}

# Build dictionary size based on RAM percentage (for 7z and zip)
$dictParam = ""
if ($Format -eq "7z" -or $Format -zip) {
    # Calculate dictionary size based on RAM percentage
    $totalRAM = (Get-CimInstance -ClassName Win32_ComputerSystem).TotalPhysicalMemory
    $availableRAM = [math]::Floor($totalRAM * ($RAM / 100))
    
    # Round to nearest 32MB and cap at 4GB
    $dictSizeMB = [math]::Floor($availableRAM / 32MB) * 32
    if ($dictSizeMB -gt 4096) { $dictSizeMB = 4096 }
    if ($dictSizeMB -lt 32) { $dictSizeMB = 32 }
    
    $dictParam = "-md=${dictSizeMB}m"
}

# ============== DISPLAY SUMMARY ==============
Write-Host ""
Write-Host "========================================" -ForegroundColor Magenta
Write-Host "       COMPRESSION SETTINGS           " -ForegroundColor Magenta
Write-Host "========================================" -ForegroundColor Magenta
Write-Host "  Source Dir      : $SourceDir" -ForegroundColor White
Write-Host "  Export Dir      : $ExportDir" -ForegroundColor White
Write-Host "  Items Found     : $($items.Count)" -ForegroundColor White
Write-Host "  Format          : $Format" -ForegroundColor White
Write-Host "  Compression Lvl : $CompressionLevel" -ForegroundColor White
Write-Host "  Method          : $CompressionMethod" -ForegroundColor White
Write-Host "  RAM Usage       : $RAM%" -ForegroundColor White
Write-Host "  Dictionary      : $([math]::Floor($dictSizeMB))MB" -ForegroundColor White
Write-Host "  Threads         : $($Threads -eq 0 ? 'Auto' : $Threads)" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Magenta
Write-Host ""

# ============== COMPRESS ITEMS ONE BY ONE ==============
$successCount = 0
$failCount = 0
$totalOriginalSize = 0
$totalCompressedSize = 0

foreach ($item in $items) {
    # Determine output filename
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($item.Name)
    $outputFile = Join-Path $ExportDir "$baseName.$Format"
    
    # If file exists, add number suffix
    $counter = 1
    while (Test-Path $outputFile) {
        $outputFile = Join-Path $ExportDir "$baseName ($counter).$Format"
        $counter++
    }
    
    # Determine input path
    if ($item.PSIsContainer) {
        $inputPath = $item.FullName
        $itemType = "[DIR] "
    } else {
        $inputPath = $item.FullName
        $itemType = "[FILE]"
    }
    
    Write-Host "$itemType Compressing: $($item.Name)" -ForegroundColor Yellow
    
    # Build compression command
    $cmdArgs = @(
        "a",
        "-t$formatType",
        "-mx=$CompressionLevel",
        $methodParam,
        $dictParam,
        $threadParam,
        "-r",
        "-y",
        "--",
        "$outputFile",
        "$inputPath\*"
    )
    
    # Remove empty parameters
    $cmdArgs = $cmdArgs | Where-Object { $_ -ne "" }
    
    # Execute compression
    & $7zPath @cmdArgs
    
    $exitCode = $LASTEXITCODE
    
    if ($exitCode -eq 0) {
        $originalSize = (Get-ChildItem $inputPath -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
        if ($null -eq $originalSize) { $originalSize = 0 }
        
        $compressedSize = (Get-Item $outputFile).Length
        
        $totalOriginalSize += $originalSize
        $totalCompressedSize += $compressedSize
        
        if ($originalSize -gt 0) {
            $ratio = [math]::Round((1 - ($compressedSize / $originalSize)) * 100, 2)
            $originalSizeMB = [math]::Round($originalSize / 1MB, 2)
            $compressedSizeMB = [math]::Round($compressedSize / 1MB, 2)
            Write-Host "       [OK] $originalSizeMB MB -> $compressedSizeMB MB (Saved: $ratio%)" -ForegroundColor Green
        } else {
            $compressedSizeMB = [math]::Round($compressedSize / 1MB, 2)
            Write-Host "       [OK] Compressed: $compressedSizeMB MB" -ForegroundColor Green
        }
        $successCount++
    } else {
        Write-Host "       [FAILED] Exit code: $exitCode" -ForegroundColor Red
        $failCount++
    }
    
    Write-Host ""
}

# ============== FINAL SUMMARY ==============
Write-Host "========================================" -ForegroundColor Magenta
Write-Host "           FINAL SUMMARY               " -ForegroundColor Magenta
Write-Host "========================================" -ForegroundColor Magenta
Write-Host "  Success      : $successCount" -ForegroundColor Green
if ($failCount -gt 0) {
    Write-Host "  Failed       : $failCount" -ForegroundColor Red
}

if ($totalOriginalSize -gt 0) {
    $totalRatio = [math]::Round((1 - ($totalCompressedSize / $totalOriginalSize)) * 100, 2)
    $totalOriginalMB = [math]::Round($totalOriginalSize / 1MB, 2)
    $totalCompressedMB = [math]::Round($totalCompressedSize / 1MB, 2)
    Write-Host "  Original     : $totalOriginalMB MB" -ForegroundColor White
    Write-Host "  Compressed   : $totalCompressedMB MB" -ForegroundColor White
    Write-Host "  Total Saved  : $totalRatio%" -ForegroundColor Cyan
}

Write-Host "  Output Dir   : $ExportDir" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "[DONE] Compression completed!" -ForegroundColor Green