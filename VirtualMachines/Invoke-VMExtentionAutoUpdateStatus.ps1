<##############################################################################
LEGAL DISCLAIMER
This Sample Code is provided for the purpose of illustration only and is not
intended to be used in a production environment.  THIS SAMPLE CODE AND ANY
RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.  We grant You a
nonexclusive, royalty-free right to use and modify the Sample Code and to
reproduce and distribute the object code form of the Sample Code, provided
that You agree: (i) to not use Our name, logo, or trademarks to market Your
software product in which the Sample Code is embedded; (ii) to include a valid
copyright notice on Your software product in which the Sample Code is embedded;
and (iii) to indemnify, hold harmless, and defend Us and Our suppliers from and
against any claims or lawsuits, including attorneys’ fees, that arise or result
from the use or distribution of the Sample Code.

This posting is provided "AS IS" with no warranties, and confers no rights. Use
of included script samples are subject to the terms specified
at https://www.microsoft.com/en-us/legal/copyright.

##############################################################################>

<#
.SYNOPSIS
    Get Azure VM extensions and if enabled for automatic upgrade
.DESCRIPTION
    Reports all VM extensions and if they are enabled for automatic upgrade.
    If the -EnableAutomaticUpgrade switch is used, the script will enable automatic upgrade for all extensions.
    Example: .\Get-VmExtUpdateStatus.ps1 -CloudEnvironment AzureUSGovernment -EnableAutomaticUpgrade -OutputReport 

    https://learn.microsoft.com/en-us/azure/virtual-machines/automatic-extension-upgrade?tabs=powershell1%2CRestAPI2
.INPUTS
    -CloudEnvironment
    -EnableAutomaticUpgrade
    -OutputReport
.OUTPUTS
    output to screen and optional CSV file

.TODO
    Add support for Azure Arc enabled servers

.NOTES
    Name: Get-VmExtUpdateStatus.ps1
    Authors/Contributors: Nick OConnor, DCODEV1702
    DateCreated: 10/2/2024
    Revisions:
#>


param(
    [string] [ValidateSet("AzureCloud", "AzureUSGovernment")]
    $CloudEnvironment = "AzureCloud",
    [switch] $EnableAutomaticUpgrade,
    [switch] $AzureArcVMs,
    [switch] $OutputReport
)

# Check if already logged in
$context = Get-AzContext
if ($null -eq $context) {
    # Login to Azure
    Connect-AzAccount
} else {
    $currentAccount = $context.Account
    $continue = Read-Host "You are already logged in as $($currentAccount.Id). Do you want to continue using this account? (Y/N)"
    if ($continue -ne 'Y') {
        # Login to Azure
        Connect-AzAccount -environment $CloudEnvironment | Out-Null
    }
}

# Get all subscriptions
$subscriptions = Get-AzSubscription
$subscriptions = $subscriptions[1] # Just hardcoding to my main subscription for now


# Initialize arrays to store the results
$vms = @()
$results = @()


foreach ($subscription in $subscriptions) {
    # Set the current subscription context and suppress output
    Set-AzContext -SubscriptionId $($subscription).Id # | Out-Null

    # Get all VMs in the current subscription
    # $vms += Get-AzVM -Status

    # Just adding a few VMs for testing
    $vms += (Get-AzVM -Name 'squid-piab' -Status)
    $vms += (Get-AzVM -Name 'Rocky8-0' -Status)
    $vms += (Get-AzVM -Name 'childdc3' -Status)
    $vms += (Get-AzVM -Name 'childdc4' -Status)
    
    if ($PSBoundParameters.ContainsKey('AzureArcVMs')) {
        # Get all Azure Arc enabled servers in the current subscription
        # $vms += Get-AzConnectedMachine -SubscriptionId $subscription.Id
        $vms += (Get-AzConnectedMachine -ResourceGroupName sec_telem_law_1 -SubscriptionId (Get-AzContext).Subscription.Id -Name 'SVR22-PROX-DC-1')
        $vms += (Get-AzConnectedMachine -ResourceGroupName sec_telem_law_1 -SubscriptionId (Get-AzContext).Subscription.Id -Name 'RHEL8-HYPRV-CMRL-AMA-00')
    }

    foreach ($vm in $vms) {

        # Check if the VM is running
        # -or ($vm.Status -ne 'Connected' -and $vm.Type -ne 'Microsoft.HybridCompute/machines')
        if (($vm.PowerState -eq "VM running" -and $vm.Type -eq 'Microsoft.Compute/virtualMachines') -or ($vm.Status -eq 'Connected' -and $vm.Type -eq 'Microsoft.HybridCompute/machines')) {
        
            if ($vm.Type -eq 'Microsoft.Compute/virtualMachines') {
                # Get all extensions for the current Azure VM
                Write-Host "Fantastic! Azure VM '$($vm.Name)' is running. Lets evaluate the status of its extensions!" -ForegroundColor Cyan
                $extensions = Get-AzVMExtension -ResourceGroupName $vm.ResourceGroupName -VMName $vm.Name
            } elseif ($vm.Type -eq 'Microsoft.HybridCompute/machines' -and ($PSBoundParameters.ContainsKey('AzureArcVMs'))) {
                # Get all extensions for the current Azure Arc VM
                Write-Host "Fantastic! Azure Arc VM '$($vm.Name)' is running. Lets evaluate the status of its extensions!" -ForegroundColor Cyan
                $extensions = Get-AzConnectedMachineExtension -ResourceGroupName $vm.ResourceGroupName -MachineName $vm.Name
            }
            
            foreach ($extension in $extensions) {

                # Enable automatic upgrade for the extension if the switch is used
                if ($PSBoundParameters.ContainsKey('EnableAutomaticUpgrade')) {

                    # Check if the extension is already configured for automatic upgrade, and if not, enable it
                    if (-not ($extension.EnableAutomaticUpgrade)) {
                        try {
                            if ($vm.Type -eq 'Microsoft.Compute/virtualMachines') {
                                # Enable automatic upgrade for eligible extension(s)
                                Set-AzVMExtension -Publisher $extension.Publisher -ExtensionType $extension.ExtensionType -ResourceGroupName $vm.ResourceGroupName -VMName $vm.Name -Name $extension.Name -EnableAutomaticUpgrade $true -ErrorAction Stop | Out-Null
                                Write-Host "Automatic upgrade enabled for Azure VM '$($vm.Name)' and extension '$($extension.Name)' in resource group '$($vm.ResourceGroupName)'." -ForegroundColor Green
                            } elseif ($vm.Type -eq 'Microsoft.HybridCompute/machines' -and ($PSBoundParameters.ContainsKey('AzureArcVMs'))) {
                                # Enable automatic upgrade for eligible extension(s)
                                Set-AzConnectedMachineExtension -Location $extension.Location -Publisher $extension.Publisher -ExtensionType $extension.ExtensionType -ResourceGroupName $vm.ResourceGroupName -MachineName $vm.Name -Name $extension.Name -EnableAutomaticUpgrade -ErrorAction Stop | Out-Null
                                Write-Host "Automatic upgrade enabled for Azure Arc VM '$($vm.Name)' and extension '$($extension.Name)' in resource group '$($vm.ResourceGroupName)'." -ForegroundColor Green
                            }
                            
                        } catch {
                            # Handle the specific error for unsupported operations
                            if ($_.Exception.Message -like "*does not support setting enableAutomaticUpgrade property to true*") {
                                Write-Host "Error: Automatic upgrade cannot be enabled for VM '$($vm.Name)' for VM extension '$($extension.Name)' in subscription '$($subscription.Name)'. This extension does not support this feature." -ForegroundColor Yellow
                            } else {
                                # Handle other exceptions
                                Write-Host "An unexpected error occurred: $($_.Exception.Message)" -ForegroundColor Red
                            }
                        }
                    }
                }

                # Add the result to the array
                $results += [PSCustomObject][ordered]@{
                    SubscriptionName       = $subscription.Name
                    ResourceGroupName      = $vm.ResourceGroupName
                    VMName                 = $vm.Name
                    Status                 = ($vm.Type -eq 'Microsoft.Compute/virtualMachines') ? $vm.PowerState : $vm.Status
                    ExtensionName          = $extension.Name
                    EnableAutomaticUpgrade = $extension.EnableAutomaticUpgrade
                    Environment            = ($vm.Type -eq 'Microsoft.Compute/virtualMachines') ? $CloudEnvironment : 'Azure Arc'
                    Location               = $vm.Location
                }
            }
        } else {

            if ($vm.Type -eq 'Microsoft.Compute/virtualMachines') {
                Write-Host "Azure VM '$($vm.Name)' is not running. Skipping evaluation of its extensions." -ForegroundColor Yellow
            } elseif ($vm.Type -eq 'Microsoft.HybridCompute/machines' -and ($PSBoundParameters.ContainsKey('AzureArcVMs'))) {
                Write-Host "Azure Arc VM '$($vm.Name)' is not running. Skipping evaluation of its extensions." -ForegroundColor Yellow
            }

            # Add the result to the array
            $results += [PSCustomObject][ordered]@{
                SubscriptionName       = $subscription.Name
                ResourceGroupName      = $vm.ResourceGroupName
                VMName                 = $vm.Name
                Status                 = ($vm.Type -eq 'Microsoft.Compute/virtualMachines') ? $vm.PowerState : $vm.Status
                ExtensionName          = "N/A"
                EnableAutomaticUpgrade = "N/A"
                Environment            = ($vm.Type -eq 'Microsoft.Compute/virtualMachines') ? $CloudEnvironment : 'Azure Arc'
                Location               = $vm.Location
            }
            continue
        }
    }
}

# Output the results to the screen
$results | Format-Table -AutoSize
# Export the results to a CSV file
if ($PSBoundParameters.ContainsKey('OutputReport')) {
    $results | Export-Csv -Path "vmExtensionUpgradeStatus.csv" -NoTypeInformation
    Write-Output "Report generated: vmExtensionUpgradeStatus.csv"
}
