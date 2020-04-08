using Microsoft.SharePoint.Client;
using OfficeDevPnP.Core;
using OfficeDevPnP.Core.Framework.Provisioning.Connectors;
using OfficeDevPnP.Core.Framework.Provisioning.Model;
using OfficeDevPnP.Core.Framework.Provisioning.ObjectHandlers;
using OfficeDevPnP.Core.Framework.Provisioning.Providers;
using OfficeDevPnP.Core.Framework.Provisioning.Providers.Xml;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading;
using System.Threading.Tasks;

namespace SP.PnP.Templates
{
    public class ProvisioningHelper
    {
        public static ProvisioningTemplate GetProvisioningTemplate(string webUrl, string authToken, out string resourceFolder)
        {
            ConsoleColor defaultForeground = Console.ForegroundColor;

            AuthenticationManager authManager = new AuthenticationManager();
            using (var ctx = authManager.GetAzureADAccessTokenAuthenticatedContext(webUrl, authToken))
            {
                ctx.RequestTimeout = Timeout.Infinite;

                // Just to output the site details
                Web web = ctx.Web;
                ctx.Load(web, w => w.Title);
                ctx.ExecuteQueryRetry();

                Console.ForegroundColor = ConsoleColor.White;
                Console.WriteLine("Your site title is:" + ctx.Web.Title);
                Console.ForegroundColor = defaultForeground;

                ProvisioningTemplateCreationInformation ptci = new ProvisioningTemplateCreationInformation(ctx.Web);

                // Create FileSystemConnector to store a temporary copy of the template 
                Guid templateId = Guid.NewGuid();
                resourceFolder = Path.Combine(Path.GetTempPath(), templateId.ToString());
                ptci.FileConnector = new FileSystemConnector(resourceFolder, "");
                ptci.ProgressDelegate = delegate (String message, Int32 progress, Int32 total)
                {
                    // Only to output progress for console UI
                    Console.WriteLine("{0:00}/{1:00} - {2}", progress, total, message);
                };

                // Execute actual extraction of the template
                ProvisioningTemplate template = ctx.Web.GetProvisioningTemplate(ptci);

                // We can serialize this template to save and reuse it
                // Optional step 
                XMLTemplateProvider provider = new XMLFileSystemTemplateProvider(resourceFolder, "");
                Console.ForegroundColor = ConsoleColor.White;
                provider.SaveAs(template, $"{templateId.ToString()}.xml");
                Console.WriteLine($"Template saved to {resourceFolder}\\{templateId}.xml");
                Console.ForegroundColor = defaultForeground;

                return template;
            }
        }

        public static void ApplyProvisioningTemplate(string webUrl, string templateString, string resourcePath, string authToken)
        {
            ProvisioningTemplate template = LoadProvisioningTemplateFromString(templateString, null, (e) => { });
            ApplyProvisioningTemplate(webUrl, template, resourcePath, authToken);
        }

        internal static ProvisioningTemplate LoadProvisioningTemplateFromString(string xml, ITemplateProviderExtension[] templateProviderExtensions, Action<Exception> exceptionHandler)
        {
            var formatter = new XMLPnPSchemaFormatter();

            XMLTemplateProvider provider = new XMLStreamTemplateProvider();

            try
            {
                using (var stream = new MemoryStream(Encoding.UTF8.GetBytes(xml)))
                {
                    return provider.GetTemplate(stream, templateProviderExtensions);
                }
            }
            catch (ApplicationException ex)
            {
                if (ex.InnerException is AggregateException)
                {
                    if (exceptionHandler != null)
                    {
                        foreach (var exception in ((AggregateException)ex.InnerException).InnerExceptions)
                        {
                            exceptionHandler(exception);
                        }
                    }
                }
            }
            return null;
        }

        public static void ApplyProvisioningTemplate(string webUrl, ProvisioningTemplate template, string resourcePath, string authToken)
        {
            AuthenticationManager authManager = new AuthenticationManager();
            using (var ctx = authManager.GetAzureADAccessTokenAuthenticatedContext(webUrl, authToken))
            {
                ConsoleColor defaultForeground = Console.ForegroundColor;

                ctx.RequestTimeout = Timeout.Infinite;

                // Just to output the site details
                Web web = ctx.Web;
                ctx.Load(web, w => w.Title);
                ctx.ExecuteQueryRetry();

                Console.ForegroundColor = ConsoleColor.White;
                Console.WriteLine("Your site title is:" + ctx.Web.Title);
                Console.ForegroundColor = defaultForeground;

                // We could potentially also upload the template from file system, but we at least need this for branding file
                //XMLTemplateProvider provider =
                //       new XMLFileSystemTemplateProvider(@"c:\temp\pnpprovisioningdemo", "");
                //template = provider.GetTemplate("PnPProvisioningDemo.xml");

                ProvisioningTemplateApplyingInformation ptai = new ProvisioningTemplateApplyingInformation();
                ptai.ProgressDelegate = delegate (String message, Int32 progress, Int32 total)
                {
                    Console.WriteLine("{0:00}/{1:00} - {2}", progress, total, message);
                };

                // Associate file connector for assets
                FileSystemConnector connector = new FileSystemConnector(resourcePath, "");
                template.Connector = connector;

                // Since template is actual object, we can modify this using code as needed
                //template.Lists.Add(new ListInstance()
                //{
                //    Title = "PnP Sample Contacts",
                //    Url = "lists/PnPContacts",
                //    TemplateType = (Int32)ListTemplateType.Contacts,
                //    EnableAttachments = true
                //});

                web.ApplyProvisioningTemplate(template, ptai);
            }
        }
    }
}
