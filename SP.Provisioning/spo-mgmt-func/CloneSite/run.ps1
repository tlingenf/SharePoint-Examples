# Input bindings are passed in via param block.
param($QueueItem, $TriggerMetadata)

Import-Module PnP.PowerShell -ErrorAction Stop

# Write out the queue message and insertion time to the information log.
Write-Host "PowerShell queue trigger function processed work item: $QueueItem"
Write-Host "Queue item insertion time: $($TriggerMetadata.InsertionTime)"

$QueueItem

# defensive programming
if ($QueueItem -eq $null) {
    throw "QueueItem is null"
}
if ($QueueItem.SourceSite -eq $null) {
    throw "QueueItem.SourceSite is null"
}
if ($QueueItem.DestSite -eq $null) {
    throw "QueueItem.DestSite is null"
}

# connect to directory site to download template
try {
    Write-Host "Generating template from site $($QueueItem.SourceSite)"
    Connect-PnPOnline -Url $QueueItem.SourceSite -ManagedIdentity
    $pnpTemplate = Get-PnPSiteTemplate -OutputInstance
    
    Write-Host "Applying template to site $($QueueItem.DestSite)"
    Connect-PnPOnline -Url $QueueItem.DestSite -ManagedIdentity

    # apply the template
    Invoke-PnPSiteTemplate -InputInstance $pnpTemplate
}
catch {
    Write-Error "Error applying template: $_"
}