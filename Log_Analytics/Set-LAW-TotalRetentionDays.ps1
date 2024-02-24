<###########################################################################

    Author: Chad Schultz (itoleck)
    Source: https://github.com/itoleck/Azure/blob/3ae83d059371ba28bb6af61a4a5884fe250eb1a5/Monitor/Set-Retentions.ps1#L19
    Modified by DCODEV1702 | 21 Feb 2024

    WARNING: THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND.
    SOURCE CODE MAKES NO REPRESENTATIONS ABOUT THE SUITABILITY OF THE INFORMATION CONTAINED 
    IN THE DOCUMENTS AND RELATED GRAPHICS PUBLISHED ON THE WEB SITE FOR ANY PURPOSE. 
    ALL SUCH DOCUMENTS AND RELATED GRAPHICS ARE PROVIDED “AS IS” WITHOUT WARRANTY OF ANY KIND. 
    SOURCE CODE HEREBY DISCLAIMS ALL WARRANTIES AND CONDITIONS WITH REGARD TO THIS INFORMATION, 
    INCLUDING ALL WARRANTIES AND CONDITIONS OF MERCHANTABILITY, WHETHER EXPRESS, IMPLIED OR STATUTORY, 
    FITNESS FOR A PARTICULAR PURPOSE, TITLE AND NON-INFRINGEMENT. IN NO EVENT SHALL SOURCE CODE 
    AND/OR ITS RESPECTIVE SUPPLIERS BE LIABLE FOR ANY SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES 
    OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION
    OF CONTRACT, NEGLIGENCE, OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE
    USE OR PERFORMANCE OF INFORMATION AVAILABLE FROM THE SERVICES.

    PRE-CONDITIONS:
    1. Azure PowerShell module is installed (Install-Module -Name Az -Scope AllUsers -Force)
    2. Has PowerShell or Azure CloudShell (PS) access
    3. Has sufficient permissions to make modification to tables in specified Log Analytics Workspace (LAW)

    POST-CONDITIONS:
    1. All tables in specified LAW will have the same total retention settings (in days)
    
###########################################################################>
param (
    [Parameter(Mandatory=$true, HelpMessage = "Resource Group name")][string] $RGName,
    [Parameter(Mandatory=$true, HelpMessage = "Log Analytics Workspace name")][string] $WorkspaceName,
    [Parameter(Mandatory=$true, HelpMessage = "Total # of Retention Days (per table)")][string] $TotalRetentionInDays,
    [Parameter(Mandatory=$false, HelpMessage = "Show the current table retention settings only")][boolean] $ShowOnly = $false
)

# Acquire all tables from specified LAW ($WorkspaceName)
$tbls = Get-AzOperationalInsightsTable -ResourceGroupName $RGName -WorkspaceName $WorkspaceName

if ($ShowOnly) {
    $tbls | Select-Object Name, RetentionInDays, TotalRetentionInDays | Sort-Object Name
} else {
    foreach ($tbl in $tbls) {
        Update-AzOperationalInsightsTable -ResourceGroupName $RGName -WorkspaceName $WorkspaceName -TotalRetentionInDays $TotalRetentionInDays -TableName $tbl
    }
}
