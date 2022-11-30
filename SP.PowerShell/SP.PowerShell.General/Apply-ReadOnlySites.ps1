[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [String]
    $SPRootSite,

    [Parameter()]
    [switch]
    $Recursive
)

# Constants
$allowedRoles = "Read","View Only","Limited Access"

Import-Module PnP.PowerShell -ErrorAction Stop

function Set-SiteReadOnly {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $SPSiteUrl
    )

    try {
        $thisConnection = Connect-PnPOnline -Url $SPSiteUrl -ValidateConnection -ErrorAction Stop -ReturnConnection
    
        $web = Get-PnPWeb -Includes RoleAssignments,HasUniqueRoleAssignments -Connection $thisConnection

        Write-Host "Processing web $($web.Title) ($($web.Url))" -ForegroundColor DarkYellow

        Set-ClientObjectReadOnly -ClientObject $web -PnPConnection $thisConnection

        $lists = Get-PnPList -Includes Hidden,RoleAssignments,HasUniqueRoleAssignments -Connection $thisConnection | Where-Object {$_.Hidden -eq $false -and $_.HasUniqueRoleAssignments -eq $true}
        $lists | ForEach-Object { Set-ClientObjectReadOnly -ClientObject $_ -PnPConnection $thisConnection }

        if ($Recursive) {
            $thisUri = [Uri]$SPSiteUrl
            Get-PnPSubWeb -Connection $thisConnection | ForEach-Object { Set-SiteReadOnly -SPSiteUrl ("{0}://{1}{2}" -f $thisUri.Scheme, $thisUri.Host, $_.ServerRelativeUrl) }
        }

        $thisConnection = $null
    }
    catch {
        Write-Error "An error occurred while processing site $($SPSiteUrl)"
        $_
        break
    }    
}

function Set-ClientObjectReadOnly {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [Microsoft.SharePoint.Client.ClientObject]
        $ClientObject,

        [Parameter(Mandatory=$true)]
        $PnPConnection
    )

    if (!$ClientObject.HasUniqueRoleAssignments) {
        $ClientObject.BreakRoleInheritance($true, $false)
        $ClientObject.Update()
        $ClientObject.Context.ExecuteQuery()
    }

    #Add Read Permission to Role Assignment, if not added already
    ForEach ($roleAssignment in $ClientObject.RoleAssignments)
    {
        $member = $roleAssignment.Member
        $loginId = Get-PnPProperty -ClientObject $member -Property Id -Connection $PnPConnection
        $loginName = Get-PnPProperty -ClientObject $member -Property LoginName -Connection $PnPConnection
        $principalType = Get-PnPProperty -ClientObject $member -Property PrincipalType -Connection $PnPConnection
        $rolebindings = Get-PnPProperty -ClientObject $roleAssignment -Property RoleDefinitionBindings -Connection $PnPConnection

        $permChanges = Get-RoleChangesObject -RoleBindings $rolebindings
        
        if ($permChanges.Count -gt 0) {
            switch ($ClientObject.GetType().Name) {
                Web {
                    Set-WebReadOnly -PrincipalType $principalType -LoginId $loginId -LoginName $loginName -PnPConnection $PnPConnection -PermissionsParameter $permChanges
                }
                List {
                    Set-ListReadOnly -List $ClientObject -PrincipalType $principalType -LoginId $loginId -LoginName $loginName -PnPConnection $PnPConnection -PermissionsParameter $permChanges
                }
                ListItem {

                }
                Default {}
            }
        }
    }
}

function Set-WebReadOnly
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [String]
        $PrincipalType,

        [Parameter(Mandatory=$true)]
        [Int32]
        $LoginId,

        [Parameter(Mandatory=$false)]
        [String]
        $LoginName,

        [Parameter(Mandatory=$true)]
        $PermissionsParameter,

        [Parameter(Mandatory=$true)]
        $PnPConnection
    )

    Write-Host "Changing $($PrincipalType) $($LoginName) for Web" -ForegroundColor DarkYellow
    $PermissionsParameter

    switch ($PrincipalType) {
        SharePointGroup {
            Set-PnPWebPermission -Group (Get-PnPGroup -Identity $LoginId -Connection $PnPConnection) -Connection $PnPConnection @PermissionsParameter
        }
        Default {
            Set-PnPWebPermission -User (Get-PnPUser -Identity $LoginId -Connection $PnPConnection).Email -Connection $PnPConnection @PermissionsParameter
        }
    }
}

function Set-ListReadOnly
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [Microsoft.SharePoint.Client.List]
        $List,

        [Parameter(Mandatory=$true)]
        [String]
        $PrincipalType,

        [Parameter(Mandatory=$true)]
        [Int32]
        $LoginId,

        [Parameter(Mandatory=$false)]
        [String]
        $LoginName,

        [Parameter(Mandatory=$true)]
        $PermissionsParameter,

        [Parameter(Mandatory=$true)]
        $PnPConnection
    )

    Write-Host "Changing $($PrincipalType) $($LoginName) for list $($list.Title)" -ForegroundColor DarkYellow
    $PermissionsParameter

    switch ($PrincipalType) {
        SharePointGroup {
            foreach ($addRole in $PermissionsParameter["AddRole"]) {
                Set-PnPListPermission -Identity $List -Group (Get-PnPGroup -Identity $LoginId) -AddRole $addRole -Connection $PnPConnection
            }
            foreach ($removeRole in $PermissionsParameter["RemoveRole"]) {
                Set-PnPListPermission -Identity $List -Group (Get-PnPGroup -Identity $LoginId) -RemoveRole $removeRole -Connection $PnPConnection
            }
        }
        Default {
            foreach ($addRole in $PermissionsParameter["AddRole"]) {
                Set-PnPListPermission -Identity $List -User (Get-PnPUser -Identity $LoginId).Email -AddRole $addRole -Connection $PnPConnection
            }
            foreach ($removeRole in $PermissionsParameter["RemoveRole"]) {
                Set-PnPListPermission -Identity $List -User (Get-PnPUser -Identity $LoginId).Email -RemoveRole $removeRole -Connection $PnPConnection
            }
        }
    }
}

function Get-RoleChangesObject
{
    param (
        [Parameter(Mandatory=$true)]
        [Microsoft.SharePoint.Client.RoleDefinitionBindingCollection]
        $RoleBindings
    )

    $removeRoles = $RoleBindings | Where-Object { $_.Name -notin $allowedRoles }

    $siteParams = @{}
    
    if ($null -ne $removeRoles) {
        $siteParams["RemoveRole"] = $removeRoles.Name -As [string[]]
    }

    if (($RoleBindings | Where-Object { $_.Name -in $allowedRoles }).Count -eq 0) {
        $siteParams["AddRole"] = "Read"
    }

    return $siteParams
}


# ### Main ###
Set-SiteReadOnly -SPSiteUrl $SPRootSite