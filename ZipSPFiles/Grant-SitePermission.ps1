param (
    [Parameter(Mandatory = $true)]
    [string]$SiteUrl,   # Example: https://contoso.sharepoint.com/sites/MySite

    [Parameter(Mandatory = $true)]
    [string]$AppClientId,  # Client ID of Managed Identity / App Registration

    [Parameter(Mandatory = $true)]
    [string]$AppDisplayName  # Display name to assign to the permission
)

# ---------------------------------------
# Step 1 - Connect to Microsoft Graph
# ---------------------------------------
Write-Host "Connecting to Microsoft Graph..."

# Required to grant permissions (admin operation)
Connect-MgGraph -Scopes "Sites.FullControl.All"

# ---------------------------------------
# Step 2 - Resolve Site ID
# ---------------------------------------
Write-Host "Resolving Site ID from URL..."

$uri = [System.Uri]$SiteUrl
$hostname = $uri.Host
$sitePath = $uri.AbsolutePath

# Graph site path format
$graphSitePath = "$($hostname):$($sitePath)"

# Retrieve site
$site = Get-MgSite -SiteId $graphSitePath

if (-not $site) {
    throw "Site not found: $SiteUrl"
}

$siteId = $site.Id
Write-Host "Resolved Site ID: $siteId"

# ---------------------------------------
# Step 3 - Grant Permission
# ---------------------------------------
Write-Host "Granting WRITE permission to app..."

$permissionBody = @{
    roles = @("write")
    grantedToIdentities = @(
        @{
            application = @{
                id = $AppClientId
                displayName = $AppDisplayName
            }
        }
    )
}

# Apply permission
New-MgSitePermission -SiteId $siteId -BodyParameter $permissionBody

Write-Host "✅ SUCCESS: Write permission granted to '$AppDisplayName' ($AppClientId) on site $SiteUrl"