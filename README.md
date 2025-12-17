# MarkConnellyPowerShellModule

[![PowerShell](https://img.shields.io/badge/PowerShell-5391FE?style=flat&logo=powershell&logoColor=white)](https://docs.microsoft.com/en-us/powershell/)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![GitHub release](https://img.shields.io/github/v/release/markdconnelly/MarkConnellyPowerShellModule)](https://github.com/markdconnelly/MarkConnellyPowerShellModule/releases)

A PowerShell module containing custom functions for automating administrative tasks in **Microsoft 365** and **Azure** environments. This module simplifies common operations through Microsoft Graph API and Azure Resource Manager integration.

## Overview

This module provides a collection of PowerShell functions designed to streamline administrative workflows for IT professionals managing Microsoft cloud environments. It features built-in authentication handling via service principals and secure credential management through PowerShell SecretStore.

### Key Features

- **Microsoft Graph API Integration**: Manage users, groups, devices, applications, and more through Microsoft Graph
- **Azure Resource Management**: Query and manage Azure resources across subscriptions
- **Secure Authentication**: Service principal-based authentication with SecretStore credential management
- **Environment Switching**: Quick switching between development and production environments
- **Custom Security Attributes**: Support for Entra ID custom security attributes
- **Device Management**: Intune and device credential management capabilities

## Installation

### Prerequisites

Ensure the following PowerShell modules are installed:

```powershell
# Install required modules
Install-Module -Name Microsoft.PowerShell.SecretStore -Scope CurrentUser
Install-Module -Name Microsoft.PowerShell.SecretManagement -Scope CurrentUser
Install-Module -Name Microsoft.Graph -Scope CurrentUser
Install-Module -Name Az -Scope CurrentUser
```

For on-premises Active Directory functions, ensure the **ActiveDirectory** module is available (included with RSAT).

### Clone the Repository

1. Identify available module paths:
   ```powershell
   $env:PSModulePath -split ';'
   ```

2. Clone to a directory in your module path:
   ```powershell
   git clone https://github.com/markdconnelly/MarkConnellyPowerShellModule.git C:\PS_CustomModules\MarkConnellyPowerShellModule
   ```

3. If using a custom directory, add it to your module path:
   ```powershell
   # Add to user environment variable
   [Environment]::SetEnvironmentVariable(
       "PSModulePath",
       "$env:PSModulePath;C:\PS_CustomModules",
       [EnvironmentVariableTarget]::User
   )
   ```

   For more details, see: [Modifying PSModulePath in Windows](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_psmodulepath?view=powershell-7.3#modifying-psmodulepath-in-windows)

### Import the Module

```powershell
Import-Module -Name MarkConnellyPowerShellModule
```

## Configuration

### Azure AD Application Setup

This module authenticates using an Azure AD service principal. Create and configure an application registration:

1. Register an application in Azure AD
2. Create a client secret
3. Grant the required API permissions (see below)
4. Store credentials in SecretStore

**Resources:**
- [Register an application with Microsoft identity platform](https://docs.microsoft.com/en-us/graph/auth-register-app-v2)
- [Video Playlist: Microsoft Graph Authentication](https://www.youtube.com/playlist?list=PLhV3_pnB0cu10uvMz1gO6onQaa5zNOWKX)

### Required API Permissions

#### Microsoft Graph API

| Permission | Type | Description |
|------------|------|-------------|
| Application.Read.All | Application | Read all applications |
| AppRoleAssignment.ReadWrite.All | Application | Manage app role assignments |
| AuditLog.Read.All | Application | Read audit logs |
| CustomSecAttributeAssignment.ReadWrite.All | Application | Manage custom security attribute assignments |
| CustomSecAttributeDefinition.Read.All | Application | Read custom security attribute definitions |
| CustomSecAttributeDefinition.ReadWrite.All | Application | Manage custom security attribute definitions |
| Device.Read.All | Application | Read all devices |
| DeviceLocalCredential.Read.All | Application | Read device local credentials |
| DeviceManagementApps.Read.All | Application | Read Intune apps |
| DeviceManagementConfiguration.Read.All | Application | Read Intune configuration |
| DeviceManagementManagedDevices.Read.All | Application | Read managed devices |
| DeviceManagementRBAC.Read.All | Application | Read Intune RBAC settings |
| DeviceManagementServiceConfig.Read.All | Application | Read Intune service config |
| Directory.Read.All | Application | Read directory data |
| Group.ReadWrite.All | Application | Manage groups |
| GroupMember.ReadWrite.All | Application | Manage group memberships |
| PrivilegedAccess.Read.AzureADGroup | Application | Read privileged access for groups |
| User.ReadWrite.All | Application | Manage users |
| UserAuthenticationMethod.ReadWrite.All | Application | Manage authentication methods |

#### Azure Resource Manager

- **Reader** role assigned at the top-level management group

### Secret Store Configuration

Store your application credentials securely using PowerShell SecretStore:

```powershell
# Development Environment
Set-Secret -Name "DevPSAppID" -Secret "your-dev-app-id"
Set-Secret -Name "DevPSAppTenantID" -Secret "your-dev-tenant-id"
Set-Secret -Name "DevPSAppSecret" -Secret "your-dev-client-secret"

# Production Environment
Set-Secret -Name "PrdPSAppID" -Secret "your-prod-app-id"
Set-Secret -Name "PrdPSAppTenantID" -Secret "your-prod-tenant-id"
Set-Secret -Name "PrdPSAppSecret" -Secret "your-prod-client-secret"
```

For a complete setup script, see: [Set-ModuleSecrets.ps1](https://github.com/markdconnelly/MarkConnellyPowerShellModule/blob/main/Scripts/Environment/Set-ModuleSecrets.ps1)

## Usage

### Basic Usage

```powershell
# Import the module
Import-Module -Name MarkConnellyPowerShellModule

# Connect to Microsoft Graph (production)
Connect-MgGraphApp -Environment Production

# Connect to Microsoft Graph (development)
Connect-MgGraphApp -Environment Development
```

### Example Workflows

```powershell
# Get all users with a specific attribute
Get-MgUser -Filter "department eq 'IT'"

# Manage group memberships
Add-MgGroupMember -GroupId $groupId -UserId $userId

# Query Azure resources
Get-AzResource -ResourceType "Microsoft.Compute/virtualMachines"
```

## Module Structure

```
MarkConnellyPowerShellModule/
├── Functions/              # PowerShell function files
├── Scripts/
│   └── Environment/        # Environment setup scripts
├── LICENSE                 # GPL-3.0 License
├── README.md              # This file
└── MarkConnellyPowerShellModule.psd1  # Module manifest
```

## Roadmap

Track upcoming features and improvements on the [Project Board](https://github.com/users/markdconnelly/projects/1/views/1).

## Dependencies

| Module | Purpose |
|--------|---------|
| Microsoft.PowerShell.SecretStore | Secure credential storage |
| Microsoft.PowerShell.SecretManagement | Secret management interface |
| Microsoft.Graph | Microsoft Graph API access |
| Az | Azure Resource Manager access |
| ActiveDirectory | On-premises AD management |

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.

## Author

**Mark D. Connelly Jr.**

- GitHub: [@markdconnelly](https://github.com/markdconnelly)

## Acknowledgments

- Microsoft Graph documentation and community
- PowerShell community contributors
- Azure documentation team
