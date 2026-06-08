# MEMORY CHECKPOINT - NppCLI Module Development
# Date: February 25, 2026 - Chat Session 2
# AI Agent: Claude (Anthropic)
# Human: Davood Yahya (DavoodSec / davoodya)

---

## FOR AI AGENT: READ THIS FIRST

You are continuing development on a PowerShell module called **NppCLI**.
This file is a COMPLETE memory dump from chat sessions 1 and 2.
It contains EVERYTHING: what was built, what was fixed, what was tested,
what the current state of every file is, every bug encountered, every
design decision made, and every rule you MUST follow.

**Read this entire file before touching any code.**

Previous memory file: `MEMORY-02-25-2026-CHAT1.md` (Chat 1 history - you
can skip it; everything relevant is carried forward into THIS file.)

---

## PROJECT OVERVIEW

- **Module Name:** NppCLI
- **Purpose:** PowerShell CLI wrapper to open files and directories in ANY editor
- **Current Version:** 3.0.0
- **Previous Versions:** 1.0.0 (Chat 1 early), 2.0.0 (Chat 1 final)
- **Author:** Davood Yahya (DavoodSec)
- **Company:** DSecurity
- **GitHub:** https://github.com/davoodya
- **Website:** https://davoodya.ir
- **Telegram:** https://t.me/davoodyahay
- **LinkedIn:** https://linkedin.com/in/davoodya

### Workspace Location

```
c:\Users\davoo\Documents\PowerShell\Modules\NppCLI\
```

This is inside the PowerShell 7+ module auto-discovery path, so
`Import-Module NppCLI` works natively. Windows PowerShell 5.1 uses a
different path (`WindowsPowerShell`), so the user imports via the profile
or full path for 5.1.

---

## COMPLETE FILE INVENTORY (End of Chat 2)

```
NppCLI/
  NppCLI.psm1                        # Main module file - exports the npp function
  NppCLI.psd1                        # Module manifest v3.0.0 (PSGallery-ready)
  Private/
    Config.ps1                        # Persistent JSON config ($HOME/.nppcli/config.json)
    EditorResolver.ps1                # Editor auto-detection, dialog, validation
    FileResolver.ps1                  # File classification, wildcards, scanning, ext filter
  test_syntax.ps1                     # 115-test automated suite (ALL PASSING both PS versions)
  README.md                          # Full user documentation
  TESTING-GUIDE.md                   # Empty - was created but NOT yet written
  FEATURES-TODO.md                   # User's feature wishlist in Farsi
  Microsoft.PowerShell_profile.ps1   # Reference copy of user's PS profile (NOT the live one)
  MEMORY-02-25-2026-CHAT1.md         # Memory from chat 1 (historical, superseded by this file)
  MEMORY-02-25-2026-CHAT2.md         # THIS FILE
```

### Config file on disk

```
$HOME/.nppcli/config.json
```

As of end of Chat 2: this file does NOT exist on disk yet. It gets created
automatically on first `npp` invocation or when user runs `npp -x`.

---

## VERSION HISTORY (What happened across both chats)

### Chat 1: v1.0.0 -> v2.0.0

The user had a broken 187-line inline `npp` function in their PS profile.
We extracted it into a proper module and fixed these 10 bugs:

1. File creation hung at confirm prompt
2. `npp -d folder *.php` warned "Directory not found: *.php"
3. `-d` switch ate the next string argument
4. `?` wildcard didn't work
5. Non-ASCII em dashes broke PS 5.1 parsing (THE HARDEST BUG)
6. `Join-Path` with 3+ args failed on PS 5.1
7. `-ext PHP` single-extension case failed
8. Hard-coded Notepad++ path
9. `$resolvedFiles` could contain `$null`
10. Confirm prompt didn't handle empty Enter key

We then upgraded to v2.0.0 with:
- Notepad++ auto-detection (env var -> common paths -> PATH search)
- `-first` / `-last` parameters
- Fixed `-ext` parsing for comma-separated strings
- 56-test suite (all passing)
- PSGallery-ready manifest
- Replaced inline function in profile with `Import-Module NppCLI`

### Chat 2: v2.0.0 -> v3.0.0 (CURRENT)

Major architecture refactor. Five critical tasks completed:

1. **Fixed extension parameter** - renamed to `-e`/`--extension`, changed
   from `[string]` to `[string[]]`, created robust normalization function
2. **Generalized editor support** - no longer hardcoded to Notepad++, works
   with ANY executable editor
3. **Executable path management** - new `-x`/`--exe` flag, persistent JSON
   config, Windows file dialog, first-run experience
4. **Short + long flag support** - all params have short/long aliases
5. **Cross-platform paths** - Join-Path everywhere, no hardcoded separators
6. **Modular architecture** - split into Private/Config.ps1,
   Private/EditorResolver.ps1, Private/FileResolver.ps1

Test suite expanded from 56 to 115 tests. All passing on both PS 5.1 and 7+.

---

## CURRENT ARCHITECTURE (v3.0.0)

### Module Loading Chain

```
NppCLI.psd1 (manifest)
  -> NppCLI.psm1 (root module)
       -> dot-sources Private/Config.ps1
       -> dot-sources Private/EditorResolver.ps1
       -> dot-sources Private/FileResolver.ps1
       -> defines function npp { ... }
       -> Export-ModuleMember -Function npp
```

Only the `npp` function is exported. All private functions are available
inside the module scope but invisible to the user.

### Function Signature

```powershell
function npp {
    [CmdletBinding(PositionalBinding = $false)]
    param(
        [Alias('directory')]
        [switch]$d,

        [Alias('recursive')]
        [switch]$r,

        [Alias('a', 'hidden')]
        [switch]$IncludeHidden,

        [Alias('extension', 'ext')]
        [string[]]$e,

        [Alias('limit')]
        [int]$l = 500,

        [Alias('confirmThreshold')]
        [int]$ct = 50,

        [int]$first = 0,
        [int]$last = 0,

        [Alias('exe')]
        [string[]]$x,

        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Paths
    )
}
```

### Parameter Map (Short / Long / Internal / Type / Default)

| Short | Long | Internal | Type | Default |
|-------|------|----------|------|---------|
| `-d` | `--directory` | `$d` | switch | off |
| `-r` | `--recursive` | `$r` | switch | off |
| `-a` | `--hidden` | `$IncludeHidden` | switch | off |
| `-e` | `--extension` (also `-ext`) | `$e` | string[] | none |
| `-l` | `--limit` | `$l` | int | 500 |
| `-ct` | `--confirmThreshold` | `$ct` | int | 50 |
| n/a | `--first` | `$first` | int | 0 |
| n/a | `--last` | `$last` | int | 0 |
| `-x` | `--exe` | `$x` | string[] | none |
| n/a | (remaining args) | `$Paths` | string[] | none |

### Execution Flow (npp function)

```
1. HANDLE -x / --exe
   - If -x with no value  -> $showExeDialog = true
   - If -x "some/path"    -> $exePathArg = "some/path"

2. RESOLVE EDITOR EXECUTABLE
   - If $showExeDialog     -> Resolve-EditorExecutable -ShowDialog
   - If $exePathArg        -> Resolve-EditorExecutable -ExePath $exePathArg
   - Else (normal)         -> Resolve-EditorExecutable
     Resolution cascade:
       Step 1: Explicit -exe path (validate + save)
       Step 2: Stored config ($HOME/.nppcli/config.json)
       Step 3: $env:NPP_PATH legacy
       Step 4: Auto-detect (Npp -> code -> subl -> atom -> nano -> vim -> notepad)
       Step 5: File dialog / console prompt (first-run)

3. NO ARGUMENTS CHECK
   If no $Paths -> launch bare editor and return

4. EXTENSION FILTER SETUP
   If -e given -> ConvertTo-NormalizedExtensionList -> $extList array

5. CLASSIFY INPUT ARGUMENTS (Resolve-InputPaths)
   For each arg in $Paths:
     -d mode: existing dir -> $directories
              wildcard     -> $patterns
              plain name   -> $patterns (filter)
              else         -> warning
     File mode: wildcard    -> $patterns
                existing file -> $resolvedFiles (absolute)
                existing dir  -> warning "use -d"
                non-existent  -> CREATE FILE, add to $resolvedFiles

6. DIRECTORY MODE SCAN (Invoke-DirectoryScan)
   If -d: scan each $directory with Get-ChildItem
   Apply $patterns as -like name filters
   Apply $extList as extension filters
   Add results to $resolvedFiles

7. NON-DIRECTORY WILDCARD EXPANSION (Invoke-WildcardExpansion)
   If NOT -d and patterns exist: expand each via Get-ChildItem
   Apply $extList as extension filter
   Add results to $resolvedFiles

8. DEDUPLICATE + SORT
   $resolvedFiles | Sort-Object -Unique

9. EMPTY CHECK
   If 0 files -> "No files matched." -> return

10. --first / --last SELECTION
    If both -> --first wins, warning about --last ignored
    Apply Select-Object -First or -Last

11. HARD LIMIT CHECK
    If count > $l -> abort with warning

12. CONFIRMATION PROMPT
    If count > $ct -> interactive a/n/c/number prompt
    Handles: empty Enter, invalid input, out-of-range numbers

13. LAUNCH EDITOR
    Single file: & $exe $resolvedFiles[0]
    Multiple:    & $exe @resolvedFiles
```

### Private Module: Config.ps1

**Functions:**
- `Get-NppCLIConfigDir` - Returns `$HOME/.nppcli` (Join-Path)
- `Get-NppCLIConfigPath` - Returns `$HOME/.nppcli/config.json`
- `Get-NppCLIConfig` - Reads JSON, returns hashtable (empty if missing)
- `Save-NppCLIConfig` - Writes hashtable as JSON, creates dir if needed
- `Get-NppCLIEditorPath` - Gets 'EditorPath' from config, validates exists
- `Set-NppCLIEditorPath` - Saves 'EditorPath' to config

**Key detail:** `ConvertFrom-Json` returns PSCustomObject. PS 5.1 cannot
convert this to hashtable natively. So `Get-NppCLIConfig` manually iterates
`$obj.PSObject.Properties` to build a hashtable.

### Private Module: EditorResolver.ps1

**Functions:**
- `Show-EditorFileDialog` - Windows Forms OpenFileDialog (Windows) or
  falls back to `Read-EditorPathFromConsole` (Linux/macOS/headless)
- `Read-EditorPathFromConsole` - Read-Host prompt with examples
- `Find-NotepadPlusPlus` - Checks $env:NPP_PATH, common install paths, PATH
- `Find-CommonEditor` - Tries Npp first, then code/subl/atom/nano/vim/notepad
- `Resolve-EditorExecutable` - Master 5-step cascade (see flow above)

**Key detail:** Platform detection uses `$IsWindows` (PS 6+ automatic var).
In PS 5.1 (always Windows), we default `$isWindows = $true` since PS 5.1
has `$PSVersionTable.PSVersion.Major -lt 6`.

**Key detail:** `Show-EditorFileDialog` wraps `Add-Type -AssemblyName
System.Windows.Forms` in try/catch. If it fails (headless, SSH, WSL),
it falls back to console prompt. This is critical for CI/CD environments.

### Private Module: FileResolver.ps1

**Functions:**
- `Test-IsWildcard` - Regex `[\*\?\[\]]` check
- `ConvertTo-NormalizedExtensionList` - THE FIX for the extension bug.
  Accepts `[string[]]` with `[AllowEmptyString()][AllowEmptyCollection()]`.
  Splits each element on commas, trims, removes dots, lowercases, deduplicates.
- `Test-ExtensionMatch` - Checks file extension against allowed list
- `Resolve-InputPaths` - Classifies args into Directories/Patterns/ResolvedFiles.
  Returns hashtable. Handles file creation for non-existent literal paths.
- `Invoke-DirectoryScan` - Get-ChildItem with splatted params, pattern filter,
  extension filter. Defaults to "." if no dirs given.
- `Invoke-WildcardExpansion` - Expands wildcard patterns via Get-ChildItem,
  applies extension filter.

---

## ALL BUGS FIXED (Complete List Across Both Chats)

| # | Bug | Root Cause | Fix | Chat |
|---|-----|-----------|-----|------|
| 1 | File creation hangs at confirm prompt | Confirm ran even for 1 file | Restructured flow order | 1 |
| 2 | `npp -d folder *.php` warns "Directory not found: *.php" | All args tested as containers | Added wildcard detection regex | 1 |
| 3 | `-d` switch eats next string argument | PositionalBinding not disabled | `[CmdletBinding(PositionalBinding=$false)]` | 1 |
| 4 | `?` wildcard doesn't work | Get-ChildItem not called for patterns | Routed patterns to GCI correctly | 1 |
| 5 | Non-ASCII chars break PS 5.1 | Em dashes (UTF-8 multi-byte) corrupted as ANSI | Removed all non-ASCII. **RULE: pure ASCII only** | 1 |
| 6 | `Join-Path` 3+ args fails PS 5.1 | PS 5.1 only accepts 2 positional args | Chain: `Join-Path (Join-Path $a $b) $c` | 1 |
| 7 | `-ext PHP` single-extension fails | Array unwrapping on function return | `@()` at assignment site, not in function | 1 |
| 8 | Hard-coded Notepad++ path | Not cross-platform | Auto-detection cascade | 1 |
| 9 | `$resolvedFiles` could contain `$null` | Empty GCI result `.FullName` is `$null` | Explicit `if ($f -and $f.FullName)` check | 1 |
| 10 | Confirm prompt crashes on empty Enter | `.ToLower()` on `$null` | `[string]::IsNullOrWhiteSpace()` guard | 1 |
| 11 | `-ext php,txt` throws argument transformation error | `-ext` was `[string]`, can't bind array | Changed to `[string[]]` + normalization function | 2 |
| 12 | Module hardcoded to Notepad++ only | Editor references throughout | Abstracted into EditorResolver.ps1 | 2 |
| 13 | No persistent editor config | Required $env:NPP_PATH every session | JSON config at $HOME/.nppcli/config.json | 2 |
| 14 | `ConvertTo-NormalizedExtensionList` rejects empty string in array | `[Mandatory]` without `[AllowEmptyString()]` | Added `[AllowEmptyString()]` attribute | 2 |
| 15 | ASCII test falsely flagged `.psm1` help example | Help text contained `C:\Program Files\Notepad++\notepad++.exe` literal | Changed example to `C:\path\to\notepad++.exe` | 2 |
| 16 | Non-recursive dir scan test expected 2 files instead of 3 | Test assertion was wrong (a.txt, b.txt, d.csv = 3, not 2) | Fixed test assertion to expect 3 | 2 |

---

## CRITICAL RULES (YOU MUST FOLLOW THESE)

1. **Pure ASCII only** in `.psm1`, `.psd1`, and all `Private/*.ps1` files.
   Windows PowerShell 5.1 reads UTF-8-without-BOM as ANSI/Windows-1252.
   Any byte > 127 will corrupt. No em dashes, no Unicode, no smart quotes.
   The test suite (Group 18) verifies this byte-by-byte.

2. **`Join-Path` always 2-argument chains.** PS 5.1 does NOT support
   `Join-Path a b c`. Always chain: `Join-Path (Join-Path $a $b) $c`.

3. **`@()` array wrapping at assignment site.** PowerShell unwraps
   single-element arrays when returning from functions. Always wrap:
   `$result = @(SomeFunction)` not `return @($thing)` inside the function.

4. **Test on BOTH `powershell` (5.1) and `pwsh` (7+).** Every change.

5. **Never break the existing 115 passing tests.** Run `test_syntax.ps1`
   after every change.

6. **`[System.Collections.Generic.List[string]]::new()`** works on PS 5.1.
   No need for `New-Object`. Confirmed working.

7. **File creation only for literal paths** - never for wildcards. If `$p`
   contains `*`, `?`, `[`, or `]`, it is a pattern, never a file to create.

8. **`--first` takes priority over `--last`** if both specified. Warning emitted.

9. **Confirm prompt fires AFTER --first/--last selection.** Flow:
   filter -> sort -> first/last -> limit check -> confirm -> launch.

10. **`-d` with no directory argument** defaults to current directory `.`

11. **Only `npp` function is exported.** Private functions must NOT leak to
    the user's session via `Export-ModuleMember`.

12. **`-x` is `[string[]]` not `[string]`** to handle paths with spaces
    that PowerShell might split. Elements are joined with space inside the
    function: `$exePathArg = ($x -join ' ').Trim()`.

13. **Config PSCustomObject-to-hashtable conversion** is required for PS 5.1.
    `ConvertFrom-Json` always returns PSCustomObject. Manual iteration via
    `$obj.PSObject.Properties` is the only PS 5.1-safe approach.

---

## TEST SUITE STATUS (Verified: End of Chat 2)

**115 tests, 100% pass rate on BOTH PowerShell 5.1 AND PowerShell 7+**

Run commands:
```powershell
# PowerShell 7+
pwsh -NoProfile -ExecutionPolicy Bypass -File test_syntax.ps1

# PowerShell 5.1
powershell -NoProfile -ExecutionPolicy Bypass -File test_syntax.ps1
```

### Test Groups

```
GROUP  1: Module Import                    -  2 tests  (PASS)
GROUP  2: Parameter Types & Binding        - 10 tests  (PASS)
GROUP  3: Short + Long Flag Aliases        -  9 tests  (PASS)
GROUP  4: CmdletBinding Attributes         -  2 tests  (PASS)
GROUP  5: Wildcard Detection Regex         - 11 tests  (PASS)
GROUP  6: Extension Filter Parsing         -  9 tests  (PASS)
GROUP  7: Extension Matching               -  5 tests  (PASS)
GROUP  8: File Creation Logic              -  3 tests  (PASS)
GROUP  9: --first / --last Selection       -  5 tests  (PASS)
GROUP 10: Cross-Platform Path Handling     -  4 tests  (PASS)
GROUP 11: Config System                    -  4 tests  (PASS)
GROUP 12: Editor Resolver                  -  5 tests  (PASS)
GROUP 13: File Resolver Functions          -  9 tests  (PASS)
GROUP 14: Directory Scan + Filter          -  9 tests  (PASS)
GROUP 15: Input Path Classification        -  4 tests  (PASS)
GROUP 16: Module Manifest Validation       - 10 tests  (PASS)
GROUP 17: Private Module Files             -  4 tests  (PASS)
GROUP 18: ASCII-Only Compliance            -  5 tests  (PASS)
GROUP 19: Edge Cases - Extension Param     -  5 tests  (PASS)
```

**IMPORTANT:** The test suite tests internal logic in isolation. It does NOT
call `npp` end-to-end (because that would launch an actual editor). Manual
end-to-end testing was NOT completed in Chat 2 - user requested a
TESTING-GUIDE.md but it was not filled before the session ended.

---

## PSDATA / GALLERY METADATA

```
GUID          : d01cb7f7-cf5a-4e7f-9271-682e6f37a768
Version       : 3.0.0
Author        : Davood Yahya (DavoodSec)
Company       : DSecurity
Copyright     : (c) 2025-2026 Davood Yahya. MIT License.
PSVersion     : 5.1 (minimum)
LicenseUri    : https://github.com/davoodya/NppCLI/blob/main/LICENSE
ProjectUri    : https://github.com/davoodya/NppCLI
Tags          : NppCLI, npp, Editor, Notepad++, VSCode, Sublime,
                FileManagement, CLI, Windows, Linux, macOS,
                CrossPlatform, Wildcard, DirectoryScanner, FileOpener,
                Automation, PowerShell, Productivity, DevTools
Exports       : npp (function only)
```

---

## BACKWARD COMPATIBILITY NOTES

These v2.0.0 patterns still work in v3.0.0 (aliases preserved):

```powershell
npp -ext php,txt        # -ext is alias for -e
npp -hidden             # -hidden is alias for -IncludeHidden
npp -a                  # -a is alias for -IncludeHidden
npp -limit 100          # -limit is alias for -l
npp -confirmThreshold 5 # -confirmThreshold is alias for -ct
$env:NPP_PATH = "..."   # Still checked as fallback in editor resolution
```

---

## PROFILE INTEGRATION

The user's live PowerShell profile (at `$PROFILE`) has this at line ~140:

```powershell
# NppCLI Module - open files/dirs in Notepad++ | usage: npp file.txt | npp -d folder *.php
# Full-featured module loaded from: $HOME\Documents\PowerShell\Modules\NppCLI\
Import-Module NppCLI -ErrorAction SilentlyContinue
```

The old 187-line inline `function npp {}` was removed from the profile in Chat 1.
The `Microsoft.PowerShell_profile.ps1` in the module folder is a REFERENCE COPY,
not the live profile.

---

## WHAT WAS NOT COMPLETED / PENDING ITEMS

### From Chat 2 specifically:

1. **TESTING-GUIDE.md is EMPTY.** The file was created at
   `c:\Users\davoo\Documents\PowerShell\Modules\NppCLI\TESTING-GUIDE.md`
   but was never written. The user asked for a full manual testing
   instruction guide so they could test every feature end-to-end and
   report back. This was the task in progress when the chat ended.

2. **No manual end-to-end testing was done.** All 115 tests are automated
   internal logic tests. Nobody actually ran `npp file.txt` or `npp -x` or
   `npp -d folder -r -e php,txt` in a real terminal to verify the full
   pipeline. This is the NEXT TASK the user wants done.

### From the broader wishlist (FEATURES-TODO.md):

- No LICENSE file in the repo
- Not published to PSGallery
- Not pushed to GitHub (no .git)
- No .gitignore
- No tab-completion / argument completer
- No -sort parameter
- No -dryrun / -WhatIf mode
- No Pester tests (current suite is custom script)
- No CI/CD pipeline
- No CHANGELOG.md file
- No git integration (open modified/staged files)
- No clipboard support
- No plugin system
- No logging

---

## HOW TO RESUME IN A NEW CHAT

### Step 1: Read this file completely
You now know everything.

### Step 2: Read these files (in order)
```
1. NppCLI.psm1              (main module - ~210 lines)
2. Private/Config.ps1        (config system - ~120 lines)
3. Private/EditorResolver.ps1 (editor finding - ~200 lines)
4. Private/FileResolver.ps1   (file ops - ~290 lines)
5. NppCLI.psd1               (manifest)
6. test_syntax.ps1            (115 tests)
```

### Step 3: Verify tests still pass
```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File test_syntax.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File test_syntax.ps1
```
Expected: 115/115 PASS on both.

### Step 4: Check what the user wants
The most likely next tasks are:
- **Write the TESTING-GUIDE.md** (manual end-to-end testing instructions)
- **Fix any bugs found during manual testing** (user will report results)
- **Features from the wishlist** (tab completion, git integration, etc.)

### Step 5: Follow the rules
- Pure ASCII only in all .ps1/.psm1/.psd1 files
- Join-Path 2-arg chains only
- Test both PS 5.1 and PS 7+
- Never break the 115 tests
- `@()` wrapping at assignment site

---

*End of memory checkpoint.*
*Last verified: February 25, 2026*
*Test suite: 115/115 PASS on both PowerShell 5.1 and PowerShell 7+*
*Module version: 3.0.0*
*Config file: $HOME/.nppcli/config.json (does not exist on disk yet - first run will create it)*
