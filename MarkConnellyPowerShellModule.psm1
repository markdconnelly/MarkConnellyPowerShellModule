# Universal psm file
# Requires -Version 5.1

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

# Export nothing to clear implicit exports
Export-ModuleMember

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
        }
        else {

            # If module is not imported, not available on disk, but is in online gallery then install and import
            if (Find-Module -Name $module | Where-Object {$_.Name -eq $module}) {
                Write-Error "Module $module not installed, but available in an online gallery. Please install the module and try again."
            }
            else {

                # If the module is not imported, not available and not in the online gallery then abort
                Write-Error "Module $module not imported, not available and not in an online gallery, exiting."
            }
        }
    }

}


# Get function files
$functionPath = ""
$functionPath = $PSScriptRoot + "\Functions\"
Write-Verbose "Function path: $functionPath"

$functionFiles = @()
$functionFiles = @(Get-ChildItem -Path $functionPath -Recurse -Include '*.ps1' -File -ErrorAction Stop) 
Write-Verbose "Function files: $functionFiles"

# Dot source the function files 
Foreach ($function in $functionFiles){
    try {
        . ($function.DirectoryName + "\" + $function.Name) #$dotSource
        Write-Verbose "Imported $($function)"
    }
    catch {
        Write-Verbose -Message "Failed to import $($function): $_"
    }
}
 
# Export everything in the public folder
Export-ModuleMember -Function * -Alias * -Cmdlet *