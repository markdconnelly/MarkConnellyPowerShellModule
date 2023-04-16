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
$hashUserAccountType = Set-MDCSecAttrHashTable -AttributeSet "CyberSecurityData" -AttributeName "AccountType" -AttributeValue "User"
$hashServiceAccountType = Set-MDCSecAttrHashTable -AttributeSet "CyberSecurityData" -AttributeName "AccountType" -AttributeValue "Service Account"
$hashAppAccountType = Set-MDCSecAttrHashTable -AttributeSet "CyberSecurityData" -AttributeName "AccountType" -AttributeValue "Application" 
$hashManagedIdentityAccountType = Set-MDCSecAttrHashTable -AttributeSet "CyberSecurityData" -AttributeName "AccountType" -AttributeValue "Managed Identity"

#-----------------------------------------------------------[Execution]------------------------------------------------------------

#Log-Start -LogPath $sLogPath -LogName $sLogName -ScriptVersion $sScriptVersion
#Script Execution goes here
#Log-Finish -LogPath $sLogFile