<#
.SYNOPSIS
    Creates an Azure AD role mapping table for all applications in the tenant. If a service principal is a member of a group that grants an 
    AAD role, the details of the permissions along with the group in the table.
.DESCRIPTION
    This is a sub function of {TBD} that produces a table output of all service principal to AAD role mappings.
.INPUTS
  None
.OUTPUTS
  $psobjServicePrincipalToRoleMapping
.NOTES
    This is a custom function written by Mark Connelly, so it may not work as intended.
    Version:        1.1
    Author:         Mark D. Connelly Jr.
    Last Updated:   04-24-2023
    Creation Date:  04-23-2023
    Purpose/Change: Initial script development
.LINK
    https://github.com/markdconnelly/MarkConnellyPowerShellModule/blob/main/Functions/AzureAD/Get-MDCServicePrincipalToAADRoleMapping.ps1
.EXAMPLE
    $array = Get-MDCServicePrincipalToAADRoleMapping 
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
                    foreach($group in $arrGroupToAADRoleMapping){
                        if($group.GroupName -eq $roleName){
                            $psobjServicePrincipalToRoleMapping += [pscustomobject]@{
                                ServicePrincipalType = $servicePrincipal.ServicePrincipalType
                                DisplayName = $servicePrincipal.DisplayName
                                ServicePrincipal = $servicePrincipal.Id
                                AppId = $servicePrincipal.AppId
                                RoleName = $group.RoleName
                                RoleDescription = $group.RoleDescription
                                RoleId = $group.RoleID
                                viaGroupName = $group.GroupName
                                viaGroupDescription = $group.GroupDescription
                                viaGroupId = $group.GroupID
                            }
                        }
                    }
                }
            }
        }
    }
    return $psobjServicePrincipalToRoleMapping
}