. \Functions\Connect-GraphAutomation.ps1
. \Functions\Set-GraphProfile.ps1

Connect-GraphAutomation
Set-GraphProfile -ProfileName "beta" 

Get-MgProfile
# Collect array of application service principals
$arrAAD_Applications = @()
$arrAAD_Applications = Get-MgServicePrincipal -All:$true | Where-Object {$_.ServicePrincipalType -eq "Application" -and $_.Tags -eq "WindowsAzureActiveDirectoryIntegratedApp"}

# Set attribute parameters for the "Application" account type
$arrApplicationAccountTypeAttribute = @{}
$arrApplicationAccountTypeAttribute = @{
	CustomSecurityAttributes = @{
		CyberSecurityData = @{ 
			"@odata.type" = "#Microsoft.DirectoryServices.CustomSecurityAttributeValue"
			AccountType = "Enterprise Application"
		}
	}
}

# Loop through the application array and set the account type attribute
foreach($app in $arrAAD_Applications){
    $arrLoopAppAttributes = @()
    try {
        $arrLoopAppAttributes = Get-MgServicePrincipal -Select Id,DisplayName,CustomSecurityAttributes -ServicePrincipalId $app.Id -ErrorAction Stop
    }
    catch {
        $arrLoopAppAttributes = $null
    }
    $hashCybersecityCoreAttributes = @{}
    $hashCybersecityCoreAttributes = $arrLoopAppAttributes.CustomSecurityAttributes.AdditionalProperties.CyberSecurityData 
    $strAccountType = ""
    $strAccountType = $hashCybersecityCoreAttributes.AccountType
    if($strAccountType -eq $null -or $strAccountType -ne "Enterprise Application"){
        try {
            Update-MgServicePrincipal -ServicePrincipalId $app.Id -BodyParameter $arrApplicationAccountTypeAttribute -ErrorAction Stop
        }
        catch {
            $Error[0].Exception.Message
        }
    }
}
Set-GraphProfile -ProfileName "v1.0"

Get-MgProfile 

$pause  = $null



