Install-Module Microsoft.PowerShell.SecretManagement, Microsoft.PowerShell.SecretStore -Scope AllUsers
Register-SecretVault -Name LocalSecretStore -ModuleName Microsoft.PowerShell.SecretStore -DefaultVault

Set-Secret -Name DevPSAppID -Secret "(Your Development Application (Client) ID)"
Set-Secret -Name DevPSAppTenantID -Secret "(Your Development Tenant ID)"
Set-Secret -Name DevPSAppSecret -Secret "(Your Development Client Secret)"
Set-Secret -Name PrdPSAppID -Secret "(Your Production Application (Client) ID)"
Set-Secret -Name PrdPSAppTenantID -Secret "(Your Production Tenant ID)"
Set-Secret -Name PrdPSAppSecret -Secret "(Your Production Client Secret)"

Get-SecretInfo -Vault LocalSecretStore