<###########################################################################

    Author: Clinton Frantz
    Source: EventHub_ADX_Table_Delta.ps1
    Modified by: DCODEV1702 | 22 Feb 2024

    PRE-CONDITIONS:
    1. Azure PowerShell module is installed (Install-Module -Name Az -Scope AllUsers -Force)
    2. Can authenticate to Azure Gov Cloud
        + Connect-AzAccount -Environment AzureUSGovernment -UseDeviceAuthentication
    3. Has PowerShell or Azure CloudShell (PS) access
    4. Has sufficient permissions to query Event Hub Namespace and ADX Cluster & Database

    POST-CONDITIONS:
    1. EventHubs and ADX Data Connections are reconciled

    USAGE:
    1. Modify the $RGName, $EHNamespace, $ADXClusterName, and $ADXDBaseName variables as needed
    2. Run the PowerShell script
    3. Review the output to see if there are any EventHubs that are not configured for ADX Database Data Connectors
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

# Compare Both Arrays and add delta's to $uniqueInList1
$uniqueInList1 = Compare-Object $EventHubTables $ADXDataConnections | Where-Object {$_.SideIndicator -eq "<="}

# Display the delta between the two lists (arrays)
if ([string]::IsNullOrEmpty($uniqueInList1) -eq $false) {
    Write-Host "`nTables that are not configured in ADX Database Data Connectors:" -ForegroundColor Yellow
    Write-Host "The following Event Hubs are not configured for ADX Database Data Connectors:" -ForegroundColor Red
    $uniqueInList1 | ForEach-Object { Write-Host $_.InputObject }
}else {
    Write-Host "`nAll Event Hubs have corresponding ADX Data Connections!" -ForegroundColor Green
}
