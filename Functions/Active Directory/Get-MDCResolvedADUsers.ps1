<#
.SYNOPSIS
    This function will take an input array, and return an array of resolved users with properties that are available.
.DESCRIPTION
    It is common to get a spreadsheet of users and be asked to perform a task on that list. Before you can do anything with the list, 
    you need to resolve the users to against Active Directory so that operations are only carried on on valid users. 
    This function will take an input array, and return an array of resolved users with all of the properties that are available.
.INPUTS
    $UserArray - An array of users to resolve
    $ExportPath - The path to export the resolved users to
.OUTPUTS
    $psobjResolvedUsersAD - An array of resolved users with properties that are available in Active Directory.
.NOTES
    This is a custom function written by Mark Connelly, so it may not work as intended.
    Version:        1.0
    Author:         Mark D. Connelly Jr. 
    Last Updated:   4-18-2023
    Creation Date:  4-18-2023
    Purpose/Change: Initial script development
.LINK
    <Link to any relevant documentation>
.EXAMPLE
    Get-MDCResolvedADUsers -UserArray $users -ExportPath "C:\Temp\ResolvedUsers.csv"" 
#>

Function Get-MDCResolvedADUsers {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true,Position=0)]
        [string]$UserArray,
        [Parameter(Mandatory=$false,Position=1)]
        [string]$ExportPath
    )

    # Function code goes here
    if($Variable1){
        Write-Host "Has input"
    } else {
        Write-Host "Is null"
    }

    # Return statement goes here
    return $Variable2
}