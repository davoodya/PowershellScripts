# DNS addresses to be applied
$primaryDNS = "178.22.122.100"   # Shecan
$secondaryDNS = "185.51.200.2"   # Electro

Write-Host "`n🔌 Available Network Interfaces:"
Get-DnsClient | Select-Object InterfaceAlias, InterfaceIndex | Sort-Object InterfaceIndex | Format-Table -AutoSize


# Prompt for comma-separated interface names
$inputString = Read-Host "Enter one or more interface names separated by commas (e.g., ether1,ether2,Wi-Fi)"

# Split input into an array and trim whitespace
$interfaces = $inputString -split "," | ForEach-Object { $_.Trim() }

foreach ($iface in $interfaces) {
    # Try to find the adapter by name
    $adapter = Get-DnsClient | Where-Object { $_.InterfaceAlias -eq $iface }

    if ($adapter) {
        Write-Host "`nSetting DNS for interface: $iface"
        
        # Apply the DNS settings
        Set-DnsClientServerAddress -InterfaceAlias $iface -ServerAddresses ($primaryDNS, $secondaryDNS)
        
        Write-Host "✅ DNS successfully applied to $iface."
    } else {
        Write-Host "`n❌ Interface '$iface' not found!" -ForegroundColor Red
    }
}

# Display current DNS settings for all provided interfaces
Write-Host "`n🔎 Current DNS settings for all processed interfaces:"
Get-DnsClientServerAddress | Where-Object { $_.InterfaceAlias -in $interfaces } | Format-Table InterfaceAlias, ServerAddresses -AutoSize
