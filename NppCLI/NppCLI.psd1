@{
    # Script module file associated with this manifest
    RootModule        = 'NppCLI.psm1'

    # Version number of this module
    ModuleVersion     = '1.0.0'

    # Unique ID for this module (generate a new GUID for production)
    GUID              = 'a3f1e8b2-7c4d-4e9a-b5f6-1a2b3c4d5e6f'

    # Author of this module
    Author            = 'Davood Yahay (Davoodsec)'

    # Company or vendor of this module
    CompanyName       = 'DavoodSec'

    # Copyright statement for this module
    Copyright         = '(c) 2026 Davood Yahay. MIT License.'

    # Description of the functionality provided by this module
    Description       = 'NppCLI - A powerful PowerShell CLI to open files and directories in Notepad++. Supports file creation, wildcard expansion, directory scanning, recursive discovery, extension filtering, hidden files, interactive confirmation, and file limits.'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '5.1'

    # Functions to export from this module
    FunctionsToExport = @('npp')

    # Cmdlets to export from this module
    CmdletsToExport   = @()

    # Variables to export from this module
    VariablesToExport  = @()

    # Aliases to export from this module
    AliasesToExport    = @()

    # Private data to pass to the module specified in RootModule
    PrivateData = @{
        PSData = @{
            # Tags applied to this module for discoverability
            Tags       = @('Notepad++', 'NppCLI', 'Editor', 'FileManagement', 'CLI', 'Windows')

            # License URI
            LicenseUri = ''

            # Project URI
            ProjectUri = ''

            # Release notes
            ReleaseNotes = @'
v1.0.0 - Initial production release
- File opening with automatic creation for non-existent files
- Wildcard support (*, ?, [a-z], [abc])
- Directory scanning with -d flag
- Recursive scanning with -r flag
- Extension filtering with -ext
- Hidden file support with -a/--hidden
- Interactive confirmation prompt for large file sets
- Hard limit to prevent overload
- Compatible with Windows PowerShell 5.1+ and PowerShell 7+
'@
        }
    }
}
