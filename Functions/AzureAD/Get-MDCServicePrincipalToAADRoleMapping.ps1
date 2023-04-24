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

Function Get-MDCServicePrincipalToAADRoleMapping {
    [CmdletBinding()]
    Param (

    )

    # Try to get service principals
    try {
        $arrServicePrincipals = Get-MgServicePrincipal -All:$true -ErrorAction Stop `
            | Where-Object {($_.ServicePrincipalType -eq "Application" -and $_.Tags -eq "WindowsAzureActiveDirectoryIntegratedApp") `
                         -or $_.ServicePrincipalType -eq "ManagedIdentity"}
    }
    catch {
        Write-Error "Unable to get service principals"
        return
    }

    $psobjServicePrincipalToRoleMapping = @()
    $arrGroupToAADRoleMapping = Get-GroupsGrantingAADRoles
    $arrGroupsGrantingRoles = $arrGroupToAADRoleMapping.GroupName
    foreach($servicePrincipal in $arrServicePrincipals){
        $servicePrincipalAADRoles = Get-MgServicePrincipalMemberOf -ServicePrincipalId $app.Id
        if($null -ne $servicePrincipalAADRoles){
            foreach($role in $servicePrincipalAADRoles){
                $memberOfODataType = ""
                $memberOfODataType = $role.AdditionalProperties.'@odata.type'
                $roleName = ""
                $roleName = $role.AdditionalProperties.displayName
                $roleDescription = ""
                $roleDescription = $role.AdditionalProperties.description
                if ($memberOfODataType -like "*directoryRole*") {
                    $psobjServicePrincipalToRoleMapping += [pscustomobject]@{
                        ServicePrincipalType = $servicePrincipal.ServicePrincipalType
                        DisplayName = $servicePrincipal.DisplayName
                        ServicePrincipal = $servicePrincipal.Id
                        AppId = $servicePrincipal.AppId
                        RoleName = $roleName
                        RoleDescription = $roleDescription
                        RoleId = $role.Id
                        viaGroupName = ""
                        viaGroupDescription = ""
                        viaGroupId = ""
                    }
                }
                if($memberOfODataType -like "*group*"){
                    if($roleName -contains $arrGroupsGrantingRoles){
                        $groupRoleMemberOf = $arrGroupToAADRoleMapping | Where-Object {$_.GroupName -eq $roleName}
                        foreach($groupRole in $groupRoleMemberOf){
                            $pause
                            $psobjServicePrincipalToRoleMapping += [pscustomobject]@{
                                ServicePrincipalType = $servicePrincipal.ServicePrincipalType
                                DisplayName = $servicePrincipal.DisplayName
                                ServicePrincipal = $servicePrincipal.Id
                                AppId = $servicePrincipal.AppId
                                RoleName = $groupRoleMemberOf.RoleName
                                RoleDescription = $groupRoleMemberOf.RoleDescription
                                RoleId = $groupRoleMemberOf.RoleID
                                viaGroupName = $groupRoleMemberOf.GroupName
                                viaGroupDescription = $groupRoleMemberOf.GroupDescription
                                viaGroupId = $groupRoleMemberOf.GroupID
                            }
                        }
                    }
                }
            }
        }
    }

    return $psobjServicePrincipalToRoleMapping
}