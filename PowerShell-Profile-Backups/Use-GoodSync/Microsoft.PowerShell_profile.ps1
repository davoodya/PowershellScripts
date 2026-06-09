# ========== PATH Adder Syntax ==========

<# if want to add variable to PATH Environment Variable using PowerShell Profile ####

$env:PATH += ";E:\Tools\Nmap"
$env:PATH += ";E:\Tools\Rust"
$env:PATH += ";E:\Tools\Custom"

#Other Env Variable:
#$env:ENVNAME = "ENVVALUE"
#>

<#
    OPTIMIZED POWERSHELL PROFILE CUSTOMIZED FOR Yakuza Style
    Maintains all features while reducing startup time
    Key optimizations:
    - Lazy loading of heavy modules
    - Removal of unused/commented code
    - Efficient module loading
#>
# ========== Module Importings ==========

## ===== Module 1 PSReadLine ===== ##
# PSReadLine configuration (lightweight settings)
Set-PSReadLineOption -HistorySearchCursorMovesToEnd -EditMode Emacs
Set-PSReadLineKeyHandler -Chord 'Tab' -Function Complete
Set-PSReadLineOption -ShowToolTips -HistoryNoDuplicates -MaximumHistoryCount 1000
Set-PSReadLineOption -PredictionSource HistoryAndPlugin -PredictionViewStyle ListView

# Color settings (minimal performance impact)
Set-PSReadLineOption -Colors @{
    "Command"   = "#8181f7"
    "Number"    = "White"
    "Keyword"   = "Green"
    "String"    = "Cyan"
    "Operator"  = "Gray"
    "Variable"  = "Blue"
    "Parameter" = "Yellow"
}


if ($null -eq (Get-Module -Name PSReadLine)) {
    Import-Module PSReadLine -ErrorAction SilentlyContinue
}

## ===== Module 2 Chocolatey =====
if ($env:ChocolateyInstall -and (Test-Path "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1")) {
    Import-Module "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1" -ErrorAction SilentlyContinue
}

# ========== LAZY-LOADED MODULES ==========
<#
    Heavy modules are loaded only when needed:
    - posh-git loads when in a git repo or when explicitly called
    - TabExpansion loads when tab completion is used
#>

# ## ===== Module 2 posh-git =====
function Import-PoshGit {
    if ($null -eq (Get-Module -Name posh-git)) {
        Import-Module posh-git -ErrorAction SilentlyContinue
    }
}

# Automatic posh-git loading when in git repository
$GitPromptSettings = @{DefaultPromptEnableTiming = $false}
function Global:Prompt() {
    if ((Get-Command git -ErrorAction SilentlyContinue) -and 
        (Test-Path .git) -or (git rev-parse --git-dir 2>$null)) {
        Import-PoshGit
    }
    "PS $($executionContext.SessionState.Path.CurrentLocation)$('>' * ($nestedPromptLevel + 1)) "
}

## ===== Module 3 TabExpansion =====
function Import-TabExpansion {
    if ($null -eq (Get-Module -Name TabExpansionPlusPlus)) {
        Import-Module TabExpansionPlusPlus -ErrorAction SilentlyContinue
    }
}


## ===== Module 4 gsudoModule =====
Import-Module gsudoModule

## ===== Module 5 PowerToys CommandNotFound module =====
#f45873b3-b655-43a6-b217-97c00aa0db58 PowerToys CommandNotFound module

Import-Module -Name Microsoft.WinGet.CommandNotFound
#f45873b3-b655-43a6-b217-97c00aa0db58


## ===== Module 6 oh-my-posh =====

# ===== OH MY POSH v3 SETUP (FAST LOAD) =====
# Use the compiled binary instead of PowerShell module

# Old Way to configure oh-my-posh (Not Use yet)
#Import-Module oh-my-posh
#Set-PoshPrompt -Theme blue-owl

## ===== oh-my-posh Configuration =====

# Optional: Use the universal shell for even better performance | Only work on new versions
oh-my-posh init pwsh | Invoke-Expression
oh-my-posh init pwsh --config "C:\Users\DavoodYa\AppData\Local\oh-my-posh\themes\kali.omp.json" | Invoke-Expression
# Suggested Themes: amro - blue-owl - blueish - cert - json - slim slimfat
#oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\blue-owl.omp.json"| Invoke-Expression

#Starship Import But dont used
#Invoke-Expression (&starship init powershell)

# ========== ENVIRONMENT VARIABLES ==========
## --- PATH Environment Variable --- ##
$env:PATH += ";C:\Apps\HackingSec\Windows-Sysinternals-Suite\"

## --- Other Environment Variables --- ##
#$env:ENVNAME = "ENVVALUE"


# ========== CUSTOM VARIABLES ==========

# Define Custom Variables
$dayaWebsite = "H:\Repo\DavoodYa` Website\DavoodYa` Customized"
$python27 = "C:\Program Files\Python27\python.exe"
$rflare = "https://mirror-pypi.runflare.com/simple"
$rflare_py = "-i https://mirror-pypi.runflare.com/simple"
$rflare_npm = "https://mirror-npm.runflare.com"
$rflare_flag = '--registry="https://mirror-npm.runflare.com"'


# ========== CUSTOM Alias AS Functions ==========

function repo { cd H:\Repo\ }
function davoodsec { cd H:\@DavoodSec\ }
function dayaWebsite { cd $dayaWebsite }
function np { npp $args }
function exp { explorer $args }
function nekoproxy { $env:HTTP_PROXY="http://127.0.0.1:2081"; $env:HTTPS_PROXY="http://127.0.0.1:2081";}
function nekoproxy2080 { $env:HTTP_PROXY="http://127.0.0.1:2080"; $env:HTTPS_PROXY="http://127.0.0.1:2080";}
function nekosocksproxy { $env:ALL_PROXY="socks5://127.0.0.1:2080"; $args }
function sniproxy { $env:ALL_PROXY="socks5://127.0.0.1:10808"; $args }
function v2proxy { $env:HTTP_PROXY="http://127.0.0.1:10808"; $env:HTTPS_PROXY="http://127.0.0.1:10808"; $args }
function pipupdater { pip list --outdated --format=json | ConvertFrom-Json | % { pip install -U $_.name } }
function ytdl { py H:\Repo\Yakuza-Malware-Arsenal\YtDl.py }
function gcl { git clone $args }
function ghc { gh repo clone $args }
function ghs { gh search repos $args }
function ghsn { gh search repos --match name $args }
function ghsc { gh search code $args }
# Usage: ghsl <search-term> <language>
function ghsl { gh search repos $args[0] --language $args[1] $args}

function path-link {
	# args[0] = "C:\Apps\EXE-Scripts\file.exe"
	# args [1] = path of exe files should be add to path
	New-Item -ItemType SymbolicLink -Path $args[0] -Target $args[1]

}

# ========== CUSTOM Functions ==========
function pipmirror {
	python -m pip install -i https://mirror-pypi.runflare.com/simple $args
}
function burpsuite {
	Write-Host "Run Command:" -ForegroundColor Green
	Write-Host "java -jar C:\Apps\HackingSec\BurpsuitePro2026\BurpLoaderKeygen117.jar" -ForegroundColor Green
	java -jar C:\Apps\HackingSec\BurpsuitePro2026\BurpLoaderKeygen117.jar
}
function pwsh-empire-server {
    docker run -it --rm -p 1337:1337 -p 5000:5000 --name pwsh_empiree_server --volumes-from data bcsecurity/empire:latest 
}

function pwsh-empire-client {
    docker run -it --rm -p 1338:1338 -p 5001:5001 --name pwsh_empiree_client --volumes-from data bcsecurity/empire:latest client 
}

function kaliDocker {
    docker run -it --rm -v kali-storage:/data --name kaliDocker kalilinux/kali-rolling /bin/bash
}

function n8nDocker {
    docker run -it --rm --name n8n -p 5678:5678 --name n8nDocker -v n8n_data:/home/node/.n8n docker.n8n.io/n8nio/n8n
}

function metasploitDocker {
    docker run -it --rm --name metasploit -p 4444:4444 -v msf-db:/var/lib/postgresql parrotsec/metasploit
}

function vapeclub-img {
    cd H:\Repo\ImageConverter
    python .\image-cv.py
}

function webp-conv {
    cd H:\Repo\ImageConverter
    python .\convert-seo-optimize.py
}

function wsl-run {
    <#
    .SYNOPSIS:
        Launch WSL Ubuntu versions based on input argument

    .PARAMETER: <Version>
        - 24  →  Ubuntu‑24.04
        - 25  →  Ubuntu‑25.04.EXAMPLE

    .EXAMPLE:
		wsl-ubuntu 24   # اجرای wsl.exe -d Ubuntu-24.04
        wsl-ubuntu 25   # اجرای wsl.exe -d Ubuntu-25.04
	
	.NOTIC:
		"wsl --distribution-id 2bf261fa-7c15-4de7-a527-08130008f039" == "wsl.exe -d Ubuntu-24.04"
		"wsl.exe --distribution-id 4b05076a-90d7-4435-8173-fb8fc7e28065" == "wsl.exe -d Ubuntu-25.10"
    #>

    param(
        [Parameter(Mandatory = $true,
                   Position = 0,
                   ValueFromPipeline = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [ValidateSet("24","25","26","fed")]
        [string]$Version
    )

    switch ($Version) {
        "24" { 
			Write-Host "Running WSL Ubuntu 24.04" -ForegroundColor Yellow
			Write-Host "wsl -d Ubuntu-24.04" -ForegroundColor Cyan
			Write-Host "wsl.exe --distribution-id 2bf261fa-7c15-4de7-a527-08130008f039" -ForegroundColor Cyan
			wsl.exe -d Ubuntu-24.04 }
        "25" { 
			Write-Host "Running WSL Ubuntu 25.10" -ForegroundColor Yellow
			Write-Host "wsl -d Ubuntu-25.10" -ForegroundColor Cyan
			Write-Host "wsl.exe --distribution-id 4b05076a-90d7-4435-8173-fb8fc7e28065" -ForegroundColor Cyan
			wsl.exe -d Ubuntu-25.10 }
		"26" { 
			Write-Host "Running WSL Ubuntu 26.04" -ForegroundColor Yellow
			Write-Host "wsl -d Ubuntu-26.04" -ForegroundColor Cyan
			Write-Host "wsl.exe --distribution-id 48c80e09-8bb7-494b-b963-6eb9770f6b6d" -ForegroundColor Cyan
			wsl.exe -d Ubuntu-26.04 }
		"fed" { 
			Write-Host "Running WSL FedoraLinux 44" -ForegroundColor Yellow
			Write-Host "wsl -d FedoraLinux-44" -ForegroundColor Cyan
			Write-Host "wsl.exe --distribution-id 49a6da12-2f87-42fc-ba69-6060b167c761" -ForegroundColor Cyan
			wsl.exe -d FedoraLinux-44 }
		
    }
}

# ========== GitHub Search Functions ==========
function ghs-json {
	gh search repos $args[0] --limit 100 --json name,url,description,stargazersCount --jq '.[] | select(.stargazersCount > 1000)'
}
function ghsl-json {
	gh search repos $args[0] --language $args[1] --limit 100 --json name,url,description,stargazersCount --jq '.[] | select(.stargazersCount > $args[2])'
}
function ghrl-json {
	gh repo list $args[0] --limit 100 --json name,url,stargazerCount --jq '.[] | select(.stargazerCount > $args[1])'
}

function ghv {
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$InputRepo
    )

    # if argument have URL, extract owner/repo from it
    if ($InputRepo -match '^https?://github\.com/([^/]+/[^/]+?)(?:\.git)?/?$') {
        $Repo = $matches[1]
    }
    else {
        $Repo = $InputRepo
    }

    # remove end slash - if exist
    $Repo = $Repo.TrimEnd('/')

    # Convert owner/repo to owner-repo to use as File Name for saving
    $SafeName = $Repo -replace '/', '-'

    # markdown output file
    $OutputFile = "$SafeName.md"

    # get repo information and save it to markdown file
    gh repo view $Repo > $OutputFile

    # Check gh running is done or not!
    if ($LASTEXITCODE -eq 0 -and (Test-Path $OutputFile)) {
        Start-Process $OutputFile
    }
    else {
        Write-Error "Failed to fetch repository view for: $Repo"
    }
}

# ========== Winget Functions ==========
function wgs { winget search -q $args }
function wgi {
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Package,

        [Parameter(Position = 1)]
        [string]$Source = "winget"
    )

    winget download `
        --source $Source `
        --id $Package `
}
function wgd {
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Package,

        [Parameter(Position = 1)]
        [string]$DownloadPath = "E:\Softwares\00_Windows\winget",

        [Parameter(Position = 2)]
        [string]$Source = "winget"
    )

    winget download `
        --source $Source `
        --id $Package `
        -d $DownloadPath
}

# ========== PATH Adder Function ==========
#### path-add => Create SymbolicLink in "C:\Apps\EXE-Scripts" which is PATH ####
function path-add {
	<# 
		Usage Guide: path-add "C:\Path\to\file.exe"
		
		then function create a symbolic link in C:\Apps\EXE-Scripts\file.exe 
		
		"C:\Apps\EXE-Scripts" in the PATH 
	#>
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$TargetPath
    )
	
	# Help Menu
    if (
        $TargetPath -eq "-h" -or
        $TargetPath -eq "--help" -or
        $TargetPath -eq "help" -or
        [string]::IsNullOrWhiteSpace($TargetPath)
    ) {

        Write-Host ""
        Write-Host '"path-add" Create SymbolicLink in "C:\Apps\EXE-Scripts"' 
		Write-Host '  "C:\Apps\EXE-Scripts" in the PATH Environment Variable'
        Write-Host ""
        Write-Host "Usage:" -ForegroundColor Green
        Write-Host "  path-add `"C:\Path\to\file.exe`"" -ForegroundColor DarkYellow
		Write-Host ""
        Write-Host '  this command create "C:\Apps\EXE-Scripts\file.exe"'
		Write-Host '  so we can run "file.exe" directly from terminal'
        Write-Host ""

        return
    }

    # Check file exist or not
    if (-not (Test-Path $TargetPath)) {
        Write-Error "Target file not found: $TargetPath"
        return
    }

    # Extract file name
    $FileName = Split-Path $TargetPath -Leaf

    # symlink Directory Path
    $LinkDirectory = "C:\Apps\EXE-Scripts"

    # Create symlink Directory if not exist
    if (-not (Test-Path $LinkDirectory)) {
        New-Item -ItemType Directory -Path $LinkDirectory | Out-Null
    }

    # Final Path of symbolic link
    $LinkPath = Join-Path $LinkDirectory $FileName

    # Check link exist or not
    if (Test-Path $LinkPath) {
        Write-Warning "Link already exists: $LinkPath"
        return
    }

    # Create new symbolic link with Original file name
    New-Item `
        -ItemType SymbolicLink `
        -Path $LinkPath `
        -Target $TargetPath | Out-Null

    Write-Host " "
	Write-Host "[+] Symbolic link created:" -ForegroundColor Yellow
    Write-Host "    $LinkPath -> $TargetPath" -ForegroundColor Green
	Write-Host " "
	Write-Host "[+] Command Run" -ForegroundColor Yellow
	Write-Host "    New-Item -ItemType SymbolicLink -Path $LinkPath -Target $TargetPath" -ForegroundColor Green
}

function path-profile-help {
	Write-Host "if want to add variable to PATH Environment Variable using PowerShell Profile," -ForegroundColor Yellow
	Write-Host 'add below lines to end of $PROFILE' -ForegroundColor Yellow
	Write-Host
	Write-Host '$env:PATH += ";E:\Tools\Nmap"' -ForegroundColor Green
	Write-Host '$env:PATH += ";E:\Tools\Rust"' -ForegroundColor Green
	Write-Host '$env:PATH += ";E:\Tools\Custom"' -ForegroundColor Green

}

#### path-padd => Add directory path to end of PowerShell Profile $PROFILE ####
function path-padd {

<#
.SYNOPSIS
    Add a directory path to PowerShell PROFILE PATH loader.

.DESCRIPTION
    This function appends a new PATH loader line to the end of the current
    PowerShell $PROFILE file.

    Instead of modifying permanent Windows Environment Variables,
    this function injects PATH entries dynamically whenever PowerShell starts.

    Added line format:
        $env:PATH += ";<PATH>"

.PARAMETER Path
    Directory path to append to PATH inside $PROFILE.

.EXAMPLE
    path-padd "E:\Tools\Nmap"

.EXAMPLE
    path-padd "E:\Apps\Go\bin"

.EXAMPLE
    path-padd help

.EXAMPLE
    path-padd -h

.EXAMPLE
    path-padd --help
#>

    param(
        [Parameter(Position = 0)]
        [string]$PathArg
    )

    # Help Menu
    if (
        $PathArg -eq "-h" -or
        $PathArg -eq "--help" -or
        $PathArg -eq "help" -or
        [string]::IsNullOrWhiteSpace($PathArg)
    ) {

        Write-Host ""
        Write-Host "path-padd - Add directory to PowerShell PROFILE PATH loader"
        Write-Host ""
        Write-Host "Usage:"
        Write-Host "  path-padd `"E:\Tools\Nmap`""
        Write-Host ""
        Write-Host "This appends the following line to your PowerShell PROFILE:"
        Write-Host '  $env:PATH += ";E:\Tools\Nmap"'
        Write-Host ""
        Write-Host "Profile File:"
        Write-Host "  $PROFILE"
        Write-Host ""

        return
    }

    # Create PowerShell PROFILE if not exist
    if (-not (Test-Path $PROFILE)) {

        $ProfileDir = Split-Path $PROFILE -Parent

        if (-not (Test-Path $ProfileDir)) {
            New-Item -ItemType Directory -Path $ProfileDir -Force | Out-Null
        }

        New-Item -ItemType File -Path $PROFILE -Force | Out-Null
    }

    # line should be add
    $PathLine = "`$env:PATH += `";$PathArg`""

    # Duplicate entries don't be add
    $ProfileContent = Get-Content $PROFILE -Raw

    if ($ProfileContent -match [regex]::Escape($PathLine)) {

        Write-Warning "Path already exists in PROFILE:"
        Write-Host "  $PathArg"

        return
    }

    # Add to end of PowerShell PROFILE
    Add-Content -Path $PROFILE -Value ""
    Add-Content -Path $PROFILE -Value $PathLine

    Write-Host ""
    Write-Host "[+] PATH loader added to PROFILE:"
    Write-Host "    $PathLine"
    Write-Host ""
    Write-Host "PROFILE:"
    Write-Host "    $PROFILE"
    Write-Host ""
    Write-Host "Reload PowerShell or run:"
    Write-Host "    . `$PROFILE"
    Write-Host ""
}

# ==============================================================================
# PowerShell Proxy Manager Help Guide
# ------------------------------------------------------------------------------
# 1. Enable proxy ONLY for the current terminal session:
#    setproxy 2081
# 2. Enable proxy for current terminal + Global Git Config:
#    setproxy 2081 -g   OR   setproxy 2081 --git
# 3. Check current proxy configurations and status:
#    setproxy -s        OR   setproxy --status
# 4. Display this help menu:
#    setproxy -h        OR   setproxy --help
# 5. Disable/Remove proxy from current terminal ONLY:
#    unsetproxy
# 6. Disable/Remove proxy from terminal + Global Git Config:
#    unsetproxy -g      OR   unsetproxy --git
# ==============================================================================

function setproxy {
    param(
        [Parameter(Mandatory=$false, Position=0)]
        $Argument,
        
        [Parameter(Mandatory=$false)]
        [Alias("g")]
        [switch]$git,

        [Parameter(Mandatory=$false)]
        [Alias("s")]
        [switch]$status
    )

    # Check if the user is requesting Status
    if ($Argument -eq "-s" -or $Argument -eq "--status" -or $Argument -eq "status" -or $Argument -eq "s" -or $status) {
        Write-Host "`n==========================================" -ForegroundColor Magenta
        Write-Host " CURRENT PROXY STATUS" -ForegroundColor Magenta
        Write-Host "==========================================" -ForegroundColor Magenta
        
        # Check Terminal Session Environment Variables
        Write-Host "[Terminal Session Variables]" -ForegroundColor White
        if ($env:HTTP_PROXY)  { Write-Host " -> HTTP_PROXY  : $env:HTTP_PROXY" -ForegroundColor Cyan } else { Write-Host " -> HTTP_PROXY  : NOT SET" -ForegroundColor DarkGray }
        if ($env:HTTPS_PROXY) { Write-Host " -> HTTPS_PROXY : $env:HTTPS_PROXY" -ForegroundColor Cyan } else { Write-Host " -> HTTPS_PROXY : NOT SET" -ForegroundColor DarkGray }
        if ($env:ALL_PROXY)   { Write-Host " -> ALL_PROXY   : $env:ALL_PROXY" -ForegroundColor Cyan } else { Write-Host " -> ALL_PROXY   : NOT SET" -ForegroundColor DarkGray }
        
        # Check Git Config Global Proxies
        Write-Host "`n[Git Global Configurations]" -ForegroundColor White
        $gitHttp  = git config --global http.proxy 2>$null
        $gitHttps = git config --global https.proxy 2>$null

        if ($gitHttp)  { Write-Host " -> git http.proxy  : $gitHttp" -ForegroundColor Cyan } else { Write-Host " -> git http.proxy  : NOT SET" -ForegroundColor DarkGray }
        if ($gitHttps) { Write-Host " -> git https.proxy : $gitHttps" -ForegroundColor Cyan } else { Write-Host " -> git https.proxy : NOT SET" -ForegroundColor DarkGray }
        
        Write-Host "==========================================" -ForegroundColor Magenta
        return
    }

    # Check if the user is requesting Help
    if ($Argument -eq "-h" -or $Argument -eq "--help" -or $Argument -eq "help" -or $Argument -eq "h" -or ($null -eq $Argument -and !$git)) {
        Write-Host "`n[ setproxy HELP MENU ]" -ForegroundColor Green
        Write-Host "Description: Quick utility to configure development proxies for Terminal and Git." -ForegroundColor Gray
        Write-Host "`nUsage:" -ForegroundColor White
        Write-Host "  setproxy [PORT]" -ForegroundColor Yellow
		Write-Host "      Set environment variables ONLY (HTTP, HTTPS, SOCKS5)" -ForegroundColor Cyan
		Write-Host "      setproxy 2080" -ForegroundColor DarkGray
		write-Host ""
        Write-Host "  setproxy [PORT] -g | --git" -ForegroundColor Yellow
		Write-Host "      Set terminal proxy + Global Git Config" -ForegroundColor Cyan
		Write-Host "      setproxy 2081 -g" -ForegroundColor DarkGray
		Write-Host "      setproxy 2081 --git" -ForegroundColor DarkGray
		write-Host ""
        Write-Host "  setproxy -s | --status | s" -ForegroundColor Yellow
		Write-Host "      Check current proxy status for environment and Git" -ForegroundColor Cyan
		Write-Host "      setproxy -s" -ForegroundColor DarkGray
		Write-Host "      setproxy --status" -ForegroundColor DarkGray
		Write-Host "      setproxy s" -ForegroundColor DarkGray
		write-Host ""
        Write-Host "  setproxy -h | --help | h | help" -ForegroundColor Yellow
		Write-Host "      Display this help guide" -ForegroundColor Cyan
		Write-Host "      setproxy -h" -ForegroundColor DarkGray
		write-Host ""
        Write-Host "`nCRITICAL NOTE:" -ForegroundColor Green
		Write-Host "  unsetproxy" -ForegroundColor Yellow
        Write-Host "      To disable or clear your proxies, you must run the 'unsetproxy' command." -ForegroundColor Cyan
		Write-Host "      unsetproxy -g | --git => unsetproxy for git & terminal" -ForegroundColor Cyan	
		Write-Host "      unsetproxy" -ForegroundColor DarkGray
		Write-Host "      unsetproxy -g" -ForegroundColor DarkGray
		Write-Host "      unsetproxy --git" -ForegroundColor DarkGray
		Write-Host "      unsetproxy --git" -ForegroundColor DarkGray
        return
    }

    # Validate and parse the port number
    [int]$port = 0
    if (![int]::TryParse($Argument, [ref]$port)) {
        Write-Host "ERROR: Please provide a valid port number (e.g., setproxy 2081) or valid flag." -ForegroundColor Red
        return
    }
    
    # 1. Configure Current Terminal Environment Variables
    $env:HTTP_PROXY  = "http://127.0.0.1:$port"
    $env:HTTPS_PROXY = "http://127.0.0.1:$port"
    $env:ALL_PROXY   = "socks5://127.0.0.1:$port"
    
    Write-Host "`n==========================================" -ForegroundColor Green
    Write-Host " Terminal Proxy successfully set to port: $port" -ForegroundColor Green
    Write-Host " -> HTTP/HTTPS: http://127.0.0.1:$port" -ForegroundColor Gray
    Write-Host " -> SOCKS5 (ALL_PROXY): socks5://127.0.0.1:$port" -ForegroundColor Gray

    # 2. Configure Git Proxy (Only if -g or --git switch is provided)
    if ($git) {
        git config --global http.proxy  "http://127.0.0.1:$port"
        git config --global https.proxy "http://127.0.0.1:$port"
        Write-Host " -> Git Global Config updated successfully." -ForegroundColor Cyan
    } else {
        Write-Host " -> Git Global Config was NOT altered (use -g to include Git)." -ForegroundColor DarkGray
    }
    Write-Host "==========================================" -ForegroundColor Green
}

function unsetproxy {
    param(
        [Parameter(Mandatory=$false, Position=0)]
        $Argument,

        [Parameter(Mandatory=$false)]
        [Alias("g")]
        [switch]$git
    )

    # Check if the user is requesting help
    if ($Argument -eq "-h" -or $Argument -eq "--help") {
        Write-Host "`n[ unsetproxy HELP MENU ]" -ForegroundColor Yellow
        Write-Host "Description: Clear and unset active proxy configurations." -ForegroundColor Gray
        Write-Host "`nUsage:" -ForegroundColor White
        Write-Host "  unsetproxy               -> Remove proxy from the current terminal environment" -ForegroundColor Cyan
        Write-Host "  unsetproxy -g            -> Remove proxy from terminal + Clear Global Git proxy" -ForegroundColor Cyan
        return
    }
    
    # 1. Remove Current Terminal Environment Variables
    Remove-Item Env:\HTTP_PROXY -ErrorAction SilentlyContinue
    Remove-Item Env:\HTTPS_PROXY -ErrorAction SilentlyContinue
    Remove-Item Env:\ALL_PROXY -ErrorAction SilentlyContinue
    
    Write-Host "`n==========================================" -ForegroundColor Yellow
    Write-Host " Terminal environment proxies REMOVED." -ForegroundColor Yellow
    
    # 2. Clear Git Proxy (If -g or explicitly written as flag)
    if ($git -or $Argument -eq "-g" -or $Argument -eq "--git") {
        git config --global --unset http.proxy
        git config --global --unset https.proxy
        Write-Host " Git global proxy configs REMOVED." -ForegroundColor Cyan
    } else {
        Write-Host " Git Global Config was NOT altered." -ForegroundColor DarkGray
    }
    Write-Host "==========================================" -ForegroundColor Yellow
}



# ========== PERFORMANCE Speed & NOTES ==========
# Print Time of Profile loaded on terminal

# Add at the VERY START of your profile
$profileStartTime = [System.Diagnostics.Stopwatch]::StartNew()

# Add at the VERY END of your profile
Write-Host "Profile loaded in $($profileStartTime.ElapsedMilliseconds) ms" -ForegroundColor DarkCyan

<#
    To measure profile load time:
    1. Measure-Command { pwsh -noprofile -command "exit" } # Baseline
    2. Measure-Command { pwsh -command "exit" }            # With profile
    
    For additional speed:
    - Consider oh-my-posh v3+ with --shell universal flag
    - Remove unused modules completely rather than commenting
#>


# ========== ALIAS ==========
# Set alias 'oc' to open program with the current path
Set-Alias -Name oc -Value 'C:\Program Files\OneCommander\OneCommander.exe'
# >>> intelligent-terminal shell-integration >>>
# Auto-generated by Intelligent Terminal. Do not edit between markers.
# Documents is resolved at runtime so this survives OneDrive Known

# Folder Move and is a silent no-op on machines without IT installed.
$__it_si = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'WindowsPowerShell\shell-integration_v1.ps1'
if (Test-Path -LiteralPath $__it_si) { . $__it_si }
Remove-Variable __it_si -ErrorAction SilentlyContinue
# <<< intelligent-terminal shell-integration <<<

# Import the Chocolatey Profile that contains the necessary code to enable
# tab-completions to function for `choco`.
# Be aware that if you are missing these lines from your profile, tab completion
# for `choco` will not function.
# See https://ch0.co/tab-completion for details.
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}


# =============================================================================
#
# Utility functions for zoxide.
#
# =============================================================================

# Call zoxide binary, returning the output as UTF-8.
function global:__zoxide_bin {
    $encoding = [Console]::OutputEncoding
    try {
        [Console]::OutputEncoding = [System.Text.Utf8Encoding]::new()
        $result = zoxide @args
        return $result
    } finally {
        [Console]::OutputEncoding = $encoding
    }
}

# pwd based on zoxide's format.
function global:__zoxide_pwd {
    $cwd = Get-Location
    if ($cwd.Provider.Name -eq "FileSystem") {
        $cwd.ProviderPath
    }
}

# cd + custom logic based on the value of _ZO_ECHO.
function global:__zoxide_cd($dir, $literal) {
    $dir = if ($literal) {
        Set-Location -LiteralPath $dir -Passthru -ErrorAction Stop
    } else {
        if ($dir -eq '-' -and ($PSVersionTable.PSVersion -lt 6.1)) {
            Write-Error "cd - is not supported below PowerShell 6.1. Please upgrade your version of PowerShell."
        }
        elseif ($dir -eq '+' -and ($PSVersionTable.PSVersion -lt 6.2)) {
            Write-Error "cd + is not supported below PowerShell 6.2. Please upgrade your version of PowerShell."
        }
        else {
            Set-Location -Path $dir -Passthru -ErrorAction Stop
        }
    }
}

# ================== Hook configuration for zoxid ==================

# Hook to add new entries to the database.
$global:__zoxide_oldpwd = __zoxide_pwd
function global:__zoxide_hook {
    $result = __zoxide_pwd
    if ($result -ne $global:__zoxide_oldpwd) {
        if ($null -ne $result) {
            zoxide add "--" $result
        }
        $global:__zoxide_oldpwd = $result
    }
}

# Initialize hook.
$global:__zoxide_hooked = (Get-Variable __zoxide_hooked -ErrorAction Ignore -ValueOnly)
if ($global:__zoxide_hooked -ne 1) {
    $global:__zoxide_hooked = 1
    $global:__zoxide_prompt_old = $function:prompt

    function global:prompt {
        if ($null -ne $__zoxide_prompt_old) {
            & $__zoxide_prompt_old
        }
        $null = __zoxide_hook
    }
}

# ================== When using zoxide with --no-cmd, alias these internal functions as desired. ==================
# Jump to a directory using only keywords.
function global:__zoxide_z {
    if ($args.Length -eq 0) {
        __zoxide_cd ~ $true
    }
    elseif ($args.Length -eq 1 -and ($args[0] -eq '-' -or $args[0] -eq '+')) {
        __zoxide_cd $args[0] $false
    }
    elseif ($args.Length -eq 1 -and (Test-Path -PathType Container -LiteralPath $args[0])) {
        __zoxide_cd $args[0] $true
    }
    elseif ($args.Length -eq 1 -and (Test-Path -PathType Container -Path $args[0] )) {
        __zoxide_cd $args[0] $false
    }
    else {
        $result = __zoxide_pwd
        if ($null -ne $result) {
            $result = __zoxide_bin query --exclude $result "--" @args
        }
        else {
            $result = __zoxide_bin query "--" @args
        }
        if ($LASTEXITCODE -eq 0) {
            __zoxide_cd $result $true
        }
    }
}

# Jump to a directory using interactive search.
function global:__zoxide_zi {
    $result = __zoxide_bin query -i "--" @args
    if ($LASTEXITCODE -eq 0) {
        __zoxide_cd $result $true
    }
}

# ================== Commands for zoxide. Disable these using --no-cmd. ==================

Set-Alias -Name z -Value __zoxide_z -Option AllScope -Scope Global -Force
Set-Alias -Name zi -Value __zoxide_zi -Option AllScope -Scope Global -Force

# =============================================================================
#
# To initialize zoxide, add this to your configuration (find it by running
# `echo $profile` in PowerShell):
#
# Invoke-Expression (& { (zoxide init powershell | Out-String) })

# =============================================================================
#
# Utility functions for yazi file manager => "y" command
#
# =============================================================================

function y {
	$tmp = (New-TemporaryFile).FullName
	yazi.cmd @args --cwd-file="$tmp"
	$cwd = Get-Content -Path $tmp -Encoding UTF8
	if ($cwd -and $cwd -ne $PWD.Path -and (Test-Path -LiteralPath $cwd -PathType Container)) {
		Set-Location -LiteralPath (Resolve-Path -LiteralPath $cwd).Path
	}
	Remove-Item -Path $tmp
}