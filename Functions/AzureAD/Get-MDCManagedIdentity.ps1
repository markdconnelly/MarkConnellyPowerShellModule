<#
.SYNOPSIS
    This function will produce an array of Azure AD Enterprise Applications. If an export path parameter is provided, the function will export the results to a csv file.
.DESCRIPTION
    Performing a set of operations on application service principals is a common task. This function quickly creates an array of those specific objects.
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
    Get-MDCManagedIdentity -ProductionEnvironment $true
    Get-MDCManagedIdentity -ProductionEnvironment $true -ExportPath "C:\Temp\"
#>

Function Get-MDCManagedIdentity {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$false,Position=0)]
        [string]$ExportPath,
        [Parameter(Mandatory=$false,Position=1)]
        [bool]$ProductionEnvironment = $false
    )

    # Collect array of managed identity service principals
    $arrAAD_ManagedIdentity = @()
    try {
        Write-Verbose "Collecting AAD Managed Identities"
        $arrAAD_ManagedIdentites = Get-MgServicePrincipal -All:$true -ErrorAction Stop | Where-Object {$_.ServicePrincipalType -eq "ManagedIdentity"}
    }
    catch {
        Write-Verbose "Unable to get AAD Managed Identities"
        throw "Unable to get AAD Managed Identities"
    }

    # Return the array of applications
    return $arrAAD_ManagedIdentity
}