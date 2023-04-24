<#
.SYNOPSIS
    This function will produce a psobject with admins and their various permissions. If an export path parameter is provided, the function will export the results to a csv file.
.DESCRIPTION
    Identifying excessive admin permissions is the goal. This report will provide the information that you need to identify and remediate excessive permissions in Azure AD.
.NOTES
    This is a custom function written by Mark Connelly, so it may not work as intended.
    Version:        1.0
    Author:         Mark D. Connelly Jr.
    Last Updated:   04-19-2023 - Mark Connelly
    Creation Date:  04-16-2023
    Purpose/Change: Cleaning structure and adding verbose error handling to the function.
.LINK
    https://github.com/markdconnelly/MarkConnellyPowerShellModule/blob/main/Functions/AzureAD/Get-MDCAzureADAdminReport.ps1
.EXAMPLE
    Get-MDCAzureADAdminReport
    Get-MDCAzureADAdminReport -ExportPath "C:\Temp\"
#>

Function Get-MDCAzureADAdminReport {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$false,Position=0)]
        [string]$ExportPath,
        [Parameter(Mandatory=$false,Position=1)]
        [bool]$ProductionEnvironment = $false
    )

    # Connect to the Microsoft Graph API
    try {
        Write-Verbose "Connecting to Graph"
        Connect-MDCGraphApplication -ProductionEnvironment $ProductionEnvironment -ErrorAction Stop | Out-Null
        Write-Verbose "Connected to Graph"
    }
    catch {
        Write-Host "Unable to connect to Graph" -BackgroundColor Black -ForegroundColor Red
        return
    }
    
    # Collect an array of all AAD roles with "Admin" in the name
    $arrAAD_Roles = @()
    try {
        Write-Verbose "Collecting AAD Roles"
        $arrAAD_Roles = Get-MgDirectoryRole -ErrorAction Stop | Where-Object {$_.DisplayName -like "*Admin*"}
    }
    catch {
        Write-Host "Unable to get AAD Roles" -BackgroundColor Black -ForegroundColor Red
        return
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
                            Write-Verbose "Creating an entry for $($groupMember.AdditionalProperties.displayName)"
                            # For each member, add a new object to the array
                            $psobjRoles += [PSCustomObject]@{
                                RoleType = "AAD"
                                RoleName = $role.DisplayName
                                MembershipType = "Group - $($member.DisplayName)"
                                MemberName = $groupMember.AdditionalProperties.displayName
                                MemberUPN = $groupMember.AdditionalProperties.userPrincipalName
                                MemberObjId = $groupMember.ObjectId
                            }
                        }
                    }
                    catch{
                        #catch: Get-MgGroupMember
                        $objError = $Error[0].Exception.Message
                        Write-Host "Unable to get members of group $($member.AdditionalProperties.displayName)" -BackgroundColor Black -ForegroundColor Red
                        Write-Host $objError -BackgroundColor Black -ForegroundColor Red
                    }
                }else{
                    Write-Verbose "Standard user assignment. Creating entry for $($roleAssignment.DisplayName)"
                    $psobjRoles += [PSCustomObject]@{
                        RoleType = "AAD"
                        RoleName = $role.DisplayName
                        MembershipType = $memberType
                        MemberName = $member.AdditionalProperties.displayName
                        MemberUPN = $member.AdditionalProperties.userPrincipalName
                        MemberObjId = $roleAssignment.ObjectId
                    }
                }
            }#End foreach($member in $arrRoleMembers)
        }           
        catch {
            #catch: Get-MgDirectoryRoleMember
            Write-Host "Unable to get members of role $($role.DisplayName)" -BackgroundColor Black -ForegroundColor Red
        }
    }#End foreach($role in $arrAAD_Roles)

    # If the ExportPath parameter is passed, export the results to a CSV file
    if($ExportPath){
        
        try {
            Write-Verbose "Exporting Azure Resource Admin Report to $ExportPath"
            Out-MDCToCSV -PSObj $psobjRoles -ExportPath $ExportPath -FileName "AzureResourceAdminReport"
            Write-Verbose "Export completed"
        }
        catch {
            $objError = $Error[0].Exception.Message
            Write-Host "Unable to export Azure Resource Admin Report to $ExportPath" -BackgroundColor Black -ForegroundColor Red
            Write-Host $objError -BackgroundColor Black -ForegroundColor Red
        }
        
    }

    # Return the array of permissions and details
    Write-Verbose "Operation Completed. Returning array of permissions"
    return $psobjRoles
}#End Function Get-GetAzureADAdministrators
Get-MDCAzureADAdminReport


