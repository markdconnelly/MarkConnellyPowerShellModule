$certThumbprint = "ad63355c56c80f2b933e0e63e5d29dd6f2cacc74"

# Connect to Azure
#Connect-AzAccount

# Get all subscriptions
$arrAzureSubscriptions = @()
# Try to get Azure subscriptions and build an array of resources. If unable to get subscriptions, stop the function.
try {
    $arrAzureSubscriptions = Get-AzSubscription -ErrorAction Stop | Where-Object {$_.State -eq "Enabled"}
    Write-Verbose "Subscriptions collected"
    foreach($sub in $arrAzureSubscriptions){
        $subDisplayName = ""
        $subDisplayName = $sub.DisplayName
        Set-AzContext -SubscriptionId $sub.Id | Out-Null
        Write-Verbose "Context set to subscription $subDisplayName"
        $arrAzureResourceGroups += Get-AzResourceGroup -ErrorAction SilentlyContinue
        Write-Verbose "Resource groups collected for subscription $subDisplayName"
    }
    Write-Verbose "Array of resource groups populated"
}
catch {
    $objError = $Error[0].Exception.Message
    Write-Host "Unable to retrieve Azure Subscriptions. Stopping..." -BackgroundColor Black -ForegroundColor Red
    Write-Host $objError -BackgroundColor Black -ForegroundColor Red
    return
}

foreach($sub in $arrAzureSubscriptions){


foreach ($rg in $arrAzureResourceGroups) {
    $name = ""
    $name = $rg.ResourceGroupName
    $id = $rg.ResourceId

    try {
        $certificates = $null
        $certificates = Get-AzWebAppCertificate -ResourceGroupName $rgName
        foreach ($certificate in $certificates) {
            if ($certificate.Thumbprint -eq $certThumbprint) {
                $currentOutput = ""
                $currentOutput = "Certificate Matched for ResourceGroup: $name Resource: $id"
                $output += $currentOutput
            }
        }
    }
    catch {
        Write-Host "Certificate Not Found for $name in resource group $rgName"
    }

}
}

$appServices.Count

Get-AzWebAppSSLBinding -Name $appService[4].ResourceGroup

$appService

Set-AzContext -SubscriptionId "c174e81d-a427-4875-88c2-a962e99d18e5"

Get-AzWebAppCertificate -ResourceGroupName "US_NC_HAMP_HAORG_RG"

$Error[0].Exception.Message
