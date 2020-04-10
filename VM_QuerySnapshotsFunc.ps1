function query-esxi
{
    param ([String] $Location,[String] $VIServer,[String] $fecha,[String] $username,[String] $password)
       
    $VIServerName= $VIServer -replace '\.','_'
    $VIServerName= $VIServerName -replace '\/','_'
    
    $filename = ".\SnapshotScans\" + $Location + "-" +  $VIServerName + "-" + $fecha + ".txt"
    
    #PS Credential
    $passwordSec = $password | ConvertTo-SecureString -asPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential($username,$passwordSec)
    $snapshot_count = 0

    # Connects to the vCenter or ESXi servers
    Connect-VIServer $VIServer -Credential $credential

    # Collects VM snapshot information for all VMs where the snapshots are older than days specified
    $snapshots = Get-VM -Server $VIServer | Get-Snapshot | Where-Object {$_.PowerState -eq "PoweredOn" } | ForEach-Object {
    #$snapshots = Get-VM -Server $VIServer | Get-Snapshot  | ForEach-Object {
        $snapshot_count = $snapshot_count+1
        $created = $_.Created 
        $PowerState = $_.PowerState
        $SizeGB = $_.SizeGB
        $name = $_.Name
        $vm = $_.VM
        $snapshot = "vm: " + $vm + " snapshot: " + $name + " fecha creacion: " +  $created + " PowerState: " + $PowerState + " SizeGB: " + $SizeGB 
        $snapshot | out-file  -filepath  $filename -Append
   }
    $snapshot_count="Cantidad de Snapshots: " + $snapshot_count
    $snapshot_count | out-file  -filepath  $filename -Append
   

    #Envio mail con los resultados
	[string[]]$recipients = "Infra <infra@mail.com>"
	
	Send-MailMessage -To $recipients -From "Infra Snapshots Scanner <snapshots@mail.com>" -Subject "Snapshots Daily Scan Results" -Body $snapshot_count -SmtpServer "mail.mail.com" -Attachments $filename
	

    # Disconnects from the connected vCenter or ESXi servers
    Disconnect-VIServer $VIServer -Confirm:$false



}

function run-query-snapshots
{
    ####################Inicio revision ####################################
	
	#Invoco el Script de Parseo de resultados
    $fecha = Get-Date -format yyyyMMddHHmm

    # Imports PowerCLI Module
    Import-Module VMware.VimAutomation.Core

    #########################################################################

    ######### US - BOCA 1 #####################
    #query-esxi "US_TEST1" "192.168.1.1" $fecha "user" "PWD" #testing
    #query-esxi "US_TEST2" "192.168.1.2" $fecha "user" "PWD" #testing 
    
    
    #########################################################################

    # Unloads the PowerCLI module
    Remove-Module VMware.VimAutomation.Core
}

#run the main function
run-query-snapshots