$username = "xxxx"
$password =""
$userpass  = $username + “:” + $password
$bytes= [System.Text.Encoding]::UTF8.GetBytes($userpass)
$encodedlogin=[Convert]::ToBase64String($bytes)

$authheader = "Basic " + $encodedlogin
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Authorization",$authheader)
$headers.Add("Accept","application/json")
$headers.Add("Content-Type","application/json")

#Solo un Ticket
#$uri = "https://xxxx.teamwork.com/desk/v1/tickets/2893078.json"
#"inboxId": 12159,
#"inboxName": "xxxxx Support",
$pathToOutputFile = "ResultDeskAPI2205.csv"

$uri = "https://xxxx.teamwork.com/desk/v1/tickets/search.json?sortBy=createdAt&sortDir=desc&inboxIds=12159"

#$uri = "https://xxxx.teamwork.com/desk/v1/tickets/search.json?sortBy=createdAt&sortDir=desc"
#$response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Post -ContentType "application/json"
	

$response = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers

$response.ToString()

"**** Cantidad de tickets: " + $response.count
"**** Cantidad de pages: " + $response.maxPages
$maxpages=$response.maxPages

$response | Select-Object -ExpandProperty  "tickets" | ConvertTo-Csv -NoTypeInformation | Add-Content $pathToOutputFile


For ($i=2; $i -le $maxpages; $i++) {
    "***query page: " + $i
    $response.tickets.Count

   

    $uri = "https://xxxx.teamwork.com/desk/v1/tickets/search.json?sortBy=createdAt&sortDir=desc&inboxIds=12159&page="+$i
    $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers


   # if ($response.tickets.Count -lt 50)  {
        
    #    $response | ConvertTo-Json | Out-File -FilePath  .\OutMenos50.txt  
   
    #}
    
    $response | Select-Object -ExpandProperty  "tickets" | ConvertTo-Csv -NoTypeInformation | Add-Content $pathToOutputFile

    }