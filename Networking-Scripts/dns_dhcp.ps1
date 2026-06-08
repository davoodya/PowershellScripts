Write-Host "`n🔌 Available Network Interfaces:"
Get-DnsClient | Select-Object InterfaceAlias, InterfaceIndex | Sort-Object InterfaceIndex | Format-Table -AutoSize


# Prompt the user to enter interface names (comma-separated)
$inputString = Read-Host "Enter one or more interface names separated by commas (e.g., ether1,ether2,Wi-Fi)"

# Convert input to array of trimmed interface names
$interfaces = $inputString -split "," | ForEach-Object { $_.Trim() }

foreach ($iface in $interfaces) {
    $adapter = Get-DnsClient | Where-Object { $_.InterfaceAlias -eq $iface }

    if ($adapter) {
        Write-Host "`nResetting DNS to DHCP for interface: $iface"

        try {
            # Set DNS to automatic (DHCP)
            Set-DnsClientServerAddress -InterfaceAlias $iface -ResetServerAddresses
            Write-Host "✅ DNS reset to DHCP successfully for $iface."
        } catch {
            Write-Host "⚠️ Failed to reset DNS for $iface $_" -ForegroundColor Yellow
        }
    } else {
        Write-Host "❌ Interface '$iface' not found!" -ForegroundColor Red
    }
}

# Display current DNS settings
Write-Host "`n🔍 Current DNS settings for all processed interfaces:"
Get-DnsClientServerAddress | Where-Object { $_.InterfaceAlias -in $interfaces } | Format-Table InterfaceAlias, ServerAddresses -AutoSize
