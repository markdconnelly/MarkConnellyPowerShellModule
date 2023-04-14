Install-Module Microsoft.PowerShell.SecretManagement, Microsoft.PowerShell.SecretStore -Scope AllUsers
Register-SecretVault -Name LocalSecretStore -ModuleName Microsoft.PowerShell.SecretStore -DefaultVault

Set-Secret -Name DevPSAppID = "(Your Development Application (Client) ID)"
Set-Secret -Name DevPSAppTenantID = "(Your Development Tenant ID)"
Set-Secret -Name DevPSAppSecret = "(Your Development Client Secret)"
Set-Secret -Name PrdPSAppID = "(Your Production Application (Client) ID)"
Set-Secret -Name PrdPSAppTenantID = "(Your Production Tenant ID)"
Set-Secret -Name PrdPSAppSecret = "(Your Production Client Secret)"

Get-SecretInfo -Vault LocalSecretStore