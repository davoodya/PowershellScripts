# ========================================================================
# NppCLI - Editor Resolver (Private)
# Handles finding, selecting, and validating editor executables.
# Supports: Notepad++, VSCode, Sublime, nano, vim, any custom editor.
# Cross-platform: Windows dialog, Linux/macOS Read-Host fallback.
# ========================================================================

function Show-EditorFileDialog {
    <#
    .SYNOPSIS
        Shows a file open dialog (Windows) or Read-Host prompt (Linux/macOS)
        to let the user select an editor executable.
    .OUTPUTS
        The selected file path as a string, or $null if cancelled.
    #>
    [CmdletBinding()]
    param()

    $isWindows = $true
    if ($PSVersionTable.PSVersion.Major -ge 6) {
        # PowerShell 6+ has $IsWindows automatic variable
        $isWindows = $IsWindows
    }
    else {
        # PowerShell 5.1 is always Windows
        $isWindows = $true
    }

    if ($isWindows) {
        try {
            Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
            $dialog = New-Object System.Windows.Forms.OpenFileDialog
            $dialog.Title = "Select Editor Executable"
            $dialog.Filter = "Executable files (*.exe)|*.exe|All files (*.*)|*.*"
            $dialog.InitialDirectory = $env:ProgramFiles
            $dialog.Multiselect = $false

            $result = $dialog.ShowDialog()

            if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
                $selected = $dialog.FileName
                Write-Verbose "User selected editor: $selected"
                return $selected
            }
            else {
                Write-Verbose "User cancelled editor selection dialog."
                return $null
            }
        }
        catch {
            # Fallback to Read-Host if dialog fails (e.g., headless environment)
            Write-Verbose "Windows Forms dialog unavailable. Falling back to console input."
            return Read-EditorPathFromConsole
        }
    }
    else {
        # Linux / macOS - no native dialog, use console prompt
        return Read-EditorPathFromConsole
    }
}

function Read-EditorPathFromConsole {
    <#
    .SYNOPSIS
        Prompts the user to type the full path to an editor executable.
    .OUTPUTS
        The typed path as a string, or $null if empty/cancelled.
    #>
    [CmdletBinding()]
    param()

    Write-Host ""
    Write-Host "Enter the full path to your editor executable:" -ForegroundColor Cyan
    Write-Host "  Examples:" -ForegroundColor Gray
    Write-Host "    C:\Program Files\Notepad++\notepad++.exe" -ForegroundColor Gray
    Write-Host "    /usr/bin/code" -ForegroundColor Gray
    Write-Host "    /usr/bin/nano" -ForegroundColor Gray
    Write-Host ""

    $input_path = Read-Host "Editor path"

    if ([string]::IsNullOrWhiteSpace($input_path)) {
        Write-Verbose "User provided no editor path."
        return $null
    }

    # Remove surrounding quotes if user added them
    $input_path = $input_path.Trim().Trim('"').Trim("'")

    return $input_path
}

function Find-NotepadPlusPlus {
    <#
    .SYNOPSIS
        Auto-detects Notepad++ executable on Windows.
        Checks common install locations and PATH.
    .OUTPUTS
        Full path to notepad++.exe or $null if not found.
    #>
    [CmdletBinding()]
    param()

    # 1. Check $env:NPP_PATH override
    if ($env:NPP_PATH -and (Test-Path $env:NPP_PATH)) {
        Write-Verbose "Found Notepad++ via NPP_PATH: $env:NPP_PATH"
        return $env:NPP_PATH
    }

    # 2. Check common Windows install locations
    $candidates = @()

    if ($env:ProgramFiles) {
        $candidates += Join-Path (Join-Path $env:ProgramFiles 'Notepad++') 'notepad++.exe'
    }
    if (${env:ProgramFiles(x86)}) {
        $candidates += Join-Path (Join-Path ${env:ProgramFiles(x86)} 'Notepad++') 'notepad++.exe'
    }
    if ($env:LOCALAPPDATA) {
        $candidates += Join-Path (Join-Path $env:LOCALAPPDATA 'Notepad++') 'notepad++.exe'
    }
    if ($env:SCOOP) {
        $candidates += Join-Path (Join-Path (Join-Path (Join-Path $env:SCOOP 'apps') 'notepadplusplus') 'current') 'notepad++.exe'
    }

    foreach ($c in $candidates) {
        if ($c -and (Test-Path $c)) {
            Write-Verbose "Found Notepad++ at: $c"
            return $c
        }
    }

    # 3. Try PATH search
    $searchNames = @('notepad++', 'notepad++.exe')
    foreach ($name in $searchNames) {
        $found = Get-Command $name -ErrorAction SilentlyContinue |
                 Select-Object -First 1 -ExpandProperty Source
        if ($found) {
            Write-Verbose "Found Notepad++ on PATH: $found"
            return $found
        }
    }

    return $null
}

function Find-CommonEditor {
    <#
    .SYNOPSIS
        Attempts to find any well-known editor on the system.
        Returns the first one found, or $null.
    #>
    [CmdletBinding()]
    param()

    # Try Notepad++ first (backward compatibility)
    $npp = Find-NotepadPlusPlus
    if ($npp) { return $npp }

    # Try other common editors on PATH
    $editorNames = @('code', 'subl', 'sublime_text', 'atom', 'nano', 'vim', 'vi', 'notepad')
    foreach ($name in $editorNames) {
        $found = Get-Command $name -ErrorAction SilentlyContinue |
                 Select-Object -First 1 -ExpandProperty Source
        if ($found) {
            Write-Verbose "Found editor on PATH: $found ($name)"
            return $found
        }
    }

    return $null
}

function Resolve-EditorExecutable {
    <#
    .SYNOPSIS
        Master resolution function for the editor executable.
        Resolution order:
          1. -exe parameter value (if provided as a path string)
          2. Stored config path ($HOME/.nppcli/config.json)
          3. $env:NPP_PATH (legacy support)
          4. Auto-detection (Notepad++, then common editors)
          5. File dialog / console prompt (first-run experience)
    .PARAMETER ExePath
        Optional explicit path passed via -exe / --exe parameter.
        If $null or empty, skips step 1.
    .PARAMETER ShowDialog
        If $true, force showing the file dialog even if a stored path exists.
    .OUTPUTS
        Full path to the editor executable, or $null if resolution fails.
    #>
    [CmdletBinding()]
    param(
        [AllowNull()]
        [AllowEmptyString()]
        [string]$ExePath,

        [switch]$ShowDialog
    )

    # Step 1: Explicit -exe path provided
    if ($ExePath -and $ExePath.Length -gt 0) {
        # Remove surrounding quotes
        $ExePath = $ExePath.Trim().Trim('"').Trim("'")

        if (Test-Path $ExePath) {
            Write-Verbose "Using explicitly provided editor: $ExePath"
            Set-NppCLIEditorPath -Path $ExePath
            return $ExePath
        }
        else {
            Write-Warning "Specified editor path does not exist: $ExePath"
            return $null
        }
    }

    # Step 1b: -exe switch with no path -> show dialog
    if ($ShowDialog) {
        $selected = Show-EditorFileDialog
        if ($selected -and (Test-Path $selected)) {
            Set-NppCLIEditorPath -Path $selected
            Write-Host "Editor saved: $selected" -ForegroundColor Green
            return $selected
        }
        elseif ($selected) {
            Write-Warning "Selected path does not exist: $selected"
            return $null
        }
        else {
            Write-Warning "No editor selected. Operation cancelled."
            return $null
        }
    }

    # Step 2: Check stored config
    $stored = Get-NppCLIEditorPath
    if ($stored) {
        Write-Verbose "Using stored editor path: $stored"
        return $stored
    }

    # Step 3: Check legacy $env:NPP_PATH
    if ($env:NPP_PATH -and (Test-Path $env:NPP_PATH)) {
        Write-Verbose "Using NPP_PATH env var: $env:NPP_PATH"
        # Save it to config for future use
        Set-NppCLIEditorPath -Path $env:NPP_PATH
        return $env:NPP_PATH
    }

    # Step 4: Auto-detection
    $autoDetected = Find-CommonEditor
    if ($autoDetected) {
        Write-Verbose "Auto-detected editor: $autoDetected"
        # Save it to config for future use
        Set-NppCLIEditorPath -Path $autoDetected
        return $autoDetected
    }

    # Step 5: First-run experience - show dialog
    Write-Host ""
    Write-Host "No editor executable found." -ForegroundColor Yellow
    Write-Host "Please select your preferred editor." -ForegroundColor Yellow
    Write-Host ""

    $selected = Show-EditorFileDialog
    if ($selected -and (Test-Path $selected)) {
        Set-NppCLIEditorPath -Path $selected
        Write-Host "Editor saved: $selected" -ForegroundColor Green
        return $selected
    }
    elseif ($selected) {
        Write-Warning "Selected path does not exist: $selected"
        return $null
    }
    else {
        Write-Warning "No editor selected. Cannot proceed."
        return $null
    }
}
