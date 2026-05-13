param (
    [Parameter(Mandatory = $true)]
    [string]$ManagedIdentityDisplayName  # Display name of the Managed Identity (Enterprise App)

    # Optional: allow direct ClientId instead of display name
    ,[Parameter(Mandatory = $false)]
    [string]$ManagedIdentityClientId
)

# ---------------------------------------
# Step 1 - Connect to Microsoft Graph
# ---------------------------------------
Write-Host "Connecting to Microsoft Graph..."

Connect-MgGraph -Scopes "AppRoleAssignment.ReadWrite.All", "Application.Read.All"

# ---------------------------------------
# Step 2 - Get Resource Service Principals
# ---------------------------------------
Write-Host "Retrieving Microsoft Graph and SharePoint service principals..."

$graphSp = Get-MgServicePrincipal -Filter "appId eq '00000003-0000-0000-c000-000000000000'"
$sharePointSp = Get-MgServicePrincipal -Filter "appId eq '00000003-0000-0ff1-ce00-000000000000'"

if (-not $graphSp) {
    throw "Microsoft Graph service principal not found"
}

if (-not $sharePointSp) {
    throw "SharePoint Online service principal not found"
}

# ---------------------------------------
# Step 3 - Get Managed Identity Service Principal
# ---------------------------------------
Write-Host "Retrieving Managed Identity Service Principal..."

if ($ManagedIdentityClientId) {
    $managedIdentitySp = Get-MgServicePrincipal -Filter "appId eq '$ManagedIdentityClientId'"
} else {
    $managedIdentitySp = Get-MgServicePrincipal -Filter "displayName eq '$ManagedIdentityDisplayName'"
}

if (-not $managedIdentitySp) {
    throw "Managed Identity not found"
}

Write-Host "Found Managed Identity: $($managedIdentitySp.DisplayName)"

# ---------------------------------------
# Step 4 - Locate Sites.Selected App Role
# ---------------------------------------
Write-Host "Locating Sites.Selected permissions..."

$graphSitesSelectedRole = $graphSp.AppRoles |
    Where-Object { $_.Value -eq "Sites.Selected" -and $_.AllowedMemberTypes -contains "Application" }

$sharePointSitesSelectedRole = $sharePointSp.AppRoles |
    Where-Object { $_.Value -eq "Sites.Selected" -and $_.AllowedMemberTypes -contains "Application" }

if (-not $graphSitesSelectedRole) {
    throw "Sites.Selected role not found on Microsoft Graph"
}

if (-not $sharePointSitesSelectedRole) {
    throw "Sites.Selected role not found on SharePoint Online"
}

Write-Host "Found Graph Sites.Selected App Role ID: $($graphSitesSelectedRole.Id)"
Write-Host "Found SharePoint Sites.Selected App Role ID: $($sharePointSitesSelectedRole.Id)"

# ---------------------------------------
# Step 5 - Assign Permissions
# ---------------------------------------
Write-Host "Assigning Sites.Selected from Microsoft Graph..."

New-MgServicePrincipalAppRoleAssignment `
    -ServicePrincipalId $managedIdentitySp.Id `
    -PrincipalId $managedIdentitySp.Id `
    -ResourceId $graphSp.Id `
    -AppRoleId $graphSitesSelectedRole.Id

Write-Host "Assigning Sites.Selected from SharePoint Online..."

New-MgServicePrincipalAppRoleAssignment `
    -ServicePrincipalId $managedIdentitySp.Id `
    -PrincipalId $managedIdentitySp.Id `
    -ResourceId $sharePointSp.Id `
    -AppRoleId $sharePointSitesSelectedRole.Id

Write-Host "✅ SUCCESS: Sites.Selected assigned from Graph and SharePoint to '$($managedIdentitySp.DisplayName)'"