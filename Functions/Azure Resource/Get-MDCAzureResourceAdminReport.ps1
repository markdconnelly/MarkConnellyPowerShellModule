<#
.SYNOPSIS
    This function will produce a psobj with admins and their various permissions. f a tenant's conditional access policies. If an export path parameter is provided, the function will export the results to a csv file.
.DESCRIPTION
    Identifying excessive admin permissions is the goal. This executive summary provides a quick report on the high level details. 
.NOTES
    This is a custom function written by Mark Connelly, so it may not work as intended.
    This function assumes a connection to the Graph API exists. If it does not, the function will fail.
.LINK
    https://github.com/markdconnelly/MarkConnellyPowerShellModule/blob/main/Functions/AzureAD/ConditionalAccess/Get-MDCConditionalAccessExecutiveSummary.ps1
.EXAMPLE
    Get-MDCAzureResourceAdminReport
    Get-MDCAzureResourceAdminReport -ExportPath "C:\Temp\"
#>

Function Get-MDCAzureResourceAdminReport {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$false,Position=0)]
        [string]$ExportPath,
        [Parameter(Mandatory=$false,Position=1)]
        [bool]$ProductionEnvironment = $false
    )

    # Put function here
    #
    #
    #
    #
    #

    return $psobjAzureResourceAdminReport
}