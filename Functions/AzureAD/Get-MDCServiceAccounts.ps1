<#
.SYNOPSIS
    This function will produce an array of Azure AD Service Accounts. If an export path parameter is provided, the function will export the results to a csv file.
.DESCRIPTION
    Performing a set of operations on aservice accounts is a common task. This function quickly creates an array of those specific objects. 
    Update this function to include any additional properties you would like to collect in the service account filter.
.NOTES
    This is a custom function written by Mark Connelly, so it may not work as intended.
    Version:        1.0
    Author:         Mark D. Connelly Jr.
    Creation Date:  04-16-2023
    Purpose/Change: Initial script development
.LINK
    https://github.com/markdconnelly/MarkConnellyPowerShellModule/blob/main/Functions/AzureAD/Get-MDCServiceAccounts.ps1
.EXAMPLE
    Get-MDCServiceAccounts
    Get-MDCServiceAccounts -ExportPath "C:\Temp\"
#>

Function Get-MDCServiceAccounts {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$false,Position=0)]
        [string]$ExportPath
    )

    # Collect array of service accounts
    $arrAAD_ServiceAccounts = @()
    try {
        Write-Verbose "Collecting AAD Service Accounts"
        $arrAAD_ServiceAccounts = Get-MgUser -All:$true -ErrorAction Stop `
        | Where-Object {$_.UserPrincipalName -like "svc*" -or $_.UserPrincipalName -like "*BreakGlass*"}
    }
    catch {
        Write-Verbose "Unable to get AAD Service Accounts"
        throw "Unable to get AAD Service Accounts"
    }

    # Export the array of applications to a csv file if an export path is provided
    if($ExportPath){
        Out-MDCToCSV -psobj $arrAAD_ServiceAccounts -ExportPath $ExportPath -FileName "AAD_ServiceAccounts"
    }
    # Return the array of applications
    return $arrAAD_ServiceAccounts
}