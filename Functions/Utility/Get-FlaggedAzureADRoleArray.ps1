<#
.SYNOPSIS
    This function is used to define flagged graph api permissions.
.DESCRIPTION
    Produces an array of flagged graph permissions to be in used in comparison operations.
.NOTES
    This is a custom function written by Mark Connelly, so it may not work as intended.
.LINK
    https://github.com/markdconnelly/MarkConnellyPowerShellModule/blob/main/Functions/Utility/Connect-MDCGraphApplication.ps1
.EXAMPLE
    Connect-MDCGraphApplication 
    Connect-MDCGraphApplication -ProductionEnvironment $false
    Connect-MDCGraphApplication -ProductionEnvironment $true
#>