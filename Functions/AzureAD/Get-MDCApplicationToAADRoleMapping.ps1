<#
.SYNOPSIS
    Creates an Azure AD role mapping table for all applications in the tenant.
.DESCRIPTION
    <More detailed description of the function>
.INPUTS
  <Inputs if any, otherwise state None>
.OUTPUTS
  <Outputs if any, otherwise state None - example: Log file stored in C:\Windows\Temp\<name>.log>
.NOTES
    This is a custom function written by Mark Connelly, so it may not work as intended.
    Version:        1.0
    Author:         Mark D. Connelly Jr.
    Last Updated:   <Date>
    Creation Date:  <Date>
    Purpose/Change: Initial script development
.LINK
    <Link to any relevant documentation>
.EXAMPLE
    Get-ExampleFunction -ExampleParameter "Example" -ExampleParameter2 "Example2" 
#>

Function Get-MDCApplicationToAADRoleMapping {
    [CmdletBinding()]
    Param (

    )

    $arrApplicationServicePrincipals = Get-MDCEnterpriseApplications
    $psobjAppToRoleMapping = @()
    foreach($app in $arrApplicationServicePrincipals){
        $appAADRoles = Get-MgServicePrincipalMemberOf -ServicePrincipalId $app.Id
        foreach($role in $appAADRoles){
            $memberOfODataType = ""
            $memberOfODataType = $role.AdditionalProperties.'@odata.type'
            if ($memberOfODataType -like "*directoryRole*") {
                $roleName = ""
                $roleName = $role.AdditionalProperties.displayName
                $psobjAppToRoleMapping += [pscustomobject]@{
                    DisplayName = $app.DisplayName
                    ServicePrincipal = $app.Id
                    AppId = $app.AppId
                    RoleName = $roleName
                    RoleId = $role.Id
                }
            }
        }

    }

    return $psobjAppToRoleMapping 
}