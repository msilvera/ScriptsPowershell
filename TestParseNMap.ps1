	#Invoco el Script de Parseo de resultados
    $fecha =  "201809171808"

    $parsefiles =  ".\NMapScans\" + '*' + $fecha  + ".xml"

    & .\Parse-Nmap.ps1  $parsefiles