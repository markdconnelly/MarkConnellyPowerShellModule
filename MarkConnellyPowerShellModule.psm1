# Universal psm file
# Requires -Version 5.0

# Export nothing to clear implicit exports
Export-ModuleMember

# Get function files
$moduleDirectory = ""
$moduleDirectory = "C:\PS_CustomModules\MarkConnellyPowerShellModule"
Write-Verbose "Module directory: $moduleDirectory"
$functionPath = ""
$functionPath = $moduleDirectory + "\Functions\"
Write-Verbose "Function path: $functionPath"
$functionFiles = @()
$functionFiles = @(Get-ChildItem -Path $functionPath -Recurse -Include '*.ps1' -File -ErrorAction Stop) 
Write-Verbose "Function files: $functionFiles"

# Dot source the files 
Foreach ($function in $functionFiles){
    try {
        . ($function.DirectoryName + "\" + $function.Name)
        Write-Verbose "Imported $($function)"
    }
    catch {
        Write-Verbose -Message "Failed to import $($function): $_"
    }
}
 
# Export everything in the public folder
Export-ModuleMember -Function * -Alias * -Cmdlet *