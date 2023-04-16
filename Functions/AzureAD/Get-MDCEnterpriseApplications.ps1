<#
.SYNOPSIS
    This function will produce an array of Azure AD Enterprise Applications. If an export path parameter is provided, the function will export the results to a csv file.
.DESCRIPTION
    Performing a set of operations on application service principals is a common task. This function quickly creates an array of those specific objects.
.NOTES
    This is a custom function written by Mark Connelly, so it may not work as intended.
.LINK
    N/A
.EXAMPLE
    Get-MDCAzureADAdminReport
    Get-MDCAzureADAdminReport -ExportPath "C:\Temp\"
#>