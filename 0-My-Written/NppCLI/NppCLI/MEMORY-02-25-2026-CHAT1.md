# MEMORY CHECKPOINT - NppCLI Module Development
# Date: February 25, 2026 - Chat Session 1
# AI Agent: Claude (Opus)
# Human: Davood Yahya (DavoodSec / davoodya)

---

## FOR AI AGENT: READ THIS FIRST

You are continuing development on a PowerShell module called **NppCLI**. This file is a complete memory dump from a prior chat session. It tells you exactly what was built, what was fixed, what was tested, and what the current state of every file is. Read it fully before making any changes.

---

## PROJECT OVERVIEW

- **Module Name:** NppCLI
- **Purpose:** PowerShell CLI wrapper to open files and directories in Notepad++
- **Current Version:** 2.0.0
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

This is inside the PowerShell module auto-discovery path, so `Import-Module NppCLI` works natively in PowerShell 7+ (pwsh). Windows PowerShell 5.1 uses a different path (`WindowsPowerShell` instead of `PowerShell`), so the user imports via the profile or full path for 5.1.

---

## FILE INVENTORY (Current State as of End of Chat 1)

```
NppCLI/
  NppCLI.psm1                      # Main module - the npp function (COMPLETE, TESTED)
  NppCLI.psd1                      # Module manifest v2.0.0 (COMPLETE, PSGallery-ready)
  README.md                        # Full documentation (COMPLETE)
  test_syntax.ps1                  # 56-test comprehensive suite (ALL PASSING)
  Microsoft.PowerShell_profile.ps1 # User's PS profile (reference copy, NOT the live profile)
  MEMORY-02-25-2026-CHAT1.md       # This file
```

**Important:** The `Microsoft.PowerShell_profile.ps1` in this folder is a reference copy of the user's profile. The actual live profile is at `$PROFILE` (typically `$HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1`). In the prior session, the old inline `npp` function (187 lines, from line 142 to 328) was replaced with `Import-Module NppCLI -ErrorAction SilentlyContinue` (at line 140-141 of the reference copy).

---

## WHAT WAS DONE (Complete History)

### Phase 1: Initial Refactor (Early in Chat)

The user had a broken `npp` function defined inline in their PowerShell profile. It had these problems:

1. **File creation failed** - `npp README.md` would not create the file and sometimes hung at a confirm prompt
2. **Confirm prompt inconsistency** - would trigger unexpectedly or hang waiting for input
3. **Wildcards like `?` didn't work** - detection regex was correct but flow logic was broken
4. **Wildcards after `-d` were treated as directories** - e.g., `npp -d mu-plugins *.php` would warn "Directory not found: *.php"
5. **Parameter binding errors** - `[switch]` parameters would sometimes eat the next string argument
6. **No differentiation** between literal paths, wildcards, and directory paths

**What we did:**
- Rewrote the entire `npp` function from scratch in `NppCLI.psm1`
- Used `[CmdletBinding(PositionalBinding = $false)]` to prevent positional binding errors
- Used `[Parameter(ValueFromRemainingArguments = $true)]` on `$Paths` to collect all remaining args
- Built a 3-way classifier: directories go to `$directories`, wildcards go to `$patterns`, literals go to `$resolvedFiles`
- In `-d` mode: wildcards and plain names (without path separators) are classified as pattern filters, NOT as directories
- File creation: checks if parent dir exists, creates it if needed, then creates the file, then resolves to absolute path
- Confirm prompt: only triggers when `$count > $confirmThreshold`, handles a/n/c/number/empty-input
- Created `NppCLI.psd1` manifest (v1.0.0)
- Replaced the inline function in the profile with `Import-Module NppCLI`

**Critical fix discovered:** Em dash characters (`---`) in comments caused Windows PowerShell 5.1 to fail parsing the file. PS 5.1 reads UTF-8 files without BOM as ANSI/Windows-1252, which corrupts multi-byte UTF-8 characters. All em dashes were replaced with regular dashes (`-`). **Rule: NEVER use non-ASCII characters in .psm1 or .psd1 files.**

### Phase 2: Major Upgrade to v2.0.0 (Later in Chat)

The user requested a comprehensive upgrade with these new requirements:

1. **Fix `-ext` parameter** - was not filtering correctly
2. **Cross-platform compatibility** - no hard-coded paths, use `Join-Path`
3. **Add `-first` and `-last` parameters** - open only first/last N matched files
4. **Prepare for PowerShell Gallery** - proper metadata, GUID, tags, URIs
5. **Parameter order independence** - any order must work
6. **All combinations must work** - wildcards + dirs + ext + first/last + recursive + hidden

**What we did:**

- **Removed hard-coded Notepad++ path** - replaced with 3-tier auto-detection:
  1. `$env:NPP_PATH` environment variable (user override)
  2. Common Windows install locations: `Program Files`, `Program Files (x86)`, `LocalAppData`, Scoop
  3. `Get-Command` PATH search for `notepad++` or `notepad++.exe`

- **Fixed all `Join-Path` calls for PS 5.1** - PS 5.1 `Join-Path` only accepts 2 arguments (not 3+). All multi-level paths now chain: `Join-Path (Join-Path $a $b) $c`

- **Added `-first` and `-last` parameters** - `[int]$first = 0` and `[int]$last = 0`. Applied AFTER all filtering/sorting but BEFORE limit check and confirm prompt. If both specified, `-first` wins with a warning.

- **Fixed `-ext` parsing** - Now correctly handles: `py,txt`, `.py,.txt`, `" .csv , txt , .json "`, `PHP` (case-insensitive). Uses `@()` array subexpression directly on the pipeline (not via function return) to avoid PowerShell's single-element array unwrapping.

- **Updated manifest to v2.0.0** with:
  - New GUID: `d01cb7f7-cf5a-4e7f-9271-682e6f37a768`
  - Author: `Davood Yahya (DavoodSec)`
  - Company: `DSecurity`
  - LicenseUri: `https://github.com/davoodya/NppCLI/blob/main/LICENSE`
  - ProjectUri: `https://github.com/davoodya/NppCLI`
  - 15 tags for PSGallery discoverability
  - Full release notes

- **Wrote comprehensive test suite** (56 tests across 10 groups - all passing on PS 5.1 AND PS 7+)

---

## CURRENT FUNCTION SIGNATURE

```powershell
function npp {
    [CmdletBinding(PositionalBinding = $false)]
    param(
        [switch]$d,                    # Directory mode
        [switch]$r,                    # Recursive
        [Alias("a")]
        [switch]$hidden,               # Include hidden files
        [string]$ext,                  # Extension filter (comma-separated)
        [int]$limit = 500,             # Hard file limit
        [int]$confirmThreshold = 50,   # Confirm prompt threshold
        [int]$first = 0,              # Open first N files
        [int]$last = 0,               # Open last N files
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Paths              # Files, dirs, or wildcard patterns
    )
}
```

---

## FUNCTION EXECUTION FLOW (Architecture)

```
1. NOTEPAD++ DETECTION
   $env:NPP_PATH -> common paths -> Get-Command PATH search
   
2. NO ARGS CHECK
   If no $Paths -> launch bare Notepad++ and return

3. EXTENSION FILTER SETUP
   Parse -ext "py,txt" -> @("py", "txt") normalized array

4. CLASSIFY INPUT ARGUMENTS (main loop over $Paths)
   For each argument:
     IF -d mode:
       - existing directory?   -> add to $directories
       - has wildcards?        -> add to $patterns
       - no path separators?   -> add to $patterns (name filter)
       - else                  -> warning "Directory not found"
     ELSE (file mode):
       - has wildcards?        -> add to $patterns
       - existing file?        -> resolve to absolute, add to $resolvedFiles
       - existing directory?   -> warning "use -d"
       - non-existent?         -> CREATE FILE (+ parent dirs), add to $resolvedFiles

5. DIRECTORY MODE SCAN (if -d)
   If no dirs found, default to current dir "."
   For each dir:
     Get-ChildItem (with -Recurse if -r, -Force if -hidden)
     Filter by $patterns (name -like pattern)
     Filter by $extList (extension match)
     Collect FullName paths

6. NON-DIRECTORY WILDCARD EXPANSION (if not -d)
   For each wildcard pattern:
     Get-ChildItem on the pattern itself
     Filter by $extList
     Collect FullName paths

7. DEDUPLICATE + SORT
   Sort-Object -Unique on $resolvedFiles

8. EMPTY CHECK
   If count = 0, print "No files matched." and return

9. -first / -last SELECTION
   If -first > 0: Select-Object -First $first
   If -last > 0:  Select-Object -Last $last
   If both: -first wins, -last ignored with warning

10. HARD LIMIT CHECK
    If count > $limit: abort with warning

11. CONFIRMATION PROMPT (if count > $confirmThreshold)
    a = open all, n = open first $threshold, c = cancel, number = open first N
    Handles: empty input, invalid input, out-of-range numbers

12. LAUNCH NOTEPAD++
    Single file:  & $exe $resolvedFiles[0]
    Multiple:     & $exe @resolvedFiles (splatting)
```

---

## BUGS FIXED (Complete List)

| # | Bug | Root Cause | Fix |
|---|-----|-----------|-----|
| 1 | File creation hangs at confirm prompt | Confirm threshold check ran even for 1 file when no files matched | Restructured flow: create file -> add to resolved -> confirm only if count > threshold |
| 2 | `npp -d folder *.php` warns "Directory not found: *.php" | In `-d` mode, all args were tested with `Test-Path -PathType Container` | Added wildcard detection regex `[\*\?\[\]]` to classify patterns separately |
| 3 | `-d` switch eats next string argument | `PositionalBinding` was not disabled, or param was not `[switch]` | `[CmdletBinding(PositionalBinding=$false)]` + proper `[switch]` types |
| 4 | `?` wildcard doesn't work | Detection was fine, but `Get-ChildItem` wasn't being called for patterns | Patterns now correctly routed to `Get-ChildItem` or `Where-Object -like` |
| 5 | Non-ASCII characters break PS 5.1 parsing | Em dashes (UTF-8 multi-byte) corrupted when PS 5.1 reads file as ANSI | All non-ASCII removed. **Rule: pure ASCII only in .psm1/.psd1** |
| 6 | `Join-Path` with 3+ args fails on PS 5.1 | PS 5.1 `Join-Path` only accepts 2 positional arguments | Chain calls: `Join-Path (Join-Path $a $b) $c` |
| 7 | `-ext PHP` single-extension case fails | `@()` wrapping a function return still unwraps single elements | Used `@()` directly on pipeline (not via function return) in the module. In tests, wrap with `@()` at call site |
| 8 | Hard-coded `C:\Program Files\Notepad++\notepad++.exe` | Not cross-platform | Auto-detection: env var -> common paths -> PATH search |
| 9 | `$resolvedFiles` could contain `$null` from empty `Get-ChildItem` | `$files.FullName` on empty result returns `$null` | Explicit null check: `if ($f -and $f.FullName)` before `.Add()` |
| 10 | Confirm prompt doesn't handle empty Enter key | `Read-Host` returns empty string, `.ToLower()` on `$null` throws | Added `[string]::IsNullOrWhiteSpace($choice)` guard |

---

## TEST SUITE STATUS

**56 tests, 100% pass rate on BOTH PowerShell 5.1 AND PowerShell 7+**

```
GROUP  1: Module Import                    - 2 tests  (PASS)
GROUP  2: Parameter Types & Binding        - 9 tests  (PASS)
GROUP  3: CmdletBinding Attributes         - 3 tests  (PASS)
GROUP  4: Wildcard Detection Regex         - 11 tests (PASS)
GROUP  5: Extension Filter Parsing Logic   - 8 tests  (PASS)
GROUP  6: File Creation Logic              - 3 tests  (PASS)
GROUP  7: -first / -last Selection Logic   - 5 tests  (PASS)
GROUP  8: Cross-Platform Path Handling     - 2 tests  (PASS)
GROUP  9: Directory Scan + Filter Simulation - 5 tests (PASS)
GROUP 10: Module Manifest Validation       - 8 tests  (PASS)
```

Run tests with:
```powershell
# PowerShell 7+
pwsh -NoProfile -ExecutionPolicy Bypass -File test_syntax.ps1

# PowerShell 5.1
powershell -NoProfile -ExecutionPolicy Bypass -File test_syntax.ps1
```

---

## KNOWN CONSTRAINTS & DESIGN DECISIONS

1. **Pure ASCII only** in `.psm1` and `.psd1` files. Windows PowerShell 5.1 reads UTF-8-without-BOM as ANSI, corrupting any non-ASCII byte sequences. This caused the first session's hardest-to-find bug.

2. **`Join-Path` always 2-argument chains** for PS 5.1 compatibility. PS 7+ supports variadic `Join-Path a b c` but PS 5.1 does not.

3. **`@()` array wrapping** must be done at the assignment site, not inside a function return. PowerShell unwraps single-element arrays when returning from functions. In the module, `$extList = @(pipeline...)` works. In the test, `$e4 = @(Parse-ExtList "PHP")` is needed.

4. **`[System.Collections.Generic.List[string]]::new()`** works on PS 5.1 (tested and confirmed). No need to use `New-Object`.

5. **File creation only for literal paths** - never for wildcards. If `$p` contains `*`, `?`, `[`, or `]`, it's treated as a wildcard pattern, never as a file to create.

6. **`-first` takes priority over `-last`** if both are specified. Emits a warning.

7. **Confirm prompt** only fires after `-first`/`-last` selection. The flow is: filter -> sort -> first/last -> limit check -> confirm -> launch.

8. **`-d` with no directory argument** defaults to the current directory `"."` - this is intentional so `npp -d *.php` works (scans current dir for PHP files).

---

## PSDATA / GALLERY METADATA

```
GUID          : d01cb7f7-cf5a-4e7f-9271-682e6f37a768
Version       : 2.0.0
Author        : Davood Yahya (DavoodSec)
Company       : DSecurity
PSVersion     : 5.1 (minimum)
LicenseUri    : https://github.com/davoodya/NppCLI/blob/main/LICENSE
ProjectUri    : https://github.com/davoodya/NppCLI
Tags          : Notepad++, NppCLI, npp, Editor, FileManagement, CLI, Windows,
                CrossPlatform, Wildcard, DirectoryScanner, FileOpener,
                Automation, PowerShell, Productivity, DevTools
Exports       : npp (function only)
```

---

## PROFILE INTEGRATION

The user's PowerShell profile at line 139-141 now reads:

```powershell
# NppCLI Module - open files/dirs in Notepad++ | usage: npp file.txt | npp -d folder *.php
# Full-featured module loaded from: $HOME\Documents\PowerShell\Modules\NppCLI\
Import-Module NppCLI -ErrorAction SilentlyContinue
```

The old 187-line inline `function npp {}` block was completely removed from the profile.

---

## WHAT IS NOT YET DONE / POTENTIAL FUTURE WORK

These items were NOT requested but may come up in future sessions:

1. **No LICENSE file** exists in the repo yet. The manifest references `https://github.com/davoodya/NppCLI/blob/main/LICENSE` but that file doesn't exist. Need to create a `LICENSE` file (MIT) before publishing to PSGallery or GitHub.

2. **Not yet published to PSGallery.** The manifest is ready. User needs to:
   ```powershell
   Publish-Module -Path "c:\Users\davoo\Documents\PowerShell\Modules\NppCLI" -NuGetApiKey "API_KEY"
   ```

3. **Not yet pushed to GitHub.** No `.git` directory exists. User needs to `git init`, create the repo on GitHub, and push.

4. **No `.gitignore`** exists. Should exclude `_npp_test_temp/`, `_npp_scan_test/`, and any `*.tmp` files.

5. **No tab-completion / argument completer** is registered. Could add `Register-ArgumentCompleter` for `-ext` (common extensions) and `$Paths` (file/directory completion).

6. **No `-sort` parameter** for controlling sort order (name, date, size). Currently always sorts alphabetically.

7. **No `-dryrun` / `-WhatIf` mode** to preview matched files without opening them.

8. **No Pester tests** - the current test suite is a custom script (`test_syntax.ps1`). Could be migrated to Pester framework for standardized PowerShell testing.

9. **No CI/CD pipeline** (GitHub Actions) for automated testing on multiple PowerShell versions.

10. **The test suite does NOT test the actual `npp` function end-to-end** (because calling `npp` would launch Notepad++). It tests all the internal logic components in isolation. A mock-based Pester test could solve this.

11. **No CHANGELOG.md** file. Release notes are only in the manifest.

---

## USER'S FULL FEATURE WISHLIST (from FEATURES-TODO.md)

The file `FEATURES-TODO.md` contains the user's full wishlist in Farsi. Here is the translated/summarized version with status:

### Category 1: Advanced File & Directory Management
- [x] Auto-create missing files/directories
- [x] Recursive directory browsing (`-r`)
- [x] Hidden/system files support (`-a` / `-hidden`)
- [x] File filtering by multiple extensions (`-ext py,txt,css`)

### Category 2: File Count Control
- [x] Limit number of files (`-limit`)
- [x] Open first/last N files (`-first`, `-last`)
- [x] Confirmation prompt for large sets

### Category 3: Wildcards & Complex Paths
- [x] Advanced wildcards (`*`, `?`, `[a-z]`)
- [x] Relative/absolute path support
- [x] Path normalization (Resolve-Path)
- [ ] Negation wildcards like `[!0-9]` - NOT TESTED, may work via PowerShell's native `-like`

### Category 4: Cross-Platform & PowerShell Core
- [x] Windows PowerShell 5.1, PowerShell 7.x and Core compatible
- [x] Cross-platform path handling (Join-Path)
- [x] Auto-detect Notepad++ path
- [ ] Alternative editors for Linux/macOS (e.g., VS Code fallback) - NOT IMPLEMENTED

### Category 5: Advanced UX
- [ ] Tab Completion for paths, wildcards, and commands
- [ ] History integration (suggest files from previous runs)
- [x] Verbose/Debug mode (`-Verbose`)
- [x] Colored output (confirmation prompt, warnings, errors)
- [ ] Aliases/shortcuts (e.g., `np` shortcut)

### Category 6: Tool Integration
- [ ] Git integration (open modified/staged files)
- [ ] Open files from specific commits or branches
- [ ] Project config file support (JSON/YAML)
- [ ] Clipboard support (copy file list)

### Category 7: Module & Extensibility
- [x] PowerShell Gallery ready (manifest, metadata, tags)
- [ ] Extensible plugin system
- [ ] Logging (record opened files, timestamps)
- [ ] Self-update from GitHub/PSGallery

### Category 8: Automation & Scripts
- [ ] Batch open from config file
- [ ] Scheduled tasks integration
- [ ] Macro recording (replay file sequences)

### Category 9: Safety & Reliability
- [ ] Safe open (check if file is locked)
- [x] Error handling (path errors, access errors, invalid files)
- [ ] Atomic operations / rollback

---

## HOW TO RESUME IN A NEW CHAT

When you receive this file in a new chat, do the following:

1. **Read this entire file** to understand the project state.
2. **Read `NppCLI.psm1`** to see the current implementation.
3. **Read `NppCLI.psd1`** to see the current manifest.
4. **Run `test_syntax.ps1`** on both PS 5.1 and PS 7+ to verify everything still passes.
5. **Ask the user** what they want to work on next.
6. **Remember these rules:**
   - Pure ASCII only in `.psm1` and `.psd1` (no em dashes, no Unicode)
   - `Join-Path` chains of 2 args only (PS 5.1 compatibility)
   - Test on BOTH `powershell` (5.1) and `pwsh` (7+)
   - `@()` array wrapping at assignment site, not function returns
   - Never break the existing 56 passing tests

---

*End of memory checkpoint. Last verified: Feb 25, 2026, all 56 tests passing on PS 5.1 and PS 7+.*
