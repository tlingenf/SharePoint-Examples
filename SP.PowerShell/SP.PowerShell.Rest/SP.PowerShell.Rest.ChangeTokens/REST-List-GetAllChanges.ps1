[string]$bodyTemplateString = "{{ ""query"": {{ ""RowLimit"": ""{0}"", ""QueryOptions"": ""<QueryOptions><OptimizeFor>FolderUrls</OptimizeFor><ViewAttributes Scope='RecursiveAll'/><DateInUtc>TRUE</DateInUtc><IncludePermissions>FALSE</IncludePermissions><IncludeAttachmentUrls>TRUE</IncludeAttachmentUrls><IncludeAttachmentVersion>TRUE</IncludeAttachmentVersion><ExpandUserField>TRUE</ExpandUserField><MeetingInstanceID>-1</MeetingInstanceID><OptimizeLookups>TRUE</OptimizeLookups><Paging ListItemCollectionPositionNext='{1}'></Paging></QueryOptions>"" }} }}"
[int]$rowLimit = 1000
[string]$listItemCollectionPositionNext = "Paged=TRUE"

function SPList-GetAllChanges {
    Param (
    [Parameter(Mandatory=$true)][string]$SiteUrl,
    [Parameter(Mandatory=$true)][string]$LibraryName,
    [Parameter(Mandatory=$true)][string]$AccessToken

    )
    begin {
        $headers = @{
            "Content-Type"="application/json;odata.metadata=none";
            "Authorization"=("Bearer {0}" -f $AccessToken);
        }

        $requestUrl = "{0}/_api/web/lists/getbytitle('{1}')/GetListItemChangesSinceToken" -f $SiteUrl, $LibraryName

        # the first request will be slightly different than follow up request; goal - obtain both the next change token and the next page of results for the current change token
        # the difference is the way the Paging is formatted at the begining <Paging>TRUE</Paging> instead of <Paging ListItemCollectionPositionNext='Paged=TRUE&amp;p_ID=100'></Paging>
        $requestBody = "{{ ""query"": {{ ""RowLimit"": ""{0}"", ""QueryOptions"": ""<QueryOptions><OptimizeFor>FolderUrls</OptimizeFor><ViewAttributes Scope='RecursiveAll'/><DateInUtc>TRUE</DateInUtc><IncludePermissions>FALSE</IncludePermissions><IncludeAttachmentUrls>TRUE</IncludeAttachmentUrls><IncludeAttachmentVersion>TRUE</IncludeAttachmentVersion><ExpandUserField>TRUE</ExpandUserField><MeetingInstanceID>-1</MeetingInstanceID><OptimizeLookups>TRUE</OptimizeLookups><Paging>TRUE</Paging></QueryOptions>"" }} }}" -f $rowLimit

        $foundItems = @()
        $LastChangeToken = ""
    }
    process {
        do {
            Write-Information ("Calling {0} with {1}" -f $requestUrl, $listItemCollectionPositionNext)
            $response = Invoke-WebRequest -Uri $requestUrl -Method Post -Headers $headers -Body $requestBody
            Write-Information ("Response: Code: {0}; length: {1}" -f $response.StatusCode, $response.RawContentLength)

            [xml]$responseXml = [System.Text.Encoding]::UTF8.GetString($response.Content)
            if ($responseXml.GetListItemChangesSinceTokenResult.listitems.Changes.LastChangeToken) {
                $LastChangeToken = $responseXml.GetListItemChangesSinceTokenResult.listitems.Changes.LastChangeToken
            }

            if ($responseXml.GetListItemChangesSinceTokenResult.listitems.data.ListItemCollectionPositionNext) {
                # the PowerShell XML parser will unescape the XML fragment contained in the ListItemCollectionPositionNext attribute
                # attempt to obtain the original unescaped string without manipulation
                [string]$sub1 = $responseXml.GetListItemChangesSinceTokenResult.listitems.data.Attributes["ListItemCollectionPositionNext"].OuterXml.Replace("ListItemCollectionPositionNext=""", "")
                $listItemCollectionPositionNext = $sub1.Substring(0, $sub1.Length - 1)
            } else {
                $listItemCollectionPositionNext = $null
            }

            foreach ($item in $responseXml.GetListItemChangesSinceTokenResult.listitems.data.row) {
                $foundItems += ${"Id"=$item.ows_ID;"GUID"=$item.ows_GUID;"Etag"=$item.Etag;"StreamHash"=$item.ows_StreamHash}
            }

            $requestBody = $bodyTemplateString -f $rowLimit, $listItemCollectionPositionNext

        } while ($listItemCollectionPositionNext)

        $foundItems
    }
    end {
        Write-Information ("{0} items found." -f $foundItems.Count)
        Write-Information ("LastChangeToken: {0}" -f $LastChangeToken)
    }
}