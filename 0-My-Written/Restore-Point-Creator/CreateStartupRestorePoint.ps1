<#
.SYNOPSIS
    Create a daily System Restore Point at Windows startup.

.DESCRIPTION
    This script is intended to be executed automatically by Windows Task Scheduler
    when the system starts.

    Workflow:
    1. Check whether a Restore Point has already been created today.
    2. If a Restore Point exists for today, skip creation.
    3. If no Restore Point exists for today, create a new one.
    4. Display the result in a Message Box.
    5. Exit automatically.

.REQUIREMENTS
    - Run with Administrator privileges.
    - System Protection must be enabled on the system drive.
    - Recommended Registry Setting:

      HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore
      DWORD: SystemRestorePointCreationFrequency = 0

      This removes the default 24-hour restriction imposed by Windows.

.RECOMMENDED TASK SCHEDULER SETTINGS
    Trigger:
        At startup

    Security:
        Run whether user is logged on or not
        Run with highest privileges

    Action:
        Program:
            powershell.exe

        Arguments:
            -ExecutionPolicy Bypass -File "C:\Scripts\CreateStartupRestorePoint.ps1"

.AUTHOR
    ChatGPT Generated Script

.VERSION
    1.0
#>

Add-Type -AssemblyName System.Windows.Forms

try
{
    $Today = (Get-Date).Date

    $RestorePoints = Get-ComputerRestorePoint -ErrorAction Stop

    $TodayRestorePoint = $RestorePoints | Where-Object {
        $_.CreationTime.Date -eq $Today
    }

    if ($TodayRestorePoint)
    {
        [System.Windows.Forms.MessageBox]::Show(
            "Today Restore Point Exists.`n`nRestore Point creation skipped.",
            "Restore Point Manager",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )

        exit 0
    }

    $Description = "Startup Restore Point - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

    Checkpoint-Computer `
        -Description $Description `
        -RestorePointType MODIFY_SETTINGS `
        -ErrorAction Stop

    [System.Windows.Forms.MessageBox]::Show(
        "Restore Point Created Successfully.`n`nDescription:`n$Description",
        "Restore Point Manager",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information
    )

    exit 0
}
catch
{
    $ErrorMessage = $_.Exception.Message

    [System.Windows.Forms.MessageBox]::Show(
        "Failed to create Restore Point.`n`nError:`n$ErrorMessage",
        "Restore Point Manager",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error
    )

    exit 1
}