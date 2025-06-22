Get-WmiObject win32_networkAdapterConfiguration | 
    where defaultipgateway -ne $null |
    Select-Object -Property Description |
    Out-GridView -PassThru | 
    ForEach-Object -Process {
        $Splat = @{
            NetAdapterInterfaceDescription = $_.Description
            Name = "PSExternal2-Huawei"
            AllowManagementOS = $True
            Notes = "External switch for internet Access for Sandbox"
            Verbose = $True
        }
    New-VMSwitch @Splat
    }


#Way 1 to add External Adapter
Get-VM DC1, SVR1 | Add-VMNetworkAdapter -Name External1-Mikrotik -Verbose

#Way 2 to add External Adapter
Get-VMSwitch -Name External2-Huawei Connect-VMNetworkAdapter -VMName DC1, SVR1 -Name External1-Mikrotik -Verbose
