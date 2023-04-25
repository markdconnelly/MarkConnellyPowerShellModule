<#
.SYNOPSIS
    Get an array of groups granting AAD roles. Map them to their respective roles.
.DESCRIPTION
    This is a sub function of Get-MDCServicePrincipalToAADRoleMapping and Get-MDCUserToAADRoleMapping that produces a table output 
    of all groups that grant AAD roles. This group is used to determine inherited permissions for service principals and users.
.INPUTS
  None
.OUTPUTS
  $psobjGroupToRoleMapping
.NOTES
    This is a custom function written by Mark Connelly, so it may not work as intended.
    Version:        1.0
    Author:         Mark D. Connelly Jr.
    Last Updated:   04-24-2023
    Creation Date:  04-23-2023
    Purpose/Change: Initial script development
.LINK
    <Link to any relevant documentation>
.EXAMPLE
    Get-ExampleFunction -ExampleParameter "Example" -ExampleParameter2 "Example2" 
#>

Function Get-MDCGroupsGrantingAADRoles {
    [CmdletBinding()]
    Param (

    )

    # try to get all AAD roles
    try {
        $arrAAD_Roles = Get-MgDirectoryRole -ErrorAction Stop
    }
    catch {
        Write-Error "Unable to get AAD Roles"
        return
    }
    
    # Loop through each AAD role and collect the members. If the member is a group, populate the group mapping table. 
    $psobjGroupToRoleMapping = @()
    foreach($role in $arrAAD_Roles){
        $arrRoleMembers = Get-MgDirectoryRoleMember -DirectoryRoleId $role.Id -ErrorAction Stop
        foreach($member in $arrRoleMembers){
            $memberType = ""
            $memberType = $member.AdditionalProperties.'@odata.type'
            if($memberType -like "*group*"){
                $psobjGroupToRoleMapping += [PSCustomObject]@{
                    GroupID = $member.Id
                    GroupName = $member.AdditionalProperties.displayName
                    GroupDescription = $member.AdditionalProperties.description
                    RoleID = $role.Id
                    RoleName = $role.DisplayName
                    RoleDescription = $role.Description
                }
            }
    
        }
    }
    
    # Return the array of group mappings
    return $psobjGroupToRoleMapping
}