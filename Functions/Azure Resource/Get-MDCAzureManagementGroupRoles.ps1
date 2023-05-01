<#
.SYNOPSIS
    This function will produce a psobj with admins and their various permissions that are scoped to the management group.
.DESCRIPTION
    Identifying excessive admin permissions is the goal. This function will produce an array of permissions that are set at the management group tier.
.NOTES
    This is a custom function written by Mark Connelly, so it may not work as intended.
    Version:        1.0
    Author:         Mark D. Connelly Jr.
    Last Updated:   04-25-2023 - Mark Connelly
    Creation Date:  04-25-2023
    Purpose/Change: Initial script development
.LINK
    #
.EXAMPLE
    $array = Get-MDCAzureManagementGroupRoles
#>

Function Get-MDCAzureManagementGroupRoles {
    [CmdletBinding()]
    Param (

    )

    # Check the current connections to Azure and M365. If not connected, stop the function.
    $currentAzContext = Get-AzContext
    $currentMgContext = Get-MgContext
    if($null -eq $currentAzContext -or $null -eq $currentMgContext){
        Write-Error "Not connected to the cloud. Please connect to the cloud before running this function."
        return
    }
    
    #region Collect Azure Role Assignments at the Management Group Scope
    $arrAzureManagementGroups = @()

    # Try to collect management groups
    try {
        $arrAzureManagementGroups = Get-AzManagementGroup -ErrorAction Stop
        Write-Verbose "Management groups collected"
    }
    catch {
        Write-Error "Unable to retrieve Azure Management Groups. If there are no management groups, this is not an error."
    }
    
    # Loop through each management group and collect role assignments
    $psobjManagementGroupRoles = @()
    foreach($managementGroup in $arrAzureManagementGroups){
        $arrManagementGroupRoleAssignments = @()
        $arrManagementGroupRoleAssignments = Get-AzRoleAssignment -Scope $managementGroup.Id | Where-Object {$_.Scope -eq $managementGroup.Id}
        foreach($roleAssignment in $arrManagementGroupRoleAssignments){
            if($roleAssignment.ObjectType -like "*group*"){ #If role assignment is a group, get the members of the group
                $arrGroupMembers = @()
                $memberType = ""
                $memberType = "Group - $($roleAssignment.DisplayName)"
                try {
                    #try: Get-MgGroupMember
                    Write-Verbose "Collecting members of group $($roleAssignment.DisplayName)"
                    $arrGroupMembers = Get-MgGroupMember -GroupId $roleAssignment.ObjectId -ErrorAction Stop
                    foreach($groupMember in $arrGroupMembers){
                        # For each member, add a new object to the array
                        $groupMemberProperties = ""
                        $groupMemberProperties = $groupMember.AdditionalProperties
                        $memberName = ""
                        $memberName = $groupMemberProperties.displayName
                        $memberUPN = ""
                        $memberUPN = $groupMemberProperties.userPrincipalName
                        Write-Verbose "Creating entry for member $($groupMember.AdditionalProperties.userPrincipalName)"
                        $psobjManagementGroupRoles += [PSCustomObject]@{
                            RoleType = "Azure"
                            Scope = "Management Group"
                            ResourceId = $managementGroup.Id
                            ResourceName = $managementGroup.DisplayName
                            ResourceType = "Management Group"
                            RoleName = $roleAssignment.RoleDefinitionName
                            MemberName = $memberName
                            MemberType = $memberType
                            MemberUpnOrAppId = $memberUPN
                            MemberObjId = $roleAssignment.ObjectId
                        }
                    }
                }
                catch {
                    #catch: Get-MgGroupMember
                    $objError = $Error[0].Exception.Message
                    Write-Host "Unable to get members of group $($roleAssignment.DisplayName)" -BackgroundColor Black -ForegroundColor Red
                    Write-Host $objError -BackgroundColor Black -ForegroundColor Red
                    Write-Verbose "Unable to resolve group members. Creating entry for $($roleAssignment.DisplayName)"
                    $psobjManagementGroupRoles += [PSCustomObject]@{
                        RoleType = "Azure"
                        Scope = "Management Group"
                        ResourceId = $managementGroup.Id
                        ResourceName = $managementGroup.DisplayName
                        ResourceType = "Management Group"
                        RoleName = $roleAssignment.RoleDefinitionName
                        MemberName = $roleAssignment.DisplayName
                        MemberType = $roleAssignment.ObjectType
                        MemberUpnOrAppId = "Unable to resolve members"
                        MemberObjId = $roleAssignment.ObjectId
                    }
                }
            }else{ 
                if($roleAssignment.ObjectType -like "*serviceprincipal*"){
                    Write-Verbose "Service Principal assignment. Creating entry for $($roleAssignment.ObjectId)"
                    try {
                        $servicePrincipal = @()
                        $servicePrincipal = Get-MgServicePrincipal -ServicePrincipalId $roleAssignment.ObjectId -ErrorAction Stop
                        $servicePrincipalDisplayName = $servicePrincipal.DisplayName
                        $servicePrinipalAppId = $servicePrincipal.AppId
                    }
                    catch {
                        Write-Verbose "Unable to get display name for service principal object id:$($roleAssignment.ObjectId)"
                    }
                    $psobjManagementGroupRoles += [PSCustomObject]@{
                        RoleType = "Azure"
                        Scope = "Management Group"
                        ResourceId = $managementGroup.Id
                        ResourceType = "Management Group"
                        ResourceName = $managementGroup.DisplayName
                        RoleName = $roleAssignment.RoleDefinitionName
                        MemberName = $servicePrincipalDisplayName
                        MemberType = $roleAssignment.ObjectType
                        MemberUpnOrAppId = $servicePrinipalAppId
                        MemberObjId = $roleAssignment.ObjectId
                    }
                }else{
                    #If role assignment is a user, proceed as normal
                    Write-Verbose "Standard user assignment. Creating entry for $($roleAssignment.DisplayName)"
                    $psobjManagementGroupRoles += [PSCustomObject]@{
                        RoleType = "Azure"
                        Scope = "Management Group"
                        ResourceId = $managementGroup.Id
                        ResourceType = "Management Group"
                        ResourceName = $managementGroup.DisplayName
                        RoleName = $roleAssignment.RoleDefinitionName
                        MemberName = $roleAssignment.DisplayName
                        MemberType = $roleAssignment.ObjectType
                        MemberUpnOrAppId = $roleAssignment.SignInName
                        MemberObjId = $roleAssignment.ObjectId
                    }
                }
            }
        }
    }
    return $psobjManagementGroupRoles
}