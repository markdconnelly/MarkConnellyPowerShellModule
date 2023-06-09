<#
.SYNOPSIS
    This function will produce an array of Azure AD users. If an export path parameter is provided, the function will export the results to a csv file.
.DESCRIPTION
    Performing a set of operations on user objects is a common task. This function quickly creates an array of those specific objects.
.NOTES
    This is a custom function written by Mark Connelly, so it may not work as intended.
    Version:        1.0
    Author:         Mark D. Connelly Jr.
    Creation Date:  04-16-2023
    Purpose/Change: Initial script development
.LINK
    https://github.com/markdconnelly/MarkConnellyPowerShellModule/blob/main/Functions/AzureAD/Get-MDCUsers.ps1
.EXAMPLE
    Get-MDCUsers
    Get-MDCUsers -ExportPath "C:\Temp\"
#>

Function Get-MDCUsers {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$false,Position=0)]
        [string]$ExportPath
    )

    # Collect array of application service principals
    $arrAAD_Users = @()
    try {
        Write-Verbose "Collecting AAD Users"
        $arrAAD_Users = Get-MgUser -All:$true -ErrorAction Stop `
        | Where-Object {$_.UserPrincipalName -notlike "svc*" `
                -and $_.UserPrincipalName -notlike "*Mailbox*" `
                -and $_.UserPrincipalName -notlike "Sync_*" `
                -and $_.UserPrincipalName -notlike "*BreakGlass*"}
    }
    catch {
        Write-Verbose "Unable to get AAD Users"
        throw "Unable to get AAD Users"
    }

    # Export the array of applications to a csv file if an export path is provided
    if($ExportPath){
        Out-MDCToCSV -psobj $arrAAD_Users -ExportPath $ExportPath -FileName "AAD_Users"
    }

    # Return the array of applications
    return $arrAAD_Users
}