# Check for Administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Administrator."
    exit
}

# 1. Show Network Interface Names
Write-Host "`nAvailable Network Interfaces:" -ForegroundColor Cyan
$adapters = Get-NetAdapter | Sort-Object Name
$i = 1
foreach ($adapter in $adapters) {
    Write-Host "[$i] $($adapter.Name)"
    $i++
}

# 2. Select Interface
$validSelection = $false
while (-not $validSelection) {
    $selection = Read-Host "`nEnter the number of the interface to configure"
    if ($selection -match '^\d+$' -and $selection -ge 1 -and $selection -le $adapters.Count) {
        $selectedAdapter = $adapters[$selection - 1]
        $validSelection = $true
    } else {
        Write-Warning "Invalid selection. Please try again."
    }
}

$interfaceAlias = $selectedAdapter.Name
Write-Host "Selected Interface: '$interfaceAlias'" -ForegroundColor Green

# 3. Get User Input
$ipAddress = Read-Host "Enter IP Address (e.g. 192.168.1.10)"
$subnetMask = Read-Host "Enter Subnet Mask (e.g. 255.255.255.0)"
$gateway = Read-Host "Enter Default Gateway (e.g. 192.168.1.1)"
$dns1 = Read-Host "Enter Primary DNS (e.g. 8.8.8.8)"
$dns2 = Read-Host "Enter Secondary DNS (e.g. 8.8.4.4)"

# Helper to convert Subnet Mask to Prefix Length (CIDR)
function Get-PrefixLength {
    param ([string]$Mask)
    try {
        $IPAddress = [System.Net.IPAddress]::Parse($Mask)
        $Bytes = $IPAddress.GetAddressBytes()
        $Bits = [String]::Join("", ($Bytes | ForEach-Object { [Convert]::ToString($_, 2).PadLeft(8, '0') }))
        return $Bits.IndexOf('0')
    } catch {
        return $null
    }
}

$prefixLength = Get-PrefixLength -Mask $subnetMask

if ($null -eq $prefixLength -or $prefixLength -eq -1) {
    Write-Error "Invalid Subnet Mask provided."
    exit
}

# 4. Apply Configuration
Write-Host "`nApplying configuration to '$interfaceAlias'..." -ForegroundColor Yellow

try {
    # Clear existing gateways and IP addresses to avoid conflicts (Switching from DHCP or changing Static)
    # Note: This momentarily disconnects the interface
    Set-NetIPInterface -InterfaceAlias $interfaceAlias -Dhcp Disabled -ErrorAction SilentlyContinue
    Remove-NetIPAddress -InterfaceAlias $interfaceAlias -AddressFamily IPv4 -Confirm:$false -ErrorAction SilentlyContinue
    Remove-NetRoute -InterfaceAlias $interfaceAlias -AddressFamily IPv4 -Confirm:$false -ErrorAction SilentlyContinue

    # Set new IP Address, Subnet (Prefix), and Default Gateway
    New-NetIPAddress -InterfaceAlias $interfaceAlias `
                     -IPAddress $ipAddress `
                     -PrefixLength $prefixLength `
                     -DefaultGateway $gateway `
                     -AddressFamily IPv4 `
                     -ErrorAction Stop | Out-Null

    # Set DNS Servers
    Set-DnsClientServerAddress -InterfaceAlias $interfaceAlias `
                               -ServerAddresses ($dns1, $dns2) `
                               -ErrorAction Stop

    Write-Host "Successfully configured '$interfaceAlias'." -ForegroundColor Green
    
    # Show new config
    Get-NetIPConfiguration -InterfaceAlias $interfaceAlias
}
catch {
    Write-Error "An error occurred while applying the configuration: $_"
}
