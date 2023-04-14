<#
.SYNOPSIS
    This function will take a psobject and output it to the file path in the parameters with a unique file name.
.DESCRIPTION
    This module frequently creates psobjects that are used for reporting. This function will take a psobject and output it to the file path in the parameters with a unique file name.
.NOTES
    This is a custom function written by Mark Connelly, so it may not work as intended.
    This function assumes a valid file path and name attribtue are passed to it. If it is not, the function will fail.
.LINK
    N/A
.EXAMPLE
    Out-MDCToCSV -psobj $psobj -ExportPath $ExportPath -FileName $FileName
    Out-MDCToCSV -psobj $psobj -ExportPath $ExportPath -FileName $FileName
#>