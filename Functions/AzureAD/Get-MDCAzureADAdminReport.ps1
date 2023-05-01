<#
.SYNOPSIS
    This function will produce a psobject with admins and their various permissions. If an export path parameter is provided, the function will export the results to a csv file.
.DESCRIPTION
    Identifying excessive admin permissions is the goal. This report will provide the information that you need to identify and remediate excessive permissions in Azure AD.
.NOTES
    This is a custom function written by Mark Connelly, so it may not work as intended.
    Version:        1.0
    Author:         Mark D. Connelly Jr.
    Last Updated:   04-19-2023 - Mark Connelly
    Creation Date:  04-16-2023
    Purpose/Change: Cleaning structure and adding verbose error handling to the function.
.LINK
    https://github.com/markdconnelly/MarkConnellyPowerShellModule/blob/main/Functions/AzureAD/Get-MDCAzureADAdminReport.ps1
.EXAMPLE
    Get-MDCAzureADAdminReport
    Get-MDCAzureADAdminReport -ExportPath "C:\Temp\"
#>

Function Get-MDCAzureADAdminReport {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$false,Position=0)]
        [string]$ExportPath,
        [Parameter(Mandatory=$false,Position=1)]
        [bool]$ProductionEnvironment = $false
    )

    # Connect to the Microsoft Graph API
    try {
        Write-Verbose "Connecting to Graph"
        Disconnect-Graph | Out-Null
        Connect-MDCGraphApplication -ProductionEnvironment $ProductionEnvironment -ErrorAction Stop | Out-Null
        Write-Verbose "Connected to Graph"
    }
    catch {
        Write-Host "Unable to connect to Graph" -BackgroundColor Black -ForegroundColor Red
        return
    }
    
    # Collect an array of all AAD roles 
    $arrAAD_Roles = @()
    try {
        Write-Verbose "Collecting AAD Roles"
        $arrAAD_Roles = Get-MgDirectoryRole -ErrorAction Stop
    }
    catch {
        Write-Host "Unable to get AAD Roles" -BackgroundColor Black -ForegroundColor Red
        return
    }

    # Set Role Mapping Arrays
    try {
        $userRoleMappingArray = Get-MDCUserToAADRoleMapping | Where-Object {$_.RoleName -eq $roleName} -ErrorAction Stop
        $servicePrincipalRoleMappingArray = Get-MDCServicePrincipalToAADRoleMapping | Where-Object {$_.RoleName -eq $roleName} -ErrorAction Stop
    }
    catch {
        $objError = $Error[0].Exception.Message
        Write-Error $objError + "Unable to get mapping tables"
        return
    }

    # Loop through each AAD role and collect the members of that role
    $psobjAzureADAdminReport = @()
    foreach($role in $arrAAD_Roles){
        $roleName = ""
        $roleName = $role.AdditionalProperties.displayName
        foreach($user in $userRoleMappingArray){
            $psobjAzureADAdminReport += [PSCustomObject]@{
                ServicePrincipalType = $user.ServicePrincipalType
                DisplayName = $user.DisplayName
                ObjectId = $user.UserId
                AppIdUPN = $user.UserPrincipalName
                RoleName = $user.RoleName
                RoleDescription = $user.RoleDescription
                RoleId = $user.RoleId
                viaGroupName = $user.viaGroupName
                viaGroupDescription = $user.viaGroupDescription
                viaGroupObjectId = $user.viaGroupObjectId
            }
        }
        foreach($servicePrincipal in $servicePrincipalRoleMappingArray){
            $psobjAzureADAdminReport += [PSCustomObject]@{
                ServicePrincipalType = $servicePrincipal.ServicePrincipalType
                DisplayName = $servicePrincipal.DisplayName
                ObjectId = $servicePrincipal.ServicePrincipal
                AppIdUPN = $servicePrincipal.AppId
                RoleName = $servicePrincipal.RoleName
                RoleDescription = $servicePrincipal.RoleDescription
                RoleId = $servicePrincipal.RoleId
                viaGroupName = $servicePrincipal.viaGroupName
                viaGroupDescription = $servicePrincipal.viaGroupDescription
                viaGroupObjectId = $servicePrincipal.viaGroupObjectId
            }
        }

    }
      

    # If the ExportPath parameter is passed, export the results to a CSV file
    if($ExportPath){
        
        try {
            Write-Verbose "Exporting Azure Resource Admin Report to $ExportPath"
            Out-MDCToCSV -PSObj $psobjRoles -ExportPath $ExportPath -FileName "AzureResourceAdminReport"
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
    return $psobjAzureADAdminReport
}#End Function Get-GetAzureADAdministrators


