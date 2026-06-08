# backuper.ps1
# Local Backup Script with persistent storage, skip/replace, and scheduling

param(
    [Parameter(Position=0)]
    [string[]]$Source,
    
    [Parameter(Position=1)]
    [string[]]$Target,
    
    [switch]$Save,
    
    [switch]$ResetSource,
    
    [switch]$ResetTarget,
    
    [switch]$Help,
    
    [switch]$Replace,
    
    [switch]$Schedule
)

# ============================================
# Configuration
# ============================================
$script:ConfigFile = Join-Path $PSScriptRoot "backuper_config.json"
$script:TaskName = "BackuperScript"
$script:ScriptPath = $PSCommandPath

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

function Register-ScheduledTask {
    try {
        # Check if task already exists
        $existingTask = Get-ScheduledTask -TaskName $script:TaskName -ErrorAction SilentlyContinue
        
        if ($existingTask) {
            Write-Host "Task '$script:TaskName' already exists. Removing old task..." -ForegroundColor Yellow
            Unregister-ScheduledTask -TaskName $script:TaskName -Confirm:$false
        }
        
        # Create action - run PowerShell with the script
        $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$script:ScriptPath`""
        
        # Create trigger - run at logon
        $trigger = New-ScheduledTaskTrigger -AtLogOn
        
        # Create principal - run for current user
        $principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Limited
        
        # Create settings
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable:$false
        
        # Register the task
        Register-ScheduledTask -TaskName $script:TaskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force | Out-Null
        
        Write-Host "Task '$script:TaskName' registered successfully!" -ForegroundColor Green
        Write-Host "The script will run automatically at Windows logon." -ForegroundColor Cyan
        return $true
    }
    catch {
        Write-Host "Error: Cannot register scheduled task: $_" -ForegroundColor Red
        return $false
    }
}

function Copy-ItemWithSkip {
    param(
        [string]$SourcePath,
        [string]$TargetPath,
        [bool]$Replace
    )
    
    # Get source item
    $sourceItem = Get-Item -LiteralPath $SourcePath -Force -ErrorAction SilentlyContinue
    
    if (-not $sourceItem) {
        Write-Host "  Warning: Source not found - $SourcePath" -ForegroundColor Red
        return @{ Status = "Error"; Message = "Source not found" }
    }
    
    # Determine destination path
    $destPath = Join-Path -Path $TargetPath -ChildPath $sourceItem.Name
    
    # Check if destination exists
    $destExists = Test-Path -LiteralPath $destPath
    
    # If not replacing and destination exists, skip
    if (-not $Replace -and $destExists) {
        # For files - skip
        if (-not $sourceItem.PSIsContainer) {
            return @{ Status = "Skipped"; Message = "File already exists" }
        }
        
        # For directories - need to check contents recursively
        # We'll copy the directory structure and missing items
        return Copy-DirectoryContents -SourceDir $SourcePath -TargetDir $destPath -Replace $Replace
    }
    
    # If replacing and destination exists, remove first
    if ($Replace -and $destExists) {
        try {
            if ($sourceItem.PSIsContainer) {
                Remove-Item -LiteralPath $destPath -Recurse -Force -ErrorAction Stop
            }
            else {
                Remove-Item -LiteralPath $destPath -Force -ErrorAction Stop
            }
        }
        catch {
            return @{ Status = "Error"; Message = "Cannot remove existing: $_" }
        }
    }
    
    # Perform the copy
    try {
        if ($sourceItem.PSIsContainer) {
            # Copy directory
            Copy-Item -LiteralPath $SourcePath -Destination $destPath -Recurse -Force -ErrorAction Stop
            return @{ Status = "Success"; Message = "Directory copied" }
        }
        else {
            # Copy file
            Copy-Item -LiteralPath $SourcePath -Destination $destPath -Force -ErrorAction Stop
            return @{ Status = "Success"; Message = "File copied" }
        }
    }
    catch {
        return @{ Status = "Error"; Message = $_.Exception.Message }
    }
}

function Copy-DirectoryContents {
    param(
        [string]$SourceDir,
        [string]$TargetDir,
        [bool]$Replace
    )
    
    # Ensure target directory exists
    if (-not (Test-Path -LiteralPath $TargetDir)) {
        try {
            New-Item -ItemType Directory -Path $TargetDir -Force -ErrorAction Stop | Out-Null
        }
        catch {
            return @{ Status = "Error"; Message = "Cannot create target directory: $_" }
        }
    }
    
    # Get all items in source directory
    $sourceItems = Get-ChildItem -LiteralPath $SourceDir -Force -ErrorAction SilentlyContinue
    
    if (-not $sourceItems) {
        return @{ Status = "Success"; Message = "Empty directory" }
    }
    
    $results = @{
        Copied = 0
        Skipped = 0
        Errors = 0
    }
    
    foreach ($item in $sourceItems) {
        $destItemPath = Join-Path -Path $TargetDir -ChildPath $item.Name
        $destExists = Test-Path -LiteralPath $destItemPath
        
        if (-not $Replace -and $destExists) {
            # If it's a directory, we need to check its contents
            if ($item.PSIsContainer) {
                # Recursively check and copy directory contents
                $subResult = Copy-DirectoryContents -SourceDir $item.FullName -TargetDir $destItemPath -Replace $Replace
                $results.Copied += $subResult.Copied
                $results.Skipped += $subResult.Skipped
                $results.Errors += $subResult.Errors
            }
            else {
                # File exists and not replacing - skip
                $results.Skipped++
            }
        }
        elseif ($Replace -and $destExists) {
            # Replace mode - remove and copy
            try {
                if ($item.PSIsContainer) {
                    Remove-Item -LiteralPath $destItemPath -Recurse -Force -ErrorAction Stop
                }
                else {
                    Remove-Item -LiteralPath $destItemPath -Force -ErrorAction Stop
                }
            }
            catch {
                $results.Errors++
                continue
            }
            
            # Now copy
            try {
                Copy-Item -LiteralPath $item.FullName -Destination $destItemPath -Recurse -Force -ErrorAction Stop
                $results.Copied++
            }
            catch {
                $results.Errors++
            }
        }
        else {
            # Destination doesn't exist - copy
            try {
                Copy-Item -LiteralPath $item.FullName -Destination $destItemPath -Recurse -Force -ErrorAction Stop
                $results.Copied++
            }
            catch {
                $results.Errors++
            }
        }
    }
    
    return $results
}

function Show-Help {
    Write-Host @"

========================================
         BACKUPER - Local Backup Tool
========================================

OVERVIEW:
    Backuper is a local backup script that copies files/directories
    from multiple source paths to multiple target paths. It supports
    persistent configuration, skip/replace modes, and scheduled execution.

USAGE:
    .\backuper.ps1 [-Source <paths>] [-Target <paths>] [-Save] [-Replace] [-Schedule] [-ResetSource] [-ResetTarget] [-Help]

FLAGS:
    -Source <paths>     Specify source file(s) or directory(ies) to backup.
                        Can be multiple paths separated by commas.
                        
    -Target <paths>    Specify target directory(ies) for backup.
                        Can be multiple paths separated by commas.
                        
    -Save              Save the current source and target paths for future use.
                        These paths will be used when running the script without parameters.
                        
    -Replace           Copy files and replace existing files in target directories.
                        By default, existing files are skipped (safer mode).
                        
    -Schedule          Register the script to run automatically at Windows logon.
                        The script will execute once after each user logon.
                        
    -ResetSource       Clear all saved source paths.
                        
    -ResetTarget       Clear all saved target paths.
                        
    -Help              Display this help message.

COPY MODES:
    Default (Skip)     - Does NOT overwrite existing files/directories
                       - Only copies items that don't exist in target
                       - Best for daily incremental backups
                       
    Replace Mode       - Overwrites existing files/directories with source
                       - Use -Replace flag to enable

========================================
              EXAMPLES
========================================

1. Basic backup with skip mode (default):
   .\backuper.ps1 -Source "H:\Files\Doc.txt" -Target "D:\Backup"

2. Multiple sources and targets:
   .\backuper.ps1 -Source "H:\My Files", "D:\Documents" -Target "D:\Backups", "F:\Backups"

3. Save paths for future use:
   .\backuper.ps1 -Source "H:\Important" -Target "D:\Backup" -Save
   
   Then run later without parameters:
   .\backuper.ps1

4. Add new paths to saved configuration:
   .\backuper.ps1 -Source "C:\NewFolder" -Target "E:\NewBackup" -Save

5. Force replace existing files:
   .\backuper.ps1 -Source "H:\Files" -Target "D:\Backup" -Replace

6. Save and replace mode together:
   .\backuper.ps1 -Source "H:\DailyBackup" -Target "D:\Backup" -Save -Replace

7. Schedule script to run at Windows logon:
   .\backuper.ps1 -Schedule
   
   (Note: Run with saved paths or specify source/target first)

8. Paths with spaces:
   .\backuper.ps1 -Source "C:\My Documents\File.txt" -Target "E:\Backup Folder"

9. Clear saved sources:
   .\backuper.ps1 -ResetSource

10. Clear saved targets:
    .\backuper.ps1 -ResetTarget

11. View this help:
    .\backuper.ps1 -Help

========================================
              NOTES
========================================

- If script is run without -Source and -Target, it uses saved paths
- If no saved paths exist, an error is displayed
- Use -Save to persist paths between executions
- Default mode skips existing files (incremental backup)
- Use -Replace to overwrite existing files
- -Schedule adds a Task Scheduler entry for logon execution

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
# Handle Schedule Flag
# ============================================
if ($Schedule) {
    Register-ScheduledTask
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
    Write-Host "`Or run with -Help for more information." -ForegroundColor Yellow
    exit 1
}

# ============================================
# Display Configuration
# ============================================
$copyMode = if ($Replace) { "REPLACE (Overwrite existing files)" } else { "SKIP (Don't overwrite existing files)" }

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "       BACKUP CONFIGURATION" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "`nCopy Mode: $copyMode" -ForegroundColor $(if ($Replace) { "Yellow" } else { "Green" })
Write-Host "`nSource paths:" -ForegroundColor Yellow
$source_dirs | ForEach-Object { Write-Host "  [+] $_" }
Write-Host "`nTarget paths:" -ForegroundColor Yellow
$target_dirs | ForEach-Object { Write-Host "  [+] $_" }
Write-Host "`n========================================`n" -ForegroundColor Cyan

# ============================================
# Perform Copy Operations
# ============================================
$global:successCount = 0
$global:skippedCount = 0
$global:errorCount = 0

foreach ($target in $target_dirs) {
    # Ensure target directory exists
    if (-not (Test-Path -LiteralPath $target)) {
        try {
            Write-Host "Creating target directory: $target" -ForegroundColor Yellow
            New-Item -ItemType Directory -Path $target -Force -ErrorAction Stop | Out-Null
        }
        catch {
            Write-Host "Error: Cannot create target directory '$target': $_" -ForegroundColor Red
            $global:errorCount++
            continue
        }
    }
    
    foreach ($source in $source_dirs) {
        # Check if source exists
        if (-not (Test-Path -LiteralPath $source)) {
            Write-Host "Warning: Source does not exist - skipping: $source" -ForegroundColor Red
            $global:errorCount++
            continue
        }
        
        # Get source item info
        $item = Get-Item -LiteralPath $source -Force
        
        # Determine destination path
        $destPath = Join-Path -Path $target -ChildPath $item.Name
        
        # Check if destination exists
        $destExists = Test-Path -LiteralPath $destPath
        
        if ($item.PSIsContainer) {
            # It's a directory
            if ($destExists) {
                # Directory exists - copy contents recursively
                Write-Host "Processing directory: $source -> $destPath" -ForegroundColor Cyan
                
                $result = Copy-DirectoryContents -SourceDir $source -TargetDir $destPath -Replace $Replace
                
                $global:successCount += $result.Copied
                $global:skippedCount += $result.Skipped
                $global:errorCount += $result.Errors
            }
            else {
                # Directory doesn't exist - copy entire directory
                Write-Host "Copying new directory: $source -> $destPath" -ForegroundColor Green
                try {
                    Copy-Item -LiteralPath $source -Destination $destPath -Recurse -Force -ErrorAction Stop
                    $global:successCount++
                }
                catch {
                    Write-Host "Error: $_" -ForegroundColor Red
                    $global:errorCount++
                }
            }
        }
        else {
            # It's a file
            if ($destExists -and -not $Replace) {
                # File exists and not replacing - skip
                Write-Host "Skipped (already exists): $destPath" -ForegroundColor DarkGray
                $global:skippedCount++
            }
            else {
                # Copy file
                Write-Host "Copying file: $source -> $destPath" -ForegroundColor Green
                try {
                    if ($destExists -and $Replace) {
                        Remove-Item -LiteralPath $destPath -Force -ErrorAction Stop
                    }
                    Copy-Item -LiteralPath $source -Destination $destPath -Force -ErrorAction Stop
                    $global:successCount++
                }
                catch {
                    Write-Host "Error: $_" -ForegroundColor Red
                    $global:errorCount++
                }
            }
        }
    }
}

# ============================================
# Summary
# ============================================
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "          BACKUP SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Successful operations: $global:successCount" -ForegroundColor Green
Write-Host "Skipped (existing):    $global:skippedCount" -ForegroundColor Yellow
Write-Host "Failed operations:     $global:errorCount" -ForegroundColor $(if ($global:errorCount -gt 0) { "Red" } else { "Green" })
Write-Host "========================================`n" -ForegroundColor Cyan