# Change all permissions to read-only.

This solution will change all permissions to read only. The script will start at the site level and change all site permissions to Read. If the site is inheriting permissions from its parent site, it will break permission inheritance and set the new site permissions to Read. It will then find any lists (excluding hidden lists) and set any list and list item permissions to Read.

## Disclaimer
This sample code, scripts, and other resources are not supported under any Microsoft standard support program or service and are meant for illustrative purposes only.

The sample code, scripts, and resources are provided AS IS without warranty of any kind. Microsoft further disclaims all implied warranties including, without limitation, any implied warranties of merchantability or of fitness for a particular purpose. The entire risk arising out of the use or performance of this material and documentation remains with you. In no event shall Microsoft, its authors, or anyone else involved in the creation, production, or delivery of the sample be liable for any damages whatsoever (including, without limitation, damages for loss of business profits,  business interruption, loss of business information, or other pecuniary loss) arising out of the  use of or inability to use the samples or documentation, even if Microsoft has been advised of  the possibility of such damages.


# Download
Simply download the script file _Apply-ReadOnlySites.ps1_.

# Syntax Examples

1. Set the site at the SPRootSite and all subsites to read only.
```
.\Apply-ReadOnlySites.ps1 -SPRootSite "https://tenant.sharepoint.com/sites/siteurl" -Recursive
```

2. Set the site at the SPRootSite and ignore subsites.
```
.\Apply-ReadOnlySites.ps1 -SPRootSite "https://tenant.sharepoint.com/sites/siteurl"
```

3. Process all subsite trees, but ignore the currest site
```
Get-PnPSubWeb | ForEach-Object { .\Apply-ReadOnlySites.ps1 -SPRootSite $_.Url -Recursive }
```