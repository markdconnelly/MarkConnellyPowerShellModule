<#
.SYNOPSIS
    This function will produce an array of Azure AD managed identities. If an export path parameter is provided, the function will export the results to a csv file.
.DESCRIPTION
    Performing a set of operations on managed identities is a common task. This function quickly creates an array of those specific objects.
.NOTES
    This is a custom function written by Mark Connelly, so it may not work as intended.
    Version:        1.0
    Author:         Mark D. Connelly Jr.
    Creation Date:  04-16-2023
    Purpose/Change: Initial script development
.LINK
    https://github.com/markdconnelly/MarkConnellyPowerShellModule/blob/main/Functions/AzureAD/Get-MDCManagedIdentity.ps1
.EXAMPLE
    Get-MDCManagedIdentity
    Get-MDCManagedIdentity -ExportPath "C:\Temp\"
#>

Function Get-MDCManagedIdentity {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$false,Position=0)]
        [string]$ExportPath
    )

    # Collect array of managed identity service principals
    $arrAAD_ManagedIdentity = @()
    try {
        Write-Verbose "Collecting AAD Managed Identities"
        $arrAAD_ManagedIdentity = Get-MgServicePrincipal -All:$true -ErrorAction Stop | Where-Object {$_.ServicePrincipalType -eq "ManagedIdentity"}
    }
    catch {
        Write-Verbose "Unable to get AAD Managed Identities"
        throw "Unable to get AAD Managed Identities"
    }

    # Export the array of applications to a csv file if an export path is provided
    if($ExportPath){
        Out-MDCToCSV -psobj $arrAAD_ManagedIdentity -ExportPath $ExportPath -FileName "AAD_ManagedIdentity"
    }
    
    # Return the array of applications
    return $arrAAD_ManagedIdentity
}