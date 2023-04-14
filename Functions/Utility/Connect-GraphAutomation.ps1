<#
.SYNOPSIS
    This function will connect to the graph api as an application service principal that is pre-defined.
.DESCRIPTION
    Quick connect function to refresh graph api connection.
.NOTES
    This is a custom function written by Mark Connelly, so it may not work as intended. Use at your own risk.
    This function assumes a secret store with the appropriate variables is in place. If it is not, the function will fail.
.LINK
    N/A
.EXAMPLE
    Connect-GraphAutomation
#>

Function Connect-GraphAutomation {
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
}