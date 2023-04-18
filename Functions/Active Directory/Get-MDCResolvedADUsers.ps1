<#
.SYNOPSIS
    This function will take an input array, and return an array of resolved users with properties that are available.
.DESCRIPTION
    It is common to get a spreadsheet of users and be asked to perform a task on that list. Before you can do anything with the list, 
    you need to resolve the users to against Active Directory so that operations are only carried on on valid users. 
    This function will take an input array, and return an array of resolved users with all of the properties that are available.
.INPUTS
    $UserArray - An array of users to resolve
    $ExportPath - The path to export the resolved users to
.OUTPUTS
    $psobjResolvedUsersAD - An array of resolved users with properties that are available in Active Directory.
.NOTES
    This is a custom function written by Mark Connelly, so it may not work as intended.
    Version:        1.0
    Author:         Mark D. Connelly Jr. 
    Last Updated:   4-18-2023
    Creation Date:  4-18-2023
    Purpose/Change: Initial script development
.LINK
    https://github.com/markdconnelly/MarkConnellyPowerShellModule/blob/main/Functions/Active%20Directory/Get-MDCResolvedADUsers.ps1
.EXAMPLE
    Get-MDCResolvedADUsers -UserArray $users -ExportPath "C:\Temp\ResolvedUsers.csv"" 
#>

Function Get-MDCResolvedADUsers {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true,Position=0)]
        [array]$UserArray,
        [Parameter(Mandatory=$false,Position=1)]
        [string]$ExportPath
    )
    $psobjResolvedUsersAD = @()

    # Loop through all of the users in the input array and try to resolve them against Active Directory
    foreach($user in $UserArray){
        $objError = ""
        $arrGetADUser = @()
        try{
            $arrGetADUser = Get-ADUser -Identity $user.UserID -Properties * -ErrorAction Stop
            Write-Verbose "Resolved $($user.UserID) to $($arrGetADUser.SamAccountName)"
            $psobjResolvedUsersAD += [PSCustomObject]@{
                UserPrincipalName = $user.UserPrincipalName
                GUID = $user.ObjectGUID
                SamAccountName = $user.SamAccountName
                SID = $user.SID
                City = $user.City
                Company = $user.Company
                Country = $user.Country
                Created = $user.Created
                Department = $user.Department
                Description = $user.Description
                EmailAddress = $user.mail
                EmployeeID = $user.EmployeeID
                State = $user.State
                StreetAddress = $user.StreetAddress
                Title = $user.Title
                OperationStatus = "Success"
                Error = "N/A"
            }
        }catch{
            Write-Verbose "Unable to resolve $($user.UserID)"
            $objError = $Error[0].Exception.Message
            $psobjResolvedUsersAD += [PSCustomObject]@{
                UserPrincipalName = $user.UserID
                GUID = "N/A"
                SamAccountName = "N/A"
                SID = "N/A"
                City = "N/A"
                Company = "N/A"
                Country = "N/A"
                Created = "N/A"
                Department = "N/A"
                Description = "N/A"
                EmailAddress = "N/A"
                EmployeeID = "N/A"
                State = "N/A"
                StreetAddress = "N/A"
                Title = "N/A"
                OperationStatus = "Failure"
                Error = $objError
            }
        }
    }

    # Export results to CSV if the export path is provided
    if($ExportPath -ne $null){
        Out-MDCToCSV -PSObj $psobjResolvedUsersAD -FileName "AD_ResolutionCheck" -ExportPath $ExportPath 
    }

    # Return the array of resolved users and their properties. Failures will be noted in the OperationStatus and Error properties.
    return $psobjResolvedUsersAD
}