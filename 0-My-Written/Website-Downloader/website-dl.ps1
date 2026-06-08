<#
.SYNOPSIS
    Mirrors a website using wget.
.DESCRIPTION
    Uses wget to recursively download all pages and assets from a given URL.
.PARAMETER Url
    The starting URL to mirror (e.g., "https://example.com").
.PARAMETER OutputDir
    Local directory to save the mirrored site (default: "./mirror").
.PARAMETER MaxDepth
    Maximum recursion depth (default: 3).
.EXAMPLE
    .\website-dl.ps1 -Url "https://example.com" -OutputDir "C:\mirror" -MaxDepth 2
.NOTES
    Requires wget to be installed and available in PATH.
    Use only on websites you own or have permission to mirror.
#>

param (
    [Parameter(Mandatory=$true)]
    [string]$Url,

    [string]$OutputDir = "./mirror",

    [int]$MaxDepth = 3
)

# Check if wget is available
if (-not (Get-Command wget -ErrorAction SilentlyContinue)) {
    Write-Error "wget is not installed or not in PATH. Please install wget and try again."
    exit 1
}

# Create output directory if it doesn't exist
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

# Build wget command
$wgetArgs = @(
    "--mirror",           # Enable mirroring
    "--convert-links",    # Convert links for local viewing
    "--adjust-extension", # Adjust file extensions
    "--page-requisites",  # Download all assets (CSS, JS, images)
    "--no-parent",        # Do not ascend to parent directory
    "--directory-prefix=$OutputDir", # Save files to output directory
    "--level=$MaxDepth",  # Recursion depth
    "--no-host-directories", # Do not create host-prefixed directories
    "--user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",
    "--wait=1",            # Wait 1 second between requests
    "--random-wait",      # Randomize wait time
    $Url                  # Target URL
)

# Execute wget
Write-Host "[*] Starting mirror of $Url to $OutputDir (Max Depth: $MaxDepth)" -ForegroundColor Cyan
& wget $wgetArgs
Write-Host "[*] Mirroring complete. Files saved to: $OutputDir" -ForegroundColor Cyan