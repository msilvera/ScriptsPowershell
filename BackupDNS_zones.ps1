#https://docs.microsoft.com/en-us/azure/dns/dns-import-export

azure config mode asm
#login to azure
azure login 
#https://docs.microsoft.com/en-us/cli/azure/create-an-azure-service-principal-azure-cli?view=azure-cli-latest

#set the suscription name
azure account set "Account 1"
azure config mode arm
$fecha = Get-Date -format yyyyMMddHHmm
$resourcegroup="Servicios-Internos"
$zona = "account1.com"
$file = "./backup_account1_com."+ "-" + $fecha + ".txt" #c:\users\mariana

azure network dns zone export $resourcegroup $zona $file
