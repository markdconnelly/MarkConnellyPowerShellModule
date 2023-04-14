<#
.SYNOPSIS
    This function will return an array of users that match the selected custom security attributes.
.DESCRIPTION
    Queries all users filtered by the custom security attributes specified in the parameters.
.NOTES
    This is a custom function written by Mark Connelly, so it may not work as intended. Use at your own risk.
    This function assumes a connection to the Microsoft Graph API is established. If it is not, the function will fail.
.LINK
    https://github.com/markdconnelly/MarkConnellyPowerShellModule/blob/main/Functions/AzureAD/CustomSecurityAttributes/Get-MDCUserBySecAttr.ps1
.EXAMPLE
    Get-MDCUserBySecAttr -CustomSecurityAttributeSet "AttributeSet1" -CustomSecurityAttributeName "Attribute1" -CustomSecurityAttributeValue "AttributeValue"
#>

Function Get-MDCUserBySecAttr{
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true,Position=0)]
        [string]$CustomSecurityAttributeSet,
        [Parameter(Mandatory=$true,Position=1)]
        [string]$CustomSecurityAttributeName,
        [Parameter(Mandatory=$true,Position=2)]
        [string]$CustomSecurityAttributeValue
    )

    # Connect to the Microsoft Graph API
    Connect-GraphAutomation

    # Switch to the beta profile
    Set-GraphProfile -ProfileName "beta"

    # Get all users and filter by the custom security attributes
    $arrUsersByCustomSecurityAttributes = @()
    $arrUsersByCustomSecurityAttributes = Get-MgUser -All:$true -Select Id,DisplayName,CustomSecurityAttributes `
    | Where-Object {$_.CustomSecurityAttributes.AdditionalProperties.$CustomSecurityAttributeSet.$CustomSecurityAttributeName -eq $CustomSecurityAttributeValue}

    # Switch to the v1.0 profile
    Set-GraphProfile -ProfileName "v1.0"
        
    return $arrUsersByCustomSecurityAttributes
}