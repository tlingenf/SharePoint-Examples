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



# This script will get all currently enabled users from Azure AD and generate a CSV file of UPNs


$outPutFolder = Join-Path $env:USERPROFILE "Desktop"


Import-Module AzureAD -ErrorAction Stop

# Get All Users From Azure AD
Write-Host "Please specify login credentials for Azure AD"
Connect-AzureAD -ErrorAction Stop

$allUsers = Get-AzureADUser -All $true -Filter "AccountEnabled eq true and UserType eq 'Member'"

# Write to CSV file
$allUsers | select UserPrincipalName | Export-Csv -Path (Join-Path $outPutFolder "UserData.csv") -NoTypeInformation -Force