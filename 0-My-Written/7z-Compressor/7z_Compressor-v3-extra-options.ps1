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
    - 7z:  0=store, 1=fastest, 3=fast, 5=normal, 7=maximum, 9=ultra
    - zip: 0=store, 1=fastest, 3=fast, 5=normal, 7=maximum, 9=ultra
    - tar/wim: Not available (uses default)
    Default: 9 (ultra)

.PARAMETER CompressionMethod
    Compression method:
    - 7z:  LZMA2, LZMA, PPMd, BZip2 (default: LZMA2)
    - zip: Deflate, Deflate64, BZip2, LZMA, PPMd (default: Deflate)
    - tar: GNU, Posix (default: GNU)
    - wim: Not available

.PARAMETER DictionarySize
    Dictionary size for compression (7z/zip only).
    Format: Number + KB/MB/GB (e.g., 256MB, 1GB, 512KB)
    Default: 256MB (7z), auto (zip)

.PARAMETER WordSize
    Word size (fast bytes):
    - 7z:  Default 64
    - zip: Default 32
    Range: 3-273

.PARAMETER SolidBlockSize
    Solid block size (7z only).
    Format: Number + KB/MB/GB (e.g., 16GB, 4GB, 2GB)
    Default: 16GB

.PARAMETER RAM
    RAM usage percentage (0-100) for 7z and zip only.
    Default: 50

.PARAMETER Threads
    Number of CPU threads to use (1-max, 0=auto).
    Default: 0 (auto-detect)

.PARAMETER Encrypt
    Enable encryption:
    - 7z:  AES-256 (only option)
    - zip: AES-256 or ZipCrypto
    - tar/wim: Not available

.PARAMETER Password
    Password for encrypted archives (required if -Encrypt is used)

.PARAMETER Split
    Split archive into parts of specified size.
    Format: Number + KB/MB/GB (e.g., 1500MB, 1GB)
    Example: -Split 1500MB creates 1500MB parts

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
    .\Compressor_7z.ps1 -SourceDir "C:\Data" -Format 7z -DictionarySize 512MB -WordSize 128 -SolidBlockSize 32GB
    # Custom dictionary, word size, and solid block for 7z

.EXAMPLE
    .\Compressor_7z.ps1 -SourceDir "C:\Files" -Format zip -WordSize 64
    # ZIP with custom word size

.EXAMPLE
    .\Compressor_7z.ps1 -SourceDir "C:\Data" -Format 7z -Encrypt AES-256 -Password "MyPassword123"
    # Encrypted 7z archive with AES-256

.EXAMPLE
    .\Compressor_7z.ps1 -SourceDir "C:\LargeFiles" -Split 1500MB
    # Split archive into 1500MB parts

.EXAMPLE
    .\Compressor_7z.ps1 -h
    # Shows help message

.NOTES
    Author: PowerShell Script
    Version: 3.0 (Full-featured: Dictionary, WordSize, SolidBlock, Encrypt, Split)
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
    [string]$DictionarySize = "",
    
    [Parameter(Mandatory=$false)]
    [int]$WordSize = 0,
    
    [Parameter(Mandatory=$false)]
    [string]$SolidBlockSize = "",
    
    [Parameter(Mandatory=$false)]
    [ValidateRange(0, 100)]
    [int]$RAM = 50,
    
    [Parameter(Mandatory=$false)]
    [int]$Threads = 0,
    
    [Parameter(Mandatory=$false)]
    [string]$Encrypt = "",
    
    [Parameter(Mandatory=$false)]
    [string]$Password = "",
    
    [Parameter(Mandatory=$false)]
    [string]$Split = "",
    
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
                        [-DictionarySize <size>] [-WordSize <n>] [-SolidBlockSize <size>]
                        [-RAM <n>] [-Threads <n>] [-Encrypt <type>] [-Password <pass>]
                        [-Split <size>] [-Help]

PARAMETERS:
    -SourceDir <path>       Source directory containing files/folders to compress
    -ExportDir <path>       Output directory (default: same as source)
    -Format <type>          Archive format: 7z, zip, tar, wim (default: 7z)
    -CompressionLevel <n>   Compression level:
                            - 7z:  0=store, 1=fastest, 3=fast, 5=normal, 7=maximum, 9=ultra
                            - zip: 0=store, 1=fastest, 3=fast, 5=normal, 7=maximum, 9=ultra
                            - tar/wim: Not available
    -CompressionMethod <m>   Compression method:
                            - 7z:  LZMA2, LZMA, PPMd, BZip2 (default: LZMA2)
                            - zip: Deflate, Deflate64, BZip2, LZMA, PPMd (default: Deflate)
                            - tar: GNU, Posix (default: GNU)
                            - wim: Not available
    -DictionarySize <size>   Dictionary size (7z/zip only). Format: 256MB, 1GB, 512KB
                            - 7z default: 256MB
    -WordSize <n>            Word size (fast bytes):
                            - 7z default: 64
                            - zip default: 32
                            Range: 3-273
    -SolidBlockSize <size>   Solid block size (7z only). Format: 16GB, 4GB, 2GB
                            - Default: 16GB
    -RAM <n>                RAM usage percentage 0-100 (7z/zip only, default: 50)
    -Threads <n>            CPU threads (0=auto, default: 0)
    -Encrypt <type>         Encryption type:
                            - 7z:  AES-256 (only)
                            - zip: AES-256, ZipCrypto
                            - tar/wim: Not available
    -Password <pass>        Password for encrypted archive (required if -Encrypt used)
    -Split <size>           Split into parts. Format: 1500MB, 1GB, 500KB
                            - Available for all formats: 7z, zip, tar, wim
    -h, -Help               Show this help message

EXAMPLES:
    1. Interactive mode (dialog):
       .\Compressor_7z.ps1

    2. ZIP with normal compression:
       .\Compressor_7z.ps1 -SourceDir "C:\Videos" -Format zip -CompressionLevel 5

    3. Maximum 7z with custom settings:
       .\Compressor_7z.ps1 -SourceDir "C:\Data" -Format 7z -CompressionLevel 9 -CompressionMethod LZMA2 -Threads 8

    4. 7z with custom dictionary, word size, solid block:
       .\Compressor_7z.ps1 -SourceDir "C:\Data" -Format 7z -DictionarySize 512MB -WordSize 128 -SolidBlockSize 32GB

    5. ZIP with custom word size:
       .\Compressor_7z.ps1 -SourceDir "C:\Files" -Format zip -WordSize 64

    6. Encrypted 7z archive:
       .\Compressor_7z.ps1 -SourceDir "C:\Data" -Format 7z -Encrypt AES-256 -Password "MyPass123"

    7. Encrypted ZIP with ZipCrypto:
       .\Compressor_7z.ps1 -SourceDir "C:\Data" -Format zip -Encrypt ZipCrypto -Password "MyPass123"

    8. Split archive into 1500MB parts:
       .\Compressor_7z.ps1 -SourceDir "C:\LargeFiles" -Split 1500MB

    9. Full example with all options:
       .\Compressor_7z.ps1 -SourceDir "C:\Data" -ExportDir "D:\Backups" -Format 7z -CompressionLevel 9 -DictionarySize 512MB -Threads 8 -Split 1500MB

    10. Show help:
        .\Compressor_7z.ps1 -h

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

# ============== HELPER FUNCTIONS ==============

# Parse size string (e.g., "256MB", "1GB", "512KB") to bytes
function Parse-SizeToBytes {
    param([string]$SizeStr)
    
    if ([string]::IsNullOrWhiteSpace($SizeStr)) { return 0 }
    
    $SizeStr = $SizeStr.Trim().ToUpper()
    
    if ($SizeStr -match '^(\d+)(KB|MB|GB|TB)?$') {
        $value = [int]$Matches[1]
        $unit = $Matches[2]
        
        switch ($unit) {
            "KB" { return $value * 1KB }
            "MB" { return $value * 1MB }
            "GB" { return $value * 1GB }
            "TB" { return $value * 1TB }
            default { return $value }  # Bytes
        }
    }
    return 0
}

# Parse size to 7z format (e.g., "256m", "1g", "512k")
function Parse-SizeTo7zFormat {
    param([string]$SizeStr)
    
    if ([string]::IsNullOrWhiteSpace($SizeStr)) { return "" }
    
    $SizeStr = $SizeStr.Trim().ToUpper()
    
    if ($SizeStr -match '^(\d+)(KB|MB|GB|TB)?$') {
        $value = [int]$Matches[1]
        $unit = $Matches[2]
        
        if ([string]::IsNullOrEmpty($unit)) { return "${value}" }
        
        switch ($unit) {
            "KB" { return "${value}k" }
            "MB" { return "${value}m" }
            "GB" { return "${value}g" }
            "TB" { return "${value}t" }
            default { return "${value}" }
        }
    }
    return ""
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

# Validate WordSize
if ($WordSize -gt 0) {
    if ($WordSize -lt 3 -or $WordSize -gt 273) {
        Write-Host "[ERROR] WordSize must be between 3 and 273" -ForegroundColor Red
        exit 1
    }
}

# Validate Encryption
$validEncrypt7z = @("AES-256")
$validEncryptZip = @("AES-256", "ZipCrypto")

if ($Encrypt -ne "") {
    if ($Format -eq "tar" -or $Format -eq "wim") {
        Write-Host "[ERROR] Encryption not available for $Format" -ForegroundColor Red
        exit 1
    }
    if ($Format -eq "7z" -and $validEncrypt7z -notcontains $Encrypt) {
        Write-Host "[ERROR] Invalid encryption for 7z. Use: AES-256" -ForegroundColor Red
        exit 1
    }
    if ($Format -eq "zip" -and $validEncryptZip -notcontains $Encrypt) {
        Write-Host "[ERROR] Invalid encryption for zip. Use: AES-256, ZipCrypto" -ForegroundColor Red
        exit 1
    }
    if ($Password -eq "") {
        Write-Host "[ERROR] Password is required when using encryption" -ForegroundColor Red
        exit 1
    }
}

# Validate RAM for tar/wim
if (($Format -eq "tar" -or $Format -eq "wim") -and $RAM -ne 50) {
    Write-Host "[WARNING] RAM parameter not available for $Format, using default" -ForegroundColor Yellow
    $RAM = 50
}

# Validate SolidBlockSize for non-7z
if ($SolidBlockSize -ne "" -and $Format -ne "7z") {
    Write-Host "[WARNING] SolidBlockSize only available for 7z, ignoring" -ForegroundColor Yellow
    $SolidBlockSize = ""
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

# Build dictionary parameter
$dictParam = ""
if ($DictionarySize -ne "") {
    $dictParam = "-md=$(Parse-SizeTo7zFormat $DictionarySize)"
} elseif ($Format -eq "7z") {
    $dictParam = "-md=256m"  # Default for 7z
}

# Build word size parameter
$wordSizeParam = ""
if ($WordSize -gt 0) {
    $wordSizeParam = "-mfb=$WordSize"
} elseif ($Format -eq "7z" -and $WordSize -eq 0) {
    $wordSizeParam = "-mfb=64"  # Default for 7z
} elseif ($Format -eq "zip" -and $WordSize -eq 0) {
    $wordSizeParam = "-mfb=32"  # Default for zip
}

# Build solid block parameter
$solidParam = ""
if ($SolidBlockSize -ne "" -and $Format -eq "7z") {
    $solidParam = "-ms=$(Parse-SizeTo7zFormat $SolidBlockSize)"
} elseif ($Format -eq "7z" -and $SolidBlockSize -eq "") {
    $solidParam = "-ms=16g"  # Default for 7z
}

# Build thread parameter
$threadParam = ""
if ($Threads -gt 0) {
    $threadParam = "-mmt=$Threads"
} elseif ($Threads -eq 0) {
    $cpuThreads = (Get-CimInstance -ClassName Win32_Processor).NumberOfLogicalProcessors
    if ($cpuThreads -gt 0) {
        $threadParam = "-mmt=$cpuThreads"
    }
}

# Build encryption parameter
$encryptParam = ""
if ($Encrypt -ne "") {
    if ($Format -eq "7z") {
        $encryptParam = "-mhe=on -p$Password"
    } elseif ($Format -eq "zip") {
        if ($Encrypt -eq "AES-256") {
            $encryptParam = "-p$Password -mAES256"
        } else {
            $encryptParam = "-p$Password"
        }
    }
}

# Build split parameter
$splitParam = ""
if ($Split -ne "") {
    $splitParam = "-v$(Parse-SizeTo7zFormat $Split)"
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
if ($DictionarySize -ne "") {
    Write-Host "  Dictionary Size : $DictionarySize" -ForegroundColor White
} else {
    Write-Host "  Dictionary Size : 256MB (default)" -ForegroundColor White
}
if ($WordSize -gt 0) {
    Write-Host "  Word Size      : $WordSize" -ForegroundColor White
} else {
    Write-Host "  Word Size      : $($Format -eq '7z' ? '64' : '32') (default)" -ForegroundColor White
}
if ($SolidBlockSize -ne "" -and $Format -eq "7z") {
    Write-Host "  Solid Block    : $SolidBlockSize" -ForegroundColor White
} elseif ($Format -eq "7z") {
    Write-Host "  Solid Block    : 16GB (default)" -ForegroundColor White
}
Write-Host "  RAM Usage       : $RAM%" -ForegroundColor White
Write-Host "  Threads         : $($Threads -eq 0 ? 'Auto' : $Threads)" -ForegroundColor White
if ($Encrypt -ne "") {
    Write-Host "  Encryption     : $Encrypt" -ForegroundColor Yellow
}
if ($Split -ne "") {
    Write-Host "  Split Size     : $Split" -ForegroundColor Yellow
}
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
        $wordSizeParam,
        $solidParam,
        $threadParam,
        $encryptParam,
        $splitParam,
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