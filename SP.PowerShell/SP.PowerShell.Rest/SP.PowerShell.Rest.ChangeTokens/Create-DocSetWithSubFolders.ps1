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

# This sample was used to create all projects in a single library

Connect-PnPOnline -Url "https://<tenant>.sharepoint.com/sites/<siteurl>"  # using user credentials stored in the local Windows credential manager
$clientContext = Get-PnPContext
$fakenames = “Acme, inc.”,“Widget Corp”,“123 Warehousing”,“Demo Company”,“Smith and Co.”,“Foo Bars”,“ABC Telecom”,“Fake Brothers”,“QWERTY Logistics”,“Demo, inc.”,“Sample Company”,“Sample, inc”,“Acme Corp”,“Allied Biscuit”,“Ankh-Sto Associates”,“Extensive Enterprise”,“Galaxy Corp”,“Globo-Chem”,“Mr. Sparkle”,“Globex Corporation”,“LexCorp”,“LuthorCorp”,“North Central Positronics”,“Omni Consimer Products”,“Praxis Corporation”,“Sombra Corporation”,“Sto Plains Holdings”,“Tessier-Ashpool”
$parentFolder = Resolve-PnPFolder -SiteRelativePath ("Projects/2019")
$docSetCt = Get-PnPContentType -List Projects -Identity "Project Folder"

for ([int]$idx = 2101; $idx -lt 4100; $idx++) {
    [string]$projNum = "02{0}{1:d4}" -f "18", $idx
    Write-Output $projNum
    $docSetCreateResult = [Microsoft.SharePoint.Client.DocumentSet.DocumentSet]::Create($clientContext, $parentFolder, $projNum, $docSetCt.Id)
    $clientContext.ExecuteQuery()

    $docSetFolder = Resolve-PnPFolder -SiteRelativePath ("{0}/{1}/{2}" -f "Projects", "2019", $projNum)
    $docSetFolder.Context.Load($docSetFolder.ListItemAllFields)
    $docSetFolder.Context.ExecuteQuery()

    Set-PnPListItem -List Projects -Identity $docSetFolder.ListItemAllFields.Id -Values @{
        "HTML_x0020_File_x0020_Type" = "SharePoint.DocumentSet";
        "Project_x0020_Number" = $projNum;
        "Customer" = ($fakenames[(Get-Random -Maximum ([array]$fakenames).count)]);
    }

    $docSetFolder.Context.Load($docSetFolder.Folders)
    $docSetFolder.Context.ExecuteQuery()

    $f1 = $docSetFolder.Folders.Add("Contract - Work Authorization")
    $f1 = $docSetFolder.Folders.Add("Email - Other Communications")
    $f1 = $docSetFolder.Folders.Add("Invoices")
    $f1 = $docSetFolder.Folders.Add("Project Documents")
    $f1 = $docSetFolder.Folders.Add("Safety")
    $f1 = $docSetFolder.Folders.Add("Final Reports")
    $f1 = $docSetFolder.Folders.Add("Working Files")
    Invoke-PnPQuery
}