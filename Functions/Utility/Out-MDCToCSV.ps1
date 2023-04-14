<#
.SYNOPSIS
    This function will take a psobject and output it to the file path in the parameters with a unique file name.
.DESCRIPTION
    This module frequently creates psobjects that are used for reporting. This function will take a psobject and output it to the file path in the parameters with a unique file name.
.NOTES
    This is a custom function written by Mark Connelly, so it may not work as intended.
    This function assumes a valid psobj, file path, and name attribtue are passed to it. If it is not, the function will fail.
.LINK
    https://github.com/markdconnelly/MarkConnellyPowerShellModule/blob/main/Functions/Utility/Out-MDCToCSV.ps1
.EXAMPLE
    Out-MDCToCSV -psobj $PSObj -ExportPath $ExportPath -FileName $FileName
    Out-MDCToCSV -psobj $PSObj -ExportPath $ExportPath -FileName $FileName
#>
Function Out-MDCToCSV {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true,Position=0)]
        [PSCustomObject[]]$PSObj,
        [Parameter(Mandatory=$true,Position=1)]
        [string]$FileName,
        [Parameter(Mandatory=$true,Position=2)]
        [string]$ExportPath
    )
    $dateNow = $null
    $dateNow = Get-Date 
    $strFilePathDate = $null
    $strFilePathDate = $dateNow.ToString("yyyyMMddhhmm")
    $strFullFilePath = $null
    $strFullFilePath = $ExportPath + "\" + $FileName + "_" + $strFilePathDate + ".csv"
    $PSObj | Export-Csv -Path $strFullFilePath -NoTypeInformation
}