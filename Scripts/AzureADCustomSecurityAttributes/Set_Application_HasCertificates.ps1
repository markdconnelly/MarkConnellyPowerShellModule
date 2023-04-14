## This script will set the "HasCertificates" Custom Security Attribute for all applications in Azure Active Directory

# Connect to Microsoft Graph as a service principal
Write-Host "Connecting to Microsoft Graph as a service principal" -BackgroundColor Black -ForegroundColor Green
$strClientID = Get-Secret -Name PSAppID -AsPlainText
$strTenantID = Get-Secret -Name PSAppTenantID -AsPlainText
$strClientSecret = Get-Secret -Name PSAppSecret -AsPlainText
$strAPI_URI = "https://login.microsoftonline.com/$strTenantID/oauth2/token"
$arrAPI_Body = @{
    grant_type = "client_credentials"
    client_id = $strClientID
    client_secret = $strClientSecret
    resource = "https://graph.microsoft.com"
}
$objAccessTokenRaw = Invoke-RestMethod -Method Post -Uri $strAPI_URI -Body $arrAPI_Body -ContentType "application/x-www-form-urlencoded"
$objAccessToken = $objAccessTokenRaw.access_token
Connect-Graph -Accesstoken $objAccessToken

# Validate that the beta profile is in use
$strProfileName = Get-MgProfile | Select-Object -ExpandProperty Name
Write-Host "Current profile: $strProfileName" -BackgroundColor Black -ForegroundColor Green
if ($strProfileName -eq "v1.0") {
    Select-MgProfile beta
    Write-Host "Profile check has changed the profile to beta" -BackgroundColor Black -ForegroundColor Green
}
else { 
    Write-Host "No action required from the profile check" -BackgroundColor Black -ForegroundColor Green
}

# Collect array of application service principals
Write-Host "Collecting array of enterprise applications" -BackgroundColor Black -ForegroundColor Green
$arrAAD_Applications = @()
$arrAAD_Applications = Get-MgServicePrincipal -All:$true | Where-Object {$_.ServicePrincipalType -eq "Application" -and $_.Tags -eq "WindowsAzureActiveDirectoryIntegratedApp"}

# Set attribute parameters for the "HasSSO" application attribute
Write-Host "Setting attribute parameters for the "HasSSO" custom security attribute" -BackgroundColor Black -ForegroundColor Green
$hashHasSSO_True = @{}
$hashHasSSO_True = @{
	CustomSecurityAttributes = @{
		CybersecurityApplications = @{ 
			"@odata.type" = "#Microsoft.DirectoryServices.CustomSecurityAttributeValue"
			HasSSO = "True"
		}
	}
}
$hashHasSSO_False = @{}
$hashHasSSO_False = @{
	CustomSecurityAttributes = @{
		CybersecurityApplications = @{ 
			"@odata.type" = "#Microsoft.DirectoryServices.CustomSecurityAttributeValue"
			HasSSO = "False"
		}
	}
}

# Loop through the application array, evaluate the HasSSO attribute, the application certificate status, and set the HasSSO attribute accordingly
$intProgressStatus = 0
Write-Host "Progress counter reset to $intProgressStatus" -BackgroundColor Black -ForegroundColor Green
$intFailures = 0
Write-Host "Failure counter reset to $intFailures" -BackgroundColor Black -ForegroundColor Green
Write-Host "Checking $($arrAAD_Applications.Count) applications for the HasSSO custom security attribute" -BackgroundColor Black -ForegroundColor Green
foreach($app in $arrAAD_Applications){
    $arrLoopAppAttributes = @()
    # Get the current HasSSO attribute value
    try {
        $arrLoopAppAttributes = Get-MgServicePrincipal -Select Id,DisplayName,CustomSecurityAttributes -ServicePrincipalId $app.Id -ErrorAction Stop
    }
    catch {
        Write-Host "Unable to get the current attributes for $($app.DisplayName)" -BackgroundColor Black -ForegroundColor Red
        $arrLoopAppAttributes = $null
    }
    $hashCybersecityAppAttributes = @{}
    $hashCybersecityAppAttributes = $arrLoopAppAttributes.CustomSecurityAttributes.AdditionalProperties.CybersecurityApplications  
    $strHasSSO = ""
    $strHasSSO = $hashCybersecityCoreAttributes.HasSSO
    if($strHasSSO -eq $null){
        $strHasSSO = "Blank"
    }
    Write-Host "Current HasSSO value is $strHasSSO" -BackgroundColor Black -ForegroundColor Green
    Write-Host "Checking $($app.DisplayName) certificates" -BackgroundColor Black -ForegroundColor Green
    $arrLoopAppCertificates = @()
    $arrLoopServicePrincipalObject = @()
    $arrLoopAppRegObject = @()
    try {
        $arrLoopServicePrincipalObject = Get-MgServicePrincipal -ServicePrincipalId $app.Id -ErrorAction Stop
    }
    catch {
        Write-Host "Unable to get service principal certificates for $($app.DisplayName)" -BackgroundColor Black -ForegroundColor Red
        $arrLoopServicePrincipalObject = $null
    }
    try {
        $arrLoopAppRegObject += Get-MgApplication -Filter "AppId eq $($app.AppId)" -ErrorAction Stop
    }
    Catch {
        Write-Host "Unable to get app registration certificates for $($app.DisplayName)" -BackgroundColor Black -ForegroundColor Red
        $arrLoopAppRegObject = $null
    }
    $arrLoopAppCertificates = $arrLoopServicePrincipalObject.KeyCredentials
    $arrLoopAppCertificates += $arrLoopAppRegObject.KeyCredentials
    catch {
        Write-Host "Unable to get app registration certificates for $($app.DisplayName)" -BackgroundColor Black -ForegroundColor Red
    }
    Write-Host "Found $($arrLoopAppCertificates.Count) certificates for $($app.DisplayName)" -BackgroundColor Black -ForegroundColor Green

    # Check if there are certificates present, and if the attribute mismatches, correct it.
    if($($arrLoopAppCertificates.Count) -eq "0"){ 
        Write-Host "No certificates found for $($app.DisplayName). Setting attribute to false." -BackgroundColor Black -ForegroundColor Red
        if($strHasSSO -ne "False"){
            try {
                Update-MgServicePrincipal -ServicePrincipalId $app.Id -BodyParameter $hashHasSSO_False -ErrorAction Stop
            }
            catch {
                $intFailures++
                Write-Host "Undable to set attribute for $($app.DisplayName)" -BackgroundColor Black -ForegroundColor Red
                Write-Host $Error[0].Exception.Message -BackgroundColor Black -ForegroundColor Red
            }
        }
        else{
            Write-Host "HasSSO attribute for $($app.DisplayName) is correct. Proceeding to the next application." -BackgroundColor Black -ForegroundColor Green
        }
    }
    else{
        Write-Host "Application certificates found for $($app.DisplayName). Setting attribute to true." -BackgroundColor Black -ForegroundColor Green
        if($strHasSSO -ne "True"){
            try {
                Update-MgServicePrincipal -ServicePrincipalId $app.Id -BodyParameter $hashHasSSO_True -ErrorAction Stop
            }
            catch {
                $intFailures++
                Write-Host "Undable to set attribute for $($app.DisplayName)" -BackgroundColor Black -ForegroundColor Red
                Write-Host $Error[0].Exception.Message -BackgroundColor Black -ForegroundColor Red
            }
        }
        else{
            Write-Host "HasSSO attribute for $($app.DisplayName) is correct. Proceeding to the next application." -BackgroundColor Black -ForegroundColor Green
        }
    }
    $intProgressStatus++
}
# Return the profile to standard before exiting
$strProfileName = Get-MgProfile | Select-Object -ExpandProperty Name
if ($strProfileName -eq "beta") {
    Select-MgProfile v1.0
    Write-Host "Script has completed. Profile check has changed the profile back to v1.0." -BackgroundColor Black -ForegroundColor Green
}
else {
    Write-Host "No action required from the profile check. v1.0 is selected." -BackgroundColor Black -ForegroundColor Green
}


