<#
.SYNOPSIS
    This function will connect to the graph api as an application service principal that is pre-defined.
.DESCRIPTION
    Quick connect function to refresh graph api connection. If the ProductionEnvironment parameter is not specified, the function will default to the development environment.
.INPUTS
  -ProductionEnvironment: This is a boolean value that will determine which environment to connect to. If not specified, the function will default to the development environment.
.OUTPUTS
  None
.NOTES
    This is a custom function written by Mark Connelly, so it may not work as intended.
    Version:        1.0
    Author:         Mark D. Connelly Jr.
    Last Updated:   4-17-2023
    Creation Date:  4-16-2023
    Purpose/Change: Initial script development
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
    $strClientID = ""
    $strTenantID = ""
    $strClientSecret = ""
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