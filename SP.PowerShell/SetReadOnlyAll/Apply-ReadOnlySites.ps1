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
$allowedRoles = "Read","View Only","Limited Access","Restricted View"
$batchSize = 500

Import-Module PnP.PowerShell -ErrorAction Stop

#Add-Type -Path (Join-Path $PSScriptRoot "SPListtItemHelper.dll") -ErrorAction Stop
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint.Client") | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint.Client.Runtime") | Out-Null
Add-Type `
    -ReferencedAssemblies (
        "Microsoft.SharePoint.Client", "Microsoft.SharePoint.Client.Runtime", "System.Linq", "System.Collections", "netstandard", "System.Linq.Expressions"
    ) `
    -TypeDefinition @"
    using System;
    using Microsoft.SharePoint.Client;
    using System.Linq;
    
    namespace SP.Powershell.Helper
    {
        public static class SPPSHelper
        {
            public static System.Collections.Generic.List<ListItem> GetListItems(Microsoft.SharePoint.Client.List list, int batchSize)
            {
                System.Collections.Generic.List<ListItem> returnListItems = new System.Collections.Generic.List<ListItem>();
    
                var query = new Microsoft.SharePoint.Client.CamlQuery();
                query.ViewXml = string.Format("<View Scope='RecursiveAll'><RowLimit>{0}(</RowLimit></View>", batchSize);
    
                do
                {
                    var batchListItems = list.GetItems(query);
                    list.Context.Load(batchListItems, i => i.Include(
                        item => item.HasUniqueRoleAssignments, 
                        item => item.Id),
                        items => items.ListItemCollectionPosition
                    );
                    list.Context.ExecuteQuery();
                    returnListItems.AddRange(batchListItems.Where(item => item.HasUniqueRoleAssignments));
                    query.ListItemCollectionPosition = batchListItems.ListItemCollectionPosition;
                } while (query.ListItemCollectionPosition != null);
    
                return returnListItems;
            }
        }
    }    
"@ -ErrorAction Stop



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

        $lists = Get-PnPList -Includes Hidden,RoleAssignments,HasUniqueRoleAssignments -Connection $thisConnection
        $lists `
            | Where-Object {$_.Hidden -eq $false -and $_.HasUniqueRoleAssignments -eq $true} `
                | ForEach-Object { Set-ClientObjectReadOnly -ClientObject $_ -PnPConnection $thisConnection }

        $lists | ForEach-Object { 
            [SP.Powershell.Helper.SPPSHelper]::GetListItems($_, $batchSize) | ForEach-Object { 
                Get-PnPProperty -ClientObject $_ -Property "RoleAssignments" -Connection $thisConnection | Out-Null
                Set-ClientObjectReadOnly -ClientObject $_ -PnPConnection $thisConnection 
            } 
        }

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
        [Parameter(ValueFromPipelineByPropertyName,Mandatory=$true)]
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
                    Set-ListItemReadOnly -ListItem $ClientObject -PrincipalType $principalType -LoginId $loginId -LoginName $loginName -PnPConnection $PnPConnection -PermissionsParameter $permChanges
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
                Set-PnPListPermission -Identity $List -Group (Get-PnPGroup -Identity $LoginId -Connection $PnPConnection) -AddRole $addRole -Connection $PnPConnection -sy
            }
            foreach ($removeRole in $PermissionsParameter["RemoveRole"]) {
                Set-PnPListPermission -Identity $List -Group (Get-PnPGroup -Identity $LoginId -Connection $PnPConnection) -RemoveRole $removeRole -Connection $PnPConnection
            }
        }
        Default {
            foreach ($addRole in $PermissionsParameter["AddRole"]) {
                Set-PnPListPermission -Identity $List -User (Get-PnPUser -Identity $LoginId -Connection $PnPConnection).Email -AddRole $addRole -Connection $PnPConnection
            }
            foreach ($removeRole in $PermissionsParameter["RemoveRole"]) {
                Set-PnPListPermission -Identity $List -User (Get-PnPUser -Identity $LoginId -Connection $PnPConnection).Email -RemoveRole $removeRole -Connection $PnPConnection
            }
        }
    }
}

function Set-ListItemReadOnly
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [Microsoft.SharePoint.Client.ListItem]
        $ListItem,

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

    $ListItem.Context.Load($ListItem.ParentList)
    $ListItem.Context.ExecuteQuery()
    Write-Host "Changing $($PrincipalType) $($LoginName) for list item $($ListItem.ParentList.Title) \ $($ListItem.Id)" -ForegroundColor DarkYellow
    $PermissionsParameter

    switch ($PrincipalType) {

        SharePointGroup {
            foreach ($addRole in $PermissionsParameter["AddRole"]) {
                Set-PnPListItemPermission -List $ListItem.ParentList -Identity $ListItem.Id -Group (Get-PnPGroup -Identity $LoginId -Connection $PnPConnection) -AddRole $addRole -Connection $PnPConnection -SystemUpdate
            }
            foreach ($removeRole in $PermissionsParameter["RemoveRole"]) {
                Set-PnPListItemPermission -List $ListItem.ParentList -Identity $ListItem.Id -Group (Get-PnPGroup -Identity $LoginId -Connection $PnPConnection) -RemoveRole $removeRole -Connection $PnPConnection -SystemUpdate
            }
            Break
        }

        Default {
            foreach ($addRole in $PermissionsParameter["AddRole"]) {
                Set-PnPListItemPermission -List $ListItem.ParentList -Identity $ListItem.Id -User (Get-PnPUser -Identity $LoginId -Connection $PnPConnection).LoginName -AddRole $addRole -Connection $PnPConnection -SystemUpdate
            }
            foreach ($removeRole in $PermissionsParameter["RemoveRole"]) {
                Set-PnPListItemPermission -List $ListItem.ParentList -Identity $ListItem.Id -User (Get-PnPUser -Identity $LoginId -Connection $PnPConnection).LoginName -RemoveRole $removeRole -Connection $PnPConnection -SystemUpdate
            }
            Break
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

Write-Host "Please login with site collection administrator credentials when prompted."

Set-SiteReadOnly -SPSiteUrl $SPRootSite