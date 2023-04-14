<#
.SYNOPSIS
    This function will connect to the graph api as an application service principal that is pre-defined.
.DESCRIPTION
    Quick connect function to refresh graph api connection.
.NOTES
    This is a custom function written by Mark Connelly, so it may not work as intended.
    This function assumes a secret store with the appropriate variables is in place. If it is not, the function will fail.
.LINK
    https://github.com/markdconnelly/MarkConnellyPowerShellModule/blob/main/Functions/Utility/Connect-MDCGraphApplication.ps1
.EXAMPLE
    Connect-MDCGraphApplication 
    Connect-MDCGraphApplication -ProductionEnvironment $false
    Connect-MDCGraphApplication -ProductionEnvironment $true
#>

Function Connect-MDCGraphApplication {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$false,Position=0)]
        [bool]$ProductionEnvironment = $false
    )
    if($ProductionEnvironment -eq $true){
        Write-Verbose "Connecting to Production Environment"
        $strClientID = Get-Secret -Name PrdPSAppID -AsPlainText
        $strTenantID = Get-Secret -Name PrdPSAppTenantID -AsPlainText
        $strClientSecret = Get-Secret -Name PrdPSAppSecret -AsPlainText
    }
    else {
        Write-Verbose "Connecting to Development Environment"
        $strClientID = Get-Secret -Name DevPSAppID -AsPlainText
        $strTenantID = Get-Secret -Name DevPSAppTenantID -AsPlainText
        $strClientSecret = Get-Secret -Name DevPSAppSecret -AsPlainText
    }
    Write-Verbose "Client ID: $strClientID"
    Write-Verbose "Tenant ID: $strTenantID"
    Write-Verbose "Creating API uri & body to request access token"
    $strAPI_URI = "https://login.microsoftonline.com/$strTenantID/oauth2/token"
    $arrAPI_Body = @{
        grant_type = "client_credentials"
        client_id = $strClientID
        client_secret = $strClientSecret
        resource = "https://graph.microsoft.com"
    }
    Write-Verbose "Requesting access token from $strAPI_URI"
    $objAccessTokenRaw = Invoke-RestMethod -Method Post -Uri $strAPI_URI -Body $arrAPI_Body -ContentType "application/x-www-form-urlencoded"
    $objAccessToken = $objAccessTokenRaw.access_token
    Connect-Graph -Accesstoken $objAccessToken
}