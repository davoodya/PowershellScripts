@{
    # Script module file associated with this manifest
    RootModule        = 'NppCLI.psm1'

    # Version number of this module
    ModuleVersion     = '3.0.0'

    # Unique GUID for this module (generated for PSGallery uniqueness)
    GUID              = 'd01cb7f7-cf5a-4e7f-9271-682e6f37a768'

    # Author of this module
    Author            = 'Davood Yahya (DavoodSec)'

    # Company or vendor of this module
    CompanyName       = 'DSecurity'

    # Copyright statement for this module
    Copyright         = '(c) 2025-2026 Davood Yahya. MIT License.'

    # Description of the functionality provided by this module
    Description       = 'NppCLI - A powerful cross-platform PowerShell CLI to open files and directories in any editor (Notepad++, VSCode, Sublime, nano, etc.). Supports file creation, wildcard expansion, directory scanning, recursive discovery, extension filtering (-e php,txt), hidden files, first/last selection, interactive confirmation, file limits, persistent editor config, and file dialog for editor selection. Compatible with PowerShell 5.1+ and 7+.'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '5.1'

    # Compatible PowerShell editions
    CompatiblePSEditions = @('Desktop', 'Core')

    # Functions to export from this module - only export the npp function
    FunctionsToExport = @('npp')

    # Cmdlets to export from this module (none)
    CmdletsToExport   = @()

    # Variables to export from this module (none)
    VariablesToExport  = @()

    # Aliases to export from this module (none)
    AliasesToExport    = @()

    # HelpInfo URI for online help
    # HelpInfoURI = ''

    # Private data to pass to the module specified in RootModule
    PrivateData = @{
        PSData = @{
            # Tags applied to this module for PowerShell Gallery discoverability
            Tags         = @(
                'NppCLI', 'npp', 'Editor', 'Notepad++', 'VSCode', 'Sublime',
                'FileManagement', 'CLI', 'Windows', 'Linux', 'macOS',
                'CrossPlatform', 'Wildcard', 'DirectoryScanner', 'FileOpener',
                'Automation', 'PowerShell', 'Productivity', 'DevTools'
            )

            # License URI (MIT on GitHub)
            LicenseUri   = 'https://github.com/davoodya/NppCLI/blob/main/LICENSE'

            # Project URI (GitHub repository)
            ProjectUri   = 'https://github.com/davoodya/NppCLI'

            # Icon URI (optional - uncomment and set if you have one)
            # IconUri    = ''

            # Release notes for this version
            ReleaseNotes = @'
v3.0.0 - Major Architecture Refactor
- GENERALIZED EDITOR SUPPORT: No longer hardcoded to Notepad++.
  Supports ANY editor: Notepad++, VSCode, Sublime, nano, vim, etc.
- PERSISTENT CONFIG: Editor path stored in $HOME/.nppcli/config.json.
  Set once, remembered forever. No need for environment variables.
- EDITOR SELECTION: First-run file dialog (Windows) or console prompt
  (Linux/macOS). Use -x / --exe to select or change editor at any time.
- BUILT-IN HELP SYSTEM: -h / --help (full), --help-summary (cheatsheet),
  --examples (usage examples). Three-layer professional CLI help output.
- FIXED EXTENSION PARAMETER: Renamed to -e / --extension.
  Now accepts string arrays: -e php,txt / -e .php,.txt / -e php -e txt.
- SHORT + LONG FLAGS: All parameters support short and long forms.
- MODULAR ARCHITECTURE: Separated into Private/ modules:
  Config.ps1, EditorResolver.ps1, FileResolver.ps1, HelpSystem.ps1
- CROSS-PLATFORM: Join-Path, Resolve-Path, Split-Path throughout.
  No hardcoded path separators. Works on Windows, Linux, macOS.
- 128-test automated suite passing on both PS 5.1 and PS 7+.
- All previous features preserved: wildcards, directory mode, recursive,
  hidden files, first/last, limit, confirm threshold, file creation.
'@

            # Prerelease string (uncomment for pre-release versions)
            # Prerelease = ''

            # Require license acceptance (set to true if needed)
            # RequireLicenseAcceptance = $false

            # External module dependencies (none)
            # ExternalModuleDependencies = @()
        }
    }
}
