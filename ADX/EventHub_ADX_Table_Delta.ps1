param (
    [Parameter(Mandatory=$true, HelpMessage = "Resource Group Name")][string] $RGName,
    [Parameter(Mandatory=$true, HelpMessage = "Event Hub Namespace")][string] $EH-Namespace,
    [Parameter(Mandatory=$true, HelpMessage = "ADX Cluster Name")][string] $ADXClusterName,
    [Parameter(Mandatory=$true, HelpMessage = "ADX Database Name")][string] $ADXDBaseName
)

# Get list of EventHubs and ADX DBase Data Connections
$EventHubTables = Get-AzEventHub -NamespaceName $EH-Namespace -ResourceGroupName $RGName | ForEach-Object { $_.Name.ToString() }
$ADXTables = Get-AzKustoDataConnection -ResourceGroupName $RGName -ClusterName $ADXClusterName -DatabaseName $ADXDBaseName | ForEach-Object { ($_.Name -split '/')[2].ToString() -replace "-dc$"}

# Compare Both Arrays
$uniqueInList1 = Compare-Object $EventHubTables $ADXTables | Where-Object {$_.SideIndicator -eq "<="}

# Display the delta between the two lists (arrays)
Write-Host "Tables that are not configured in ADX Database Data Connectors"
$uniqueInList1 | ForEach-Object { Write-Host $_.InputObject }
