using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request. $($Request.Body)"

# Interact with query parameters or the body of the request.
$SiteUrl = $Request.Body.siteUrl

[array]$output = @()

try {
    Connect-PnPOnline -Url $SiteUrl -ClientId $env:ClientId -Thumbprint $env:WEBSITE_LOAD_CERTIFICATES -Tenant $env:TenantId
    Connect-MgGraph -ClientId  $env:ClientId -CertificateThumbprint $env:WEBSITE_LOAD_CERTIFICATES -TenantId $env:TenantId

    [array]$siteAdmins = Get-PnPSiteCollectionAdmin

    foreach ($owner in $siteAdmins) {
        if ($owner.Email) {
            switch ($owner.PrincipalType) {
                "User" {
                    $output += @{
                        "DisplayName" = $owner.Title;
                        "Email" = $owner.Email;
                        "Type" = "User";
                    }
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
                        $groupDetails.Owners | ForEach-object {
                            Get-MgUser -UserId $_.Id | ForEach-Object {
                                $output += @{
                                    "DisplayName" = $_.DisplayName;
                                    "Email" = $_.UserPrincipalName;
                                    "Type" = "Group Member";
                                }
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
