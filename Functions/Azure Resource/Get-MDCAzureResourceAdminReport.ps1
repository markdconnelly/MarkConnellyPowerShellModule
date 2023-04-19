<#
.SYNOPSIS
    This function will produce a psobj with admins and their various permissions. f a tenant's conditional access policies. If an export path parameter is provided, the function will export the results to a csv file.
.DESCRIPTION
    Identifying excessive admin permissions is the goal. This report will provide the information that you need to identify and remediate excessive permissions in the Azure Resource Manager.
.NOTES
    This is a custom function written by Mark Connelly, so it may not work as intended.
    Version:        1.0
    Author:         Mark D. Connelly Jr.
    Creation Date:  04-18-2023
    Purpose/Change: Initial script development
.LINK
    https://github.com/markdconnelly/MarkConnellyPowerShellModule/blob/main/Functions/AzureAD/ConditionalAccess/Get-MDCConditionalAccessExecutiveSummary.ps1
.EXAMPLE
    Get-MDCAzureResourceAdminReport
    Get-MDCAzureResourceAdminReport -ExportPath "C:\Temp\"
    Get-MDCAzureResourceAdminReport -ExportPath "C:\Temp\" -ProductionEnvironment $true
#>

Function Get-MDCAzureResourceAdminReport {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$false,Position=0)]
        [string]$ExportPath,
        [Parameter(Mandatory=$false,Position=1)]
        [bool]$ProductionEnvironment = $false
    )

    #region Connect to the Azure Resource Manager
    try {
        Write-Verbose "Connecting to the Azure Resource Manager"
        Connect-MDCAzApplication -ProductionEnvironment $ProductionEnvironment -ErrorAction Stop
    }
    catch {
        Write-Verbose "Unable to connect to the Azure Resource Manager"
        throw "Unable to connect to the Azure Resource Manager"
    }#endregion

    #region Collect Azure Role Assignments at the Management Group Scope
    $arrAzureManagementGroups = @()

    # Try to collect management groups
    try {
        $arrAzureManagementGroups = Get-AzManagementGroup -ErrorAction Stop
    }
    catch {
        Write-Verbose $Error[0].Exception.Message
        Write-Verbose "Unable to retrieve Azure Management Groups"
    }
    
    # Loop through each management group and collect role assignments
    foreach($managementGroup in $arrAzureManagementGroups){
        $arrManagementGroupRoleAssignments = @()
        $arrManagementGroupRoleAssignments = Get-AzRoleAssignment -Scope $managementGroup.GroupId | Where-Object {$_.Scope -eq $managementGroup.GroupId}
        foreach($roleAssignment in $arrManagementGroupRoleAssignments){
            if($roleAssignment.ObjectType -like "*group*"){ #If role assignment is a group, get the members of the group
                Write-Verbose "$($roleAssignment.DisplayName) is a group"
                $arrGroupMembers = @()
                try {
                    #try: Get-MgGroupMember
                    Write-Verbose "Collecting members of group $($roleAssignment.DisplayName)"
                    $arrGroupMembers = Get-MgGroupMember -GroupId $roleAssignment.ObjectId -ErrorAction Stop
                    $groupMember = ""
                    foreach($groupMember in $arrGroupMembers){
                        # For each member, add a new object to the array
                        $psobjRoles += [PSCustomObject]@{
                            RoleType = "Azure"
                            Scope = "Management Group"
                            ResourceId = $managementGroup.GroupId
                            ResourceName = $managementGroup.DisplayName
                            ResourceType = "Management Group"
                            RoleName = $roleAssignment.RoleDefinitionName
                            MemberName = $groupMember.AdditionalProperties.userPrincipalName
                            MemberType = "Group - $($roleAssignment.DisplayName)"
                            MemberUpn = $groupMember.AdditionalProperties.userPrincipalName
                            MemberObjId = $roleAssignment.ObjectId
                        }
                        $pause = ""
                    }
                }
                catch {
                    #catch: Get-MgGroupMember
                    Write-Verbose "Unable to get members of group $($roleAssignment.DisplayName)"
                }
            }else{ #If role assignment is a user, proceed as normal
                $psobjRoles += [PSCustomObject]@{
                    RoleType = "Azure"
                    Scope = "Management Group"
                    ResourceId = $managementGroup.GroupId
                    ResourceName = $managementGroup.DisplayName
                    ResourceType = "Management Group"
                    RoleName = $roleAssignment.RoleDefinitionName
                    MemberName = $roleAssignment.DisplayName
                    MemberType = $roleAssignment.ObjectType
                    MemberUpn = $roleAssignment.SignInName
                    MemberObjId = $roleAssignment.ObjectId
                }
            }
        }
    }#endregion

    #region Collect Azure Role Assignments at the Subscription Scope
    $arrAzureSubscriptions = @()

    # Try to collect subscriptions. End if error encountered.
    try {
        $arrAzureSubscriptions = Get-AzSubscription -ErrorAction Stop
    }
    catch {
        Write-Host $Error[0].Exception.Message
        Write-Host "Unable to retrieve Azure Subscriptions. Stopping..."
        return
    }

    # Loop through each subscription and collect role assignments
    foreach($sub in $arrAzureSubscriptions){
        
        # Set the context to the subscription before running the loop algorithm
        Set-AzContext -SubscriptionId $sub.Id

        # Collect role assignments at the subscription scope
        $arrRoleAssignments = @()
        $arrRoleAssignments = Get-AzRoleAssignment | Where-Object {$_.Scope -eq "/subscriptions/$($sub.Id)"}
        foreach($roleAssignment in $arrRoleAssignments){
            if ($roleAssignment.ObjectType -like "*group*") { #If role assignment is a group, get the members of the group
                Write-Verbose "$($role.DisplayName) is a group"
                $arrGroupMembers = @()
                try {
                    #try: Get-MgGroupMember
                    Write-Verbose "Collecting members of group $($roleAssignment.DisplayName)"
                    $arrGroupMembers = Get-MgGroupMember -GroupId $roleAssignment.ObjectId -ErrorAction Stop
                    $groupMember = ""
                    foreach($groupMember in $arrGroupMembers){
                        # For each member, add a new object to the array
                        $psobjRoles += [PSCustomObject]@{
                            RoleType = "Azure"
                            Scope = "Subscription"
                            ResourceId = $sub.Id
                            ResourceName = $sub.Name
                            ResourceType = "Subscription"
                            RoleName = $roleAssignment.RoleDefinitionName
                            MemberName = $groupMember.AdditionalProperties.userPrincipalName
                            MemberType = "Group - $($roleAssignment.DisplayName)"
                            MemberUpn = $groupMember.AdditionalProperties.userPrincipalName
                            MemberObjId = $roleAssignment.ObjectId
                        }
                        $pause = ""
                    }
                }
                Catch{
                    #catch: Get-MgGroupMember
                    Write-Verbose "Unable to get members of group $($roleAssignment.DisplayName)"
                }
            }else{ #If role assignment is a user, proceed as normal
                $psobjRoles += [PSCustomObject]@{
                    RoleType = "Azure"
                    Scope = "Subscription"
                    ResourceId = $sub.Id
                    ResourceType = "Subscription"
                    ResourceName = $sub.Name
                    RoleName = $roleAssignment.RoleDefinitionName
                    MemberName = $roleAssignment.DisplayName
                    MemberType = $roleAssignment.ObjectType
                    MemberUpn = $roleAssignment.SignInName
                    MemberObjId = $roleAssignment.ObjectId
                }
            }
        }
        $intProgress++
    }#endregion

    #region Collect Azure Role Assignments at the Resource Group Scope
    $arrAzureResourceGroups = @()

    # Loop through each subscription and collect an array of resource groups
    foreach($sub in $arrAzureSubscriptions){
        Set-AzContext -SubscriptionId $sub.Id
        $arrAzureResourceGroups += Get-AzResourceGroup
    }

    # Loop through each resource group and collect role assignments
    foreach($rg in $arrAzureResourceGroups){
        $arrRoleAssignments = @()
        $arrRoleAssignments = Get-AzRoleAssignment -ResourceGroupName $rg.ResourceGroupName | Where-Object {$_.Scope -like "*resourceGroups/$($rg.ResourceGroupName)"}
        foreach($roleAssignment in $arrRoleAssignments){
            if($roleAssignment.ObjectType -like "*group*"){ #If role assignment is a group, get the members of the group
                Write-Verbose "$($roleAssignment.DisplayName) is a group"
                $arrGroupMembers = @()
                try {
                    #try: Get-MgGroupMember
                    Write-Verbose "Collecting members of group $($roleAssignment.DisplayName)"
                    $arrGroupMembers = Get-MgGroupMember -GroupId $roleAssignment.ObjectId -ErrorAction Stop
                    $groupMember = ""
                    foreach($groupMember in $arrGroupMembers){
                        # For each member, add a new object to the array
                        $psobjRoles += [PSCustomObject]@{
                            RoleType = "Azure"
                            Scope = "Resource Group"
                            ResourceId = $rg.ResourceId
                            ResourceName = $rg.ResourceGroupName
                            ResourceType = "Resource Group"
                            RoleName = $roleAssignment.RoleDefinitionName
                            MemberName = $groupMember.AdditionalProperties.userPrincipalName
                            MemberType = "Group - $($roleAssignment.DisplayName)"
                            MemberUpn = $groupMember.AdditionalProperties.userPrincipalName
                            MemberObjId = $roleAssignment.ObjectId
                        }
                        $pause = ""
                    }
                }
                catch {
                    #catch: Get-MgGroupMember
                    Write-Verbose "Unable to get members of group $($roleAssignment.DisplayName)"
                }
            }else{ #If role assignment is a user, proceed as normal
                $psobjRoles += [PSCustomObject]@{
                    RoleType = "Azure"
                    Scope = "Resource Group"
                    ResourceId = $rg.ResourceId
                    ResourceName = $rg.ResourceGroupName
                    ResourceType = "Resource Group"
                    RoleName = $roleAssignment.RoleDefinitionName
                    MemberName = $roleAssignment.DisplayName
                    MemberType = $roleAssignment.ObjectType
                    MemberUpn = $roleAssignment.SignInName
                    MemberObjId = $roleAssignment.ObjectId
                }
            }
        }
        $intProgress++
    }#endregion

    #region Collect Azure Role Assignments at the Resource Scope
    $arrAzureResources = @()

    # Loop through each subscription and collect an array of resources
    foreach($sub in $arrAzureSubscriptions){
        Set-AzContext -SubscriptionId $sub.Id
        $arrAzureResources += Get-AzResource
    }

    # Loop through each resource and collect role assignments
    foreach($resource in $arrAzureResources){
        $arrRoleAssignments = @()
        $arrRoleAssignments = Get-AzRoleAssignment -Scope $resource.ResourceId | Where-Object {$_.Scope -like "*/$($resource.Name)"}
        foreach($roleAssignment in $arrRoleAssignments){
            if($roleAssignment.ObjectType -like "*group*"){ #If role assignment is a group, get the members of the group
                Write-Verbose "$($roleAssignment.DisplayName) is a group"
                $arrGroupMembers = @()
                try{
                    #try: Get-MgGroupMember
                    Write-Verbose "Collecting members of group $($roleAssignment.DisplayName)"
                    $arrGroupMembers = Get-MgGroupMember -GroupId $roleAssignment.ObjectId -ErrorAction Stop
                    $groupMember = ""
                    foreach($groupMember in $arrGroupMembers){
                        # For each member, add a new object to the array
                        $psobjRoles += [PSCustomObject]@{
                            RoleType = "Azure"
                            Scope = "Resource"
                            ResourceId = $resource.ResourceId
                            ResourceName = $resource.ResourceName
                            ResourceType = $resource.ResourceType
                            RoleName = $roleAssignment.RoleDefinitionName
                            MemberName = $groupMember.AdditionalProperties.userPrincipalName
                            MemberType = "Group - $($roleAssignment.DisplayName)"
                            MemberUpn = $groupMember.AdditionalProperties.userPrincipalName
                            MemberObjId = $roleAssignment.ObjectId
                        }
                        $pause = ""
                    }
                }catch{
                    #catch: Get-MgGroupMember
                    Write-Verbose "Unable to get members of group $($roleAssignment.DisplayName)"
                }
            }else{ #If role assignment is a user, proceed as normal
                $psobjRoles += [PSCustomObject]@{
                    RoleType = "Azure"
                    Scope = "Resource"
                    ResourceId = $resource.ResourceId
                    ResourceName = $resource.ResourceName
                    ResourceType = $resource.ResourceType
                    RoleName = $role.RoleDefinitionName
                    MemberName = $role.DisplayName
                    MemberType = $role.ObjectType
                    MemberUpn = $role.SignInName
                    MemberObjId = $role.ObjectId
                }
            }
        }
        $intProgress++
    }#endregion

    # Return the array of permissions and details
    return $psobjAzureResourceAdminReport
}

Get-MDCAzureResourceAdminReport -Verbose