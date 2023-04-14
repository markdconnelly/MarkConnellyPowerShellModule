<#
.SYNOPSIS
    This function will produce a psobject with admins and their various permissions. If an export path parameter is provided, the function will export the results to a csv file.
.DESCRIPTION
    Identifying excessive admin permissions is the goal. This report will provide the information that you need to identify and remediate excessive permissions.
.NOTES
    This is a custom function written by Mark Connelly, so it may not work as intended.
    This function assumes a secret store with the appropriate variables is in place. If it is not, the function will fail.
.LINK
    N/A
.EXAMPLE
    Get-MDCAzureADAdminReport
    Get-MDCAzureADAdminReport -ExportPath "C:\Temp\"
#>

Function Get-MDCAzureADAdminReport {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$false,Position=0)]
        [string]$ExportPath
    )

    # Connect to the Microsoft Graph API
    try {
        Write-Verbose "Connecting to Graph"
        Connect-MDCGraphApplication -ErrorAction Stop
    }
    catch {
        Write-Verbose "Unable to connect to Graph"
        throw "Unable to connect to Graph"
    }
    
    # Collect an array of all AAD roles with "Admin" in the name
    $arrAAD_Roles = @()
    try {
        Write-Verbose "Collecting AAD Roles"
        $arrAAD_Roles = Get-MgDirectoryRole -ErrorAction Stop | Where-Object {$_.DisplayName -like "*Admin*"}
    }
    catch {
        Write-Verbose "Unable to get AAD Roles"
        throw "Unable to get AAD Roles"
    }

    # Loop through each AAD role and collect the members
    $role = ""
    $psobjRoles = @()
    foreach($role in $arrAAD_Roles){
        Write-Verbose "Processing $($role.DisplayName)"
        # For each role, collect the members
        $arrRoleMembers = @()
        try {
            #try: Get-MgDirectoryRoleMember
            Write-Verbose "Collecting members of $($role.DisplayName)"
            $arrRoleMembers = Get-MgDirectoryRoleMember -DirectoryRoleId $role.Id -ErrorAction Stop

            # Loop through each member of the role. 
            $member = ""
            Write-Verbose "There are $($role.Count) members of $($role.DisplayName)"
            foreach($member in $arrRoleMembers){
                Write-Verbose "Processing $($member.AdditionalProperties.displayName)"
                $memberType = ""
                $memberType = $member.AdditionalProperties.'@odata.type'
                # If the member is a group, collect the members of the group
                if($memberType -like "*group*"){
                    Write-Verbose "$($member.AdditionalProperties.displayName) is a group"
                    $arrGroupMembers = @()
                    try {
                        #try: Get-MgGroupMember
                        Write-Verbose "Collecting members of group $($member.AdditionalProperties.displayName)"
                        $arrGroupMembers = Get-MgGroupMember -GroupId $member.Id -ErrorAction Stop
                        $groupMember = ""
                        foreach($groupMember in $arrGroupMembers){
                            # For each member, add a new object to the array
                            $psobjRoles += [PSCustomObject]@{
                                RoleType = "AAD"
                                RoleName = $role.DisplayName
                                MembershipType = "Group"
                                MemberName = $groupMember.AdditionalProperties.displayName
                                MemberUPN = $groupMember.AdditionalProperties.userPrincipalName
                            }
                        }
                    }
                    catch{
                        #catch: Get-MgGroupMember
                        Write-Verbose "Unable to get members of group $($member.AdditionalProperties.displayName)"
                    }
                }else{
                    Write-Verbose "$($member.AdditionalProperties.displayName) is not a group"
                    $psobjRoles += [PSCustomObject]@{
                        RoleType = "AAD"
                        RoleName = $role.DisplayName
                        MembershipType = "User"
                        MemberName = $member.AdditionalProperties.displayName
                        MemberUPN = $member.AdditionalProperties.userPrincipalName
                    }
                }
            }#End foreach($member in $arrRoleMembers)
        }           
        catch {
            #catch: Get-MgDirectoryRoleMember
            Write-Verbose "Unable to get members of role $($role.DisplayName)"
        }
    }#End foreach($role in $arrAAD_Roles)

    # If the ExportPath parameter is passed, export the results to a CSV file
    if($ExportPath){
        Write-Verbose "Exporting to $ExportPath"
        $dateNow = $null
        $strFilePathDate = $null
        $strFullFilePath = $null
        $dateNow = Get-Date 
        $strFilePathDate = $dateNow.ToString("yyyyMMddhhmm")
        $strFullFilePath = "$ExportPath\AADAdmins_$strFilePathDate.csv"
        $psobjRoles | Export-Csv -Path $strFullFilePath -NoTypeInformation
    }
}#End Function Get-GetAzureADAdministrators


