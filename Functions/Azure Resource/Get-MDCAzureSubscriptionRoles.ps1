<#
.SYNOPSIS
    This function will produce a psobj with admins and their various permissions that are scoped to the subscription.
.DESCRIPTION
    Identifying excessive admin permissions is the goal. This function will produce an array of permissions that are set at the subscription tier.
.NOTES
    This is a custom function written by Mark Connelly, so it may not work as intended.
    Version:        1.0
    Author:         Mark D. Connelly Jr.
    Last Updated:   04-28-2023 - Mark Connelly
    Creation Date:  04-25-2023
    Purpose/Change: Updated logic to use switch statements instead of if statements. Added additional comments and corrected verbose logging.
.LINK
    #
.EXAMPLE
    $array = Get-MDCAzureSubscriptionRoles
#>

Function Get-MDCAzureSubscriptionRoles {
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

    #region Collect Azure Role Assignments at the Subscription Scope
    $arrAzureSubscriptions = @()

    # Try to collect subscriptions. End if error encountered.
    try {
        $arrAzureSubscriptions = Get-AzSubscription -ErrorAction Stop | Where-Object {$_.State -eq "Enabled"}
        Write-Verbose "Subscriptions collected"
    }
    catch {
        $objError = $Error[0].Exception.Message
        Write-Host "Unable to retrieve Azure Subscriptions. Stopping..." -BackgroundColor Black -ForegroundColor Red
        Write-Host $objError -BackgroundColor Black -ForegroundColor Red
        return
    }

    $psobjSubscriptionRoles = @()
    # Loop through each subscription and collect role assignments
    foreach($sub in $arrAzureSubscriptions){
        $resourceId = ""
        $resourceType = ""
        $resourceName = ""
        $resourceId = $sub.Id
        $resourceType = "Subscription"
        $resourceName = $sub.Name

        Write-Verbose "Processing subscription $resourceName"

        # Set the context to the subscription before running the loop algorithm
        Write-Verbose "Setting context to subscription $resourceName"
        Set-AzContext -SubscriptionId $resourceId | Out-Null

        # Collect role assignments at the subscription scope
        $arrSubscriptionRoleAssignments = @()
        $arrSubscriptionRoleAssignments = Get-AzRoleAssignment | Where-Object {$_.Scope -eq "/subscriptions/$($sub.Id)"}
        foreach($roleAssignment in $arrSubscriptionRoleAssignments){
            $roleAssignmentDisplayName = ""
            $roleAssignmentDisplayName = $roleAssignment.DisplayName
            $roleAssignmentObjectId = ""
            $roleAssignmentObjectId = $roleAssignment.ObjectId
            Write-Verbose "Processing role assignment on subscription $resourceName assigned to $roleAssignmentDisplayName"
            $memberType = ""
            $memberType = $roleAssignment.ObjectType
            switch($memberType){
                {$_ -like "*user*"}{
                    #If role assignment is a user, extract user properties and add a new object to the array
                    Write-Verbose "Standard user assignment. Creating entry for $roleAssignmentDisplayName"
                    $psobjSubscriptionRoles += [PSCustomObject]@{
                        RoleType = "Azure"
                        Scope = "Subscription"
                        ResourceId = $resourceId
                        ResourceName = $resourceName
                        ResourceType = $resourceType
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
                    $psobjSubscriptionRoles += [PSCustomObject]@{
                        RoleType = "Azure"
                        Scope = "Subscription"
                        ResourceId = $resourceId
                        ResourceName = $resourceName
                        ResourceType = $resourceType
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
                            switch ($memberType) {
                                {$_ -like "*user*"}{
                                    Write-Verbose "Creating user entry for member $memberUPN"
                                    $psobjSubscriptionRoles += [PSCustomObject]@{
                                        RoleType = "Azure"
                                        Scope = "Subscription"
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
                                    $psobjSubscriptionRoles += [PSCustomObject]@{
                                        RoleType = "Azure"
                                        Scope = "Subscription"
                                        ResourceId = $resourceId
                                        ResourceName = $resourceName
                                        ResourceType = $resourceType
                                        RoleName = $roleAssignment.RoleDefinitionName
                                        MemberName = $memberName
                                        MemberType = $viaGroupName
                                        MemberUpnOrAppId = $memberUPN
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
                        $psobjSubscriptionRoles += [PSCustomObject]@{
                            RoleType = "Azure"
                            Scope = "Subscription"
                            ResourceId = $resourceId
                            ResourceName = $resourceName
                            ResourceType = $resourceType
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
                    $psobjSubscriptionRoles += [PSCustomObject]@{
                        RoleType = "Azure"
                        Scope = "Subscription"
                        ResourceId = $resourceId
                        ResourceName = $resourceName
                        ResourceType = $resourceType
                        RoleName = $roleAssignment.RoleDefinitionName
                        MemberName = $roleAssignmentDisplayName
                        MemberType = "Unknown"
                        MemberUpnOrAppId = $roleAssignment.SignInName
                        MemberObjId = $roleAssignmentObjectId
                    }
                    ;Break
                }
            }
        }
    }
    # Return the array of permissions and details
    Write-Verbose "Operation Completed. Returning array of permissions"
    return $psobjSubscriptionRoles
}