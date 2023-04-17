<#
.SYNOPSIS
    This function will add an array of users to the provided AD group. The column header that is passed must be "UserID" and it must be formatted in one of the following formats.
    1. SamAccountName
    2. DN
    3. GUID
    4. SID
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

    $intProgress = 1
    $arrResolvedUsers = @()
    foreach($user in $UserArray){
        ##Progress Bar
        Write-Progress `
            -Activity 'Processing' `
            -Status "$intProgress of $($UserArray.Count)" `
            -CurrentOperation $intProgress `
            -PercentComplete (($intProgress / @($UserArray).Count) * 100)

        ##Attempt to resolve user from the provided array
        $arrUser = $null
        $arrUser = Get-ADUser -Identity $user.UserID -ErrorAction SilentlyContinue
        if($arrUser -ne $null){
            $arrResolvedUsers += $arrUser
        }
        $intProgress ++
    }
    if($arrResolvedUsers.Count -ne $UserArray.Count){
        # Alert and exit function
        Write-Host "Number of resolved users:""$($arrResolvedUsers.Count)"" does not match number of users in input:""$($UserArray.Count)""; Stopping..." `
        return
    }


}