# Changelog

All notable changes to the NppCLI module are documented in this file.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versioning follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [3.0.0] - 2026-02-26

### Added
- Generalized editor support: works with any executable editor (Notepad++, VSCode, Sublime, nano, vim, etc.)
- Persistent editor configuration stored in `$HOME/.nppcli/config.json`
- Editor selection via file dialog (Windows) or console prompt (Linux/macOS)
- New `-x` / `--exe` parameter for editor path management
- Short + long flag support for all parameters (`-d`/`--directory`, `-r`/`--recursive`, `-a`/`--hidden`, `-e`/`--extension`, `-l`/`--limit`, `-ct`/`--confirmThreshold`)
- Modular architecture: Private/Config.ps1, Private/EditorResolver.ps1, Private/FileResolver.ps1
- Built-in help system: `-h`/`--help`, `--help-summary`, `--examples`
- Private/HelpSystem.ps1 with three-layer help output (summary, comprehensive, examples)
- 128-test automated test suite (all passing on PS 5.1 and PS 7+)
- ASCII-only compliance verification for PS 5.1 safety
- Usage-Guide.md comprehensive documentation
- LICENSE file (MIT)
- CHANGELOG.md

### Changed
- Extension parameter renamed from `-ext` to `-e` / `--extension` (backward-compatible alias `-ext` retained)
- Extension parameter type changed from `[string]` to `[string[]]` for proper multi-extension support
- Editor resolution uses 5-step cascade: explicit path, stored config, env var, auto-detect, dialog
- Cross-platform path handling throughout (Join-Path, Resolve-Path, Split-Path)
- All Join-Path calls use 2-argument chaining for PS 5.1 compatibility
- Module manifest updated with CompatiblePSEditions, comprehensive tags, and PSGallery metadata

### Fixed
- Extension parameter now accepts all input forms without errors (`-e php,txt`, `-e .php,.txt`, `-e php -e txt`)
- No more argument transformation errors with multiple extensions

## [2.0.0] - 2026-02-25

### Added
- Cross-platform Notepad++ auto-detection
- Cross-platform path handling (no hard-coded backslashes)
- New `--first N` and `--last N` parameters for file subset selection
- 56-test comprehensive test suite
- PSGallery-ready module manifest

### Fixed
- `-ext` parameter handling for comma-separated strings
- File creation hanging at confirm prompt
- `-d` switch consuming next string argument
- `?` wildcard not matching
- Non-ASCII characters breaking PS 5.1 parsing
- `Join-Path` with 3+ arguments failing on PS 5.1
- `-ext PHP` single-extension case failing
- `$resolvedFiles` containing `$null` entries
- Confirm prompt crashing on empty Enter

## [1.0.0] - 2026-02-25

### Added
- Initial release
- File opening and automatic creation
- Wildcard expansion (`*`, `?`, `[a-z]`, `[abc]`)
- Directory scanning with `-d` flag
- Recursive scanning with `-r` flag
- Extension filtering
- Hidden file support with `-a` flag
- Interactive confirmation prompts for large file sets
- Hard limit to prevent mass-open
