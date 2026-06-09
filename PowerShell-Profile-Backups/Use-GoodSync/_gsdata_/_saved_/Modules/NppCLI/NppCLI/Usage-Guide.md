# NppCLI Usage Guide

**Complete Command Reference & User Manual**

NppCLI v3.0.0 | Author: Davood Yahya (DavoodSec) | DSecurity

---

## Table of Contents

- [Quick Start](#quick-start)
- [Command Syntax](#command-syntax)
- [Parameters Reference](#parameters-reference)
- [Help Flags](#help-flags)
- [Editor Configuration](#editor-configuration)
- [Opening Files](#opening-files)
- [Wildcard Patterns](#wildcard-patterns)
- [Directory Scanning](#directory-scanning)
- [Recursive Scanning](#recursive-scanning)
- [Extension Filtering](#extension-filtering)
- [Hidden Files](#hidden-files)
- [First / Last Selection](#first--last-selection)
- [File Limits & Confirmation](#file-limits--confirmation)
- [Combined Advanced Patterns](#combined-advanced-patterns)
- [Execution Flow](#execution-flow)
- [Editor Resolution Order](#editor-resolution-order)
- [File Creation Behavior](#file-creation-behavior)
- [Configuration File](#configuration-file)
- [Edge Cases & Notes](#edge-cases--notes)
- [Cross-Platform Compatibility](#cross-platform-compatibility)
- [Cheatsheet](#cheatsheet)
- [Troubleshooting](#troubleshooting)

---

## Quick Start

```powershell
# Install
Install-Module -Name NppCLI -Scope CurrentUser

# Open a file (creates it if it doesn't exist)
npp file.txt

# Open multiple files
npp file1.txt file2.txt README.md

# Open all .txt files in current directory
npp *.txt

# Scan a directory for PHP files
npp -d src *.php

# Recursive scan with extension filter
npp -d project -r -e py,txt

# Select your editor
npp -x

# View help
npp -h
```

---

## Command Syntax

```
npp [-d|--directory] [-r|--recursive] [-a|--hidden]
    [-e|--extension <extensions>] [--first <N>] [--last <N>]
    [-l|--limit <N>] [-ct|--confirmThreshold <N>]
    [-x|--exe [<path>]] [-h|--help] [--help-summary] [--examples]
    [<Paths...>]
```

Parameters can appear in **any order**. All of these are equivalent:

```powershell
npp -d project -a -r *.csv *.txt
npp -r -a -d project *.csv *.txt
npp *.csv *.txt -d project -r -a
```

---

## Parameters Reference

### -d, --directory (switch)

Directory scanning mode. Path arguments are treated as directories to scan for files.

```powershell
npp -d src                    # Scan src/ directory
npp --directory project       # Long form
```

Without `-d`, if you pass a directory name, you get a warning: `'src' is a directory. Use -d flag to scan directories.`

If `-d` is used with no directory argument, it defaults to the current directory `.`

### -r, --recursive (switch)

Recurse into subdirectories when scanning.

```powershell
npp -d src -r                 # Recursively scan src/
npp -d src --recursive        # Long form
```

Also works with wildcard expansion in non-directory mode.

### -a, --hidden (switch)

Include hidden and system files in scan results. Maps to `-Force` on `Get-ChildItem` internally.

```powershell
npp -a *.log                  # Include hidden .log files
npp -d logs -r -a             # Recursive scan including hidden
npp --hidden *.conf           # Long form
```

Aliases: `-a`, `-hidden`, `--hidden`, `-IncludeHidden`

### -e, --extension (string[])

Filter results by file extension(s). Accepts all of these forms:

```powershell
npp -e php                    # Single extension
npp -e php,txt                # Comma-separated
npp -e .php,.txt              # With dots
npp -e "php, txt"             # Quoted with spaces
npp -e " .csv , txt , .json " # Messy input (auto-cleaned)
npp -e php -e txt             # Multiple -e flags
npp --extension php,txt       # Long form
```

Extensions are normalized internally: leading dots removed, lowercased, deduplicated.

Aliases: `-e`, `-ext`, `--extension`

### --first N (int, default: 0)

After all filtering and sorting, open only the first N matched files.

```powershell
npp -d project -r --first 5   # Open first 5 matched files
npp *.log --first 10           # First 10 .log files
```

If N exceeds the total file count, all files are opened. If both `--first` and `--last` are specified, `--first` takes priority.

### --last N (int, default: 0)

After all filtering and sorting, open only the last N matched files.

```powershell
npp -d project -r --last 3    # Open last 3 matched files
npp -d logs -r -a --last 20   # Last 20 files, including hidden
```

If N exceeds the total file count, all files are opened. Ignored if `--first` is also specified.

### -l, --limit N (int, default: 500)

Hard maximum on files that can be opened in a single invocation. If the resolved file count exceeds this number, npp aborts with a warning.

```powershell
npp -d big-folder -l 100      # Abort if more than 100 files
npp -d data --limit 200       # Long form
```

### -ct, --confirmThreshold N (int, default: 50)

If the resolved file count exceeds this threshold, an interactive confirmation prompt is displayed:

```
120 files detected.
  a => open all 120 files
  n => open first 50 files
  c => cancel
  or enter a number (1-120)

Choice:
```

Options:
- **`a`** -- Open all files
- **`n`** -- Open first N files (threshold value)
- **`c`** -- Cancel operation
- **`<number>`** -- Open the first `<number>` files
- **Empty Enter** -- Cancels the operation

```powershell
npp -d big-folder -ct 20      # Confirm if more than 20 files
npp -d data --confirmThreshold 100
```

### -x, --exe (string[])

Editor executable management.

```powershell
npp -x                        # Show file dialog / console prompt
npp --exe                     # Same (long form)
npp -x "C:\Program Files\Notepad++\notepad++.exe"   # Set specific editor
npp --exe "/usr/bin/code"     # Set editor (Linux)
```

The resolved path is saved permanently to the config file. If `-x` is the only argument (no files to open), npp returns after saving the editor path.

You can combine `-x` with files:

```powershell
npp -x "C:\Program Files\Notepad++\notepad++.exe" file1.txt file2.txt
```

This sets the editor AND opens the files in a single command.

### Paths (positional, string[])

All remaining arguments are treated as file paths, directory paths, or wildcard patterns.

```powershell
npp file.txt                  # Single file
npp file1.txt file2.txt       # Multiple files
npp *.txt *.css               # Multiple wildcards
npp -d src *.php *.js         # Directory + patterns
```

---

## Help Flags

NppCLI includes a built-in help system with three layers.

### -h, --help

Show full help output: summary cheatsheet + comprehensive reference + usage examples.

```powershell
npp -h
npp --help
```

### --help-summary

Show only the compact summary/cheatsheet section. Designed for quick terminal reference.

```powershell
npp --help-summary
```

### --examples

Show only the usage examples section.

```powershell
npp --examples
```

Help flags are intercepted before any other logic executes. They produce zero overhead and no editor resolution occurs.

---

## Editor Configuration

### First Run

On first use, if no editor is configured:
- **Windows:** A file open dialog appears to select an executable
- **Linux/macOS:** A console prompt asks for the full path

The selected path is saved permanently.

### Setting the Editor

```powershell
# Interactive selection
npp -x
npp --exe

# Direct path
npp -x "C:\Program Files\Notepad++\notepad++.exe"
npp --exe "/usr/bin/code"
npp -x "C:\Program Files\Microsoft VS Code\Code.exe"
npp -x "C:\Program Files\Sublime Text\subl.exe"
```

### Changing the Editor

Run `npp -x` at any time to select a new editor. The new path overwrites the previous configuration.

---

## Opening Files

### Basic File Opening

```powershell
npp file.txt                  # Open file.txt
npp file1.txt file2.txt       # Open multiple files
npp README.md                 # Open existing file
```

### Automatic File Creation

If a file does not exist, NppCLI creates it (including parent directories):

```powershell
npp newfile.txt               # Creates newfile.txt, then opens it
npp subfolder/config.json     # Creates subfolder/ and config.json
npp deep/nested/dir/file.py   # Creates entire path
```

File creation only applies to **literal paths** (no wildcards).

### Launch Editor with No Files

```powershell
npp                           # Opens the editor with no files
```

---

## Wildcard Patterns

NppCLI supports PowerShell-style wildcard patterns:

| Pattern | Matches |
|---------|---------|
| `*` | Any sequence of characters |
| `?` | Any single character |
| `[abc]` | Any one of a, b, c |
| `[a-z]` | Any character in range |
| `[!0-9]` | Any character NOT in range |

```powershell
npp *.txt                     # All .txt files
npp *.txt *.css               # All .txt and .css files
npp file?.log                 # file1.log, fileA.log, etc.
npp test[1-5].txt             # test1.txt through test5.txt
npp report*                   # report.csv, report_final.txt, etc.
```

Wildcard patterns that match zero files produce: `No files matched.`

---

## Directory Scanning

Use `-d` to scan directories for files:

```powershell
npp -d src                    # All files in src/
npp -d src *.php              # Only .php files in src/
npp -d src *.php *.js         # .php and .js files in src/
npp --directory project       # Long form
```

Without `-d`, passing a directory name produces a warning.

If `-d` is used with no directory argument, the current directory is scanned.

---

## Recursive Scanning

Add `-r` to recurse into subdirectories:

```powershell
npp -d src -r                 # All files in src/ and subdirectories
npp -d src -r *.py            # Only .py files, recursively
npp -d project -r --recursive # Long form
```

Recursion also works with wildcard expansion in non-directory mode:

```powershell
npp *.txt -r                  # Expand *.txt recursively
```

---

## Extension Filtering

The `-e` parameter filters results by file extension, independent of wildcard patterns:

```powershell
npp -d src -e php             # Only .php files
npp -d src -r -e php,txt      # .php and .txt files, recursively
npp -d src -r -e .py,.txt     # Same (dots auto-stripped)
npp -d src -e php -e js       # Multiple -e flags
npp -e csv *.txt *.csv        # Filter wildcards by extension
```

Extension normalization:
- Leading dots are removed: `.php` becomes `php`
- Values are lowercased: `PHP` becomes `php`
- Duplicates are removed: `php,php,txt` becomes `php,txt`
- Spaces are trimmed: ` .csv , txt ` becomes `csv,txt`

---

## Hidden Files

By default, hidden and system files are excluded. Use `-a` to include them:

```powershell
npp -a *.log                  # Include hidden .log files
npp -d logs -r -a             # Recursive scan including hidden
npp --hidden *.conf           # Long form
```

---

## First / Last Selection

Select a subset of matched files after all filtering:

```powershell
# First N files
npp -d project -r --first 5
npp *.log --first 10

# Last N files
npp -d project -r --last 3
npp -d logs -r -a --last 20
```

If both `--first` and `--last` are specified, `--first` takes priority and a warning is emitted about `--last` being ignored.

---

## File Limits & Confirmation

### Hard Limit (-l / --limit)

Prevents accidentally opening too many files:

```powershell
npp -d big-folder -l 100      # Abort if more than 100 files
```

Default: 500 files. If exceeded, npp aborts with a warning.

### Confirmation Threshold (-ct / --confirmThreshold)

Triggers an interactive prompt when file count exceeds the threshold:

```powershell
npp -d big-folder -ct 20      # Confirm if more than 20 files
```

Default: 50 files. The prompt offers:
- `a` -- open all
- `n` -- open first N (threshold value)
- `c` -- cancel
- Any number -- open that many files

---

## Combined Advanced Patterns

```powershell
# Recursive scan with extension filter, hidden files, first 20
npp -d project -r -a -e py,txt --first 20

# Multiple wildcards with directory mode (order doesn't matter)
npp -r -a -d src *.csv *.txt

# Extension filter with custom limit
npp -d mu-plugins -e php --limit 100

# Set editor and open files in one command
npp -x "C:\Program Files\Notepad++\notepad++.exe" file1.txt file2.txt

# Verbose output for debugging
npp -d src -r -Verbose

# Custom confirmation threshold with recursive scan
npp -d data -r -e csv --confirmThreshold 100 --limit 200
```

---

## Execution Flow

When you run `npp`, the following steps execute in order:

1. **Help check** -- If `-h`, `--help-summary`, or `--examples` is set, display help and return immediately.
2. **Editor management** -- If `-x`/`--exe` is set, handle editor selection/setting.
3. **Resolve editor** -- Find the editor executable through the 5-step cascade.
4. **No-argument check** -- If no paths were given, launch the bare editor.
5. **Extension filter setup** -- Parse `-e` into a normalized extension list.
6. **Classify inputs** -- Sort arguments into files, directories, and patterns.
7. **Directory scan** -- If `-d` is active, scan directories with `Get-ChildItem`.
8. **Wildcard expansion** -- If not `-d`, expand wildcard patterns.
9. **Deduplicate & sort** -- Remove duplicate paths and sort alphabetically.
10. **First/Last selection** -- Apply `--first` or `--last` to narrow results.
11. **Hard limit check** -- If count exceeds `-l`, abort.
12. **Confirmation prompt** -- If count exceeds `-ct`, prompt the user.
13. **Launch editor** -- Open all resolved files in the editor.

---

## Editor Resolution Order

NppCLI resolves the editor executable through a 5-step cascade:

1. **Explicit `-x`/`--exe` path** -- If provided and valid, use it. Save to config.
2. **Stored config** -- Read from `$HOME/.nppcli/config.json`.
3. **`$env:NPP_PATH`** -- Legacy environment variable (backward compatibility).
4. **Auto-detection** -- Search for common editors in this order:
   - Notepad++ (common install paths, PATH)
   - `code` (VS Code)
   - `subl` / `sublime_text` (Sublime Text)
   - `atom` (Atom)
   - `nano`
   - `vim` / `vi`
   - `notepad` (Windows fallback)
5. **Interactive selection** -- File dialog (Windows) or console prompt (Linux/macOS).

Once an editor is found, it is saved to config for future use.

---

## File Creation Behavior

When a **literal path** (no wildcards) does not exist:

1. Parent directories are created automatically via `New-Item -ItemType Directory`
2. The file is created as an empty file via `New-Item -ItemType File`
3. The file is then opened in the editor

This behavior only applies to literal paths. Wildcard patterns that match nothing produce `No files matched.` and do not create any files.

---

## Configuration File

**Location:** `$HOME/.nppcli/config.json`

**Example contents:**

```json
{
    "EditorPath": "C:\\Program Files\\Notepad++\\notepad++.exe"
}
```

The config file is created automatically on first editor selection. It stores the editor path permanently so you only need to configure it once.

The config directory is `$HOME/.nppcli/` which works on all platforms:
- Windows: `C:\Users\username\.nppcli\config.json`
- Linux: `/home/username/.nppcli/config.json`
- macOS: `/Users/username/.nppcli/config.json`

---

## Edge Cases & Notes

- **`--first` vs `--last`**: If both are specified, `--first` wins and a warning is emitted.
- **`-d` with no directory**: Defaults to current directory `.`
- **Extension mixing**: `-e` accepts mixed forms in a single invocation (e.g., `-e .php,txt`)
- **Paths with spaces**: Quote them: `npp "my file.txt"` or `npp -x "C:\Program Files\My Editor\editor.exe"`
- **`-x` path splitting**: The `-x` parameter is `[string[]]` internally. If PowerShell splits a path on spaces, the elements are joined back together.
- **Empty Enter at prompt**: Cancels the confirmation operation.
- **Verbose mode**: Use `-Verbose` to see detailed diagnostic output (file counts, filter results, paths resolved).
- **Parameter order**: All parameters can be specified in any order. NppCLI uses `PositionalBinding = $false` with `ValueFromRemainingArguments`.

---

## Cross-Platform Compatibility

| Platform | Status |
|----------|--------|
| Windows PowerShell 5.1+ | Fully supported |
| PowerShell 7+ (Windows) | Fully supported |
| PowerShell 7+ (Linux) | Fully supported |
| PowerShell 7+ (macOS) | Fully supported |

**Design decisions for cross-platform:**
- All path operations use `Join-Path`, `Resolve-Path`, `Split-Path` (no hardcoded separators)
- `Join-Path` uses 2-argument chaining for PowerShell 5.1 compatibility
- Editor selection: Windows Forms dialog on Windows, `Read-Host` fallback on Linux/macOS
- Config stored in `$HOME/.nppcli/config.json` (works on all platforms)
- All module source files are pure ASCII (prevents PS 5.1 encoding issues)

---

## Cheatsheet

```
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

QUICK EXAMPLES
  npp file.txt                  Open (or create) file.txt
  npp *.txt *.css               Open all .txt and .css files
  npp -d src -r -e py,js        Recursive scan, filter by extension
  npp -d logs --first 10        Open first 10 files from logs/
  npp -x                        Select editor via dialog/prompt
  npp                           Launch editor with no files
  npp -h                        Show full help
```

---

## Troubleshooting

- **"No editor found"** -- Run `npp -x` or `npp --exe` to select an editor. Or set `$env:NPP_PATH`.
- **Confirm prompt appears unexpectedly** -- Increase the threshold: `npp -d folder -ct 200`
- **Wildcard `?` not matching** -- Quote the pattern if your shell interprets it: `npp 'file?.txt'`
- **Old `npp` function conflicts** -- Remove any `function npp {}` block from your `$PROFILE` and use `Import-Module NppCLI` instead.
- **Extension filter not working** -- Use: `-e php,txt` or `-e .php,.txt` or `-e php -e txt`
- **Editor path with spaces** -- Quote it: `npp -x "C:\Program Files\My Editor\editor.exe"`
- **File count exceeds limit** -- Use `-l` to increase the hard limit, or use `--first`/`--last` to narrow results.
- **Module not loading** -- Ensure the module is in a PowerShell module path: `$env:PSModulePath -split ';'`

---

## Module Information

| Field | Value |
|-------|-------|
| Module Name | NppCLI |
| Version | 3.0.0 |
| Author | Davood Yahya (DavoodSec) |
| Company | DSecurity |
| License | MIT |
| Min PowerShell | 5.1 |
| GitHub | [github.com/davoodya/NppCLI](https://github.com/davoodya/NppCLI) |
| Website | [davoodya.ir](https://davoodya.ir) |

---

*Generated for NppCLI v3.0.0 -- February 2026*
