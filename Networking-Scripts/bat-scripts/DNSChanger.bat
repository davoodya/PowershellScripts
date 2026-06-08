# Set DNS Addresses
$primaryDNS = "178.22.122.100"
$secondaryDNS = "185.51.200.2"

# Interfaces lists
$interfaces = @("ether1", "ether2")

foreach ($iface in $interfaces) {
    Write-Host "Set DNS For: $iface"

    # Get interface current settings
    $adapter = Get-DnsClient | Where-Object {$_.InterfaceAlias -eq $iface}

    if ($adapter) {
        # Set DNS
        Set-DnsClientServerAddress -InterfaceAlias $iface -ServerAddresses ($primaryDNS, $secondaryDNS)
        Write-Host "✅ DNS SuSccesfully Set for: $iface " -ForegroundColor Green
    } else {
        Write-Host "❌ Interface with name: $iface not founded!!!"  -ForegroundColor Red
    }
}

# Set Current DNS apply on interfaces
Write-Host "`n✅ Current DNS Server for All Interfaces: " -ForegroundColor Cyan
Get-DnsClientServerAddress | Where-Object {$_.InterfaceAlias -in $interfaces} | Format-Table InterfaceAlias, ServerAddresses -AutoSize
