This sample is losely based on the instructions found at https://learn.microsoft.com/en-us/sharepoint/dev/declarative-customization/site-design-pnp-provisioning. However the solution is customized to be able to support several different PnP Provisioning Templates hosted in a SharePoint library.

# Instructions
To deploy a Function App that can run the PnP provisioning engine from a SharePoint site template, follow these steps:
1. Create a new Function App in the Azure portal using the PowerShell runtime stack and the consumption plan. Choose a name, resource group, region, and storage account for your Function App.
2. Enable the system-assigned managed identity for the Function App under the Identity section. This will create a service principal that will be used to connect to SharePoint. 
3. Grant the service principal the Sites.FullControl.All, User.ReadBasic.All, and GroupMember.Read.All  permissions which will grant full control permission on all sites in the tenant. You can use the PnP PowerShell commands to do this, as shown in [Using PnP PowerShell in Azure Functions](https://pnp.github.io/powershell/articles/azurefunctions.html). You will need the object ID of the service principal, which you can find under the Identity section of the Function App.
``
Example: 
Add-PnPAzureADServicePrincipalAppRole -Principal "xxxxxxxxxxxxxxxxxxxxxx" -AppRole "User.ReadBasic.All" -BuiltInType MicrosoftGraph
```
4. Create a new queue named "applypnpsitetemplate" on the storage account associated with the Function App, you can use the Azure portal. Navigate to the storage account and go to the "Queues" section. Click on "Add queue" and enter "applypnpsitetemplate" as the queue name. Save the changes.
5. You will need Visual Studio Code with the Azure Functions extension enabled on your machine. Open the project in VSCode and deploy to your new function app.
6. A SharePoint site and a specific folder within its document library are required to store the PnP template files.
6. Create two new environment variables as app settings for the Function App. 
    a. The first environment variable is named TemplateSiteUrl and its value should be set to the URL of the SharePoint site that contains the library of PnP templates.    
    b. The second environment variable should be named TemplateFolderPath and its value should be set to the server-relative URL of the folder containing the PnP templates.
7. Create a Power Automate flow that will be triggered by the SharePoint site template following the instructions from https://learn.microsoft.com/en-us/sharepoint/dev/declarative-customization/site-design-pnp-provisioning. The template should pass an additional property called "TemplateName" to the flow, where you can specify the name of the PnP template file. The second action in the flow will be to save a message to an Azure Storage Queue with the following format:
```
{
"SiteUrl" : "https://tenant.sharepoint.com/sites/templatesite",
"TemplateName": "myTemplate.pnp"
}
```
8. Create a site design that will trigger a Power Automate flow when a site is created and create a Power Automate flow that will get the template name from the site design, and send them as a message to the queue that the function is listening.