# NppCLI - PowerShell Module for Editor File Management

**NppCLI** is a powerful cross-platform PowerShell module that provides a CLI to open files and directories in **any editor** (Notepad++, VSCode, Sublime, nano, vim, or any custom executable).

It supports advanced features including file creation, wildcard expansion, directory scanning, recursive file discovery, extension filtering, first/last file selection, hidden file handling, interactive confirmation, file limits, persistent editor configuration, and cross-platform editor selection.

- **Author:** Davood Yahya (DavoodSec)
- **Company:** DSecurity
- **Version:** 3.0.0
- **GitHub:** [https://github.com/davoodya](https://github.com/davoodya)
- **Website:** [https://davoodya.ir](https://davoodya.ir)
- **Telegram:** [https://t.me/davoodyahay](https://t.me/davoodyahay)
- **LinkedIn:** [https://linkedin.com/in/davoodya](https://linkedin.com/in/davoodya)

---

## Installation

### Option 1: From PowerShell Gallery (Recommended)

```powershell
Install-Module -Name NppCLI -Scope CurrentUser
```

### Option 2: Module Directory (Manual)

Copy the entire `NppCLI` folder (including `Private/` subdirectory) into:

```
$HOME\Documents\PowerShell\Modules\NppCLI\
```

PowerShell will auto-discover the module. Use it directly:

```powershell
npp file.txt
```

### Option 3: Import in your Profile

Add to your `$PROFILE`:

```powershell
Import-Module NppCLI
```

### Option 4: Manual Import

```powershell
Import-Module "C:\path\to\NppCLI\NppCLI.psd1"
```

---

## Architecture

NppCLI v3.0.0 uses a modular architecture with separated concerns:

```
NppCLI/
  NppCLI.psm1          # Main module - the npp function
  NppCLI.psd1          # Module manifest (PSGallery-ready)
  Private/
    Config.ps1          # Persistent configuration ($HOME/.nppcli/config.json)
    EditorResolver.ps1  # Editor detection, selection, validation
    FileResolver.ps1    # File classification, scanning, extension filtering
  test_syntax.ps1       # Comprehensive test suite (115 tests)
  README.md             # This file
```

### Separation of Concerns

- **Config.ps1** - Handles reading/writing `$HOME/.nppcli/config.json`. Stores the editor path permanently. No dependency on environment variables for normal operation.

- **EditorResolver.ps1** - Resolves the editor executable through a 5-step cascade:
  1. Explicit `-x` / `--exe` parameter
  2. Stored config path
  3. `$env:NPP_PATH` (legacy support)
  4. Auto-detection (Notepad++, VSCode, Sublime, nano, vim, etc.)
  5. File dialog (Windows) or console prompt (Linux/macOS)
Write a Checkpoint and Summary from all tasks done in this chat in the {{insert}}.md. I want to send this file to you in another chat so you can remember all of the tasks and jobs done here. So this memory-checkpoint file is suitable and ready for AI Agents like YOU with Cluade Models. Write this memory and help file in a way that is convenient for you, and by reading it,t you will understand exactly what you have done, what features you have implemented, what bugs you have fixed, and where you actually are and where you should start.
- **FileResolver.ps1** - All file operations: wildcard detection, extension normalization, input path classification (directories vs. patterns vs. literal files), directory scanning with filters, and wildcard expansion.

---

## Editor Configuration

### First Run

On first use, if no editor is configured, NppCLI will:
- **Windows:** Show a file open dialog to select an executable
- **Linux/macOS:** Prompt you to type the full path

The selected path is saved permanently to `$HOME/.nppcli/config.json`.

### Setting the Editor

```powershell
# Show file dialog (Windows) or console prompt (Linux/macOS)
npp -x
npp --exe

# Set a specific editor path directly
npp -x "C:\Program Files\Notepad++\notepad++.exe"
npp --exe "/usr/bin/code"
npp -x "C:\Program Files\Microsoft VS Code\Code.exe"
```

### Auto-Detection Order

If no editor is configured, NppCLI tries:
1. `$env:NPP_PATH` environment variable (legacy support)
2. Common Notepad++ install locations (Program Files, Scoop, etc.)
3. Common editors on PATH: `code`, `subl`, `sublime_text`, `atom`, `nano`, `vim`, `notepad`

### Config File Location

```
$HOME/.nppcli/config.json
```

Example contents:
```json
{
    "EditorPath": "C:\\Program Files\\Notepad++\\notepad++.exe"
}
```

---

## Command: `npp`

### Syntax

```
npp [-d|--directory] [-r|--recursive] [-a|--hidden]
    [-e|--extension <extensions>] [--first <N>] [--last <N>]
    [-l|--limit <number>] [-ct|--confirmThreshold <number>]
    [-x|--exe [<path>]] [<Paths...>]
```

### Parameters

| Short | Long | Type | Default | Description |
|-------|------|------|---------|-------------|
| `-d` | `--directory` | Switch | | Directory mode. Scan directories for files. |
| `-r` | `--recursive` | Switch | | Recursive. Scan directories recursively. |
| `-a` | `--hidden` | Switch | | Include hidden/system files. |
| `-e` | `--extension` | String[] | | Extension filter(s). Comma-separated or array. |
| | `--first` | Int | 0 | Open only the first N matched files. |
| | `--last` | Int | 0 | Open only the last N matched files. |
| `-l` | `--limit` | Int | 500 | Maximum files that can be opened at once. |
| `-ct` | `--confirmThreshold` | Int | 50 | File count above which confirmation appears. |
| `-x` | `--exe` | String[] | | Set/select editor executable. |
| | `Paths` | String[] | | Files, directories, or wildcard patterns. |

### Extension Parameter (-e / --extension)

The extension parameter now accepts **all these forms** without errors:

```powershell
npp -e php                    # Single extension
npp -e php,txt                # Comma-separated
npp -e .php,.txt              # With dots
npp -e "php,txt"              # Quoted comma-separated
npp -e " .csv , txt , .json " # With spaces and dots
npp --extension php,txt       # Long form
npp -e php -e txt             # Multiple -e flags (array binding)
```

All forms are normalized internally: dots removed, lowercased, deduplicated.

### Parameter Order Independence

Parameters can be specified in **any order**. All of these are equivalent:

```powershell
npp -d project -a -r *.csv *.txt
npp -r -a -d project *.csv *.txt
npp --directory project --recursive --hidden *.csv *.txt
npp -r --directory project -e php,txt *.php *.txt
npp *.csv *.txt -d project -r -a
```

---

## Features

### Open Files

```powershell
npp file1.txt file2.txt
```

### Create Files Automatically

If a file does not exist, it will be created (including parent directories):

```powershell
npp README.md
npp newfile.txt
npp subfolder/config.json
```

### Wildcard Support

```powershell
npp *.txt
npp file?.txt
npp new*
npp test[1-5].txt
npp *.txt *.css
```

### Directory Mode (-d / --directory)

```powershell
npp -d mu-plugins
npp --directory mu-plugins
npp -d mu-plugins *.php
npp -d mu-plugins *.php *.js
```

### Recursive Scanning (-r / --recursive)

```powershell
npp -d mu-plugins -r
npp -d mu-plugins --recursive *.php
```

### Extension Filter (-e / --extension)

```powershell
npp -d mu-plugins -e php
npp -d mu-plugins -r -e php,txt
npp -d mu-plugins -r --extension .py,.txt
npp -e csv *.txt *.csv
```

### First / Last File Selection (--first / --last)

```powershell
npp -d project -r *.csv *.txt --first 5
npp -d project -r *.csv *.txt --last 3
npp *.log --first 10
npp -d logs -r -a --last 20
```

If both `--first` and `--last` are specified, `--first` takes priority.

### Hidden Files (-a / --hidden)

```powershell
npp -a *.log
npp --hidden *.log
npp -d logs -r -a
```

### File Limit (-l / --limit)

```powershell
npp -d big-folder -l 100
npp -d big-folder --limit 100
```

### Confirmation Prompt (-ct / --confirmThreshold)

If the number of files exceeds the threshold, you are prompted:

```
120 files detected.
  a => open all 120 files
  n => open first 50 files
  c => cancel
  or enter a number (1-120)

Choice:
```

Options:
- **`a`** - Open all files
- **`n`** - Open first N files (threshold value)
- **`c`** - Cancel
- **`<number>`** - Open the first `<number>` files

### No Arguments

Launch the editor with no files:

```powershell
npp
```

### Verbose Output

```powershell
npp -d mu-plugins -r -Verbose
```

---

## Editor Examples

### Use Notepad++

```powershell
npp -x "C:\Program Files\Notepad++\notepad++.exe"
npp file.txt
```

### Use Visual Studio Code

```powershell
npp --exe "C:\Program Files\Microsoft VS Code\Code.exe"
npp file.txt
```

### Use Sublime Text

```powershell
npp -x "C:\Program Files\Sublime Text\subl.exe"
npp *.py
```

### Use nano (Linux)

```powershell
npp --exe "/usr/bin/nano"
npp config.yml
```

### Change Editor at Any Time

```powershell
npp -x    # Opens file dialog / console prompt
npp --exe # Same thing
```

---

## Combined Examples

```powershell
# Recursive scan with extension filter and first N
npp -d project -r -a -e py,txt --first 20

# Multiple wildcards with directory mode
npp -r -a -d project *.csv *.txt

# Extension filter with limit
npp -d mu-plugins -e php --limit 100

# Set editor and open files in one command
npp -x "C:\Program Files\Notepad++\notepad++.exe" file1.txt file2.txt
```

---

## Cross-Platform Compatibility

- **Windows PowerShell 5.1+** - Fully supported
- **PowerShell 7+ (pwsh)** - Fully supported on Windows, Linux, and macOS
- No hard-coded path separators - uses `Join-Path`, `Resolve-Path`, `Split-Path` throughout
- Editor selection: Windows Forms dialog on Windows, Read-Host fallback on Linux/macOS
- Config stored in `$HOME/.nppcli/config.json` (works on all platforms)
- All `Join-Path` calls use 2-argument chaining for PS 5.1 compatibility
- Pure ASCII in all module source files (prevents PS 5.1 encoding issues)

---

## Running Tests

The test suite includes 115 tests across 19 groups:

```powershell
# PowerShell 7+
pwsh -NoProfile -ExecutionPolicy Bypass -File test_syntax.ps1

# PowerShell 5.1
powershell -NoProfile -ExecutionPolicy Bypass -File test_syntax.ps1

# Keep temp files for debugging
.\test_syntax.ps1 -SkipCleanup
```

### Test Groups

1. Module Import (2 tests)
2. Parameter Types & Binding (10 tests)
3. Short + Long Flag Aliases (9 tests)
4. CmdletBinding Attributes (2 tests)
5. Wildcard Detection Regex (11 tests)
6. Extension Filter Parsing (9 tests)
7. Extension Matching (5 tests)
8. File Creation Logic (3 tests)
9. --first / --last Selection (5 tests)
10. Cross-Platform Path Handling (4 tests)
11. Config System (4 tests)
12. Editor Resolver (5 tests)
13. File Resolver Functions (9 tests)
14. Directory Scan + Filter Simulation (9 tests)
15. Input Path Classification (4 tests)
16. Module Manifest Validation (10 tests)
17. Private Module Files (4 tests)
18. ASCII-Only Compliance (5 tests)
19. Edge Cases - Extension Parameter (5 tests)

---

## Publishing to PowerShell Gallery

```powershell
# Test the manifest first
Test-ModuleManifest -Path .\NppCLI.psd1

# Publish
Publish-Module -Path .\NppCLI -NuGetApiKey "YOUR_API_KEY"
```

---

## Troubleshooting

- **"No editor found"** - Use `npp -x` or `npp --exe` to select an editor. Or set `$env:NPP_PATH`.
- **Confirm prompt appears unexpectedly** - Increase the threshold: `npp -d folder -ct 200` or `npp -d folder --confirmThreshold 200`.
- **Wildcard `?` not matching** - Quote the pattern if your shell interprets it: `npp 'file?.txt'`.
- **Old `npp` function conflicts** - Remove the `function npp {}` block from your `$PROFILE` and use `Import-Module NppCLI` instead.
- **Extension filter not working** - Use: `-e php,txt` or `-e .php,.txt` or `-e php -e txt`.
- **Editor path with spaces** - Quote it: `npp -x "C:\Program Files\My Editor\editor.exe"`.

---

## Migration from v2.0.0

### Changed Parameters

| v2.0.0 | v3.0.0 | Notes |
|--------|--------|-------|
| `-ext` | `-e` / `--extension` / `-ext` (alias) | Now accepts arrays. `-ext` still works as alias. |
| `-hidden` | `-a` / `--hidden` / `-IncludeHidden` | `-a` and `-hidden` still work as aliases. |
| `-limit` | `-l` / `--limit` | `-limit` still works as alias. |
| `-confirmThreshold` | `-ct` / `--confirmThreshold` | `-confirmThreshold` still works as alias. |
| N/A | `-x` / `--exe` | NEW: Set/select editor executable. |
| N/A | `--directory` | NEW: Long form alias for `-d`. |
| N/A | `--recursive` | NEW: Long form alias for `-r`. |

### Breaking Changes

- The module now uses persistent config instead of only `$env:NPP_PATH`. Existing `$env:NPP_PATH` is still respected as a fallback.
- `-ext` parameter type changed from `[string]` to `[string[]]`. This fixes the multi-extension bug but means the internal type is different. All existing usage patterns still work.

---

## Changelog

### v3.0.0

- Generalized editor support (any executable editor)
- Persistent config storage (`$HOME/.nppcli/config.json`)
- File dialog for editor selection (Windows) with console fallback (Linux/macOS)
- New `-x` / `--exe` parameter for editor management
- Fixed extension parameter: renamed to `-e` / `--extension`, now `[string[]]` type
- Short + long flag support for all parameters
- Modular architecture (Private/Config.ps1, EditorResolver.ps1, FileResolver.ps1)
- 115-test comprehensive test suite
- Full cross-platform path handling
- ASCII-only compliance verification

### v2.0.0

- Cross-platform Notepad++ auto-detection
- Cross-platform path handling (no hard-coded backslashes)
- New `-first N` and `-last N` parameters
- Fixed `-ext` parameter handling
- Comprehensive test suite
- Ready for PowerShell Gallery publication

### v1.0.0

- Initial release with file opening, creation, wildcards, directory scanning, extension filtering, and confirmation prompts.

---

## License

MIT License

## Author

**Davood Yahya (DavoodSec)** - DSecurity - PowerShell Automation & Security Tools
