# DNS addresses to be applied
$primaryDNS = "178.22.122.100"   # Shecan
$secondaryDNS = "185.51.200.2"   # Electro

# Prompt the user to enter the interface name
$interfaceName = Read-Host "Enter the name of the network interface (e.g., ether1)"

# Try to get the interface based on user input
$adapter = Get-DnsClient | Where-Object { $_.InterfaceAlias -eq $interfaceName }

if ($adapter) {
    Write-Host "Setting DNS for interface: $interfaceName"

    # Set the DNS addresses
    Set-DnsClientServerAddress -InterfaceAlias $interfaceName -ServerAddresses ($primaryDNS, $secondaryDNS)

    Write-Host "✅ DNS successfully applied to $interfaceName.`n"
    
    # Display current DNS settings for verification
    Write-Host "Current DNS servers for ${interfaceName}:"
    Get-DnsClientServerAddress -InterfaceAlias $interfaceName | Format-Table InterfaceAlias, ServerAddresses -AutoSize
} else {
    Write-Host "❌ Interface '$interfaceName' was not found. Please check the name and try again." -ForegroundColor Red
}
