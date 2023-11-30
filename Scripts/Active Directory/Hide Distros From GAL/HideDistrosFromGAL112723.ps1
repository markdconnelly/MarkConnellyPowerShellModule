# Purpose: This script is specifically written to target the root active directory object and set it's mail attribute to hide it from the GAL.
#          This is required because the Microsoft Graph commands are ineffective at modifying the cloud object without Group Write Back enabled. 
#          Because of this, the on-premises object must be modified and then synced to the cloud. There is no on prem Exchange server in this environment, so this script is used.
# Author: Mark D. Connelly Jr. 
# Date: 11/27/2020
# Version: 1.0.0
# Status: Untested

#############################################
# SET THESE VARIABLES
#############################################

# Path to the CSV file containing the groups to hide from the GAL
$csvPath = "C:\temp\HideDistrosFromGAL112723.csv"

# Path to save the exported CSV file containing the results of the script
$csvResultsPath = "C:\temp\HideDistrosFromGAL112723Results.csv"

#############################################
# SET THESE VARIABLES
#############################################

# It is assumed the machine running this script has the ActiveDirectory Module installed. If not, uncomment the next line or import the module ActiveDirectory outside of the script.
# Import-Module ActiveDirectory

# Import the CSV file and error out if unable to do so
try {
    Write-Host "Importing CSV file"
    $HideFromGalGroups = Import-Csv -Path $csvPath -ErrorAction Stop
}
catch {
    Write-Host "Error importing CSV file. Please check the file location and try again. If this error persists, please step through the code to identify the error."
    Exit
}

# Intialize psobj for result output
$psobjResultsReport = @()

# Loop through each group in the CSV file and hide it from the GAL
foreach ($Group in $HideFromGalGroups){

    # Initialize variables that are contained only in the loop
    $strGroupName = ""
    $strGroupName = $Group.name
    $boolReplaceShowInAddressBook = $false
    $boolClearShowInAddressBook = $false
    $error1 = ""
    $error2 = ""
    # End loop variable

    # Try to update the attribute msExchHideFromAddressLists to true. If it fails, instantiate the variable to false for the final report
    try {
        Set-ADObject $Group.name -replace @{msExchHideFromAddressLists=$true} -ErrorAction Stop
        $boolReplaceShowInAddressBook = $true
    }
    catch {
        $boolReplaceShowInAddressBook = $false
        $error1 = $_.Exception.Message
    }
    
    # Try to clear the ShowInAddressBook attribute. If it fails, instantiate the variable to false for the final report
    try {
        Set-ADObject $Group.name -clear ShowinAddressBook
        $boolClearShowInAddressBook = $true
    }
    catch {
        $boolClearShowInAddressBook = $false
        $error2 = $_.Exception.Message
    }

    # Populate the PSObject with the results of the loop for a final export to csv
    $psobjResultsReport += [PSCustomObject]@{
        DistroName = $strGroupName
        HiddenFromGAL = $boolReplaceShowInAddressBook
        ClearedFromGAL = $boolClearShowInAddressBook
        AttributeSet = $error1
        AttributeCleared = $error2
    } 
}

# Export the results to a CSV file
$psobjResultsReport | Export-Csv -Path $csvResultsPath -NoTypeInformation