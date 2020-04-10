##########################################################################################################
# Disclaimer
# The sample scripts are not supported under any Microsoft standard support program or service.
#
# The sample scripts are provided AS IS without warranty of any kind. Microsoft further disclaims all
# implied warranties including, without limitation, any implied warranties of merchantability or of fitness
# for a particular purpose. The entire risk arising out of the use or performance of the sample scripts and
# documentation remains with you. In no event shall Microsoft, its authors, or anyone else involved in the
# creation, production, or delivery of the scripts be liable for any damages whatsoever (including, without
# limitation, damages for loss of business profits, business interruption, loss of business information,
# or other pecuniary loss) arising out of the use of or inability to use the sample scripts or documentation, 
# even if Microsoft has been advised of the possibility of such damages.
##########################################################################################################

# This example script was used to create a library per project in a subsite designated by the year

Connect-PnPOnline -Url "https://<tenant>.sharepoint.com/sites/<siteUrl>/<yearSiteUrl>" # using user credentials stored in the local Windows credential manager

$fakenames = “Acme, inc.”,“Widget Corp”,“123 Warehousing”,“Demo Company”,“Smith and Co.”,“Foo Bars”,“ABC Telecom”,“Fake Brothers”,“QWERTY Logistics”,“Demo, inc.”,“Sample Company”,“Sample, inc”,“Acme Corp”,“Allied Biscuit”,“Ankh-Sto Associates”,“Extensive Enterprise”,“Galaxy Corp”,“Globo-Chem”,“Mr. Sparkle”,“Globex Corporation”,“LexCorp”,“LuthorCorp”,“North Central Positronics”,“Omni Consimer Products”,“Praxis Corporation”,“Sombra Corporation”,“Sto Plains Holdings”,“Tessier-Ashpool”

for ([int]$idx = 2187; $idx -lt 5000; $idx++) {
    [string]$projNum = "02{0}{1:d4}" -f "19", $idx
    Write-Host $projNum
    New-PnPList -Title $projNum -Url $projNum -Template DocumentLibrary -EnableContentTypes
    $lib = Get-PnPList -Identity $projNum
    Add-PnPContentTypeToList -List $projNum -ContentType "Project Document"
    Remove-PnPContentTypeFromList -List $projNum -ContentType "Document"
    Set-PnPDefaultColumnValues -List $lib -Field "Project_x0020_Number" -Value $projNum
    Set-PnPDefaultColumnValues -List $lib -Field "Customer" -Value ($fakenames[(Get-Random -Maximum ([array]$fakenames).count)])

    $rootFolder = $lib.RootFolder
    $lib.Context.Load($rootFolder)
    Invoke-PnPQuery

    $rootFolder.Context.Load($rootFolder.Folders)
    $rootFolder.Context.ExecuteQuery()

    $f1 = $rootFolder.Folders.Add("Contract - Work Authorization")
    $f1 = $rootFolder.Folders.Add("Email - Other Communications")
    $f1 = $rootFolder.Folders.Add("Invoices")
    $f1 = $rootFolder.Folders.Add("Project Documents")
    $f1 = $rootFolder.Folders.Add("Safety")
    $f1 = $rootFolder.Folders.Add("Final Reports")
    $f1 = $rootFolder.Folders.Add("Working Files")
    Invoke-PnPQuery
}