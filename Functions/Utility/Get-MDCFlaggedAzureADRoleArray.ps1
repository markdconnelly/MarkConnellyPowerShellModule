<#
.SYNOPSIS
    This function is used to define flagged Azure AD roles.
.DESCRIPTION
    Produces an array of flagged Azure AD roles to be in used in comparison operations.
.NOTES
    This is a custom function written by Mark Connelly, so it may not work as intended.
    Version:        1.0
    Author:         Mark D. Connelly Jr.
    Creation Date:  04-16-2023
    Purpose/Change: Initial script development
.LINK
    https://github.com/markdconnelly/MarkConnellyPowerShellModule/blob/main/Functions/Utility/Get-FlaggedAzureADRoleArray.ps1
.EXAMPLE
    $variable = Get-FlaggedAzureADRoleArray
#>

Function Get-FlaggedAzureADRoleArray {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$false,Position=0)]
        [string]$ExportPath
    )

    # Define the array of flagged Azure AD roles
    $arrFlaggedAzureADRoles = Get-MgDirectoryRole | Where-Object {$_.DisplayName -like "*Administrator*"} | Select-Object Id, DisplayName, Description

    # Export the array of applications to a csv file if an export path is provided
    if($ExportPath){
        Out-MDCToCSV -psobj $arrFlaggedAzureADRoles -ExportPath $ExportPath -FileName "AAD_FlaggedRoleArray"
    }
    return $arrFlaggedAzureADRoles
}