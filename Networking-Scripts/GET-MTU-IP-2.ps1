# Prompt the user to enter an IP address
$ip = Read-Host "Please enter the IP address"

# Use Test-NetConnection to get network information including MTU
$networkInfo = Test-NetConnection -ComputerName $ip -InformationLevel Detailed

# Display the MTU
Write-Host "The MTU for IP address $ip is: $($networkInfo.Mtu)"