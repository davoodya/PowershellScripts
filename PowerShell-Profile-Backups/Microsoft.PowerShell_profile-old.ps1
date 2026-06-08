
<#
    OPTIMIZED POWERSHELL PROFILE CUSTOMIZED FOR Yakuza Style
    Maintains all features while reducing startup time
    Key optimizations:
    - Lazy loading of heavy modules
    - Removal of unused/commented code
    - Efficient module loading
#>

# ========== CORE SETTINGS (Fast-loading essentials) ==========
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

# ========== MODULE LOADING (Optimized) ==========
# PSReadLine - Load only if not already present
if ($null -eq (Get-Module -Name PSReadLine)) {
    Import-Module PSReadLine -ErrorAction SilentlyContinue
}

# Chocolatey - Conditional load
if ($env:ChocolateyInstall -and (Test-Path "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1")) {
    Import-Module "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1" -ErrorAction SilentlyContinue
}

# ========== LAZY-LOADED MODULES ==========
<#
    Heavy modules are loaded only when needed:
    - posh-git loads when in a git repo or when explicitly called
    - TabExpansion loads when tab completion is used
#>

# posh-git lazy loader
function Import-PoshGit {
    if ($null -eq (Get-Module -Name posh-git)) {
        Import-Module posh-git -ErrorAction SilentlyContinue
    }
}

# TabExpansion lazy loader
function Import-TabExpansion {
    if ($null -eq (Get-Module -Name TabExpansionPlusPlus)) {
        Import-Module TabExpansionPlusPlus -ErrorAction SilentlyContinue
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


# ===== OH MY POSH v3 SETUP (FAST LOAD) =====
# Use the compiled binary instead of PowerShell module
oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\blue-owl.omp.json"| Invoke-Expression

# Optional: Use the universal shell for even better performance | Only work on new versions
# oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\kali.omp.json" --shell universal | Invoke-Expression
# Suggested Themes: amro - blue-owl - blueish - cert - json - slim slimfat

#Starship Import But dont used
#Invoke-Expression (&starship init powershell)

# ========== CUSTOM FUNCTIONS + VARIABLES ==========

# Define Custom Variables
$dayaWebsite = "H:\Repo\DavoodYa` Website\DavoodYa` Customized"
$python27 = "C:\Program Files\Python27\python.exe"

# Aliases for Files & Directories
function repo { cd H:\Repo\ }
function davoodsec { cd H:\@DavoodSec\ }
function dayaWebsite { cd $dayaWebsite }


# ========== FUNCTIONS(Aliases) TO RUN TOOLS ==========
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

function list-h {
    cd H:\Repo\
    dir
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



