<#
.SYNOPSIS
    Manages system shutdown, sleep, restart, or screen lock actions with a specified delay.

.DESCRIPTION
    This script allows users to schedule system shutdown, hibernation (sleep), restart,
    or screen lock operations after a specified number of minutes.

.PARAMETER Action
    The action to perform. Valid options are: --shutdown, --sleep, --restart, --lock.

.PARAMETER Minute
    The delay in minutes before the action is performed. This parameter is ignored if --help or -h is used.

.EXAMPLE
    .\shutdowner.ps1 --shutdown 91
    Schedules the system to shut down in 91 minutes.

.EXAMPLE
    .\shutdowner.ps1 --sleep 75
    Schedules the system to hibernate (sleep) in 75 minutes.

.EXAMPLE
    .\shutdowner.ps1 --restart 62
    Schedules the system to restart in 62 minutes.

.EXAMPLE
    .\shutdowner.ps1 --lock 50
    Locks the screen after 50 minutes. Note: The screen is locked immediately upon command execution due to limitations with PowerShell's direct scheduling of screen lock.

.EXAMPLE
    .\shutdowner.ps1 --help
    Displays this help information.

.NOTES
    Author: Your Name/AI Assistant
    Version: 1.0
    Requires: Administrator privileges (remove if not needed).
#>
param(
    [Parameter(Mandatory=$false, HelpMessage="The action to perform: --shutdown, --sleep, --restart, --lock. Use --help for details.")]
    [string]$Action,

    [Parameter(Mandatory=$false, HelpMessage="The delay in minutes. Ignored for --help.")]
    [int]$Minute
)

# Handle Help parameters first
if ($Action -eq "--help" -or $Action -eq "-h") {
    Write-Host "Syntax:" -ForegroundColor Green
    Write-Host "  shutdowner.ps1 --ACTION [minutes]"
    Write-Host ""
    Write-Host "Actions:" -ForegroundColor Green
    Write-Host "  --shutdown : Shuts down the computer."
    Write-Host "  --sleep    : Puts the computer into hibernation (sleep mode)."
    Write-Host "  --restart  : Restarts the computer."
    Write-Host "  --lock     : Locks the computer screen."
    Write-Host "-----------------------------------------------------" -ForegroundColor DarkYellow
    Write-Host ""
    Write-Host "Example Usage: " -ForegroundColor Green
    Write-Host ""
    Write-Host "Shutdown in 91 Minutes:"
    Write-Host "  shutdowner.ps1 --shutdown 91"
    Write-Host "--------------------------------" -ForegroundColor DarkYellow
    Write-Host ""

    Write-Host "Sleep in 75 Minutes:"
    Write-Host "  shutdowner.ps1 --sleep 75"
    Write-Host "--------------------------------" -ForegroundColor DarkYellow
    Write-Host ""

    Write-Host "Restart in 62 Minutes:"
    Write-Host "  shutdowner.ps1 --restart 62"
    Write-Host "--------------------------------" -ForegroundColor DarkYellow
    Write-Host ""

    Write-Host "Lock Screen in 50 Minutes:"
    Write-Host "  shutdowner.ps1 --lock 50"
    Write-Host "--------------------------------" -ForegroundColor DarkYellow
    Write-Host ""
    # Exit after showing help, no further processing needed
    exit
}

# Validate if Action is provided when not showing help
if (-not $Action) {
    Write-Error "Error: --ACTION is required when not using --help or -h."
    Write-Host "Please use --help or -h for usage instructions."
    exit 1
}

# Convert minutes to seconds
$Seconds = $Minute * 60

# Determine the action and execute the command
switch ($Action) {
    "--sleep" {
        Write-Host "Scheduling system to Sleep in $Minute minutes ($Seconds seconds)..."
        # Use Start-Sleep to wait the specified amount of seconds before executing sleep
        Start-Sleep -Seconds $Seconds
        shutdown /h
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to schedule sleep. Error code: $LASTEXITCODE. Ensure hibernation is enabled."
        } else {
            Write-Host "Sleep scheduled successfully."
        }
    }
    "--shutdown" {
        Write-Host "Scheduling system to Shutdown in $Minute minutes ($Seconds seconds)..."
        Start-Sleep -Seconds $Seconds
        shutdown /s
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to schedule shutdown. Error code: $LASTEXITCODE."
        } else {
            Write-Host "Shutdown scheduled successfully."
        }
    }
    "--restart" {
        Write-Host "Scheduling system to Restart in $Minute minutes ($Seconds seconds)..."
        Start-Sleep -Seconds $Seconds
        shutdown /r
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to schedule restart. Error code: $LASTEXITCODE."
        } else {
            Write-Host "Restart scheduled successfully."
        }
    }
    "--lock" {
        Write-Host "Locking the screen in $Minute minutes..."
        # Use Start-Sleep to wait for the specified minutes before locking the screen
        Start-Sleep -Seconds $Seconds
        Write-Host "Locking the workstation now."
        rundll32.exe user32.dll,LockWorkStation
        Write-Host "Screen locked."
    }
    default {
        Write-Error "Invalid action specified: '$Action'. Please use --help or -h for a list of valid actions."
        exit 1
    }
}
