# ========================================================================
# NppCLI - File Resolver (Private)
# Handles all file resolution, classification, wildcard expansion,
# directory scanning, extension filtering, and deduplication.
# ========================================================================

function Test-IsWildcard {
    <#
    .SYNOPSIS
        Tests if a string contains wildcard characters (*, ?, [, ]).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    return ($Path -match '[\*\?\[\]]')
}

function ConvertTo-NormalizedExtensionList {
    <#
    .SYNOPSIS
        Converts raw extension input (string or string array) into a
        normalized array of lowercase extensions without leading dots.

    .DESCRIPTION
        Handles all input forms:
          -e php              -> @('php')
          -e php,txt          -> @('php','txt')
          -e .php,.txt        -> @('php','txt')
          -e "php, txt"       -> @('php','txt')
          -e php -e txt       -> @('php','txt')   (array input)

    .PARAMETER RawExtensions
        One or more strings, each potentially containing comma-separated extensions.

    .OUTPUTS
        A string array of normalized extension names.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [AllowEmptyCollection()]
        [string[]]$RawExtensions
    )

    $result = [System.Collections.Generic.List[string]]::new()

    foreach ($entry in $RawExtensions) {
        if ([string]::IsNullOrWhiteSpace($entry)) { continue }

        # Split on comma
        $parts = $entry.Split(',')
        foreach ($part in $parts) {
            $cleaned = $part.Trim().TrimStart('.').ToLower()
            if ($cleaned -ne '' -and -not $result.Contains($cleaned)) {
                $result.Add($cleaned)
            }
        }
    }

    return @($result.ToArray())
}

function Test-ExtensionMatch {
    <#
    .SYNOPSIS
        Tests if a file's extension matches a list of allowed extensions.
    .PARAMETER FileName
        The file name (or full path - extension is extracted).
    .PARAMETER ExtensionList
        Array of normalized (no dot, lowercase) extension names.
    .OUTPUTS
        $true if the file extension is in the list, $false otherwise.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FileName,

        [Parameter(Mandatory = $true)]
        [string[]]$ExtensionList
    )

    $fileExt = [System.IO.Path]::GetExtension($FileName).TrimStart('.').ToLower()
    return ($ExtensionList -contains $fileExt)
}

function Resolve-InputPaths {
    <#
    .SYNOPSIS
        Classifies and resolves input path arguments into:
          - $Directories (existing directories for -d mode)
          - $Patterns (wildcard patterns for filtering or expansion)
          - $ResolvedFiles (resolved absolute paths to existing or created files)

    .PARAMETER Paths
        The raw path arguments from the user.
    .PARAMETER DirectoryMode
        If $true, we are in directory scanning mode (-d).
    .OUTPUTS
        A hashtable with keys: Directories, Patterns, ResolvedFiles
    #>
    [CmdletBinding()]
    param(
        [AllowNull()]
        [string[]]$Paths,

        [switch]$DirectoryMode
    )

    $resolvedFiles = [System.Collections.Generic.List[string]]::new()
    $patterns      = [System.Collections.Generic.List[string]]::new()
    $directories   = [System.Collections.Generic.List[string]]::new()

    if (-not $Paths -or $Paths.Count -eq 0) {
        return @{
            Directories   = @($directories.ToArray())
            Patterns      = @($patterns.ToArray())
            ResolvedFiles = @($resolvedFiles.ToArray())
        }
    }

    foreach ($p in $Paths) {
        if ([string]::IsNullOrWhiteSpace($p)) { continue }

        $isWildcard = Test-IsWildcard -Path $p

        if ($DirectoryMode) {
            # ---- DIRECTORY MODE classification ----
            if (Test-Path $p -PathType Container) {
                $directories.Add((Resolve-Path $p).Path)
            }
            elseif ($isWildcard) {
                $patterns.Add($p)
            }
            else {
                # Not a directory and not a wildcard.
                # If it has no path separators, treat as a name/pattern filter.
                if ($p -notmatch '[\\/]') {
                    $patterns.Add($p)
                }
                else {
                    Write-Warning "Directory not found: $p"
                }
            }
        }
        else {
            # ---- FILE MODE classification ----
            if ($isWildcard) {
                $patterns.Add($p)
            }
            else {
                # Literal file path
                if (Test-Path $p -PathType Leaf) {
                    $resolvedFiles.Add((Resolve-Path $p).Path)
                }
                elseif (Test-Path $p -PathType Container) {
                    Write-Warning "'$p' is a directory. Use -d flag to scan directories. Skipping."
                }
                else {
                    # FILE CREATION: file does not exist - create it
                    try {
                        $parent = Split-Path $p -Parent
                        if ($parent -and -not (Test-Path $parent)) {
                            New-Item -ItemType Directory -Path $parent -Force | Out-Null
                            Write-Verbose "Created parent directory: $parent"
                        }
                        New-Item -ItemType File -Path $p -Force | Out-Null
                        $created = (Resolve-Path $p).Path
                        $resolvedFiles.Add($created)
                        Write-Verbose "Created new file: $created"
                    }
                    catch {
                        Write-Warning "Cannot create file: $p - $($_.Exception.Message)"
                    }
                }
            }
        }
    }

    return @{
        Directories   = @($directories.ToArray())
        Patterns      = @($patterns.ToArray())
        ResolvedFiles = $resolvedFiles
    }
}

function Invoke-DirectoryScan {
    <#
    .SYNOPSIS
        Scans directories for files, applies pattern and extension filters.

    .PARAMETER Directories
        Array of directory paths to scan.
    .PARAMETER Patterns
        Array of wildcard patterns to filter file names.
    .PARAMETER ExtensionList
        Array of normalized extension names to filter by.
    .PARAMETER Recursive
        Scan recursively.
    .PARAMETER IncludeHidden
        Include hidden/system files.
    .OUTPUTS
        A List[string] of resolved file paths.
    #>
    [CmdletBinding()]
    param(
        [string[]]$Directories,
        [string[]]$Patterns,
        [string[]]$ExtensionList,
        [switch]$Recursive,
        [switch]$IncludeHidden
    )

    $results = [System.Collections.Generic.List[string]]::new()

    # If no directories provided, default to current directory
    if (-not $Directories -or $Directories.Count -eq 0) {
        $Directories = @((Resolve-Path '.').Path)
        Write-Verbose "No directory specified with -d; using current directory."
    }

    foreach ($dir in $Directories) {
        Write-Verbose "Scanning directory: $dir"

        $gciParams = @{
            Path        = $dir
            File        = $true
            ErrorAction = 'SilentlyContinue'
        }
        if ($Recursive)     { $gciParams['Recurse'] = $true }
        if ($IncludeHidden) { $gciParams['Force']   = $true }

        $files = @(Get-ChildItem @gciParams)
        Write-Verbose "  Found $($files.Count) total files in $dir"

        # Apply wildcard/name pattern filter
        if ($Patterns -and $Patterns.Count -gt 0) {
            $files = @($files | Where-Object {
                $fileName = $_.Name
                foreach ($pat in $Patterns) {
                    if ($fileName -like $pat) { return $true }
                }
                return $false
            })
            Write-Verbose "  After pattern filter: $($files.Count) files"
        }

        # Apply extension filter
        if ($ExtensionList -and $ExtensionList.Count -gt 0) {
            $files = @($files | Where-Object {
                $fileExt = $_.Extension.TrimStart('.').ToLower()
                $ExtensionList -contains $fileExt
            })
            Write-Verbose "  After extension filter: $($files.Count) files"
        }

        foreach ($f in $files) {
            if ($f -and $f.FullName) {
                $results.Add($f.FullName)
            }
        }
    }

    return $results
}

function Invoke-WildcardExpansion {
    <#
    .SYNOPSIS
        Expands wildcard patterns to file paths (non-directory mode).

    .PARAMETER Patterns
        Array of wildcard patterns.
    .PARAMETER ExtensionList
        Array of normalized extension names to filter by.
    .PARAMETER Recursive
        Expand recursively.
    .PARAMETER IncludeHidden
        Include hidden/system files.
    .OUTPUTS
        A List[string] of resolved file paths.
    #>
    [CmdletBinding()]
    param(
        [string[]]$Patterns,
        [string[]]$ExtensionList,
        [switch]$Recursive,
        [switch]$IncludeHidden
    )

    $results = [System.Collections.Generic.List[string]]::new()

    if (-not $Patterns -or $Patterns.Count -eq 0) {
        return $results
    }

    foreach ($pat in $Patterns) {
        Write-Verbose "Expanding wildcard pattern: $pat"

        $gciParams = @{
            Path        = $pat
            File        = $true
            ErrorAction = 'SilentlyContinue'
        }
        if ($Recursive)     { $gciParams['Recurse'] = $true }
        if ($IncludeHidden) { $gciParams['Force']   = $true }

        $files = @(Get-ChildItem @gciParams)

        # Apply extension filter
        if ($ExtensionList -and $ExtensionList.Count -gt 0) {
            $files = @($files | Where-Object {
                $fileExt = $_.Extension.TrimStart('.').ToLower()
                $ExtensionList -contains $fileExt
            })
        }

        foreach ($f in $files) {
            if ($f -and $f.FullName) {
                $results.Add($f.FullName)
            }
        }
        Write-Verbose "  Pattern '$pat' matched $($files.Count) files"
    }

    return $results
}
