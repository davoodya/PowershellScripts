<#
.SYNOPSIS
    NppCLI - Open files and directories in any editor from the command line.

.DESCRIPTION
    A PowerShell module that wraps any editor executable with advanced file operations:
    - Open one or more files (creating them if they don't exist)
    - Wildcard expansion (*, ?, [a-z], [abc])
    - Directory scanning with optional recursion
    - Extension filtering (-e php,txt or --extension .py,.txt)
    - Hidden file support (-a / --hidden)
    - First/Last N file selection (--first, --last)
    - Interactive confirmation prompts for large file sets
    - Hard limit to prevent accidentally opening too many files
    - Cross-platform path handling (Windows, Linux, macOS)
    - Auto-detection of editor executable (Notepad++, VSCode, etc.)
    - Persistent config storage ($HOME/.nppcli/config.json)
    - File dialog or console prompt for first-run editor selection
    - Supports ANY executable editor

.EXAMPLE
    npp file.txt file2.txt
    Opens file.txt and file2.txt in the configured editor. Creates them if they don't exist.

.EXAMPLE
    npp *.txt
    Opens all .txt files in the current directory.

.EXAMPLE
    npp -d mu-plugins *.php
    Opens all .php files inside the mu-plugins directory.

.EXAMPLE
    npp -d mu-plugins -r -e php,txt
    Recursively opens all .php and .txt files inside mu-plugins.

.EXAMPLE
    npp -d project -r *.csv *.txt --first 5
    Recursively finds .csv and .txt files in project, opens the first 5.

.EXAMPLE
    npp -x "C:\path\to\notepad++.exe"
    Sets the specified editor and saves the path permanently.

.EXAMPLE
    npp --exe
    Shows a file dialog to select the editor executable.

.NOTES
    Author : Davood Yahya (DavoodSec)
    Module : NppCLI v3.0.0
    GitHub : https://github.com/davoodya
    Website: https://davoodya.ir
    Compatible with: Windows PowerShell 5.1+ and PowerShell 7+ (Windows/Linux/macOS)
#>

# ========================================================================
# LOAD PRIVATE HELPER MODULES
# ========================================================================
$privatePath = Join-Path $PSScriptRoot 'Private'

. (Join-Path $privatePath 'Config.ps1')
. (Join-Path $privatePath 'EditorResolver.ps1')
. (Join-Path $privatePath 'FileResolver.ps1')
. (Join-Path $privatePath 'HelpSystem.ps1')

# ========================================================================
# MAIN FUNCTION
# ========================================================================

function npp {
    [CmdletBinding(PositionalBinding = $false)]
    param(
        # -d | --directory : Directory mode - treat path arguments as directories to scan
        [Alias('directory')]
        [switch]$d,

        # -r | --recursive : Recursive scanning
        [Alias('recursive')]
        [switch]$r,

        # -a | --hidden : Include hidden/system files
        [Alias('a', 'hidden')]
        [switch]$IncludeHidden,

        # -e | --extension : Extension filter(s)
        # Accepts: -e php  |  -e php,txt  |  -e .php,.txt  |  -e "php,txt"
        # Also accepts array input: -e php -e txt
        [Alias('extension', 'ext')]
        [string[]]$e,

        # -l | --limit : Hard maximum number of files (default 500)
        [Alias('limit')]
        [int]$l = 500,

        # -ct | --confirmThreshold : Confirm prompt threshold (default 50)
        [Alias('confirmThreshold')]
        [int]$ct = 50,

        # --first : Open only the first N matched files
        [int]$first = 0,

        # --last : Open only the last N matched files
        [int]$last = 0,

        # -x | --exe : Editor executable path or trigger dialog
        # Usage:
        #   -x                        -> show file dialog
        #   -x "C:\path\editor.exe"   -> set and save this path
        #   --exe                     -> show file dialog
        #   --exe "/usr/bin/code"     -> set and save this path
        [Alias('exe')]
        [string[]]$x,

        # -h | --help : Show full help (summary + comprehensive + examples)
        [Alias('help')]
        [switch]$h,

        # --help-summary : Show only the summary/cheatsheet section
        [switch]$HelpSummary,

        # --examples : Show only the examples section
        [switch]$Examples,

        # Remaining arguments: file paths, directory paths, or wildcard patterns
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Paths
    )

    # ========================================================================
    # HELP SYSTEM - check before any other logic
    # Intercept help flags early to avoid editor resolution overhead.
    # ========================================================================
    if ($h -or $HelpSummary -or $Examples) {
        Show-NppHelp -Summary:$HelpSummary -Examples:$Examples -Full:$h
        return
    }

    # ========================================================================
    # HANDLE -x / --exe PARAMETER
    # Determine if the user wants to set/select an editor.
    #
    # Because -x is [string[]] with ValueFromRemainingArguments=$false,
    # we need to detect these cases:
    #   npp -x                    -> $x is bound but empty (show dialog)
    #   npp -x "path"             -> $x contains the path
    #   npp --exe                 -> $x is bound but empty (show dialog)
    #   npp --exe "/usr/bin/code" -> $x contains the path
    # ========================================================================
    $exePathArg = $null
    $showExeDialog = $false

    if ($PSBoundParameters.ContainsKey('x')) {
        if ($x -and $x.Count -gt 0) {
            # Join all parts in case path with spaces was split
            $exePathArg = ($x -join ' ').Trim()
            if ($exePathArg -eq '') {
                $showExeDialog = $true
            }
        }
        else {
            $showExeDialog = $true
        }
    }

    # ========================================================================
    # RESOLVE EDITOR EXECUTABLE
    # ========================================================================
    $exe = $null

    if ($showExeDialog) {
        # User explicitly asked for the dialog
        $exe = Resolve-EditorExecutable -ShowDialog
        if (-not $exe) {
            Write-Error "No editor selected. Cannot proceed."
            return
        }
        # If -x was the ONLY thing the user wanted, and no Paths given, just confirm and return
        if ((-not $Paths -or $Paths.Count -eq 0) -and $first -eq 0 -and $last -eq 0) {
            return
        }
    }
    elseif ($exePathArg) {
        # User provided an explicit path
        $exe = Resolve-EditorExecutable -ExePath $exePathArg
        if (-not $exe) {
            Write-Error "Editor path not valid: $exePathArg"
            return
        }
        # If no Paths to open, just confirm save and return
        if ((-not $Paths -or $Paths.Count -eq 0) -and $first -eq 0 -and $last -eq 0) {
            Write-Host "Editor saved: $exe" -ForegroundColor Green
            return
        }
    }
    else {
        # Normal resolution (stored config -> env var -> auto-detect -> dialog)
        $exe = Resolve-EditorExecutable
        if (-not $exe) {
            Write-Error "No editor found. Use -x or --exe to set one."
            return
        }
    }

    Write-Verbose "Editor executable: $exe"

    # ========================================================================
    # NO ARGUMENTS - just launch editor
    # ========================================================================
    if (-not $Paths -or $Paths.Count -eq 0) {
        & $exe
        return
    }

    # ========================================================================
    # EXTENSION FILTER SETUP
    # Parse -e into a normalized list: no dots, lowercase.
    # ========================================================================
    $extList = @()
    if ($e -and $e.Count -gt 0) {
        $extList = ConvertTo-NormalizedExtensionList -RawExtensions $e
        if ($extList.Count -gt 0) {
            Write-Verbose "Extension filter active: $($extList -join ', ')"
        }
    }

    # ========================================================================
    # CLASSIFY INPUT ARGUMENTS
    # ========================================================================
    $classified = Resolve-InputPaths -Paths $Paths -DirectoryMode:$d

    # Extract into local variables (PS 5.1 compat - hashtable access)
    $resolvedFiles = $classified['ResolvedFiles']
    $patterns      = $classified['Patterns']
    $directories   = $classified['Directories']

    # Ensure $resolvedFiles is a List[string] for .Add() support
    if ($resolvedFiles -isnot [System.Collections.Generic.List[string]]) {
        $tempList = [System.Collections.Generic.List[string]]::new()
        foreach ($rf in $resolvedFiles) {
            if ($rf) { $tempList.Add($rf) }
        }
        $resolvedFiles = $tempList
    }

    # ========================================================================
    # DIRECTORY MODE - SCAN DIRECTORIES FOR FILES
    # ========================================================================
    if ($d) {
        $scanResults = Invoke-DirectoryScan `
            -Directories $directories `
            -Patterns $patterns `
            -ExtensionList $extList `
            -Recursive:$r `
            -IncludeHidden:$IncludeHidden

        foreach ($f in $scanResults) {
            if ($f) { $resolvedFiles.Add($f) }
        }
    }

    # ========================================================================
    # NON-DIRECTORY WILDCARD EXPANSION
    # ========================================================================
    if (-not $d -and $patterns -and $patterns.Count -gt 0) {
        $expandResults = Invoke-WildcardExpansion `
            -Patterns $patterns `
            -ExtensionList $extList `
            -Recursive:$r `
            -IncludeHidden:$IncludeHidden

        foreach ($f in $expandResults) {
            if ($f) { $resolvedFiles.Add($f) }
        }
    }

    # ========================================================================
    # DEDUPLICATE AND SORT
    # ========================================================================
    $resolvedFiles = @($resolvedFiles | Sort-Object -Unique)
    $count = $resolvedFiles.Count

    Write-Verbose "Total unique files after all filters: $count"

    # ========================================================================
    # EMPTY RESULT CHECK
    # ========================================================================
    if ($count -eq 0) {
        Write-Host "No files matched." -ForegroundColor Yellow
        return
    }

    # ========================================================================
    # --first / --last SELECTION
    # ========================================================================
    if ($first -gt 0 -and $last -gt 0) {
        Write-Warning "Both --first and --last specified. Using --first $first (ignoring --last)."
        $last = 0
    }

    if ($first -gt 0) {
        if ($first -gt $count) {
            Write-Verbose "--first $first exceeds file count ($count); opening all $count files."
        }
        else {
            $resolvedFiles = @($resolvedFiles | Select-Object -First $first)
            $count = $resolvedFiles.Count
            Write-Verbose "Selected first $first files."
        }
    }
    elseif ($last -gt 0) {
        if ($last -gt $count) {
            Write-Verbose "--last $last exceeds file count ($count); opening all $count files."
        }
        else {
            $resolvedFiles = @($resolvedFiles | Select-Object -Last $last)
            $count = $resolvedFiles.Count
            Write-Verbose "Selected last $last files."
        }
    }

    # ========================================================================
    # HARD LIMIT CHECK
    # ========================================================================
    if ($count -gt $l) {
        Write-Warning "File count ($count) exceeds hard limit ($l). Aborting."
        Write-Warning "Use -l / --limit <number> to increase the limit, or use --first/--last to narrow results."
        return
    }

    # ========================================================================
    # CONFIRMATION PROMPT
    # ========================================================================
    if ($count -gt $ct) {
        Write-Host ""
        Write-Host "$count files detected." -ForegroundColor Cyan
        Write-Host "  a => open all $count files" -ForegroundColor Green
        Write-Host "  n => open first $ct files" -ForegroundColor Yellow
        Write-Host "  c => cancel" -ForegroundColor Red
        Write-Host "  or enter a number (1-$count)" -ForegroundColor Gray
        Write-Host ""

        $choice = Read-Host "Choice"

        # Handle null/empty (user pressed Enter)
        if ([string]::IsNullOrWhiteSpace($choice)) {
            Write-Host "No input received. Cancelling." -ForegroundColor Red
            return
        }

        switch ($choice.Trim().ToLower()) {
            'a' {
                Write-Verbose "User chose: open all $count files."
            }
            'c' {
                Write-Host "Cancelled." -ForegroundColor Red
                return
            }
            'n' {
                $resolvedFiles = @($resolvedFiles | Select-Object -First $ct)
                Write-Verbose "User chose: open first $ct files."
            }
            default {
                if ($choice -match '^\d+$') {
                    $num = [int]$choice
                    if ($num -gt 0 -and $num -le $count) {
                        $resolvedFiles = @($resolvedFiles | Select-Object -First $num)
                        Write-Verbose "User chose: open first $num files."
                    }
                    else {
                        Write-Warning "Invalid number: $num. Must be between 1 and $count."
                        return
                    }
                }
                else {
                    Write-Warning "Invalid input: '$choice'. Cancelled."
                    return
                }
            }
        }
    }

    # ========================================================================
    # LAUNCH EDITOR
    # ========================================================================
    $finalCount = $resolvedFiles.Count
    Write-Verbose "Opening $finalCount file(s) in editor..."

    if ($finalCount -eq 1) {
        & $exe $resolvedFiles[0]
    }
    else {
        & $exe @resolvedFiles
    }
}

# ========================================================================
# MODULE EXPORT
# ========================================================================
Export-ModuleMember -Function npp
