<#
.SYNOPSIS
    NppCLI - Open files and directories in Notepad++ from the command line.

.DESCRIPTION
    A PowerShell function that wraps Notepad++ with advanced file operations:
    - Open one or more files (creating them if they don't exist)
    - Wildcard expansion (*, ?, [a-z], [abc])
    - Directory scanning with optional recursion
    - Extension filtering
    - Hidden file support
    - Interactive confirmation prompts for large file sets
    - Hard limit to prevent accidentally opening too many files

.EXAMPLE
    npp file.txt file2.txt
    Opens file.txt and file2.txt in Notepad++. Creates them if they don't exist.

.EXAMPLE
    npp *.txt
    Opens all .txt files in the current directory.

.EXAMPLE
    npp -d mu-plugins *.php
    Opens all .php files inside the mu-plugins directory.

.EXAMPLE
    npp -d mu-plugins -r -ext php,txt
    Recursively opens all .php and .txt files inside mu-plugins.

.NOTES
    Author: Davood Yahay (Davoodsec)
    Module: NppCLI
    Requires: Notepad++ installed at C:\Program Files\Notepad++\notepad++.exe
    Compatible with: Windows PowerShell 5.1+ and PowerShell 7+
#>

function npp {
    [CmdletBinding(PositionalBinding = $false)]
    param(
        # -d : Directory mode - treat path arguments as directories to scan for files
        [switch]$d,

        # -r : Recursive - scan directories recursively (used with -d, or with wildcards)
        [switch]$r,

        # -a / --hidden : Include hidden files in directory scans and wildcard resolution
        [Alias("a")]
        [switch]$hidden,

        # -ext : Comma-separated list of file extensions to filter (e.g., -ext php,txt)
        [string]$ext,

        # -limit : Hard maximum number of files that can be opened at once (default 500)
        [int]$limit = 500,

        # -confirmThreshold : Number of files above which a confirmation prompt appears (default 50)
        [int]$confirmThreshold = 50,

        # Remaining positional arguments: file paths, directory paths, or wildcard patterns
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Paths
    )

    # ========================================================================
    # NOTEPAD++ EXECUTABLE PATH
    # ========================================================================
    $exe = "C:\Program Files\Notepad++\notepad++.exe"

    if (-not (Test-Path $exe)) {
        Write-Error "Notepad++ not found at: $exe"
        return
    }

    # If no arguments are provided, just launch Notepad++ with no files
    if (-not $Paths -or $Paths.Count -eq 0) {
        & $exe
        return
    }

    # ========================================================================
    # EXTENSION FILTER SETUP
    # Parse the -ext parameter into a normalized list of extensions (no dots, lowercase)
    # ========================================================================
    $extList = @()
    if ($ext) {
        $extList = @($ext.Split(",") | ForEach-Object {
            $_.Trim().TrimStart(".").ToLower()
        } | Where-Object { $_ -ne "" })
    }

    # ========================================================================
    # CLASSIFY INPUT ARGUMENTS
    # Separate paths into: directories, wildcard patterns, and literal file paths.
    # In directory mode (-d), non-directory non-wildcard args are treated as patterns
    # if they look like filenames with extensions (e.g., "*.php"), otherwise warned.
    # ========================================================================
    $resolvedFiles = [System.Collections.Generic.List[string]]::new()
    $patterns      = [System.Collections.Generic.List[string]]::new()
    $directories   = [System.Collections.Generic.List[string]]::new()

    foreach ($p in $Paths) {
        # Skip empty/null entries
        if ([string]::IsNullOrWhiteSpace($p)) { continue }

        # Check if this argument contains wildcard characters
        $isWildcard = $p -match '[\*\?\[\]]'

        if ($d) {
            # --- DIRECTORY MODE CLASSIFICATION ---
            # If the path is an existing directory, add it to directory list
            if (Test-Path $p -PathType Container) {
                $directories.Add((Resolve-Path $p).Path)
            }
            elseif ($isWildcard) {
                # It's a wildcard pattern - will be used to filter files in directories
                $patterns.Add($p)
            }
            else {
                # Not a directory and not a wildcard.
                # Could be a filename pattern like "readme.php" used as a literal filter,
                # or a typo. In directory mode, non-wildcard non-directory args are
                # treated as exact name filters (like patterns).
                # Check if it looks like a file name (has an extension or no path separator)
                if ($p -notmatch '[\\/]') {
                    # Treat as a name pattern (exact match filter)
                    $patterns.Add($p)
                }
                else {
                    Write-Warning "Directory not found: $p"
                }
            }
        }
        else {
            # --- FILE MODE CLASSIFICATION ---
            if ($isWildcard) {
                $patterns.Add($p)
            }
            else {
                # Literal file path - resolve or create
                if (Test-Path $p -PathType Leaf) {
                    # File exists - resolve to absolute path
                    $resolvedFiles.Add((Resolve-Path $p).Path)
                }
                elseif (Test-Path $p -PathType Container) {
                    # It's actually a directory - inform user to use -d
                    Write-Warning "'$p' is a directory. Use -d flag to scan directories. Skipping."
                }
                else {
                    # -----------------------------------------------------------
                    # FILE CREATION: File does not exist - create it
                    # -----------------------------------------------------------
                    try {
                        # Ensure parent directory exists
                        $parent = Split-Path $p -Parent
                        if ($parent -and -not (Test-Path $parent)) {
                            New-Item -ItemType Directory -Path $parent -Force | Out-Null
                        }
                        # Create the file (empty)
                        New-Item -ItemType File -Path $p -Force | Out-Null
                        # Resolve to absolute path after creation
                        $resolvedFiles.Add((Resolve-Path $p).Path)
                        Write-Verbose "Created new file: $((Resolve-Path $p).Path)"
                    }
                    catch {
                        Write-Warning "Cannot create file: $p - $_"
                    }
                }
            }
        }
    }

    # ========================================================================
    # DIRECTORY MODE - SCAN DIRECTORIES FOR FILES
    # If -d is set and we have directories, scan them with optional recursion,
    # then apply wildcard patterns and extension filters.
    # ========================================================================
    if ($d) {
        # If no explicit directories were provided, use the current directory
        if ($directories.Count -eq 0) {
            $directories.Add((Resolve-Path ".").Path)
            Write-Verbose "No directory specified with -d; using current directory."
        }

        foreach ($dir in $directories) {
            # Build Get-ChildItem parameters
            $gciParams = @{
                Path        = $dir
                File        = $true
                ErrorAction = "SilentlyContinue"
            }

            if ($r)      { $gciParams["Recurse"] = $true }
            if ($hidden) { $gciParams["Force"]    = $true }

            $files = @(Get-ChildItem @gciParams)

            # Apply wildcard pattern filter (if any patterns were provided)
            if ($patterns.Count -gt 0) {
                $files = @($files | Where-Object {
                    $name = $_.Name
                    foreach ($pat in $patterns) {
                        if ($name -like $pat) { return $true }
                    }
                    return $false
                })
            }

            # Apply extension filter (if -ext was provided)
            if ($extList.Count -gt 0) {
                $files = @($files | Where-Object {
                    $fileExt = $_.Extension.TrimStart(".").ToLower()
                    $extList -contains $fileExt
                })
            }

            # Add resolved full paths
            foreach ($f in $files) {
                if ($f -and $f.FullName) {
                    $resolvedFiles.Add($f.FullName)
                }
            }
        }
    }

    # ========================================================================
    # NON-DIRECTORY WILDCARD EXPANSION
    # When NOT in directory mode, expand wildcard patterns in the current
    # directory (or the path specified in the pattern).
    # ========================================================================
    if (-not $d -and $patterns.Count -gt 0) {
        foreach ($pat in $patterns) {
            # Build Get-ChildItem parameters for the wildcard pattern
            $gciParams = @{
                Path        = $pat
                File        = $true
                ErrorAction = "SilentlyContinue"
            }

            if ($r)      { $gciParams["Recurse"] = $true }
            if ($hidden) { $gciParams["Force"]    = $true }

            $files = @(Get-ChildItem @gciParams)

            # Apply extension filter
            if ($extList.Count -gt 0) {
                $files = @($files | Where-Object {
                    $fileExt = $_.Extension.TrimStart(".").ToLower()
                    $extList -contains $fileExt
                })
            }

            # Add resolved full paths
            foreach ($f in $files) {
                if ($f -and $f.FullName) {
                    $resolvedFiles.Add($f.FullName)
                }
            }
        }
    }

    # ========================================================================
    # DEDUPLICATE AND SORT
    # Remove duplicates and sort alphabetically for consistent ordering.
    # ========================================================================
    $resolvedFiles = @($resolvedFiles | Sort-Object -Unique)
    $count = $resolvedFiles.Count

    # ========================================================================
    # EMPTY RESULT CHECK
    # ========================================================================
    if ($count -eq 0) {
        Write-Host "No files matched." -ForegroundColor Yellow
        return
    }

    # ========================================================================
    # HARD LIMIT CHECK
    # Prevent accidentally opening a massive number of files.
    # ========================================================================
    if ($count -gt $limit) {
        Write-Warning "File count ($count) exceeds hard limit ($limit). Aborting."
        Write-Warning "Use -limit <number> to increase the limit if needed."
        return
    }

    # ========================================================================
    # CONFIRMATION PROMPT
    # If the number of files exceeds the confirm threshold, prompt the user.
    # Options:
    #   a            => open all files
    #   n            => open only the first $confirmThreshold files
    #   c            => cancel (open nothing)
    #   <number>     => open the first <number> files
    # ========================================================================
    if ($count -gt $confirmThreshold) {
        Write-Host ""
        Write-Host "$count files detected." -ForegroundColor Cyan
        Write-Host "  a => open all $count files" -ForegroundColor Green
        Write-Host "  n => open first $confirmThreshold files" -ForegroundColor Yellow
        Write-Host "  c => cancel" -ForegroundColor Red
        Write-Host "  or enter a number (1-$count)" -ForegroundColor Gray
        Write-Host ""

        $choice = Read-Host "Choice"

        # Handle null/empty input (user pressed Enter with no input)
        if ([string]::IsNullOrWhiteSpace($choice)) {
            Write-Host "No input received. Cancelling." -ForegroundColor Red
            return
        }

        switch ($choice.Trim().ToLower()) {
            "a" {
                # Open all - no change to $resolvedFiles
                Write-Verbose "User chose to open all $count files."
            }
            "c" {
                Write-Host "Cancelled." -ForegroundColor Red
                return
            }
            "n" {
                $resolvedFiles = @($resolvedFiles | Select-Object -First $confirmThreshold)
                Write-Verbose "User chose to open first $confirmThreshold files."
            }
            default {
                if ($choice -match '^\d+$') {
                    $num = [int]$choice
                    if ($num -gt 0 -and $num -le $count) {
                        $resolvedFiles = @($resolvedFiles | Select-Object -First $num)
                        Write-Verbose "User chose to open first $num files."
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
    # LAUNCH NOTEPAD++
    # Pass all resolved file paths as arguments to Notepad++.
    # Each path is quoted to handle spaces in file/directory names.
    # ========================================================================
    $finalCount = $resolvedFiles.Count
    Write-Verbose "Opening $finalCount file(s) in Notepad++..."

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
