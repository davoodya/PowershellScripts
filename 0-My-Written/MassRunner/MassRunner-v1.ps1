#!/usr/bin/env pwsh
<#
.SYNOPSIS
    MassRunner - Execute commands in bulk from a text file

.DESCRIPTION
    Reads each line from a text file and executes a specified command with that line as an argument.
    Perfect for batch Git cloning, opening multiple files, or running batch processes.

.EXAMPLE
    .\MassRunner.ps1 -Command "git clone" -File "C:\repos.txt"

.EXAMPLE
    .\MassRunner.ps1 -Command "notepad++" -File "C:\files.txt" -DelaySeconds 2

.EXAMPLE
    .\MassRunner.ps1 -Command "python" -File "C:\scripts.txt"
#>

param(
    [Parameter(Mandatory=$false)]
    [Alias("c")]
    [string]$Command,
    
    [Parameter(Mandatory=$false)]
    [Alias("f")]
    [string]$File,
    
    [Parameter(Mandatory=$false)]
    [Alias("d")]
    [int]$DelaySeconds = 0,
    
    [Parameter(Mandatory=$false)]
    [Alias("h", "?")]
    [switch]$Help
)

# Show help with colors
if ($Help -or ($Command -eq $null -and $File -eq $null)) {
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  MASS RUNNER v2.0 - Bulk Command Executor" -ForegroundColor White
    Write-Host "═══════════════════════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    
    # SYNOPSIS
    Write-Host "SYNOPSIS" -ForegroundColor Green
    Write-Host "  MassRunner.ps1 -Command <command> -File <filepath> [-DelaySeconds <seconds>]" -ForegroundColor White
    Write-Host ""
    
    # DESCRIPTION
    Write-Host "DESCRIPTION" -ForegroundColor Green
    Write-Host "  Reads each line from a text file and executes the specified command with that line" -ForegroundColor White
    Write-Host "  as an argument. Waits for each command to complete before starting the next one." -ForegroundColor White
    Write-Host ""
    
    # PARAMETERS
    Write-Host "PARAMETERS" -ForegroundColor Green
    Write-Host "  -Command, -c     " -NoNewline -ForegroundColor DarkYellow
    Write-Host "<string>   Command to execute (e.g., 'git clone', 'notepad.exe')" -ForegroundColor White
    Write-Host "  -File, -f        " -NoNewline -ForegroundColor DarkYellow
    Write-Host "<string>   Path to text file containing arguments (one per line)" -ForegroundColor White
    Write-Host "  -DelaySeconds, -d" -NoNewline -ForegroundColor DarkYellow
    Write-Host "<int>     Wait N seconds between each command" -ForegroundColor White
    Write-Host "  -Help, -h, -?    " -NoNewline -ForegroundColor DarkYellow
    Write-Host "<switch>  Display this help message" -ForegroundColor White
    Write-Host ""
    
    # EXAMPLES
    Write-Host "EXAMPLES" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "  # Clone multiple Git repositories from a file" -ForegroundColor DarkYellow
    Write-Host '  .\MassRunner.ps1 -Command "git clone" -File "C:\repos.txt"' -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "  # Open multiple files with Notepad++ with 2 second delay" -ForegroundColor DarkYellow
    Write-Host '  .\MassRunner.ps1 -Command "C:\Program Files\Notepad++\notepad++.exe" -File "C:\files.txt" -DelaySeconds 2' -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "  # Run Python scripts sequentially" -ForegroundColor DarkYellow
    Write-Host '  .\MassRunner.ps1 -Command "python" -File "C:\scripts.txt"' -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "  # Open URLs in default browser" -ForegroundColor DarkYellow
    Write-Host '  .\MassRunner.ps1 -Command "start" -File "C:\urls.txt"' -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "  # Execute multiple batch files with 3 second delay" -ForegroundColor DarkYellow
    Write-Host '  .\MassRunner.ps1 -Command "cmd /c" -File "C:\batch_files.txt" -DelaySeconds 3' -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "  # Download multiple files using curl" -ForegroundColor DarkYellow
    Write-Host '  .\MassRunner.ps1 -Command "curl -O" -File "C:\download_urls.txt"' -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "  # Extract multiple archives to specific locations" -ForegroundColor DarkYellow
    Write-Host '  .\MassRunner.ps1 -Command "tar -xf" -File "C:\archives.txt"' -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "  # Run multiple PowerShell scripts" -ForegroundColor DarkYellow
    Write-Host '  .\MassRunner.ps1 -Command "powershell -File" -File "C:\ps_scripts.txt"' -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "═══════════════════════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    exit 0
}

# Validate required parameters
if (-not $Command) {
    Write-Host "`n[ERROR] Missing -Command parameter" -ForegroundColor Red
    Write-Host "[TIP] Use -h for help`n" -ForegroundColor Yellow
    exit 1
}

if (-not $File) {
    Write-Host "`n[ERROR] Missing -File parameter" -ForegroundColor Red
    Write-Host "[TIP] Use -h for help`n" -ForegroundColor Yellow
    exit 1
}

# Check if file exists
if (-not (Test-Path $File)) {
    Write-Host "`n[ERROR] File not found: $File`n" -ForegroundColor Red
    exit 1
}

# Read and process file content
$items = Get-Content $File | Where-Object { $_.Trim() -ne "" -and -not $_.StartsWith('#') } | ForEach-Object { $_.Trim() }

if ($items.Count -eq 0) {
    Write-Host "`n[WARNING] No valid items found in: $File`n" -ForegroundColor Yellow
    exit 0
}

# Find git.exe if command is "git clone"
$actualCommand = $Command
$isGitCommand = $Command -eq "git clone"

if ($isGitCommand) {
    $gitPaths = @(
        (Get-Command git -ErrorAction SilentlyContinue).Source,
        "C:\Program Files\Git\bin\git.exe",
        "C:\Program Files (x86)\Git\bin\git.exe",
        "$env:ProgramFiles\Git\bin\git.exe",
        "${env:ProgramFiles(x86)}\Git\bin\git.exe"
    )
    
    $gitExe = $gitPaths | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
    
    if ($gitExe) {
        $actualCommand = $gitExe
        Write-Host "[INFO] Found Git at: $gitExe" -ForegroundColor Cyan
    } else {
        Write-Host "[ERROR] Git not found! Please install Git or add it to PATH" -ForegroundColor Red
        exit 1
    }
}

# Display header
Write-Host "`n═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  MASS RUNNER EXECUTION STARTED" -ForegroundColor White
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Command:     $Command" -ForegroundColor Gray
Write-Host "  Items:       $($items.Count)" -ForegroundColor Gray
Write-Host "  Source:      $(Split-Path $File -Leaf)" -ForegroundColor Gray
if ($DelaySeconds -gt 0) { Write-Host "  Delay:       $DelaySeconds seconds" -ForegroundColor Gray }
Write-Host "═══════════════════════════════════════════════════════════════`n" -ForegroundColor Cyan

$successCount = 0
$failCount = 0
$currentIndex = 0
$failedItems = @()

foreach ($item in $items) {
    $currentIndex++
    
    # Display current item header
    Write-Host "[$currentIndex/$($items.Count)] Processing:" -NoNewline -ForegroundColor Yellow
    Write-Host " $item" -ForegroundColor White
    
    try {
        if ($isGitCommand) {
            # Special handling for git clone
            $arguments = "clone `"$item`""
            Write-Host "  → Running: git clone ..." -ForegroundColor Gray
            
            $process = Start-Process -FilePath $actualCommand -ArgumentList $arguments -NoNewWindow -Wait -PassThru
            
            if ($process.ExitCode -eq 0) {
                $repoName = ($item -split '/')[-1] -replace '\.git$', ''
                Write-Host "  ✅ Cloned: $repoName" -ForegroundColor Green
                $successCount++
            } else {
                Write-Host "  ❌ Failed (exit code: $($process.ExitCode))" -ForegroundColor Red
                $failCount++
                $failedItems += "[$currentIndex] $item (Exit code: $($process.ExitCode))"
            }
        }
        else {
            # Generic command handling
            $process = Start-Process -FilePath $Command -ArgumentList "`"$item`"" -NoNewWindow -Wait -PassThru
            
            if ($process.ExitCode -eq 0) {
                Write-Host "  ✅ Success" -ForegroundColor Green
                $successCount++
            } else {
                Write-Host "  ❌ Failed (exit code: $($process.ExitCode))" -ForegroundColor Red
                $failCount++
                $failedItems += "[$currentIndex] $item (Exit code: $($process.ExitCode))"
            }
        }
    }
    catch {
        Write-Host "  ❌ Error: $($_.Exception.Message)" -ForegroundColor Red
        $failCount++
        $failedItems += "[$currentIndex] $item (Error: $($_.Exception.Message))"
    }
    
    # Add separator after each command (except last)
    if ($currentIndex -lt $items.Count) {
        Write-Host ""
        Write-Host "------------------------------------------" -ForegroundColor DarkGray
        Write-Host ""
    }
    
    # Delay between commands (except after last)
    if ($DelaySeconds -gt 0 -and $currentIndex -lt $items.Count) {
        Write-Host "  ⏳ Waiting $DelaySeconds seconds..." -ForegroundColor Gray
        Start-Sleep -Seconds $DelaySeconds
        Write-Host ""
    }
}

# Final summary
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
if ($successCount -eq $items.Count) {
    Write-Host "  ✅ ALL COMPLETED SUCCESSFULLY" -ForegroundColor Green
} elseif ($successCount -eq 0) {
    Write-Host "  ❌ ALL OPERATIONS FAILED" -ForegroundColor Red
} else {
    Write-Host "  ⚠️  PARTIAL COMPLETION" -ForegroundColor Yellow
}
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  ✅ Successful: $successCount" -ForegroundColor Green
Write-Host "  ❌ Failed:     $failCount" -ForegroundColor Red
Write-Host "  📊 Success Rate: $([math]::Round(($successCount / $items.Count) * 100, 1))%" -ForegroundColor White

# Show failed items details
if ($failedItems.Count -gt 0) {
    Write-Host ""
    Write-Host "  ⚠️  FAILED ITEMS:" -ForegroundColor Yellow
    foreach ($failedItem in $failedItems) {
        Write-Host "     • $failedItem" -ForegroundColor Red
    }
}

Write-Host "═══════════════════════════════════════════════════════════════`n" -ForegroundColor Cyan

if ($failCount -gt 0) { exit 1 } else { exit 0 }