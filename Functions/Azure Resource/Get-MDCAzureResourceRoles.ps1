<#
.SYNOPSIS
    This function will produce a psobj with admins and their various permissions that are scoped to the resource specifically.
.DESCRIPTION
    Identifying excessive admin permissions is the goal. This function will produce an array of permissions that are set at the resource specifically.
.NOTES
    This is a custom function written by Mark Connelly, so it may not work as intended.
    Version:        1.0
    Author:         Mark D. Connelly Jr.
    Last Updated:   04-27-2023 - Mark Connelly
    Creation Date:  04-24-2023
    Purpose/Change: Initial script development
.LINK
    #
.EXAMPLE
    $array = Get-MDCAzureResourceRoles
#>

Function Get-MDCAzureResourceRoles {
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

    $arrAzureSubscriptions = @()
    $arrAzureResources = @()

    # Try to get Azure subscriptions and build an array of resources. If unable to get subscriptions, stop the function.
    try {
        $arrAzureSubscriptions = Get-AzSubscription -ErrorAction Stop
        Write-Verbose "Subscriptions collected"
        foreach($sub in $arrAzureSubscriptions){
            Set-AzContext -SubscriptionId $sub.Id | Out-Null
            Write-Verbose "Context set to subscription $($sub.DisplayName)"
            $arrAzureResources += Get-AzResourceGroup
            Write-Verbose "Resources collected for subscription $($sub.DisplayName)"
        }
        Write-Verbose "Array of resources populated"
    }
    catch {
        $objError = $Error[0].Exception.Message
        Write-Host "Unable to retrieve Azure Subscriptions. Stopping..." -BackgroundColor Black -ForegroundColor Red
        Write-Host $objError -BackgroundColor Black -ForegroundColor Red
        return
    }

    $psobjResourceRoles = @()
    # Loop through each resource and collect role assignments
    foreach($resource in $arrAzureResources){
        Write-Verbose "Processing resource group $($resource.ResourceGroupName)"
        $arrResourceRoleAssignments = @()
        $arrResourceRoleAssignments = Get-AzRoleAssignment -ResourceGroupName $resource.ResourceGroupName | Where-Object {$_.Scope -like "*/$($resource.Name)"}
        foreach($roleAssignment in $arrResourceRoleAssignments){
            Write-Verbose "Processing role assignment for $($roleAssignment.DisplayName) in resource group $($resource.ResourceGroupName)"
            $memberType = ""
            $memberType = $roleAssignment.ObjectType
            switch($memberType){
                {$_ -like "*user*"}{
                    #If role assignment is a user, extract user properties and add a new object to the array
                    Write-Verbose "Standard user assignment. Creating entry for $($roleAssignment.DisplayName)"
                    $psobjResourceRoles += [PSCustomObject]@{
                        RoleType = "Azure"
                        Scope = "Resource Group"
                        ResourceId = $resource.ResourceId
                        ResourceType = $resource.ResourceType
                        ResourceName = $resource.ResourceGroupName
                        RoleName = $roleAssignment.RoleDefinitionName
                        MemberName = $roleAssignment.DisplayName
                        MemberType = $memberType
                        MemberUpnOrAppId = $roleAssignment.SignInName
                        MemberObjId = $roleAssignment.ObjectId
                    }
                }
                {$_ -like "*serviceprincipal*"}{
                    #If role assignment is a service principal, extract the service principal properties and add a new object to the array
                    Write-Verbose "Service Principal assignment. Creating entry for $($roleAssignment.ObjectId)"
                    try {
                        $servicePrincipal = @()
                        $servicePrincipal = Get-MgServicePrincipal -ServicePrincipalId $roleAssignment.ObjectId -ErrorAction Stop
                        $servicePrincipalDisplayName = $servicePrincipal.DisplayName
                        $servicePrinipalAppId = $servicePrincipal.AppId
                    }
                    catch {
                        Write-Verbose "Unable to get display name for service principal object id:$($roleAssignment.ObjectId)"
                        $servicePrincipalDisplayName = "Name resolution error for object id:$($roleAssignment.ObjectId)"
                    }
                    $psobjResourceRoles += [PSCustomObject]@{
                        RoleType = "Azure"
                        Scope = "Resource"
                        ResourceId = $resource.ResourceId
                        ResourceType = $resource.ResourceType
                        ResourceName = $resource.ResourceGroupName
                        RoleName = $roleAssignment.RoleDefinitionName
                        MemberName = $servicePrincipalDisplayName
                        MemberType = $memberType
                        MemberUpnOrAppId = $servicePrinipalAppId
                        MemberObjId = $roleAssignment.ObjectId
                    }
                }
                {$_ -like "*group*"}{
                    #If role assignment is a group, loop through each member and create an entry with their properties in the array and add it to the object
                    Write-Verbose "Group assignment. Getting members for $($roleAssignment.DisplayName)"
                    $arrGroupMembers = @()
                    $memberType = "Group - $($roleAssignment.DisplayName)"

                    # try to get group members
                    try {
                        Write-Verbose "Collecting members of group $($roleAssignment.DisplayName)"
                        $arrGroupMembers = Get-MgGroupTransitiveMember -GroupId $roleAssignment.ObjectId -ErrorAction Stop
                        $groupMember = ""
                        # if you can get the group members, loop through each member, evaluate what type of object it is, and add a record to the array
                        foreach($groupMember in $arrGroupMembers){
                            $groupMemberProperties = ""
                            $groupMemberProperties = $groupMember.AdditionalProperties
                            $memberType = ""
                            $memberType = $groupMemberProperties.'@odata.type'
                            $memberName = $groupMemberProperties.displayName
                            $memberUPN = ""
                            $memberUPN = $groupMemberProperties.userPrincipalName
                            switch($memberType){
                                {$_ -like "*user*"}{
                                    Write-Verbose "Creating user entry for member $memberUPN"
                                    $psobjResourceRoles += [PSCustomObject]@{
                                        RoleType = "Azure"
                                        Scope = "Resource"
                                        ResourceId = $resource.ResourceId
                                        ResourceName = $resource.ResourceGroupName
                                        ResourceType = $resource.ResourceType
                                        RoleName = $roleAssignment.RoleDefinitionName
                                        MemberName = $memberName
                                        MemberType = "User"
                                        MemberUpnOrAppId = $memberUPN
                                        MemberObjId = $roleAssignment.ObjectId
                                    }
                                }
                                {$_ -like "*group*"}{
                                    Write-Verbose "Creating group entry for member $memberName"
                                    $psobjResourceRoles += [PSCustomObject]@{
                                        RoleType = "Azure"
                                        Scope = "Resource"
                                        ResourceId = $resource.ResourceId
                                        ResourceName = $resource.ResourceGroupName
                                        ResourceType = $resource.ResourceType
                                        RoleName = $roleAssignment.RoleDefinitionName
                                        MemberName = $memberName
                                        MemberType = "Group"
                                        MemberUpnOrAppId = $memberName
                                        MemberObjId = $roleAssignment.ObjectId
                                    }
                                }
                            }
                        }
                    }
                    catch {
                        Write-Verbose "Unable to get members of group $($roleAssignment.DisplayName)"
                        Write-Verbose "Creating entry for group $($roleAssignment.DisplayName)"
                        $psobjResourceRoles += [PSCustomObject]@{
                            RoleType = "Azure"
                            Scope = "Resource"
                            ResourceId = $resource.ResourceId
                            ResourceName = $resource.ResourceGroupName
                            ResourceType = $resource.ResourceType
                            RoleName = $roleAssignment.RoleDefinitionName
                            MemberName = $roleAssignment.DisplayName
                            MemberType = "Group - Unable to get members"
                            MemberUpnOrAppId = $roleAssignment.SignInName
                            MemberObjId = $roleAssignment.ObjectId
                        }
                    }
                }
                {$_ -like "*unknown*"}{
                    Write-Verbose "Unknown assignment. Creating entry for $($roleAssignment.ObjectId)"
                    $psobjResourceRoles += [PSCustomObject]@{
                        RoleType = "Azure"
                        Scope = "Resource"
                        ResourceId = $resource.ResourceId
                        ResourceName = $resource.ResourceGroupName
                        ResourceType = $resource.ResourceType
                        RoleName = $roleAssignment.RoleDefinitionName
                        MemberName = $roleAssignment.DisplayName
                        MemberType = "Unknown"
                        MemberUpnOrAppId = $roleAssignment.SignInName
                        MemberObjId = $roleAssignment.ObjectId
                    }
                }
            }
        }
    }
    # Return the array of permissions and details
    Write-Verbose "Operation Completed. Returning array of permissions"
    return $psobjResourceRoles
}