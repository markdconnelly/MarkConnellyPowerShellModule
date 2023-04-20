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
#>

Function Get-MDCEnterpriseApplications {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$false,Position=0)]
        [string]$ExportPath
    )

    # Collect array of application service principals
    $arrAAD_Applications = @()
    try {
        Write-Verbose "Collecting AAD Applications"
        $arrAAD_Applications = Get-MgServicePrincipal -All:$true -ErrorAction Stop | Where-Object {$_.ServicePrincipalType -eq "Application" -and $_.Tags -eq "WindowsAzureActiveDirectoryIntegratedApp"} 
    }
    catch {
        Write-Verbose "Unable to get AAD Applications"
        throw "Unable to get AAD Applications"
    }

    # Export the array of applications to a csv file if an export path is provided
    if($ExportPath){
        Out-MDCToCSV -psobj $arrAAD_Applications -ExportPath $ExportPath -FileName "AAD_Applications"
    }
    
    # Return the array of applications
    return $arrAAD_Applications
}