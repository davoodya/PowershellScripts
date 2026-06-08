<#
.SYNOPSIS
    Compressor_7z.ps1 - Batch compression tool for files and directories using 7-Zip

.DESCRIPTION
    This script compresses each file and directory individually using 7-Zip with 
    maximum compression settings (LZMA2, Ultra, 256MB dictionary, Solid block).
    
    Processes items ONE BY ONE to minimize system resource usage.

.PARAMETER SourceDir
    Path to the directory containing files/folders to compress.
    If not provided, a folder selection dialog will appear.

.PARAMETER ExportDir
    Output directory for compressed files.
    Default: Same as SourceDir (files will be created next to source items)

.PARAMETER Help
    Shows this help message

.EXAMPLE
    .\Compressor_7z.ps1
    # Opens folder selection dialog

.EXAMPLE
    .\Compressor_7z.ps1 -SourceDir "C:\Videos\MyFolder"
    # Compresses all files and folders in MyFolder

.EXAMPLE
    .\Compressor_7z.ps1 -SourceDir "C:\Videos" -ExportDir "D:\Compressed"
    # Compresses items in C:\Videos and saves .7z files to D:\Compressed

.EXAMPLE
    .\Compressor_7z.ps1 -h
    # Shows help message

.NOTES
    Author: PowerShell Script
    Version: 1.3 (Fixed: Using direct execution instead of Start-Process)
    7-Zip Required: Yes (C:\Program Files\7-Zip\7z.exe)
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$SourceDir = "",
    
    [Parameter(Mandatory=$false)]
    [string]$ExportDir = "",
    
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
    .\Compressor_7z.ps1 [-SourceDir <path>] [-ExportDir <path>] [-Help]

PARAMETERS:
    -SourceDir <path>   Source directory containing files/folders to compress
    -ExportDir <path>   Output directory for compressed files (default: same as source)
    -h, -Help           Show this help message

EXAMPLES:
    1. Interactive mode (dialog):
       .\Compressor_7z.ps1

    2. Compress all items in a folder:
       .\Compressor_7z.ps1 -SourceDir "C:\Videos\MyFolder"

    3. Compress with custom output:
       .\Compressor_7z.ps1 -SourceDir "C:\Data" -ExportDir "D:\Backups"

    4. Show help:
       .\Compressor_7z.ps1 -h
       .\Compressor_7z.ps1 -Help

COMPRESSION SETTINGS:
    Format:        7z
    Level:         Ultra (9)
    Method:        LZMA2
    Dictionary:    256MB
    Word Size:     64
    Solid Block:   16GB
    Threads:       12

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

# ============== CHECK 7-ZIP ==============
if (-not (Test-Path $7zPath)) {
    Write-Host "[ERROR] 7-Zip not found at: $7zPath" -ForegroundColor Red
    Write-Host "Please install 7-Zip and update the `$7zPath variable." -ForegroundColor Yellow
    exit 1
}

# ============== FOLDER SELECTION DIALOG ==============
# If SourceDir is empty, show dialog
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

# Remove trailing backslash if exists
$SourceDir = $SourceDir.TrimEnd('\')

# Validate source path
if (-not (Test-Path $SourceDir)) {
    Write-Host "[ERROR] Source path not found: $SourceDir" -ForegroundColor Red
    exit 1
}

# ============== DETERMINE OUTPUT DIRECTORY ==============
# Default: same as source directory
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
    # It's a directory - get ALL direct children (files AND folders)
    $children = Get-ChildItem -Path $SourceDir -Force
    
    foreach ($child in $children) {
        # Skip hidden/system items
        if ($child.Name -notmatch '^\.') {
            $items += $child
        }
    }
} else {
    # It's a single file
    $items += $itemInfo
}

# Filter out system/hidden items
$items = $items | Where-Object { $_.Attributes -notmatch 'System' }

if ($items.Count -eq 0) {
    Write-Host "[WARNING] No files or directories found to compress!" -ForegroundColor Yellow
    exit 0
}

# ============== DISPLAY SUMMARY ==============
Write-Host ""
Write-Host "========================================" -ForegroundColor Magenta
Write-Host "       COMPRESSION SETTINGS           " -ForegroundColor Magenta
Write-Host "========================================" -ForegroundColor Magenta
Write-Host "  Source Dir   : $SourceDir" -ForegroundColor White
Write-Host "  Export Dir   : $ExportDir" -ForegroundColor White
Write-Host "  Items Found  : $($items.Count)" -ForegroundColor White
Write-Host "  Format       : 7z (LZMA2, Ultra)" -ForegroundColor White
Write-Host "  Dictionary   : 256MB" -ForegroundColor White
Write-Host "  Solid Block  : 16GB" -ForegroundColor White
Write-Host "  Threads      : 12" -ForegroundColor White
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
    $outputFile = Join-Path $ExportDir "$baseName.7z"
    
    # If file exists, add number suffix
    $counter = 1
    while (Test-Path $outputFile) {
        $outputFile = Join-Path $ExportDir "$baseName ($counter).7z"
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
    
    # ========================================================
    # KEY FIX: Use & (call operator) instead of Start-Process
    # This properly handles paths with spaces
    # ========================================================
    
    & $7zPath a -t7z -mx=9 -m0=lzma2 -md=256m -mfb=64 -ms=16g -mmt=12 -r -y -- "$outputFile" "$inputPath\*"
    
    $exitCode = $LASTEXITCODE
    
    if ($exitCode -eq 0) {
        # Calculate original size (recursive)
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