#Prompt to give data from User input

#region 0: Setup Virtual Switches
# Create Private Virtual Switch
$VMSwitchName = Read-Host "Enter Name of Private Virtual Switch"
New-VMSwitch -Name $VMSwitchName -SwitchType Private -Notes "Switch Used for VMs"
Write-Host "Virtual Private Switch Created in Name: $VMSwitchName `n" -ForegroundColor Green

#Get a list of all NICs that have a Gateway address
# Then Create External(Public) Switch with selected internet-base NIC
Get-WmiObject win32_networkAdapterConfiguration |
	where defaultipgateway -ne $null |
	Select-Object -Property Description |
	Out-GridView -PassThru |
	ForEach-Object -Process {
		$Splat = @{
			NetAdapterInterfaceDescription = $_.Description
			Name = "PSExternal"
			AllowManagementOS = $True
			Notes = "External switch for the Sandbox"
			Verbose = $True
		}
	New-VMSwitch @Splat
}
#endregion 0

#region 1: Create Virtual Machines

#Get the path to the Windows Server 2012 R2 ISO file
$ISOPath = "H:\OS\ISO\Windows2012R2.iso"
$VHDPath= "D:\HyperV_VMs\"

#Create the VM
$Names = "DC1", "SVR1"
ForEach ($Name in $Names)
{
	$VMHash = @{BootDevice = "CD"
				MemoryStartupBytes = 512MB
				Name = $Name
				SwitchName = "PSTest"
				NewVHDPath = "$($VHDPath)\$($Name).vhdx";
				NewVHDSizeBytes = 10GB
				Verbose = $True
			}
	New-VM @VMHash

}

#endregion 1

#region 2: Configure DVD Drive to Point ISO File
Set-VMDvdDrive -VMName DC1 -Path $ISOPath -Verbose
Set-VMDvdDrive -VMName SVR1 -Path $ISOPath -Verbose

#endregion 2

#region 3: Setup VM Memory Configuration
$VMMemoryHash = @{
	DynamicMemoryEnabled = $True
	MaximumBytes = 4096MB
	MinimumBytes = 512MB
}
Get-VM -Name DC1, SVR1 | Set-VMMemory @VMMemoryHash

#endregion 3

#region 4: Setup external switch on the VMs
#If the external NIC was created, run this code.
#First we should Add External Adapter to VMs
Get-VM DC1, SVR1 | Add-VMNetworkAdapter -Name PSExternal -Verbose
#Second we should Connect External Adapter to VMs
Get-VMSwitch -Name PSExternal | Connect-VMNetworkAdapter -VMName DC1, SVR1 -Name PSExternal -Verbose
#endregion 4
