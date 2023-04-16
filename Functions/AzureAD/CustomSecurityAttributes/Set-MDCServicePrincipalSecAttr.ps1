<#
.SYNOPSIS
    This function will set a custom security attribute for a service principal.
.DESCRIPTION
    This function will validate the security attributes that are passed into the function as valid, and then set that attribute on the designated service principal.
.NOTES
    This is a custom function written by Mark Connelly, so it may not work as intended. Use at your own risk.
.LINK
    https://github.com/markdconnelly/MarkConnellyPowerShellModule/blob/main/Functions/AzureAD/CustomSecurityAttributes/Set-MDCServicePrincipalSecAttr.ps1
.EXAMPLE
    Set-MDCServicePrincipalSecAttr -ServicePrincipalId "object id" -AttributeSet "Set1" -AttributeName "Attribute1" -AttributeValue "Value1"
#>

Function Set-MDCServicePrincipalSecAttr{
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true,Position=0)]
        [string]$ServicePrincipalId,
        [Parameter(Mandatory=$true,Position=1)]
        [string]$CustomSecurityAttributeSet,
        [Parameter(Mandatory=$true,Position=2)]
        [string]$CustomSecurityAttributeName,
        [Parameter(Mandatory=$true,Position=3)]
        [string]$CustomSecurityAttributeValue
    )

    # Switch to the beta profile
    Set-GraphProfile -ProfileName "beta"

    # Validate that the attribute set is valid
    try {
        Get-MgDirectoryCustomSecurityAttributeDefinition `
            | Where-Object {$_.AttributeSet -eq $CustomSecurityAttributeSet -and $_.Name -eq $CustomSecurityAttributeName} -ErrorAction Stop
    }
    catch {
        throw "The attribute set and attribute name combination is not valid. Please check the attribute set and attribute name and try again."
    }
    try {
        $hashAttibuteDefinition = Set-MDCSecAttrHashTable `
                                    -AttributeSet $CustomSecurityAttributeSet `
                                    -AttributeName $CustomSecurityAttributeName `
                                    -AttributeValue $CustomSecurityAttributeValue
    }
    catch {
        throw "Unable to create a hash table with the attribute set and attribute name combination."
    }
    try {
        Update-MgServicePrincipal -ServicePrincipalId $ServicePrincipalId -BodyParameter $hashAttibuteDefinition -ErrorAction Stop
        Write-Host "$ServicePrincipalId 's Custom Security Attribute has been updated" -BackgroundColor Black -ForegroundColor Green
        Write-Host "AttributeSet: $CustomSecurityAttributeSet" -BackgroundColor Black -ForegroundColor Green
        Write-Host "AttributeName: $CustomSecurityAttributeName" -BackgroundColor Black -ForegroundColor Green
        Write-Host "AttributeValue: $CustomSecurityAttributeValue" -BackgroundColor Black -ForegroundColor Green
    }
    catch {
        throw $Error[0].Exception.Message
    }

    # Switch to the v1.0 profile
    Set-GraphProfile -ProfileName "v1.0"
}