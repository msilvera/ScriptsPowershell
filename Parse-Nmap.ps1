####################################################################################
#.Synopsis 
#    Parse XML output files of the nmap port scanner (www.nmap.org). 
#
#.Description 
#    Parse XML output files of the nmap port scanner (www.nmap.org) and  
#    emit custom objects with properties containing the scan data. The 
#    script can accept either piped or parameter input.  The script can be
#    safely dot-sourced without error as is. 
#
#.Parameter Path  
#    Either 1) a string with or without wildcards to one or more XML output
#    files, or 2) one or more FileInfo objects representing XML output files.
#
#.Parameter OutputDelimiter
#    The delimiter for the strings in the OS, Ports and Services properties. 
#    Default is a newline.  Change it when you want single-line output. 
#
#.Parameter RunStatsOnly
#    Only displays general scan information from each XML output file, such
#    as scan start/stop time, elapsed time, command-line arguments, etc.
#
#.Example 
#    dir *.xml | .\parse-nmap.ps1
#
#.Example 
#	 .\parse-nmap.ps1 -path onefile.xml
#    .\parse-nmap.ps1 -path *files.xml 
#
#.Example 
#    $files = dir *some.xml,others*.xml 
#    .\parse-nmap.ps1 -path $files    
#
#.Example 
#    .\parse-nmap.ps1 -path scanfile.xml -runstatsonly
#
#.Example 
#    .\parse-nmap.ps1 scanfile.xml -OutputDelimiter " "
#
#Requires -Version 2 
#
#.Notes 
#  Author: Enclave Consulting LLC, Jason Fossen (http://www.sans.org/sec505)  
# Version: 4.6
# Updated: 27.Feb.2016
#   LEGAL: PUBLIC DOMAIN.  SCRIPT PROVIDED "AS IS" WITH NO WARRANTIES OR GUARANTEES OF 
#          ANY KIND, INCLUDING BUT NOT LIMITED TO MERCHANTABILITY AND/OR FITNESS FOR
#          A PARTICULAR PURPOSE.  ALL RISKS OF DAMAGE REMAINS WITH THE USER, EVEN IF
#          THE AUTHOR, SUPPLIER OR DISTRIBUTOR HAS BEEN ADVISED OF THE POSSIBILITY OF
#          ANY SUCH DAMAGE.  IF YOUR STATE DOES NOT PERMIT THE COMPLETE LIMITATION OF
#          LIABILITY, THEN DELETE THIS FILE SINCE YOU ARE NOW PROHIBITED TO HAVE IT.
####################################################################################

[CmdletBinding(SupportsShouldProcess=$True)]
Param ([Parameter(Mandatory=$True, ValueFromPipeline=$true)] $Path, [String] $OutputDelimiter = "`n", [Switch] $RunStatsOnly)


function parse-nmap 
{
	param ($Path, [String] $OutputDelimiter = "`n", [Switch] $RunStatsOnly)
	
	if ($Path -match '/\?|/help|--h|--help') 
	{ 
        $MyInvocation = (Get-Variable -Name MyInvocation -Scope Script).Value
        get-help -full ($MyInvocation.MyCommand.Path)   
		exit 
	}

	if ($Path -eq $null) {$Path = @(); $input | foreach { $Path += $_ } } 
	if (($Path -ne $null) -and ($Path.gettype().name -eq "String")) {$Path = dir $path} #To support wildcards in $path.  
	$1970 = [DateTime] "01 Jan 1970 01:00:00 GMT"

    #caracteres especiales
    $Tab = [char]9
    $Enter2 = [char]13
    #$Enter = "`r`n`r`n"
	$Enter = "`r`n"
    #Seteo nombre del file
	$fecha = Get-Date -format yyyyMMddHHmm
	$filename =  './Results/NMap_ScanResult' + $fecha +  '.txt'

    $body = ""

    $ports = "80,443,1433,1434,3389,8080,8082,20-25,160-165,4422,4444,444,8180,5060,10000,9005,9006,8760,23082,18082,8992,8993,9001,9007,8463,8990,48000,43321,8998,8991,9015,8999,9008,8997,9010,8995,8996,9011,6379,26379,7000,7001,7199,9160,9200,9300,6377,26377,9170,9230"
    			
    $desc = "Scan de los siguientes puertos TCP y UDP: " + $ports + $Enter
    $desc >> $filename
		
    # Not doing just -RunStats, so process hosts from XML file.
	ForEach ($file in $Path) 
    {
		
        $location,$ip,$date = $file.name.split("-")
        
        Write-Verbose -Message ("[" + (get-date).ToLongTimeString() + "] Starting $file" )
        $StartTime = get-date  

		$xmldoc = new-object System.XML.XMLdocument
		$xmldoc.Load($file)
		

		
		# Process each of the <host> nodes from the nmap report.
		$i = 0  #Counter for <host> nodes processed.

		
        foreach ($hostnode in $xmldoc.nmaprun.host) 
        { 
            # Init some variables, with $entry being the custom object for each <host>. 
	        $service = " " #service needs to be a single space.
	        $entry = ($entry = " " | select-object HostName, FQDN, Status, IPv4, IPv6, MAC, Ports, Services, OS, Script) 

			# Extract state element of status:
			if ($hostnode.Status -ne $null -and $hostnode.Status.length -ne 0) { $entry.Status = $hostnode.status.state.Trim() }  
			if ($entry.Status.length -lt 2) { $entry.Status = "<no-status>" }

			# Extract computer names provided by user or through PTR record, but avoid duplicates and allow multiple names.
            # Note that $hostnode.hostnames can be empty, and the formatting of one versus multiple names is different.
            # The crazy foreach-ing here is to deal with backwards compatibility issues...
            $tempFQDN = $tempHostName = ""
			ForEach ($hostname in $hostnode.hostnames)
            {
                ForEach ($hname in $hostname.hostname)
                {
                    ForEach ($namer in $hname.name)
                    {
                        if ($namer -ne $null -and $namer.length -ne 0 -and $namer.IndexOf(".") -ne -1) 
                        {
                            #Only append to temp variable if it would be unique.
                            if($tempFQDN.IndexOf($namer.tolower()) -eq -1)
                            { $tempFQDN = $tempFQDN + " " + $namer.tolower() }
                        }
                        elseif ($namer -ne $null -and $namer.length -ne 0)
                        {
                            #Only append to temp variable if it would be unique.
                            if($tempHostName.IndexOf($namer.tolower()) -eq -1)
                            { $tempHostName = $tempHostName + " " + $namer.tolower() } 
                        }
                    }
                }
            }

            $tempFQDN = $tempFQDN.Trim()
            $tempHostName = $tempHostName.Trim()

            if ($tempHostName.Length -eq 0 -and $tempFQDN.Length -eq 0) { $tempHostName = "<no-hostname>" } 

            #Extract hostname from the first (and only the first) FQDN, if FQDN present.
            if ($tempFQDN.Length -ne 0 -and $tempHostName.Length -eq 0) 
            { $tempHostName = $tempFQDN.Substring(0,$tempFQDN.IndexOf("."))  } 

            if ($tempFQDN.Length -eq 0) { $tempFQDN = "<no-fullname>" }

            $entry.FQDN = $tempFQDN
            $entry.HostName = $tempHostName  #This can be different than FQDN because PTR might not equal user-supplied hostname.
            


			# Process each of the <address> nodes, extracting by type.
			ForEach ($addr in $hostnode.address)
            {
				if ($addr.addrtype -eq "ipv4") { $entry.IPv4 += $addr.addr + " "}
				if ($addr.addrtype -eq "ipv6") { $entry.IPv6 += $addr.addr + " "}
				if ($addr.addrtype -eq "mac")  { $entry.MAC  += $addr.addr + " "}
			}        
			if ($entry.IPv4 -eq $null) { $entry.IPv4 = "<no-ipv4>" } else { $entry.IPv4 = $entry.IPv4.Trim()}
			if ($entry.IPv6 -eq $null) { $entry.IPv6 = "<no-ipv6>" } else { $entry.IPv6 = $entry.IPv6.Trim()}
			if ($entry.MAC  -eq $null) { $entry.MAC  = "<no-mac>"  } else { $entry.MAC  = $entry.MAC.Trim() }


			# Process all ports from <ports><port>, and note that <port> does not contain an array if it only has one item in it.
            # This could be parsed out into separate properties, but that would be overkill.  We still want to be able to use
            # simple regex patterns to do our filtering afterwards, and it's helpful to have the output look similar to
            # the console output of nmap by itself for easier first-time comprehension.  
			if ($hostnode.ports.port -eq $null) { 
                $entry.Ports = "<no-ports>" 
                $entry.Services = "<no-services>" 
                $openports = 0
            } 
			else 
			{
				#ForEach ($porto in $hostnode.ports.port)
                #{
				#	if ($porto.service.name -eq $null) { $service = "unknown" } else { $service = $porto.service.name } 
				#	$entry.Ports += $porto.state.state + ":" + $porto.protocol + ":" + $porto.portid + ":" + $service + $OutputDelimiter 
                #    # Build Services property. What a mess...but exclude non-open/non-open|filtered ports and blank service info, and exclude servicefp too for the sake of tidiness.
                #    if ($porto.state.state -like "open*" -and ($porto.service.tunnel.length -gt 2 -or $porto.service.product.length -gt 2 -or $porto.service.proto.length -gt 2)) { $entry.Services += $porto.protocol + ":" + $porto.portid + ":" + $service + ":" + ($porto.service.product + " " + $porto.service.version + " " + $porto.service.tunnel + " " + $porto.service.proto + " " + $porto.service.rpcnum).Trim() + " <" + ([Int] $porto.service.conf * 10) + "%-confidence>$OutputDelimiter" }
				#}
				#Mariana
				$openports = 0
                
				ForEach ($porto in $hostnode.ports.port)
                {
					if ($porto.service.name -eq $null) { $service = "unknown" } else { $service = $porto.service.name } 
					if ($porto.state.state -like "open") {
						$openports += 1
						$entry.Ports +=  $Tab  + $porto.state.state + ":" + $porto.protocol + ":" + $porto.portid + ":" + $service + $OutputDelimiter + $Enter
					} else {$entry.Ports += ""}
					
                    # Build Services property. What a mess...but exclude non-open/non-open|filtered ports and blank service info, and exclude servicefp too for the sake of tidiness.
                    #if ($porto.state.state -like "open*" -and ($porto.service.tunnel.length -gt 2 -or $porto.service.product.length -gt 2 -or $porto.service.proto.length -gt 2)) { $entry.Services += $porto.protocol + ":" + $porto.portid + ":" + $service + ":" + ($porto.service.product + " " + $porto.service.version + " " + $porto.service.tunnel + " " + $porto.service.proto + " " + $porto.service.rpcnum).Trim() + " <" + ([Int] $porto.service.conf * 10) + "%-confidence>$OutputDelimiter" }
				}
				
				$entry.Ports = $entry.Ports.Trim()
			
			}
    
			# Emit custom object from script.
			$i++  #Progress counter...
            #$entry.FQDN = $tempFQDN
            #$entry.HostName

			$salida =  $location + " HOST IP " +  $entry.IPv4 + " -> " + $openports + " puertos abiertos "
			$salida2 =  $Tab  + $entry.Ports
			
            $salida
			$salida  >> $filename
			
			if ($openports -gt 0) {
				$salida2
				$salida2  >> $filename
                $body += $salida  + $Enter  + $Enter2
                $body += $salida2 + $Enter  + $Enter2
			}
			
			#$entry
		}
		
				
		Write-Verbose -Message ( "[" + (get-date).ToLongTimeString() + "] Finished $file, processed $i entries." ) 
        Write-Verbose -Message ('Total Run Time: ' + ( [MATH]::Round( ((Get-date) - $StartTime).TotalSeconds, 3 )) + ' seconds')
        Write-Verbose -Message ('Entries/Second: ' + ( [MATH]::Round( ($i / $((Get-date) - $StartTime).TotalSeconds), 3 ) ) )  
	}

    #Envio mail con los resultados

	$username = "infraestructura"
    $password = "Inc0nc3rt.2017"
    $passwordSec = $password | ConvertTo-SecureString -asPlainText -Force
    $credentials = New-Object System.Management.Automation.PSCredential($username,$passwordSec) 
	
  
	[string[]]$recipients = "Infra <infra@inconcertcc.com>","Gabriel Barcia <gbarcia@inconcertcc.com>","Josep Gimenez <jgimenez@inconcert.es>"
	#[string[]]$recipients = "Mariana <msilvera@inconcertcc.com>"
	Send-MailMessage -To $recipients -From "Infra NMap Scanner <nmap@inconcertcc.com>" -Credential $credentials -Subject "NMAP Daily Scan Results" -Body $body -SmtpServer "mail.inconcertcc.com" -Attachments $filename
	
}


# Build hashtable for splatting the parameters:
$ParamArgs = @{ Path = $Path ; OutputDelimiter = $OutputDelimiter ; RunStatsOnly = $RunStatsOnly } 

# Allow XML files to be piped into script:
if ($ParamArgs.Path -eq $null) { $ParamArgs.Path = @(); $input | foreach { $ParamArgs.Path += $_ } } 

# Run the main function with the splatted params:
parse-nmap @ParamArgs


# Notes:
# I know that the proper PowerShell way is to output $null instead of
# strings like "<no-os>" for properties with no data, but this actually
# caused confusion with people new to PowerShell and makes the outputwrite to
# more digestible when exported to CSV and other formats.

