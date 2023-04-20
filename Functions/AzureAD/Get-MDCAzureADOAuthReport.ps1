<#
.SYNOPSIS
    Creates a report of existing OAuth2 permissions for all users and applications in the tenant.
.DESCRIPTION
    Identifying excessive admin permissions is the goal. This report will provide the information 
    that you need to identify and remediate excessive OAuth permissions in Azure Active Directory.
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

Function Get-ExampleFunction {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$false,Position=0)]
        [string]$ExportPath,
        [Parameter(Mandatory=$false,Position=1)]
        [bool]$ProductionEnvironment = $false
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