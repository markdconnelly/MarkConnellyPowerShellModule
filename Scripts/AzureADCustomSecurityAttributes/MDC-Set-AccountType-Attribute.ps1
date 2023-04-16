<#
.SYNOPSIS
  This script will set the AccountType attribute for all users and service principals in the tenant.
.DESCRIPTION
  This script will collect all users and service principals in the tenant and set the AccountType attribute to "User", "Service Account", "Application", or "Managed Identity" respectively.
.NOTES
  Version:        1.0
  Author:         Mark D. Connelly Jr.
  Creation Date:  04-16-2023
  Purpose/Change: Initial script development
#>

#----------------------------------------------------------[Declarations]----------------------------------------------------------

#Script Version
$sScriptVersion = "1.0"

#Log File Info
$sLogPath = "C:\Windows\Temp"
$sLogName = "<script_name>.log"
$sLogFile = Join-Path -Path $sLogPath -ChildPath $sLogName

#-----------------------------------------------------------[Execution]------------------------------------------------------------

#Log-Start -LogPath $sLogPath -LogName $sLogName -ScriptVersion $sScriptVersion
#Script Execution goes here
#Log-Finish -LogPath $sLogFile