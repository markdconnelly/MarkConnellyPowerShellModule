<#
.SYNOPSIS
    This function will produce a psobj with admins and their various permissions that are scoped to the management group.
.DESCRIPTION
    Identifying excessive admin permissions is the goal. This function will produce an array of permissions that are set at the management group tier.
.NOTES
    This is a custom function written by Mark Connelly, so it may not work as intended.
    Version:        1.0
    Author:         Mark D. Connelly Jr.
    Last Updated:   05-01-2023 - Mark Connelly
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
    if($null -eq $currentAzContext){
        Write-Error "Not connected to the Azure Resource Manager. Please connect before running this function."
        return
    }
    if($null -eq $currentMgContext){
        Write-Error "Not connected to the Microsoft Graph. Please connect before running this function."
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
        
        $mgId = ""
        $mgType = ""
        $mgName = ""
        $mgId = $managementGroup.Id
        $mgType = "Management Group"
        $mgName = $managementGroup.DisplayName
        Write-Verbose "Processing management group $mgName"
        $arrManagementGroupRoleAssignments = @()
        $arrManagementGroupRoleAssignments = Get-AzRoleAssignment -Scope $managementGroup.Id | Where-Object {$_.Scope -eq $managementGroup.Id}
        foreach($roleAssignment in $arrManagementGroupRoleAssignments){
            $roleAssignmentDisplayName = ""
            $roleAssignmentDisplayName = $roleAssignment.DisplayName
            $roleAssignmentObjectId = ""
            $roleAssignmentObjectId = $roleAssignment.ObjectId
            $memberType = ""
            $memberType = $roleAssignment.ObjectType
            switch ($memberType) {
                {$_ -like "*user*"}{
                    #If role assignment is a user, extract user properties and add a new object to the array
                    Write-Verbose "Standard user assignment. Creating entry for $roleAssignmentDisplayName"
                    $psobjManagementGroupRoles += [PSCustomObject]@{
                        RoleType = "Azure"
                        Scope = "Management Group"
                        ResourceId = $mgId
                        ResourceName = $mgName
                        ResourceType = $mgType
                        RoleName = $roleAssignment.RoleDefinitionName
                        MemberName = $roleAssignmentDisplayName
                        MemberType = "User"
                        MemberUpnOrAppId = $roleAssignment.SignInName
                        MemberObjId = $roleAssignmentObjectId
                    }
                    ;Break
                }
                {$_ -like "*serviceprincipal*"}{
                    #If role assignment is a service principal, extract the service principal properties and add a new object to the array
                    Write-Verbose "Service Principal assignment. Creating entry for $roleAssignmentObjectId"
                    try {
                        $servicePrincipal = @()
                        $servicePrincipalDisplayName = ""
                        $servicePrinipalAppId = ""
                        $servicePrincipal = Get-MgServicePrincipal -ServicePrincipalId $roleAssignmentObjectId -ErrorAction Stop
                        $servicePrincipalDisplayName = $servicePrincipal.DisplayName
                        $servicePrinipalAppId = $servicePrincipal.AppId
                    }
                    catch {
                        Write-Verbose "Unable to get display name for service principal object id:$roleAssignmentObjectId"
                        $servicePrincipalDisplayName = "Name resolution error for object id:$roleAssignmentObjectId"
                    }
                    $psobjManagementGroupRoles += [PSCustomObject]@{
                        RoleType = "Azure"
                        Scope = "Management Group"
                        ResourceId = $mgId
                        ResourceName = $mgName
                        ResourceType = $mgType
                        RoleName = $roleAssignment.RoleDefinitionName
                        MemberName = $servicePrincipalDisplayName
                        MemberType = "Service Principal"
                        MemberUpnOrAppId = $servicePrinipalAppId
                        MemberObjId = $roleAssignmentObjectId
                    }
                    ;Break
                }
                {$_ -like "*group*"}{
                    #If role assignment is a group, loop through each member and create an entry with their properties in the array and add it to the object
                    Write-Verbose "Group assignment. Getting members for $roleAssignmentDisplayName"
                    $arrGroupMembers = @()
                    $viaGroupName = "Group - $roleAssignmentDisplayName"
                    # try to get group members
                    try {
                        Write-Verbose "Collecting members of group $roleAssignmentDisplayName"
                        $arrGroupMembers = Get-MgGroupTransitiveMember -GroupId $roleAssignmentObjectId -ErrorAction Stop
                        $groupMember = "" 
                                                # if you can get the group members, loop through each member, evaluate what type of object it is, and add a record to the array
                                                foreach($groupMember in $arrGroupMembers){
                                                    $groupMemberProperties = ""
                                                    $groupMemberProperties = $groupMember.AdditionalProperties
                                                    $memberName = ""
                                                    $memberUPN = ""
                                                    $memberType = ""
                                                    $memberObjId = ""
                                                    $memberName = $groupMemberProperties.displayName
                                                    $memberType = $groupMemberProperties.'@odata.type'
                                                    $memberUPN = $groupMemberProperties.userPrincipalName
                                                    $memberObjId = $groupMemberProperties.id
                                                    switch($memberType){
                                                        {$_ -like "*user*"}{
                                                            Write-Verbose "Creating user entry for member $memberUPN"
                                                            $psobjManagementGroupRoles += [PSCustomObject]@{
                                                                RoleType = "Azure"
                                                                Scope = "Management Group"
                                                                ResourceId = $mgId
                                                                ResourceName = $mgName
                                                                ResourceType = $mgType
                                                                RoleName = $roleAssignment.RoleDefinitionName
                                                                MemberName = $memberName
                                                                MemberType = $viaGroupName
                                                                MemberUpnOrAppId = $memberUPN
                                                                MemberObjId = $roleAssignmentObjectId
                                                            }
                                                            ;Break
                                                        }
                                                        {$_ -like "*group*"}{
                                                            Write-Verbose "Creating group entry for member $memberName"
                                                            $psobjManagementGroupRoles += [PSCustomObject]@{
                                                                RoleType = "Azure"
                                                                Scope = "Management Group"
                                                                ResourceId = $mgId
                                                                ResourceName = $mgName
                                                                ResourceType = $mgType
                                                                RoleName = $roleAssignment.RoleDefinitionName
                                                                MemberName = $memberName
                                                                MemberType = $viaGroupName
                                                                MemberUpnOrAppId = $memberName
                                                                MemberObjId = $memberObjId
                                                            }
                                                            ;Break
                                                        }
                                                    }
                                                }
                    }
                    catch {
                        Write-Verbose "Unable to get members of group $roleAssignmentDisplayName"
                        Write-Verbose "Creating entry for group $roleAssignmentDisplayName"
                        $psobjManagementGroupRoles += [PSCustomObject]@{
                            RoleType = "Azure"
                            Scope = "Management Group"
                            ResourceId = $mgId
                            ResourceName = $mgName
                            ResourceType = $mgType
                            RoleName = $roleAssignment.RoleDefinitionName
                            MemberName = $roleAssignmentDisplayName
                            MemberType = "Group - Unable to get members"
                            MemberUpnOrAppId = $roleAssignment.SignInName
                            MemberObjId = $roleAssignmentObjectId
                        }
                    }
                    ;Break
                }
                {$_ -like "*unknown*"}{
                    Write-Verbose "Unknown assignment. Creating entry for $roleAssignmentObjectId"
                    $psobjManagementGroupRoles += [PSCustomObject]@{
                        RoleType = "Azure"
                        Scope = "Management Group"
                        ResourceId = $mgId
                        ResourceName = $mgName
                        ResourceType = "Management Group"
                        RoleName = $roleAssignment.RoleDefinitionName
                        MemberName = $memberName
                        MemberType = $memberType
                        MemberUpnOrAppId = $memberUPN
                        MemberObjId = $roleAssignment.ObjectId
                    }
                    ;Break
                }
            }
        }
    }
    return $psobjManagementGroupRoles
}