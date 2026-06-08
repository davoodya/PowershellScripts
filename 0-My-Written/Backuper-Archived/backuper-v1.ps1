# backuper.ps1
# Local Backup Script - copies files/directories from source to multiple targets

param(
    [Parameter(Position=0)]
    [string[]]$Source,
    
    [Parameter(Position=1)]
    [string[]]$Target
)

# ============================================
# Initialize arrays
# ============================================
$source_dirs = @()
$target_dirs = @()

# ============================================
# Add source paths from command line arguments
# ============================================
if ($Source) {
    foreach ($src in $Source) {
        if ($src -and $src.Trim() -ne "") {
            $source_dirs += $src.Trim()
        }
    }
}

# ============================================
# Add target paths from command line arguments
# ============================================
if ($Target) {
    foreach ($tgt in $Target) {
        if ($tgt -and $tgt.Trim() -ne "") {
            $target_dirs += $tgt.Trim()
        }
    }
}

# ============================================
# Validation: Check if source and target are provided
# ============================================
if ($source_dirs.Count -eq 0) {
    Write-Host "Error: No source paths specified!" -ForegroundColor Red
    Write-Host "Usage: .\backuper.ps1 -Source `"<path1>`", `"<path2>`" -Target `"<path1>`", `"<path2>`"" -ForegroundColor Yellow
    Write-Host "Example: .\backuper.ps1 -Source `"H:\Repo\Dir1`", `"D:\Files\doc.txt`" -Target `"D:\Backup`"" -ForegroundColor Cyan
    exit 1
}

if ($target_dirs.Count -eq 0) {
    Write-Host "Error: No target directories specified!" -ForegroundColor Red
    Write-Host "Usage: .\backuper.ps1 -Source `"<path1>`" -Target `"<path1>`", `"<path2>`"" -ForegroundColor Yellow
    exit 1
}

# ============================================
# Display configuration
# ============================================
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "       BACKUP CONFIGURATION" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "`nSource paths:" -ForegroundColor Yellow
$source_dirs | ForEach-Object { Write-Host "  [+] $_" }
Write-Host "`nTarget paths:" -ForegroundColor Yellow
$target_dirs | ForEach-Object { Write-Host "  [+] $_" }
Write-Host "`n========================================`n" -ForegroundColor Cyan

# ============================================
# Perform copy operations
# ============================================
$successCount = 0
$errorCount = 0

foreach ($target in $target_dirs) {
    # Ensure target directory exists
    if (-not (Test-Path -LiteralPath $target)) {
        try {
            Write-Host "Creating target directory: $target" -ForegroundColor Yellow
            New-Item -ItemType Directory -Path $target -Force -ErrorAction Stop | Out-Null
        }
        catch {
            Write-Host "Error: Cannot create target directory '$target': $_" -ForegroundColor Red
            $errorCount++
            continue
        }
    }
    
    foreach ($source in $source_dirs) {
        # Check if source exists
        if (-not (Test-Path -LiteralPath $source)) {
            Write-Host "Warning: Source does not exist - skipping: $source" -ForegroundColor Red
            $errorCount++
            continue
        }
        
        # Get item info
        $item = Get-Item -LiteralPath $source -Force
        
        # Determine destination path
        $destPath = Join-Path -Path $target -ChildPath $item.Name
        
        try {
            if ($item.PSIsContainer) {
                # It's a directory - copy recursively
                Write-Host "Copying directory: $source -> $destPath" -ForegroundColor Green
                
                # Remove existing directory if exists to ensure clean copy
                if (Test-Path -LiteralPath $destPath) {
                    Remove-Item -LiteralPath $destPath -Recurse -Force -ErrorAction Stop
                }
                
                Copy-Item -LiteralPath $source -Destination $destPath -Recurse -Force -ErrorAction Stop
            }
            else {
                # It's a file - copy directly
                Write-Host "Copying file: $source -> $destPath" -ForegroundColor Green
                Copy-Item -LiteralPath $source -Destination $destPath -Force -ErrorAction Stop
            }
            $successCount++
        }
        catch {
            Write-Host "Error copying '$source' to '$destPath': $_" -ForegroundColor Red
            $errorCount++
        }
    }
}

# ============================================
# Summary
# ============================================
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "          BACKUP SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Successful operations: $successCount" -ForegroundColor Green
Write-Host "Failed operations:     $errorCount" -ForegroundColor $(if ($errorCount -gt 0) { "Red" } else { "Green" })
Write-Host "========================================`n" -ForegroundColor Cyan