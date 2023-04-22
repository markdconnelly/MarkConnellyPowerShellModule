<#
.SYNOPSIS
    This function will connect to the Azure Resource Manager as an application service principal that is pre-defined.
.DESCRIPTION
    Quick connect function to refresh graph api connection. If the ProductionEnvironment parameter is not specified, the function will default to the development environment.
.INPUTS
  <Inputs if any, otherwise state None>
.OUTPUTS
  <Outputs if any, otherwise state None - example: Log file stored in C:\Windows\Temp\<name>.log>
.NOTES
    This is a custom function written by Mark Connelly, so it may not work as intended.
    Version:        1.1
    Author:         Mark D. Connelly Jr.
    Last Updated:   4-22-2023
    Creation Date:  4-17-2023
    Purpose/Change: Added error checking to get current context and perform no action if already connected in the proper context.
.LINK
    https://github.com/markdconnelly/MarkConnellyPowerShellModule/blob/main/Functions/Utility/Connect-MDCAzApplication.ps1
.EXAMPLE
    Connect-MDCAzApplication
    Connect-MDCAzApplication -ProductionEnvironment $false  
    Connect-MDCAzApplication -ProductionEnvironment $true
#>

Function Connect-MDCAzApplication {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$false,Position=0)]
        [bool]$ProductionEnvironment = $false
    )

    # Get the current Azure Resource Manager context
    $objCurrentAzContext = @()
    $objCurrentAzContext = Get-AzContext

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
        $graphTokenTesting = Get-MgUser -All $true -Top 1 -ErrorAction Stop
        $graphTokenTesting = $null
    }
    catch {
        Write-Verbose "Tested current context with $($graphTokenTesting.DisplayName) and it is not valid."
        Write-Verbose "Unable to get user from current context. Disconnecting and continuing"
        Disconnect-Graph | Out-Null
    }
    try {
        $azureTokenTesting = Get-AzSubscription -ErrorAction Stop
        $azureTokenTesting = $null
    }
    catch {
        Write-Verbose "Tested current context with $($azureTokenTesting[0].Name) and it is not valid."
        Write-Verbose "Unable to get subscription from current context. Disconnecting and continuing"
        Disconnect-AzAccount | Out-Null
    }

    if($null -ne $objCurrentAzContext){
        if($ProductionEnvironment -eq $true){
            if($objCurrentAzContext.TenantId -eq $strPrdTenantId){
                Write-Verbose "Already Connected to Production Environment"
                return
            }
            else{
                Disconnect-Graph | Out-Null
            }
        }
        else{
            if($objCurrentAzContext.TenantId -eq $strDevTenantId){
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
    Write-Verbose "Client ID: $strClientID"
    Write-Verbose "Tenant ID: $strTenantID"

    # Connect to Azure Resource Manager
    Write-Verbose "Securing client secret"
    $strClientSecretSecured = ""
    $strClientSecretSecured = ConvertTo-SecureString $strClientSecret -AsPlainText -Force
    Write-Verbose "Creating service principal credential object"
    $objServicePrincipalCredential = ""
    $objServicePrincipalCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $strClientID, $strClientSecretSecured
    Write-Verbose "Connecting to the Azure Resource Manager"
    try {
        Connect-AzAccount -ServicePrincipal -Credential $objServicePrincipalCredential -Tenant $strTenantID -ErrorAction Stop
    }
    catch {
        return "Unable to connect to the Azure Resource Manager"
    }
}