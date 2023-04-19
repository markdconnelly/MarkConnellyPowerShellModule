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
    Version:        1.0
    Author:         Mark D. Connelly Jr.
    Last Updated:   4-17-2023
    Creation Date:  4-17-2023
    Purpose/Change: Initial script development
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

    # Check if you should connect to the production environment or the development environment. Set secret variables appropriately.
    $strClientID = ""
    $strTenantID = ""
    $strClientSecret = ""
    Disconnect-AzAccount -Force
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
        throw $error[0].Exception.Message
    }
}