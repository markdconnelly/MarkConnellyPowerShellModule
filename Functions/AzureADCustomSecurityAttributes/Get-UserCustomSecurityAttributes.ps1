<#
.SYNOPSIS
    This function will return the value of a custom security attribute for a user.
.DESCRIPTION
    Queries the established custom security attribute for a user and checks the user specified in the parameter for that attribtue
.NOTES
    This is a custom function written by Mark Connelly, so it may not work as intended. Use at your own risk.
    This function assumes a connection to the Microsoft Graph API is established. If it is not, the function will fail.
.LINK
    N/A
.EXAMPLE
    Get-UserCustomSecurityAttributes -UserPrincipalName "user@contoso.org" -CustomSecurityAttributeSet "AttributeSet1" -CustomSecurityAttribute "Attribute1"
        If only a UPN is passed, the function will return all custom security attributes for the user.
#>

Function Get-UserCustomSecurityAttributes {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true,Position=0)]
        [string]$UserId
    )

    # Connect to the Microsoft Graph API
    Connect-GraphAutomation

    # Switch to the beta profile
    Set-GraphProfile -ProfileName "beta"

    ##
    # Itterate through the custom security attributes to build a psobject of the attributes
    $arrUser = @()
    $arrUser = Get-MgUser -UserId $UserId -Select Id,DisplayName,CustomSecurityAttributes

    ##
    $hashCustomAttributes = @{}
    $hashCustomAttributes = $arrUser.CustomSecurityAttributes.AdditionalProperties

    $psobjUserCustomSecurityAttributes = @()
    foreach($set in $hashCustomAttributes.Keys){
        ##
        $strAttributeSetName = $null
        $strAttributeSetName = $arrCustomAttributeSet[$set] 
        foreach($attribute in $strAttributeSetName){
            ##
            $strAttributeValue = $null
            $strAttributeValue = $hashCustomAttributes[$attribute] 

            ##
            $psobjUserCustomSecurityAttributes += [PSCustomObject]@{
                AttributeSet = $strAttributeSetName
                AttributeName = $strAttributeName
                AttributeValue = $strAttributeValue
            }
        }
    }

    # Switch to the v1.0 profile
    Set-GraphProfile -ProfileName "v1.0"
    
    Write-Host "Custom Security Attributes for $UserId"
    return $psobjUserCustomSecurityAttributes
}
