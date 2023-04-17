# MarkConnellyPowerShellModule
This repo contains the PowerShell module owned and maintained by Mark D. Connelly Jr.
This module contains a number of functions and scripts that are used to perform various tasks in the Microsoft 365 and Azure environments.

## Getting Started
To get started, clone this repository to your local machine.  You can identify which directories are available by checking the following variable in your editor of choice:
```$env:PSModulePath```

On my machine, this variable is set to the following:
1. ```C:\PS_CustomModules;```
2. ```C:\Users\markconnelly\Documents\PowerShell\Modules;```
3. ```C:\Users\markconnelly\OneDrive - Imperion\Documents\PowerShell\Modules;```
4. ```c:\Users\maconnelly\.vscode\extensions\ms-vscode.powershell-2023.2.1\modules;```
5. ```C:\Program Files\WindowsPowerShell\Modules;```
6. ```C:\Program Files (x86)\WindowsPowerShell\Modules;```
7. ```C:\WINDOWS\system32\WindowsPowerShell\v1.0\Modules;```

I like to maintain separation, so I use the ```C:\PS_CustomModules``` directory to store my custom modules.  This is the directory that I cloned this repository to. Any directory that is listed in the ```$env:PSModulePath``` variable is a valid location to store your custom modules. To update the system variable to include your custom module directory, you can see the following link:
 - https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_psmodulepath?view=powershell-7.3#modifying-psmodulepath-in-windows

## Using the Module
To use the module, you must import it into your PowerShell session.  To do this, you can use the following command:
```Import-Module -Name DomainServicesPowerShellModule```

## Module Dependencies
This module has a few dependencies that must be installed before functions will operate as expected.  These dependencies are listed below:
1. Microsoft.PowerShell.SecretStore
2. Microsoft.PowerShell.SecretManagement
3. ActiveDirectory
4. Microsoft.Graph
5. Az
6. We will continue to update this list as more dependencies are identified.

## Application Service Principal Dependencies
This module assumes that you are connecing to the Microsoft Graph API as an application.  It is assumed that this service principal has been given the proper permissions to perform the functions included in this module. Application details are stored in the SecretStore and used in various quick connect functions.

See this article for more information on how to create a service principal and grant it the proper permissions:
 - https://docs.microsoft.com/en-us/graph/auth-register-app-v2
 - https://www.youtube.com/playlist?list=PLhV3_pnB0cu10uvMz1gO6onQaa5zNOWKX

Permissions required for this module are listed below:
1. Graph API:
    - Application.Read.All
    - AppRoleAssignment.ReadWrite.All
    - AuditLog.Read.All
    - CustomSecAttributeAssignment.ReadWrite.All
    - CustomSecAttributeDefinition.Read.All
    - CustomSecAttributeDefinition.ReadWrite.All
    - Device.Read.All
    - DeviceLocalCredential.Read.All
    - DeviceManagementApps.Read.All
    - DeviceManagementConfiguration.Read.All
    - DeviceManagementManagedDevices.Read.All
    - DeviceManagementRBAC.Read.All
    - DeviceManagementServiceConfig.Read.All
    - Directory.Read.All
    - Group.ReadWrite.All
    - GroupMember.ReadWrite.All
    - PrivilegedAccess.Read.AzureADGroup
    - User.ReadWrite.All
    - UserAuthenticationMethod.ReadWrite.All
2. Azure Resource Manager:
    - Reader role assigned at the top management group
    
## Secret Dependencies
This module has a few secrets that must be stored in the SecretStore in order to function properly.  These secrets are listed below:
1. Development Application:
    - DevPSAppID = (Your Development Application (Client) ID)
    - DevPSAppTenantID = (Your Development Tenant ID)
    - DevPSAppSecret = (Your Development Client Secret)

2. Production Application:
    - PrdPSAppID = (Your Production Application (Client) ID)
    - PrdPSAppTenantID = (Your Production Tenant ID)
    - PrdPSAppSecret = (Your Production Client Secret)


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

