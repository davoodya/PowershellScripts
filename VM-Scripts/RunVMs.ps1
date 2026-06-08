#Get VM Objects 
$VMs = Get-VM -VMName DC1, SVR1

#Get the Name of Localhost
$Hostname = Hostname

#Make sure each VM is Started and Connect to it.
ForEach ($VM in $VMs)
{
    If($VM.State -ne "Running")
    {
        Start-VM -VMName $VM.Name
        Invoke-Expression -Command "VMConnect $($HostName) $($VM.Name)"
    }
    Else
    {
        Invoke-Expression -Command "VMConnect $($HostName) $($VM.Name)"
    }
}