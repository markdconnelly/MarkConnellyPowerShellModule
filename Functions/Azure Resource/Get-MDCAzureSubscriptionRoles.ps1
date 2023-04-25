<#
.SYNOPSIS
    This function will produce a psobj with admins and their various permissions that are scoped to the subscription.
.DESCRIPTION
    Identifying excessive admin permissions is the goal. This function will produce an array of permissions that are set at the subscription tier.
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
    $array = Get-MDCAzureSubscriptionRoles
#>

Function Get-MDCAzureSubscriptionRoles {
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

    #region Collect Azure Role Assignments at the Subscription Scope
    $arrAzureSubscriptions = @()

    # Try to collect subscriptions. End if error encountered.
    try {
        $arrAzureSubscriptions = Get-AzSubscription -ErrorAction Stop
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
        Write-Verbose "Processing subscription $($sub.DisplayName)"

        # Set the context to the subscription before running the loop algorithm
        Write-Verbose "Setting context to subscription $($sub.DisplayName)"
        Set-AzContext -SubscriptionId $sub.Id | Out-Null

        # Collect role assignments at the subscription scope
        $arrRoleAssignments = @()
        $arrRoleAssignments = Get-AzRoleAssignment | Where-Object {$_.Scope -eq "/subscriptions/$($sub.Id)"}
        foreach($roleAssignment in $arrRoleAssignments){
            Write-Verbose "Processing role assignment for $($roleAssignment.DisplayName) in subscription $($sub.DisplayName)"
            if ($roleAssignment.ObjectType -like "*group*") { #If role assignment is a group, get the members of the group
                Write-Verbose "$($role.DisplayName) is a group"
                $arrGroupMembers = @()
                try {
                    #try: Get-MgGroupMember
                    Write-Verbose "Collecting members of group $($roleAssignment.DisplayName)"
                    $arrGroupMembers = Get-MgGroupMember -GroupId $roleAssignment.ObjectId -ErrorAction Stop
                    $groupMember = ""
                    $memberType = ""
                    $memberType = "Group - $($roleAssignment.DisplayName)"
                    $memberName = ""
                    $memberName = $groupMember.AdditionalProperties.displayName
                    $memberUPN = ""
                    $memberUPN = $groupMember.AdditionalProperties.userPrincipalName

                    foreach($groupMember in $arrGroupMembers){
                        # For each member, add a new object to the array
                        Write-Verbose "Creating entry for member $($groupMember.AdditionalProperties.userPrincipalName)"
                        $psobjSubscriptionRoles += [PSCustomObject]@{
                            RoleType = "Azure"
                            Scope = "Subscription"
                            ResourceId = $sub.Id
                            ResourceName = $sub.Name
                            ResourceType = "Subscription"
                            RoleName = $roleAssignment.RoleDefinitionName
                            MemberName = $memberName
                            MemberType = $memberType
                            MemberUpnOrAppId = $memberUPN
                            MemberObjId = $roleAssignment.ObjectId
                        }
                    }
                }
                Catch{
                    #catch: Get-MgGroupMember
                    $objError = $Error[0].Exception.Message
                    Write-Host "Unable to get members of group $($roleAssignment.DisplayName)" -BackgroundColor Black -ForegroundColor Red
                    Write-Host $objError -BackgroundColor Black -ForegroundColor Red
                    Write-Verbose "Creating entry for member $($roleAssignment.DisplayName)"

                    $psobjSubscriptionRoles += [PSCustomObject]@{
                        RoleType = "Azure"
                        Scope = "Subscription"
                        ResourceId = $sub.Id
                        ResourceName = $sub.Name
                        ResourceType = "Subscription"
                        RoleName = $roleAssignment.RoleDefinitionName
                        MemberName = $roleAssignment.DisplayName
                        MemberType = $memberType
                        MemberUpnOrAppId = $roleAssignment.SignInName
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
                    $psobjSubscriptionRoles += [PSCustomObject]@{
                        RoleType = "Azure"
                        Scope = "Subscription"
                        ResourceId = $sub.Id
                        ResourceType = "Subscription"
                        ResourceName = $sub.Name
                        RoleName = $roleAssignment.RoleDefinitionName
                        MemberName = $servicePrincipalDisplayName
                        MemberType = $roleAssignment.ObjectType
                        MemberUpnOrAppId = $servicePrinipalAppId
                        MemberObjId = $roleAssignment.ObjectId
                    }
                }else{
                    #If role assignment is a user, proceed as normal
                    Write-Verbose "Standard user assignment. Creating entry for $($roleAssignment.DisplayName)"
                    $psobjSubscriptionRoles += [PSCustomObject]@{
                        RoleType = "Azure"
                        Scope = "Subscription"
                        ResourceId = $sub.Id
                        ResourceType = "Subscription"
                        ResourceName = $sub.Name
                        RoleName = $roleAssignment.RoleDefinitionName
                        MemberName = $roleAssignment.DisplayName
                        MemberType = $roleAssignment.ObjectType
                        MemberUpnOrAppId = $roleAssignment.SignInName
                        MemberObjId = $roleAssignment.ObjectId
                    }
                }
            }
        }
    }#endregion

    # Return the array of permissions and details
    Write-Verbose "Operation Completed. Returning array of permissions"
    return $psobjSubscriptionRoles
}