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
if ($QueueItem.SiteUrl -eq $null) {
    throw "QueueItem.SiteUrl is null"
}
if ($QueueItem.TemplateName -eq $null) {
    throw "QueueItem.TemplateName is null"
}

# connect to directory site to download template
try {
    Write-Host "Retrieving template $($QueueItem.TemplateName) from directory"
    Connect-PnPOnline -Url $env:TemplateSiteUrl -ManagedIdentity
    $pnpFile = Get-PnPFile -Url ("{0}/{1}" -f $env:TemplateFolderPath, $($QueueItem.TemplateName)) -AsString

    Write-Host "Applying template to $($QueueItem.SiteUrl) with $($QueueItem.TemplateName) bytes"
    Connect-PnPOnline -Url $QueueItem.SiteUrl -ManagedIdentity

    # read the template
    $pnpTemplate = Read-PnPSiteTemplate -Xml $pnpFile

    # apply the template
    Invoke-PnPSiteTemplate -InputInstance $pnpTemplate
}
catch {
    Write-Error "Error applying template: $_"
}