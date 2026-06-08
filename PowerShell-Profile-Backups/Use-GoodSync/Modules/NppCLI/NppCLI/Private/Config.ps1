# ========================================================================
# NppCLI - Configuration Management (Private)
# Handles persistent storage of editor executable path and settings.
# Config stored in: $HOME/.nppcli/config.json
# ========================================================================

function Get-NppCLIConfigDir {
    <#
    .SYNOPSIS
        Returns the config directory path for NppCLI.
    #>
    [CmdletBinding()]
    param()

    $configDir = Join-Path $HOME '.nppcli'
    return $configDir
}

function Get-NppCLIConfigPath {
    <#
    .SYNOPSIS
        Returns the full path to config.json.
    #>
    [CmdletBinding()]
    param()

    $configDir = Get-NppCLIConfigDir
    $configFile = Join-Path $configDir 'config.json'
    return $configFile
}

function Get-NppCLIConfig {
    <#
    .SYNOPSIS
        Reads the NppCLI config from disk. Returns a hashtable.
        Returns empty hashtable if config does not exist.
    #>
    [CmdletBinding()]
    param()

    $configPath = Get-NppCLIConfigPath

    if (Test-Path $configPath) {
        try {
            $raw = Get-Content -Path $configPath -Raw -ErrorAction Stop
            if ([string]::IsNullOrWhiteSpace($raw)) {
                return @{}
            }
            $obj = $raw | ConvertFrom-Json -ErrorAction Stop

            # Convert PSCustomObject to hashtable for PS 5.1 compat
            $config = @{}
            foreach ($prop in $obj.PSObject.Properties) {
                $config[$prop.Name] = $prop.Value
            }
            return $config
        }
        catch {
            Write-Warning "Failed to read NppCLI config: $($_.Exception.Message)"
            return @{}
        }
    }
    else {
        return @{}
    }
}

function Save-NppCLIConfig {
    <#
    .SYNOPSIS
        Saves the NppCLI config hashtable to disk as JSON.
    .PARAMETER Config
        A hashtable of config key-value pairs.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Config
    )

    $configDir = Get-NppCLIConfigDir
    $configPath = Get-NppCLIConfigPath

    try {
        if (-not (Test-Path $configDir)) {
            New-Item -ItemType Directory -Path $configDir -Force | Out-Null
            Write-Verbose "Created config directory: $configDir"
        }

        $json = $Config | ConvertTo-Json -Depth 4
        Set-Content -Path $configPath -Value $json -Encoding UTF8 -Force
        Write-Verbose "Config saved to: $configPath"
    }
    catch {
        Write-Warning "Failed to save NppCLI config: $($_.Exception.Message)"
    }
}

function Get-NppCLIEditorPath {
    <#
    .SYNOPSIS
        Retrieves the stored editor executable path from config.
        Returns $null if not set.
    #>
    [CmdletBinding()]
    param()

    $config = Get-NppCLIConfig
    $editorPath = $null

    if ($config.ContainsKey('EditorPath') -and $config['EditorPath']) {
        $editorPath = $config['EditorPath']
        if (Test-Path $editorPath) {
            return $editorPath
        }
        else {
            Write-Verbose "Stored editor path no longer valid: $editorPath"
            return $null
        }
    }

    return $null
}

function Set-NppCLIEditorPath {
    <#
    .SYNOPSIS
        Saves the editor executable path to config.
    .PARAMETER Path
        The full path to the editor executable.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $config = Get-NppCLIConfig
    $config['EditorPath'] = $Path
    Save-NppCLIConfig -Config $config
    Write-Verbose "Editor path saved: $Path"
}
