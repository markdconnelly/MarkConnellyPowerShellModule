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
    https://github.com/markdconnelly/MarkConnellyPowerShellModule/blob/main/Functions/AzureAD/Get-MDCEnterpriseApplications.ps1
.EXAMPLE
    Get-MDCEnterpriseApplications
    Get-MDCEnterpriseApplications -ExportPath "C:\Temp\"
    Get-MDCEnterpriseApplications -ProductionEnvironment $true
    Get-MDCEnterpriseApplications -ProductionEnvironment $true -ExportPath "C:\Temp\"
#>

Function Get-MDCEnterpriseApplications {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$false,Position=0)]
        [string]$ExportPath,
        [Parameter(Mandatory=$false,Position=1)]
        [bool]$ProductionEnvironment = $false
    )

    # Collect array of application service principals
    $arrAAD_Applications = @()
    try {
        Write-Verbose "Collecting AAD Applications"
        $arrAAD_Applications = Get-MDCApplicationServicePrincipals -ProductionEnvironment $ProductionEnvironment -ErrorAction Stop
    }
    catch {
        Write-Verbose "Unable to get AAD Applications"
        throw "Unable to get AAD Applications"
    }

    # Return the array of applications
    return $arrAAD_Applications
}