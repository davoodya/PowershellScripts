# ========================================================================
# NppCLI - Help System (Private)
# Professional CLI help output for the npp command.
# Three display layers: Summary, Comprehensive, Examples.
# Inspired by git, docker, and az CLI help formatting.
# ========================================================================

function Show-NppHelpSummary {
    <#
    .SYNOPSIS
        Displays a compact cheatsheet-style summary of the npp command.
        Designed for fast terminal reading.
    #>
    [CmdletBinding()]
    param()

    $text = @"

  NppCLI v3.0.0 - Open files and directories in any editor
  =========================================================

  USAGE
    npp [<files...>]                        Open file(s) in editor
    npp -d <dir> [<patterns...>]            Scan directory for files
    npp -x [<path>]                         Set/select editor executable

  FLAGS
    -d,  --directory              Treat paths as directories to scan
    -r,  --recursive              Scan directories recursively
    -a,  --hidden                 Include hidden/system files
    -e,  --extension <ext,...>    Filter by extension(s)  e.g. -e php,txt
         --first <N>              Open only the first N matched files
         --last  <N>              Open only the last  N matched files
    -l,  --limit <N>              Max files to open         [default: 500]
    -ct, --confirmThreshold <N>   Confirm prompt threshold   [default: 50]
    -x,  --exe [<path>]           Set or select editor executable

  HELP
    -h,  --help                   Show full help (all sections)
         --help-summary           Show this summary only
         --examples               Show usage examples only

  QUICK PATTERNS
    npp file.txt                  Open (or create) file.txt
    npp *.txt *.css               Open all .txt and .css files
    npp -d src -r -e py,js        Recursive scan, filter by extension
    npp -d logs --first 10        Open first 10 files from logs/
    npp -x                        Select editor via dialog/prompt
    npp                           Launch editor with no files

"@
    Write-Host $text
}

function Show-NppHelpComprehensive {
    <#
    .SYNOPSIS
        Displays full comprehensive documentation of the npp command.
        Covers all parameters, behavior, edge cases, and internals.
    #>
    [CmdletBinding()]
    param()

    $text = @"

  NppCLI v3.0.0 - Comprehensive Reference
  ========================================

  COMMAND
    npp

  SYNOPSIS
    Open files and directories in any configured editor from the
    PowerShell command line. Supports file creation, wildcard expansion,
    directory scanning, extension filtering, and more.

  DESCRIPTION
    NppCLI wraps any editor executable (Notepad++, VSCode, Sublime,
    nano, vim, or any custom binary) behind the 'npp' command. It
    resolves files through multiple strategies, creates missing files
    on demand, expands wildcards, scans directories with filters, and
    launches the editor with the final file list.

    On first use, if no editor is configured, NppCLI will present a
    file dialog (Windows) or console prompt (Linux/macOS) to select
    the editor. The choice is saved permanently.

  PARAMETERS

    <files...>  (positional, string[])
        One or more file paths, directory paths, or wildcard patterns.
        Non-existent literal paths are created automatically.
        Wildcard patterns (*, ?, [a-z]) are expanded.
        Parameters can appear in any order.

    -d, --directory  (switch)
        Directory scanning mode. Path arguments are treated as
        directories. Files inside them are discovered and opened.
        Without -d, directory arguments produce a warning.
        If -d is used with no directory argument, defaults to ".".

    -r, --recursive  (switch)
        Recurse into subdirectories during scanning.
        Works with both -d (directory scan) and wildcard expansion.

    -a, --hidden  (switch)
        Include hidden and system files in results.
        Maps to -Force on Get-ChildItem internally.

    -e, --extension <ext,...>  (string[])
        Filter results by file extension(s).
        Accepts all forms:
          -e php             single extension
          -e php,txt         comma-separated
          -e .php,.txt       with dots
          -e "php, txt"      quoted with spaces
          -e php -e txt      multiple flags
        Extensions are normalized: dots removed, lowercased, deduplicated.
        Alias: -ext (backward compatibility with v2.0.0)

    --first <N>  (int, default: 0)
        After all filtering, open only the first N files.
        If N exceeds the total count, all files are opened.
        If both --first and --last are given, --first wins.

    --last <N>  (int, default: 0)
        After all filtering, open only the last N files.
        If N exceeds the total count, all files are opened.
        Ignored if --first is also specified.

    -l, --limit <N>  (int, default: 500)
        Hard maximum on files that can be opened in a single
        invocation. If the count exceeds this, npp aborts with
        a warning. Use this to prevent accidental mass-open.

    -ct, --confirmThreshold <N>  (int, default: 50)
        If the resolved file count exceeds this threshold, an
        interactive confirmation prompt appears:
          a  => open all files
          n  => open first N (threshold value)
          c  => cancel
          #  => open first # files (user-specified number)
        Empty Enter cancels the operation.

    -x, --exe [<path>]  (string[])
        Editor executable management.
          -x               show file dialog / console prompt
          -x "path"        set editor to the given path
        The resolved path is saved to config.json permanently.
        If -x is the only argument (no files), npp returns after
        saving the editor path.

    -h, --help  (switch)
        Show full help (summary + comprehensive + examples).

    --help-summary  (switch)
        Show summary/cheatsheet only.

    --examples  (switch)
        Show usage examples only.

    -Verbose  (switch, inherited from CmdletBinding)
        Show detailed diagnostic output during execution.

  EDITOR RESOLUTION ORDER
    1. Explicit -x / --exe path (validated and saved)
    2. Stored config (config.json in home directory)
    3. NPP_PATH environment variable (legacy)
    4. Auto-detection: Notepad++ > code > subl > atom > nano > vim > notepad
    5. File dialog (Windows) or console prompt (Linux/macOS)

  CONFIG FILE
    Location: home-directory/.nppcli/config.json
    Format:   { "EditorPath": "C:\\path\\to\\editor.exe" }
    Created automatically on first editor selection.

  EXECUTION FLOW
    1. Check help flags --> display help and return
    2. Handle -x / --exe --> set editor if requested
    3. Resolve editor executable (5-step cascade)
    4. If no file arguments --> launch bare editor
    5. Parse extension filter (-e)
    6. Classify input paths (files / directories / patterns)
    7. Directory mode: scan with Get-ChildItem + filters
    8. Non-directory mode: expand wildcards + filters
    9. Deduplicate and sort results
    10. Apply --first / --last selection
    11. Check hard limit (-l)
    12. Confirmation prompt if count > threshold (-ct)
    13. Launch editor with final file list

  FILE CREATION BEHAVIOR
    When a literal path (no wildcards) does not exist:
    - Parent directories are created automatically
    - The file is created as an empty file
    - The file is then opened in the editor
    This only applies to literal paths. Wildcard patterns that
    match nothing produce "No files matched." instead.

  EDGE CASES & NOTES
    - --first takes priority over --last if both are specified
    - -d with no directory defaults to current directory "."
    - -e accepts mixed forms in a single invocation
    - Paths with spaces work when quoted: npp "my file.txt"
    - The -x parameter is [string[]] to handle space-split paths;
      elements are joined internally
    - Empty Enter at confirmation prompt cancels the operation
    - All module source files are pure ASCII (PS 5.1 compatibility)

  COMPATIBILITY
    - Windows PowerShell 5.1+    fully supported
    - PowerShell 7+ (pwsh)       fully supported (Windows/Linux/macOS)
    - No hard-coded path separators; cross-platform throughout
    - Join-Path 2-argument chains for PS 5.1 compatibility

  AUTHOR
    Davood Yahya (DavoodSec) - DSecurity
    GitHub:   https://github.com/davoodya
    Website:  https://davoodya.ir

"@
    Write-Host $text
}

function Show-NppHelpExamples {
    <#
    .SYNOPSIS
        Displays practical usage examples for the npp command.
        Covers basic through advanced real-world scenarios.
    #>
    [CmdletBinding()]
    param()

    $text = @"

  NppCLI v3.0.0 - Usage Examples
  ==============================

  BASIC - Open Files
    npp file.txt                      Open (or create) a single file
    npp file1.txt file2.txt           Open multiple files
    npp README.md                     Open an existing file
    npp subfolder/config.json         Create parent dirs + file, then open

  BASIC - Wildcards
    npp *.txt                         Open all .txt in current directory
    npp *.txt *.css                   Open all .txt and .css files
    npp file?.log                     Single-char wildcard
    npp test[1-5].txt                 Range wildcard
    npp report*                       Prefix wildcard

  DIRECTORY SCANNING
    npp -d src                        Open all files in src/
    npp -d src *.php                  Open .php files in src/
    npp -d src *.php *.js             Open .php and .js files in src/
    npp --directory project           Long form

  RECURSIVE SCANNING
    npp -d src -r                     Recursively open all files in src/
    npp -d src -r *.py                Recursive, only .py files
    npp -d project --recursive        Long form

  EXTENSION FILTERING
    npp -d src -e php                 Filter by .php extension
    npp -d src -r -e php,txt          Multiple extensions, comma-separated
    npp -d src -r -e .py,.txt         With dots (auto-normalized)
    npp -d src -e php -e js           Multiple -e flags
    npp -e csv *.txt *.csv            Extension filter + wildcards

  HIDDEN FILES
    npp -a *.log                      Include hidden .log files
    npp -d logs -r -a                 Recursive scan including hidden
    npp --hidden *.conf               Long form

  FIRST / LAST SELECTION
    npp -d project -r --first 5       Open only first 5 matched files
    npp -d project -r --last 3        Open only last 3 matched files
    npp *.log --first 10              First 10 .log files in current dir
    npp -d logs -r -a --last 20       Last 20 files, including hidden

  FILE LIMIT & CONFIRMATION
    npp -d big-folder -l 100          Set hard limit to 100 files
    npp -d big-folder -ct 20          Confirm if more than 20 files
    npp -d data --limit 200 --confirmThreshold 100

  EDITOR MANAGEMENT
    npp -x                            Open file dialog to select editor
    npp --exe                         Same as above (long form)
    npp -x "C:\Program Files\Notepad++\notepad++.exe"
                                      Set editor to Notepad++
    npp --exe "/usr/bin/code"         Set editor to VS Code (Linux)
    npp -x "C:\Program Files\Sublime Text\subl.exe"
                                      Set editor to Sublime Text

  COMBINED ADVANCED PATTERNS
    npp -d project -r -a -e py,txt --first 20
        Recursive scan of project/, include hidden files,
        filter to .py and .txt, open only the first 20.

    npp -r -a -d src *.csv *.txt
        Same as: npp -d src -r -a *.csv *.txt
        (parameter order does not matter)

    npp -d mu-plugins -e php --limit 100
        Scan mu-plugins/ for .php files, hard limit at 100.

    npp -x "C:\Program Files\Notepad++\notepad++.exe" file1.txt file2.txt
        Set editor AND open files in a single command.

  LAUNCH EDITOR ONLY
    npp                               Launch editor with no files

  VERBOSE DIAGNOSTICS
    npp -d src -r -Verbose            See detailed resolution output
    npp *.txt -Verbose                See wildcard expansion details

  HELP
    npp -h                            Full help (all sections)
    npp --help                        Same as -h
    npp --help-summary                Quick reference cheatsheet
    npp --examples                    Show these examples

"@
    Write-Host $text
}

function Show-NppHelp {
    <#
    .SYNOPSIS
        Dispatches the appropriate help section(s) based on flags.
    .PARAMETER Summary
        Show only the summary section.
    .PARAMETER Examples
        Show only the examples section.
    .PARAMETER Full
        Show all sections (summary + comprehensive + examples).
    #>
    [CmdletBinding()]
    param(
        [switch]$Summary,
        [switch]$Examples,
        [switch]$Full
    )

    if ($Summary -and -not $Full) {
        Show-NppHelpSummary
        return
    }

    if ($Examples -and -not $Full) {
        Show-NppHelpExamples
        return
    }

    # Full help (default): all three sections
    Show-NppHelpSummary
    Show-NppHelpComprehensive
    Show-NppHelpExamples
}
