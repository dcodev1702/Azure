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
    [Parameter(Mandatory=$false, HelpMessage = "Resource Group Name")]
    [string] $RGName = 'sec_telem_law_1',
    [Parameter(Mandatory=$false, HelpMessage = "Event Hub Namespace")]
    [string] $EHNamespace = 'SecurityTables-1',
    [Parameter(Mandatory=$false, HelpMessage = "ADX Cluster Name")]
    [string] $ADXClusterName = 'dart007',
    [Parameter(Mandatory=$false, HelpMessage = "ADX Database Name")]
    [string] $ADXDBaseName = 'sentinel-2-adx'
)

# Get list of EventHubs and ADX DBase Data Connections
$EventHubTables = Get-AzEventHub -NamespaceName $EHNamespace -ResourceGroupName $RGName | ForEach-Object { $_.Name.ToString() }
$ADXDataConnections = Get-AzKustoDataConnection -ResourceGroupName $RGName -ClusterName $ADXClusterName -DatabaseName $ADXDBaseName | ForEach-Object { ($_.Name -split '/')[2].ToString() -replace "-dc$"}

Write-Host "Event Hubs" -ForegroundColor Green
$EventHubTables | ForEach-Object { $_ }

Write-Host "ADX Data Connections" -ForegroundColor DarkMagenta
$ADXDataConnections | ForEach-Object { $_ }

# Compare Both Arrays
$uniqueInList1 = Compare-Object $EventHubTables $ADXDataConnections | Where-Object {$_.SideIndicator -eq "<="}

# Display the delta between the two lists (arrays)
if ([string]::IsNullOrEmpty($uniqueInList1) -eq $false) {
    Write-Host "`nTables that are not configured in ADX Database Data Connectors:" -ForegroundColor Yellow
    Write-Host "The following Event Hubs are not configured for ADX Database Data Connectors:" -ForegroundColor Red
    $uniqueInList1 | ForEach-Object { Write-Host $_.InputObject }
}else {
    Write-Host "`nAll Event Hubs have corresponding ADX Data Connections!" -ForegroundColor Green
}
