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
            $subDisplayName = ""
            $subDisplayName = $sub.DisplayName
            Set-AzContext -SubscriptionId $sub.Id | Out-Null
            Write-Verbose "Context set to subscription $subDisplayName"
            $arrAzureResourceGroups += Get-AzResourceGroup -ErrorAction SilentlyContinue
            Write-Verbose "Resource groups collected for subscription $subDisplayName"
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
                        MemberName = $roleAssignmentDisplayName
                        MemberType = $memberType
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
                    $psobjResourceGroupRoles += [PSCustomObject]@{
                        RoleType = "Azure"
                        Scope = "Resource Group"
                        ResourceId = $resourceId
                        ResourceType = $resourceType
                        ResourceName = $resourceName
                        RoleName = $roleAssignment.RoleDefinitionName
                        MemberName = $servicePrincipalDisplayName
                        MemberType = $memberType
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
                                    $psobjResourceGroupRoles += [PSCustomObject]@{
                                        RoleType = "Azure"
                                        Scope = "Resource Group"
                                        ResourceId = $resourceId
                                        ResourceName = $resourceName
                                        ResourceType = $resourceType
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
                                    $psobjResourceGroupRoles += [PSCustomObject]@{
                                        RoleType = "Azure"
                                        Scope = "Resource Group"
                                        ResourceId = $resourceId
                                        ResourceName = $resourceName
                                        ResourceType = $resourceType
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
                        $psobjResourceGroupRoles += [PSCustomObject]@{
                            RoleType = "Azure"
                            Scope = "Resource Group"
                            ResourceId = $resourceId
                            ResourceName = $resourceName
                            ResourceType = $resourceType
                            RoleName = $roleAssignment.RoleDefinitionName
                            MemberName = $roleAssignmentDisplayName
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
                        ResourceId = $resourceId
                        ResourceName = $resourceName
                        ResourceType = $resourceType
                        RoleName = $roleAssignment.RoleDefinitionName
                        MemberName = $roleAssignmentDisplayName
                        MemberType = "Unknown"
                        MemberUpnOrAppId = $roleAssignment.SignInName
                        MemberObjId = $roleAssignmentObjectId
                    }
                }
            }
        }
    }

    # Return the array of permissions and details
    Write-Verbose "Operation Completed. Returning array of permissions"
    return $psobjResourceGroupRoles
}