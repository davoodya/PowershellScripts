# Set GOROOT
[System.Environment]::SetEnvironmentVariable('GOROOT', 'C:\Program Files\Go', 'User')

# Set GOPATH
[System.Environment]::SetEnvironmentVariable('GOPATH', 'C:\Users\davoo\go', 'User')

# Get the current Path variable
$currentPath = [System.Environment]::GetEnvironmentVariable('Path', 'User')

# Check if %GOROOT%\bin is already in the Path
if (-not $currentPath -like "*%GOROOT%\bin*") {
    # Append %GOROOT%\bin to the Path variable
    $newPath = "$currentPath;C:\Program Files\Go\bin"
    [System.Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
}

# Output the new values for confirmation
Write-Host "GOROOT set to: $([System.Environment]::GetEnvironmentVariable('GOROOT', 'User'))"
Write-Host "GOPATH set to: $([System.Environment]::GetEnvironmentVariable('GOPATH', 'User'))"
Write-Host "Updated Path: $([System.Environment]::GetEnvironmentVariable('Path', 'User'))"
