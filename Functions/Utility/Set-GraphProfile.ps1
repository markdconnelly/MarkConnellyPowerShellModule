<#
.SYNOPSIS
    This function will switch the graph profile as an application service principal that is pre-defined.
.DESCRIPTION
    Quick connect function to refresh graph api connection.
.NOTES
    This is a custom function written by Mark Connelly, so it may not work as intended. Use at your own risk.
    This function assumes a secret store with the appropriate variables is in place. If it is not, the function will fail.
.LINK
    N/A
.EXAMPLE
    Set-GraphProfile -ProfileName "Beta"
#>

Function Set-GraphProfile {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true,Position=0)]
        [ValidateSet('v1.0','beta')]
        [string]$ProfileName
    )
    # Validate that the correct profile is in use
    $strCurrentProfileName = Get-MgProfile | Select-Object -ExpandProperty Name
    Write-Host "Current profile: $strCurrentProfileName" -BackgroundColor Black -ForegroundColor Green
    if ($strCurrentProfileName -ne $ProfileName) {
        Select-MgProfile $ProfileName
        Write-Host "Profile check has changed the profile to $ProfileName" -BackgroundColor Black -ForegroundColor Green
    }
}