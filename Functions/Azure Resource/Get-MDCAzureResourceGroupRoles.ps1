<#
.SYNOPSIS
    This function will produce a psobj with admins and their various permissions that are scoped to the resource group tier.
.DESCRIPTION
    Identifying excessive admin permissions is the goal. This function will produce an array of permissions that are set at the resource group tier.
.NOTES
    This is a custom function written by Mark Connelly, so it may not work as intended.
    Version:        1.0
    Author:         Mark D. Connelly Jr.
    Last Updated:   04-24-2023 - Mark Connelly
    Creation Date:  04-24-2023
    Purpose/Change: Initial script development
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
    if($null -eq $currentAzContext -or $null -eq $currentMgContext){
        Write-Error "Not connected to the cloud. Please connect to the cloud before running this function."
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
            $arrAzureResourceGroups += Get-AzResourceGroup
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
        Write-Verbose "Processing resource group $($rg.ResourceGroupName)"
        $arrRoleAssignments = @()
        $arrRoleAssignments = Get-AzRoleAssignment -ResourceGroupName $rg.ResourceGroupName | Where-Object {$_.Scope -like "*resourceGroups/$($rg.ResourceGroupName)"}
        foreach($roleAssignment in $arrRoleAssignments){
            Write-Verbose "Processing role assignment for $($roleAssignment.DisplayName) in resource group $($rg.ResourceGroupName)"
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
                        Write-Verbose "Creating entry for member $($groupMember.AdditionalProperties.userPrincipalName)"
                        $psobjResourceGroupRoles += [PSCustomObject]@{
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
                    }
                }
                catch {
                    #catch: Get-MgGroupMember
                    $objError = $Error[0].Exception.Message
                    Write-Host "Unable to get members of group $($roleAssignment.DisplayName)" -BackgroundColor Black -ForegroundColor Red
                    Write-Host $objError -BackgroundColor Black -ForegroundColor Red
                    Write-Verbose "Standard user assignment. Creating entry for $($roleAssignment.DisplayName)"
                    $psobjResourceGroupRoles += [PSCustomObject]@{
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
            }else{ #If role assignment is a user, proceed as normal
                Write-Verbose "Standard user assignment. Creating entry for $($roleAssignment.DisplayName)"
                $psobjResourceGroupRoles += [PSCustomObject]@{
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
    }

    # Return the array of permissions and details
    Write-Verbose "Operation Completed. Returning array of permissions"
    return $psobjResourceGroupRoles
}