# backuper.ps1
# Local Backup Script with persistent storage

param(
    [Parameter(Position=0)]
    [string[]]$Source,
    
    [Parameter(Position=1)]
    [string[]]$Target,
    
    [switch]$Save,
    
    [switch]$ResetSource,
    
    [switch]$ResetTarget,
    
    [switch]$Help
)

# ============================================
# Configuration
# ============================================
$script:ConfigFile = Join-Path $PSScriptRoot "backuper_config.json"

# ============================================
# Helper Functions
# ============================================

function Load-Config {
    if (Test-Path -LiteralPath $script:ConfigFile) {
        try {
            $content = Get-Content -LiteralPath $script:ConfigFile -Raw -ErrorAction Stop
            return $content | ConvertFrom-Json
        }
        catch {
            return @{ Source = @(); Target = @() }
        }
    }
    return @{ Source = @(); Target = @() }
}

function Save-Config {
    param(
        [hashtable]$Config
    )
    
    try {
        $Config | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $script:ConfigFile -Force -ErrorAction Stop
        return $true
    }
    catch {
        Write-Host "Error: Cannot save configuration: $_" -ForegroundColor Red
        return $false
    }
}

function Show-Help {
    Write-Host @"

========================================
         BACKUPER - Local Backup Tool
========================================

USAGE:
    .\backuper.ps1 [-Source <path1>, <path2>, ...] [-Target <path1>, <path2>, ...] [-Save] [-ResetSource] [-ResetTarget] [-Help]

FLAGS:
    -Source <paths>    Specify source file(s) or directory(ies) to backup
                      Can be used multiple times or with comma-separated values
                      
    -Target <paths>   Specify target directory(ies) for backup
                      Can be used multiple times or with comma-separated values
                      
    -Save             Save the current source and target paths for future use
                      These paths will be used when running the script without parameters
                      
    -ResetSource      Clear all saved source paths
                      
    -ResetTarget     Clear all saved target paths
                      
    -Help            Display this help message

EXAMPLES:
    # Basic usage with source and target
    .\backuper.ps1 -Source "H:\Files\Doc.txt" -Target "D:\Backup"
    
    # Multiple sources and targets
    .\backuper.ps1 -Source "H:\Files\Obsidian", "D:\Notes" -Target "D:\Backups", "F:\Backups"
    
    # Save paths for future use
    .\backuper.ps1 -Source "H:\My Files" -Target "D:\Backup" -Save
    
    # Run with saved paths (no parameters needed)
    .\backuper.ps1
    
    # Add new paths to existing saved paths
    .\backuper.ps1 -Source "C:\NewFolder" -Target "E:\NewBackup" -Save
    
    # Clear saved sources
    .\backuper.ps1 -ResetSource
    
    # Clear saved targets
    .\backuper.ps1 -ResetTarget
    
    # Paths with spaces (use quotes)
    .\backuper.ps1 -Source "C:\My Documents\File.txt" -Target "E:\Backup Folder"

NOTES:
    - If script is run without -Source and -Target, it will use saved paths
    - If no saved paths exist, an error will be displayed
    - Use -Save to persist paths between script executions

========================================

"@ -ForegroundColor Cyan
}

# ============================================
# Handle Help Flag First
# ============================================
if ($Help) {
    Show-Help
    exit 0
}

# ============================================
# Load Saved Configuration
# ============================================
$config = Load-Config
$savedSource = @($config.Source)
$savedTarget = @($config.Target)

# ============================================
# Handle Reset Flags
# ============================================
if ($ResetSource) {
    $savedSource = @()
    $config.Source = @()
    
    if (Save-Config -Config $config) {
        Write-Host "All saved source paths have been cleared." -ForegroundColor Green
    }
    exit 0
}

if ($ResetTarget) {
    $savedTarget = @()
    $config.Target = @()
    
    if (Save-Config -Config $config) {
        Write-Host "All saved target paths have been cleared." -ForegroundColor Green
    }
    exit 0
}

# ============================================
# Process Source Paths
# ============================================
$source_dirs = @()

# Add saved sources
foreach ($src in $savedSource) {
    if ($src -and $src.Trim() -ne "") {
        $source_dirs += $src.Trim()
    }
}

# Add new sources from command line
if ($Source) {
    foreach ($src in $Source) {
        if ($src -and $src.Trim() -ne "") {
            $source_dirs += $src.Trim()
        }
    }
}

# ============================================
# Process Target Paths
# ============================================
$target_dirs = @()

# Add saved targets
foreach ($tgt in $savedTarget) {
    if ($tgt -and $tgt.Trim() -ne "") {
        $target_dirs += $tgt.Trim()
    }
}

# Add new targets from command line
if ($Target) {
    foreach ($tgt in $Target) {
        if ($tgt -and $tgt.Trim() -ne "") {
            $target_dirs += $tgt.Trim()
        }
    }
}

# ============================================
# Save Configuration if -Save flag is used
# ============================================
if ($Save) {
    # Remove duplicates
    $uniqueSources = $source_dirs | Select-Object -Unique
    $uniqueTargets = $target_dirs | Select-Object -Unique
    
    $config.Source = @($uniqueSources)
    $config.Target = @($uniqueTargets)
    
    if (Save-Config -Config $config) {
        Write-Host "Configuration saved successfully!" -ForegroundColor Green
        Write-Host "Saved sources: $($uniqueSources -join ', ')" -ForegroundColor Cyan
        Write-Host "Saved targets: $($uniqueTargets -join ', ')" -ForegroundColor Cyan
    }
    
    # If only saving and not running backup, exit
    # But we should still run the backup after saving
}

# ============================================
# Validation: Check if source and target are provided
# ============================================
if ($source_dirs.Count -eq 0) {
    Write-Host "`nError: No source paths specified!" -ForegroundColor Red
    Write-Host "`nUsage: .\backuper.ps1 -Source `"<path1>`", `"<path2>`" -Target `"<path1>`", `"<path2>`"" -ForegroundColor Yellow
    Write-Host "Example: .\backuper.ps1 -Source `"H:\Repo\Dir1`", `"D:\Files\doc.txt`" -Target `"D:\Backup`"" -ForegroundColor Cyan
    Write-Host "`nOr run with -Help for more information." -ForegroundColor Yellow
    exit 1
}

if ($target_dirs.Count -eq 0) {
    Write-Host "`nError: No target directories specified!" -ForegroundColor Red
    Write-Host "`nUsage: .\backuper.ps1 -Source `"<path1>`" -Target `"<path1>`", `"<path2>`"" -ForegroundColor Yellow
    Write-Host "Example: .\backuper.ps1 -Source `"H:\My Files`" -Target `"D:\Backup`", `"E:\Backup`"" -ForegroundColor Cyan
    Write-Host "`nOr run with -Help for more information." -ForegroundColor Yellow
    exit 1
}

# ============================================
# Display Configuration
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
# Perform Copy Operations
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