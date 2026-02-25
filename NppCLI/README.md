# NppCLI - PowerShell Module for Notepad++ File Management

**NppCLI** is a PowerShell module that provides a powerful CLI to open files and directories in Notepad++.  
It supports advanced features like file creation, wildcard expansion, directory scanning, recursive file discovery, extension filtering, hidden file handling, interactive confirmation, and file limits.

---

## Installation

### Option 1: Module Directory (Recommended)

Copy `NppCLI.psm1` and `NppCLI.psd1` into:

```
$HOME\Documents\PowerShell\Modules\NppCLI\
```

PowerShell will auto-discover the module. Use it directly:

```powershell
npp file.txt
```

### Option 2: Import in your Profile

Add to your `$PROFILE`:

```powershell
Import-Module NppCLI
```

### Option 3: Manual Import

```powershell
Import-Module "C:\path\to\NppCLI\NppCLI.psd1"
```

---

## Command: `npp`

### Syntax

```
npp [-d] [-r] [-a|--hidden] [-ext <extensions>] [-limit <number>] [-confirmThreshold <number>] [<Paths...>]
```

### Parameters

- **`-d`** (Switch) — Directory mode. Treat path arguments as directories and scan for files inside them.
- **`-r`** (Switch) — Recursive. Scan directories recursively. Works with `-d` and with wildcards.
- **`-a`** / **`-hidden`** (Switch) — Include hidden files in scans.
- **`-ext <string>`** — Comma-separated list of extensions to filter (e.g., `-ext php,txt`).
- **`-limit <int>`** — Maximum number of files that can be opened at once. Default: `500`.
- **`-confirmThreshold <int>`** — File count above which a confirmation prompt appears. Default: `50`.
- **`Paths`** (String[]) — One or more files, directories, or wildcard patterns.

---

## Features

### Open Files in Notepad++

Open any file or multiple files directly:

```powershell
npp file1.txt file2.txt
```

### Create Files Automatically

If a file does not exist, it will be created and opened:

```powershell
npp README.md
npp newfile.txt
npp subfolder\config.json   # Creates subfolder if needed
```

### Wildcard Support

Open files using standard wildcards:

```powershell
npp *.txt
npp file?.txt
npp new*
npp test[1-5].txt
npp *.txt *.css
```

### Directory Mode (`-d`)

Open all files inside a directory:

```powershell
npp -d mu-plugins
```

### Wildcard with Directory

Open only matching files inside a directory:

```powershell
npp -d mu-plugins *.php
npp -d mu-plugins *.php *.js
```

### Recursive Directory Scanning (`-r`)

```powershell
npp -d mu-plugins -r
npp -d mu-plugins -r *.php
```

### Extension Filter (`-ext`)

Only open files with specified extensions:

```powershell
npp -d mu-plugins -ext php
npp -d mu-plugins -r -ext php,txt
```

### Hidden Files (`-a`)

```powershell
npp -a *.log
npp -d logs -r -a
```

### File Limit (`-limit`)

Prevent opening too many files at once:

```powershell
npp -d big-folder -limit 100
```

### Confirmation Prompt (`-confirmThreshold`)

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
- **`a`** — Open all files
- **`n`** — Open first N files (threshold value)
- **`c`** — Cancel
- **`<number>`** — Open the first `<number>` files

### No Arguments

Launch Notepad++ with no files:

```powershell
npp
```

---

## Example Commands

### Open specific files

```powershell
npp file1.txt file2.txt
```

### Create and open new files

```powershell
npp README.md newfile.txt
```

### Wildcards

```powershell
npp *.txt
npp file?.txt
npp new*
npp test[1-5].txt
```

### Open directory

```powershell
npp -d mu-plugins
```

### Directory with wildcard filter

```powershell
npp -d mu-plugins *.php
npp -d mu-plugins -r *.php
npp -d mu-plugins -r -ext php,txt
```

### Include hidden files

```powershell
npp -a *.log
npp -d logs -r -a
```

### Confirmation prompt

```powershell
npp -d big-folder -r
# Prompts if files > 50 by default
```

### Limit maximum files

```powershell
npp -d big-folder -limit 100
```

### Verbose output

```powershell
npp -d mu-plugins -r -Verbose
```

---

## Profile Integration

After installing the module to `$HOME\Documents\PowerShell\Modules\NppCLI\`, you can **remove** the old `npp` function from your PowerShell profile and replace it with:

```powershell
Import-Module NppCLI
```

This gives you the full `npp` command with all features. The old inline function in your profile is no longer needed.

---

## Troubleshooting

- **"Notepad++ not found"** — Ensure Notepad++ is installed at `C:\Program Files\Notepad++\notepad++.exe`. If installed elsewhere, edit the `$exe` variable in `NppCLI.psm1`.
- **Confirm prompt appears unexpectedly** — Lower the `-confirmThreshold` value, or increase it to avoid prompts: `npp -d folder -confirmThreshold 200`.
- **Wildcard `?` not matching** — Ensure the pattern is quoted if your shell is interpreting it: `npp 'file?.txt'`.
- **Old `npp` function conflicts** — Remove or comment out the `function npp {}` block in your `$PROFILE` before using the module.

---

## Notes & Known Limitations

- File creation only works for literal paths, not wildcards.
- Confirm prompt requires interactive console focus.
- Module is intended for Windows and requires Notepad++.
- Compatible with Windows PowerShell 5.1+ and PowerShell 7+.
- When using `-d` without specifying a directory, the current directory is used.

---

## License

MIT License

## Author

**Davood Yahya (Davoodya)** — PowerShell Automation & Security Tools
