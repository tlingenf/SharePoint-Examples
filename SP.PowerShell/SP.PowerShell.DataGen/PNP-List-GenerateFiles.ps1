
function SPList-GenerateFiles {
    Param(
        [Parameter(Mandatory=$true)][string]$SiteUrl,
        [Parameter(Mandatory=$true)][string]$LibName,
        [Parameter(Mandatory=$true)][string]$DummyFilePath,
        [Parameter(Mandatory=$false)][string]$SiteRelativeFolderUrl = "Shared%20Documents",
        [Parameter(Mandatory=$true)][int]$NumItems
    )
    begin {
        Connect-PnPOnline -Url $SiteUrl
    }
    process {
        for([int]$i = 0; $i -le $NumItems; $i++) {
            Add-PnPFile -Path $DummyFilePath -Folder $SiteRelativeFolder -NewFileName ("File {0:0000}.txt" -f $i)
        }
    }
    end {
        Disconnect-PnPOnline
    }
}