
# run the following on all servers in the farm, only if the site is not secured with HTTPS
$serviceConfig = Get-SPSecurityTokenServiceConfig;
$serviceConfig.AllowOAuthOverHttp = $true;
$serviceConfig.Update();

#####

$config = Get-SPSecurityTokenServiceConfig;
$config.AuthenticationPipelineClaimMappingRules.AddIdentityProviderNameMappingRule("OrgId Rule", [Microsoft.SharePoint.Administration.Claims.SPIdentityProviderTypes]::Forms,"membership", "urn:federation:microsoftonline");
$config.UseIncomingUriToValidateAudience = $true;
$config.Update();

Add-PSSnapin Microsoft.SharePoint.PowerShell
#Variables
$stscertpfx="c:\temp\STSSPOnline.pfx"
$stscertcer="c:\temp\STSSPOnline.cer"
$stscertpassword="pass@word1"
$spcn="*.contoso.com" # replace yourdomainname with your onpremise domain that you added to Office 365 
$spsite="http://intranet.contoso.com"
$spoappid="00000003-0000-0ff1-ce00-000000000000"
		
#Update the Certificate on the STS
$pfxCertificate=New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 $stscertpfx, $stscertpassword, 20
Set-SPSecurityTokenServiceConfig -ImportSigningCertificate $pfxCertificate 
		
#Type Yes when prompted with the following message.
#You are about to change the signing certificate for the Security Token Service. Changing the certificate to an invalid, inaccessible or non-existent certificate will cause your SharePoint installation to stop functioning. Refer to the following article for instructions on how to change this certificate: http://go.microsoft.com/fwlink/?LinkID=178475. Are you sure, you want to continue?
		
#Restart IIS so STS Picks up the New Certificate
iisreset
net stop SPTimerV4
net start SPTimerV4
		
#To Validate Certificate Replacement 
$pfxCertificate
(Get-SPSecurityTokenServiceConfig).LocalLoginProvider.SigningCertificate
		
#Do Some Conversions With the Certificates to Base64
$pfxCertificate = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 -ArgumentList $stscertpfx,$stscertpassword
$pfxCertificateBin = $pfxCertificate.GetRawCertData()
$cerCertificate = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
$cerCertificate.Import($stscertcer)
$cerCertificateBin = $cerCertificate.GetRawCertData()
$credValue = [System.Convert]::ToBase64String($cerCertificateBin)
        

# this part only needs to be run once

#Establish Remote Windows PowerShell Connection with Office 365
enable-psremoting
		
#When prompted with Are you sure you want to perform this action? type Yes for all of the actions.
new-pssession
Import-Module MSOnline -force –verbose 
Import-Module MSOnlineExtended -force –verbose
Import-Module Microsoft.PowerShell.Utility
Import-Module Microsoft.Online.SharePoint.PowerShell -Force
		
#Log on as a Global Administrator for Office 365 
Connect-MsolService
#When prompted, provide the Global Admin account for your Office 365 tenant. This would have been sent to your corporate e-mail address when you signed up for the tenant. 
		
#Register the On-Premise STS as Service Principal in Office 365
New-MsolServicePrincipalCredential -AppPrincipalId $spoappid -Type asymmetric -Usage Verify -Value $credValue 
$SharePoint = Get-MsolServicePrincipal -AppPrincipalId $spoappid
$spns = $SharePoint.ServicePrincipalNames
$spns.Add("$spoappid/$spcn") 
Set-MsolServicePrincipal -AppPrincipalId $spoappid -ServicePrincipalNames $spns 
$spocontextID = (Get-MsolCompanyInformation).ObjectID
$spoappprincipalID = (Get-MsolServicePrincipal -ServicePrincipalName $spoappid).ObjectID
$sponameidentifier = "$spoappprincipalID@$spocontextID"
		
#Finally Establish in the On-Premise Farm a Trust with the ACS
$site=Get-Spsite "$spsite"
$appPrincipal = Register-SPAppPrincipal -site $site.rootweb -nameIdentifier $sponameidentifier -displayName "SharePoint Online" 
Set-SPAuthenticationRealm -realm $spocontextID 
New-SPAzureAccessControlServiceApplicationProxy -Name "ACS" -MetadataServiceEndpointUri "https://accounts.accesscontrol.windows.net/metadata/json/1/" -DefaultProxyGroup
New-SPTrustedSecurityTokenIssuer -MetadataEndpoint "https://accounts.accesscontrol.windows.net/metadata/json/1/" -IsTrustBroker -Name "ACS"

# alternate metadata endpoint as shown in some examples for use in the above 2 lines
$metadataEndpoint = "https://accounts.accesscontrol.windows.net/" + $spocontextID + "/metadata/json/1"
