<#
.SYNOPSIS
    This function will produce a psobj with admins and their various permissions. If an export path parameter is provided, the function will export the results to a csv file.
.DESCRIPTION
    Identifying excessive admin permissions is the goal. This report will provide the information that you need to identify and remediate excessive permissions in the Azure Resource Manager.
.NOTES
    This is a custom function written by Mark Connelly, so it may not work as intended.
    Version:        1.0
    Author:         Mark D. Connelly Jr.
    Last Updated:   04-24-2023 - Mark Connelly
    Creation Date:  04-18-2023
    Purpose/Change: Updating to be cleaner and use sub functions better. 
.LINK
    https://github.com/markdconnelly/MarkConnellyPowerShellModule/blob/main/Functions/Azure%20Resource/Get-MDCAzureAdminReport.ps1
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
        Disconnect-AzAccount | Out-Null 
        Disconnect-MgGraph | Out-Null
    }
    catch {
        # Do nothing
    }

    try {
        Write-Verbose "Connecting to the Azure Resource Manager"
        Connect-MDCAzApplication -ProductionEnvironment $ProductionEnvironment -ErrorAction Stop | Out-Null
        Write-Verbose "Connected to the Azure Resource Manager"
    }
    catch {
        $objError = $Error[0].Exception.Message
        Write-Host "Unable to connect to the Azure Resource Manager" -BackgroundColor Black -ForegroundColor Red
        Write-Host $objError -BackgroundColor Black -ForegroundColor Red
        return
    }

    # Try to connect to the Microsoft Graph API. End if error encountered.
    try {
        Write-Verbose "Connecting to the Microsoft Graph API"
        Connect-MDCGraphApplication -ProductionEnvironment $ProductionEnvironment -ErrorAction Stop | Out-Null
        Write-Verbose "Connected to the Microsoft Graph API"
    }
    catch {
        $objError = $Error[0].Exception.Message
        Write-Host "Unable to connect to the Microsoft Graph API" -BackgroundColor Black -ForegroundColor Red
        Write-Host $objError -BackgroundColor Black -ForegroundColor Red
        return
    }#endregion

    
    #region Collect Azure Role Assignments at the various scopes
    $psobjAzureResourceAdminRoleReport = @()

    # Try to get permissions at the management group scope
    try {
        Write-Verbose "Trying to get management group roles"
        $arrAzureManagementGroupRoles = Get-MDCAzureManagementGroupRoles -ErrorAction Stop
        Write-Verbose "Successfully collected management group roles"
    }
    catch {
        Write-Verbose "Unable to collect Azure Management Group roles. Creating an error entry in the report."
        Write-Error "Unable to collect Azure Management Group roles"
        $psobjAzureResourceAdminRoleReport += [PSCustomObject]@{
            RoleType = "Azure"
            Scope = "Management Group"
            ResourceId = "N/A"
            ResourceName = "N/A"
            ResourceType = "N/A"
            RoleName = "N/A"
            MemberName = "N/A"
            MemberType = "N/A"
            MemberUPNOrAppId = "N/A"
            MemberObjId = "N/A"
            Error = "Unable to collect Azure Management Group roles"
        }
    }
    
    # Loop through each management group permission to build the report
    Write-Verbose "Looping through each management group role to extract permissions."
    foreach($permission in $arrAzureManagementGroupRoles){
        $psobjAzureResourceAdminRoleReport += [PSCustomObject]@{
            RoleType = "Azure"
            Scope = $permission.Scope
            ResourceId = $permission.ResourceId
            ResourceName = $permission.ResourceName
            ResourceType = $permission.ResourceType
            RoleName = $permission.RoleName
            MemberName = $permission.MemberName
            MemberType = $permission.MemberType
            MemberUPNOrAppId = $permission.MemberUpnOrAppId
            MemberObjId = $permission.MemberObjId
            Error = ""
        }
    }
    Write-Verbose "Management Group roles complete."

    # Try to get permissions at the subscription scope
    try {
        Write-Verbose "Trying to get subscription roles"
        $arrAzureSubscriptionRoles = Get-MDCAzureSubscriptionRoles -ErrorAction Stop
        Write-Verbose "Successfully collected subscription roles"
    }
    catch {
        Write-Verbose "Unable to collect Azure Subscription roles. Creating an error entry in the report."
        Write-Error "Unable to collect Azure Subscription roles"
        $psobjAzureResourceAdminRoleReport += [PSCustomObject]@{
            RoleType = "Azure"
            Scope = "Subscription"
            ResourceId = "N/A"
            ResourceName = "N/A"
            ResourceType = "N/A"
            RoleName = "N/A"
            MemberName = "N/A"
            MemberType = "N/A"
            MemberUPNOrAppId = "N/A"
            MemberObjId = "N/A"
            Error = "Unable to collect Azure Subscription roles"
        }
    }
    
    # Loop through each subscription permission to build the report
    Write-Verbose "Looping through each subscription role to extract permissions."
    foreach($permission in $arrAzureSubscriptionRoles){
        $psobjAzureResourceAdminRoleReport += [PSCustomObject]@{
            RoleType = "Azure"
            Scope = $permission.Scope
            ResourceId = $permission.ResourceId
            ResourceName = $permission.ResourceName
            ResourceType = $permission.ResourceType
            RoleName = $permission.RoleName
            MemberName = $permission.MemberName
            MemberType = $permission.MemberType
            MemberUPNOrAppId = $permission.MemberUpnOrAppId
            MemberObjId = $permission.MemberObjId
            Error = ""
        }
    }
    Write-Verbose "Subscription roles complete."

    # Try to get permissions at the resource group scope
    try {
        Write-Verbose "Trying to get resource group roles"
        $arrAzureResourceGroupRoles = Get-MDCAzureResourceGroupRoles -Verbose -ErrorAction Stop
        Write-Verbose "Successfully collected resource group roles"
    }
    catch {
        Write-Verbose "Unable to collect Azure Resource Group roles. Creating an error entry in the report."
        Write-Error "Unable to collect Azure Resource Group roles"
        $psobjAzureResourceAdminRoleReport += [PSCustomObject]@{
            RoleType = "Azure"
            Scope = "Resource Group"
            ResourceId = "N/A"
            ResourceName = "N/A"
            ResourceType = "N/A"
            RoleName = "N/A"
            MemberName = "N/A"
            MemberType = "N/A"
            MemberUPNOrAppId = "N/A"
            MemberObjId = "N/A"
            Error = "Unable to collect Azure Resource Group roles"
        }
    }

    # Loop through each subscription permission to build the report
    Write-Verbose "Looping through each resource group role to extract permissions."
    foreach($permission in $arrAzureResourceGroupRoles){
        $psobjAzureResourceAdminRoleReport += [PSCustomObject]@{
            RoleType = "Azure"
            Scope = $permission.Scope
            ResourceId = $permission.ResourceId
            ResourceName = $permission.ResourceName
            ResourceType = $permission.ResourceType
            RoleName = $permission.RoleName
            MemberName = $permission.MemberName
            MemberType = $permission.MemberType
            MemberUPNOrAppId = $permission.MemberUpnOrAppId | Out-String
            MemberObjId = $permission.MemberObjId
            Error = ""
        }
    }
    Write-Verbose "Resource Group roles complete."

    # Try to get permissions at the resource scope
    try {
        Write-Verbose "Trying to get resource roles"
        $arrAzureResourceRoles = Get-MDCAzureResourceRoles -ErrorAction Stop
        Write-Verbose "Successfully collected resource roles"
    }
    catch {
        Write-Verbose "Unable to collect Azure Resource roles. Creating an error entry in the report."
        Write-Error "Unable to collect Azure Resource roles"
        $psobjAzureResourceAdminRoleReport += [PSCustomObject]@{
            RoleType = "Azure"
            Scope = "Resource"
            ResourceId = "N/A"
            ResourceName = "N/A"
            ResourceType = "N/A"
            RoleName = "N/A"
            MemberName = "N/A"
            MemberType = "N/A"
            MemberUPNOrAppId = "N/A"
            MemberObjId = "N/A"
            Error = "Unable to collect Azure Resource roles"
        }
    }

    # Loop through each subscription permission to build the report
    Write-Verbose "Looping through each resource role to extract permissions."
    foreach($permission in $arrAzureResourceRoles){
        $psobjAzureResourceAdminRoleReport += [PSCustomObject]@{
            RoleType = "Azure"
            Scope = $permission.Scope
            ResourceId = $permission.ResourceId
            ResourceName = $permission.ResourceName
            ResourceType = $permission.ResourceType
            RoleName = $permission.RoleName
            MemberName = $permission.MemberName
            MemberType = $permission.MemberType
            MemberUPNOrAppId = $permission.MemberUpnOrAppId | Out-String
            MemberObjId = $permission.MemberObjId
            Error = ""
        }
    }
    Write-Verbose "Resource roles complete."

    # Export the array of permissions to a CSV file if an export path is specified
    if($ExportPath){
        try {
            Write-Verbose "Exporting Azure Resource Admin Report to $ExportPath"
            Out-MDCToCSV -PSObj $psobjAzureResourceAdminRoleReport -ExportPath $ExportPath -FileName "AzureResourceAdminReport"
            Write-Verbose "Export completed"
        }
        catch {
            $objError = $Error[0].Exception.Message
            Write-Host "Unable to export Azure Resource Admin Report to $ExportPath" -BackgroundColor Black -ForegroundColor Red
            Write-Host $objError -BackgroundColor Black -ForegroundColor Red
        }  
    }

    # Return the array of permissions and details
    Write-Verbose "Operation Completed. Returning array of permissions"
    return $psobjAzureResourceAdminRoleReport
}