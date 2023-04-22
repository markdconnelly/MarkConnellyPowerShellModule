<#
.SYNOPSIS
    This function will switch the graph profile between v1.0 and beta.
.DESCRIPTION
    Quick connect function to refresh graph api connection.
.NOTES
    This is a custom function written by Mark Connelly, so it may not work as intended.
    This function assumes a connection to the Graph API exists. If it does not, the function will fail.
.LINK
    https://github.com/markdconnelly/MarkConnellyPowerShellModule/blob/main/Functions/Utility/Set-MDCGraphProfile.ps1
.EXAMPLE
    Set-MDCGraphProfile -ProfileName "Beta"
#>

Function Set-MDCGraphProfile {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true,Position=0)]
        [ValidateSet('v1.0','beta')]
        [string]$ProfileName
    )
    # Validate that the correct profile is in use
    $strCurrentProfileName = Get-MgProfile | Select-Object -ExpandProperty Name
    Write-Verbose "Current profile: $strCurrentProfileName"
    if ($strCurrentProfileName -ne $ProfileName) {
        try {
            Select-MgProfile $ProfileName
            Write-Verbose "Profile check has changed the profile to $ProfileName"
        }
        catch {
            Write-Error "Profile check failed to change the profile to $ProfileName"
            return $Error[0].Exception.Message
        }
    }
}