

function scan-ranges
{
    param ([String] $Location,[String] $IPRange,[String] $fecha)
       
    $IPRangeName= $IPRange -replace '\.','_'
    $IPRangeName= $IPRangeName -replace '\/','_'
    
    $filename = ".\NMapScans\" + $Location + "-" +  $IPRangeName + "-" + $fecha + ".xml"
    
    $ports = "80,443,1433,1434,3389,9170,9230"
    #nmap -sT -sU -p 80,443,1433,1434,3389,5060,10000 -Pn $IPRange -oX $filename
    nmap -sT -sU -p $ports -Pn $IPRange -oX $filename
    
}

function run-nmap-scan
{
    ####################Inicio scan####################################
	
	#Invoco el Script de Parseo de resultados
    $fecha = Get-Date -format yyyyMMddHHmm
   
	
    #ES-BARCELONA
    
    scan-ranges "ES_BARCELONA" "xx.xx.xx.xx/28" $fecha #Telvent Subnet 1
    scan-ranges "ES_BARCELONA" "xx.xx.xx.xx/28" $fecha #Telvent Subnet 2

	
    #ES- IBERCOM
    #scan-ranges "ES_IBERCOM" "xx.xx.xx.xx/27" $fecha #Ibercom Subnet 1
    #scan-ranges "ES_IBERCOM" "xx.xx.xx.xx/27" $fecha #Ibercom Subnet 2


    #ES-INTERXION
    #scan-ranges "ES_INTERXION" "xx.xx.xx.xx/25" $fecha #Interxion Subnet 1

    ###################PARSE RESULTADOS#################################

    $parsefiles =  ".\NMapScans\" + '*' + $fecha  + ".xml"

    & .\Parse-Nmap.ps1  $parsefiles
	
}


#run the main function
run-nmap-scan