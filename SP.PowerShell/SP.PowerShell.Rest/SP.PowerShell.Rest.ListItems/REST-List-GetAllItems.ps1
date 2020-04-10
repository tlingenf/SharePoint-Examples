function SPList-GetAllItems {
    Param (
    [Parameter(Mandatory=$true)][string]$SiteUrl,
    [Parameter(Mandatory=$true)][string]$LibraryName,
    [Parameter(Mandatory=$true)][string]$AccessToken

    )
    begin {
        $headers = @{
            "Accept"="application/json;odata=verbose";
            "Content-Type"="application/json;odata.metadata=none";
            "Authorization"=("Bearer {0}" -f $AccessToken);
        }

        $nextItemUrl = "{0}/_api/web/lists/getByTitle('{1}')/items" -f $SiteUrl, $LibraryName

        $foundItems = @()
    }
    process {
        do {
            Write-Output ("Calling {0}" -f $nextItemUrl)
            $response = Invoke-WebRequest -Uri $nextItemUrl -Headers $headers

            Write-Output ("Response: Code: {0}; length: {1}" -f $response.StatusCode, $response.RawContentLength)

            # results may have duplicate Id, ID values. Replace ID with _ID to allow casting to JSON.
            $json = $response.Content.ToString().Replace("""ID""", "_ID") | ConvertFrom-Json    

            foreach ($item in $json.d.results) {
                $foundItems += $item.GUID
            }

            $nextItemUrl = $json.d.__next

        } while ($json.d.__next);

        return $foundItems
    }
    end {
        Write-Output ("{0} items found." -f $foundItems.Count)
    }
}