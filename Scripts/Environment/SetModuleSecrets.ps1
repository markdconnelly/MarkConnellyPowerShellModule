# Install the SecretManagement and Secretstore modules if they are not present
Install-Module Microsoft.PowerShell.SecretManagement, Microsoft.PowerShell.SecretStore -Scope AllUsers

# Register the LocalSecretStore as the default vault
Register-SecretVault -Name LocalSecretStore -ModuleName Microsoft.PowerShell.SecretStore -DefaultVault

# Set the password timeout to 24 hours
Set-SecretStoreConfiguration -PasswordTimeout 86400

# Set the secrets that are required for the module
Set-Secret -Name DevPSAppID -Secret "(Your Development Application (Client) ID)"
Set-Secret -Name DevPSAppTenantID -Secret "(Your Development Tenant ID)"
Set-Secret -Name DevPSAppSecret -Secret "(Your Development Client Secret)"
Set-Secret -Name PrdPSAppID -Secret "(Your Production Application (Client) ID)"
Set-Secret -Name PrdPSAppTenantID -Secret "(Your Production Tenant ID)"
Set-Secret -Name PrdPSAppSecret -Secret "(Your Production Client Secret)"

# List the secrets that have been set to validate they are configured as desired. 
Get-SecretInfo -Vault LocalSecretStore