<#
.SYNOPSIS
    Bulk file renamer with add/remove operations at start, end, or anywhere in filenames.

.DESCRIPTION
    This script renames files in a specified directory by adding or removing strings
    at the beginning, end, or anywhere within filenames. It also supports changing
    file extensions and combining multiple operations (Start + End simultaneously).

.PARAMETER Path
    Required. Specifies the directory containing files to rename.

.PARAMETER Start
    String to add at the beginning of filenames. When used with -Remove, removes
    this string from the beginning instead. Can be combined with -End.

.PARAMETER End
    String to add at the end of filenames (before extension). When used with -Remove,
    removes this string from the end instead. Can be combined with -Start.

.PARAMETER Delete
    String to remove from anywhere in filenames. Cannot be used with -Start or -End.

.PARAMETER Remove
    Switch that changes behavior from "add" to "remove" when used with -Start and/or -End.
    When both -Start and -End are present, removes from both ends simultaneously.

.PARAMETER Ext
    Changes the file extension of all files to the specified value (without dot).
    Example: -Ext md changes all extensions to .md
    Can be used alone or with -Start, -End, or -Delete.

.PARAMETER WhatIf
    Demonstrates what would happen without actually renaming any files.

.EXAMPLE
    .\Renamer.ps1 -Path "C:\Files" -Start "prefix_"
    Adds "prefix_" to the beginning of all filenames.

.EXAMPLE
    .\Renamer.ps1 -Path "C:\Files" -End "_suffix" -Remove
    Removes "_suffix" from the end of all filenames (before extension).

.EXAMPLE
    .\Renamer.ps1 -Path "C:\Files" -Start "dev" -End "_prefix"
    Adds "dev" to beginning AND "_prefix" to end of all filenames simultaneously.

.EXAMPLE
    .\Renamer.ps1 -Path "C:\Files" -Start "dev" -End "_prefix" -Remove
    Removes "dev" from beginning AND "_prefix" from end of all filenames simultaneously.

.EXAMPLE
    .\Renamer.ps1 -Path "C:\Files" -Delete "temp"
    Removes the string "temp" from anywhere in filenames.

.EXAMPLE
    .\Renamer.ps1 -Path "C:\Files" -Ext md
    Changes all file extensions to .md

.EXAMPLE
    .\Renamer.ps1 -Path "C:\Files" -Start "hello" -End "_world" -Ext txt
    Adds "hello" to beginning, "_world" to end, and changes extension to .txt

.EXAMPLE
    .\Renamer.ps1 -Path "C:\Files" -Start "dev" -Remove -Ext pdf
    Removes "dev" from beginning and changes extension to .pdf

.NOTES
    Author: PowerShell Script
    Version: 3.1
    Requires: PowerShell 5.1 or later
#>

[CmdletBinding(DefaultParameterSetName = "None")]
param(
    [Parameter(Mandatory = $true, Position = 0)]
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
    [switch]$WhatIf
)

# ============================================
# MANUAL VALIDATION - Check conflicting parameters
# ============================================

$hasStart = $PSBoundParameters.ContainsKey('Start')
$hasEnd = $PSBoundParameters.ContainsKey('End')
$hasDelete = $PSBoundParameters.ContainsKey('Delete')
$hasExt = $PSBoundParameters.ContainsKey('Ext')
$hasRemove = $Remove.IsPresent

# Validate: Delete cannot be used with Start, End, or Ext
if ($hasDelete -and ($hasStart -or $hasEnd -or $hasExt)) {
    Write-Error "ERROR: -Delete cannot be used with -Start, -End, or -Ext"
    exit 1
}

# Validate: At least one operation must be specified
if (-not ($hasStart -or $hasEnd -or $hasDelete -or $hasExt)) {
    Write-Error "ERROR: No operation specified. Use -Start, -End, -Delete, or -Ext"
    exit 1
}

# Validate: Remove requires Start or End
if ($hasRemove -and (-not ($hasStart -or $hasEnd))) {
    Write-Error "ERROR: -Remove can only be used with -Start or -End"
    exit 1
}

# ============================================
# HELPER FUNCTIONS
# ============================================

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
        # Prevent empty filename (extension only)
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
        # Prevent empty filename
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
    
    # Check if result would be empty (extension only)
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
    # Remove dot from NewExt if user included it
    $cleanExt = $NewExt.TrimStart('.')
    # Handle the case where filename might be just the extension
    if ([string]::IsNullOrWhiteSpace($nameWithoutExt)) {
        return "." + $cleanExt
    }
    return $nameWithoutExt + "." + $cleanExt
}

# ============================================
# GET FILES
# ============================================

# Get all files in the directory (exclude directories)
try {
    $files = Get-ChildItem -Path $Path -File -ErrorAction Stop
}
catch {
    Write-Error "Failed to read directory: $_"
    exit 1
}

# Validate that there are files to process
if ($files.Count -eq 0) {
    Write-Host "No files found in directory: $Path" -ForegroundColor Yellow
    exit 0
}

# ============================================
# DISPLAY OPERATION SUMMARY
# ============================================

$processed = 0
$skipped = 0
$errors = 0

Write-Host "`n=== OPERATION SUMMARY ===" -ForegroundColor Cyan
Write-Host "Directory: $Path" -ForegroundColor White
Write-Host "Files found: $($files.Count)" -ForegroundColor White

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

foreach ($op in $operations) {
    Write-Host "  • $op" -ForegroundColor Yellow
}

if ($WhatIf) {
    Write-Host "`n[WHATIF MODE] Preview only - no changes will be made" -ForegroundColor Magenta
}
Write-Host "========================`n" -ForegroundColor Cyan

# ============================================
# PROCESS EACH FILE
# ============================================

foreach ($file in $files) {
    $newName = $file.Name
    
    # Apply Delete operation (if specified) - this is exclusive
    if ($hasDelete) {
        $newName = Remove-Delete -OriginalName $newName -String $Delete
        if ($null -eq $newName) {
            Write-Warning "Skipped '$($file.Name)' - operation would result in empty filename"
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
                    Write-Warning "Skipped '$($file.Name)' - operation would result in empty filename"
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
                    Write-Warning "Skipped '$($file.Name)' - operation would result in empty filename"
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
        $skipped++
        continue
    }
    
    # Validate new name is not empty or invalid
    if ([string]::IsNullOrWhiteSpace($newName)) {
        Write-Warning "Skipped '$($file.Name)' - new name would be empty or invalid"
        $skipped++
        continue
    }
    
    $newPath = Join-Path -Path $Path -ChildPath $newName
    
    # Check for name collision with existing file
    if (Test-Path -Path $newPath -PathType Leaf) {
        Write-Warning "Skipped '$($file.Name)' - target file '$newName' already exists"
        $skipped++
        continue
    }
    
    # Perform rename or preview
    try {
        if ($WhatIf) {
            Write-Host "[WHATIF] Would rename: '$($file.Name)' -> '$newName'" -ForegroundColor Green
        }
        else {
            Rename-Item -Path $file.FullName -NewName $newName -ErrorAction Stop
            Write-Host "Renamed: '$($file.Name)' -> '$newName'" -ForegroundColor Green
        }
        $processed++
    }
    catch {
        Write-Error "Failed to rename '$($file.Name)': $_"
        $errors++
    }
}

# ============================================
# FINAL SUMMARY
# ============================================

Write-Host "`n=== OPERATION COMPLETED ===" -ForegroundColor Cyan
Write-Host "Successfully processed: $processed" -ForegroundColor Green
Write-Host "Skipped: $skipped" -ForegroundColor Yellow
if ($errors -gt 0) { Write-Host "Errors: $errors" -ForegroundColor Red }
Write-Host "=========================" -ForegroundColor Cyan