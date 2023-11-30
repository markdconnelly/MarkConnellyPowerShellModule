# Hide Distros From GAL
This script is intended to explicitly modify the Active Directory attribute that hides a distro from the GAL. 
This is needed in the instance that you are running Exchange Online only and a Hybrid Active Directory environment where Group Writeback is not enabled.

# Test Case
1. To test this script, create 5 dummy distribution groups locally in Active Directory and then syncing them to the cloud. 
- Test-HideFromGal01
- Test-HideFromGal02
- Test-HideFromGal03
- Test-HideFromGal04
- Test-HideFromGal05
2. Once you have verified that the objects synced successfully, look at your Global Address book and validate that they are generally visible. 
3. Copy the test csv file included in this directory to your local machine
- https://github.com/markdconnelly/MarkConnellyPowerShellModule/blob/main/Scripts/Active%20Directory/Hide%20Distros%20From%20GAL/TestCase-HideDistrosFromGAL-ADOnPrem.csv
4. Copy the script file included in this directory to your local machine
- https://github.com/markdconnelly/MarkConnellyPowerShellModule/blob/main/Scripts/Active%20Directory/Hide%20Distros%20From%20GAL/HideDistrosFromGAL112723.ps1
5. Open the script in a program that will allow debug flows
6. Set the variables at the top of the scipt to the local path where the csv is located and where you want the output report stored
7. Use the debug process (Generally F5 to step through the script and validate that it is behaving as expected)
8. If errors are found, address them and retest
9. After you are satisfied with the scripts performance, swap out the test file with your production list