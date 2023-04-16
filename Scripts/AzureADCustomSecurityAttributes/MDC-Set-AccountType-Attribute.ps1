<#
.SYNOPSIS
  This script will set the AccountType attribute for all users and service principals in the tenant.
.DESCRIPTION
  This script will collect all users and service principals in the tenant and set the AccountType attribute to "User", "Service Account", "Application", or "Managed Identity" respectively.
.NOTES
  Version:        1.0
  Author:         Mark D. Connelly Jr.
  Creation Date:  04-16-2023
  Purpose/Change: Initial script development
#>

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

# Connect to the Microsoft Graph API
Connect-MDCGraphApplication -ErrorAction Stop
Set-MDCGraphProfile -ProfileName "beta" -ErrorAction Stop

#----------------------------------------------------------[Declarations]----------------------------------------------------------

# Create arrays to hold users, service accounts, applications, and managed identities.
$arrUsers = @()
$arrServiceAccounts = @()
$arrApplications = @()
$arrManagedIdentities = @()

# Try to get user objects
try {
    $arrUsers = Get-MDCUsers -ErrorAction Stop
}
catch {
    Write-Host "Unable to get users"
    $arrUsers = @()
}

# Try to get service account objects
try {
    $arrServiceAccounts = Get-MDCServiceAccounts -ErrorAction Stop
}
catch {
    Write-Host "Unable to get service accounts"
    $arrServiceAccounts = @()
}

# Try to get application objects
try {
    $arrApplications = Get-MDCEnterpriseApplications -ErrorAction Stop
}
catch {
    Write-Host "Unable to get applications"
    $arrApplications = @()
}

# Try to get managed identity objects
try {
    $arrManagedIdentities = Get-MDCManagedIdentity -ErrorAction Stop
}
catch {
    Write-Host "Unable to get managed identities"
    $arrManagedIdentities = @()
}

#-----------------------------------------------------------[Execution]------------------------------------------------------------

# Set the AccountType attribute for all users
Foreach ($user in $arrUsers){
    try {
        Set-MDCUserSecAttr -UserPrincipalName $user.$UserPrincipalName -AttributeSet "CyberSecurityData" -AttributeName "AccountType" -AttributeValue "User" -ErrorAction Stop
    }
    catch {
        Write-Verbose "Unable to set AccountType attribute for $($user)"
    }
}

# Set the AccountType attribute for all service accounts
Foreach ($serviceAccount in $arrServiceAccounts){
    try {
        Set-MDCUserSecAttr -UserPrincipalName $serviceAccount.$userPrincipalName -AttributeSet "CyberSecurityData" -AttributeName "AccountType" -AttributeValue "Service Account" -ErrorAction Stop
    }
    catch {
        Write-Verbose "Unable to set AccountType attribute for $($serviceAccount)"
    }
}

# Set the AccountType attribute for all applications
Foreach ($application in $arrApplications){
    try {
        Set-MDCServicePrincipalSecAttr -ServicePrincipalId $application.Id -AttributeSet "CyberSecurityData" -AttributeName "AccountType" -AttributeValue "Application" -ErrorAction Stop
    }
    catch {
        Write-Verbose "Unable to set AccountType attribute for $($application)"
    }
}

# Set the AccountType attribute for all managed identities
Foreach ($managedIdentity in $arrManagedIdentities){
    try {
        Set-MDCServicePrincipalSecAttr -ServicePrincipalId $managedIdentity.Id -AttributeSet "CyberSecurityData" -AttributeName "AccountType" -AttributeValue "Managed Identity" -ErrorAction Stop
    }
    catch {
        Write-Verbose "Unable to set AccountType attribute for $($managedIdentity)"
    }
}