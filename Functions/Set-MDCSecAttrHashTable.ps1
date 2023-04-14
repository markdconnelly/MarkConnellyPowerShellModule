<#
.SYNOPSIS
    This function will create a hash table with the custom security attribute definition that is passed to it.
.DESCRIPTION
    This function will create a hash table with the custom security attribute definition that is passed to it.
.NOTES
    This is a custom function written by Mark Connelly, so it may not work as intended. Use at your own risk.
    This function assumes a secret store with the appropriate variables is in place. If it is not, the function will fail.
.LINK
    https://github.com/markdconnelly/MarkConnellyPowerShellModule/blob/main/Functions/AzureAD/CustomSecurityAttributes/Set-MDCSecAttrHashTable.ps1
.EXAMPLE
    Set-MDCSecAttrHashTable -AttributeSet "Set1" -AttributeName "Attribute1" -AttributeValue "Value1"
#>
Function Set-UserCustomSecurityAttribute{
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true,Position=0)]
        [string]$CustomSecurityAttributeSet,
        [Parameter(Mandatory=$true,Position=1)]
        [string]$CustomSecurityAttributeName,
        [Parameter(Mandatory=$true,Position=2)]
        [string]$CustomSecurityAttributeValue
    )
    $hashCustomSecurityAttribute = @{}
    $hashCustomSecurityAttribute = @{
        CustomSecurityAttributes = @{
            $CustomSecurityAttributeSet = @{ 
                "@odata.type" = "#Microsoft.DirectoryServices.CustomSecurityAttributeValue"
                $CustomSecurityAttributeName = $CustomSecurityAttributeValue
            }
        }
    }
    return $hashCustomSecurityAttribute
}