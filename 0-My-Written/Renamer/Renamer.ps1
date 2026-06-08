<#
.SYNOPSIS
    Bulk file renamer with add/remove operations at start, end, or anywhere in filenames.

.DESCRIPTION
    This script renames files by adding or removing strings at the beginning, end,
    or anywhere within filenames. It also supports changing file extensions and
    combining multiple operations.

    Two input modes available:
    1. -Path: Process all files in a specified directory
    2. No -Path: Open file selection dialog to pick specific files

.PARAMETER Path
    Optional. Specifies the directory containing files to rename.
    If not provided, a file selection dialog will open.

.PARAMETER Start
    String to add at the beginning of filenames. When used with -Remove, removes
    this string from the beginning instead. Can be combined with -End.

.PARAMETER End
    String to add at the end of filenames (before extension). When used with -Remove,
    removes this string from the end instead. Can be combined with -Start.

.PARAMETER Delete
    String to remove from anywhere in filenames. Can be used with -Ext, but NOT with -Start or -End.

.PARAMETER Remove
    Switch that changes behavior from "add" to "remove" when used with -Start and/or -End.
    When both -Start and -End are present, removes from both ends simultaneously.

.PARAMETER Ext
    Changes the file extension of all files to the specified value (without dot).
    Example: -Ext md changes all extensions to .md
    Can be used with any other parameter except when -Delete is used with -Start/-End.

.PARAMETER WhatIf
    Demonstrates what would happen without actually renaming any files.

.EXAMPLE
    .\Renamer.ps1 -Path "C:\Files" -Start "prefix_"
    Adds "prefix_" to the beginning of all filenames in C:\Files

.EXAMPLE
    .\Renamer.ps1 -Start "dev" -End "_v2" -Ext txt
    Opens file dialog, adds "dev" to beginning, "_v2" to end, and changes extension to .txt

.EXAMPLE
    .\Renamer.ps1 -Delete "temp" -Ext pdf
    Opens file dialog, removes "temp" from anywhere, and changes extension to .pdf

.EXAMPLE
    .\Renamer.ps1 -Path "C:\Files" -Delete "old" -Ext md
    Removes "old" from anywhere AND changes extension to .md

# ============================================
# CHEAT SHEET SUMMARY
# ============================================
# 
# QUICK REFERENCE:
# ----------------
# Add to beginning:     -Start "text"
# Add to end:           -End "text"
# Remove from beginning: -Start "text" -Remove
# Remove from end:      -End "text" -Remove
# Remove from anywhere: -Delete "text"
# Change extension:     -Ext "newExt"
# Combine operations:   -Start "a" -End "b" -Ext "txt"
# Preview changes:      -WhatIf
# Process directory:    -Path "C:\Folder"
# Select files manually: (no -Path parameter)
#
# VALID COMBINATIONS:
# -------------------
# ✓ -Start + -End
# ✓ -Start + -Ext
# ✓ -End + -Ext
# ✓ -Start + -End + -Ext
# ✓ -Delete + -Ext
# ✗ -Delete + -Start
# ✗ -Delete + -End
# ✗ -Remove without -Start or -End
#
.NOTES
    Author: PowerShell Script
    Version: 4.2
    Requires: PowerShell 5.1 or later
#>

[CmdletBinding(DefaultParameterSetName = "Dialog")]
param(
    [Parameter(ParameterSetName = "Path")]
    [ValidateScript({
        if (-not (Test-Path -Path $_ -PathType Container)) {
            throw "Directory does not exist or is not accessible: $_"
        }
        return $true
    })]
    [string]$Path,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Start,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$End,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Delete,

    [Parameter()]
    [switch]$Remove,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Ext,

    [Parameter()]
    [switch]$WhatIf,

    [Parameter()]
    [switch]$Help
)

# Display help if requested
if ($Help -or ($PSBoundParameters.ContainsKey('Help')) -or ($args -contains '-h') -or ($args -contains '--help')) {
    # Function to write colored help text
    function Write-HelpColor {
        param(
            [string]$Text,
            [string]$ForegroundColor = "White"
        )
        Write-Host $Text -ForegroundColor $ForegroundColor
    }
    
    # Header
    Write-Host ""
    Write-Host "FILE RENAMER TOOL v4.1" -ForegroundColor Cyan
    Write-Host "=====================" -ForegroundColor Cyan
    Write-Host ""
    
    # SYNOPSIS
    Write-Host "SYNOPSIS" -ForegroundColor Green
    Write-Host "    Bulk file renamer with add/remove operations at start, end, or anywhere in filenames." -ForegroundColor White
    Write-Host ""
    
    # DESCRIPTION
    Write-Host "DESCRIPTION" -ForegroundColor Green
    Write-Host "    This script renames files by adding or removing strings at the beginning, end," -ForegroundColor White
    Write-Host "    or anywhere within filenames. It also supports changing file extensions and" -ForegroundColor White
    Write-Host "    combining multiple operations." -ForegroundColor White
    Write-Host ""
    Write-Host "    Two input modes available:" -ForegroundColor White
    Write-Host "    1. -Path: Process all files in a specified directory" -ForegroundColor White
    Write-Host "    2. No -Path: Open file selection dialog to pick specific files" -ForegroundColor White
    Write-Host ""
    
    # USAGE
    Write-Host "USAGE" -ForegroundColor Green
    Write-Host "    .\Renamer.ps1 [-Path <directory>] [-Start <string>] [-End <string>]" -ForegroundColor White
    Write-Host "                  [-Delete <string>] [-Remove] [-Ext <extension>] [-WhatIf]" -ForegroundColor White
    Write-Host ""
    
    # PARAMETERS
    Write-Host "PARAMETERS" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "    -Path <string>" -ForegroundColor DarkYellow
    Write-Host "        Specifies the directory containing files to rename." -ForegroundColor White
    Write-Host "        If not provided, a file selection dialog will open." -ForegroundColor White
    Write-Host "        Example: -Path `"C:\MyFiles`"" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "    -Start <string>" -ForegroundColor DarkYellow
    Write-Host "        String to add at the beginning of filenames." -ForegroundColor White
    Write-Host "        When used with -Remove, removes this string from the beginning instead." -ForegroundColor White
    Write-Host "        Example: -Start `"backup_`"" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "    -End <string>" -ForegroundColor DarkYellow
    Write-Host "        String to add at the end of filenames (before extension)." -ForegroundColor White
    Write-Host "        When used with -Remove, removes this string from the end instead." -ForegroundColor White
    Write-Host "        Example: -End `"_v2`"" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "    -Delete <string>" -ForegroundColor DarkYellow
    Write-Host "        String to remove from anywhere in filenames." -ForegroundColor White
    Write-Host "        Can be used with -Ext, but NOT with -Start or -End." -ForegroundColor White
    Write-Host "        Example: -Delete `"temp`"" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "    -Remove" -ForegroundColor DarkYellow
    Write-Host "        Switch that changes behavior from `"add`" to `"remove`" when used with -Start or -End." -ForegroundColor White
    Write-Host "        Example: -Start `"old_`" -Remove" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "    -Ext <extension>" -ForegroundColor DarkYellow
    Write-Host "        Changes the file extension of all files to the specified value (without dot)." -ForegroundColor White
    Write-Host "        Can be used with any other parameter except when -Delete is used with -Start/-End." -ForegroundColor White
    Write-Host "        Example: -Ext pdf" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "    -WhatIf" -ForegroundColor DarkYellow
    Write-Host "        Demonstrates what would happen without actually renaming any files." -ForegroundColor White
    Write-Host "        Example: -WhatIf" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "    -Help, -h, --help" -ForegroundColor DarkYellow
    Write-Host "        Displays this help message." -ForegroundColor White
    Write-Host ""
    
    # CHEAT SHEET
    Write-Host "CHEAT SHEET" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "    ACTION                          COMMAND" -ForegroundColor White
    Write-Host "    ───────────────────────────────────────────────────────────────────────" -ForegroundColor Gray
    
    Write-Host "    Add to beginning               " -ForegroundColor White -NoNewline
    Write-Host "-Start `"text`"" -ForegroundColor Cyan
    
    Write-Host "    Add to end                     " -ForegroundColor White -NoNewline
    Write-Host "-End `"text`"" -ForegroundColor Cyan
    
    Write-Host "    Remove from beginning          " -ForegroundColor White -NoNewline
    Write-Host "-Start `"text`" -Remove" -ForegroundColor Cyan
    
    Write-Host "    Remove from end                " -ForegroundColor White -NoNewline
    Write-Host "-End `"text`" -Remove" -ForegroundColor Cyan
    
    Write-Host "    Remove from anywhere           " -ForegroundColor White -NoNewline
    Write-Host "-Delete `"text`"" -ForegroundColor Cyan
    
    Write-Host "    Change extension               " -ForegroundColor White -NoNewline
    Write-Host "-Ext `"newExt`"" -ForegroundColor Cyan
    
    Write-Host "    Combine operations             " -ForegroundColor White -NoNewline
    Write-Host "-Start `"a`" -End `"b`" -Ext `"txt`"" -ForegroundColor Cyan
    
    Write-Host "    Preview changes                " -ForegroundColor White -NoNewline
    Write-Host "-WhatIf" -ForegroundColor Cyan
    
    Write-Host "    Process directory              " -ForegroundColor White -NoNewline
    Write-Host "-Path `"C:\Folder`"" -ForegroundColor Cyan
    
    Write-Host "    Select files manually          " -ForegroundColor White -NoNewline
    Write-Host "(no -Path parameter)" -ForegroundColor Cyan
    Write-Host ""
    
    # VALID COMBINATIONS
    Write-Host "VALID COMBINATIONS" -ForegroundColor Green
    Write-Host "    ✓ -Start + -End" -ForegroundColor Green
    Write-Host "    ✓ -Start + -Ext" -ForegroundColor Green
    Write-Host "    ✓ -End + -Ext" -ForegroundColor Green
    Write-Host "    ✓ -Start + -End + -Ext" -ForegroundColor Green
    Write-Host "    ✓ -Delete + -Ext" -ForegroundColor Green
    Write-Host "    ✗ -Delete + -Start" -ForegroundColor Red
    Write-Host "    ✗ -Delete + -End" -ForegroundColor Red
    Write-Host "    ✗ -Remove without -Start or -End" -ForegroundColor Red
    Write-Host ""
    
    # EXAMPLES
    Write-Host "EXAMPLES" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "    # Add prefix to all files in a directory" -ForegroundColor DarkYellow
    Write-Host "    .\Renamer.ps1 -Path `"C:\Files`" -Start `"backup_`"" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "    # Add suffix to selected files (opens dialog)" -ForegroundColor DarkYellow
    Write-Host "    .\Renamer.ps1 -End `"_final`"" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "    # Remove prefix and change extension" -ForegroundColor DarkYellow
    Write-Host "    .\Renamer.ps1 -Path `"C:\Files`" -Start `"old_`" -Remove -Ext new" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "    # Remove string from anywhere and change extension" -ForegroundColor DarkYellow
    Write-Host "    .\Renamer.ps1 -Delete `"draft`" -Ext final" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "    # Combine multiple operations" -ForegroundColor DarkYellow
    Write-Host "    .\Renamer.ps1 -Start `"prod_`" -End `"_v3`" -Ext zip" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "    # Preview changes before applying" -ForegroundColor DarkYellow
    Write-Host "    .\Renamer.ps1 -Path `"C:\Files`" -Start `"new_`" -WhatIf" -ForegroundColor Cyan
    Write-Host ""
    
    exit 0
}

# ============================================
# MANUAL VALIDATION - Check conflicting parameters
# ============================================

$hasStart = $PSBoundParameters.ContainsKey('Start')
$hasEnd = $PSBoundParameters.ContainsKey('End')
$hasDelete = $PSBoundParameters.ContainsKey('Delete')
$hasExt = $PSBoundParameters.ContainsKey('Ext')
$hasRemove = $Remove.IsPresent
$hasPath = $PSBoundParameters.ContainsKey('Path')

# Validate: Delete cannot be used with Start or End (but CAN be used with Ext)
if ($hasDelete -and ($hasStart -or $hasEnd)) {
    Write-Error "ERROR: -Delete cannot be used with -Start or -End. However, -Delete CAN be used with -Ext." -ErrorAction Stop
    exit 1
}

# Validate: At least one operation must be specified
if (-not ($hasStart -or $hasEnd -or $hasDelete -or $hasExt)) {
    Write-Error "ERROR: No operation specified. Use -Start, -End, -Delete, or -Ext" -ErrorAction Stop
    exit 1
}

# Validate: Remove requires Start or End
if ($hasRemove -and (-not ($hasStart -or $hasEnd))) {
    Write-Error "ERROR: -Remove can only be used with -Start or -End" -ErrorAction Stop
    exit 1
}

# ============================================
# HELPER FUNCTIONS
# ============================================

# Function to open file selection dialog
function Show-FileDialog {
    Add-Type -AssemblyName System.Windows.Forms
    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Multiselect = $true
    $dialog.Title = "Select files to rename"
    $dialog.Filter = "All files (*.*)|*.*"
    $dialog.InitialDirectory = [Environment]::GetFolderPath('Desktop')
    
    $result = $dialog.ShowDialog()
    
    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        return $dialog.FileNames
    }
    else {
        Write-Host "No files selected. Exiting..." -ForegroundColor Yellow
        exit 0
    }
}

# Function to add string to beginning of filename
function Add-Start {
    param([string]$OriginalName, [string]$String)
    return $String + $OriginalName
}

# Function to add string to end of filename (before extension)
function Add-End {
    param([string]$OriginalName, [string]$String)
    $nameWithoutExt = [System.IO.Path]::GetFileNameWithoutExtension($OriginalName)
    $extension = [System.IO.Path]::GetExtension($OriginalName)
    return $nameWithoutExt + $String + $extension
}

# Function to remove string from beginning
function Remove-Start {
    param([string]$OriginalName, [string]$String)
    if ($OriginalName.StartsWith($String, [System.StringComparison]::OrdinalIgnoreCase)) {
        $result = $OriginalName.Substring($String.Length)
        $nameWithoutExt = [System.IO.Path]::GetFileNameWithoutExtension($result)
        if ([string]::IsNullOrWhiteSpace($nameWithoutExt)) {
            return $null
        }
        return $result
    }
    return $OriginalName
}

# Function to remove string from end (before extension)
function Remove-End {
    param([string]$OriginalName, [string]$String)
    $nameWithoutExt = [System.IO.Path]::GetFileNameWithoutExtension($OriginalName)
    $extension = [System.IO.Path]::GetExtension($OriginalName)
    
    if ($nameWithoutExt.EndsWith($String, [System.StringComparison]::OrdinalIgnoreCase)) {
        $newBaseName = $nameWithoutExt.Substring(0, $nameWithoutExt.Length - $String.Length)
        if ([string]::IsNullOrWhiteSpace($newBaseName)) {
            return $null
        }
        return $newBaseName + $extension
    }
    return $OriginalName
}

# Function to remove string from anywhere in filename
function Remove-Delete {
    param([string]$OriginalName, [string]$String)
    $newName = $OriginalName -replace [regex]::Escape($String), ""
    
    $nameWithoutExt = [System.IO.Path]::GetFileNameWithoutExtension($newName)
    if ([string]::IsNullOrWhiteSpace($nameWithoutExt)) {
        return $null
    }
    return $newName
}

# Function to change file extension
function Change-Extension {
    param([string]$OriginalName, [string]$NewExt)
    $nameWithoutExt = [System.IO.Path]::GetFileNameWithoutExtension($OriginalName)
    $cleanExt = $NewExt.TrimStart('.')
    
    if ([string]::IsNullOrWhiteSpace($nameWithoutExt)) {
        return "." + $cleanExt
    }
    return $nameWithoutExt + "." + $cleanExt
}

# ============================================
# GET FILES (Directory or Dialog)
# ============================================

Write-Host "`nFile Renamer Tool v4.2" -ForegroundColor Cyan
Write-Host "=====================" -ForegroundColor Cyan

# Get files based on input method
if ($hasPath) {
    Write-Host "Input Mode: Directory Processing" -ForegroundColor White
    Write-Host "Location: $Path" -ForegroundColor Gray
    
    try {
        $files = Get-ChildItem -Path $Path -File -ErrorAction Stop
    }
    catch {
        Write-Error "ERROR: Failed to read directory: $_" -ErrorAction Stop
        exit 1
    }
}
else {
    Write-Host "Input Mode: File Selection Dialog" -ForegroundColor White
    Write-Host "Please select files from the dialog box..." -ForegroundColor Gray
    
    $files = Show-FileDialog
    if ($null -eq $files -or $files.Count -eq 0) {
        exit 0
    }
    
    # Convert file paths to FileInfo objects
    $files = $files | ForEach-Object { Get-Item $_ }
}

# Validate that there are files to process
if ($files.Count -eq 0) {
    Write-Host "No files found to process" -ForegroundColor Yellow
    exit 0
}

# ============================================
# DISPLAY OPERATION SUMMARY
# ============================================

$processed = 0
$skipped = 0
$errors = 0

Write-Host "`nFiles to process: $($files.Count)" -ForegroundColor White

# Build operation description
$operations = @()

if ($hasDelete) {
    $operations += "REMOVE string '$Delete' from anywhere in filename"
}
else {
    if ($hasStart) {
        if ($hasRemove) {
            $operations += "REMOVE string '$Start' from BEGINNING"
        }
        else {
            $operations += "ADD string '$Start' to BEGINNING"
        }
    }
    if ($hasEnd) {
        if ($hasRemove) {
            $operations += "REMOVE string '$End' from END (before extension)"
        }
        else {
            $operations += "ADD string '$End' to END (before extension)"
        }
    }
}

if ($hasExt) {
    $cleanExt = $Ext.TrimStart('.')
    $operations += "CHANGE extension to '.$cleanExt'"
}

Write-Host "Operations to perform:" -ForegroundColor Yellow
foreach ($op in $operations) {
    Write-Host "  - $op" -ForegroundColor Green
}

if ($WhatIf) {
    Write-Host "[WHATIF MODE] Preview only - no changes will be made" -ForegroundColor Magenta
}
Write-Host ""

# ============================================
# PROCESS EACH FILE
# ============================================

foreach ($file in $files) {
    $newName = $file.Name
    
    # Apply Delete operation (if specified) - this is exclusive with Start/End
    if ($hasDelete) {
        $newName = Remove-Delete -OriginalName $newName -String $Delete
        if ($null -eq $newName) {
            Write-Host "SKIPPED: $($file.Name) - Would result in empty filename" -ForegroundColor Yellow
            $skipped++
            continue
        }
    }
    else {
        # Apply Start operation (add or remove)
        if ($hasStart) {
            if ($hasRemove) {
                $newName = Remove-Start -OriginalName $newName -String $Start
                if ($null -eq $newName) {
                    Write-Host "SKIPPED: $($file.Name) - Would result in empty filename" -ForegroundColor Yellow
                    $skipped++
                    continue
                }
            }
            else {
                $newName = Add-Start -OriginalName $newName -String $Start
            }
        }
        
        # Apply End operation (add or remove)
        if ($hasEnd) {
            if ($hasRemove) {
                $newName = Remove-End -OriginalName $newName -String $End
                if ($null -eq $newName) {
                    Write-Host "SKIPPED: $($file.Name) - Would result in empty filename" -ForegroundColor Yellow
                    $skipped++
                    continue
                }
            }
            else {
                $newName = Add-End -OriginalName $newName -String $End
            }
        }
    }
    
    # Apply Extension change (if specified)
    if ($hasExt) {
        $newName = Change-Extension -OriginalName $newName -NewExt $Ext
    }
    
    # Skip if no change
    if ($newName -eq $file.Name) {
        Write-Host "SKIPPED: $($file.Name) - No change needed" -ForegroundColor DarkGray
        $skipped++
        continue
    }
    
    # Validate new name is not empty or invalid
    if ([string]::IsNullOrWhiteSpace($newName)) {
        Write-Host "SKIPPED: $($file.Name) - New name would be empty" -ForegroundColor Yellow
        $skipped++
        continue
    }
    
    $newPath = Join-Path -Path $file.DirectoryName -ChildPath $newName
    
    # Check for name collision with existing file
    if (Test-Path -Path $newPath -PathType Leaf) {
        Write-Host "SKIPPED: $($file.Name) - Target '$newName' already exists" -ForegroundColor Yellow
        $skipped++
        continue
    }
    
    # Perform rename or preview
    try {
        if ($WhatIf) {
            Write-Host "[WHATIF] Would rename: '$($file.Name)' -> '$newName'" -ForegroundColor Cyan
        }
        else {
            Rename-Item -Path $file.FullName -NewName $newName -ErrorAction Stop
            Write-Host "RENAMED: '$($file.Name)' -> '$newName'" -ForegroundColor Green
        }
        $processed++
    }
    catch {
        Write-Host "ERROR: Failed to rename '$($file.Name)': $_" -ForegroundColor Red
        $errors++
    }
}

# ============================================
# FINAL SUMMARY
# ============================================

Write-Host "`n=== OPERATION COMPLETED ===" -ForegroundColor Cyan
Write-Host "Successfully processed: $processed" -ForegroundColor Green
if ($skipped -gt 0) {
    Write-Host "Skipped: $skipped" -ForegroundColor Yellow
}
if ($errors -gt 0) {
    Write-Host "Errors: $errors" -ForegroundColor Red
}
Write-Host "=========================" -ForegroundColor Cyan