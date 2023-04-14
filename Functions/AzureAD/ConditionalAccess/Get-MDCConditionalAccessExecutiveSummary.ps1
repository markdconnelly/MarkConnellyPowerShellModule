<#
.SYNOPSIS
    This function will produce an executive summary of a tenant's conditional access policies.
.DESCRIPTION
    Identifying which controls are enforced in various conditional access policies is a challenge. This executive summary provides a quick report on the high level details. 
.NOTES
    This is a custom function written by Mark Connelly, so it may not work as intended.
    This function assumes a connection to the Graph API exists. If it does not, the function will fail.
.LINK
    https://github.com/markdconnelly/MarkConnellyPowerShellModule/blob/main/Functions/AzureAD/ConditionalAccess/Get-MDCConditionalAccessExecutiveSummary.ps1
.EXAMPLE
    Get-MDCConditionalAccessExecutiveSummary
    Get-MDCConditionalAccessExecutiveSummary -ProductionEnvironment $true
    Get-MDCConditionalAccessExecutiveSummary -ExportPath "C:\Temp\"
    Get-MDCConditionalAccessExecutiveSummary -ProductionEnvironment $true -ExportPath "C:\Temp\"
#>
Function Set-MDCGraphProfile {
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
}