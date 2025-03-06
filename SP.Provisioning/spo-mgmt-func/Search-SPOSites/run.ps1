using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request. $($Request.Body)"

# Interact with query parameters or the body of the request.
$searchText = $Request.Body.searchText
$SiteUrl = $Request.Body.siteUrl

[array]$output = @()

try {
    Connect-PnPOnline -Url $SiteUrl -ManagedIdentity # -ClientId $env:ClientId -Thumbprint $env:WEBSITE_LOAD_CERTIFICATES -Tenant $env:TenantId

    [string]$queryText

    if ($searchText.ToLower().StartsWith("https://")) {
        $queryText = "contentclass:STS_Site path:$($searchText)*"
    } else {
        $queryText = "contentclass:STS_Site $($searchText)*"
    }

    $searchResults = Submit-PnPSearchQuery -Query $queryText
    foreach ($result in $searchResults.ResultRows) {
        $output += @{
            "Title" = $result["Title"];
            "Url" = $result["SPWebUrl"];
        }
    }
}
catch {
    $output += @{
        "Title" = $_;
        "Url" = "Error";
    }
}

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = ConvertTo-Json -InputObject $output
})