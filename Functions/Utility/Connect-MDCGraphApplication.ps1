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
    Version:        1.1
    Author:         Mark D. Connelly Jr.
    Last Updated:   4-22-2023
    Creation Date:  4-16-2023
    Purpose/Change: Added error checking to get current context and perform no action if already connected in the proper context.
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

    # Get the current Graph context
    $objCurrentMgContext = Get-MgContext

    # Try to get the secrets from the secret store. Fail if any of the secrets are not found.
    try {
        $strPrdTenantId = Get-Secret -Name PrdPSAppTenantID -AsPlainText -ErrorAction Stop
        $strPrdAppId = Get-Secret -Name PrdPSAppID -AsPlainText -ErrorAction Stop
        $strPrdAppSecret = Get-Secret -Name PrdPSAppSecret -AsPlainText -ErrorAction Stop
        $strDevTenantId = Get-Secret -Name DevPSAppTenantID -AsPlainText -ErrorAction Stop
        $strDevAppId = Get-Secret -Name DevPSAppID -AsPlainText -ErrorAction Stop
        $strDevAppSecret = Get-Secret -Name DevPSAppSecret -AsPlainText -ErrorAction Stop
    }
    catch {
        return "Unable to access the secret store"
    }

    # If the current context is not null, check to see if the current context matches the selected environment. 
    # If it matches, return. If it does not, disconnect and continue.
    try {
        $tokenTesting = Get-MgUser -All $true -Top 1 -ErrorAction Stop
        $tokenTesting = $null
    }
    catch {
        Write-Verbose "Tested current context with $($tokenTesting.DisplayName) and it is not valid."
        Write-Verbose "Unable to get user from current context. Disconnecting and continuing"
        Disconnect-Graph | Out-Null
    }

    if($null -ne $objCurrentMgContext){
        if($ProductionEnvironment -eq $true){
            if($objCurrentMgContext.TenantId -eq $strPrdTenantId){
                Write-Verbose "Already Connected to Production Environment"
                return
            }
            else {
                Disconnect-Graph | Out-Null
            }
        }
        else{
            if($objCurrentMgContext.TenantId -eq $strDevTenantId){
                Write-Verbose "Already Connected to Development Environment"
                return
            }
            else {
                Disconnect-Graph | Out-Null
            }
        }
    }

    # Set the environment variables based on the selected environment. Production or development
    if($ProductionEnvironment -eq $true){
        Write-Verbose "Setting production environment variables"
        $strClientID = $strPrdAppId
        $strTenantID = $strPrdTenantId
        $strClientSecret = $strPrdAppSecret
    }
    else{
        Write-Verbose "Setting development environment variables"
        $strClientID = $strDevAppId
        $strTenantID = $strDevTenantId
        $strClientSecret = $strDevAppSecret
    }

    # Create the API body and request the access token
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

    # Try to connect to the graph api. If you cannot, return an error.
    try {
        Connect-Graph -Accesstoken $objAccessToken | Out-Null
        Write-Verbose "Connected to Graph API"
    }
    catch {
        return "Unable to connect to Graph API"
    }
}