<#
.SYNOPSIS
    This function will produce a psobj with admins and their various permissions that are scoped to the resource group tier.
.DESCRIPTION
    Identifying excessive admin permissions is the goal. This function will produce an array of permissions that are set at the resource group tier.
.NOTES
    This is a custom function written by Mark Connelly, so it may not work as intended.
    Version:        1.0
    Author:         Mark D. Connelly Jr.
    Last Updated:   04-28-2023 - Mark Connelly
    Creation Date:  04-24-2023
    Purpose/Change: Updated logic to use switch statements instead of if statements. Added additional comments and corrected verbose logging.
.LINK
    #
.EXAMPLE
    $array = Get-MDCAzureResourceGroupRoles
#>

Function Get-MDCAzureResourceGroupRoles {
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

    $arrAzureSubscriptions = @()
    $arrAzureResourceGroups = @()

    # Try to get Azure subscriptions and build an array of resource groups. If unable to get subscriptions, stop the function.
    try {
        $arrAzureSubscriptions = Get-AzSubscription -ErrorAction Stop
        Write-Verbose "Subscriptions collected"
        foreach($sub in $arrAzureSubscriptions){
            Set-AzContext -SubscriptionId $sub.Id | Out-Null
            Write-Verbose "Context set to subscription $($sub.DisplayName)"
            $arrAzureResourceGroups += Get-AzResourceGroup -ErrorAction SilentlyContinue
            Write-Verbose "Resource groups collected for subscription $($sub.DisplayName)"
        }
        Write-Verbose "Array of resource groups populated"
    }
    catch {
        $objError = $Error[0].Exception.Message
        Write-Host "Unable to retrieve Azure Subscriptions. Stopping..." -BackgroundColor Black -ForegroundColor Red
        Write-Host $objError -BackgroundColor Black -ForegroundColor Red
        return
    }

    $psobjResourceGroupRoles = @()
    # Loop through each resource group and collect role assignments
    foreach($rg in $arrAzureResourceGroups){
        $resourceId = ""
        $resourceType = ""
        $resourceName = ""
        $resourceId = $rg.ResourceId #check to see if this is accurate
        $resourceType = "Resource Group"
        $resourceName = $rg.ResourceGroupName     
        Write-Verbose "Processing resource group $resourceName"
        $arrResourceGroupRoleAssignments = @()
        $arrResourceGroupRoleAssignments = Get-AzRoleAssignment -ResourceGroupName $rg.ResourceGroupName | Where-Object {$_.Scope -like "*resourceGroups/$($rg.ResourceGroupName)"}
        foreach($roleAssignment in $arrResourceGroupRoleAssignments){
            $roleAssignmentDisplayName = ""
            $roleAssignmentDisplayName = $roleAssignment.DisplayName
            $roleAssignmentObjectId = ""
            $roleAssignmentObjectId = $roleAssignment.ObjectId
            Write-Verbose "Processing role assignment on $resourceName for $roleAssignmentDisplayName "
            $memberType = ""
            $memberType = $roleAssignment.ObjectType
            switch($memberType){
                {$_ -like "*user*"}{
                    #If role assignment is a user, extract user properties and add a new object to the array
                    Write-Verbose "Standard user assignment. Creating entry for $roleAssignmentDisplayName"
                    $psobjResourceGroupRoles += [PSCustomObject]@{
                        RoleType = "Azure"
                        Scope = "Resource Group"
                        ResourceId = $resourceId
                        ResourceType = $resourceType
                        ResourceName = $resourceName
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
                    $psobjResourceGroupRoles += [PSCustomObject]@{
                        RoleType = "Azure"
                        Scope = "Resource Group"
                        ResourceId = $rg.ResourceId
                        ResourceType = "Resource Group"
                        ResourceName = $rg.ResourceGroupName
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
                                    $psobjResourceGroupRoles += [PSCustomObject]@{
                                        RoleType = "Azure"
                                        Scope = "Resource Group"
                                        ResourceId = $rg.ResourceId
                                        ResourceName = $rg.ResourceGroupName
                                        ResourceType = "Resource Group"
                                        RoleName = $roleAssignment.RoleDefinitionName
                                        MemberName = $memberName
                                        MemberType = "User"
                                        MemberUpnOrAppId = $memberUPN
                                        MemberObjId = $roleAssignment.ObjectId
                                    }
                                }
                                {$_ -like "*group*"}{
                                    Write-Verbose "Creating group entry for member $memberName"
                                    $psobjResourceGroupRoles += [PSCustomObject]@{
                                        RoleType = "Azure"
                                        Scope = "Resource Group"
                                        ResourceId = $rg.ResourceId
                                        ResourceName = $rg.ResourceGroupName
                                        ResourceType = "Resource Group"
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
                        $psobjResourceGroupRoles += [PSCustomObject]@{
                            RoleType = "Azure"
                            Scope = "Resource Group"
                            ResourceId = $rg.ResourceId
                            ResourceName = $rg.ResourceGroupName
                            ResourceType = "Resource Group"
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
                    $psobjResourceGroupRoles += [PSCustomObject]@{
                        RoleType = "Azure"
                        Scope = "Resource Group"
                        ResourceId = $rg.ResourceId
                        ResourceName = $rg.ResourceGroupName
                        ResourceType = "Resource Group"
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
    return $psobjResourceGroupRoles
}