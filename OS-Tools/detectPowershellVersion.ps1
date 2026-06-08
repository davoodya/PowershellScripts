# Check the PowerShell version
if ($PSVersionTable.PSVersion.Major -ge 7)
{
	Write-Host "This script is running in PowerShell Core (7+)."
}
elseif ($PSVersionTable.PSVersion.Major -eq 5 -and $PSVersionTable.PSVersion.Minor -eq 1)
{
	Write-Host "This script is running in Windows PowerShell (5.1)."
}
else
{
	Write-Host "This script is running in an unsupported version of PowerShell."
}

