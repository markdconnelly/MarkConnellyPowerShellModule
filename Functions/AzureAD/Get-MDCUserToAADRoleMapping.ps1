<#
.SYNOPSIS
    Creates an Azure AD role mapping table for all users in the tenant. If a user is a member of a group that grants an
    AAD role, the details of the permissions along with the group in the table.
.DESCRIPTION
    This is a sub function of {TBD} that produces a table output of all user to AAD role mappings.
.INPUTS
  None
.OUTPUTS
  <Outputs if any, otherwise state None - example: Log file stored in C:\Windows\Temp\<name>.log>
.NOTES
    This is a custom function written by Mark Connelly, so it may not work as intended.
    Version:        1.0
    Author:         Mark D. Connelly Jr.
    Last Updated:   04-24-2023
    Creation Date:  04-24-2023
    Purpose/Change: Initial script development
.LINK
    https://github.com/markdconnelly/MarkConnellyPowerShellModule/blob/main/Functions/AzureAD/Get-MDCUserToAADRoleMapping.ps1
.EXAMPLE
    $array = Get-MDCUserToAADRoleMapping
#>

Function Get-MDCUserToAADRoleMapping {
    [CmdletBinding()]
    Param (

    )

    # Try to get all users
    try {
        $arrUsers = Get-MgUser -All:$true -ErrorAction Stop
    }
    catch {
        Write-Error "Unable to get users"
        return
    }

    $psobjUserToRoleMapping = @()
    $arrGroupToAADRoleMapping = Get-MDCGroupsGrantingAADRoles
    foreach($user in $arrUsers){
        try {
            $userAADRoles = Get-MgUserMemberOf -UserId $user.Id
        }
        catch {
            $objError = $_.Exception.Message
            Write-Verbose "Unable to get service principal membership for $($servicePrincipal.DisplayName)"
            Write-Error $objError
            continue
        }
        
        if($null -ne $userAADRoles){
            foreach($role in $userAADRoles){
                $memberOfODataType = ""
                $memberOfODataType = $role.AdditionalProperties.'@odata.type'
                $roleName = ""
                $roleName = $role.AdditionalProperties.displayName
                $roleDescription = ""
                $roleDescription = $role.AdditionalProperties.description
                if ($memberOfODataType -like "*directoryRole*") {
                    $psobjUserToRoleMapping += [pscustomobject]@{
                        ServicePrincipalType = "User"
                        DisplayName = $user.DisplayName
                        UserPrincipalName = $user.UserPrincipalName
                        UserId = $user.Id
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
                            $psobjUserToRoleMapping += [pscustomobject]@{
                                ServicePrincipalType = "User"
                                DisplayName = $user.DisplayName
                                UserPrincipalName = $user.UserPrincipalName
                                UserId = $user.Id
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

    # Return statement goes here
    return $psobjUserToRoleMapping
}