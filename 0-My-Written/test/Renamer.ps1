<#
.SYNOPSIS
    Bulk file renamer with add/remove operations at start, end, or anywhere in filenames.

.DESCRIPTION
    This script renames files in a specified directory by adding or removing strings
    at the beginning, end, or anywhere within filenames. It includes safety checks
    to prevent name collisions and empty filenames.

.PARAMETER Path
    Required. Specifies the directory containing files to rename.

.PARAMETER Start
    String to add at the beginning of filenames. When used with -Remove, removes
    this string from the beginning instead.

.PARAMETER End
    String to add at the end of filenames (before extension). When used with -Remove,
    removes this string from the end instead.

.PARAMETER Delete
    String to remove from anywhere in filenames. Cannot be used with -Start or -End.

.PARAMETER Remove
    Switch that changes behavior from "add" to "remove" when used with -Start or -End.

.EXAMPLE
    .\Renamer.ps1 -Path "C:\Files" -Start "prefix_"
    Adds "prefix_" to the beginning of all filenames.

.EXAMPLE
    .\Renamer.ps1 -Path "C:\Files" -End "_suffix" -Remove
    Removes "_suffix" from the end of all filenames (before extension).

.EXAMPLE
    .\Renamer.ps1 -Path "C:\Files" -Delete "temp"
    Removes the string "temp" from anywhere in filenames.

.NOTES
    Author: PowerShell Script
    Version: 2.0
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

    [Parameter(ParameterSetName = "Start")]
    [ValidateNotNullOrEmpty()]
    [string]$Start,

    [Parameter(ParameterSetName = "End")]
    [ValidateNotNullOrEmpty()]
    [string]$End,

    [Parameter(ParameterSetName = "Delete")]
    [ValidateNotNullOrEmpty()]
    [string]$Delete,

    [Parameter(ParameterSetName = "Start")]
    [Parameter(ParameterSetName = "End")]
    [switch]$Remove,

    [switch]$WhatIf
)

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
        return $OriginalName.Substring($String.Length)
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

# Initialize counters
$processed = 0
$skipped = 0
$errors = 0

# Display operation summary before execution
Write-Host "`n=== OPERATION SUMMARY ===" -ForegroundColor Cyan
Write-Host "Directory: $Path" -ForegroundColor White
Write-Host "Files found: $($files.Count)" -ForegroundColor White

if ($Delete) {
    Write-Host "Operation: REMOVE string '$Delete' from anywhere in filename" -ForegroundColor Yellow
}
elseif ($Start -or $End) {
    $target = if ($Start) { $Start } else { $End }
    $position = if ($Start) { "BEGINNING" } else { "END (before extension)" }
    $action = if ($Remove) { "REMOVE" } else { "ADD" }
    Write-Host "Operation: $action string '$target' at $position" -ForegroundColor Yellow
}
else {
    Write-Host "ERROR: No operation specified. Use -Start, -End, or -Delete." -ForegroundColor Red
    exit 1
}

if ($WhatIf) {
    Write-Host "`n[WHATIF MODE] Preview only - no changes will be made" -ForegroundColor Magenta
}
Write-Host "========================`n" -ForegroundColor Cyan

# Process each file
foreach ($file in $files) {
    $newName = $null
    
    # Determine new name based on parameters
    if ($Delete) {
        $newName = Remove-Delete -OriginalName $file.Name -String $Delete
    }
    elseif ($Start) {
        if ($Remove) {
            $newName = Remove-Start -OriginalName $file.Name -String $Start
        }
        else {
            $newName = Add-Start -OriginalName $file.Name -String $Start
        }
    }
    elseif ($End) {
        if ($Remove) {
            $newName = Remove-End -OriginalName $file.Name -String $End
        }
        else {
            $newName = Add-End -OriginalName $file.Name -String $End
        }
    }
    
    # Skip if no change or invalid new name
    if ($null -eq $newName -or $newName -eq $file.Name) {
        $skipped++
        if ($null -eq $newName) {
            Write-Warning "Skipped '$($file.Name)' - operation would result in empty filename"
        }
        else {
            Write-Verbose "Skipped '$($file.Name)' - no change needed" -Verbose:$false
        }
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

# Final summary
Write-Host "`n=== OPERATION COMPLETED ===" -ForegroundColor Cyan
Write-Host "Successfully processed: $processed" -ForegroundColor Green
Write-Host "Skipped: $skipped" -ForegroundColor Yellow
if ($errors -gt 0) { Write-Host "Errors: $errors" -ForegroundColor Red }
Write-Host "=========================" -ForegroundColor Cyan