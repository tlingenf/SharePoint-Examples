using namespace System.Net

# Import-Module Microsoft.Graph.Authentication
# Import-Module Microsoft.Graph.Groups
# Import-Module Microsoft.Graph.Users

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request. $($Request.Body)"

# Interact with query parameters or the body of the request.
$SiteUrl = $Request.Body.siteUrl

[array]$output = @()

try {
    Connect-MgGraph -Identity # -ClientId $env:ClientId -CertificateThumbprint $env:WEBSITE_LOAD_CERTIFICATES -TenantId $env:TenantId
    Write-Host "Connected to Microsoft Graph"

    # Currently an issue with compatability of the PnP PowerShell and Microsoft Graph modules using the Microsoft.Graph.Core library.
    # As a workaround, we need to make sure to query the Graph API before using PnP PowerShell.
    # The next line simply is to force the Graph API to load.
    Get-MgUser -Top 1 | Out-Null


    # Import-Module PnP.PowerShell
    Connect-PnPOnline -Url $SiteUrl -ManagedIdentity # -ClientId $env:ClientId -Thumbprint $env:WEBSITE_LOAD_CERTIFICATES -Tenant $env:TenantId
    Write-Host "Connected to PnP Online"

    [array]$siteAdmins = Get-PnPSiteCollectionAdmin
    Write-Host $siteAdmins

    foreach ($owner in $siteAdmins) {
        if ($owner.Email) {
            switch ($owner.PrincipalType) {
                "User" {
                    $output += @{
                        "DisplayName" = $owner.Title;
                        "Email" = $owner.Email;
                        "Type" = "User";
                    }
                    Write-Host "User: $($owner.Title)"
                }
                
                "SecurityGroup" {
                    $loginName = $owner.LoginName.Split("|")
                    if ($loginName[0] -eq "c:0o.c") {
                        $groupId = $loginName[2].Split("_")
                        $groupDetails = Get-MgGroup -GroupId $groupId[0] -ExpandProperty Owners
                        $output += @{
                            "DisplayName" = $groupDetails.DisplayName;
                            "Email" = $groupDetails.Mail;
                            "Type" = "Group";
                        }
                        Write-Host "Group: $($groupDetails.DisplayName)"
                        $groupDetails.Owners | ForEach-object {
                            Get-MgUser -UserId $_.Id | ForEach-Object {
                                $output += @{
                                    "DisplayName" = $_.DisplayName;
                                    "Email" = $_.UserPrincipalName;
                                    "Type" = "Group Member";
                                }
                                Write-Host "Group Owner: $($_.DisplayName)"
                            }
                        }
                    } else {
                        $output += @{
                            "DisplayName" = $owner.Title;
                            "Email" = $owner.Email;
                            "Type" = "Group";
                        }
                    }
                }
            
                Default {
                    $owner
                }
            }
        }
    }
}
catch {
    $output += @{
        "DisplayName" = $_;
        "Email" = "";
        "Type" = "Error";
    }
}

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = ConvertTo-Json -InputObject $output
})