using System;
using System.Collections.Generic;
using System.Configuration;
using System.Linq;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.SharePoint.Client;
using OfficeDevPnP.Core;
using OfficeDevPnP.Core.Framework.Provisioning.Connectors;
using OfficeDevPnP.Core.Framework.Provisioning.Model;
using OfficeDevPnP.Core.Framework.Provisioning.ObjectHandlers;
using OfficeDevPnP.Core.Framework.Provisioning.Providers.Xml;
using OfficeDevPnP.Core.Sites;
using SPExamples.Console;

/*
 * ##########################################################################################################
# Disclaimer
# The sample scripts are not supported under any Microsoft standard support program or service.
#
# The sample scripts are provided AS IS without warranty of any kind. Microsoft further disclaims all
# implied warranties including, without limitation, any implied warranties of merchantability or of fitness
# for a particular purpose. The entire risk arising out of the use or performance of the sample scripts and
# documentation remains with you. In no event shall Microsoft, its authors, or anyone else involved in the
# creation, production, or delivery of the scripts be liable for any damages whatsoever (including, without
# limitation, damages for loss of business profits, business interruption, loss of business information,
# or other pecuniary loss) arising out of the use of or inability to use the sample scripts or documentation, 
# even if Microsoft has been advised of the possibility of such damages.
##########################################################################################################
*/

namespace SPExamples.Console.CodeExamples
{
    class CloneWorkshopExample
    {
        public CloneWorkshopExample()
        {
            ConsoleColor defaultForeground = System.Console.ForegroundColor;

            // Collect information 
            string templateWebUrl = "https://tenant.sharepoint.com/sites/ws101-template";

            // Authentication

            // GET the template from existing site and serialize
            // Serializing the template for later reuse is optional
            ProvisioningTemplate template = GetProvisioningTemplate(defaultForeground, templateWebUrl);

            // Create a new communication site
            var dateStamp = DateTime.Now.ToString("MM-dd-yyyyThh-mm-ss");
            string targetWebUrl = $"https://tenant.sharepoint.com/sites/ws101_{dateStamp}";
            var siteTitle = $"Workshop 101 - {dateStamp}";
            var newSiteUrl = CreateNewCommunicationSite(targetWebUrl, siteTitle, $"Workshop 101 class site for the {siteTitle} session.");

            // APPLY the template to new site from 
            ApplyProvisioningTemplate(defaultForeground, newSiteUrl.Result, template);
        }

        private static ProvisioningTemplate GetProvisioningTemplate(ConsoleColor defaultForeground, string webUrl)
        {
            AuthenticationManager authManager = new AuthenticationManager();
            using (var ctx = authManager.GetAzureADAppOnlyAuthenticatedContext(
               webUrl,
               ConfigurationManager.AppSettings["clientId"] as string,
               ConfigurationManager.AppSettings["tenantId"] as string,
               ConfigurationManager.AppSettings["pfxPath"] as string,
               ConfigurationManager.AppSettings["pfxPass"] as string))
            {
                ctx.RequestTimeout = Timeout.Infinite;

                // Just to output the site details
                Web web = ctx.Web;
                ctx.Load(web, w => w.Title);
                ctx.ExecuteQueryRetry();

                System.Console.ForegroundColor = ConsoleColor.White;
                System.Console.WriteLine("Your site title is:" + ctx.Web.Title);
                System.Console.ForegroundColor = defaultForeground;

                ProvisioningTemplateCreationInformation ptci
                        = new ProvisioningTemplateCreationInformation(ctx.Web);

                // Create FileSystemConnector to store a temporary copy of the template 
                ptci.FileConnector = new FileSystemConnector(@"c:\temp\pnpprovisioningdemo", "");
                ptci.PersistComposedLookFiles = true;
                ptci.ProgressDelegate = delegate (String message, Int32 progress, Int32 total)
                {
                    // Only to output progress for console UI
                    System.Console.WriteLine("{0:00}/{1:00} - {2}", progress, total, message);
                };

                // Execute actual extraction of the template
                ProvisioningTemplate template = ctx.Web.GetProvisioningTemplate(ptci);

                // We can serialize this template to save and reuse it
                // Optional step 
                XMLTemplateProvider provider =
                        new XMLFileSystemTemplateProvider(@"c:\temp\pnpprovisioningdemo", "");
                provider.SaveAs(template, "PnPProvisioningDemo.xml");

                return template;
            }
        }

        private static async Task<string> CreateNewCommunicationSite(string newSiteUrl, string title, string description)
        {
            Uri siteUri = new Uri(newSiteUrl);
            AuthenticationManager authManager = new AuthenticationManager();
            using (var ctx = authManager.GetAzureADAppOnlyAuthenticatedContext(
               $"{siteUri.Scheme}://{siteUri.Host}",
               ConfigurationManager.AppSettings["clientId"] as string,
               ConfigurationManager.AppSettings["tenantId"] as string,
               ConfigurationManager.AppSettings["pfxPath"] as string,
               ConfigurationManager.AppSettings["pfxPass"] as string))
            {
                // Create new "modern" communication site at the url https://[tenant].sharepoint.com/sites/mymoderncommunicationsite
                var communicationContext = await ctx.CreateSiteAsync(new CommunicationSiteCollectionCreationInformation
                {
                    Title = title,
                    Description = description,
                    Lcid = 1033, // Mandatory
                    AllowFileSharingForGuestUsers = false, // Optional
                    SiteDesign = CommunicationSiteDesign.Blank, // Mandatory
                    Url = newSiteUrl, // Mandatory
                    Owner = "admin@M365x419243.onmicrosoft.com"
                });
                communicationContext.Load(communicationContext.Web, w => w.Url);
                communicationContext.ExecuteQueryRetry();
                System.Console.WriteLine(communicationContext.Web.Url);
                return communicationContext.Web.Url;
            }
        }

        private static void ApplyProvisioningTemplate(ConsoleColor defaultForeground, string webUrl, ProvisioningTemplate template)
        {
            AuthenticationManager authManager = new AuthenticationManager();
            using (var ctx = authManager.GetAzureADAppOnlyAuthenticatedContext(
               webUrl,
               ConfigurationManager.AppSettings["clientId"] as string,
               ConfigurationManager.AppSettings["tenantId"] as string,
               ConfigurationManager.AppSettings["pfxPath"] as string,
               ConfigurationManager.AppSettings["pfxPass"] as string))
            {
                ctx.RequestTimeout = Timeout.Infinite;

                // Just to output the site details
                Web web = ctx.Web;
                ctx.Load(web, w => w.Title);
                ctx.ExecuteQueryRetry();

                System.Console.ForegroundColor = ConsoleColor.White;
                System.Console.WriteLine("Your site title is:" + ctx.Web.Title);
                System.Console.ForegroundColor = defaultForeground;

                // We could potentially also upload the template from file system, but we at least need this for branding file
                //XMLTemplateProvider provider =
                //       new XMLFileSystemTemplateProvider(@"c:\temp\pnpprovisioningdemo", "");
                //template = provider.GetTemplate("PnPProvisioningDemo.xml");

                ProvisioningTemplateApplyingInformation ptai
                        = new ProvisioningTemplateApplyingInformation();
                ptai.ProgressDelegate = delegate (String message, Int32 progress, Int32 total)
                {
                    System.Console.WriteLine("{0:00}/{1:00} - {2}", progress, total, message);
                };

                // Associate file connector for assets
                FileSystemConnector connector = new FileSystemConnector(@"c:\temp\pnpprovisioningdemo", "");
                template.Connector = connector;

                // Since template is actual object, we can modify this using code as needed
                template.Lists.Add(new ListInstance()
                {
                    Title = "PnP Sample Contacts",
                    Url = "lists/PnPContacts",
                    TemplateType = (Int32)ListTemplateType.Contacts,
                    EnableAttachments = true
                });

                web.ApplyProvisioningTemplate(template, ptai);
            }
        }

        public static void Run()
        {
            var newCodeExample = new CloneWorkshopExample();
        }
    }
}
