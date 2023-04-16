<#
.SYNOPSIS
    This function will add an array of users to the provided AD group.
.DESCRIPTION
    Bulk adding users to new groups is a common task. This function will add an array of users to the provided AD group.
.NOTES
    This is a custom function written by Mark Connelly, so it may not work as intended.
    Version:        1.0
    Author:         Mark D. Connelly Jr.
    Creation Date:  04-16-2023
    Purpose/Change: Initial script development
.LINK
    https://github.com/markdconnelly/MarkConnellyPowerShellModule/blob/main/Functions/Active%20Directory/Set-MDCBulkGroupMembership.ps1
.EXAMPLE
    Set-MDCBulkGroupMembership -UserArray $arrUsers -GroupName "TestGroup"
#>

Function Set-MDCBulkGroupMembership{
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true,Position=0)]
        [array]$UserArray,
        [Parameter(Mandatory=$true,Position=1)]
        [string]$GroupName
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