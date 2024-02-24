<###########################################################################

    Author: Clinton Frantz
    Modified by DCODEV1702 | 22 Feb 2024

    PRE-CONDITIONS:
    1. Azure PowerShell module is installed (Install-Module -Name Az -Scope AllUsers -Force)
    2. Has PowerShell or Azure CloudShell (PS) access
    3. Has sufficient permissions to make modification to tables in specified Log Analytics Workspace (LAW)

    POST-CONDITIONS:
    1. EventHubs and ADX Data Connections are reconciled
###########################################################################>
param (
    [Parameter(Mandatory=$true, HelpMessage = "Resource Group Name")][string] $RGName,
    [Parameter(Mandatory=$true, HelpMessage = "Event Hub Namespace")][string] $EHNamespace,
    [Parameter(Mandatory=$true, HelpMessage = "ADX Cluster Name")][string] $ADXClusterName,
    [Parameter(Mandatory=$true, HelpMessage = "ADX Database Name")][string] $ADXDBaseName
)

# Get list of EventHubs and ADX DBase Data Connections
$EventHubTables = Get-AzEventHub -NamespaceName $EHNamespace -ResourceGroupName $RGName | ForEach-Object { $_.Name.ToString() }
$ADXDataConnections = Get-AzKustoDataConnection -ResourceGroupName $RGName -ClusterName $ADXClusterName -DatabaseName $ADXDBaseName | ForEach-Object { ($_.Name -split '/')[2].ToString() -replace "-dc$"}

# Compare Both Arrays
$uniqueInList1 = Compare-Object $EventHubTables $ADXDataConnections | Where-Object {$_.SideIndicator -eq "<="}

# Display the delta between the two lists (arrays)
Write-Host "Tables that are not configured in ADX Database Data Connectors"
$uniqueInList1 | ForEach-Object { Write-Host $_.InputObject }
