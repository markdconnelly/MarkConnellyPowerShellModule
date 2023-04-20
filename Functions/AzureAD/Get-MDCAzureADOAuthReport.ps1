<#
.SYNOPSIS
    Creates a report of existing OAuth2 permissions for all users and applications in the tenant.
.DESCRIPTION
    Identifying excessive admin permissions is the goal. This report will provide the information 
    that you need to identify and remediate excessive OAuth permissions in Azure Active Directory.
.INPUTS
  <Inputs if any, otherwise state None>
.OUTPUTS
  <Outputs if any, otherwise state None - example: Log file stored in C:\Windows\Temp\<name>.log>
.NOTES
    This is a custom function written by Mark Connelly, so it may not work as intended.
    Version:        1.0
    Author:         Mark D. Connelly Jr.
    Last Updated:   04-19-2023 - Mark Connelly
    Creation Date:  04-19-2023 - Mark Connelly
    Purpose/Change: Initial script development
.LINK
    https://github.com/markdconnelly/MarkConnellyPowerShellModule/blob/main/Functions/AzureAD/Get-MDCAzureADOAuthReport.ps1
.EXAMPLE
    Get-MDCAzureADOAuthReport
    Get-MDCAzureADOAuthReport -ExportPath "C:\Temp\"
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

    # Collect an array of all tenant wide permissions
    Write-Verbose "Collecting tenant wide permissions"
    $tenantWidePermissions = @()

    # put a try catch here
    try {
        $tenantWidePermissions = Get-MgOauth2PermissionGrant | Where-Object { $_.ConsentType -eq "AllPrincipals" }

        # Loop through permissions and collect the information
    }
    catch {
        <#Do this if a terminating exception happens#>
    }
    
    $scopearray = $($oauth.Scope).Split(" ")
    # output to psobj here
    $psobjRoles += [PSCustomObject]@{
        ConsentType = "AllPrincipals"
        UserID = "All Users"
        User = " All Users" # principal id -> Display name
        ApplicationId = "" 
        ApplicationName = "" # client Id -> Display name
        ResourceId = ""
        ResourceName = "" # resource id -> Display name
        Scope = "" # scope
    }

    # Collect an array of all users
    Write-Verbose "Collecting all users in the tenant"
    $arrAllUsers = @()
    # put a try catch here
    $arrAllUsers = Get-MgUser -All $true

    # Loop through users and collect their permissions
    $oauth = Get-MgUserOauth2PermissionGrant -UserId $userID


    # Return an array of permissions in the tenant
    return $psobjOauthPermissionReport
}