<# 
    Manually load the function library files until the module loads correctly.
#>

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

# Dot source the function files 
Foreach ($function in $functionFiles){
    try {
        $dotSource = ""
        $dotSource = ($function.DirectoryName + "\" + $function.Name)
        . $dotSource
        Write-Verbose "Imported $($function)"
    }
    catch {
        Write-Verbose -Message "Failed to import $($function): $_"
    }
}
 