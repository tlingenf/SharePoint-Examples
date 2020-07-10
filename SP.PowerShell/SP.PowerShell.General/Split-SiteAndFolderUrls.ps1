$originalUrl = "https://tenant.sharepoint.com/sites/site-collection/subsite/Shared Documents/folder 1"

$urlParts = $originalUrl.Replace('https://','') -split '/'

$continueLoop = $true
$loopCounter = $urlParts.Length

do {
    $combineParts = @()
    $pathCounter = 0

    do {
        $combineParts += $urlParts[$pathCounter]
        $pathCounter = $pathCounter + 1
    } until ($pathCounter -ge $loopCounter - 1)

    $siteUrl = [string]::Concat('https://', $combineParts -join '/')
    $folderUrl = $originalUrl.Replace($siteUrl, '')

    # attempt to create file here, if success set $continueLoop = $false
    Write-Output ("SiteUrl: {0}; Folder: {1}" -f $siteUrl, $folderUrl)

    $loopCounter = $loopCounter - 1
    if ($loopCounter -le 3) {
        $continueLoop = $false
    }
} until ($continueLoop -eq $false)