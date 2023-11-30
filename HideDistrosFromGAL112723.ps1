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
    # End loop variable

    # Try to update the attribute msExchHideFromAddressLists to true. If it fails, instantiate the variable to false for the final report
    try {
        Set-ADObject $Group.name -replace @{msExchHideFromAddressLists=$true} -ErrorAction Stop
        $boolReplaceShowInAddressBook = $true
    }
    catch {
        $boolReplaceShowInAddressBook = $false
    }
    
    # Try to clear the ShowInAddressBook attribute. If it fails, instantiate the variable to false for the final report
    try {
        Set-ADObject $Group.name -clear ShowinAddressBook
        $boolClearShowInAddressBook = $true
    }
    catch {
        $boolClearShowInAddressBook = $false
    }

    # Populate the PSObject with the results of the loop for a final export to csv
    $psobjResultsReport += [PSCustomObject]@{
        DistroName = $strGroupName
        HiddenFromGAL = $boolReplaceShowInAddressBook
        ClearedFromGAL = $boolClearShowInAddressBook
    } 
}

# Export the results to a CSV file
$psobjResultsReport | Export-Csv -Path $csvResultsPath -NoTypeInformation