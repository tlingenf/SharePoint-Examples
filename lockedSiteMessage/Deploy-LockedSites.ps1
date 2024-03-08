param (
    [Parameter(Mandatory=$true)]
    [string]$inputPath
)

Import-Module PnP.Powershell -ErrorAction Stop

$componentId = "379b3684-e3fc-4a6c-b18b-1df6fea9367b"
$messageText = "This site has been <strong>locked</strong> by your administrator.<br/><a href='mailto:support@mycompany,com'>Contact support</a> for more information."
$rootSite = "https://tenant.sharepoint.com"

Connect-PnPOnline -Url $rootSite -Interactive

# Get the app from the catalog
$app = Get-PnPApp -Identity "Locked Site Message Extension"

function Lock-Site {
    param (
        [Parameter(Mandatory=$true)]
        [string]$siteUrl
    )

    # Connect to the site
    Write-Host "Connecting to site $($siteUrl)"
    Connect-PnPOnline -Url $siteUrl

    Write-Host "Unlocking site"
    Set-PnPSite -LockState Unlock

    # Add the app to the site
    Get-PnPApp -Identity $app.Id
    Write-Host "Installing app $($app.Title)"

    Install-PnPApp -Identity $app.Id -Wait

    # Configure the message
    $ac = Get-PnPApplicationCustomizer -ClientSideComponentId $componentId
    if ($null -ne $ac.clientSideComponentProperties -and ($ac.clientSideComponentProperties | ConvertFrom-Json).Message -ne $messageText) {
        Write-Host "Updating message"
        Set-PnPApplicationCustomizer -clientSideComponentId $componentId -clientSideComponentProperties ("{{""Message"":""{0}"" }}" -f $messageText)
    }
    
    # Lock the site
    Write-Host "Locking site"
    Set-PnPSite -LockState ReadOnly

    # Disconnect from the site
    Disconnect-PnPOnline
    Write-Host "Disconnected from site"
}

$content = Get-Content $inputPath
foreach ($site in $content) {
    Lock-Site -siteUrl $site
}