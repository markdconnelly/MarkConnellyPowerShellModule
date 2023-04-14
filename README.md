# MarkConnellyPowerShellModule
This repo contains a PowerShell module with my custom functions.

Assumptions:
For an example walkthrough of how these requirements are met, see this YouTube playlist:
https://youtube.com/playlist?list=PLhV3_pnB0cu10uvMz1gO6onQaa5zNOWKX

Functions in this module assume that you are connecting to the Microsoft Graph API as an application. It is assumed that this service principal has been given the proper permissions to perform the functions included in this module.

Functions also depend on the following secrets being stored in the secret store:
 - DevPSAppID = (Your Development Application (Client) ID)
 - DevPSAppTenantID = (Your Development Tenant ID)
 - DevPSAppSecret = (Your Development Client Secret)
 - PrdPSAppID = (Your Production Application (Client) ID)
 - PrdPSAppTenantID = (Your Production Tenant ID)
 - PrdPSAppSecret = (Your Production Client Secret)

See for an example:
https://github.com/markdconnelly/MarkConnellyPowerShellModule/blob/main/Scripts/Environment/Set-ModuleSecrets.ps1

This module will only work in this directory
"C:\PS_CustomModules"

That directory must also be loaded into the environment variable "$env:PSModulePath". See this document for instructions on updating:

https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_psmodulepath?view=powershell-7.3#modifying-psmodulepath-in-windows

