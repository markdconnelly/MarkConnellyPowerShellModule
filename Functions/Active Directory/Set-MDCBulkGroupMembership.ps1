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
        [string]$GroupName,
        [Parameter(Mandatory=$false,Position=2)]
        [string]$ExportPath
    )

    # Validate group name input
    $arrGroup = $null
    try {
        $arrGroup = Get-ADGroup -Identity $GroupName -Properties member -ErrorAction Stop
    }
    catch {
        Write-Host "Unable to resolve group: ""$GroupName""; Stopping..."
        return
    }

    $intProgress = 1
    $arrResolvedUsers = @()
    foreach($user in $UserArray){
        Write-Progress `
            -Activity 'Processing' `
            -Status "$intProgress of $($UserArray.Count)" `
            -CurrentOperation $intProgress `
            -PercentComplete (($intProgress / @($UserArray).Count) * 100)

        ##Attempt to resolve user from the provided array
        $arrUser = $null
        $arrUser = Get-ADUser -Identity $user.UserID -ErrorAction SilentlyContinue
        if($null -ne $arrUser){
            $arrResolvedUsers += $arrUser
        }
        $intProgress ++
    }
    if($arrResolvedUsers.Count -ne $UserArray.Count){
        # Alert and exit function
        Write-Host "Number of resolved users:""$($arrResolvedUsers.Count)"" does not match number of users in input:""$($UserArray.Count)""; Stopping..." `
        return
    }

    # Add users to group
    $intProgress = 1
    $psobjBulkAddResults = @()
    foreach($user in $arrResolvedUsers){
        Write-Progress `
            -Activity 'Processing' `
            -Status "$intProgress of $($arrResolvedUsers.Count)" `
            -CurrentOperation $intProgress `
            -PercentComplete (($intProgress / @($arrResolvedUsers).Count) * 100)

        # Set default flag values 
        $strError = "N/A"
        $boolAction = $false
        $boolSuccess = $true

        # Check if user is already a member of the group, if not, add user to group. If error, write error to output. 
        try{
            if($arrGroup.members -notcontains $user.distinguishedName){
                ##Add user to group
                Add-AdGroupMember `
                    -Identity $arrGroup.Sid `
                    -Members $user.Sid `
                    -ErrorAction Stop
                ##Note that action was taken
                $boolAction = $true
            }else{
                ##Note that action was not taken
                $boolAction = $false
                $strError = "User already a member of group"
            }
        }
        catch{
            ##Note that action failed; Capture error
            $boolSuccess = $false
            $strError = $Error[0].Exception.Message
        }
        # Add loop output to PSObject
        $psobjBulkAddResults += [PSCustomObject]@{
            GroupName = $arrGroup.Name
            UserName = $user.Name
            UserSam = $user.SamAccountName
            UserSid = $user.Sid
            ActionTaken = $boolAction
            ActionSuccess = $boolSuccess
            ActionError = $strError
        }
        $intProgress ++
    }

    # Export results to CSV if the export path is provided
    if($ExportPath -ne $null){
        Out-MDCToCSV -PSObj $psobjBulkAddResults -FileName "AD_BulkAddTo$($arrGroup.Name)" -ExportPath $ExportPath 
    }

    ##Summarize flags and print on screen
    $psobjBulkAddResults | Group-Object ActionTaken | Select-Object name,count
    $psobjBulkAddResults | Group-Object ActionSuccess | Select-Object name,count

    # return results for further processing
    return $psobjBulkAddResults
}