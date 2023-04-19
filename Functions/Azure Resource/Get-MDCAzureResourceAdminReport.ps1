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

    #region Connect to the Azure Resource Manager and Graph API

    # Try to connect to the Azure Resource Manager. End if error encountered.
    try {
        Write-Verbose "Connecting to the Azure Resource Manager"
        Connect-MDCAzApplication -ProductionEnvironment $ProductionEnvironment -ErrorAction Stop | Out-Null
        Write-Verbose "Connected to the Azure Resource Manager"
    }
    catch {
        Write-Verbose "Unable to connect to the Azure Resource Manager - $($Error[0].Exception.Message)"
        return
    }

    # Try to connect to the Microsoft Graph API. End if error encountered.
    try {
        Write-Verbose "Connecting to the Microsoft Graph API"
        Connect-MDCGraphApplication -ProductionEnvironment $ProductionEnvironment -ErrorAction Stop | Out-Null
        Write-Verbose "Connected to the Microsoft Graph API"
    }
    catch {
        Write-Verbose "Unable to connect to the Microsoft Graph API - $($Error[0].Exception.Message)"
        return
    }#endregion

    #region Collect Azure Role Assignments at the Management Group Scope
    $arrAzureManagementGroups = @()

    # Try to collect management groups
    try {
        $arrAzureManagementGroups = Get-AzManagementGroup -ErrorAction Stop
        Write-Verbose "Management groups collected"
    }
    catch {
        Write-Verbose "Unable to retrieve Azure Management Groups. If there are no management groups, this is not an error."
    }
    
    # Loop through each management group and collect role assignments
    $psobjRoles = @()
    foreach($managementGroup in $arrAzureManagementGroups){
        Write-Verbose "Processing management group $($managementGroup.DisplayName)"
        $arrManagementGroupRoleAssignments = @()
        $arrManagementGroupRoleAssignments = Get-AzRoleAssignment -Scope $managementGroup.Id | Where-Object {$_.Scope -eq $managementGroup.Id}
        foreach($roleAssignment in $arrManagementGroupRoleAssignments){
            Write-Verbose "Processing role assignment for $($roleAssignment.DisplayName) in management group $($managementGroup.DisplayName)"
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
                    }
                }
                catch {
                    #catch: Get-MgGroupMember
                    $objError = $Error[0].Exception.Message
                    Write-Verbose "Unable to get members of group $($roleAssignment.DisplayName)"
                    Write-Verbose $objError
                }
            }else{ #If role assignment is a user, proceed as normal
                Write-Verbose "Standard user assignment. Creating entry for $($roleAssignment.DisplayName)"
                $psobjRoles += [PSCustomObject]@{
                    RoleType = "Azure"
                    Scope = "Management Group"
                    ResourceId = $managementGroup.Id
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
        Write-Verbose "Subscriptions collected"
    }
    catch {
        $objError = $Error[0].Exception.Message
        Write-Verbose $objError
        Write-Host "Unable to retrieve Azure Subscriptions. Stopping..."
        return
    }

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
                    foreach($groupMember in $arrGroupMembers){
                        # For each member, add a new object to the array
                        Write-Verbose "Creating entry for member $($groupMember.AdditionalProperties.userPrincipalName)"
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
                    }
                }
                Catch{
                    #catch: Get-MgGroupMember
                    $objError = $Error[0].Exception.Message
                    Write-Verbose "Unable to get members of group $($roleAssignment.DisplayName)"
                    Write-Verbose $objError
                }
            }else{ #If role assignment is a user, proceed as normal
                Write-Verbose "Standard user assignment. Creating entry for $($roleAssignment.DisplayName)"
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
    }#endregion

    #region Collect Azure Role Assignments at the Resource Group Scope
    $arrAzureResourceGroups = @()

    # Loop through each subscription and collect an array of resource groups
    foreach($sub in $arrAzureSubscriptions){
        Write-Verbose "Collecting resource groups for subscription $($sub.DisplayName)"
        Set-AzContext -SubscriptionId $sub.Id | Out-Null
        $arrAzureResourceGroups += Get-AzResourceGroup
    }
    Write-Verbose "Resource groups collected"

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
                    }
                }
                catch {
                    #catch: Get-MgGroupMember
                    $objError = $Error[0].Exception.Message
                    Write-Verbose "Unable to get members of group $($roleAssignment.DisplayName)"
                    Write-Verbose $objError
                }
            }else{ #If role assignment is a user, proceed as normal
                Write-Verbose "Standard user assignment. Creating entry for $($roleAssignment.DisplayName)"
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
    }#endregion

    #region Collect Azure Role Assignments at the Resource Scope
    $arrAzureResources = @()

    # Loop through each subscription and collect an array of resources
    foreach($sub in $arrAzureSubscriptions){
        Write-Verbose "Collecting resources for subscription $($sub.DisplayName)"
        Set-AzContext -SubscriptionId $sub.Id | Out-Null
        $arrAzureResources += Get-AzResource
    }
    Write-Verbose "Resources collected"

    # Loop through each resource and collect role assignments
    foreach($resource in $arrAzureResources){
        Write-Verbose "Processing resource $($resource.Name)"
        $arrRoleAssignments = @()
        $arrRoleAssignments = Get-AzRoleAssignment -Scope $resource.ResourceId | Where-Object {$_.Scope -like "*/$($resource.Name)"}
        foreach($roleAssignment in $arrRoleAssignments){
            Write-Verbose "Processing role assignment for $($roleAssignment.DisplayName) in resource $($resource.Name)"
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
                        Write-Verbose "Creating entry for member $($groupMember.AdditionalProperties.userPrincipalName)"
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
                    }
                }catch{
                    #catch: Get-MgGroupMember
                    $objError = $Error[0].Exception.Message
                    Write-Verbose "Unable to get members of group $($roleAssignment.DisplayName)"
                    Write-Verbose $objError
                }
            }else{ #If role assignment is a user, proceed as normal
                Write-Verbose "Standard user assignment. Creating entry for $($roleAssignment.DisplayName)"
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
    }#endregion

    # Export the array of permissions to a CSV file if an export path is specified
    if($ExportPath){
        
        try {
            Write-Verbose "Exporting Azure Resource Admin Report to $ExportPath"
            Out-MDCToCSV -PSObj $psobjRoles -ExportPath $ExportPath -FileName "AzureResourceAdminReport"
            Write-Verbose "Export completed"
        }
        catch {
            $objError = $Error[0].Exception.Message
            Write-Verbose "Unable to export Azure Resource Admin Report to $ExportPath"
            Write-Verbose $objError
        }
        
    }

    # Return the array of permissions and details
    Write-Verbose "Operation Completed. Returning array of permissions"
    return $psobjRoles | Format-Table
}