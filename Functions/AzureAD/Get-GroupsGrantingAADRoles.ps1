<#
.SYNOPSIS
    Get an array of groups granting AAD roles
.DESCRIPTION
    <More detailed description of the function>
.INPUTS
  <Inputs if any, otherwise state None>
.OUTPUTS
  <Outputs if any, otherwise state None - example: Log file stored in C:\Windows\Temp\<name>.log>
.NOTES
    This is a custom function written by Mark Connelly, so it may not work as intended.
    Version:        1.0
    Author:         <Name>
    Last Updated:   <Date>
    Creation Date:  <Date>
    Purpose/Change: Initial script development
.LINK
    <Link to any relevant documentation>
.EXAMPLE
    Get-ExampleFunction -ExampleParameter "Example" -ExampleParameter2 "Example2" 
#>

Function Get-GroupsGrantingAADRoles {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true,Position=0)]
        [string]$Variable1,
        [Parameter(Mandatory=$false,Position=1)]
        [string]$Variable2 = "Default Value"
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