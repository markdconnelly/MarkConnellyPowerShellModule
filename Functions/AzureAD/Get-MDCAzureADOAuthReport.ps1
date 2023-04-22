<#
.SYNOPSIS
    Creates a report of existing OAuth2 permissions for all users and applications in the tenant.
.DESCRIPTION
    Identifying excessive admin permissions is the goal. This report will provide the information 
    that you need to identify and remediate excessive OAuth permissions in Azure Active Directory.
.INPUTS
    $ExportPath - The path to export the report to. If not provided, the report will not be exported.
    $ProductionEnvironment - If set to $true, the function will connect to the production environment. If not provided, the function will connect to the test environment.
.OUTPUTS
    $psobjOauthPermissionReport - A psobject containing the OAuth permissions for all users and applications in the tenant.
.NOTES
    This is a custom function written by Mark Connelly, so it may not work as intended.
    Version:        1.0
    Author:         Mark D. Connelly Jr.
    Last Updated:   04-21-2023 - Mark Connelly
    Creation Date:  04-19-2023 - Mark Connelly
    Purpose/Change: Initial script development
.LINK
    https://github.com/markdconnelly/MarkConnellyPowerShellModule/blob/main/Functions/AzureAD/Get-MDCAzureADOAuthReport.ps1
.EXAMPLE
    Get-MDCAzureADOAuthReport
    Get-MDCAzureADOAuthReport -ExportPath "C:\Temp\"
    Get-MDCAzureADOAuthReport -ExportPath "C:\Temp\" -ProductionEnvironment $true
#>

Function Get-MDCAzureADOAuthReport {
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
        Connect-MDCGraphApplication -ProductionEnvironment $ProductionEnvironment -ErrorAction Stop | Out-Null
        Write-Verbose "Connected to Graph"
    }
    catch {
        Write-Host "Unable to connect to Graph" -BackgroundColor Black -ForegroundColor Red
        return
    }

    # Intialize psobj
    $psobjOauthPermissionReport = @()

    # Collect an array of all tenant wide permissions
    Write-Verbose "Collecting tenant wide permissions"
    $tenantWidePermissions = @()

    #region Tenant Wide Permissions
    # Try to get tenant wide permissions. If it fails, then there are none.
    try { 
        $tenantWidePermissions = Get-MgOauth2PermissionGrant | Where-Object { $_.ConsentType -eq "AllPrincipals" } -ErrorAction Stop
        Write-Verbose "Tenant wide permissions found"

        # Loop through permissions and collect the information
        $oauthGrant = @()
        foreach ($oauthGrant in $tenantWidePermissions) {
            Write-Verbose "Collecting information for tenant wide permission $($oauthGrant.Id)"
            $strConsentType = ""
            $strConsentType = "AllPrincipals"
            $strUserId = ""
            $strUserId = "All Users"
            $strUserName = ""
            $strUserName = " All Users"
            $strApplicationId = ""
            $strApplicationId = $oauthGrant.ClientId
            $strApplicationName = ""
            # try to resolve the application name
            try {
                $strApplicationName = $((Get-MgServicePrincipal -ServicePrincipalId $strApplicationId -ErrorAction Stop).DisplayName) 
            }
            catch {
                $strApplicationName = "Unable to resolve app display name"
            }
            $strResourceId = ""
            $strResourceId = $oauthGrant.ResourceId
            $strResourceName = ""
            # try to resolve the resource name
            try {
                $strResourceName = (Get-MgServicePrincipal -ServicePrincipalId $strResourceId).DisplayName
            }
            catch {
                $strResourceName = "Unable to resolve resource display name"
            }
            $arrScopes = @()
            $arrScopes = $($oauthGrant.Scope).Split(" ")

            # Loop through scopes and create a table entry for each scope that is granted
            foreach($scope in $arrScopes) {
                Write-Verbose "Collecting information for tenant wide scope $scope"
                $psobjOauthPermissionReport += [PSCustomObject]@{
                    ConsentType = $strConsentType
                    PrincipalType = "All Users"
                    UserID = $strUserId
                    UserName = $strUserName 
                    ApplicationId = $strApplicationId 
                    ApplicationName = $strApplicationName
                    ResourceId = $strResourceId
                    ResourceName = $strResourceName
                    Scope = $scope
                }
            }
        }
    }
    catch {
        Write-Verbose "No tenant wide permissions found"
    }#endregion

    #region User Specific Permissions
    # Collect an array of all users
    Write-Verbose "Collecting all users in the tenant"
    
    $arrAllUsers = @()
    # try to get all users in the tenant.
    try {
        $arrAllUsers = Get-MgUser -All $true
        Write-Verbose "All users collected"
    }
    catch {
        Write-Verbose "Unable to get full user array. Exiting"
        return
    }
    
    # Loop through users and collect their permissions
    Write-Verbose "Collecting permissions for each user"
    $user = @()
    $arrUserOauthPermissions = @()
    foreach($user in $arrAllUsers){
        # try to get oauth permissions for the user. If it fails, then document that in the array and move on to the next user. 
        Write-Verbose "Collecting permissions for user $($user.Id)"
        try {
            $arrUserOauthPermissions = Get-MgUserOauth2PermissionGrant -UserId $userID -ErrorAction Stop
            Write-Verbose "Permissions collected for user $($user.DisplayName)"
            $strConsentType = ""
            $strConsentType = $arrUserOauthPermissions.ConsentType
            $strUserId = ""
            $strUserId = $user.Id
            $strUserName = ""
            $strUserName = $user.DisplayName
            $strApplicationId = ""
            $strApplicationId = $oauthGrant.ClientId
            $strApplicationName = ""

            # try to resolve the application name 
            try {
                $strApplicationName = $((Get-MgServicePrincipal -ServicePrincipalId $strApplicationId -ErrorAction Stop).DisplayName) 
            }
            catch {
                $strApplicationName = "Unable to resolve app display name"
            }
            $strResourceId = ""
            $strResourceId = $oauthGrant.ResourceId

            # try to resolve the resource name
            try {
                $strResourceName = (Get-MgServicePrincipal -ServicePrincipalId $strResourceId).DisplayName
            }
            catch {
                $strResourceName = "Unable to resolve resource display name"
            }
            $arrScopes = @()
            $arrScopes = $($oauthGrant.Scope).Split(" ")

            # Loop through scopes and create a table entry for each scope that is granted
            foreach($scope in $arrScopes) {
                Write-Verbose "Creating table entry for $($user.Id) scope $scope"
                $psobjOauthPermissionReport += [PSCustomObject]@{
                    ConsentType = $strConsentType
                    PrincipalType = "User"
                    UserID = $strUserId
                    UserName = $strUserName # principal id -> Display name
                    ApplicationId = $strApplicationId 
                    ApplicationName = $strApplicationName # client Id -> Display name
                    ResourceId = $strResourceId
                    ResourceName = $strResourceName # resource id -> Display name
                    Scope = $scope # scope
                }
            }
        }
        catch {
            Write-Verbose "No permissions found for user $($user.Id)"
        }
    }#endregion


    #region Application Specific Permissions
    # Collect an array of all service principals
    Write-Verbose "Collecting all service principals in the tenant"

    $arrAllServicePrincipals = @()
    # try to get all service principals in the tenant.
    try {
        $arrAllServicePrincipals = Get-MgServicePrincipal -All $true
    }
    catch {
        $objError = $Error[0].Exception.Message
        Write-Verbose "Unable to get full service principal array. Exiting"
        throw "Unable to get full service principal array. Error: $objError"
    }

    # Loop through service principals and collect their permissions
    Write-Verbose "Collecting permissions for each service principal"
    $servicePrincipal = @()
    $arrServicePrincipalOauthPermissions = @()
    foreach($servicePrincipal in $arrAllServicePrincipals){
        # try to get oauth permissions for the service principal. If it fails, then document that in the array and move on to the next service principal. 
        Write-Verbose "Collecting permissions for service principal $($servicePrincipal.Id)"
        try {
            $arrServicePrincipalOauthPermissions = Get-MgServicePrincipalOauth2PermissionGrant -ServicePrincipalId $servicePrincipal.Id -ErrorAction Stop
            $strConsentType = ""
            $strConsentType = $arrServicePrincipalOauthPermissions.ConsentType
            $strUserId = ""
            $strUserName = ""
            $strApplicationId = ""
            $strApplicationId = $arrServicePrincipalOauthPermissions.ClientId
            $strApplicationName = ""

            # try to resolve the application name 
            try {
                $strApplicationName = $((Get-MgServicePrincipal -ServicePrincipalId $strApplicationId -ErrorAction Stop).DisplayName) 
            }
            catch {
                $strApplicationName = "Unable to resolve app display name"
            }
            $strResourceId = ""
            $strResourceId = $arrServicePrincipalOauthPermissions.ResourceId

            # try to resolve the resource name
            try {
                $strResourceName = (Get-MgServicePrincipal -ServicePrincipalId $strResourceId).DisplayName
            }
            catch {
                $strResourceName = "Unable to resolve resource display name"
            }
            $arrScopes = @()
            $arrScopes = $($oauthGrant.Scope).Split(" ")

            # Loop through scopes and create a table entry for each scope that is granted
            foreach($scope in $arrScopes) {
                $psobjOauthPermissionReport += [PSCustomObject]@{
                    ConsentType = $strConsentType
                    PrincipalType = "Service Principal"
                    UserID = $strUserId
                    UserName = $strUserName
                    ApplicationId = $strApplicationId 
                    ApplicationName = $strApplicationName
                    ResourceId = $strResourceId
                    ResourceName = $strResourceName
                    Scope = $scope
                }
            }
        }
        catch {
            Write-Verbose "No permissions found for service principal $($servicePrincipal.Id)"
        }
    }#endregion

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
            throw $objError 
        }
        
    }

    # Return an array of permissions in the tenant
    return $psobjOauthPermissionReport
}

Get-MDCAzureADOAuthReport -ExportPath "C:\Temp"