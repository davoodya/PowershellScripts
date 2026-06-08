# Prompt the user to enter an IP address
$ip = Read-Host "Please enter the IP address"

# Initialize variables
$mtu = 1472  # Starting MTU size for typical internet traffic (1500 bytes - 28 bytes for IP/ICMP headers)
$found = $false
$increment = 10

# Function to perform a ping test with a specific packet size
function Test-MTU($ip, $size) {
    $ping = ping $ip -f -l $size -n 1
    return $ping -like "*TTL expired*" -or $ping -like "*Reply from*"
}

# Use binary search to find the MTU
while (-not $found) {
    if (Test-MTU $ip $mtu) {
        $mtu += $increment
    } else {
        if ($increment -eq 1) {
            $found = $true
            $mtu -= 1  # Adjust because the last increment that failed
        } else {
            $mtu -= $increment
            $increment = [Math]::Max(1, [int]($increment / 2))
        }
    }
}

# Display the MTU
Write-Host "The MTU for IP address $ip is: $($mtu + 28)"  # Add 28 to account for the header

#----------Script Explanation----------
#1. Initialization: The script starts with an MTU of 1472, which is typical for internet traffic (1500 bytes minus 28 bytes for the IP and ICMP headers).
#2. Ping Test Function: A function Test-MTU sends a ping to the specified IP with the "do not fragment" flag set and a specific packet size.
#3. Binary Search: The script uses a form of binary search to adjust the MTU size. It increases the MTU size until a packet fails to reach the destination without fragmentation, then it fine-tunes the size.
#4. Output: The script outputs the MTU size plus 28 bytes to account for the IP and ICMP headers.
#This script provides a practical approach to determining the MTU using the ping command. Adjustments might be necessary depending on the specific network environment and the behavior of intermediate routers.