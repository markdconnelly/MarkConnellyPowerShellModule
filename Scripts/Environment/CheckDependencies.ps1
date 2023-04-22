# Set Module Dependencies
$requiredModules = @()
$requiredModules += @(
    'Az',
    'Microsoft.Graph',
    'Microsoft.PowerShell.SecretStore',
    'Microsoft.PowerShell.SecretManagement',
    'ActiveDirectory'
)
Write-Verbose "Required modules: $requiredModules"

# Perform dependent module checks

# Loop through all required modules and check if they are imported
foreach($module in $requiredModules){
    if (Get-Module | Where-Object {$_.Name -eq $module}) {
        Write-Verbose "Module $module is already imported."
    }
    else {

        # If module is not imported, but available on disk then import
        if (Get-Module -ListAvailable | Where-Object {$_.Name -eq $module}) {
            Write-Verbose "Module $module is available for importing"
			Import-Module $module -Verbose
        }
        else {

            # If module is not imported, not available on disk, but is in online gallery then install and import
            if (Find-Module -Name $module | Where-Object {$_.Name -eq $module}) {
                Install-Module -Name $module -Force -Verbose -Scope AllUsers
                Import-Module $module -Verbose
            }
            else {

                # If the module is not imported, not available and not in the online gallery then abort
                Write-Error "Module $module not imported, not available and not in an online gallery, exiting."
            }
        }
    }

}