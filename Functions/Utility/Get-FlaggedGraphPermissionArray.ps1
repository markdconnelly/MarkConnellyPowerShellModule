<#
.SYNOPSIS
    This function is used to define flagged graph api permissions.
.DESCRIPTION
    Produces an array of flagged graph permissions to be in used in comparison operations.
.NOTES
    This is a custom function written by Mark Connelly, so it may not work as intended.
.LINK
    https://github.com/markdconnelly/MarkConnellyPowerShellModule/blob/main/Functions/Utility/Get-FlaggedAzureADRoleArray.ps1
.EXAMPLE
    $variable = Get-FlaggedAzureADRoleArray
#>

Function Get-FlaggedAzureADRoleArray {
    [CmdletBinding()]
    Param ()

    $arrFlaggedAzureADRoles = Get-MgDirectoryRole | Where-Object {$_.DisplayName -like "*Administrator*"} | Select-Object Id, DisplayName, Description
    return $arrFlaggedAzureADRoles
}