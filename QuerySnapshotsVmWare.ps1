[string]$VIServer = "192.168.0.1"
# Imports PowerCLI Module
Import-Module VMware.VimAutomation.Core

#ignorar error de certificado
set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false
set-PowerCLIConfiguration -DisplayDeprecationWarnings $false -Confirm:$false

#PS Credential
$password = "xxxxx" | ConvertTo-SecureString -asPlainText -Force
$username = "xxxxx"
$credential = New-Object System.Management.Automation.PSCredential($username,$password)
$snapshot_count = 0

# Connects to the vCenter or ESXi servers
Connect-VIServer $VIServer -Credential $credential

# Collects VM snapshot information for all VMs where the snapshots are older than days specified
$snapshots = Get-VM -Server $VIServer | Get-Snapshot | ForEach-Object {
    $snapshot_count = $snapshot_count+1
    #$snapshot_count | out-file  -filepath ".\snapshots.txt" -Append
    $created = $_.Created 
    $PowerState = $_.PowerState
    $SizeGB = $_.SizeGB
    $name = $_.Name
    $vm = $_.VM
    $snapshot = "vm: " + $vm + " snapshot: " + $name + " fecha creacion: " +  $created + " PowerState: " + $PowerState + " SizeGB: " + $SizeGB 
    $snapshot | out-file  -filepath ".\snapshots.txt" -Append
    
   }
    
 Write-Output $snapshots

# $snapshots | out-file ".\snapshots.txt"

#| Where-Object {$_.Created -lt (Get-Date).AddDays(-$DeleteOlderThan)}



# Removes snapshots older than days specified
#$snapshots | Remove-Snapshot -RemoveChildren -RunAsync -Confirm:$false

# Disconnects from the connected vCenter or ESXi servers
Disconnect-VIServer $VIServer -Confirm:$false

# Unloads the PowerCLI module
Remove-Module VMware.VimAutomation.Core