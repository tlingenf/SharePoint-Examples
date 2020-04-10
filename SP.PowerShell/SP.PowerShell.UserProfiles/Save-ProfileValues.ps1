##########################################################################################################
# Disclaimer
# This sample code, scripts, and other resources are not supported under any Microsoft standard support 
# program or service and are meant for illustrative purposes only.
#
# The sample code, scripts, and resources are provided AS IS without warranty of any kind. Microsoft 
# further disclaims all implied warranties including, without limitation, any implied warranties of 
# merchantability or of fitness for a particular purpose. The entire risk arising out of the use or 
# performance of this material and documentation remains with you. In no event shall Microsoft, its 
# authors, or anyone else involved in the creation, production, or delivery of the sample be liable 
# for any damages whatsoever (including, without limitation, damages for loss of business profits, 
# business interruption, loss of business information, or other pecuniary loss) arising out of the 
# use of or inability to use the samples or documentation, even if Microsoft has been advised of 
# the possibility of such damages.
##########################################################################################################
Import-Module SharePointPnPPowerShellOnline -ErrorAction Stop

$siteUrl = "https://trlingen-admin.sharepoint.com"
$csvFilePath = "C:\Users\trlingen\Code\CommonUtil\SPPowerShellSnippets\UserData.csv"

$csvInput = Import-Csv -Path $csvFilePath

Connect-PnPOnline -Url $siteUrl -Credential TrlingenDev -ErrorAction Stop

[int]$idx = 0

foreach ($row in $csvInput) {
    Write-Progress -Activity "Importing Values" -Status $row.UserPrincipalName -CurrentOperation "Setting Skills" -PercentComplete (($idx++ / $csvInput.Count) * 100)
    $skills = $row.Skills -split ","
    Set-PnPUserProfileProperty -Account $row.UserPrincipalName -PropertyName "SPS-Skills" -Value $null
    if ($skills) {
        Set-PnPUserProfileProperty -Account $row.UserPrincipalName -PropertyName "SPS-Skills" -Values $skills
    }

    Write-Progress -Activity "Importing Values" -Status $row.UserPrincipalName -CurrentOperation "Setting Certifications" -PercentComplete (($idx / $csvInput.Count) * 100)
    $certifications = $row.Certifications -split ","
    Set-PnPUserProfileProperty -Account $row.UserPrincipalName -PropertyName "Certifications" -Value $null
    if ($certifications) {
        Set-PnPUserProfileProperty -Account $row.UserPrincipalName -PropertyName "Certifications" -Values $certifications
    }

    Write-Progress -Activity "Importing Values" -Status $row.UserPrincipalName -CurrentOperation "Setting Location" -PercentComplete (($idx / $csvInput.Count) * 100)
    Set-PnPUserProfileProperty -Account $row.UserPrincipalName -PropertyName "SPS-Location" -Value $null
    if ($row.Location) {
        Set-PnPUserProfileProperty -Account $row.UserPrincipalName -PropertyName "SPS-Location" -Value $row.Location
    }

}